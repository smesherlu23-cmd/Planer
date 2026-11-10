import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/database.dart';
import 'package:planer/data/money_queries.dart';
import 'package:planer/data/queries.dart';
import 'package:planer/data/transfer.dart';
import 'package:planer/logic/finance.dart';

Recurring rec({
  int id = 1,
  RecurringKind kind = RecurringKind.expense,
  double amount = 1000,
  RepeatKind repeat = RepeatKind.monthly,
  int every = 1,
  required int next,
  int? monthDay,
}) => Recurring(
  id: id,
  name: 'п$id',
  icon: 'payments',
  kind: kind,
  amount: amount,
  repeat: repeat,
  every: every,
  nextDay: next,
  monthDay: monthDay,
  archived: false,
  sortOrder: 0,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('следующая дата: неделя, месяц с переносом на конец, год', () {
    expect(nextOccurrence(20261109, RepeatKind.weekly, 1), 20261116);
    expect(nextOccurrence(20261109, RepeatKind.weekly, 2), 20261123);
    expect(nextOccurrence(20260131, RepeatKind.monthly, 1), 20260228);
    // После февраля снова 31-е, если помним число.
    expect(nextOccurrence(20260228, RepeatKind.monthly, 1, anchorDay: 31), 20260331);
    expect(nextOccurrence(20261109, RepeatKind.monthly, 3), 20270209);
    expect(nextOccurrence(20240229, RepeatKind.yearly, 1), 20250228);
  });

  test('даты платежа в периоде, просроченный считается сегодня', () {
    expect(occurrences(rec(next: 20261115), 20261109, 20261231), [20261115, 20261215]);
    expect(occurrences(rec(next: 20261101), 20261109, 20261130), [20261109]);
    expect(occurrences(rec(next: 20261110, repeat: RepeatKind.weekly), 20261109, 20261130), [20261110, 20261117, 20261124]);
  });

  test('стоимость в месяц и подписи периода', () {
    expect(monthlyCost(rec(next: 1, amount: 1200, repeat: RepeatKind.yearly)), 100);
    expect(monthlyCost(rec(next: 1, amount: 600)), 600);
    expect(monthlyCost(rec(next: 1, amount: 1200, every: 2)), 600);
    expect(repeatLabel(RepeatKind.monthly, 1), 'каждый месяц');
    expect(repeatLabel(RepeatKind.weekly, 2), 'раз в 2 недели');
    expect(repeatLabel(RepeatKind.yearly, 5), 'раз в 5 лет');
  });

  test('можно тратить до зарплаты за вычетом платежей', () {
    final s = safeToSpend(
      balance: 20000,
      today: 20261110,
      recurrings: [
        rec(id: 1, kind: RecurringKind.income, amount: 65000, next: 20261120),
        rec(id: 2, amount: 600, next: 20261115),
        rec(id: 3, kind: RecurringKind.fund, amount: 12000, next: 20261125),
      ],
    );
    expect(s.byIncome, isTrue);
    expect(s.untilDay, 20261120);
    expect(s.days, 10);
    // Платёж по кредиту после зарплаты не вычитается.
    expect(s.obligations, 600);
    expect(s.perDay, closeTo(1940, 0.01));
    expect(s.leftToday, closeTo(1940, 0.01));
  });

  test('сегодняшние траты уменьшают остаток на сегодня, но не дневной лимит', () {
    // Утром было 10 000, потратил 1 500: на счетах 8 500.
    final s = safeToSpend(balance: 8500, today: 20261121, spentToday: 1500, recurrings: const []);
    // До конца ноября 10 дней.
    expect(s.days, 10);
    expect(s.perDay, 1000);
    expect(s.leftToday, -500);
  });

  test('без дохода считается до конца месяца, неотмеченный доход не продлевает срок вперёд', () {
    final s = safeToSpend(balance: 3000, today: 20261130, recurrings: [rec(kind: RecurringKind.income, next: 20261125)]);
    expect(s.untilDay, 20261225);
    final noIncome = safeToSpend(balance: 3000, today: 20261130, recurrings: const []);
    expect(noIncome.days, 1);
    expect(noIncome.perDay, 3000);
  });

  test('периоды и доли категорий', () {
    expect(periodRange(Period.week, 20261111), (20261109, 20261115));
    expect(periodRange(Period.month, 20261111, shift: -1), (20261001, 20261031));
    expect(periodRange(Period.year, 20261111), (20260101, 20261231));
    expect(daysPassed(20261101, 20261130, 20261110), 10);
    expect(daysPassed(20261001, 20261031, 20261110), 31);

    Transaction tx(int id, double amount, int? cat, int day, {bool income = false}) =>
        Transaction(id: id, amount: amount, isIncome: income, categoryId: cat, day: day, at: DateTime(2026));
    final cur = [tx(1, 300, 1, 20261105), tx(2, 700, 2, 20261106), tx(3, 5000, null, 20261106, income: true)];
    final prev = [tx(4, 200, 1, 20261005)];
    final shares = categoryShares(cur, prev);
    expect(shares.first.categoryId, 2);
    expect(shares.first.share, closeTo(0.7, 1e-9));
    expect(changePercent(shares.last.sum, shares.last.previous), 50);
    final series = monthlySeries([...cur, ...prev], DateTime(2026, 11), count: 2);
    expect(series.map((s) => s.month), [202610, 202611]);
    expect(series.last.income, 5000);
    expect(series.last.expenses, 1000);
  });

  test('поиск по заметке, категории и сумме', () {
    expect(matchesQuery('шаур', note: 'Шаурма', amount: 250), isTrue);
    expect(matchesQuery('еда', category: 'Еда и перекусы', amount: 250), isTrue);
    expect(matchesQuery('1 500', amount: 1500), isTrue);
    expect(matchesQuery('кино', note: 'Шаурма', amount: 250), isFalse);
  });

  group('в базе', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('остаток счёта: операции, переводы, копилки, сверка', () async {
      final card = await db.saveAccount(AccountsCompanion.insert(name: 'Карта', initialBalance: const Value(10000)));
      final cash = await db.saveAccount(AccountsCompanion.insert(name: 'Наличные'));
      await db.saveTransaction(TransactionsCompanion.insert(amount: 1500, day: 20261109, accountId: Value(card)));
      await db.saveTransaction(
        TransactionsCompanion.insert(amount: 30000, day: 20261109, isIncome: const Value(true), accountId: Value(card)),
      );
      await db.saveTransfer(TransfersCompanion.insert(fromAccountId: card, toAccountId: cash, amount: 2000, day: 20261109));
      final piggy = await db.saveFund(FundsCompanion.insert(name: 'Civic', kind: FundKind.savings));
      final loan = await db.saveFund(FundsCompanion.insert(name: 'Кредит', kind: FundKind.debt, initialAmount: const Value(100000)));
      await db.into(db.fundMoves).insert(FundMovesCompanion.insert(fundId: piggy, amount: 5000, day: 20261109, accountId: Value(card)));
      await db.into(db.fundMoves).insert(FundMovesCompanion.insert(fundId: piggy, amount: -1000, day: 20261109, accountId: Value(cash)));
      await db.into(db.fundMoves).insert(FundMovesCompanion.insert(fundId: loan, amount: 12000, day: 20261109, accountId: Value(card)));
      var b = await db.watchAccountBalances().first;
      expect(b[card], 10000 - 1500 + 30000 - 2000 - 5000 - 12000);
      expect(b[cash], 2000 + 1000);

      await db.setAccountBalance(card, 20000, b[card]!);
      b = await db.watchAccountBalances().first;
      expect(b[card], 20000);
    });

    test('оплата регулярного платежа пишет операцию или взнос и сдвигает дату', () async {
      final card = await db.saveAccount(AccountsCompanion.insert(name: 'Карта'));
      final loan = await db.saveFund(FundsCompanion.insert(name: 'Кредит', kind: FundKind.debt, initialAmount: const Value(100000)));
      await db.saveRecurring(
        RecurringsCompanion.insert(
          name: 'Связь',
          kind: RecurringKind.expense,
          amount: 600,
          repeat: RepeatKind.monthly,
          nextDay: 20261131 - 1,
          monthDay: const Value(30),
          accountId: Value(card),
        ),
      );
      await db.saveRecurring(
        RecurringsCompanion.insert(
          name: 'Кредит',
          kind: RecurringKind.fund,
          amount: 12000,
          repeat: RepeatKind.monthly,
          nextDay: 20261125,
          fundId: Value(loan),
        ),
      );
      final list = await db.watchRecurrings().first;
      await db.payRecurring(list.firstWhere((r) => r.name == 'Связь'), day: 20261130);
      await db.payRecurring(list.firstWhere((r) => r.name == 'Кредит'), day: 20261125, accountId: card);
      final tx = (await db.select(db.transactions).get()).single;
      expect(tx.amount, 600);
      expect(tx.accountId, card);
      expect((await db.watchFundValues().first)[loan], 88000);
      final after = await db.watchRecurrings().first;
      expect(after.firstWhere((r) => r.name == 'Связь').nextDay, 20261230);
      expect(after.firstWhere((r) => r.name == 'Кредит').nextDay, 20261225);
      expect((await db.watchAccountBalances().first)[card], -12600);
    });

    test('счета, переводы и платежи переносятся экспортом', () async {
      final card = await db.saveAccount(AccountsCompanion.insert(name: 'Карта'));
      final cash = await db.saveAccount(AccountsCompanion.insert(name: 'Наличные'));
      await db.saveTransfer(TransfersCompanion.insert(fromAccountId: card, toAccountId: cash, amount: 500, day: 20261109));
      await db.saveRecurring(
        RecurringsCompanion.insert(
          name: 'ЗП',
          kind: RecurringKind.income,
          amount: 65000,
          repeat: RepeatKind.monthly,
          nextDay: 20261120,
          accountId: Value(card),
        ),
      );
      final json = await exportJson(db);
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await importJson(other, json);
      expect((await other.select(other.transfers).get()).single.amount, 500);
      expect((await other.select(other.recurrings).get()).single.accountId, card);
      expect((await other.watchAccountBalances().first)[cash], 500);
    });
  });

  test('переход с версии 4: старые операции попадают на счёт «Карта»', () async {
    final dir = await Directory.systemTemp.createTemp('planer_migration5');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final current = AppDatabase(NativeDatabase(file));
    await current.saveTransaction(TransactionsCompanion.insert(amount: 700, day: 20261101));
    await current.saveTransaction(TransactionsCompanion.insert(amount: 30000, day: 20261102, isIncome: const Value(true)));
    for (final t in ['recurrings', 'transfers', 'accounts']) {
      await current.customStatement('DROP TABLE "$t"');
    }
    await current.customStatement('PRAGMA user_version = 4');
    await current.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final accounts = await db.select(db.accounts).get();
    expect(accounts.single.name, 'Карта');
    expect((await db.select(db.transactions).get()).every((t) => t.accountId == accounts.single.id), isTrue);
    expect((await db.watchAccountBalances().first)[accounts.single.id], 29300);
    expect(await db.select(db.recurrings).get(), isEmpty);
  });
}
