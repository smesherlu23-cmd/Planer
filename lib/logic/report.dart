/// Отчёт за неделю: всё, что произошло с понедельника по воскресенье.
library;

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import 'calc.dart';
import 'food.dart';
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
  });

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
    b.writeln('Planer: неделя ${formatDay(from)} – ${formatDay(to, withYear: true)}');
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
    if (dayNotes > 0) {
      b.writeln();
      b.writeln('Итогов дня: $dayNotes из 7${moodAvg == null ? '' : ', среднее настроение ${formatNumber(moodAvg!)}'}');
    }
    if (review != null && review!.body.trim().isNotEmpty) {
      b.writeln();
      b.writeln('Обзор недели:');
      b.writeln(review!.body.trim());
    }
    return b.toString().trimRight();
  }
}

Future<WeekReport> buildWeekReport(AppDatabase db, int monday, {int? today}) async {
  final from = monday;
  final to = addDays(monday, 6);
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
  final review = journal.where((j) => j.kind == JournalKind.week && j.day == monday).firstOrNull;

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
  );
}
