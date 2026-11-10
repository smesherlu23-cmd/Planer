/// Запросы модуля «Деньги»: счета, переводы, регулярные платежи.
library;

import 'package:drift/drift.dart';

import '../logic/finance.dart';
import 'database.dart';
import 'dates.dart';

const keyLastAccount = 'money_last_account';

extension MoneyQueries on AppDatabase {
  // ----- Счета -----

  Stream<List<Account>> watchAccounts({bool archived = false}) =>
      (select(accounts)
            ..where((t) => t.archived.equals(archived))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
          .watch();

  Future<int> saveAccount(AccountsCompanion a) async {
    if (a.id.present) {
      await (update(accounts)..where((t) => t.id.equals(a.id.value))).write(a);
      return a.id.value;
    }
    final row = await customSelect('SELECT COALESCE(MAX(sort_order), 0) AS m FROM accounts').getSingle();
    return into(accounts).insert(a.copyWith(sortOrder: Value(row.read<int>('m') + 1)));
  }

  /// Остатки всех счетов, включая архивные.
  Stream<Map<int, double>> watchAccountBalances() => customSelect(
    'SELECT 1',
    readsFrom: {accounts, transactions, transfers, fundMoves, funds},
  ).watch().asyncMap((_) => accountBalancesNow());

  Future<Map<int, double>> accountBalancesNow() async {
    final moves = await select(fundMoves).join([innerJoin(funds, funds.id.equalsExp(fundMoves.fundId))]).get();
    return accountBalances(
      accounts: await select(accounts).get(),
      transactions: await select(transactions).get(),
      transfers: await select(transfers).get(),
      fundMoves: [for (final r in moves) (r.readTable(fundMoves), r.readTable(funds).kind)],
    );
  }

  /// Поставить счёту остаток [balance] на сегодня: меняется начальный остаток, история не трогается.
  Future<void> setAccountBalance(int accountId, double balance, double current) async {
    final a = await (select(accounts)..where((t) => t.id.equals(accountId))).getSingle();
    await (update(
      accounts,
    )..where((t) => t.id.equals(accountId))).write(AccountsCompanion(initialBalance: Value(a.initialBalance + balance - current)));
  }

  // ----- Переводы -----

  Stream<List<Transfer>> watchTransfers({required int from, required int to}) =>
      (select(transfers)
            ..where((t) => t.day.isBetweenValues(from, to))
            ..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.at)]))
          .watch();

  Future<int> saveTransfer(TransfersCompanion t) async {
    if (t.id.present) {
      await (update(transfers)..where((x) => x.id.equals(t.id.value))).write(t);
      return t.id.value;
    }
    return into(transfers).insert(t);
  }

  // ----- Операции за всё время -----

  Stream<List<Transaction>> watchAllTransactions() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.at)])).watch();

  // ----- Регулярные платежи -----

  Stream<List<Recurring>> watchRecurrings() =>
      (select(recurrings)
            ..where((t) => t.archived.equals(false))
            ..orderBy([(t) => OrderingTerm(expression: t.nextDay), (t) => OrderingTerm(expression: t.id)]))
          .watch();

  Future<int> saveRecurring(RecurringsCompanion r) async {
    if (r.id.present) {
      await (update(recurrings)..where((t) => t.id.equals(r.id.value))).write(r);
      return r.id.value;
    }
    return into(recurrings).insert(r);
  }

  /// Отметить регулярный платёж оплаченным: записать операцию или взнос и сдвинуть дату на следующий период.
  Future<void> payRecurring(Recurring r, {double? amount, int? day, int? accountId}) => transaction(() async {
    final sum = amount ?? r.amount;
    final when = day ?? todayKey();
    final account = accountId ?? r.accountId;
    if (r.kind == RecurringKind.fund && r.fundId != null) {
      await into(fundMoves)
          .insert(FundMovesCompanion.insert(fundId: r.fundId!, amount: sum, day: when, note: Value(r.name), accountId: Value(account)));
    } else {
      await into(transactions).insert(
        TransactionsCompanion.insert(
          amount: sum,
          day: when,
          isIncome: Value(r.kind == RecurringKind.income),
          categoryId: Value(r.categoryId),
          accountId: Value(account),
          note: Value(r.name),
        ),
      );
    }
    await skipRecurring(r);
  });

  /// Пропустить платёж: дата сдвигается, ничего не записывается.
  Future<void> skipRecurring(Recurring r) => (update(recurrings)..where((t) => t.id.equals(r.id))).write(
    RecurringsCompanion(nextDay: Value(nextOccurrence(r.nextDay, r.repeat, r.every, anchorDay: r.monthDay))),
  );
}
