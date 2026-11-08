/// Отчёт за неделю: всё, что произошло с понедельника по воскресенье.
library;

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import 'calc.dart';
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

class WeekReport {
  WeekReport({
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
  });

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

  int get habitsPlanned => habits.fold(0, (a, h) => a + h.planned);
  int get habitsDone => habits.fold(0, (a, h) => a + h.done);

  /// Текст для копирования: отправить в чат, сохранить, показать Claude.
  String toText() {
    final b = StringBuffer();
    b.writeln('Planer: неделя ${formatDay(from)} – ${formatDay(to, withYear: true)}');
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
      b.writeln('Тренировки: $workoutsDone из $workoutsPlanned${workoutNames.isEmpty ? '' : ' (${workoutNames.join(', ')})'}');
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

  return WeekReport(
    from: from,
    to: to,
    habits: habitWeeks,
    trackers: trackerWeeks,
    workoutsDone: sessions.length,
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
