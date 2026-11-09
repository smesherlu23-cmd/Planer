import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/money_queries.dart';
import '../../data/queries.dart';
import '../../logic/calc.dart';
import '../../logic/finance.dart';
import '../common.dart';
import '../icons.dart';
import '../money_screen.dart';
import '../theme.dart';

enum OpFilter { all, expense, income, transfer }

/// Все операции месяца: поиск, фильтры по типу и счёту, итоги по дням.
class MoneyOperationsTab extends StatefulWidget {
  const MoneyOperationsTab({super.key});

  @override
  State<MoneyOperationsTab> createState() => _MoneyOperationsTabState();
}

class _MoneyOperationsTabState extends State<MoneyOperationsTab> with AutomaticKeepAliveClientMixin {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _query = TextEditingController();
  var _filter = OpFilter.all;
  int? _account;

  int get _from => dayKey(_month);
  int get _to => dayKey(DateTime(_month.year, _month.month + 1, 0));

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final db = context.db;
    final theme = Theme.of(context);
    return Watch(
      deps: [_from],
      streams: () => [
        db.watchTransactions(from: _from, to: _to),
        db.watchTransfers(from: _from, to: _to),
        db.select(db.categories).watch(),
        db.select(db.accounts).watch(),
      ],
      builder: (context, v) {
        final cats = {for (final c in v[2] as List<Category>) c.id: c};
        final allAccounts = v[3] as List<Account>;
        final accounts = {for (final a in allAccounts) a.id: a};
        final q = _query.text;
        var txs = (v[0] as List<Transaction>).where((t) {
          if (_account != null && t.accountId != _account) return false;
          if (_filter == OpFilter.transfer) return false;
          if (_filter == OpFilter.expense && t.isIncome) return false;
          if (_filter == OpFilter.income && !t.isIncome) return false;
          return matchesQuery(q, note: t.note, category: cats[t.categoryId]?.name, amount: t.amount);
        }).toList();
        final transfers = (v[1] as List<Transfer>).where((t) {
          if (_filter == OpFilter.expense || _filter == OpFilter.income) return false;
          if (_account != null && t.fromAccountId != _account && t.toAccountId != _account) return false;
          return matchesQuery(q, note: t.note, category: 'перевод', amount: t.amount);
        }).toList();
        final expenses = txs.where((t) => !t.isIncome).fold<double>(0, (a, t) => a + t.amount);
        final income = txs.where((t) => t.isIncome).fold<double>(0, (a, t) => a + t.amount);
        final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
        return ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                  ),
                  Expanded(
                    child: Text(monthTitle(_month.year, _month.month), textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Поиск: заметка, категория, сумма',
                  suffixIcon: q.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(_query.clear)),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final (f, label) in const [
                    (OpFilter.all, 'Все'),
                    (OpFilter.expense, 'Расходы'),
                    (OpFilter.income, 'Доходы'),
                    (OpFilter.transfer, 'Переводы'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(label: Text(label), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
                    ),
                  if (allAccounts.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    for (final a in allAccounts.where((a) => !a.archived))
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          avatar: Icon(appIcon(a.icon, fallback: 'card').icon, size: 18),
                          label: Text(a.name),
                          selected: _account == a.id,
                          onSelected: (on) => setState(() => _account = on ? a.id : null),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: Wrap(
                spacing: 16,
                children: [
                  Text('Расходы ${formatMoney(expenses)}', style: muted),
                  Text('Доходы ${formatMoney(income)}', style: muted),
                  Text('${txs.length + transfers.length} опер.', style: muted),
                ],
              ),
            ),
            if (txs.isEmpty && transfers.isEmpty)
              Card(
                child: EmptyHint(
                  q.isNotEmpty || _filter != OpFilter.all || _account != null ? 'Ничего не нашлось' : 'За этот месяц операций нет',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ...operationGroups(context, txs: txs, transfers: transfers, categories: cats, accounts: accounts),
          ],
        );
      },
    );
  }
}

/// Операции и переводы, сгруппированные по дням, с суммой расходов за день.
/// [perspective]: счёт, с точки зрения которого показывать знак перевода.
List<Widget> operationGroups(
  BuildContext context, {
  required List<Transaction> txs,
  required List<Transfer> transfers,
  required Map<int, Category> categories,
  required Map<int, Account> accounts,
  int? perspective,
}) {
  final byDay = <int, List<Object>>{};
  for (final t in txs) {
    byDay.putIfAbsent(t.day, () => []).add(t);
  }
  for (final t in transfers) {
    byDay.putIfAbsent(t.day, () => []).add(t);
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in days) ...[
      _DayHeader(day: day, items: byDay[day]!),
      GroupCard(
        children: [
          for (final o in byDay[day]!)
            if (o is Transaction)
              TransactionTile(t: o, category: categories[o.categoryId], account: accounts[o.accountId], showAccount: perspective == null)
            else if (o is Transfer)
              _TransferTile(t: o, accounts: accounts, perspective: perspective),
        ],
      ),
    ],
  ];
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.items});
  final int day;
  final List<Object> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spent = items.whereType<Transaction>().where((t) => !t.isIncome).fold<double>(0, (a, t) => a + t.amount);
    final label = dayLabel(day);
    final muted = theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
      child: Row(
        children: [
          Expanded(child: Text(label[0].toUpperCase() + label.substring(1), style: muted)),
          if (spent > 0) Text('−${formatMoney(spent)}', style: muted),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.t, required this.category, this.account, this.showAccount = true});
  final Transaction t;
  final Category? category;
  final Account? account;
  final bool showAccount;

  @override
  Widget build(BuildContext context) {
    final sub = [if (t.note != null) t.note!, if (showAccount && account != null) account!.name].join(' · ');
    return ListTile(
      leading: ItemIcon(category?.icon, size: 40, fallback: 'payments'),
      title: Text(category?.name ?? (t.isIncome ? 'Доход' : 'Без категории')),
      subtitle: sub.isEmpty ? null : Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        '${t.isIncome ? '+' : '−'}${formatMoney(t.amount)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: t.isIncome ? Accent.habits : null, fontWeight: FontWeight.w700),
      ),
      onTap: () => showTransactionSheet(context, existing: t),
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({required this.t, required this.accounts, this.perspective});
  final Transfer t;
  final Map<int, Account> accounts;
  final int? perspective;

  @override
  Widget build(BuildContext context) {
    final from = accounts[t.fromAccountId]?.name ?? '?';
    final to = accounts[t.toAccountId]?.name ?? '?';
    final sign = perspective == null ? '' : (perspective == t.toAccountId ? '+' : '−');
    return ListTile(
      leading: const ColorIcon(Icons.swap_horiz_rounded, color: Accent.trackers, size: 40),
      title: const Text('Перевод'),
      subtitle: Text(['$from → $to', if (t.note != null) t.note!].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        '$sign${formatMoney(t.amount)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Accent.trackers),
      ),
      onTap: () => showTransferSheet(context, t),
    );
  }
}
