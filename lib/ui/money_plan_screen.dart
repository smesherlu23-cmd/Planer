import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import '../logic/money_plan.dart';
import 'common.dart';
import 'icons.dart';
import 'theme.dart';

const _keyMonthly = 'money_plan_monthly';
const _keyDepositRate = 'money_deposit_rate';

/// Аналитика денег: сколько остаётся, разные планы, досрочные платежи, сроки копилок, где сэкономить.
class MoneyPlanScreen extends StatelessWidget {
  const MoneyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final now = DateTime.now();
    final from = dayKey(DateTime(now.year, now.month - 6, 1));
    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика и планы')),
      body: Watch(
        streams: () => [
          db.watchTransactions(from: from, to: todayKey()),
          db.watchFunds(),
          db.watchFundValues(),
          db.watchCategories(),
          db.watchAllSettings(),
        ],
        builder: (context, v) {
          final txs = v[0] as List<Transaction>;
          final funds = v[1] as List<Fund>;
          final values = v[2] as Map<int, double>;
          final cats = {for (final c in v[3] as List<Category>) c.id: c};
          final settings = v[4] as Map<String, String>;
          final depositRate = double.tryParse(settings[_keyDepositRate] ?? '') ?? 0;
          final items = [
            for (final f in funds)
              PlanItem(
                id: f.id,
                name: f.name,
                isDebt: f.kind == FundKind.debt,
                balance: values[f.id] ?? fundValue(f, 0),
                target: f.kind == FundKind.debt ? null : f.target,
                rate: f.kind == FundKind.debt ? (f.interestRate ?? 0) : depositRate,
                payment: f.kind == FundKind.debt ? (f.monthlyAmount ?? 0) : 0,
              ),
          ];
          final flow = averageFlow(txs, now: now);
          final minimum = minimumPayments(items);
          final planned = minimum + funds.where((f) => f.kind == FundKind.savings).fold<double>(0, (a, f) => a + (f.monthlyAmount ?? 0));
          final free = flow == null ? null : math.max(0.0, flow.income - flow.expenses);
          final saved = double.tryParse(settings[_keyMonthly] ?? '');
          final monthly = math.max(minimum, saved ?? (planned > 0 ? planned : (free ?? minimum)));
          return _PlanBody(
            items: items,
            funds: funds,
            flow: flow,
            free: free,
            minimum: minimum,
            planned: planned,
            monthly: monthly,
            depositRate: depositRate,
            spending: [for (final (id, sum) in spendingByCategory(txs, now: now)) (cats[id], sum)],
          );
        },
      ),
    );
  }
}

class _PlanBody extends StatelessWidget {
  const _PlanBody({
    required this.items,
    required this.funds,
    required this.flow,
    required this.free,
    required this.minimum,
    required this.planned,
    required this.monthly,
    required this.depositRate,
    required this.spending,
  });

  final List<PlanItem> items;
  final List<Fund> funds;
  final MonthlyFlow? flow;
  final double? free;
  final double minimum;
  final double planned;
  final double monthly;
  final double depositRate;
  final List<(Category?, double)> spending;

  @override
  Widget build(BuildContext context) {
    final debts = items.where((i) => i.isDebt && i.open).toList();
    final goals = items.where((i) => !i.isDebt && i.target != null && i.open).toList();
    final results = [for (final s in Strategy.values) simulate(items, monthly, s)];
    // Без ставок по долгам планы стоят одинаково: не выделяем ни один.
    final rated = debts.any((d) => d.rate > 0) || goals.any((g) => g.rate > 0);
    final best = debts.isEmpty || goals.isEmpty || !rated ? null : bestStrategy(items, results);
    final icons = {for (final f in funds) f.id: f.icon};
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _FlowCard(flow: flow),
        _MonthlyCard(
          monthly: monthly,
          minimum: minimum,
          planned: planned,
          free: free,
          depositRate: depositRate,
          hasGoals: goals.isNotEmpty,
        ),
        if (debts.isEmpty && goals.isEmpty)
          const Card(
            child: EmptyHint(
              'Добавь кредит или копилку с целью на экране «Деньги», и здесь появятся сроки и планы.',
              icon: Icons.savings_outlined,
            ),
          ),
        if (debts.isNotEmpty && goals.isNotEmpty) ...[
          const SectionTitle('Планы'),
          _Recommendation(items: items, results: results, best: best ?? Strategy.debtsFirst),
          for (final r in results) _StrategyCard(result: r, items: items, icons: icons, best: r.strategy == best, monthly: monthly),
        ] else if (debts.isNotEmpty || goals.isNotEmpty) ...[
          const SectionTitle('Если откладывать эту сумму'),
          _StrategyCard(result: results.first, items: items, icons: icons, best: false, monthly: monthly, showTitle: false),
        ],
        for (final d in debts) ...[SectionTitle('${d.name}: как закрыть быстрее'), _DebtCard(debt: d, free: free)],
        for (final g in goals) ...[
          SectionTitle('${g.name}: когда накопишь'),
          _GoalCard(goal: g, fund: funds.firstWhere((f) => f.id == g.id)),
        ],
        if (spending.isNotEmpty) ...[
          const SectionTitle('Где можно сэкономить'),
          _SpendingCard(spending: spending, debt: debts.isEmpty ? null : debts.reduce((a, b) => a.rate >= b.rate ? a : b)),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: Text(
            'Расчёт помесячный: проценты начисляются на остаток раз в месяц, досрочные платежи сокращают срок. '
            'Банк может считать по дням, поэтому реальные цифры отличаются на несколько процентов.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35),
          ),
        ),
      ],
    );
  }
}

TextStyle? _muted(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35);

/// Сколько в среднем приходит, уходит и остаётся.
class _FlowCard extends StatelessWidget {
  const _FlowCard({required this.flow});
  final MonthlyFlow? flow;

  @override
  Widget build(BuildContext context) {
    final f = flow;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (f == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Средний месяц появится, когда наберутся доходы и расходы хотя бы за один прошлый месяц. '
            'Пока планы считаются по сумме, которую ты укажешь ниже.',
            style: _muted(context),
          ),
        ),
      );
    }
    final left = f.income - f.expenses;
    return HeroCard(
      colors: dark ? const [Color(0xFFB45309), Color(0xFFC2410C)] : const [Color(0xFFD97706), Color(0xFFEA580C)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            f.months == 1 ? 'Прошлый месяц' : 'В среднем за ${f.months} мес.',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            left >= 0 ? 'Остаётся ${formatMoney(left)}' : 'Не хватает ${formatMoney(-left)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HeroStat(label: 'Доходы', value: formatMoney(f.income)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HeroStat(label: 'Расходы', value: formatMoney(f.expenses)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HeroStat(label: 'Норма сбережений', value: f.income <= 0 ? '—' : '${(100 * left / f.income).round()}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Сколько в месяц идёт на долги и копилки. Ползунок сразу пересчитывает все планы.
class _MonthlyCard extends StatefulWidget {
  const _MonthlyCard({
    required this.monthly,
    required this.minimum,
    required this.planned,
    required this.free,
    required this.depositRate,
    required this.hasGoals,
  });
  final double monthly;
  final double minimum;
  final double planned;
  final double? free;
  final double depositRate;
  final bool hasGoals;

  @override
  State<_MonthlyCard> createState() => _MonthlyCardState();
}

class _MonthlyCardState extends State<_MonthlyCard> {
  double? _drag;
  double? _rateDrag;

  double get _max {
    final m = [widget.monthly * 2, widget.planned * 1.5, (widget.free ?? 0) * 1.2, widget.minimum + 20000, 50000.0].reduce(math.max);
    return (m / 1000).ceil() * 1000;
  }

  Future<void> _set(double v) => context.db.setSetting(_keyMonthly, '${v.round()}');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = (_drag ?? widget.monthly).clamp(widget.minimum, _max).toDouble();
    final rate = _rateDrag ?? widget.depositRate;
    Widget chip(String label, double v) => ActionChip(
      label: Text('$label ${formatMoney(v)}'),
      onPressed: () {
        setState(() => _drag = null);
        _set(math.max(v, widget.minimum));
      },
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('На долги и копилки в месяц', style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(formatMoney(value), style: theme.textTheme.headlineMedium?.copyWith(color: Accent.money)),
            if (widget.minimum > 0) Text('Из них обязательные платежи по долгам: ${formatMoney(widget.minimum)}', style: _muted(context)),
            Slider(
              value: value,
              min: widget.minimum,
              max: _max,
              divisions: math.max(1, ((_max - widget.minimum) / 500).round()),
              activeColor: Accent.money,
              onChanged: (v) => setState(() => _drag = v),
              onChangeEnd: (v) => _set(v),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (widget.planned > 0) chip('Как сейчас', widget.planned),
                if (widget.free != null && widget.free! > 0) chip('Всё свободное', widget.free!),
              ],
            ),
            if (widget.hasGoals) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(child: Text('Вклад или накопительный счёт', style: theme.textTheme.titleSmall)),
                  Text('${formatNumber(rate, maxDecimals: 1)}% годовых', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              Slider(
                value: rate.clamp(0, 25).toDouble(),
                max: 25,
                divisions: 50,
                activeColor: Accent.money,
                onChanged: (v) => setState(() => _rateDrag = v),
                onChangeEnd: (v) async {
                  await context.db.setSetting(_keyDepositRate, formatNumber(v, maxDecimals: 1).replaceAll(',', '.'));
                  if (mounted) setState(() => _rateDrag = null);
                },
              ),
              Text(
                rate == 0
                    ? 'Если копишь на счёте с процентами, укажи ставку: копилки наберутся быстрее.'
                    : 'Проценты на копилки начисляются каждый месяц.',
                style: _muted(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(_MonthlyCard old) {
    super.didUpdateWidget(old);
    if (old.monthly != widget.monthly) _drag = null;
  }
}

/// Какой план выгоднее и почему.
class _Recommendation extends StatelessWidget {
  const _Recommendation({required this.items, required this.results, required this.best});
  final List<PlanItem> items;
  final List<PlanResult> results;
  final Strategy best;

  @override
  Widget build(BuildContext context) {
    final debtRate = items.where((i) => i.isDebt && i.open).map((i) => i.rate).fold<double>(0, math.max);
    final depositRate = items.where((i) => !i.isDebt).map((i) => i.rate).fold<double>(0, math.max);
    final bestR = results.firstWhere((r) => r.strategy == best);
    final worst = results.reduce((a, b) => (a.interestPaid - a.interestEarned) >= (b.interestPaid - b.interestEarned) ? a : b);
    final saving = (worst.interestPaid - worst.interestEarned) - (bestR.interestPaid - bestR.interestEarned);
    final String text;
    if (debtRate == 0) {
      text =
          'У кредита не указана ставка, поэтому планы считаются без процентов и по деньгам почти равны. '
          'Укажи ставку в карточке кредита, и станет видно, сколько стоит каждый план.';
    } else if (best == Strategy.debtsFirst) {
      text =
          'Выгоднее «${best.label}»: кредит под ${formatNumber(debtRate, maxDecimals: 1)}% стоит дороже, '
          'чем приносит ${depositRate == 0 ? 'копилка без процентов' : 'вклад под ${formatNumber(depositRate, maxDecimals: 1)}%'}. '
          '${saving >= 100 ? 'Это сэкономит ${formatMoney(saving)} по сравнению с планом «${worst.strategy.label}».' : ''}';
    } else {
      text =
          'Выгоднее «${best.label}»: вклад под ${formatNumber(depositRate, maxDecimals: 1)}% приносит больше, чем стоит кредит. '
          '${saving >= 100 ? 'Разница ${formatMoney(saving)} по сравнению с планом «${worst.strategy.label}».' : ''}';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ColorIcon(Icons.tips_and_updates_rounded, color: Accent.money, size: 40),
            const SizedBox(width: 12),
            Expanded(child: Text(text.trim(), style: const TextStyle(height: 1.35))),
          ],
        ),
      ),
    );
  }
}

/// Один план: когда закроется каждый долг и копилка и сколько уйдёт на проценты.
class _StrategyCard extends StatelessWidget {
  const _StrategyCard({
    required this.result,
    required this.items,
    required this.icons,
    required this.best,
    required this.monthly,
    this.showTitle = true,
  });
  final PlanResult result;
  final List<PlanItem> items;
  final Map<int, String> icons;
  final bool best;
  final double monthly;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = items.where((i) => i.isDebt ? i.balance > 0 : i.target != null).toList();
    return Card(
      shape: best
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Accent.money, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Row(
                children: [
                  Expanded(child: Text(result.strategy.label, style: theme.textTheme.titleMedium)),
                  if (best) const Pill('выгоднее', icon: Icons.star_rounded, color: Accent.money),
                ],
              ),
              const SizedBox(height: 2),
              Text(result.strategy.description, style: _muted(context)),
              const SizedBox(height: 10),
            ],
            for (final i in shown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    ItemIcon(icons[i.id], size: 34, fallback: i.isDebt ? 'bank' : 'savings'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(_when(i, result.doneMonth[i.id]), style: _muted(context)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (result.interestPaid >= 1) Pill('проценты банку ${formatMoney(result.interestPaid)}', color: const Color(0xFFEF4444)),
                if (result.interestEarned >= 1) Pill('доход по вкладу ${formatMoney(result.interestEarned)}', color: Accent.habits),
                Pill('в копилках через год ${formatMoney(result.savedAfterYear)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _when(PlanItem i, int? month) {
    if (month == null) return i.isDebt ? 'не закроется: денег не хватает' : 'дольше 50 лет';
    if (month == 0) return i.isDebt ? 'закрыт' : 'уже накоплено';
    return '${i.isDebt ? 'закроешь' : 'накопишь'} через ${monthsLabel(month)}';
  }
}

/// Строка таблицы вариантов: подпись, срок, деньги.
Widget _variantRow(
  BuildContext context, {
  required String label,
  required String when,
  String? money,
  Color? moneyColor,
  bool bold = false,
}) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ),
        Expanded(child: Text(when, style: theme.textTheme.bodyMedium)),
        if (money != null) ...[
          const SizedBox(width: 8),
          Text(
            money,
            style: TextStyle(fontWeight: FontWeight.w600, color: moneyColor ?? theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    ),
  );
}

/// Как быстрее закрыть долг: доплаты каждый месяц и разовый платёж.
class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debt, required this.free});
  final PlanItem debt;
  final double? free;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = payoff(balance: debt.balance, payment: debt.payment, ratePercent: debt.rate);
    if (debt.payment <= 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Укажи платёж в месяц в карточке долга, чтобы увидеть сроки.', style: _muted(context)),
        ),
      );
    }
    final extras = <double>{0, 2000, 5000, 10000};
    final spare = free == null ? null : (free! - debt.payment);
    if (spare != null && spare > 1000) extras.add((spare / 500).floor() * 500);
    final lumps = [10000.0, 30000.0, 50000.0].where((l) => l < debt.balance).toList();
    String saved(Payoff? p) {
      if (base == null || p == null) return '';
      final s = base.interest - p.interest;
      return s >= 1 ? '−${formatMoney(s)}' : '';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Осталось ${formatMoney(debt.balance)}, платёж ${formatMoney(debt.payment)}'
              '${debt.rate > 0 ? ', ставка ${formatNumber(debt.rate, maxDecimals: 1)}%' : ', ставка не указана'}.',
              style: _muted(context),
            ),
            const SizedBox(height: 8),
            Text('Доплачивать каждый месяц', style: theme.textTheme.titleSmall),
            for (final e in (extras.toList()..sort()))
              Builder(
                builder: (context) {
                  final p = payoff(balance: debt.balance, payment: debt.payment + e, ratePercent: debt.rate);
                  return _variantRow(
                    context,
                    label: e == 0 ? 'Как сейчас' : '+${formatMoney(e)}',
                    bold: e == 0,
                    when: p == null ? 'платёж не покрывает проценты' : monthsLabel(p.months),
                    money: debt.rate <= 0 || p == null ? null : (e == 0 ? 'проценты ${formatMoney(p.interest)}' : saved(p)),
                    moneyColor: e == 0 ? null : Accent.habits,
                  );
                },
              ),
            if (lumps.isNotEmpty) ...[
              const Divider(height: 20),
              Text('Внести разом сейчас, платёж прежний', style: theme.textTheme.titleSmall),
              for (final l in lumps)
                Builder(
                  builder: (context) {
                    final p = payoff(balance: debt.balance, payment: debt.payment, ratePercent: debt.rate, lumpSum: l);
                    final faster = base == null || p == null ? null : base.months - p.months;
                    return _variantRow(
                      context,
                      label: formatMoney(l),
                      when: p == null ? '—' : '${monthsLabel(p.months)}${faster != null && faster > 0 ? ' (на $faster мес. раньше)' : ''}',
                      money: debt.rate <= 0 ? null : saved(p),
                      moneyColor: Accent.habits,
                    );
                  },
                ),
            ],
            if (debt.rate > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Зелёным: сколько не отдашь банку в виде процентов. При досрочном погашении выбирай в банке «уменьшить срок»: так экономия больше, чем при уменьшении платежа.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Когда накопишь: разные взносы и сколько нужно, чтобы успеть к сроку.
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.fund});
  final PlanItem goal;
  final Fund fund;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = goal.target!;
    final left = target - goal.balance;
    final base = fund.monthlyAmount ?? 0;
    final variants = <double>{
      if (base > 0) ...[base, base * 1.5, base * 2] else ...[5000, 10000, 20000],
    }.toList()..sort();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Накоплено ${formatMoney(goal.balance)} из ${formatMoney(target)}, осталось ${formatMoney(left)}.',
              style: _muted(context),
            ),
            const SizedBox(height: 8),
            Text('Если откладывать в месяц', style: theme.textTheme.titleSmall),
            for (final m in variants)
              Builder(
                builder: (context) {
                  final months = monthsToTarget(balance: goal.balance, target: target, monthly: m, ratePercent: goal.rate);
                  return _variantRow(
                    context,
                    label: formatMoney((m / 100).round() * 100.0),
                    bold: m == base,
                    when: months == null ? 'дольше 100 лет' : monthsLabel(months),
                  );
                },
              ),
            const Divider(height: 20),
            Text('Чтобы успеть', style: theme.textTheme.titleSmall),
            for (final months in [6, 12, 24])
              _variantRow(
                context,
                label: 'за $months мес.',
                when:
                    'нужно ${formatMoney((monthlyNeeded(balance: goal.balance, target: target, months: months, ratePercent: goal.rate) / 100).ceil() * 100.0)} в месяц',
              ),
          ],
        ),
      ),
    );
  }
}

/// Самые большие траты и что даст их урезать на 20%.
class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.spending, required this.debt});
  final List<(Category?, double)> spending;
  final PlanItem? debt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = spending.take(4).toList();
    final total = spending.fold<double>(0, (a, r) => a + r.$2);
    final cut = top.take(3).fold<double>(0, (a, r) => a + r.$2) * 0.2;
    final d = debt;
    final base = d == null || d.payment <= 0 ? null : payoff(balance: d.balance, payment: d.payment, ratePercent: d.rate);
    final faster = d == null || base == null ? null : payoff(balance: d.balance, payment: d.payment + cut, ratePercent: d.rate);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Расходы в среднем за месяц: ${formatMoney(total)}', style: _muted(context)),
            const SizedBox(height: 6),
            for (final (c, sum) in top)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    ItemIcon(c?.icon, size: 34, fallback: 'payments'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c?.name ?? 'Без категории', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${(100 * sum / total).round()}% расходов · −20% дадут ${formatMoney(sum * 0.2)}', style: _muted(context)),
                        ],
                      ),
                    ),
                    Text(formatMoney(sum), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            if (cut >= 100) ...[
              const Divider(height: 20),
              Text(
                'Если урезать три самые большие траты на 20%, освободится ${formatMoney(cut)} в месяц'
                '${base != null && faster != null && base.months > faster.months ? '. Отправляя их в «${d!.name}», закроешь его на ${base.months - faster.months} мес. раньше' : ''}'
                '${base != null && faster != null && d!.rate > 0 && base.interest - faster.interest >= 1 ? ' и сэкономишь ${formatMoney(base.interest - faster.interest)} процентов' : ''}.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
