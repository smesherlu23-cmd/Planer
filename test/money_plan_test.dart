import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/database.dart';
import 'package:planer/logic/money_plan.dart';

void main() {
  test('выплата долга: срок, проценты, доплаты и разовый платёж', () {
    final flat = payoff(balance: 120000, payment: 12000)!;
    expect(flat.months, 10);
    expect(flat.interest, 0);
    final withRate = payoff(balance: 120000, payment: 12000, ratePercent: 20)!;
    expect(withRate.months, 12);
    expect(withRate.interest, greaterThan(10000));
    expect(withRate.interest, lessThan(13000));
    final faster = payoff(balance: 120000, payment: 17000, ratePercent: 20)!;
    expect(faster.months, lessThan(withRate.months));
    expect(faster.interest, lessThan(withRate.interest));
    expect(payoff(balance: 120000, payment: 12000, lumpSum: 30000)!.months, 8);
    // Платёж меньше процентов: долг не закрыть.
    expect(payoff(balance: 120000, payment: 1000, ratePercent: 20), isNull);
  });

  test('копилка: срок и сколько откладывать', () {
    expect(monthsToTarget(balance: 0, target: 60000, monthly: 20000), 3);
    expect(monthlyNeeded(balance: 0, target: 60000, months: 12), 5000);
    expect(monthlyNeeded(balance: 0, target: 60000, months: 12, ratePercent: 12), lessThan(5000));
    expect(monthsToTarget(balance: 0, target: 300000, monthly: 23000, ratePercent: 15)!, lessThan(14));
  });

  test('планы: сначала кредит выгоднее, если вклад без процентов', () {
    const items = [
      PlanItem(id: 1, name: 'Кредит', isDebt: true, balance: 108000, rate: 20, payment: 12000),
      PlanItem(id: 2, name: 'Права', isDebt: false, balance: 0, target: 60000),
      PlanItem(id: 3, name: 'Civic', isDebt: false, balance: 20000, target: 300000),
    ];
    expect(minimumPayments(items), 12000);
    final results = [for (final s in Strategy.values) simulate(items, 55000, s)];
    final debtsFirst = results[0], savingsFirst = results[2];
    expect(debtsFirst.doneMonth[1]!, lessThan(savingsFirst.doneMonth[1]!));
    expect(debtsFirst.interestPaid, lessThan(savingsFirst.interestPaid));
    expect(savingsFirst.doneMonth[2]!, lessThan(debtsFirst.doneMonth[2]!));
    // Всё в итоге закрывается при любом плане.
    for (final r in results) {
      expect(r.debtsClosed(items), isNotNull);
      expect(r.goalsReached(items), isNotNull);
    }
    expect(bestStrategy(items, results), Strategy.debtsFirst);
  });

  test('средний месяц и траты по категориям без текущего месяца', () {
    Transaction tx(int id, int day, double amount, {bool income = false, int? cat}) =>
        Transaction(id: id, amount: amount, isIncome: income, categoryId: cat, day: day, at: DateTime(2026));
    final txs = [
      tx(1, 20260905, 60000, income: true),
      tx(2, 20260910, 30000, cat: 1),
      tx(3, 20261005, 70000, income: true),
      tx(4, 20261010, 20000, cat: 1),
      tx(5, 20261012, 10000, cat: 2),
      tx(6, 20261105, 99999, cat: 2),
    ];
    final flow = averageFlow(txs, now: DateTime(2026, 11, 9))!;
    expect(flow.months, 2);
    expect(flow.income, 65000);
    expect(flow.expenses, 30000);
    final cats = spendingByCategory(txs, now: DateTime(2026, 11, 9));
    expect(cats.first, (1, 25000.0));
    expect(cats.last, (2, 5000.0));
  });
}
