import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/money_queries.dart';
import '../../data/queries.dart';
import '../../logic/calc.dart';
import '../../logic/finance.dart';
import '../../logic/values.dart';
import '../common.dart';
import '../icons.dart';
import '../money_screen.dart';
import '../theme.dart';
import 'accounts.dart';
import 'recurring.dart';

/// Главная денег: сколько есть, сколько можно тратить, что скоро платить, копилки и лимиты.
class MoneyOverviewTab extends StatelessWidget {
  const MoneyOverviewTab({super.key, required this.openTab});
  final ValueChanged<int> openTab;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final now = DateTime.now();
    final today = todayKey(now);
    final from = dayKey(DateTime(now.year, now.month));
    final to = dayKey(DateTime(now.year, now.month + 1, 0));
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Watch(
      deps: [from],
      streams: () => [
        db.watchAccounts(),
        db.watchAccountBalances(),
        db.watchRecurrings(),
        db.watchTransactions(from: from, to: to),
        db.watchFunds(),
        db.watchFundValues(),
        db.watchAllFundMoves(),
        db.select(db.categories).watch(),
      ],
      builder: (context, v) {
        final accounts = v[0] as List<Account>;
        final balances = v[1] as Map<int, double>;
        final recurrings = v[2] as List<Recurring>;
        final txs = v[3] as List<Transaction>;
        final funds = v[4] as List<Fund>;
        final values = v[5] as Map<int, double>;
        final moves = v[6] as List<FundMove>;
        final cats = v[7] as List<Category>;
        final catById = {for (final c in cats) c.id: c};

        final total = accounts.fold<double>(0, (a, x) => a + (balances[x.id] ?? 0));
        final expenses = txs.where((t) => !t.isIncome).fold<double>(0, (a, t) => a + t.amount);
        final income = txs.where((t) => t.isIncome).fold<double>(0, (a, t) => a + t.amount);
        final spentToday = txs.where((t) => !t.isIncome && t.day == today && t.accountId != null).fold<double>(0, (a, t) => a + t.amount);
        final safe = safeToSpend(balance: total, recurrings: recurrings, today: today, spentToday: spentToday);
        final savings = funds.where((f) => f.kind == FundKind.savings).fold<double>(0, (a, f) => a + (values[f.id] ?? 0));
        final debts = funds.where((f) => f.kind == FundKind.debt).fold<double>(0, (a, f) => a + (values[f.id] ?? 0));
        final upcoming = recurrings.where((r) => r.nextDay <= addDays(today, 14)).toList();

        final byCat = <int?, double>{};
        for (final t in txs.where((t) => !t.isIncome)) {
          byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
        }
        final catRows = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final limited = cats.where((c) => !c.archived && c.monthlyLimit != null && !c.isIncome && !byCat.containsKey(c.id)).toList();
        final shownCats = [
          ...catRows.where((e) => catById[e.key]?.monthlyLimit != null),
          ...catRows.where((e) => catById[e.key]?.monthlyLimit == null).take(4),
        ];

        return ListView(
          padding: const EdgeInsets.only(top: 6, bottom: 110),
          children: [
            HeroCard(
              colors: dark ? const [Color(0xFFB45309), Color(0xFFC2410C)] : const [Color(0xFFD97706), Color(0xFFEA580C)],
              child: accounts.isEmpty
                  ? _NoAccountsHero(expenses: expenses, income: income, month: now)
                  : _BalanceHero(total: total, safe: safe, expenses: expenses, capital: total + savings - debts, today: today),
            ),
            if (accounts.isNotEmpty) ...[
              SectionTitle(
                'Счета',
                trailing: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen())),
                  child: const Text('Все'),
                ),
              ),
              AccountsStrip(accounts: accounts, balances: balances),
            ] else
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                  leading: const ColorIcon(Icons.account_balance_wallet_rounded, color: Accent.money, size: 40),
                  title: const Text('Добавь счета'),
                  subtitle: const Text('Карта, наличные: будет виден остаток и сколько можно тратить в день'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountEditScreen())),
                ),
              ),
            SectionTitle(
              'Скоро платить',
              trailing: TextButton(onPressed: () => openTab(3), child: const Text('Все')),
            ),
            if (recurrings.isEmpty)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                  leading: const ColorIcon(Icons.event_repeat_rounded, color: Accent.money, size: 40),
                  title: const Text('Регулярные платежи'),
                  subtitle: const Text('Зарплата, связь, подписки, кредит: напомню о дате и посчитаю, сколько свободно'),
                  trailing: const Icon(Icons.add_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringEditScreen())),
                ),
              )
            else if (upcoming.isEmpty)
              const Card(child: EmptyHint('В ближайшие две недели платежей нет', icon: Icons.event_available_rounded))
            else
              GroupCard(
                children: [for (final r in upcoming) RecurringTile(r: r, category: catById[r.categoryId], today: today, compact: true)],
              ),
            if (shownCats.isNotEmpty || limited.isNotEmpty) ...[
              SectionTitle(
                'Траты за ${monthTitle(now.year, now.month).split(' ').first.toLowerCase()}',
                trailing: TextButton(onPressed: () => openTab(2), child: const Text('Аналитика')),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      for (final e in shownCats) CategoryLimitRow(category: catById[e.key], spent: e.value, total: expenses),
                      for (final c in limited) CategoryLimitRow(category: c, spent: 0, total: expenses),
                    ],
                  ),
                ),
              ),
            ],
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
            for (final f in funds) FundCard(fund: f, value: values[f.id] ?? fundValue(f, 0), recent: recentMonthlyPace(moves, f.id)),
          ],
        );
      },
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.total, required this.safe, required this.expenses, required this.capital, required this.today});
  final double total;
  final SafeToSpend safe;
  final double expenses;
  final double capital;
  final int today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final until = safe.byIncome ? 'до дохода ${formatDay(safe.untilDay)}' : 'до конца месяца';
    final short = safe.perDay < 0;
    final left = safe.leftToday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'На счетах',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(formatMoney(total), style: theme.textTheme.displaySmall?.copyWith(color: Colors.white)),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                short ? 'Не хватает $until' : 'Можно потратить сегодня',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                short ? formatMoney(-safe.free) : formatMoney(left < 0 ? 0 : left),
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                short
                    ? 'Впереди платежей на ${formatMoney(safe.obligations)}, а на счетах ${formatMoney(safe.balance)}.'
                    : [
                        'По ${formatMoney(safe.perDay)} в день $until (${safe.days} дн.)',
                        if (safe.obligations > 0) 'платежи ${formatMoney(safe.obligations)} уже отложены',
                        if (left < 0) 'сегодня перерасход ${formatMoney(-left)}',
                      ].join(', '),
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: HeroStat(label: 'Потрачено в месяце', value: formatMoney(expenses)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HeroStat(label: 'Капитал', value: formatMoney(capital)),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoAccountsHero extends StatelessWidget {
  const _NoAccountsHero({required this.expenses, required this.income, required this.month});
  final double expenses;
  final double income;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = income - expenses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Потрачено за ${monthTitle(month.year, month.month).toLowerCase()}',
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(formatMoney(expenses), style: theme.textTheme.displaySmall?.copyWith(color: Colors.white)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: HeroStat(label: 'Доходы', value: '+${formatMoney(income)}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HeroStat(label: 'Осталось', value: '${diff < 0 ? '−' : '+'}${formatMoney(diff.abs())}'),
            ),
          ],
        ),
      ],
    );
  }
}
