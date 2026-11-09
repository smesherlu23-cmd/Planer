import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../logic/budget.dart';
import '../logic/calc.dart';
import 'common.dart';
import 'icons.dart';
import 'money_screen.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// Бюджет на экране «Деньги»
// ---------------------------------------------------------------------------

/// Группы бюджета: доходы, платежи, накопления, расходы. План против факта.
class BudgetSections extends StatelessWidget {
  const BudgetSections({super.key, required this.budget, required this.month});
  final MonthBudget budget;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final b = budget;
    void edit() => Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetEditScreen(month: month)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Бюджет',
          trailing: TextButton.icon(onPressed: edit, icon: const Icon(Icons.tune_rounded, size: 18), label: const Text('План')),
        ),
        if (b.unallocated.abs() >= 1)
          Card(
            color: (b.unallocated < 0 ? theme.colorScheme.error : Accent.habits).withValues(alpha: 0.1),
            child: ListTile(
              leading: Icon(
                b.unallocated < 0 ? Icons.warning_amber_rounded : Icons.savings_outlined,
                color: b.unallocated < 0 ? theme.colorScheme.error : Accent.habits,
              ),
              title: Text(
                b.unallocated < 0
                    ? 'Распределено на ${formatMoney(-b.unallocated)} больше дохода'
                    : 'Не распределено ${formatMoney(b.unallocated)}',
              ),
              subtitle: Text(
                b.unallocated < 0 ? 'Урежь расходы или накопления в плане' : 'Отправь их в копилку или долг, чтобы деньги не растворились',
              ),
              onTap: edit,
            ),
          ),
        for (final g in BudgetGroup.values)
          if (b.of(g).isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(g.label, style: theme.textTheme.labelLarge?.copyWith(color: muted)),
                  ),
                  Text(
                    '${formatMoney(b.of(g).fold<double>(0, (a, r) => a + r.fact))} из ${formatMoney(b.of(g).fold<double>(0, (a, r) => a + r.plan))}',
                    style: theme.textTheme.labelLarge?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [for (final r in b.of(g)) BudgetRowTile(row: r)]),
              ),
            ),
          ],
      ],
    );
  }
}

class BudgetRowTile extends StatelessWidget {
  const BudgetRowTile({super.key, required this.row});
  final BudgetRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final r = row;
    final color = switch (r.group) {
      BudgetGroup.income => Accent.habits,
      BudgetGroup.debts => Accent.trackers,
      BudgetGroup.savings => Accent.money,
      BudgetGroup.expenses => r.over ? theme.colorScheme.error : Accent.goals,
    };
    final fallback = switch (r.group) {
      BudgetGroup.income => 'salary',
      BudgetGroup.debts => 'bank',
      BudgetGroup.savings => 'savings',
      BudgetGroup.expenses => 'payments',
    };
    final left = r.plan - r.fact;
    final String hint;
    if (r.unplanned) {
      hint = 'не было в плане';
    } else if (r.group == BudgetGroup.expenses) {
      hint = r.over ? 'перерасход ${formatMoney(-left)}' : 'осталось ${formatMoney(left)}';
    } else {
      hint = r.done ? 'выполнено' : 'ещё ${formatMoney(left)}';
    }
    return InkWell(
      onTap: r.fund == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => FundDetailScreen(fundId: r.fund!.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ItemIcon(r.icon, size: 38, fallback: fallback),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (r.done)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.check_circle_rounded, size: 16, color: Accent.habits),
                        ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: formatMoney(r.fact),
                                  style: TextStyle(fontWeight: FontWeight.w700, color: r.over ? theme.colorScheme.error : null),
                                ),
                                if (!r.unplanned)
                                  TextSpan(
                                    text: ' / ${formatMoney(r.plan)}',
                                    style: TextStyle(color: muted, fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ProgressLine(value: r.plan <= 0 ? 1 : r.fact / r.plan, color: r.unplanned ? muted : color, height: 6),
                  const SizedBox(height: 4),
                  Text(hint, style: TextStyle(fontSize: 12, color: r.over ? theme.colorScheme.error : muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка, когда бюджет на месяц ещё не составлен.
class NoBudgetCard extends StatelessWidget {
  const NoBudgetCard({super.key, required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: EmptyHint(
        'Распредели доход месяца: сколько на платежи, сколько в копилки, сколько на расходы по категориям. '
        'Потом здесь будет видно, сколько ещё можно потратить.',
        icon: Icons.account_balance_wallet_outlined,
        action: FilledButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetEditScreen(month: month))),
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Составить бюджет'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Составление бюджета
// ---------------------------------------------------------------------------

class BudgetEditScreen extends StatefulWidget {
  const BudgetEditScreen({super.key, required this.month});
  final DateTime month;

  @override
  State<BudgetEditScreen> createState() => _BudgetEditScreenState();
}

class _Line {
  _Line({this.category, this.fund, required double amount})
    : controller = TextEditingController(text: amount > 0 ? formatNumber(amount, maxDecimals: 0) : '');
  final Category? category;
  final Fund? fund;
  final TextEditingController controller;
  double get amount => parseNumber(controller.text) ?? 0;
}

class _BudgetEditScreenState extends State<BudgetEditScreen> {
  List<_Line>? _lines;
  String? _source;

  int get _month => monthKey(widget.month);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final l in _lines ?? const <_Line>[]) {
      l.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final db = context.db;
    final cats = await db.watchCategories().first;
    final funds = await db.watchFunds().first;
    final fundValues = await db.watchFundValues().first;
    var lines = await db.budgetOf(_month);
    String? source;
    if (lines.isEmpty) {
      final prev = await db.previousBudgetMonth(_month);
      if (prev != null) {
        lines = await db.budgetOf(prev);
        final m = monthFromKey(prev);
        source = 'Заполнено как в ${monthTitle(m.year, m.month).toLowerCase()}. Поправь, что изменилось.';
      } else {
        source = 'Заполнено по лимитам категорий и плановым взносам. Поправь под себя.';
      }
    }
    final byCat = {for (final l in lines.where((l) => l.categoryId != null)) l.categoryId!: l.amount};
    final byFund = {for (final l in lines.where((l) => l.fundId != null)) l.fundId!: l.amount};
    final fromDefaults = lines.isEmpty;
    // Последний доход по категориям: подсказка для первого бюджета.
    final lastIncome = <int, double>{};
    if (fromDefaults) {
      final from = dayKey(DateTime(widget.month.year, widget.month.month - 1));
      final to = dayKey(DateTime(widget.month.year, widget.month.month, 0));
      for (final t in await db.transactionsBetween(from, to)) {
        if (t.isIncome && t.categoryId != null) lastIncome[t.categoryId!] = (lastIncome[t.categoryId!] ?? 0) + t.amount;
      }
    }
    final result = <_Line>[
      for (final c in cats.where((c) => c.isIncome)) _Line(category: c, amount: byCat[c.id] ?? (fromDefaults ? lastIncome[c.id] ?? 0 : 0)),
      for (final f in funds)
        // Закрытый долг и полная копилка в план не просятся.
        if (byFund.containsKey(f.id) || !(fundValues[f.id] != null && _finished(f, fundValues[f.id]!)))
          _Line(fund: f, amount: byFund[f.id] ?? (fromDefaults ? f.monthlyAmount ?? 0 : 0)),
      for (final c in cats.where((c) => !c.isIncome)) _Line(category: c, amount: byCat[c.id] ?? (fromDefaults ? c.monthlyLimit ?? 0 : 0)),
    ];
    for (final l in result) {
      l.controller.addListener(() => setState(() {}));
    }
    if (!mounted) return;
    setState(() {
      _lines = result;
      _source = source;
    });
  }

  bool _finished(Fund f, double value) => f.kind == FundKind.debt ? value <= 0 : (f.target != null && value >= f.target!);

  Future<void> _save() async {
    await context.db.saveBudget(_month, [for (final l in _lines!) (categoryId: l.category?.id, fundId: l.fund?.id, amount: l.amount)]);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines;
    final title = monthTitle(widget.month.year, widget.month.month);
    return Scaffold(
      appBar: AppBar(title: Text('Бюджет: ${title[0].toLowerCase()}${title.substring(1)}')),
      body: lines == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _Totals(lines: lines),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (_source != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          child: Text(_source!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ),
                      _group(context, 'Доходы', 'Сколько придёт за месяц', lines.where((l) => l.category?.isIncome ?? false)),
                      _group(
                        context,
                        'Платежи по долгам',
                        'Сколько отдать в этом месяце',
                        lines.where((l) => l.fund?.kind == FundKind.debt),
                      ),
                      _group(
                        context,
                        'Накопления',
                        'Сколько отложить в каждую копилку',
                        lines.where((l) => l.fund?.kind == FundKind.savings),
                      ),
                      _group(
                        context,
                        'Расходы',
                        'Лимит на месяц по каждой категории. Пусто: без лимита',
                        lines.where((l) => l.category != null && !l.category!.isIncome),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(onPressed: _save, child: const Text('Сохранить бюджет')),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _group(BuildContext context, String title, String hint, Iterable<_Line> lines) {
    if (lines.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
          child: Text(hint, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final l in lines)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Row(
                      children: [
                        ItemIcon(l.fund?.icon ?? l.category?.icon, size: 38, fallback: l.fund != null ? 'savings' : 'payments'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(l.fund?.name ?? l.category!.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 120,
                          child: NumberField(controller: l.controller, label: 'Сумма', suffix: '₽'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Итог сверху: доход, распределено, свободно.
class _Totals extends StatelessWidget {
  const _Totals({required this.lines});
  final List<_Line> lines;

  @override
  Widget build(BuildContext context) {
    final income = lines.where((l) => l.category?.isIncome ?? false).fold<double>(0, (a, l) => a + l.amount);
    final allocated = lines.where((l) => !(l.category?.isIncome ?? false)).fold<double>(0, (a, l) => a + l.amount);
    final free = income - allocated;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return HeroCard(
      colors: dark ? const [Color(0xFFB45309), Color(0xFFC2410C)] : const [Color(0xFFD97706), Color(0xFFEA580C)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            free < 0 ? 'Распределено больше дохода на' : 'Свободно, ещё не распределено',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatMoney(free.abs()), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HeroStat(label: 'Доход', value: formatMoney(income)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HeroStat(label: 'Распределено', value: formatMoney(allocated)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
