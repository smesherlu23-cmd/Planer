import 'package:drift/drift.dart' show Value, OrderingTerm, BooleanExpressionOperators;
import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/icon_keys.dart';
import '../../data/money_queries.dart';
import '../../data/queries.dart';
import '../../logic/calc.dart';
import '../common.dart';
import '../icons.dart';
import '../money_screen.dart';
import '../theme.dart';
import 'operations_tab.dart';

/// Все счета с остатками и общей суммой.
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Scaffold(
      appBar: AppBar(title: const Text('Счета')),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountEditScreen())),
        child: const Icon(Icons.add_rounded),
      ),
      body: Watch(
        streams: () => [db.watchAccounts(), db.watchAccounts(archived: true), db.watchAccountBalances()],
        builder: (context, v) {
          final accounts = v[0] as List<Account>;
          final archived = v[1] as List<Account>;
          final balances = v[2] as Map<int, double>;
          final total = accounts.fold<double>(0, (a, x) => a + (balances[x.id] ?? 0));
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (accounts.isEmpty)
                const Card(
                  child: EmptyHint(
                    'Счёт это место, где лежат деньги: карта, наличные, накопительный счёт. '
                    'Укажи, сколько на каждом сейчас, и приложение будет само вести остаток по операциям.',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text('Всего ${formatMoney(total)}', style: Theme.of(context).textTheme.headlineSmall),
                ),
                GroupCard(
                  children: [for (final a in accounts) AccountTile(account: a, balance: balances[a.id] ?? 0)],
                ),
              ],
              if (accounts.length >= 2)
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Перевести между счетами'),
                    onPressed: () => showTransactionSheet(context, initialKind: TxKind.transfer),
                  ),
                ),
              if (archived.isNotEmpty) ...[
                const SectionTitle('В архиве'),
                GroupCard(
                  children: [for (final a in archived) AccountTile(account: a, balance: balances[a.id] ?? 0)],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class AccountTile extends StatelessWidget {
  const AccountTile({super.key, required this.account, required this.balance});
  final Account account;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ItemIcon(account.icon, size: 40, fallback: 'card'),
      title: Text(account.name),
      trailing: Text(
        formatMoney(balance),
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700, color: balance < 0 ? Theme.of(context).colorScheme.error : null),
      ),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountDetailScreen(accountId: account.id))),
    );
  }
}

/// Счёт: остаток и все его операции.
class AccountDetailScreen extends StatelessWidget {
  const AccountDetailScreen({super.key, required this.accountId});
  final int accountId;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Watch(
      deps: [accountId],
      streams: () => [
        (db.select(db.accounts)..where((t) => t.id.equals(accountId))).watchSingleOrNull(),
        db.watchAccountBalances(),
        (db.select(db.transactions)
              ..where((t) => t.accountId.equals(accountId))
              ..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.at)])
              ..limit(200))
            .watch(),
        (db.select(db.transfers)..where((t) => t.fromAccountId.equals(accountId) | t.toAccountId.equals(accountId))).watch(),
        (db.select(db.categories)).watch(),
        (db.select(db.accounts)).watch(),
      ],
      builder: (context, v) {
        final a = v[0] as Account?;
        if (a == null) return const Scaffold(body: Center(child: Text('Удалено')));
        final balance = (v[1] as Map<int, double>)[a.id] ?? 0;
        final txs = v[2] as List<Transaction>;
        final transfers = v[3] as List<Transfer>;
        final cats = {for (final c in v[4] as List<Category>) c.id: c};
        final accounts = {for (final x in v[5] as List<Account>) x.id: x};
        final theme = Theme.of(context);
        final dark = theme.brightness == Brightness.dark;
        return Scaffold(
          appBar: AppBar(
            title: Text(a.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountEditScreen(account: a, balance: balance),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              HeroCard(
                colors: dark ? const [Color(0xFF1E3A8A), Color(0xFF4338CA)] : const [Color(0xFF2563EB), Color(0xFF6366F1)],
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Остаток',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(formatMoney(balance), style: theme.textTheme.displaySmall?.copyWith(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    Icon(appIcon(a.icon, fallback: 'card').icon, color: Colors.white70, size: 40),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Сверить остаток'),
                        onPressed: () => showBalanceSheet(context, a, balance),
                      ),
                    ),
                    if (accounts.length >= 2) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Перевод'),
                          onPressed: () => showTransactionSheet(context, initialKind: TxKind.transfer),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SectionTitle('Операции'),
              if (txs.isEmpty && transfers.isEmpty) const Card(child: EmptyHint('Пока операций нет', icon: Icons.receipt_long_outlined)),
              ...operationGroups(context, txs: txs, transfers: transfers, categories: cats, accounts: accounts, perspective: a.id),
            ],
          ),
        );
      },
    );
  }
}

/// Сверить остаток с банком: приложение подстроит начальный остаток, история не меняется.
Future<void> showBalanceSheet(BuildContext context, Account a, double current) {
  final c = TextEditingController(text: formatNumber(current, maxDecimals: 2));
  return showFormSheet(
    context,
    (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Сколько на «${a.name}» сейчас', style: Theme.of(sheet).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Посмотри остаток в банке или посчитай наличные. Разница не попадёт в расходы.',
          style: TextStyle(color: Theme.of(sheet).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        NumberField(controller: c, label: 'Остаток', suffix: '₽', autofocus: true, allowNegative: true),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            final v = parseNumber(c.text);
            if (v == null) return showSnack(sheet, 'Введи сумму');
            await sheet.db.setAccountBalance(a.id, v, current);
            if (sheet.mounted) Navigator.pop(sheet);
          },
          child: const Text('Сохранить'),
        ),
      ],
    ),
  );
}

class AccountEditScreen extends StatefulWidget {
  const AccountEditScreen({super.key, this.account, this.balance});
  final Account? account;
  final double? balance;

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  late final _name = TextEditingController(text: widget.account?.name ?? '');
  late String? _icon = iconKeyFor(widget.account?.icon) ?? 'card';
  late final _balance = TextEditingController(text: widget.balance == null ? '' : formatNumber(widget.balance!, maxDecimals: 2));

  Future<void> _save() async {
    final db = context.db;
    final name = _name.text.trim();
    if (name.isEmpty) return showSnack(context, 'Введи название');
    final balance = parseNumber(_balance.text) ?? 0;
    final a = widget.account;
    if (a == null) {
      await db.saveAccount(AccountsCompanion.insert(name: name, icon: Value(_icon ?? 'card'), initialBalance: Value(balance)));
    } else {
      await db.saveAccount(AccountsCompanion(id: Value(a.id), name: Value(name), icon: Value(_icon ?? 'card')));
      if (widget.balance != null && (balance - widget.balance!).abs() >= 0.005) await db.setAccountBalance(a.id, balance, widget.balance!);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.account;
    final db = context.db;
    return Scaffold(
      appBar: AppBar(title: Text(a == null ? 'Новый счёт' : a.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconField(value: _icon, fallback: 'card', onChanged: (v) => setState(() => _icon = v)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  autofocus: a == null,
                  decoration: const InputDecoration(labelText: 'Название', hintText: 'Карта, Наличные, Накопительный'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final (name, icon) in const [('Карта', 'card'), ('Наличные', 'wallet'), ('Накопительный', 'bank')])
                ActionChip(
                  label: Text(name),
                  onPressed: () => setState(() {
                    _name.text = name;
                    _icon = icon;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          NumberField(controller: _balance, label: 'Сколько на счёте сейчас', suffix: '₽', allowNegative: true),
          const SizedBox(height: 8),
          Text(
            'Дальше остаток считается сам: доходы плюс, расходы минус, переводы и взносы в копилки тоже учитываются.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Сохранить')),
          if (a != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: Icon(a.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
              label: Text(a.archived ? 'Вернуть из архива' : 'В архив'),
              onPressed: () async {
                await db.saveAccount(AccountsCompanion(id: Value(a.id), archived: Value(!a.archived)));
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Удалить счёт'),
              onPressed: () async {
                if (await confirm(
                  context,
                  'Удалить «${a.name}»?',
                  text: 'Операции останутся, но без счёта. Переводы с этим счётом удалятся.',
                  ok: 'Удалить',
                  danger: true,
                )) {
                  await db.deleteById(db.accounts, a.id);
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

/// Счета на обзоре: горизонтальная лента карточек.
class AccountsStrip extends StatelessWidget {
  const AccountsStrip({super.key, required this.accounts, required this.balances});
  final List<Account> accounts;
  final Map<int, double> balances;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final a in accounts)
            SizedBox(
              width: 150,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountDetailScreen(accountId: a.id))),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              appIcon(a.icon, fallback: 'card').icon,
                              color: appIcon(a.icon, fallback: 'card').color,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(a.name, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge),
                            ),
                          ],
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatMoney(balances[a.id] ?? 0),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: (balances[a.id] ?? 0) < 0 ? theme.colorScheme.error : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: 96,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountEditScreen())),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: Accent.money),
                    SizedBox(height: 4),
                    Text('Счёт', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
