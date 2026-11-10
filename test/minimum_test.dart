import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/database.dart';
import 'package:planer/data/queries.dart';
import 'package:planer/logic/food.dart';
import 'package:planer/logic/minimum.dart';
import 'package:planer/logic/report.dart';
import 'package:planer/logic/sleep.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('уровень по порогам', () {
    expect(levelOf(5), Level.full);
    expect(levelOf(60, goal: 60, min: 20), Level.full);
    expect(levelOf(30, goal: 60, min: 20), Level.minimum);
    expect(levelOf(10, goal: 60, min: 20), Level.below);
    // Только норма: всё, что меньше, считается минимумом.
    expect(levelOf(10, goal: 60), Level.minimum);
    // Только минимум: он и есть норма.
    expect(levelOf(25, min: 20), Level.full);
    expect(levelOf(15, min: 20), Level.below);
  });

  test('трекер с порогами отмечает привычку нормой, минимумом или никак', () async {
    final t = await db.saveTracker(
      TrackersCompanion.insert(name: 'Код', kind: TrackerKind.duration, dailyGoal: const Value(60), dailyMin: const Value(20)),
    );
    final h = await db.saveHabit(HabitsCompanion.insert(name: 'Код', trackerId: Value(t)));
    Future<HabitLog?> log(int day) => (db.select(db.habitLogs)..where((l) => l.habitId.equals(h) & l.day.equals(day))).getSingleOrNull();

    await db.addEntry(t, 10, day: 20261109);
    expect(await log(20261109), isNull, reason: 'меньше минимума не засчитывается');
    await db.addEntry(t, 15, day: 20261109);
    expect((await log(20261109))!.minimum, isTrue, reason: '25 минут: минимум');
    await db.addEntry(t, 40, day: 20261109);
    expect((await log(20261109))!.minimum, isFalse, reason: 'добрал до часа: норма');
  });

  test('в тяжёлый день трекер без порогов отмечает привычку минимумом', () async {
    final t = await db.saveTracker(TrackersCompanion.insert(name: 'Чтение', kind: TrackerKind.duration));
    final h = await db.saveHabit(HabitsCompanion.insert(name: 'Чтение', trackerId: Value(t)));
    await db.setHardDay(20261109, true);
    await db.addEntry(t, 15, day: 20261109);
    await db.addEntry(t, 15, day: 20261110);
    final logs = await (db.select(db.habitLogs)..where((l) => l.habitId.equals(h))).get();
    expect({for (final l in logs) l.day: l.minimum}, {20261109: true, 20261110: false});
    expect(await db.hardDaysBetween(20261101, 20261130), [20261109]);
    await db.setHardDay(20261109, false);
    expect(await db.isHardDay(20261109), isFalse);
  });

  test('облегчённая тренировка: меньше подходов, чем в плане', () {
    expect(sessionIsMinimum(plannedSets: 16, doneSets: 5), isTrue);
    expect(sessionIsMinimum(plannedSets: 16, doneSets: 16), isFalse);
    const p = Program(id: 1, name: 'A', daysMask: 0, minSets: 2, archived: false, sortOrder: 0);
    const e = ProgramExercise(id: 1, programId: 1, name: 'x', sets: 4, repsMin: 8, repsMax: 12, unit: 'повт', sortOrder: 0);
    expect(lightSets(p, e), 2);
    expect(lightSets(p.copyWith(minSets: const Value(null)), e), 1);
    expect(lightSets(p.copyWith(minSets: const Value(9)), e), 4);
  });

  test('минимум цели в обе стороны', () {
    expect(goalMinimumReached(start: 67, target: 73, minimum: 71, current: 71.2), isTrue);
    expect(goalMinimumReached(start: 67, target: 73, minimum: 71, current: 70), isFalse);
    expect(goalMinimumReached(start: 120000, target: 0, minimum: 30000, current: 25000), isTrue);
    expect(goalMinimumReached(start: 67, target: 73, minimum: null, current: 80), isFalse);
  });

  test('сон и питание: норма и минимум', () {
    const g = SleepGoals(bed: 23 * 60, wake: 7 * 60, duration: 8 * 60, minimum: 7 * 60);
    SleepLog night(int minutes) => SleepLog(
      id: 1,
      day: 20261109,
      bedAt: DateTime(2026, 11, 8, 23),
      wakeAt: DateTime(2026, 11, 8, 23).add(Duration(minutes: minutes)),
    );
    expect(sleepLevel(night(480), g), Level.full);
    expect(sleepLevel(night(430), g), Level.minimum);
    expect(sleepLevel(night(360), g), Level.below);

    final f = FoodGoals.from({
      'food_kcal': '3000',
      'food_protein': '130',
      'food_kcal_min': '2500',
      'food_protein_min': '100',
      'food_mode': 'gain',
    });
    expect(foodLevel((kcal: 3000, protein: 130, fat: 0, carbs: 0, water: 0), f), Level.full);
    expect(foodLevel((kcal: 2600, protein: 110, fat: 0, carbs: 0, water: 0), f), Level.minimum);
    expect(foodLevel((kcal: 2600, protein: 80, fat: 0, carbs: 0, water: 0), f), Level.below);
    expect(foodLevel((kcal: 0, protein: 0, fat: 0, carbs: 0, water: 0), f), isNull);
  });

  test('отчёт недели считает тяжёлые дни и облегчённые тренировки', () async {
    final p = await db.saveProgram(ProgramsCompanion.insert(name: 'A'));
    final program = await (db.select(db.programs)..where((x) => x.id.equals(p))).getSingle();
    final set = SessionSetsCompanion.insert(sessionId: 0, exerciseName: 'x', setIndex: 0, reps: 10);
    await db.saveSession(program: program, day: 20261110, sets: [set], minimum: true);
    await db.saveSession(program: program, day: 20261112, sets: [set]);
    await db.setHardDay(20261110, true);
    final r = await buildWeekReport(db, 20261109, today: 20261115);
    expect(r.hardDays, 1);
    expect(r.workoutsMinimum, 1);
    expect(r.toText(), contains('Тяжёлых дней: 1'));
    expect(r.toText(), contains('облегчённых 1'));
  });
}
