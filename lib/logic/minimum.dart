/// Норма и минимум: общий язык для привычек, трекеров, тренировок, сна и питания.
library;

import '../data/database.dart';

/// Насколько выполнено за день.
enum Level {
  /// Записано, но меньше минимума.
  below,

  /// Минимум есть, до нормы не дотянул.
  minimum,

  /// Норма.
  full,
}

/// Уровень по значению и порогам.
///
/// Без порогов любое значение считается нормой. Если задан только минимум, он и есть норма.
/// Если задана только норма, всё, что меньше неё, считается минимумом.
Level levelOf(double value, {double? goal, double? min}) {
  if (goal == null && min == null) return Level.full;
  if (goal != null && value >= goal) return Level.full;
  if (min != null && value < min) return Level.below;
  return goal == null ? Level.full : Level.minimum;
}

/// У каких трекеров бывают пороги: у чисел и времени.
bool trackerHasThresholds(TrackerKind k) => k == TrackerKind.number || k == TrackerKind.duration;

/// Уровень трекера за день. null, если записи нет или трекер без порогов.
Level? trackerLevel(Tracker t, double? value) {
  if (value == null || !trackerHasThresholds(t.kind)) return null;
  if (t.dailyGoal == null && t.dailyMin == null) return null;
  return levelOf(value, goal: t.dailyGoal, min: t.dailyMin);
}

/// Засчитывается ли запись трекера как выполнение за день.
bool trackerCounts(Tracker t, double? value) {
  if (value == null) return false;
  if (t.kind == TrackerKind.yesNo) return value > 0;
  return trackerLevel(t, value) != Level.below;
}

/// Сколько подходов делать на упражнение в облегчённой тренировке.
int lightSets(Program p, ProgramExercise e) => (p.minSets ?? 1).clamp(1, e.sets);

/// Тренировка считается облегчённой, если подходов меньше, чем в плане.
bool sessionIsMinimum({required int plannedSets, required int doneSets}) => doneSets < plannedSets;

/// Цель: достигнут ли минимум. Направление берётся из старта и цели.
bool goalMinimumReached({required double start, required double target, required double? minimum, required double? current}) {
  if (minimum == null || current == null) return false;
  return target >= start ? current >= minimum : current <= minimum;
}
