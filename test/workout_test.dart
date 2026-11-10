import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/database.dart';
import 'package:planer/data/dates.dart';
import 'package:planer/data/exercise_catalog.dart';
import 'package:planer/data/queries.dart';
import 'package:planer/data/templates.dart';
import 'package:planer/data/workout_queries.dart';
import 'package:planer/logic/workout.dart';

SessionSet set(int session, String name, int reps, {double? weight, int index = 0}) =>
    SessionSet(id: 0, sessionId: session, exerciseName: name, setIndex: index, reps: reps, weight: weight);

Advice advise(
  List<int> last, {
  String name = 'Отжимания от пола',
  int sets = 3,
  int min = 10,
  int max = 12,
  List<int> history = const [],
}) => adviseNext(name: name, sets: sets, repsMin: min, repsMax: max, unit: 'повт', last: last, history: history);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('прогрессия', () {
    test('первый раз: нижняя граница', () {
      final a = advise([]);
      expect(a.kind, AdviceKind.start);
      expect(a.targets, [10, 10, 10]);
    });

    test('добираем по одному повтору в первом незаполненном подходе', () {
      final a = advise([12, 11, 10]);
      expect(a.kind, AdviceKind.build);
      expect(a.targets, [12, 12, 10]);
    });

    test('все подходы на верхней границе: следующая ступень лестницы', () {
      final a = advise([12, 12, 12]);
      expect(a.kind, AdviceKind.levelUp);
      expect(a.text, contains('Отжимания ноги на стуле'));
    });

    test('без лестницы и с весом: прибавить вес', () {
      final a = adviseNext(name: 'Своё', sets: 2, repsMin: 8, repsMax: 10, unit: 'повт', last: [10, 10], weighted: true);
      expect(a.kind, AdviceKind.levelUp);
      expect(a.text, contains('вес'));
    });

    test('слишком тяжело: предлагает ступень ниже', () {
      final a = advise([7, 6, 9]);
      expect(a.kind, AdviceKind.tooHard);
      expect(a.text, contains('Отжимания с колен'));
    });

    test('упражнение на время: +5 секунд', () {
      final a = adviseNext(name: 'Планка', sets: 2, repsMin: 30, repsMax: 60, unit: 'сек', last: [40, 35]);
      expect(a.targets, [45, 35]);
    });

    test('застой три тренировки подряд', () {
      expect(isStalled([30, 33, 33, 32, 33]), isTrue);
      expect(isStalled([30, 31, 32, 33]), isFalse);
      expect(isStalled([30, 31, 32]), isFalse);
      expect(advise([11, 11, 10], history: [30, 32, 32, 31, 32]).kind, AdviceKind.stalled);
    });
  });

  test('рекорды и новые рекорды', () {
    final before = [set(1, 'X', 8), set(1, 'X', 8), set(2, 'X', 9, weight: 5)];
    final r = recordsOf(before);
    expect(r.bestSet, 9);
    expect(r.bestTotal, 16);
    expect(r.maxWeight, 5);
    expect(r.sessions, 2);
    expect(r.bestMax, closeTo(6.5, 0.01));
    expect(newRecords('повт', before, [set(3, 'X', 10)]), ['лучший подход: 10 повт.']);
    expect(newRecords('повт', before, [set(3, 'X', 9), set(3, 'X', 9)]), ['больше всего за тренировку: 18 повт.']);
    expect(newRecords('повт', const [], [set(3, 'X', 10)]), isEmpty);
  });

  test('подходы на мышцы: основная целиком, вспомогательная наполовину', () {
    final m = muscleSets(
      [set(1, 'Отжимания от пола', 10), set(1, 'Подтягивания', 8), set(1, 'Своё', 5)],
      muscleByName: {'Своё': Muscle.legs},
    );
    expect(m[Muscle.chest], 1);
    expect(m[Muscle.back], 1);
    expect(m[Muscle.arms], 1); // по 0,5 от отжиманий и подтягиваний
    expect(m[Muscle.shoulders], 0.5);
    expect(m[Muscle.legs], 1);
  });

  test('недели подряд по плану', () {
    const today = 20261111; // среда
    final days = [20261109, 20261102, 20261104, 20261106, 20261026, 20261028, 20261030];
    expect(weekStreak(sessionDays: days, perWeek: 3, today: today), 2);
    expect(weekStreak(sessionDays: [...days, 20261110, 20261111], perWeek: 3, today: today), 3);
    expect(weekStreak(sessionDays: days, perWeek: 0, today: today), 3);
    final weeks = sessionsPerWeek(days, today: today, weeks: 3);
    expect(weeks.map((w) => w.$2), [3, 3, 1]);
  });

  test('справочник: все упражнения лестниц есть, у шаблона известны мышцы', () {
    for (final chain in exerciseChains.values) {
      for (final name in chain) {
        expect(catalogExercise(name), isNotNull, reason: name);
      }
    }
    for (final r in readyPrograms) {
      for (final name in r.exercises) {
        expect(catalogExercise(name), isNotNull, reason: name);
      }
    }
    expect(catalogExercise('мёртвый жук')?.muscle, Muscle.core);
    expect(nextStep('Подтягивания'), 'Подтягивания с паузой наверху');
    expect(previousStep('Подтягивания'), 'Подтягивания с резинкой');
    expect(nextStep('Подтягивания лучником'), isNull);
    expect(formatClock(65), '1:05');
    expect(formatClock(3725), '1:02:05');
    expect(formatRest(90), '1,5 мин');
  });

  test('шаблон «Мой план»: каждое упражнение есть в справочнике', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await applyTemplate(db, 'my_plan', today: todayKey());
    for (final e in await db.select(db.programExercises).get()) {
      expect(catalogExercise(e.name), isNotNull, reason: e.name);
    }
  });

  test('тренировка в базе: история упражнения, черновик, порядок, готовые программы', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.addReadyProgram(readyPrograms.first);
    final exercises = await db.exercisesOf(id);
    expect(exercises.first.name, 'Подтягивания');
    expect(exercises.first.restSec, 120);

    final s1 = await db.saveWorkout(
      programId: id,
      programName: 'A',
      day: 20261102,
      durationSec: 2400,
      sets: [
        SessionSetsCompanion.insert(sessionId: 0, exerciseName: 'Подтягивания', setIndex: 0, reps: 6),
        SessionSetsCompanion.insert(sessionId: 0, exerciseName: 'Подтягивания', setIndex: 1, reps: 5),
      ],
    );
    await db.saveWorkout(
      programId: id,
      programName: 'A',
      day: 20261104,
      sets: [SessionSetsCompanion.insert(sessionId: 0, exerciseName: 'подтягивания', setIndex: 0, reps: 7)],
    );
    final history = await db.exerciseHistory('Подтягивания');
    expect(history.length, 2);
    expect(history.first.sets.single.reps, 7);
    expect(history.last.sets.map((s) => s.reps), [6, 5]);
    await db.updateSessionInfo(s1, feel: 4, note: 'ок');
    final saved = await (db.select(db.workoutSessions)..where((t) => t.id.equals(s1))).getSingle();
    expect(saved.durationSec, 2400);
    expect(saved.feel, 4);

    await db.reorderExercises([for (final e in exercises.reversed) e.id]);
    expect((await db.exercisesOf(id)).first.name, exercises.last.name);

    final copy = await db.duplicateProgram((await db.select(db.programs).get()).first);
    expect((await db.exercisesOf(copy)).length, exercises.length);

    expect(await db.workoutDraft(), isNull);
    final draft = WorkoutDraft(
      programId: id,
      programName: 'A',
      startedAt: DateTime(2026, 11, 9, 18),
      day: 20261109,
      light: false,
      note: 'тест',
      exercises: [
        DraftExercise(exerciseId: exercises.first.id, name: 'Подтягивания', sets: [(7, null, true), (null, 2.5, false)]),
      ],
    );
    await db.saveWorkoutDraft(draft);
    final back = await db.workoutDraft();
    expect(back!.note, 'тест');
    expect(back.exercises.single.sets, [(7, null, true), (null, 2.5, false)]);
    await db.saveWorkoutDraft(null);
    expect(await db.workoutDraft(), isNull);

    await db.setSportGoal('Подтягивания', 15);
    expect(await db.watchSportGoals().first, {'Подтягивания': 15});
    await db.setSportGoal('Подтягивания', null);
    expect(await db.watchSportGoals().first, isEmpty);
  });

  test('переход с версии 4: новые столбцы спорта, старые тренировки на месте', () async {
    final dir = await Directory.systemTemp.createTemp('planer_migration5');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final current = AppDatabase(NativeDatabase(file));
    await current.customStatement("INSERT INTO workout_sessions (program_name, day, at, minimum) VALUES ('A', 20261102, 0, 0)");
    for (final (table, column) in [
      ('program_exercises', 'muscle'),
      ('program_exercises', 'rest_sec'),
      ('workout_sessions', 'duration_sec'),
      ('workout_sessions', 'feel'),
    ]) {
      await current.customStatement('ALTER TABLE "$table" DROP COLUMN "$column"');
    }
    await current.customStatement('PRAGMA user_version = 4');
    await current.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final s = (await db.select(db.workoutSessions).get()).single;
    expect(s.programName, 'A');
    expect(s.durationSec, isNull);
    await db.saveExercise(
      ProgramExercisesCompanion.insert(
        programId: await db.saveProgram(ProgramsCompanion.insert(name: 'B')),
        name: 'X',
        restSec: const Value(60),
      ),
    );
    expect((await db.select(db.programExercises).get()).single.restSec, 60);
  });
}
