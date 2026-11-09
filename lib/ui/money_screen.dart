import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/icon_keys.dart';
import '../data/queries.dart';
import '../logic/budget.dart';
import '../logic/calc.dart';
import '../logic/values.dart';
import 'budget_screen.dart';
import 'common.dart';
import 'icons.dart';
import 'theme.dart';

/// Долг выплачивается: прогресс зелёный. Копилка копится: прогресс цвета раздела.
const _debtColor = Color(0xFFEF4444);

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  int get _from => dayKey(_month);
  int get _to => dayKey(DateTime(_month.year, _month.month + 1, 0));

  void _shift(int months) => setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return ScrollFabScope(
      child: Scaffold(
        floatingActionButton: ScrollFab(
          child: FloatingActionButton.extended(
            heroTag: null,
            onPressed: () => showTransactionSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Операция'),
          ),
        ),
        body: Watch(
          deps: [_from],
          streams: () => [
            db.watchTransactions(from: _from, to: _to),
            db.watchCategories(),
            db.watchFunds(),
            db.watchFundValues(),
            db.watchAllFundMoves(),
            (db.select(db.categories)).watch(),
            db.watchBudget(monthKey(_month)),
          ],
          builder: (context, v) {
            final txs = v[0] as List<Transaction>;
            final cats = v[1] as List<Category>;
            final funds = v[2] as List<Fund>;
            final values = v[3] as Map<int, double>;
            final moves = v[4] as List<FundMove>;
            final allCats = {for (final c in v[5] as List<Category>) c.id: c};
            final budget = buildBudget(
              lines: v[6] as List<BudgetLine>,
              categories: allCats.values.toList(),
              funds: funds,
              transactions: txs,
              moves: [
                for (final m in moves)
                  if (m.day >= _from && m.day <= _to) m,
              ],
            );
            final daysLeft = daysLeftInMonth(_month, DateTime.now());
            final expenses = txs.where((t) => !t.isIncome).fold<double>(0, (a, t) => a + t.amount);
            final income = txs.where((t) => t.isIncome).fold<double>(0, (a, t) => a + t.amount);
            final byCat = <int?, double>{};
            for (final t in txs.where((t) => !t.isIncome)) {
              byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
            }
            final catRows = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            final limited = cats.where((c) => c.monthlyLimit != null && !c.isIncome && !byCat.containsKey(c.id)).toList();
            final byDay = <int, List<Transaction>>{};
            for (final t in txs) {
              byDay.putIfAbsent(t.day, () => []).add(t);
            }
            final diff = income - expenses;

            return ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                PageHeader(
                  overline: 'бюджет на месяц',
                  title: 'Деньги',
                  actions: [
                    IconButton(
                      tooltip: 'Категории',
                      icon: const Icon(Icons.category_rounded),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                    ),
                  ],
                ),
                HeroCard(
                  colors: dark ? const [Color(0xFFB45309), Color(0xFFC2410C)] : const [Color(0xFFD97706), Color(0xFFEA580C)],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HeroArrow(Icons.chevron_left_rounded, onTap: () => _shift(-1)),
                          Expanded(
                            child: Text(
                              monthTitle(_month.year, _month.month),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),
                          HeroArrow(Icons.chevron_right_rounded, onTap: () => _shift(1)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (budget.planned && budget.expensePlan > 0) ...[
                        Text(
                          budget.leftToSpend >= 0 ? 'Можно ещё потратить' : 'Перерасход',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatMoney(budget.leftToSpend.abs()),
                            style: theme.textTheme.displaySmall?.copyWith(color: Colors.white),
                          ),
                        ),
                        if (budget.leftToSpend > 0 && daysLeft > 0)
                          Text(
                            'это ${formatMoney(budget.leftToSpend / daysLeft)} в день до конца месяца',
                            style: const TextStyle(color: Colors.white),
                          ),
                      ] else ...[
                        const Text(
                          'Потрачено',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(formatMoney(expenses), style: theme.textTheme.displaySmall?.copyWith(color: Colors.white)),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (budget.planned)
                        Row(
                          children: [
                            Expanded(
                              child: HeroStat(label: 'Доход', value: '${formatMoney(income)} из ${formatMoney(budget.incomePlan)}'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: HeroStat(
                                label: 'Отложено',
                                value: '${formatMoney(budget.saveFact)} из ${formatMoney(budget.savePlan)}',
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: HeroStat(label: 'Доходы', value: '+${formatMoney(income)}'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: HeroStat(label: 'Разница', value: '${diff < 0 ? '−' : '+'}${formatMoney(diff.abs())}'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (budget.planned) BudgetSections(budget: budget, month: _month) else NoBudgetCard(month: _month),
                SectionTitle(
                  'Копилки и долги',
                  trailing: IconButton(
                    tooltip: 'Копилка или долг',
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FundEditScreen())),
                  ),
                ),
                if (funds.isEmpty)
                  Card(
                    child: EmptyHint(
                      'Копилка показывает, сколько накоплено и когда дойдёшь до цели. Долг показывает остаток и срок закрытия.',
                      icon: Icons.savings_outlined,
                      action: FilledButton.tonal(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FundEditScreen())),
                        child: const Text('Добавить'),
                      ),
                    ),
                  ),
                for (final f in funds) _FundCard(fund: f, value: values[f.id] ?? fundValue(f, 0), recent: recentMonthlyPace(moves, f.id)),
                if (!budget.planned && (catRows.isNotEmpty || limited.isNotEmpty)) ...[
                  const SectionTitle('По категориям'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          for (final e in catRows) _CategoryRow(category: allCats[e.key], spent: e.value, total: expenses),
                          for (final c in limited) _CategoryRow(category: c, spent: 0, total: expenses),
                        ],
                      ),
                    ),
                  ),
                ],
                const SectionTitle('Операции'),
                if (txs.isEmpty) const Card(child: EmptyHint('За этот месяц операций нет', icon: Icons.receipt_long_outlined)),
                for (final MapEntry(key: day, value: list) in byDay.entries) ...[
                  _DayHeader(day: day, txs: list),
                  GroupCard(
                    children: [for (final t in list) _TransactionTile(t: t, category: allCats[t.categoryId])],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.txs});
  final int day;
  final List<Transaction> txs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spent = txs.where((t) => !t.isIncome).fold<double>(0, (a, t) => a + t.amount);
    final label = dayLabel(day);
    final muted = theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
      child: Row(
        children: [
          Expanded(child: Text(label[0].toUpperCase() + label.substring(1), style: muted)),
          if (spent > 0) Text('−${formatMoney(spent)}', style: muted),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.t, required this.category});
  final Transaction t;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ItemIcon(category?.icon, size: 40, fallback: 'payments'),
      title: Text(category?.name ?? (t.isIncome ? 'Доход' : 'Без категории')),
      subtitle: t.note == null ? null : Text(t.note!, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        '${t.isIncome ? '+' : '−'}${formatMoney(t.amount)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: t.isIncome ? Accent.habits : null, fontWeight: FontWeight.w700),
      ),
      onTap: () => showTransactionSheet(context, existing: t),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.spent, required this.total});
  final Category? category;
  final double spent;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limit = category?.monthlyLimit;
    final over = limit != null && spent > limit;
    final color = over ? theme.colorScheme.error : Accent.money;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ItemIcon(category?.icon, size: 38, fallback: 'payments'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category?.name ?? 'Без категории',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatMoney(spent),
                      style: TextStyle(fontWeight: FontWeight.w700, color: over ? theme.colorScheme.error : null),
                    ),
                    if (limit != null)
                      Text(' / ${formatMoney(limit)}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                ProgressLine(
                  value: limit != null ? (limit == 0 ? 1 : spent / limit) : (total == 0 ? 0 : spent / total),
                  color: color,
                  height: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Прогресс копилки или долга: доля накопленного или выплаченного. null, если цели нет.
double? _fundProgress(Fund f, double value) {
  if (f.kind == FundKind.debt) return f.initialAmount <= 0 ? 1 : 1 - value / f.initialAmount;
  if (f.target != null) return f.target! <= 0 ? 1 : value / f.target!;
  return null;
}

class _FundCard extends StatelessWidget {
  const _FundCard({required this.fund, required this.value, required this.recent});
  final Fund fund;
  final double value;
  final double? recent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = fund;
    final isDebt = f.kind == FundKind.debt;
    final forecast = fundForecast(f, value, recentMonthly: recent);
    final progress = _fundProgress(f, value);
    final String line;
    if (isDebt) {
      line = 'осталось ${formatMoney(value)} из ${formatMoney(f.initialAmount)}';
    } else if (f.target != null) {
      line = '${formatMoney(value)} из ${formatMoney(f.target!)}';
    } else {
      line = formatMoney(value);
    }
    final color = isDebt ? Accent.habits : Accent.money;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FundDetailScreen(fundId: f.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ItemIcon(f.icon, fallback: isDebt ? 'bank' : 'savings'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(f.name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            Pill(isDebt ? 'долг' : 'копилка', color: isDebt ? _debtColor : Accent.money),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(line, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
                      ],
                    ),
                  ),
                  if (progress != null)
                    Text('${(progress.clamp(0, 1) * 100).round()}%', style: theme.textTheme.titleLarge?.copyWith(color: color)),
                ],
              ),
              if (progress != null) ...[const SizedBox(height: 14), ProgressLine(value: progress, color: color)],
              if (forecast.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(Icons.schedule_rounded, size: 16, color: muted),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(forecast.text, style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Операция
// ---------------------------------------------------------------------------

Future<void> showTransactionSheet(BuildContext context, {Transaction? existing}) {
  return showFormSheet(context, (_) => _TransactionForm(existing: existing));
}

class _TransactionForm extends StatefulWidget {
  const _TransactionForm({this.existing});
  final Transaction? existing;

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  late final _amount = TextEditingController(text: widget.existing == null ? '' : formatNumber(widget.existing!.amount, maxDecimals: 2));
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late bool _income = widget.existing?.isIncome ?? false;
  late int? _category = widget.existing?.categoryId;
  late int _day = widget.existing?.day ?? todayKey();

  Future<void> _save() async {
    final amount = parseNumber(_amount.text);
    if (amount == null || amount <= 0) return showSnack(context, 'Введи сумму');
    await context.db.saveTransaction(
      TransactionsCompanion(
        id: widget.existing == null ? const Value.absent() : Value(widget.existing!.id),
        amount: Value(amount),
        isIncome: Value(_income),
        categoryId: Value(_category),
        day: Value(_day),
        note: Value(emptyToNull(_note.text)),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Расход')),
            ButtonSegment(value: true, label: Text('Доход')),
          ],
          selected: {_income},
          onSelectionChanged: (s) => setState(() {
            _income = s.first;
            _category = null;
          }),
        ),
        const SizedBox(height: 16),
        NumberField(controller: _amount, label: 'Сумма', suffix: '₽', autofocus: widget.existing == null),
        const SizedBox(height: 12),
        StreamBuilder<List<Category>>(
          stream: db.watchCategories(),
          builder: (context, snap) {
            final cats = (snap.data ?? const <Category>[]).where((c) => c.isIncome == _income).toList();
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in cats)
                  ChoiceChip(
                    avatar: Icon(
                      appIcon(c.icon, fallback: 'payments').icon,
                      color: appIcon(c.icon, fallback: 'payments').color,
                    ),
                    label: Text(c.name),
                    selected: _category == c.id,
                    onSelected: (on) => setState(() => _category = on ? c.id : null),
                  ),
              ],
            );
          },
        ),
        DayTile(day: _day, onChanged: (d) => setState(() => _day = d ?? _day)),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Заметка (необязательно)'),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Сохранить')),
        if (widget.existing != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              await db.deleteById(db.transactions, widget.existing!.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Удалить'),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Копилка или долг
// ---------------------------------------------------------------------------

class FundDetailScreen extends StatelessWidget {
  const FundDetailScreen({super.key, required this.fundId});
  final int fundId;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Watch(
      deps: [fundId],
      streams: () => [(db.select(db.funds)..where((t) => t.id.equals(fundId))).watchSingleOrNull(), db.watchFundMoves(fundId)],
      builder: (context, v) {
        final f = v[0] as Fund?;
        if (f == null) return const Scaffold(body: Center(child: Text('Удалено')));
        final theme = Theme.of(context);
        final muted = theme.colorScheme.onSurfaceVariant;
        final moves = v[1] as List<FundMove>;
        final value = fundValue(f, moves.fold<double>(0, (a, m) => a + m.amount));
        final isDebt = f.kind == FundKind.debt;
        final forecast = fundForecast(f, value, recentMonthly: recentMonthlyPace(moves, f.id));
        final progress = _fundProgress(f, value);
        final color = isDebt ? Accent.habits : Accent.money;
        final facts = [
          if (isDebt) 'было ${formatMoney(f.initialAmount)}',
          if (!isDebt && f.target != null) 'цель ${formatMoney(f.target!)}',
          if (f.monthlyAmount != null) '${isDebt ? 'платёж' : 'взнос'} ${formatMoney(f.monthlyAmount!)} в мес.',
          if (isDebt && f.interestRate != null) 'ставка ${formatNumber(f.interestRate!)}%',
        ];
        return Scaffold(
          appBar: AppBar(
            title: Text(f.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FundEditScreen(fund: f))),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ItemIcon(f.icon, size: 56, fallback: isDebt ? 'bank' : 'savings'),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isDebt ? 'Осталось выплатить' : 'Накоплено', style: TextStyle(color: muted)),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(formatMoney(value), style: theme.textTheme.headlineMedium),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(
                              '${(progress.clamp(0, 1) * 100).round()}%',
                              style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 6),
                            Text(isDebt ? 'выплачено' : 'от цели', style: TextStyle(color: muted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ProgressLine(value: progress, color: color, height: 12),
                      ],
                      if (facts.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(spacing: 6, runSpacing: 6, children: [for (final s in facts) Pill(s)]),
                      ],
                      if (forecast.text.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.schedule_rounded, size: 18, color: muted),
                            const SizedBox(width: 8),
                            Expanded(child: Text(forecast.text, style: const TextStyle(height: 1.35))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add_rounded),
                        label: Text(isDebt ? 'Платёж' : 'Внести'),
                        onPressed: () => _moveSheet(context, f, sign: 1),
                      ),
                    ),
                    if (!isDebt) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
                          icon: const Icon(Icons.remove_rounded),
                          label: const Text('Снять'),
                          onPressed: () => _moveSheet(context, f, sign: -1),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SectionTitle('История'),
              if (moves.isEmpty) const Card(child: EmptyHint('Пока ничего', icon: Icons.history_rounded)),
              if (moves.isNotEmpty)
                GroupCard(
                  children: [
                    for (final m in moves)
                      ListTile(
                        leading: IconBadge(
                          m.amount >= 0 ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: m.amount >= 0 ? Accent.habits : _debtColor,
                        ),
                        title: Text(
                          '${m.amount >= 0 ? '+' : '−'}${formatMoney(m.amount.abs())}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text([dayLabel(m.day), if (m.note != null) m.note!].join(' · ')),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () async {
                            if (await confirm(context, 'Удалить запись?', ok: 'Удалить', danger: true)) {
                              await db.deleteById(db.fundMoves, m.id);
                            }
                          },
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _moveSheet(BuildContext context, Fund f, {required int sign}) {
    final amount = TextEditingController(text: f.monthlyAmount == null || sign < 0 ? '' : formatNumber(f.monthlyAmount!));
    final note = TextEditingController();
    var day = todayKey();
    return showFormSheet(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sign < 0 ? 'Снять из «${f.name}»' : (f.kind == FundKind.debt ? 'Платёж по «${f.name}»' : 'Внести в «${f.name}»'),
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            NumberField(controller: amount, label: 'Сумма', suffix: '₽', autofocus: true),
            DayTile(day: day, onChanged: (d) => setState(() => day = d ?? day)),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Заметка (необязательно)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final v = parseNumber(amount.text);
                if (v == null || v <= 0) return showSnack(sheetContext, 'Введи сумму');
                await sheetContext.db.addFundMove(f.id, v * sign, day: day, note: emptyToNull(note.text));
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

class FundEditScreen extends StatefulWidget {
  const FundEditScreen({super.key, this.fund});
  final Fund? fund;

  @override
  State<FundEditScreen> createState() => _FundEditScreenState();
}

class _FundEditScreenState extends State<FundEditScreen> {
  late final _name = TextEditingController(text: widget.fund?.name ?? '');
  late String? _icon = iconKeyFor(widget.fund?.icon);
  late FundKind _kind = widget.fund?.kind ?? FundKind.savings;
  late final _initial = TextEditingController(text: _num(widget.fund?.initialAmount));
  late final _target = TextEditingController(text: _num(widget.fund?.target));
  late final _rate = TextEditingController(text: _num(widget.fund?.interestRate));
  late final _monthly = TextEditingController(text: _num(widget.fund?.monthlyAmount));

  static String _num(double? v) => v == null || v == 0 ? '' : formatNumber(v, maxDecimals: 2);

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return showSnack(context, 'Введи название');
    final isDebt = _kind == FundKind.debt;
    final initial = parseNumber(_initial.text) ?? 0;
    if (isDebt && initial <= 0) return showSnack(context, 'Укажи сумму долга');
    await context.db.saveFund(
      FundsCompanion(
        id: widget.fund == null ? const Value.absent() : Value(widget.fund!.id),
        name: Value(name),
        icon: Value(_icon ?? (isDebt ? 'bank' : 'savings')),
        kind: Value(_kind),
        initialAmount: Value(initial),
        target: Value(isDebt ? null : parseNumber(_target.text)),
        interestRate: Value(isDebt ? parseNumber(_rate.text) : null),
        monthlyAmount: Value(parseNumber(_monthly.text)),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final f = widget.fund;
    final isDebt = _kind == FundKind.debt;
    return Scaffold(
      appBar: AppBar(title: Text(f == null ? 'Новая копилка или долг' : f.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<FundKind>(
            segments: const [
              ButtonSegment(value: FundKind.savings, label: Text('Копилка')),
              ButtonSegment(value: FundKind.debt, label: Text('Долг')),
            ],
            selected: {_kind},
            onSelectionChanged: f == null ? (s) => setState(() => _kind = s.first) : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconField(value: _icon, fallback: isDebt ? 'bank' : 'savings', onChanged: (v) => setState(() => _icon = v)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NumberField(controller: _initial, label: isDebt ? 'Сколько был должен на старте' : 'Сколько уже есть', suffix: '₽'),
          const SizedBox(height: 12),
          if (!isDebt) ...[NumberField(controller: _target, label: 'Цель (необязательно)', suffix: '₽'), const SizedBox(height: 12)],
          if (isDebt) ...[
            NumberField(controller: _rate, label: 'Ставка, % годовых (необязательно)', suffix: '%'),
            const SizedBox(height: 12),
          ],
          NumberField(controller: _monthly, label: isDebt ? 'Платёж в месяц' : 'Плановый взнос в месяц (необязательно)', suffix: '₽'),
          const SizedBox(height: 8),
          Text(
            isDebt ? 'Остаток считается так: сумма на старте минус все платежи. Срок закрытия считается по платежу и ставке.' : 'Баланс считается так: сумма на старте плюс взносы минус снятия. Если взнос не указан, срок считается по среднему за 3 месяца.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Сохранить')),
          if (f != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.archive_outlined),
              label: const Text('В архив'),
              onPressed: () async {
                await db.setArchived(db.funds, f.id, true);
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Удалить вместе с историей'),
              onPressed: () async {
                if (await confirm(
                  context,
                  'Удалить «${f.name}»?',
                  text: 'Вся история взносов и платежей удалится.',
                  ok: 'Удалить',
                  danger: true,
                )) {
                  await db.deleteById(db.funds, f.id);
                  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Категории
// ---------------------------------------------------------------------------

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return ScrollFabScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Категории')),
        floatingActionButton: ScrollFab(
          child: FloatingActionButton(heroTag: null, onPressed: () => _edit(context, null), child: const Icon(Icons.add_rounded)),
        ),
        body: StreamBuilder<List<Category>>(
          stream: db.watchCategories(),
          builder: (context, snap) {
            final cats = snap.data ?? const <Category>[];
            return ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                const SectionTitle('Расходы'),
                GroupCard(children: [for (final c in cats.where((c) => !c.isIncome)) _tile(context, c)]),
                const SectionTitle('Доходы'),
                GroupCard(children: [for (final c in cats.where((c) => c.isIncome)) _tile(context, c)]),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, Category c) => ListTile(
    leading: ItemIcon(c.icon, size: 40, fallback: 'payments'),
    title: Text(c.name),
    trailing: const Icon(Icons.chevron_right_rounded),
    subtitle: c.monthlyLimit == null ? null : Text('лимит ${formatMoney(c.monthlyLimit!)} в месяц'),
    onTap: () => _edit(context, c),
  );

  Future<void> _edit(BuildContext context, Category? c) {
    final name = TextEditingController(text: c?.name ?? '');
    var icon = iconKeyFor(c?.icon) ?? 'payments';
    final limit = TextEditingController(text: c?.monthlyLimit == null ? '' : formatNumber(c!.monthlyLimit!));
    var income = c?.isIncome ?? false;
    return showFormSheet(
      context,
      (sheet) => StatefulBuilder(
        builder: (sheet, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Расход')),
                ButtonSegment(value: true, label: Text('Доход')),
              ],
              selected: {income},
              onSelectionChanged: (s) => setState(() => income = s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconField(value: icon, fallback: 'payments', onChanged: (v) => setState(() => icon = v)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: name,
                    autofocus: c == null,
                    decoration: const InputDecoration(labelText: 'Название'),
                  ),
                ),
              ],
            ),
            if (!income) ...[
              const SizedBox(height: 12),
              NumberField(controller: limit, label: 'Лимит в месяц (необязательно)', suffix: '₽'),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return showSnack(sheet, 'Введи название');
                await sheet.db.saveCategory(
                  CategoriesCompanion(
                    id: c == null ? const Value.absent() : Value(c.id),
                    name: Value(name.text.trim()),
                    icon: Value(icon),
                    isIncome: Value(income),
                    monthlyLimit: Value(income ? null : parseNumber(limit.text)),
                  ),
                );
                if (sheet.mounted) Navigator.pop(sheet);
              },
              child: const Text('Сохранить'),
            ),
            if (c != null)
              TextButton(
                onPressed: () async {
                  // Категорию прячем, а не удаляем: старые операции её помнят.
                  await sheet.db.setArchived(sheet.db.categories, c.id, true);
                  if (sheet.mounted) Navigator.pop(sheet);
                },
                child: const Text('Скрыть категорию'),
              ),
          ],
        ),
      ),
    );
  }
}
