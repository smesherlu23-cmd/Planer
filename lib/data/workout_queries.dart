import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';
import 'dates.dart';
import 'exercise_catalog.dart';
import 'queries.dart';

/// Одна тренировка упражнения в истории: когда и какие подходы.
class ExerciseSession {
  ExerciseSession(this.session, this.sets);
  final WorkoutSession session;
  final List<SessionSet> sets;
}

/// Запросы модуля «Спорт».
extension WorkoutQueries on AppDatabase {
  /// Все подходы всех тренировок. Данных немного: за год три тренировки в неделю это пара тысяч строк.
  Stream<List<SessionSet>> watchAllSets() =>
      (select(sessionSets)..orderBy([(t) => OrderingTerm(expression: t.sessionId), (t) => OrderingTerm(expression: t.setIndex)])).watch();

  Stream<List<ProgramExercise>> watchAllExercises() => select(programExercises).watch();

  /// История упражнения по названию, от новых к старым.
  Future<List<ExerciseSession>> exerciseHistory(String name, {int? beforeSession}) async {
    final rows =
        await (select(sessionSets).join([innerJoin(workoutSessions, workoutSessions.id.equalsExp(sessionSets.sessionId))])..orderBy([
              OrderingTerm.desc(workoutSessions.day),
              OrderingTerm.desc(workoutSessions.at),
              OrderingTerm(expression: sessionSets.setIndex),
            ]))
            .get();
    final result = <ExerciseSession>[];
    // SQLite lower() не знает кириллицу, поэтому сравниваем названия здесь.
    String norm(String v) => v.trim().toLowerCase().replaceAll('ё', 'е');
    final key = norm(name);
    for (final r in rows) {
      final set = r.readTable(sessionSets);
      if (norm(set.exerciseName) != key) continue;
      final s = r.readTable(workoutSessions);
      if (beforeSession != null && s.id == beforeSession) continue;
      if (result.isEmpty || result.last.session.id != s.id) result.add(ExerciseSession(s, []));
      result.last.sets.add(set);
    }
    return result;
  }

  /// Сохранить тренировку с длительностью. Возвращает id.
  Future<int> saveWorkout({
    required int? programId,
    required String programName,
    required int day,
    required List<SessionSetsCompanion> sets,
    String? note,
    bool minimum = false,
    int? durationSec,
  }) {
    return transaction(() async {
      final id = await into(workoutSessions).insert(
        WorkoutSessionsCompanion.insert(
          programId: Value(programId),
          programName: programName,
          day: day,
          note: Value(note),
          minimum: Value(minimum),
          durationSec: Value(durationSec),
        ),
      );
      for (final s in sets) {
        await into(sessionSets).insert(s.copyWith(sessionId: Value(id)));
      }
      return id;
    });
  }

  Future<void> updateSessionInfo(int id, {int? feel, String? note}) =>
      (update(workoutSessions)..where((t) => t.id.equals(id))).write(WorkoutSessionsCompanion(feel: Value(feel), note: Value(note)));

  /// Новый порядок упражнений программы.
  Future<void> reorderExercises(List<int> ids) => transaction(() async {
    for (final (i, id) in ids.indexed) {
      await (update(programExercises)..where((t) => t.id.equals(id))).write(ProgramExercisesCompanion(sortOrder: Value(i)));
    }
  });

  /// Копия программы со всеми упражнениями.
  Future<int> duplicateProgram(Program p) => transaction(() async {
    final id = await saveProgram(
      ProgramsCompanion.insert(
        name: '${p.name} (копия)',
        daysMask: Value(p.daysMask),
        note: Value(p.note),
        minSets: Value(p.minSets),
        minimumText: Value(p.minimumText),
      ),
    );
    for (final e in await exercisesOf(p.id)) {
      await saveExercise(
        ProgramExercisesCompanion.insert(
          programId: id,
          name: e.name,
          sets: Value(e.sets),
          repsMin: Value(e.repsMin),
          repsMax: Value(e.repsMax),
          unit: Value(e.unit),
          note: Value(e.note),
          muscle: Value(e.muscle),
          restSec: Value(e.restSec),
        ),
      );
    }
    return id;
  });

  /// Добавить готовую программу из справочника.
  Future<int> addReadyProgram(ReadyProgram r) => transaction(() async {
    final id = await saveProgram(
      ProgramsCompanion.insert(
        name: r.name,
        daysMask: Value(maskFromWeekdays(r.weekdays)),
        note: Value(r.description),
        minSets: const Value(1),
      ),
    );
    for (final name in r.exercises) {
      final c = catalogExercise(name)!;
      await saveExercise(
        ProgramExercisesCompanion.insert(
          programId: id,
          name: c.name,
          sets: Value(c.sets),
          repsMin: Value(c.repsMin),
          repsMax: Value(c.repsMax),
          unit: Value(c.unit),
          note: Value(c.hint),
          restSec: Value(c.restSec),
        ),
      );
    }
    return id;
  });

  // ----- Незаконченная тренировка -----

  static const _draftKey = 'workout_draft';

  Stream<WorkoutDraft?> watchWorkoutDraft() => watchSetting(_draftKey).map(WorkoutDraft.tryParse);

  Future<WorkoutDraft?> workoutDraft() async => WorkoutDraft.tryParse(await getSetting(_draftKey));

  Future<void> saveWorkoutDraft(WorkoutDraft? d) => setSetting(_draftKey, d == null ? null : jsonEncode(d.toJson()));

  // ----- Цели по упражнениям: «15 подтягиваний подряд» -----

  static const _goalsKey = 'sport_goals';

  Stream<Map<String, int>> watchSportGoals() => watchSetting(_goalsKey).map(_parseGoals);

  Future<void> setSportGoal(String exercise, int? target) async {
    final goals = _parseGoals(await getSetting(_goalsKey));
    if (target == null || target <= 0) {
      goals.remove(exercise);
    } else {
      goals[exercise] = target;
    }
    await setSetting(_goalsKey, goals.isEmpty ? null : jsonEncode(goals));
  }

  static Map<String, int> _parseGoals(String? raw) {
    if (raw == null) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return {for (final e in m.entries) e.key: (e.value as num).toInt()};
    } catch (_) {
      return {};
    }
  }
}

/// Тренировка, которая идёт прямо сейчас. Хранится в настройках, чтобы не потерять её,
/// если телефон закрыл приложение.
class WorkoutDraft {
  WorkoutDraft({
    required this.programId,
    required this.programName,
    required this.startedAt,
    required this.day,
    required this.light,
    required this.exercises,
    this.note = '',
  });

  final int programId;
  final String programName;
  final DateTime startedAt;
  final int day;
  final bool light;
  final String note;
  final List<DraftExercise> exercises;

  Map<String, Object?> toJson() => {
    'programId': programId,
    'programName': programName,
    'startedAt': startedAt.toIso8601String(),
    'day': day,
    'light': light,
    'note': note,
    'exercises': [for (final e in exercises) e.toJson()],
  };

  static WorkoutDraft? tryParse(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return WorkoutDraft(
        programId: m['programId'] as int,
        programName: m['programName'] as String,
        startedAt: DateTime.parse(m['startedAt'] as String),
        day: m['day'] as int,
        light: m['light'] as bool? ?? false,
        note: m['note'] as String? ?? '',
        exercises: [for (final e in m['exercises'] as List) DraftExercise.fromJson(e as Map<String, dynamic>)],
      );
    } catch (_) {
      return null;
    }
  }
}

class DraftExercise {
  DraftExercise({required this.exerciseId, required this.name, required this.sets});
  final int? exerciseId;
  final String name;

  /// Подходы: повторы, вес, отмечен ли.
  final List<(int? reps, double? weight, bool done)> sets;

  Map<String, Object?> toJson() => {
    'id': exerciseId,
    'name': name,
    'sets': [
      for (final (r, w, d) in sets) [r, w, d],
    ],
  };

  static DraftExercise fromJson(Map<String, dynamic> m) => DraftExercise(
    exerciseId: m['id'] as int?,
    name: m['name'] as String,
    sets: [for (final s in m['sets'] as List) ((s as List)[0] as int?, (s[1] as num?)?.toDouble(), s[2] as bool)],
  );
}
