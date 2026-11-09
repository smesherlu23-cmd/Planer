/// Логика спорта: прогрессия, рекорды, объём по мышцам, серии недель.
///
/// Прогрессия двойная, как в большинстве программ на массу: сначала добираешь
/// повторы до верхней границы во всех подходах, потом усложняешь упражнение
/// (следующая ступень лестницы или вес) и снова начинаешь с нижней границы.
library;

import 'dart:math' as math;

import '../data/database.dart';
import '../data/dates.dart';
import '../data/exercise_catalog.dart';

/// Мышца упражнения: сохранённая, иначе из справочника, иначе null.
Muscle? muscleOf(String name, [String? stored]) => Muscle.byKey(stored) ?? catalogExercise(name)?.muscle;

/// Отдых между подходами в секундах.
int restOf(ProgramExercise e) => e.restSec ?? catalogExercise(e.name)?.restSec ?? 90;

enum AdviceKind {
  /// Ещё не делал: начни с нижней границы.
  start,

  /// Добираем повторы.
  build,

  /// Все подходы на верхней границе: пора усложнять.
  levelUp,

  /// В прошлый раз не дотянул до нижней границы.
  tooHard,

  /// Несколько тренировок без прироста.
  stalled,
}

class Advice {
  const Advice(this.kind, this.text, this.targets);
  final AdviceKind kind;
  final String text;

  /// Цель на каждый подход.
  final List<int> targets;
}

/// Сумма повторов (или секунд) за тренировку по упражнению.
int totalReps(Iterable<SessionSet> sets) => sets.fold(0, (a, s) => a + s.reps);

/// Застой: в последних трёх тренировках не было лучше, чем до них.
/// [totals] по порядку от старых к новым.
bool isStalled(List<int> totals) {
  if (totals.length < 4) return false;
  final before = totals.sublist(0, totals.length - 3).reduce(math.max);
  final recent = totals.sublist(totals.length - 3).reduce(math.max);
  return recent <= before;
}

/// Что делать в этот раз. [last] это подходы прошлой тренировки по упражнению,
/// [history] суммы повторов за прошлые тренировки от старых к новым.
Advice adviseNext({
  required String name,
  required int sets,
  required int repsMin,
  required int repsMax,
  required String unit,
  required List<int> last,
  List<int> history = const [],
  String? note,
  bool weighted = false,
}) {
  final timed = unit == 'сек';
  final step = timed ? 5 : 1;
  if (last.isEmpty) {
    return Advice(
      AdviceKind.start,
      timed ? 'Первый раз: начни с $repsMin сек и оставь немного сил.' : 'Первый раз: начни с $repsMin повторов и оставь 2 в запасе.',
      List.filled(sets, repsMin),
    );
  }
  final done = [for (var i = 0; i < sets; i++) i < last.length ? last[i] : 0];
  if (last.length >= sets && last.take(sets).every((r) => r >= repsMax)) {
    final next = nextStep(name);
    final how = [
      if (next != null) 'переходи на «$next»',
      if (weighted || next == null) 'добавь вес (+1–2,5 кг)',
      if (next == null && !weighted && note != null) note,
    ];
    return Advice(
      AdviceKind.levelUp,
      'В прошлый раз все подходы на верхней границе. Пора усложнять: ${how.join(' или ')}. Повторы снова с $repsMin.',
      List.filled(sets, repsMax),
    );
  }
  if (isStalled([...history])) {
    return Advice(
      AdviceKind.stalled,
      'Три тренировки без прироста. Сначала проверь сон и еду, а в этот раз сделай как в прошлый, без рывков.',
      done.map((r) => math.max(r, repsMin)).toList(),
    );
  }
  final below = last.where((r) => r < repsMin).length;
  if (below * 2 > last.length) {
    final prev = previousStep(name);
    return Advice(
      AdviceKind.tooHard,
      'В прошлый раз в большинстве подходов меньше $repsMin. Отдыхай дольше${prev != null ? ' или вернись к «$prev»' : ''}.',
      done.map((r) => math.min(repsMax, math.max(r, 1))).toList(),
    );
  }
  // Добираем: +1 повтор (или +5 секунд) в первом подходе, который ещё не на верхней границе.
  final targets = [...done];
  final i = targets.indexWhere((r) => r < repsMax);
  if (i >= 0) targets[i] = math.min(repsMax, math.max(targets[i] + step, repsMin));
  for (var j = 0; j < targets.length; j++) {
    if (targets[j] == 0) targets[j] = repsMin;
  }
  return Advice(
    AdviceKind.build,
    timed
        ? 'Цель: +$step сек в подходе ${i + 1}, остальные как в прошлый раз.'
        : 'Цель: +1 повтор в подходе ${i + 1}, остальные как в прошлый раз.',
    targets,
  );
}

// ---------------------------------------------------------------------------
// Рекорды
// ---------------------------------------------------------------------------

/// Оценка максимума на один повтор по формуле Эпли. Только для подходов с весом.
double estimatedMax(double weight, int reps) => reps <= 1 ? weight : weight * (1 + reps / 30);

class ExerciseRecords {
  const ExerciseRecords({required this.bestSet, required this.bestTotal, this.maxWeight, this.bestMax, this.sessions = 0});

  /// Лучший подход: больше всего повторов или секунд.
  final int bestSet;

  /// Больше всего повторов за одну тренировку.
  final int bestTotal;
  final double? maxWeight;
  final double? bestMax;
  final int sessions;

  static const empty = ExerciseRecords(bestSet: 0, bestTotal: 0);
}

ExerciseRecords recordsOf(Iterable<SessionSet> sets) {
  var bestSet = 0;
  double? maxWeight, bestMax;
  final totals = <int, int>{};
  for (final s in sets) {
    bestSet = math.max(bestSet, s.reps);
    totals[s.sessionId] = (totals[s.sessionId] ?? 0) + s.reps;
    final w = s.weight;
    if (w != null && w > 0) {
      maxWeight = math.max(maxWeight ?? 0, w);
      bestMax = math.max(bestMax ?? 0, estimatedMax(w, s.reps));
    }
  }
  return ExerciseRecords(
    bestSet: bestSet,
    bestTotal: totals.values.fold(0, math.max),
    maxWeight: maxWeight,
    bestMax: bestMax,
    sessions: totals.length,
  );
}

/// Новые рекорды тренировки в сравнении со всей прошлой историей упражнения.
List<String> newRecords(String unit, Iterable<SessionSet> before, Iterable<SessionSet> now) {
  if (before.isEmpty || now.isEmpty) return const [];
  final a = recordsOf(before), b = recordsOf(now);
  final u = unit == 'сек' ? 'сек' : 'повт.';
  return [
    if (b.bestSet > a.bestSet) 'лучший подход: ${b.bestSet} $u',
    if (b.bestTotal > a.bestTotal && b.bestSet <= a.bestSet) 'больше всего за тренировку: ${b.bestTotal} $u',
    if (b.maxWeight != null && b.maxWeight! > (a.maxWeight ?? 0)) 'максимальный вес: ${_kg(b.maxWeight!)} кг',
  ];
}

String _kg(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1).replaceAll('.', ',');

/// Тоннаж: сумма повторов × вес. Подходы без веса не считаются.
double tonnage(Iterable<SessionSet> sets) => sets.fold(0.0, (a, s) => a + (s.weight ?? 0) * s.reps);

// ---------------------------------------------------------------------------
// Объём и регулярность
// ---------------------------------------------------------------------------

/// Подходы на мышцу за период. Основная мышца +1, вспомогательные +0,5.
/// [muscleByName] задаёт мышцу своих упражнений, которых нет в справочнике.
Map<Muscle, double> muscleSets(Iterable<SessionSet> sets, {Map<String, Muscle> muscleByName = const {}}) {
  final result = <Muscle, double>{};
  for (final s in sets) {
    final cat = catalogExercise(s.exerciseName);
    final main = muscleByName[s.exerciseName] ?? cat?.muscle;
    if (main == null) continue;
    result[main] = (result[main] ?? 0) + 1;
    for (final m in cat?.secondary ?? const <Muscle>[]) {
      if (m != main) result[m] = (result[m] ?? 0) + 0.5;
    }
  }
  return result;
}

/// Рекомендация на массу: 10–20 рабочих подходов на мышцу в неделю.
const weeklySetsLow = 10;
const weeklySetsHigh = 20;

/// Сколько недель подряд выполнен план тренировок. Текущая неделя считается,
/// только если план уже выполнен, иначе серия идёт с прошлой недели.
int weekStreak({required Iterable<int> sessionDays, required int perWeek, required int today}) {
  final need = math.max(1, perWeek);
  final counts = <int, Set<int>>{};
  for (final d in sessionDays) {
    counts.putIfAbsent(weekStart(d), () => {}).add(d);
  }
  var week = weekStart(today);
  var streak = 0;
  if ((counts[week]?.length ?? 0) >= need) streak++;
  week = addDays(week, -7);
  while ((counts[week]?.length ?? 0) >= need) {
    streak++;
    week = addDays(week, -7);
  }
  return streak;
}

/// Количество тренировок по неделям, от старых к новым: [weeks] недель до текущей включительно.
List<(int weekStart, int count)> sessionsPerWeek(Iterable<int> sessionDays, {required int today, int weeks = 8}) {
  final start = addDays(weekStart(today), -7 * (weeks - 1));
  final counts = List.filled(weeks, 0);
  final seen = <int>{};
  for (final d in sessionDays) {
    if (d < start || d > today || !seen.add(d)) continue;
    counts[daysBetween(start, weekStart(d)) ~/ 7]++;
  }
  return [for (var i = 0; i < weeks; i++) (addDays(start, 7 * i), counts[i])];
}

/// "12:05" или "1:02:05".
String formatClock(int seconds) {
  final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// Отдых по-человечески: "1,5 мин", "45 сек", "2 мин".
String formatRest(int seconds) {
  if (seconds < 60) return '$seconds сек';
  if (seconds % 60 == 0) return '${seconds ~/ 60} мин';
  if (seconds % 30 == 0) return '${(seconds / 60).toString().replaceAll('.', ',')} мин';
  return formatClock(seconds);
}
