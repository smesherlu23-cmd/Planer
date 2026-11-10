import 'package:drift/drift.dart';

import '../logic/focus.dart';
import '../logic/tasks.dart';
import 'database.dart';
import 'dates.dart';

/// Запросы модуля «Время»: задачи и таймер фокуса.
extension TimeQueries on AppDatabase {
  // ---------------------------------------------------------------------------
  // Задачи
  // ---------------------------------------------------------------------------

  Stream<List<Task>> watchTasks() => select(tasks).watch();

  Future<List<Task>> allTasks() => select(tasks).get();

  Future<Task?> taskById(int id) => (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> saveTask(TasksCompanion t) async {
    if (t.id.present) {
      await (update(tasks)..where((x) => x.id.equals(t.id.value))).write(t);
      return t.id.value;
    }
    final maxExp = tasks.sortOrder.max();
    final row = await (selectOnly(tasks)..addColumns([maxExp])).getSingle();
    return into(tasks).insert(t.copyWith(sortOrder: Value((row.read(maxExp) ?? 0) + 1)));
  }

  /// Отметить или снять отметку. У повторяющейся задачи при отметке появляется следующая копия
  /// вместе с шагами, а при снятии отметки эта копия убирается, если её ещё не трогали.
  Future<void> setTaskDone(Task task, bool done, {int? today, DateTime? now}) => transaction(() async {
    final t = today ?? todayKey(now);
    if (!done) {
      await (update(tasks)..where((x) => x.id.equals(task.id))).write(const TasksCompanion(doneDay: Value(null), doneAt: Value(null)));
      if (task.repeat != TaskRepeat.none && task.parentId == null) {
        final doneDay = task.doneDay ?? t;
        final next = nextRepeatDay(task.repeat, task.day ?? doneDay, doneDay);
        await (delete(tasks)..where(
              (x) =>
                  x.title.equals(task.title) &
                  x.day.equals(next) &
                  x.doneDay.isNull() &
                  x.parentId.isNull() &
                  x.repeat.equals(task.repeat.index),
            ))
            .go();
      }
      return;
    }
    await (update(
      tasks,
    )..where((x) => x.id.equals(task.id))).write(TasksCompanion(doneDay: Value(t), doneAt: Value(now ?? DateTime.now())));
    if (task.repeat == TaskRepeat.none || task.parentId != null) return;
    final next = nextRepeatDay(task.repeat, task.day ?? t, t);
    final copyId = await into(tasks).insert(
      TasksCompanion.insert(
        title: task.title,
        note: Value(task.note),
        day: Value(next),
        time: Value(task.time),
        remind: Value(task.remind),
        priority: Value(task.priority),
        estimate: Value(task.estimate),
        kind: Value(task.kind),
        repeat: Value(task.repeat),
        sortOrder: Value(task.sortOrder),
      ),
    );
    final steps = await (select(tasks)..where((x) => x.parentId.equals(task.id))).get();
    for (final s in steps) {
      await into(tasks).insert(TasksCompanion.insert(title: s.title, parentId: Value(copyId), sortOrder: Value(s.sortOrder)));
    }
  });

  /// Перенести задачи на другой день (или во «Входящие», если [day] null).
  Future<void> moveTasks(Iterable<int> ids, int? day) =>
      (update(tasks)..where((x) => x.id.isIn(ids))).write(TasksCompanion(day: Value(day)));

  Future<void> deleteTask(int id) => (delete(tasks)..where((x) => x.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // Фокус
  // ---------------------------------------------------------------------------

  Stream<List<FocusSession>> watchFocus({int? from}) {
    final q = select(focusSessions)..orderBy([(t) => OrderingTerm(expression: t.at, mode: OrderingMode.desc)]);
    if (from != null) q.where((t) => t.day.isBiggerOrEqualValue(from));
    return q.watch();
  }

  Future<int> addFocus({required DateTime at, required int minutes, int? taskId, BlockKind? kind}) =>
      into(focusSessions)
          .insert(FocusSessionsCompanion.insert(day: dayKey(at), at: at, minutes: minutes, taskId: Value(taskId), kind: Value(kind)));

  Future<FocusState?> focusState() async {
    final row = await (select(settings)..where((t) => t.key.equals(focusSettingKey))).getSingleOrNull();
    return FocusState.decode(row?.value);
  }

  Future<void> setFocusState(FocusState? s) async {
    if (s == null) {
      await (delete(settings)..where((t) => t.key.equals(focusSettingKey))).go();
    } else {
      await into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: focusSettingKey, value: s.encode()));
    }
  }

  /// Если рабочий отрезок уже закончился, записать его и убрать таймер. Возвращает записанные минуты.
  /// Вызывается при открытии экрана и каждую секунду, пока он открыт, поэтому отрезок не потеряется,
  /// даже если приложение было закрыто.
  Future<int?> finishFocusIfDue({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final s = await focusState();
    if (s == null || !s.finished(n)) return null;
    await setFocusState(null);
    if (s.isBreak) return 0;
    await addFocus(
      at: s.end!.subtract(Duration(minutes: s.minutes)),
      minutes: s.minutes,
      taskId: s.taskId,
      kind: s.kind,
    );
    // Помним, сколько рабочих кругов подряд прошло: для подсказки о длинном перерыве.
    await into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: 'focus_round', value: '${s.round}'));
    return s.minutes;
  }

  /// Остановить таймер раньше. Если отработана хотя бы минута, она записывается.
  Future<int> stopFocus({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final s = await focusState();
    await setFocusState(null);
    if (s == null || s.isBreak) return 0;
    final m = s.elapsedMinutes(n);
    if (m >= 1) await addFocus(at: s.startedAt(n), minutes: m, taskId: s.taskId, kind: s.kind);
    return m;
  }
}
