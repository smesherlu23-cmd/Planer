import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/icon_keys.dart';
import '../data/money_queries.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import '../logic/values.dart';
import 'money/accounts.dart';
import 'money/analytics_tab.dart';
import 'money/operations_tab.dart';
import 'money/overview_tab.dart';
import 'money/plans_tab.dart';
import 'money_plan_screen.dart';
import 'common.dart';
import 'icons.dart';
import 'theme.dart';

const debtColor = Color(0xFFEF4444);

/// Деньги как отдельное приложение: обзор, операции, аналитика и планы.
class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 4, vsync: this)..addListener(_showFab);
  final _body = GlobalKey();

  /// На новой вкладке кнопка «Операция» снова видна, даже если на прошлой её спрятала прокрутка.
  void _showFab() {
    final ctx = _body.currentContext;
    if (ctx == null) return;
    UserScrollNotification(
      metrics: FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 0,
        pixels: 0,
        viewportDimension: 0,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      ),
      context: ctx,
      direction: ScrollDirection.forward,
    ).dispatch(ctx);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        body: Column(
          key: _body,
          children: [
            PageHeader(
              overline: 'счета, траты и планы',
              title: 'Деньги',
              actions: [
                IconButton(
                  tooltip: 'Счета',
                  icon: const Icon(Icons.account_balance_wallet_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                ),
                IconButton(
                  tooltip: 'Категории',
                  icon: const Icon(Icons.category_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                ),
              ],
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Accent.money,
              labelColor: Theme.of(context).colorScheme.onSurface,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Обзор'),
                Tab(text: 'Операции'),
                Tab(text: 'Аналитика'),
                Tab(text: 'Планы'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  MoneyOverviewTab(openTab: (i) => _tabs.animateTo(i)),
                  const MoneyOperationsTab(),
                  const MoneyAnalyticsTab(),
                  const MoneyPlansTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryLimitRow extends StatelessWidget {
  const CategoryLimitRow({super.key, required this.category, required this.spent, required this.total});
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
double? fundProgress(Fund f, double value) {
  if (f.kind == FundKind.debt) return f.initialAmount <= 0 ? 1 : 1 - value / f.initialAmount;
  if (f.target != null) return f.target! <= 0 ? 1 : value / f.target!;
  return null;
}

class FundCard extends StatelessWidget {
  const FundCard({super.key, required this.fund, required this.value, required this.recent});
  final Fund fund;
  final double value;
  final double? recent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = fund;
    final isDebt = f.kind == FundKind.debt;
    final forecast = fundForecast(f, value, recentMonthly: recent);
    final progress = fundProgress(f, value);
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
                            Pill(isDebt ? 'долг' : 'копилка', color: isDebt ? debtColor : Accent.money),
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

/// Новая операция или правка старой. [initialKind] открывает сразу перевод или доход.
Future<void> showTransactionSheet(BuildContext context, {Transaction? existing, TxKind initialKind = TxKind.expense}) {
  return showFormSheet(context, (_) => _TransactionForm(existing: existing, initialKind: initialKind));
}

enum TxKind { expense, income, transfer }

class _TransactionForm extends StatefulWidget {
  const _TransactionForm({this.existing, this.existingTransfer, this.initialKind = TxKind.expense});
  final Transaction? existing;
  final Transfer? existingTransfer;
  final TxKind initialKind;

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  late final Transaction? _tx = widget.existing;
  late final Transfer? _tr = widget.existingTransfer;
  late final _amount = TextEditingController(text: _initialAmount == null ? '' : formatNumber(_initialAmount!, maxDecimals: 2));
  late final _note = TextEditingController(text: _tx?.note ?? _tr?.note ?? '');
  late TxKind _kind = _tr != null ? TxKind.transfer : (_tx == null ? widget.initialKind : (_tx.isIncome ? TxKind.income : TxKind.expense));
  late int? _category = _tx?.categoryId;
  late int? _account = _tx?.accountId ?? _tr?.fromAccountId;
  late int? _toAccount = _tr?.toAccountId;
  late int _day = _tx?.day ?? _tr?.day ?? todayKey();
  var _accountTouched = false;

  double? get _initialAmount => _tx?.amount ?? _tr?.amount;

  bool get _editing => _tx != null || _tr != null;

  Future<void> _save() async {
    final db = context.db;
    final amount = parseNumber(_amount.text);
    if (amount == null || amount <= 0) return showSnack(context, 'Введи сумму');
    if (_kind == TxKind.transfer) {
      if (_account == null || _toAccount == null) return showSnack(context, 'Выбери, откуда и куда');
      if (_account == _toAccount) return showSnack(context, 'Счета должны быть разные');
      if (_tx != null) await db.deleteById(db.transactions, _tx.id);
      await db.saveTransfer(
        TransfersCompanion(
          id: _tr == null ? const Value.absent() : Value(_tr.id),
          fromAccountId: Value(_account!),
          toAccountId: Value(_toAccount!),
          amount: Value(amount),
          day: Value(_day),
          note: Value(emptyToNull(_note.text)),
        ),
      );
    } else {
      if (_tr != null) await db.deleteById(db.transfers, _tr.id);
      await db.saveTransaction(
        TransactionsCompanion(
          id: _tx == null ? const Value.absent() : Value(_tx.id),
          amount: Value(amount),
          isIncome: Value(_kind == TxKind.income),
          categoryId: Value(_category),
          accountId: Value(_account),
          day: Value(_day),
          note: Value(emptyToNull(_note.text)),
        ),
      );
    }
    if (_account != null) await db.setSetting(keyLastAccount, '$_account');
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final db = context.db;
    if (_tx != null) await db.deleteById(db.transactions, _tx.id);
    if (_tr != null) await db.deleteById(db.transfers, _tr.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final theme = Theme.of(context);
    return Watch(
      streams: () => [db.watchCategories(), db.watchAccounts(), db.watchSetting(keyLastAccount)],
      builder: (context, v) {
        final allCats = v[0] as List<Category>;
        final accounts = v[1] as List<Account>;
        final last = int.tryParse((v[2] as String?) ?? '');
        if (!_editing && !_accountTouched && _account == null && accounts.isNotEmpty) {
          _account = accounts.any((a) => a.id == last) ? last : accounts.first.id;
        }
        final cats = allCats.where((c) => c.isIncome == (_kind == TxKind.income)).toList();
        final color = switch (_kind) {
          TxKind.expense => theme.colorScheme.onSurface,
          TxKind.income => Accent.habits,
          TxKind.transfer => Accent.trackers,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<TxKind>(
              segments: [
                const ButtonSegment(value: TxKind.expense, label: Text('Расход')),
                const ButtonSegment(value: TxKind.income, label: Text('Доход')),
                if (accounts.length >= 2 || _tr != null) const ButtonSegment(value: TxKind.transfer, label: Text('Перевод')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() {
                _kind = s.first;
                _category = null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              autofocus: !_editing,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w700),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))],
              decoration: InputDecoration(
                hintText: '0',
                suffixText: '₽',
                prefixText: switch (_kind) {
                  TxKind.expense => '−',
                  TxKind.income => '+',
                  TxKind.transfer => '',
                },
              ),
            ),
            const SizedBox(height: 14),
            if (_kind == TxKind.transfer) ...[
              _label(context, 'Откуда'),
              AccountChips(accounts: accounts, selected: _account, onSelected: (id) => setState(() => _account = id)),
              const SizedBox(height: 10),
              _label(context, 'Куда'),
              AccountChips(accounts: accounts, selected: _toAccount, onSelected: (id) => setState(() => _toAccount = id)),
            ] else ...[
              _label(context, 'Категория'),
              Wrap(
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
              ),
              if (accounts.isNotEmpty) ...[
                const SizedBox(height: 12),
                _label(context, _kind == TxKind.income ? 'На счёт' : 'Со счёта'),
                AccountChips(
                  accounts: accounts,
                  selected: _account,
                  onSelected: (id) => setState(() {
                    _account = id;
                    _accountTouched = true;
                  }),
                ),
              ],
            ],
            DayTile(day: _day, onChanged: (d) => setState(() => _day = d ?? _day)),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Заметка (необязательно)'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Сохранить')),
            if (_editing)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                onPressed: _delete,
                child: const Text('Удалить'),
              ),
          ],
        );
      },
    );
  }
}

Widget _label(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
);

/// Правка перевода между счетами.
Future<void> showTransferSheet(BuildContext context, Transfer existing) {
  return showFormSheet(context, (_) => _TransactionForm(existingTransfer: existing));
}

/// Выбор счёта чипами. [allowNone]: можно снять выбор.
class AccountChips extends StatelessWidget {
  const AccountChips({super.key, required this.accounts, required this.selected, required this.onSelected, this.allowNone = false});
  final List<Account> accounts;
  final int? selected;
  final ValueChanged<int?> onSelected;
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final a in accounts)
          ChoiceChip(
            avatar: Icon(
              appIcon(a.icon, fallback: 'card').icon,
              color: appIcon(a.icon, fallback: 'card').color,
            ),
            label: Text(a.name),
            selected: selected == a.id,
            onSelected: (on) {
              if (on) {
                onSelected(a.id);
              } else if (allowNone) {
                onSelected(null);
              }
            },
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
        final progress = fundProgress(f, value);
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
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.insights_rounded),
                  label: Text(isDebt ? 'Как закрыть быстрее' : 'Когда накоплю при другом взносе'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoneyPlanScreen())),
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
                          color: m.amount >= 0 ? Accent.habits : debtColor,
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
    int? account;
    var accountTouched = false;
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
            Watch(
              streams: () => [sheetContext.db.watchAccounts(), sheetContext.db.watchSetting(keyLastAccount)],
              builder: (context, v) {
                final accounts = v[0] as List<Account>;
                if (accounts.isEmpty) return const SizedBox.shrink();
                final last = int.tryParse((v[1] as String?) ?? '');
                if (!accountTouched && account == null) account = accounts.any((a) => a.id == last) ? last : accounts.first.id;
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, sign < 0 ? 'На счёт' : 'Со счёта'),
                      AccountChips(
                        accounts: accounts,
                        selected: account,
                        allowNone: true,
                        onSelected: (id) => setState(() {
                          account = id;
                          accountTouched = true;
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
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
                final db = sheetContext.db;
                await db
                    .into(db.fundMoves)
                    .insert(
                      FundMovesCompanion.insert(
                        fundId: f.id,
                        amount: v * sign,
                        day: day,
                        note: Value(emptyToNull(note.text)),
                        accountId: Value(account),
                      ),
                    );
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
