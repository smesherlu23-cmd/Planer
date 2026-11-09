/// Таймер фокуса (метод помидора) и итоги по времени.
///
/// Состояние таймера хранится в настройке `focus` как JSON с моментом окончания.
/// Поэтому таймер не сбивается, если закрыть приложение: остаток считается от часов.
library;

import 'dart:convert';

import '../data/database.dart';
import '../data/dates.dart';
import 'day_plan.dart';

const focusSettingKey = 'focus';
const focusPresets = [15, 25, 45, 60, 90];
const breakPresets = [5, 10, 15];

class FocusState {
  const FocusState({required this.minutes, required this.isBreak, this.end, this.left, this.taskId, this.kind, this.round = 1});

  /// Длина отрезка в минутах.
  final int minutes;
  final bool isBreak;

  /// Когда закончится. null: на паузе.
  final DateTime? end;

  /// Сколько секунд осталось на паузе.
  final int? left;
  final int? taskId;
  final BlockKind? kind;

  /// Какой по счёту рабочий отрезок подряд: после четвёртого советуем длинный перерыв.
  final int round;

  bool get paused => end == null;

  static FocusState start({required int minutes, bool isBreak = false, int? taskId, BlockKind? kind, int round = 1, DateTime? now}) =>
      FocusState(
        minutes: minutes,
        isBreak: isBreak,
        end: (now ?? DateTime.now()).add(Duration(minutes: minutes)),
        taskId: taskId,
        kind: kind,
        round: round,
      );

  int secondsLeft(DateTime now) {
    if (end == null) return left ?? minutes * 60;
    final s = end!.difference(now).inMilliseconds / 1000;
    return s <= 0 ? 0 : s.ceil();
  }

  bool finished(DateTime now) => !paused && secondsLeft(now) == 0;

  /// Сколько минут отработано на момент [now].
  int elapsedMinutes(DateTime now) => ((minutes * 60 - secondsLeft(now)) / 60).floor();

  /// Когда начался отрезок.
  DateTime startedAt(DateTime now) => now.subtract(Duration(seconds: minutes * 60 - secondsLeft(now)));

  FocusState pause(DateTime now) =>
      FocusState(minutes: minutes, isBreak: isBreak, left: secondsLeft(now), taskId: taskId, kind: kind, round: round);

  FocusState resume(DateTime now) => FocusState(
    minutes: minutes,
    isBreak: isBreak,
    end: now.add(Duration(seconds: left ?? minutes * 60)),
    taskId: taskId,
    kind: kind,
    round: round,
  );

  String encode() => jsonEncode({
    'minutes': minutes,
    'break': isBreak,
    if (end != null) 'end': end!.millisecondsSinceEpoch,
    if (left != null) 'left': left,
    if (taskId != null) 'task': taskId,
    if (kind != null) 'kind': kind!.index,
    'round': round,
  });

  static FocusState? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final end = m['end'] as int?;
      final kind = m['kind'] as int?;
      return FocusState(
        minutes: m['minutes'] as int,
        isBreak: m['break'] as bool? ?? false,
        end: end == null ? null : DateTime.fromMillisecondsSinceEpoch(end),
        left: m['left'] as int?,
        taskId: m['task'] as int?,
        kind: kind == null || kind < 0 || kind >= BlockKind.values.length ? null : BlockKind.values[kind],
        round: m['round'] as int? ?? 1,
      );
    } catch (_) {
      return null;
    }
  }
}

String formatClock(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

// ---------------------------------------------------------------------------
// Итоги
// ---------------------------------------------------------------------------

class TimeWeek {
  const TimeWeek({
    required this.days,
    required this.focusByDay,
    required this.doneByDay,
    required this.focusByKind,
    required this.planByKind,
    required this.topTasks,
    required this.estimateRatio,
    required this.estimateSamples,
  });

  /// Семь дней с понедельника.
  final List<int> days;
  final List<int> focusByDay;
  final List<int> doneByDay;
  final Map<BlockKind?, int> focusByKind;

  /// Сколько минут на сферу заложено в плане дня за неделю.
  final Map<BlockKind, int> planByKind;

  /// Задачи, на которые ушло больше всего фокуса: (название, минуты).
  final List<(String, int)> topTasks;

  /// Во сколько раз реальное время больше оценки. null: мало данных.
  final double? estimateRatio;
  final int estimateSamples;

  int get focusTotal => focusByDay.fold(0, (a, b) => a + b);
  int get doneTotal => doneByDay.fold(0, (a, b) => a + b);
  int get activeDays => focusByDay.where((m) => m > 0).length;
}

TimeWeek timeWeek({
  required int weekStartDay,
  required List<Task> tasks,
  required List<FocusSession> sessions,
  required List<TimeBlock> blocks,
}) {
  final days = [for (var i = 0; i < 7; i++) addDays(weekStartDay, i)];
  final focusByDay = List.filled(7, 0);
  final doneByDay = List.filled(7, 0);
  final focusByKind = <BlockKind?, int>{};
  final byTask = <int, int>{};
  final taskById = {for (final t in tasks) t.id: t};
  for (final s in sessions) {
    final i = days.indexOf(s.day);
    if (i < 0) continue;
    focusByDay[i] += s.minutes;
    final kind = s.kind ?? taskById[s.taskId]?.kind;
    focusByKind[kind] = (focusByKind[kind] ?? 0) + s.minutes;
    if (s.taskId != null) byTask[s.taskId!] = (byTask[s.taskId!] ?? 0) + s.minutes;
  }
  for (final t in tasks) {
    if (t.parentId != null || t.doneDay == null) continue;
    final i = days.indexOf(t.doneDay!);
    if (i >= 0) doneByDay[i]++;
  }
  final planByKind = <BlockKind, int>{};
  for (var w = 1; w <= 7; w++) {
    final d = distribution(blocksForWeekday(blocks, w));
    for (final e in d.byKind.entries) {
      if (e.key == BlockKind.sleep) continue;
      planByKind[e.key] = (planByKind[e.key] ?? 0) + e.value;
    }
  }
  final top = byTask.entries.where((e) => taskById.containsKey(e.key)).map((e) => (taskById[e.key]!.title, e.value)).toList()
    ..sort((a, b) => b.$2.compareTo(a.$2));

  // Точность оценок считаем по всем сделанным задачам с оценкой и фокусом, не только за неделю.
  final allByTask = <int, int>{};
  for (final s in sessions) {
    if (s.taskId != null) allByTask[s.taskId!] = (allByTask[s.taskId!] ?? 0) + s.minutes;
  }
  var est = 0, real = 0, samples = 0;
  for (final t in tasks) {
    final spent = allByTask[t.id];
    if (t.doneDay == null || t.estimate == null || t.estimate == 0 || spent == null) continue;
    est += t.estimate!;
    real += spent;
    samples++;
  }
  return TimeWeek(
    days: days,
    focusByDay: focusByDay,
    doneByDay: doneByDay,
    focusByKind: focusByKind,
    planByKind: planByKind,
    topTasks: top.take(5).toList(),
    estimateRatio: samples >= 3 ? real / est : null,
    estimateSamples: samples,
  );
}

/// Серия дней подряд с фокусом, считая от сегодня (сегодня без фокуса не обрывает серию).
int focusStreak(Iterable<FocusSession> sessions, int today) {
  final days = {for (final s in sessions) s.day};
  var d = days.contains(today) ? today : addDays(today, -1);
  var n = 0;
  while (days.contains(d)) {
    n++;
    d = addDays(d, -1);
  }
  return n;
}
