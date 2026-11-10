import 'dart:async';

import 'package:drift/drift.dart';

import '../logic/goals.dart';
import 'database.dart';
import 'dates.dart';
import 'queries.dart';

/// Запросы модуля целей и дневника.
extension GoalJournalQueries on AppDatabase {
  // ---------------------------------------------------------------------------
  // Цели
  // ---------------------------------------------------------------------------

  Stream<List<Goal>> watchAllGoals() =>
      (select(goals)..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)])).watch();

  Stream<Goal?> watchGoal(int id) => (select(goals)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Stream<List<GoalStep>> watchAllGoalSteps() => select(goalSteps).watch();

  Stream<List<GoalCheckin>> watchAllGoalCheckins() => select(goalCheckins).watch();

  /// Всё, из чего считается прогресс целей, одним потоком.
  Stream<GoalSources> watchGoalSources() {
    final parts = <Stream<Object?>>[
      watchTrackers(),
      watchAllEntries(),
      select(funds).watch(),
      watchAllFundMoves(),
      watchAllGoalSteps(),
      watchAllGoalCheckins(),
    ];
    return _combine(parts).map(
      (v) => GoalSources(
        trackers: {for (final t in v[0] as List<Tracker>) t.id: t},
        entries: v[1] as List<TrackerEntry>,
        funds: {for (final f in v[2] as List<Fund>) f.id: f},
        fundMoves: v[3] as List<FundMove>,
        steps: v[4] as List<GoalStep>,
        checkins: v[5] as List<GoalCheckin>,
      ),
    );
  }

  Future<GoalSources> loadGoalSources() async => GoalSources(
    trackers: {for (final t in await select(trackers).get()) t.id: t},
    entries: await select(trackerEntries).get(),
    funds: {for (final f in await select(funds).get()) f.id: f},
    fundMoves: await select(fundMoves).get(),
    steps: await select(goalSteps).get(),
    checkins: await select(goalCheckins).get(),
  );

  Future<int> addGoalStep(int goalId, String title, {int? dueDay}) async {
    final maxExp = goalSteps.sortOrder.max();
    final row =
        await (selectOnly(goalSteps)
              ..addColumns([maxExp])
              ..where(goalSteps.goalId.equals(goalId)))
            .getSingle();
    return into(
      goalSteps,
    ).insert(GoalStepsCompanion.insert(goalId: goalId, title: title, dueDay: Value(dueDay), sortOrder: Value((row.read(maxExp) ?? 0) + 1)));
  }

  Future<void> updateGoalStep(int id, {String? title, Value<int?> dueDay = const Value.absent()}) => (update(
    goalSteps,
  )..where((t) => t.id.equals(id))).write(GoalStepsCompanion(title: title == null ? const Value.absent() : Value(title), dueDay: dueDay));

  Future<void> setGoalStepDone(int id, bool done, {int? day}) =>
      (update(goalSteps)..where((t) => t.id.equals(id))).write(GoalStepsCompanion(doneDay: Value(done ? (day ?? todayKey()) : null)));

  Future<void> moveGoalStep(List<GoalStep> ordered) => transaction(() async {
    for (var i = 0; i < ordered.length; i++) {
      await (update(goalSteps)..where((t) => t.id.equals(ordered[i].id))).write(GoalStepsCompanion(sortOrder: Value(i)));
    }
  });

  /// Отметить значение цели на день. Одна отметка на день: новая заменяет старую.
  Future<void> addGoalCheckin(int goalId, double value, {int? day, String? note}) => transaction(() async {
    final d = day ?? todayKey();
    await (delete(goalCheckins)..where((t) => t.goalId.equals(goalId) & t.day.equals(d))).go();
    await into(goalCheckins).insert(GoalCheckinsCompanion.insert(goalId: goalId, day: d, value: value, note: Value(note)));
  });

  Future<void> setGoalAchieved(int goalId, int? day) =>
      (update(goals)..where((t) => t.id.equals(goalId))).write(GoalsCompanion(achievedDay: Value(day)));

  // ---------------------------------------------------------------------------
  // Дневник
  // ---------------------------------------------------------------------------

  Stream<List<JournalEntry>> watchAllJournal() =>
      (select(journalEntries)..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.at)])).watch();

  Stream<List<JournalEntry>> watchGoalNotes(int goalId) =>
      (select(journalEntries)
            ..where((t) => t.goalId.equals(goalId))
            ..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.at)]))
          .watch();

  Future<JournalEntry?> journalFor(JournalKind kind, int day) =>
      (select(journalEntries)
            ..where((t) => t.kind.equalsValue(kind) & t.day.equals(day))
            ..limit(1))
          .getSingleOrNull();
}

Stream<List<Object?>> _combine(List<Stream<Object?>> streams) async* {
  final values = List<Object?>.filled(streams.length, null);
  final has = List<bool>.filled(streams.length, false);
  final controller = StreamController<List<Object?>>();
  final subs = <StreamSubscription<Object?>>[];
  for (var i = 0; i < streams.length; i++) {
    subs.add(
      streams[i].listen((v) {
        values[i] = v;
        has[i] = true;
        if (has.every((h) => h)) controller.add(List.of(values));
      }, onError: controller.addError),
    );
  }
  try {
    yield* controller.stream;
  } finally {
    for (final s in subs) {
      await s.cancel();
    }
    await controller.close();
  }
}
