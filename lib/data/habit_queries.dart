import 'package:drift/drift.dart';

import '../logic/habits.dart';
import 'database.dart';
import 'queries.dart';

/// Запросы модуля привычек: количество за день, пропуски, заметки, порядок.
extension HabitQueries on AppDatabase {
  Stream<List<HabitDay>> watchAllHabitDays() => select(habitDays).watch();

  Stream<List<HabitDay>> watchHabitDaysOf(int habitId) => (select(habitDays)..where((t) => t.habitId.equals(habitId))).watch();

  Future<HabitLog?> habitLogOn(int habitId, int day) =>
      (select(habitLogs)..where((t) => t.habitId.equals(habitId) & t.day.equals(day))).getSingleOrNull();

  Future<HabitDay?> habitDayOn(int habitId, int day) => _habitDay(habitId, day);

  Future<HabitDay?> _habitDay(int habitId, int day) =>
      (select(habitDays)..where((t) => t.habitId.equals(habitId) & t.day.equals(day))).getSingleOrNull();

  /// Изменить подробности дня. Пустая строка удаляется.
  Future<void> _updateDay(int habitId, int day, HabitDay Function(HabitDay) change) async {
    final old = await _habitDay(habitId, day) ?? HabitDay(id: -1, habitId: habitId, day: day, skipped: false);
    final next = change(old);
    final empty = (next.value == null || next.value == 0) && !next.skipped && (next.note == null || next.note!.trim().isEmpty);
    if (old.id != -1) {
      if (empty) {
        await (delete(habitDays)..where((t) => t.id.equals(old.id))).go();
      } else {
        await (update(habitDays)..where((t) => t.id.equals(old.id))).write(
          HabitDaysCompanion(value: Value(next.value), skipped: Value(next.skipped), note: Value(next.note)),
        );
      }
    } else if (!empty) {
      await into(habitDays).insert(
        HabitDaysCompanion.insert(
          habitId: habitId,
          day: day,
          value: Value(next.value),
          skipped: Value(next.skipped),
          note: Value(next.note),
        ),
      );
    }
  }

  /// Записать количество за день. Дотянул до цели: день отмечается сделанным; меньше: отметка снимается.
  Future<void> setHabitValue(Habit habit, int day, double value) => transaction(() async {
    final v = value < 0 ? 0.0 : value;
    await _updateDay(habit.id, day, (d) => d.copyWith(value: Value(v), skipped: false));
    final target = habit.target;
    if (target == null) return;
    final log = await (select(habitLogs)..where((t) => t.habitId.equals(habit.id) & t.day.equals(day))).getSingleOrNull();
    if (v >= target && (log == null || log.minimum)) {
      await setHabitDone(habit.id, day, done: true);
    } else if (v < target && log != null && !log.minimum) {
      await setHabitDone(habit.id, day, done: false);
    }
  });

  /// Отметить или снять отметку. У привычки-количества отметка ставит количество равным цели.
  Future<void> toggleHabit(Habit habit, int day, {required bool done, bool minimum = false}) => transaction(() async {
    await setHabitDone(habit.id, day, done: done, minimum: minimum);
    if (done) await _updateDay(habit.id, day, (d) => d.copyWith(skipped: false));
    final target = habit.target;
    if (target != null && !minimum) {
      final current = (await _habitDay(habit.id, day))?.value ?? 0;
      if (done && current < target) await _updateDay(habit.id, day, (d) => d.copyWith(value: Value(target)));
      if (!done && current >= target) await _updateDay(habit.id, day, (d) => d.copyWith(value: const Value(null)));
    }
  });

  /// Пропуск по уважительной причине (болезнь, дорога): серию не рвёт.
  Future<void> setHabitSkipped(int habitId, int day, bool skipped) => transaction(() async {
    if (skipped) await setHabitDone(habitId, day, done: false);
    await _updateDay(habitId, day, (d) => d.copyWith(skipped: skipped));
  });

  Future<void> setHabitNote(int habitId, int day, String? note) =>
      _updateDay(habitId, day, (d) => d.copyWith(note: Value(note == null || note.trim().isEmpty ? null : note.trim())));

  /// Новый порядок привычек.
  Future<void> reorderHabits(List<int> ids) => transaction(() async {
    for (var i = 0; i < ids.length; i++) {
      await (update(habits)..where((t) => t.id.equals(ids[i]))).write(HabitsCompanion(sortOrder: Value(i)));
    }
  });
}

/// Расписание привычки для расчётов. Начало: день создания или первая отметка, если она раньше.
HabitPlan planOf(Habit h, [HabitMarks? m]) {
  var first = dayKeyOf(h.createdAt);
  for (final d in [...?m?.done, ...?m?.skipped]) {
    if (d < first) first = d;
  }
  return HabitPlan(daysMask: h.daysMask, perWeek: h.perWeek, firstDay: first);
}

int dayKeyOf(DateTime t) => t.year * 10000 + t.month * 100 + t.day;

/// Отметки привычки из таблиц.
HabitMarks marksOf(int habitId, Iterable<HabitLog> logs, Iterable<HabitDay> days) => HabitMarks(
  done: {
    for (final l in logs)
      if (l.habitId == habitId) l.day,
  },
  skipped: {
    for (final d in days)
      if (d.habitId == habitId && d.skipped) d.day,
  },
);
