import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import '../logic/values.dart';
import 'common.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Деньги'),
        actions: [
          IconButton(
            tooltip: 'Категории',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showTransactionSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Операция'),
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
        ],
        builder: (context, v) {
          final txs = v[0] as List<Transaction>;
          final cats = v[1] as List<Category>;
          final funds = v[2] as List<Fund>;
          final values = v[3] as Map<int, double>;
          final moves = v[4] as List<FundMove>;
          final allCats = {for (final c in v[5] as List<Category>) c.id: c};
          final expenses = txs.where((t) => !t.isIncome).fold<double>(0, (a, t) => a + t.amount);
          final income = txs.where((t) => t.isIncome).fold<double>(0, (a, t) => a + t.amount);
          final byCat = <int?, double>{};
          for (final t in txs.where((t) => !t.isIncome)) {
            byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
          }
          final catRows = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final limited = cats.where((c) => c.monthlyLimit != null && !c.isIncome && !byCat.containsKey(c.id));

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              const SectionTitle('Копилки и долги'),
              if (funds.isEmpty)
                const EmptyHint('Копилка показывает, сколько накоплено и когда дойдёшь до цели. Долг показывает остаток и срок закрытия.'),
              for (final f in funds) _FundCard(fund: f, value: values[f.id] ?? fundValue(f, 0), recent: recentMonthlyPace(moves, f.id)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Копилка или долг'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FundEditScreen())),
                  ),
                ),
              ),
              const Divider(),
              Row(
                children: [
                  IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left)),
                  Expanded(
                    child: Text(
                      monthTitle(_month.year, _month.month),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right)),
                ],
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _Sum(label: 'Расходы', value: expenses),
                      _Sum(label: 'Доходы', value: income),
                      _Sum(label: 'Разница', value: income - expenses),
                    ],
                  ),
                ),
              ),
              if (catRows.isNotEmpty || limited.isNotEmpty) const SectionTitle('Расходы по категориям'),
              for (final e in catRows) _CategoryRow(category: allCats[e.key], spent: e.value, total: expenses),
              for (final c in limited) _CategoryRow(category: c, spent: 0, total: expenses),
              const SectionTitle('Операции'),
              if (txs.isEmpty) const EmptyHint('За этот месяц операций нет'),
              for (final t in txs)
                ListTile(
                  leading: Text(allCats[t.categoryId]?.icon ?? (t.isIncome ? '💵' : '💸'), style: const TextStyle(fontSize: 22)),
                  title: Text(allCats[t.categoryId]?.name ?? (t.isIncome ? 'Доход' : 'Без категории')),
                  subtitle: Text([dayLabel(t.day), if (t.note != null) t.note!].join(' · ')),
                  trailing: Text(
                    '${t.isIncome ? '+' : '−'}${formatMoney(t.amount)}',
                    style: TextStyle(color: t.isIncome ? Colors.green : null, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => showTransactionSheet(context, existing: t),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Sum extends StatelessWidget {
  const _Sum({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(child: Text(formatMoney(value), style: Theme.of(context).textTheme.titleMedium)),
        ],
      ),
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
    final limit = category?.monthlyLimit;
    final over = limit != null && spent > limit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${category?.icon ?? '💸'} ${category?.name ?? 'Без категории'}'),
              const Spacer(),
              Text(
                limit == null ? formatMoney(spent) : '${formatMoney(spent)} из ${formatMoney(limit)}',
                style: TextStyle(color: over ? Theme.of(context).colorScheme.error : null),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ProgressLine(
            value: limit != null ? (limit == 0 ? 1 : spent / limit) : (total == 0 ? 0 : spent / total),
            color: over ? Theme.of(context).colorScheme.error : null,
          ),
        ],
      ),
    );
  }
}

class _FundCard extends StatelessWidget {
  const _FundCard({required this.fund, required this.value, required this.recent});
  final Fund fund;
  final double value;
  final double? recent;

  @override
  Widget build(BuildContext context) {
    final f = fund;
    final isDebt = f.kind == FundKind.debt;
    final forecast = fundForecast(f, value, recentMonthly: recent);
    double? progress;
    String line;
    if (isDebt) {
      progress = f.initialAmount <= 0 ? 1 : 1 - value / f.initialAmount;
      line = 'Осталось ${formatMoney(value)} из ${formatMoney(f.initialAmount)}';
    } else if (f.target != null) {
      progress = f.target! <= 0 ? 1 : value / f.target!;
      line = '${formatMoney(value)} из ${formatMoney(f.target!)}';
    } else {
      line = formatMoney(value);
    }
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FundDetailScreen(fundId: f.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(f.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f.name, style: Theme.of(context).textTheme.titleMedium)),
                  Text(isDebt ? 'долг' : 'копилка', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 6),
              Text(line),
              if (progress != null) ...[const SizedBox(height: 6), ProgressLine(value: progress)],
              if (forecast.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(forecast.text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                    label: Text('${c.icon} ${c.name}'),
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
        final moves = v[1] as List<FundMove>;
        final value = fundValue(f, moves.fold<double>(0, (a, m) => a + m.amount));
        final isDebt = f.kind == FundKind.debt;
        final forecast = fundForecast(f, value, recentMonthly: recentMonthlyPace(moves, f.id));
        return Scaffold(
          appBar: AppBar(
            title: Text('${f.icon} ${f.name}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FundEditScreen(fund: f))),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(isDebt ? 'Осталось выплатить' : 'Накоплено', style: Theme.of(context).textTheme.titleSmall),
              Text(formatMoney(value), style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                [
                  if (isDebt) 'было ${formatMoney(f.initialAmount)}',
                  if (!isDebt && f.target != null) 'цель ${formatMoney(f.target!)}',
                  if (f.monthlyAmount != null) '${isDebt ? 'платёж' : 'взнос'} ${formatMoney(f.monthlyAmount!)} в месяц',
                  if (isDebt && f.interestRate != null) 'ставка ${formatNumber(f.interestRate!)}%',
                ].join(' · '),
              ),
              if (forecast.text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(forecast.text)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(isDebt ? 'Платёж' : 'Внести'),
                    onPressed: () => _moveSheet(context, f, sign: 1),
                  ),
                  if (!isDebt)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.remove),
                      label: const Text('Снять'),
                      onPressed: () => _moveSheet(context, f, sign: -1),
                    ),
                ],
              ),
              const SectionTitle('История'),
              if (moves.isEmpty) const EmptyHint('Пока ничего'),
              for (final m in moves)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${m.amount >= 0 ? '+' : '−'}${formatMoney(m.amount.abs())}'),
                  subtitle: Text([dayLabel(m.day), if (m.note != null) m.note!].join(' · ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (await confirm(context, 'Удалить запись?', ok: 'Удалить', danger: true)) {
                        await db.deleteById(db.fundMoves, m.id);
                      }
                    },
                  ),
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
  late final _icon = TextEditingController(text: widget.fund?.icon ?? '🐷');
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
        icon: Value(emptyToNull(_icon.text) ?? (isDebt ? '🏦' : '🐷')),
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
              EmojiField(controller: _icon),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Категории')),
      floatingActionButton: FloatingActionButton(heroTag: null, onPressed: () => _edit(context, null), child: const Icon(Icons.add)),
      body: StreamBuilder<List<Category>>(
        stream: db.watchCategories(),
        builder: (context, snap) {
          final cats = snap.data ?? const <Category>[];
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              const SectionTitle('Расходы'),
              for (final c in cats.where((c) => !c.isIncome)) _tile(context, c),
              const SectionTitle('Доходы'),
              for (final c in cats.where((c) => c.isIncome)) _tile(context, c),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, Category c) => ListTile(
    leading: Text(c.icon, style: const TextStyle(fontSize: 22)),
    title: Text(c.name),
    subtitle: c.monthlyLimit == null ? null : Text('лимит ${formatMoney(c.monthlyLimit!)} в месяц'),
    onTap: () => _edit(context, c),
  );

  Future<void> _edit(BuildContext context, Category? c) {
    final name = TextEditingController(text: c?.name ?? '');
    final icon = TextEditingController(text: c?.icon ?? '💸');
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
                EmojiField(controller: icon),
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
                    icon: Value(emptyToNull(icon.text) ?? '💸'),
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
