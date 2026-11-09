/// Аналитика денег: сколько остаётся в месяц, как быстрее закрыть долги и когда накопишь.
///
/// Все расчёты помесячные. Проценты по долгу начисляются на остаток раз в месяц (ставка / 12),
/// как в обычном кредите с ежемесячным платежом. Досрочные платежи уменьшают срок, а не платёж:
/// так переплата меньше.
library;

import 'dart:math' as math;

import '../data/database.dart';
import '../data/dates.dart';

// ---------------------------------------------------------------------------
// Свободные деньги
// ---------------------------------------------------------------------------

/// Доходы и расходы в среднем за месяц.
typedef MonthlyFlow = ({double income, double expenses, int months});

/// Средние доходы и расходы за последние [months] полных месяцев, в которых были операции.
/// Текущий месяц не считается: он ещё не закончился. null, если операций нет.
MonthlyFlow? averageFlow(List<Transaction> txs, {required DateTime now, int months = 3}) {
  final thisMonth = monthKey(now);
  final byMonth = <int, (double, double)>{};
  for (final t in txs) {
    final m = t.day ~/ 100;
    if (m >= thisMonth) continue;
    final (inc, exp) = byMonth[m] ?? (0.0, 0.0);
    byMonth[m] = t.isIncome ? (inc + t.amount, exp) : (inc, exp + t.amount);
  }
  if (byMonth.isEmpty) return null;
  final keys = byMonth.keys.toList()..sort();
  final recent = keys.reversed.take(months).toList();
  var inc = 0.0, exp = 0.0;
  for (final k in recent) {
    inc += byMonth[k]!.$1;
    exp += byMonth[k]!.$2;
  }
  return (income: inc / recent.length, expenses: exp / recent.length, months: recent.length);
}

/// Расходы по категориям в среднем за месяц за последние [months] полных месяцев. Сначала самые большие.
List<(int? categoryId, double perMonth)> spendingByCategory(List<Transaction> txs, {required DateTime now, int months = 3}) {
  final thisMonth = monthKey(now);
  final monthsSeen = <int>{};
  final sums = <int?, double>{};
  for (final t in txs) {
    final m = t.day ~/ 100;
    if (m >= thisMonth || t.isIncome) continue;
    monthsSeen.add(m);
  }
  final recent = (monthsSeen.toList()..sort()).reversed.take(months).toSet();
  if (recent.isEmpty) return const [];
  for (final t in txs) {
    if (t.isIncome || !recent.contains(t.day ~/ 100)) continue;
    sums[t.categoryId] = (sums[t.categoryId] ?? 0) + t.amount;
  }
  final rows = [for (final e in sums.entries) (e.key, e.value / recent.length)];
  rows.sort((a, b) => b.$2.compareTo(a.$2));
  return rows;
}

// ---------------------------------------------------------------------------
// Один долг
// ---------------------------------------------------------------------------

/// Итог выплаты долга: за сколько месяцев и сколько уйдёт на проценты.
typedef Payoff = ({int months, double interest});

/// Выплата долга фиксированным платежом. null, если платёж не покрывает проценты.
Payoff? payoff({required double balance, required double payment, double? ratePercent, double lumpSum = 0}) {
  var b = balance - lumpSum;
  if (b <= 0.005) return (months: 0, interest: 0);
  if (payment <= 0) return null;
  final r = (ratePercent ?? 0) / 100 / 12;
  var months = 0;
  var interest = 0.0;
  while (b > 0.005) {
    final i = b * r;
    if (payment <= i) return null;
    interest += i;
    b = b + i - math.min(payment, b + i);
    months++;
    if (months > 1200) return null;
  }
  return (months: months, interest: interest);
}

// ---------------------------------------------------------------------------
// Одна копилка
// ---------------------------------------------------------------------------

/// Через сколько месяцев накопишь [target] взносами [monthly] при ставке вклада [ratePercent].
int? monthsToTarget({required double balance, required double target, required double monthly, double ratePercent = 0}) {
  if (balance >= target) return 0;
  if (monthly <= 0 && ratePercent <= 0) return null;
  final r = ratePercent / 100 / 12;
  var b = balance;
  var months = 0;
  while (b < target - 0.005) {
    b = b * (1 + r) + monthly;
    months++;
    if (months > 1200) return null;
  }
  return months;
}

/// Сколько откладывать в месяц, чтобы накопить [target] за [months] месяцев.
double monthlyNeeded({required double balance, required double target, required int months, double ratePercent = 0}) {
  if (balance >= target || months <= 0) return 0;
  final r = ratePercent / 100 / 12;
  if (r == 0) return (target - balance) / months;
  final grow = math.pow(1 + r, months).toDouble();
  return math.max(0, (target - balance * grow) * r / (grow - 1));
}

// ---------------------------------------------------------------------------
// Все копилки и долги вместе: разные планы
// ---------------------------------------------------------------------------

/// Копилка или долг для расчёта планов.
class PlanItem {
  const PlanItem({
    required this.id,
    required this.name,
    required this.isDebt,
    required this.balance,
    this.target,
    this.rate = 0,
    this.payment = 0,
  });

  final int id;
  final String name;
  final bool isDebt;

  /// Долг: сколько осталось. Копилка: сколько накоплено.
  final double balance;

  /// Цель копилки. У долга цель всегда ноль.
  final double? target;

  /// Ставка в % годовых: по долгу или по вкладу.
  final double rate;

  /// Обязательный платёж по долгу в месяц.
  final double payment;

  bool get open => isDebt ? balance > 0.005 : (target != null && balance < target! - 0.005);
}

enum Strategy {
  debtsFirst('Сначала кредит', 'Сверх обязательного платежа всё идёт в долг. Когда он закрыт, деньги идут в копилки.'),
  split('Пополам', 'Свободные деньги делятся поровну между досрочными платежами и копилками.'),
  savingsFirst('Сначала копить', 'По долгу только обязательный платёж, остальное в копилки.');

  const Strategy(this.label, this.description);
  final String label;
  final String description;
}

/// Результат плана: когда закрывается каждая копилка и долг и сколько уйдёт на проценты.
class PlanResult {
  PlanResult({
    required this.strategy,
    required this.doneMonth,
    required this.interestPaid,
    required this.interestEarned,
    required this.savedAfterYear,
  });

  final Strategy strategy;

  /// Номер месяца, в котором долг закрыт или копилка набрана (1 = ближайший). null: за 50 лет не успеть.
  final Map<int, int?> doneMonth;
  final double interestPaid;
  final double interestEarned;

  /// Сколько будет во всех копилках через 12 месяцев.
  final double savedAfterYear;

  /// Когда закроются все долги.
  int? debtsClosed(List<PlanItem> items) => _last(items.where((i) => i.isDebt));

  /// Когда наберутся все копилки с целью.
  int? goalsReached(List<PlanItem> items) => _last(items.where((i) => !i.isDebt && i.target != null));

  int? _last(Iterable<PlanItem> items) {
    var last = 0;
    for (final i in items) {
      final m = doneMonth[i.id];
      if (m == null) return null;
      last = math.max(last, m);
    }
    return last;
  }
}

/// Сколько в месяц уходит на обязательные платежи по долгам.
double minimumPayments(List<PlanItem> items) => items.where((i) => i.isDebt && i.open).fold(0.0, (a, i) => a + i.payment);

/// Помесячно раскладывает [monthly] рублей по долгам и копилкам по плану [strategy].
///
/// Долги с большей ставкой гасятся раньше («лавина»): так переплата меньше всего.
/// Копилки наполняются по порядку списка.
PlanResult simulate(List<PlanItem> items, double monthly, Strategy strategy, {int maxMonths = 600}) {
  final bal = {for (final i in items) i.id: i.balance};
  final done = <int, int?>{for (final i in items) i.id: i.open ? null : 0};
  final debts = items.where((i) => i.isDebt).toList()..sort((a, b) => b.rate.compareTo(a.rate));
  final goals = items.where((i) => !i.isDebt && i.target != null).toList();
  final free = items.where((i) => !i.isDebt && i.target == null).toList();
  var paid = 0.0, earned = 0.0, savedAfterYear = 0.0;

  bool debtOpen(PlanItem d) => bal[d.id]! > 0.005;
  bool goalOpen(PlanItem g) => bal[g.id]! < g.target! - 0.005;

  /// Досрочно в долги: сначала с большей ставкой. Возвращает остаток денег.
  double toDebts(double money) {
    for (final d in debts) {
      if (money <= 0) break;
      if (!debtOpen(d)) continue;
      final pay = math.min(money, bal[d.id]!);
      bal[d.id] = bal[d.id]! - pay;
      money -= pay;
    }
    return money;
  }

  /// В копилки по порядку, до цели. Остаток в копилки без цели. Возвращает остаток денег.
  double toGoals(double money) {
    for (final g in goals) {
      if (money <= 0) break;
      if (!goalOpen(g)) continue;
      final put = math.min(money, g.target! - bal[g.id]!);
      bal[g.id] = bal[g.id]! + put;
      money -= put;
    }
    return money;
  }

  for (var month = 1; month <= maxMonths; month++) {
    final anyOpen = debts.any(debtOpen) || goals.any(goalOpen);
    if (!anyOpen) break;
    // Проценты за месяц.
    for (final d in debts.where(debtOpen)) {
      final i = bal[d.id]! * d.rate / 100 / 12;
      bal[d.id] = bal[d.id]! + i;
      paid += i;
    }
    for (final s in [...goals, ...free]) {
      final i = bal[s.id]! * s.rate / 100 / 12;
      bal[s.id] = bal[s.id]! + i;
      earned += i;
    }
    // Обязательные платежи.
    var money = monthly;
    for (final d in debts.where(debtOpen)) {
      final pay = math.min(math.min(d.payment, bal[d.id]!), money);
      bal[d.id] = bal[d.id]! - pay;
      money -= pay;
    }
    // Остальное по плану.
    switch (strategy) {
      case Strategy.debtsFirst:
        money = toGoals(toDebts(money));
      case Strategy.savingsFirst:
        money = toDebts(toGoals(money));
      case Strategy.split:
        final half = money / 2;
        final restDebt = toDebts(half);
        final restGoal = toGoals(money - half + restDebt);
        money = toDebts(restGoal);
    }
    if (money > 0 && free.isNotEmpty) {
      bal[free.first.id] = bal[free.first.id]! + money;
    }
    for (final i in items) {
      if (done[i.id] != null) continue;
      final closed = i.isDebt ? !debtOpen(i) : (i.target != null && !goalOpen(i));
      if (closed) done[i.id] = month;
    }
    if (month == 12) savedAfterYear = [...goals, ...free].fold(0.0, (a, s) => a + bal[s.id]!);
  }
  if (savedAfterYear == 0) savedAfterYear = [...goals, ...free].fold(0.0, (a, s) => a + bal[s.id]!);
  return PlanResult(strategy: strategy, doneMonth: done, interestPaid: paid, interestEarned: earned, savedAfterYear: savedAfterYear);
}

/// Какой план выгоднее: меньше всего денег уходит на проценты за вычетом дохода по вкладам,
/// при равенстве тот, где всё готово раньше.
Strategy bestStrategy(List<PlanItem> items, List<PlanResult> results) {
  double cost(PlanResult r) => r.interestPaid - r.interestEarned;
  int finish(PlanResult r) => math.max(r.debtsClosed(items) ?? 9999, r.goalsReached(items) ?? 9999);
  final sorted = [...results]
    ..sort((a, b) {
      final c = cost(a).compareTo(cost(b));
      if ((cost(a) - cost(b)).abs() > 100) return c;
      return finish(a).compareTo(finish(b));
    });
  return sorted.first.strategy;
}

/// «через 9 мес., в августе 2027»
String monthsLabel(int months, {int? today}) {
  if (months <= 0) return 'уже';
  final when = dayFromKey(addMonthsKey(today ?? todayKey(), months));
  final years = months ~/ 12, rest = months % 12;
  final span = years == 0
      ? '$months мес.'
      : rest == 0
      ? '$years ${_years(years)}'
      : '$years ${_years(years)} $rest мес.';
  return '$span, ${monthTitle(when.year, when.month).toLowerCase()}';
}

String _years(int n) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return 'год';
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'года';
  return 'лет';
}

/// Дата через n месяцев.
int addMonthsKey(int key, int months) {
  final d = dayFromKey(key);
  final first = DateTime(d.year, d.month + months, 1);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return dayKey(DateTime(first.year, first.month, math.min(d.day, lastDay)));
}
