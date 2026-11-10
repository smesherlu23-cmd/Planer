/// Расчёты модуля «Деньги»: остатки на счетах, регулярные платежи, сколько можно тратить
/// до следующего дохода, разбивка расходов за период.
library;

import 'dart:math' as math;

import '../data/database.dart';
import '../data/dates.dart';

// ---------------------------------------------------------------------------
// Счета
// ---------------------------------------------------------------------------

/// Остаток каждого счёта: начальный остаток, плюс доходы, минус расходы, плюс-минус переводы.
/// Взнос в копилку и платёж по долгу уменьшают счёт, снятие из копилки увеличивает.
Map<int, double> accountBalances({
  required List<Account> accounts,
  required List<Transaction> transactions,
  required List<Transfer> transfers,
  required List<(FundMove, FundKind)> fundMoves,
}) {
  final b = {for (final a in accounts) a.id: a.initialBalance};
  void add(int? id, double v) {
    if (id != null && b.containsKey(id)) b[id] = b[id]! + v;
  }

  for (final t in transactions) {
    add(t.accountId, t.isIncome ? t.amount : -t.amount);
  }
  for (final t in transfers) {
    add(t.fromAccountId, -t.amount);
    add(t.toAccountId, t.amount);
  }
  for (final (m, _) in fundMoves) {
    // У копилки плюс это взнос, минус снятие. У долга плюс это платёж. В обоих случаях деньги уходят со счёта.
    add(m.accountId, -m.amount);
  }
  return b;
}

// ---------------------------------------------------------------------------
// Регулярные платежи
// ---------------------------------------------------------------------------

/// Следующая дата после [day] для повтора [repeat] каждые [every] периодов.
/// Для месяцев число сохраняется, а если его нет в месяце, берётся последний день.
int nextOccurrence(int day, RepeatKind repeat, int every, {int? anchorDay}) {
  final n = math.max(1, every);
  final d = dayFromKey(day);
  switch (repeat) {
    case RepeatKind.weekly:
      return addDays(day, 7 * n);
    case RepeatKind.monthly:
    case RepeatKind.yearly:
      final months = repeat == RepeatKind.monthly ? n : 12 * n;
      final first = DateTime(d.year, d.month + months, 1);
      final last = DateTime(first.year, first.month + 1, 0).day;
      return dayKey(DateTime(first.year, first.month, math.min(anchorDay ?? d.day, last)));
  }
}

/// Все даты платежа с [from] по [to] включительно, начиная с ближайшей [Recurring.nextDay].
/// Просроченный платёж (дата раньше [from]) попадает в список один раз, датой [from].
List<int> occurrences(Recurring r, int from, int to) {
  final out = <int>[];
  final anchor = r.monthDay ?? dayFromKey(r.nextDay).day;
  var d = r.nextDay;
  var guard = 0;
  if (d < from) {
    out.add(from);
    while (d < from && guard++ < 1000) {
      d = nextOccurrence(d, r.repeat, r.every, anchorDay: anchor);
    }
  }
  while (d <= to && guard++ < 1000) {
    out.add(d);
    d = nextOccurrence(d, r.repeat, r.every, anchorDay: anchor);
  }
  return out;
}

/// Сколько платёж стоит в среднем за месяц.
double monthlyCost(Recurring r) {
  final every = math.max(1, r.every);
  return switch (r.repeat) {
    RepeatKind.weekly => r.amount * 52 / 12 / every,
    RepeatKind.monthly => r.amount / every,
    RepeatKind.yearly => r.amount / 12 / every,
  };
}

/// «каждый месяц», «раз в 2 недели», «каждый год».
String repeatLabel(RepeatKind repeat, int every) {
  if (every <= 1) {
    return switch (repeat) {
      RepeatKind.weekly => 'каждую неделю',
      RepeatKind.monthly => 'каждый месяц',
      RepeatKind.yearly => 'каждый год',
    };
  }
  final unit = switch (repeat) {
    RepeatKind.weekly => _plural(every, 'неделю', 'недели', 'недель'),
    RepeatKind.monthly => _plural(every, 'месяц', 'месяца', 'месяцев'),
    RepeatKind.yearly => _plural(every, 'год', 'года', 'лет'),
  };
  return 'раз в $every $unit';
}

String _plural(int n, String one, String few, String many) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return one;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
  return many;
}

// ---------------------------------------------------------------------------
// Сколько можно тратить
// ---------------------------------------------------------------------------

/// Сколько можно тратить в день до следующего дохода.
class SafeToSpend {
  const SafeToSpend({
    required this.balance,
    required this.untilDay,
    required this.days,
    required this.obligations,
    required this.perDay,
    required this.spentToday,
    required this.byIncome,
  });

  /// Деньги на счетах сейчас.
  final double balance;

  /// День следующего дохода (не включается) или конец месяца, если доход не задан.
  final int untilDay;

  /// Сколько дней, включая сегодня, нужно продержаться.
  final int days;

  /// Обязательные платежи до этого дня: расходы, взносы и платежи по долгам.
  final double obligations;

  /// Можно тратить в день. Может быть меньше нуля: денег не хватает.
  final double perDay;

  /// Сколько уже потрачено сегодня.
  final double spentToday;

  /// Срок посчитан до регулярного дохода, а не до конца месяца.
  final bool byIncome;

  double get free => balance - obligations;

  /// Сколько ещё можно потратить сегодня. Сегодняшние траты уже вычтены из остатка,
  /// поэтому дневной лимит считается так, будто их не было.
  double get leftToday => (balance + spentToday - obligations) / days - spentToday;
}

/// [balance] это деньги на счетах сейчас, [spentToday] сегодняшние расходы (уже вычтены из остатка).
SafeToSpend safeToSpend({required double balance, required List<Recurring> recurrings, required int today, double spentToday = 0}) {
  // Ближайший доход после сегодняшнего дня. Неотмеченный прошлый доход не считается: денег ещё нет на счёте,
  // поэтому срок тянется до следующего.
  final incomes = <int>[];
  for (final r in recurrings.where((r) => r.kind == RecurringKind.income)) {
    var d = r.nextDay;
    var guard = 0;
    while (d <= today && guard++ < 1000) {
      d = nextOccurrence(d, r.repeat, r.every, anchorDay: r.monthDay);
    }
    incomes.add(d);
  }
  incomes.sort();
  final d = dayFromKey(today);
  final endOfMonth = dayKey(DateTime(d.year, d.month + 1, 1));
  final until = incomes.isEmpty ? endOfMonth : incomes.first;
  final days = math.max(1, daysBetween(today, until));
  var obligations = 0.0;
  for (final r in recurrings) {
    if (r.kind == RecurringKind.income) continue;
    obligations += r.amount * occurrences(r, today, addDays(until, -1)).length;
  }
  final perDay = (balance + spentToday - obligations) / days;
  return SafeToSpend(
    balance: balance,
    untilDay: until,
    days: days,
    obligations: obligations,
    perDay: perDay,
    spentToday: spentToday,
    byIncome: incomes.isNotEmpty,
  );
}

// ---------------------------------------------------------------------------
// Периоды и аналитика
// ---------------------------------------------------------------------------

enum Period {
  week('Неделя'),
  month('Месяц'),
  year('Год');

  const Period(this.label);
  final String label;
}

/// Начало и конец периода (ключи дней, включительно), который содержит [day], со сдвигом на [shift] периодов.
(int, int) periodRange(Period p, int day, {int shift = 0}) {
  final d = dayFromKey(day);
  switch (p) {
    case Period.week:
      final start = addDays(weekStart(day), 7 * shift);
      return (start, addDays(start, 6));
    case Period.month:
      final first = DateTime(d.year, d.month + shift, 1);
      return (dayKey(first), dayKey(DateTime(first.year, first.month + 1, 0)));
    case Period.year:
      return (dayKey(DateTime(d.year + shift, 1, 1)), dayKey(DateTime(d.year + shift, 12, 31)));
  }
}

/// Сколько дней периода прошло к [today], включая его. Для прошлых периодов вся длина.
int daysPassed(int from, int to, int today) {
  if (today < from) return 0;
  return daysBetween(from, math.min(to, today)) + 1;
}

/// Сумма расходов по категории за период и сравнение с прошлым периодом.
typedef CategoryShare = ({int? categoryId, double sum, double share, double? previous});

/// Расходы по категориям за [current] с долей и суммой за [previous] для сравнения. Сначала самые большие.
List<CategoryShare> categoryShares(List<Transaction> current, List<Transaction> previous) {
  final now = <int?, double>{}, before = <int?, double>{};
  for (final t in current.where((t) => !t.isIncome)) {
    now[t.categoryId] = (now[t.categoryId] ?? 0) + t.amount;
  }
  for (final t in previous.where((t) => !t.isIncome)) {
    before[t.categoryId] = (before[t.categoryId] ?? 0) + t.amount;
  }
  final total = now.values.fold<double>(0, (a, b) => a + b);
  final rows = [
    for (final e in now.entries) (categoryId: e.key, sum: e.value, share: total == 0 ? 0.0 : e.value / total, previous: before[e.key]),
  ];
  rows.sort((a, b) => b.sum.compareTo(a.sum));
  return rows;
}

/// Доходы и расходы по месяцам: последние [count] месяцев до [month] включительно, по порядку.
List<({int month, double income, double expenses})> monthlySeries(List<Transaction> txs, DateTime month, {int count = 6}) {
  final keys = [for (var i = count - 1; i >= 0; i--) monthKey(DateTime(month.year, month.month - i))];
  final inc = {for (final k in keys) k: 0.0}, exp = {for (final k in keys) k: 0.0};
  for (final t in txs) {
    final m = t.day ~/ 100;
    if (!inc.containsKey(m)) continue;
    if (t.isIncome) {
      inc[m] = inc[m]! + t.amount;
    } else {
      exp[m] = exp[m]! + t.amount;
    }
  }
  return [for (final k in keys) (month: k, income: inc[k]!, expenses: exp[k]!)];
}

/// Изменение в процентах относительно прошлого. null, если сравнивать не с чем.
int? changePercent(double now, double? before) {
  if (before == null || before <= 0) return null;
  return ((now - before) / before * 100).round();
}

/// Подходит ли операция под поиск: по заметке, названию категории или сумме.
bool matchesQuery(String query, {String? note, String? category, required double amount}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if ((note ?? '').toLowerCase().contains(q)) return true;
  if ((category ?? '').toLowerCase().contains(q)) return true;
  final digits = q.replaceAll(RegExp(r'[\s₽]'), '').replaceAll(',', '.');
  final n = double.tryParse(digits);
  return n != null && (amount - n).abs() < 0.5;
}
