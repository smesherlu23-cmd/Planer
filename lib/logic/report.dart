/// Итоги за день, неделю или месяц: всё, что произошло, прогресс целей и сравнение с прошлым периодом.
library;

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../data/goal_queries.dart';
import 'calc.dart';
import 'food.dart';
import 'goals.dart';
import 'journal.dart';
import 'minimum.dart';
import 'sleep.dart';
import 'values.dart';

class HabitWeek {
  HabitWeek(this.habit, this.planned, this.done, this.minimum);
  final Habit habit;
  final int planned;
  final int done;
  final int minimum;
}

class TrackerWeek {
  TrackerWeek(this.tracker, this.label);
  final Tracker tracker;
  final String label;
}

/// Сон за неделю.
class SleepWeek {
  SleepWeek(this.stats, this.goals);
  final SleepStats stats;
  final SleepGoals goals;
}

/// Питание за неделю: средние за дни с записями.
class FoodWeek {
  FoodWeek({
    required this.days,
    required this.avgKcal,
    required this.avgProtein,
    required this.onTarget,
    required this.goals,
    this.minimum = 0,
  });
  final int days;
  final double avgKcal;
  final double avgProtein;

  /// Дней по норме и дней только с минимумом.
  final int onTarget;
  final int minimum;
  final FoodGoals goals;
}

enum ReportPeriod { day, week, month }

/// Границы периода, в который входит [day].
({int from, int to}) periodRange(ReportPeriod p, int day) {
  switch (p) {
    case ReportPeriod.day:
      return (from: day, to: day);
    case ReportPeriod.week:
      final m = weekStart(day);
      return (from: m, to: addDays(m, 6));
    case ReportPeriod.month:
      final d = dayFromKey(day);
      return (from: dayKey(DateTime(d.year, d.month)), to: dayKey(DateTime(d.year, d.month + 1, 0)));
  }
}

/// Сдвинуть период на [n] вперёд или назад.
int shiftPeriod(ReportPeriod p, int from, int n) => switch (p) {
  ReportPeriod.day => addDays(from, n),
  ReportPeriod.week => addDays(from, 7 * n),
  ReportPeriod.month => () {
    final d = dayFromKey(from);
    return dayKey(DateTime(d.year, d.month + n));
  }(),
};

String periodTitle(ReportPeriod p, int from, int to) => switch (p) {
  ReportPeriod.day => formatDayLong(from),
  ReportPeriod.week => '${formatDay(from)} – ${formatDay(to)}',
  ReportPeriod.month => monthName(from),
};

/// Какой обзор пишется за период.
JournalKind reviewKind(ReportPeriod p) => switch (p) {
  ReportPeriod.day => JournalKind.day,
  ReportPeriod.week => JournalKind.week,
  ReportPeriod.month => JournalKind.month,
};

/// Как цель сдвинулась за период.
class GoalMove {
  GoalMove(this.goal, this.status, this.before, this.after, this.text);
  final Goal goal;
  final GoalStatus status;
  final double? before;
  final double? after;

  /// «67 → 67,8 кг (+0,8)».
  final String text;

  double? get delta => before == null || after == null ? null : after! - before!;

  /// Сдвиг в сторону цели.
  bool get forward {
    final d = delta;
    if (d == null || d == 0) return false;
    return (status.target >= status.start) == (d > 0);
  }
}

/// Цифры прошлого периода для сравнения.
class PrevStats {
  PrevStats({required this.habitsRate, required this.moodAvg, required this.expenses, required this.workoutsDone});
  final double? habitsRate;
  final double? moodAvg;
  final double expenses;
  final int workoutsDone;
}

class WeekReport {
  WeekReport({
    this.sleep,
    this.food,
    required this.from,
    required this.to,
    required this.habits,
    required this.trackers,
    required this.workoutsDone,
    required this.workoutsPlanned,
    required this.workoutNames,
    required this.expenses,
    required this.income,
    required this.topCategories,
    required this.fundMoves,
    required this.moodAvg,
    required this.dayNotes,
    required this.review,
    this.hardDays = 0,
    this.workoutsMinimum = 0,
    this.period = ReportPeriod.week,
    this.days = 7,
    this.goals = const [],
    this.moods = const [],
    this.wins = const [],
    this.tags = const [],
    this.prev,
  });

  final ReportPeriod period;

  /// Сколько дней периода уже прошло.
  final int days;
  final List<GoalMove> goals;
  final List<(int day, int? mood)> moods;

  /// Победы из итогов дня.
  final List<(int day, String text)> wins;

  /// Теги за период и сколько раз встречались.
  final List<(String, int)> tags;
  final PrevStats? prev;

  /// Доля выполненных привычек. null, если ничего не планировалось.
  double? get habitsRate => habitsPlanned == 0 ? null : habitsDone / habitsPlanned;

  /// Сколько дней недели отмечено как тяжёлые.
  final int hardDays;

  /// Сколько тренировок сделано облегчённо.
  final int workoutsMinimum;

  final int from;
  final int to;
  final List<HabitWeek> habits;
  final List<TrackerWeek> trackers;
  final int workoutsDone;
  final int workoutsPlanned;
  final List<String> workoutNames;
  final double expenses;
  final double income;
  final List<(String, double)> topCategories;
  final List<(Fund, double)> fundMoves;
  final double? moodAvg;
  final int dayNotes;
  final JournalEntry? review;
  final SleepWeek? sleep;
  final FoodWeek? food;

  int get habitsPlanned => habits.fold(0, (a, h) => a + h.planned);
  int get habitsDone => habits.fold(0, (a, h) => a + h.done);

  /// Текст для копирования: отправить в чат, сохранить, показать Claude.
  String toText() {
    final b = StringBuffer();
    b.writeln(switch (period) {
      ReportPeriod.day => 'Planer: итоги дня, ${formatDay(from, withYear: true)}',
      ReportPeriod.week => 'Planer: неделя ${formatDay(from)} – ${formatDay(to, withYear: true)}',
      ReportPeriod.month => 'Planer: ${monthName(from).toLowerCase()}',
    });
    if (hardDays > 0) b.writeln('Тяжёлых дней: $hardDays');
    if (habits.isNotEmpty) {
      b.writeln();
      b.writeln('Привычки: $habitsDone из $habitsPlanned');
      for (final h in habits) {
        final min = h.minimum > 0 ? ', из них минимумом ${h.minimum}' : '';
        b.writeln('- ${h.habit.name}: ${h.done} из ${h.planned}$min');
      }
    }
    if (trackers.isNotEmpty) {
      b.writeln();
      b.writeln('Трекеры:');
      for (final t in trackers) {
        b.writeln('- ${t.tracker.name}: ${t.label}');
      }
    }
    if (workoutsPlanned > 0 || workoutsDone > 0) {
      b.writeln();
      b.writeln(
        'Тренировки: $workoutsDone из $workoutsPlanned${workoutsMinimum > 0 ? ', из них облегчённых $workoutsMinimum' : ''}'
        '${workoutNames.isEmpty ? '' : ' (${workoutNames.join(', ')})'}',
      );
    }
    if (expenses > 0 || income > 0 || fundMoves.isNotEmpty) {
      b.writeln();
      b.writeln('Деньги: расходы ${formatMoney(expenses)}, доходы ${formatMoney(income)}');
      for (final (name, sum) in topCategories) {
        b.writeln('- $name: ${formatMoney(sum)}');
      }
      for (final (f, sum) in fundMoves) {
        final what = f.kind == FundKind.debt ? 'выплачено' : (sum >= 0 ? 'отложено' : 'снято');
        b.writeln('- ${f.name}: $what ${formatMoney(sum.abs())}');
      }
    }
    final sl = sleep;
    if (sl != null && sl.stats.nights > 0) {
      b.writeln();
      b.writeln(
        'Сон: записано ночей ${sl.stats.nights}, в среднем ${formatDuration(sl.stats.avgDuration!)}, '
        'отбой в среднем ${formatMinutes(sl.stats.avgBed!)}, вовремя ${sl.stats.onTime} из ${sl.stats.nights}, '
        'выспался ${sl.stats.full} из ${sl.stats.nights}${sl.stats.minimum > 0 ? ', минимум ${sl.stats.minimum}' : ''}',
      );
    }
    final fd = food;
    if (fd != null && fd.days > 0) {
      b.writeln();
      b.writeln(
        'Питание: в среднем ${formatNumber(fd.avgKcal, maxDecimals: 0)} ккал и ${formatNumber(fd.avgProtein, maxDecimals: 0)} г белка в день '
        '(цель ${formatNumber(fd.goals.kcal, maxDecimals: 0)} ккал и ${formatNumber(fd.goals.protein, maxDecimals: 0)} г), '
        'норма в ${fd.onTarget} из ${fd.days} дней${fd.minimum > 0 ? ', минимум в ${fd.minimum}' : ''}',
      );
    }
    if (goals.isNotEmpty) {
      b.writeln();
      b.writeln('Цели:');
      for (final g in goals) {
        b.writeln('- ${g.goal.name}: ${g.text}, ${goalPaceLabel(g.status.pace).toLowerCase()}');
      }
    }
    if (dayNotes > 0 && period != ReportPeriod.day) {
      b.writeln();
      b.writeln('Итогов дня: $dayNotes из $days${moodAvg == null ? '' : ', среднее настроение ${formatNumber(moodAvg!)}'}');
    }
    if (tags.isNotEmpty) b.writeln('Чаще всего: ${tags.take(5).map((t) => '${t.$1} (${t.$2})').join(', ')}');
    if (wins.isNotEmpty) {
      b.writeln();
      b.writeln('Победы:');
      for (final (_, w) in wins.take(15)) {
        b.writeln('- $w');
      }
    }
    final r = review;
    if (r != null) {
      final f = journalFields(r.kind);
      void section(String? label, String? text) {
        final lines = listLines(text);
        if (label == null || lines.isEmpty) return;
        b.writeln();
        b.writeln('$label:');
        for (final l in lines) {
          b.writeln(lines.length > 1 ? '- $l' : l);
        }
      }

      if (period == ReportPeriod.day && r.mood != null) b.writeln('Настроение: ${r.mood} из 10');
      if (period != ReportPeriod.day) section(f.wins, r.wins);
      if (period == ReportPeriod.day) section(f.gratitude, r.gratitude);
      section(f.lesson, r.lesson);
      section(f.focus, r.focus);
      section(period == ReportPeriod.day ? f.body : 'Обзор', r.body);
    }
    return b.toString().trimRight();
  }
}

Future<WeekReport> buildWeekReport(AppDatabase db, int monday, {int? today}) => buildReport(db, ReportPeriod.week, monday, today: today);

/// Итоги периода, в который входит [day].
Future<WeekReport> buildReport(AppDatabase db, ReportPeriod period, int day, {int? today, bool compare = true}) async {
  final range = periodRange(period, day);
  final from = range.from;
  final to = range.to;
  final monday = from;
  final t = today ?? todayKey();
  // Неделя, которая ещё идёт, считается только до сегодня.
  final until = to < t ? to : t;

  final habits = await (db.select(db.habits)..where((h) => h.archived.equals(false))).get();
  final logs = await db.habitLogsBetween(from, until);
  final habitWeeks = <HabitWeek>[];
  for (final h in habits) {
    final own = logs.where((l) => l.habitId == h.id).toList();
    final c = habitCompletion(daysMask: h.daysMask, doneDays: {for (final l in own) l.day}, from: from, to: until);
    if (c.planned == 0 && own.isEmpty) continue;
    habitWeeks.add(HabitWeek(h, c.planned, own.length, own.where((l) => l.minimum).length));
  }

  final trackers = await (db.select(db.trackers)..where((x) => x.archived.equals(false))).get();
  final entries = await db.entriesBetween(from, to);
  final before = await db.entriesBetween(0, addDays(from, -1));
  final trackerWeeks = <TrackerWeek>[];
  for (final tr in trackers) {
    final own = entries.where((e) => e.trackerId == tr.id).toList();
    if (own.isEmpty) continue;
    var label = periodSummary(tr, own).label;
    if (tr.kind == TrackerKind.number) {
      final prev = dailySeries(tr, before);
      final last = dailySeries(tr, own).last.$2;
      if (prev.isNotEmpty) {
        final diff = last - prev.last.$2;
        final sign = diff > 0 ? '+' : (diff < 0 ? '−' : '±');
        label = '${formatTrackerValue(tr, last)} ($sign${formatNumber(diff.abs(), maxDecimals: 2)} за неделю)';
      } else {
        label = formatTrackerValue(tr, last);
      }
    }
    final levels = [for (final (_, v) in dailySeries(tr, own)) trackerLevel(tr, v)];
    if (levels.any((l) => l != null)) {
      final full = levels.where((l) => l == Level.full).length;
      final min = levels.where((l) => l == Level.minimum).length;
      label += '; норма $full дн.${min > 0 ? ', минимум $min дн.' : ''}';
    }
    trackerWeeks.add(TrackerWeek(tr, label));
  }

  final programs = await (db.select(db.programs)..where((p) => p.archived.equals(false))).get();
  final scheduledMask = programs.fold<int>(0, (m, p) => m | p.daysMask);
  var planned = 0;
  for (var d = from; d <= until; d = addDays(d, 1)) {
    if (maskHasDay(scheduledMask, d)) planned++;
  }
  final sessions = await db.sessionsBetween(from, to);

  final txs = await db.transactionsBetween(from, to);
  final cats = {for (final c in await db.select(db.categories).get()) c.id: c};
  final byCat = <String, double>{};
  for (final tx in txs.where((x) => !x.isIncome)) {
    final name = cats[tx.categoryId]?.name ?? 'Без категории';
    byCat[name] = (byCat[name] ?? 0) + tx.amount;
  }
  final top = byCat.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => b.$2.compareTo(a.$2));

  final moves = await db.fundMovesBetween(from, to);
  final funds = {for (final f in await db.select(db.funds).get()) f.id: f};
  final byFund = <int, double>{};
  for (final m in moves) {
    byFund[m.fundId] = (byFund[m.fundId] ?? 0) + m.amount;
  }

  final journal = await db.journalBetween(from, to);
  final dayNotes = journal.where((j) => j.kind == JournalKind.day).toList();
  final moods = [
    for (final j in dayNotes)
      if (j.mood != null) j.mood!,
  ];
  final rk = reviewKind(period);
  final review = journal.where((j) => j.kind == rk && j.day == monday).firstOrNull;
  final tagCount = <String, int>{};
  for (final j in dayNotes) {
    for (final tag in parseTags(j.tags)) {
      tagCount[tag] = (tagCount[tag] ?? 0) + 1;
    }
  }
  final tags = [for (final e in tagCount.entries) (e.key, e.value)]..sort((a, b) => b.$2.compareTo(a.$2));
  final wins = [
    for (final j in dayNotes..sort((a, b) => a.day.compareTo(b.day)))
      for (final w in listLines(j.wins)) (j.day, w),
  ];

  // Цели: где были до периода и где сейчас.
  final goalRows = await (db.select(db.goals)..where((g) => g.archived.equals(false))).get();
  final sources = await db.loadGoalSources();
  final goalMoves = <GoalMove>[];
  for (final g in goalRows) {
    if (g.achievedDay != null && g.achievedDay! < from) continue;
    final st = goalStatus(g, sources, today: until);
    final before = goalValueAt(g, sources, addDays(from, -1)) ?? (g.startDay < from ? null : goalBounds(g, sources).start);
    final after = goalValueAt(g, sources, until);
    if (after == null) continue;
    String f(double v) => formatGoalValue(g, sources, v);
    String text;
    if (before == null || before == after) {
      text = before == null ? f(after) : '${f(after)}, без изменений';
    } else {
      final d = after - before;
      final sign = d > 0 ? '+' : '−';
      final abs = goalIsMoney(g) ? formatMoney(d.abs()) : formatNumber(d.abs(), maxDecimals: 2);
      text = '${f(before)} → ${f(after)} ($sign$abs)';
    }
    goalMoves.add(GoalMove(g, st, before, after, text));
  }

  PrevStats? prev;
  if (compare) {
    final p = await buildReport(db, period, shiftPeriod(period, from, -1), today: t, compare: false);
    prev = PrevStats(habitsRate: p.habitsRate, moodAvg: p.moodAvg, expenses: p.expenses, workoutsDone: p.workoutsDone);
  }

  final settings = {for (final r in await db.select(db.settings).get()) r.key: r.value};
  final sleepGoals = SleepGoals.from(settings);
  final sleepLogs = await db.sleepBetween(from, to);
  final foodGoals = FoodGoals.from(settings);
  final meals = await db.mealsBetween(from, to);
  final water = await db.waterBetween(from, to);
  final foodDays = {for (final m in meals) m.day}.toList();
  final totals = [for (final d in foodDays) dayFood(d, meals, water)];

  return WeekReport(
    sleep: sleepLogs.isEmpty ? null : SleepWeek(sleepStats(sleepLogs, sleepGoals, from: from, to: to, today: until), sleepGoals),
    food: totals.isEmpty
        ? null
        : FoodWeek(
            days: totals.length,
            avgKcal: totals.fold<double>(0, (a, x) => a + x.kcal) / totals.length,
            avgProtein: totals.fold<double>(0, (a, x) => a + x.protein) / totals.length,
            onTarget: totals.where((x) => foodLevel(x, foodGoals) == Level.full).length,
            minimum: totals.where((x) => foodLevel(x, foodGoals) == Level.minimum).length,
            goals: foodGoals,
          ),
    from: from,
    to: to,
    habits: habitWeeks,
    trackers: trackerWeeks,
    workoutsDone: sessions.length,
    workoutsMinimum: sessions.where((s) => s.minimum).length,
    hardDays: (await db.hardDaysBetween(from, until)).length,
    workoutsPlanned: planned,
    workoutNames: [for (final s in sessions..sort((a, b) => a.day.compareTo(b.day))) s.programName],
    expenses: txs.where((x) => !x.isIncome).fold(0, (a, x) => a + x.amount),
    income: txs.where((x) => x.isIncome).fold(0, (a, x) => a + x.amount),
    topCategories: top.take(5).toList(),
    fundMoves: [
      for (final e in byFund.entries)
        if (funds[e.key] != null) (funds[e.key]!, e.value),
    ],
    moodAvg: moods.isEmpty ? null : moods.reduce((a, b) => a + b) / moods.length,
    dayNotes: dayNotes.length,
    review: review,
    period: period,
    days: until < from ? 0 : daysBetween(from, until) + 1,
    goals: goalMoves,
    moods: moodSeries(journal, from: from, to: to),
    wins: wins,
    tags: tags,
    prev: prev,
  );
}
