/// Цели: текущее значение, история, темп и прогноз.
///
/// Методики, на которые опирается модуль:
/// - измеримый результат к сроку (SMART) и линия плана от старта к сроку, как в Strides;
/// - «зачем» и план «если…, то…» на главное препятствие (WOOP, Габриэле Эттинген);
/// - опережающие показатели: привычки, которые двигают цель (4 дисциплины исполнения);
/// - крупная цель делится на этапы с датами.
library;

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import 'calc.dart';
import 'values.dart';

String goalAreaLabel(GoalArea? a) => switch (a) {
  GoalArea.health => 'Здоровье и тело',
  GoalArea.money => 'Деньги',
  GoalArea.career => 'Работа и карьера',
  GoalArea.study => 'Учёба и навыки',
  GoalArea.relations => 'Люди и отношения',
  GoalArea.hobby => 'Увлечения',
  GoalArea.other || null => 'Другое',
};

String goalKindLabel(GoalKind k) => switch (k) {
  GoalKind.tracker => 'По трекеру',
  GoalKind.fund => 'Копилка или долг',
  GoalKind.manual => 'Отмечаю сам',
  GoalKind.steps => 'Этапы',
};

String goalKindHint(GoalKind k) => switch (k) {
  GoalKind.tracker => 'Значение берётся из трекера: вес, подтягивания, часы кода.',
  GoalKind.fund => 'Баланс копилки или остаток долга из раздела «Деньги».',
  GoalKind.manual => 'Сам вносишь значение, когда оно меняется: книги, уровень, клиенты.',
  GoalKind.steps => 'Проект из шагов: «Сделать резюме», «Пройти курс». Прогресс по сделанным этапам.',
};

/// Всё, из чего считаются цели. Загружается одним разом для списка целей.
class GoalSources {
  GoalSources({
    this.trackers = const {},
    this.entries = const [],
    this.funds = const {},
    this.fundMoves = const [],
    this.steps = const [],
    this.checkins = const [],
  });

  final Map<int, Tracker> trackers;
  final List<TrackerEntry> entries;
  final Map<int, Fund> funds;
  final List<FundMove> fundMoves;
  final List<GoalStep> steps;
  final List<GoalCheckin> checkins;

  List<GoalStep> stepsOf(int goalId) => [
    for (final s in steps)
      if (s.goalId == goalId) s,
  ]..sort((a, b) => a.sortOrder != b.sortOrder ? a.sortOrder.compareTo(b.sortOrder) : a.id.compareTo(b.id));

  List<GoalCheckin> checkinsOf(int goalId) => [
    for (final c in checkins)
      if (c.goalId == goalId) c,
  ]..sort((a, b) => a.day != b.day ? a.day.compareTo(b.day) : a.id.compareTo(b.id));
}

/// Старт и цель с учётом типа: у этапов старт 0, цель это число этапов.
({double start, double target}) goalBounds(Goal g, GoalSources s) {
  if (g.kind == GoalKind.steps) return (start: 0, target: s.stepsOf(g.id).length.toDouble());
  return (start: g.startValue, target: g.targetValue);
}

/// Единица измерения цели.
String goalUnitOf(Goal g, GoalSources s) => switch (g.kind) {
  GoalKind.tracker => goalUnit(s.trackers[g.trackerId]),
  GoalKind.fund => '₽',
  GoalKind.manual => g.unit ?? '',
  GoalKind.steps => 'эт.',
};

bool goalIsMoney(Goal g) => g.kind == GoalKind.fund;

/// Значение цели в удобном для чтения виде.
String formatGoalValue(Goal g, GoalSources s, double v) {
  if (goalIsMoney(g)) return formatMoney(v);
  final unit = goalUnitOf(g, s);
  final n = g.kind == GoalKind.steps ? formatNumber(v.roundToDouble()) : formatNumber(v, maxDecimals: 2);
  return unit.isEmpty ? n : '$n $unit';
}

/// История значения цели по дням, по возрастанию даты. Последняя точка это текущее значение.
List<(int day, double value)> goalHistory(Goal g, GoalSources s) {
  switch (g.kind) {
    case GoalKind.tracker:
      final t = s.trackers[g.trackerId];
      if (t == null) return const [];
      final series = dailySeries(t, s.entries);
      switch (t.kind) {
        case TrackerKind.duration:
          var sum = 0.0;
          return [for (final (d, v) in series) (d, (sum += v) / 60)];
        case TrackerKind.yesNo:
          var n = 0.0;
          return [for (final (d, v) in series) (d, v > 0 ? ++n : n)];
        case TrackerKind.number:
        case TrackerKind.scale10:
          return series;
      }
    case GoalKind.fund:
      final f = s.funds[g.fundId];
      if (f == null) return const [];
      final byDay = <int, double>{};
      for (final m in s.fundMoves) {
        if (m.fundId == f.id) byDay[m.day] = (byDay[m.day] ?? 0) + m.amount;
      }
      final days = byDay.keys.toList()..sort();
      var sum = 0.0;
      final points = [for (final d in days) (d, fundValue(f, sum += byDay[d]!))];
      // Без движений значение копилки всё равно известно: начальная сумма.
      if (points.isEmpty || points.first.$1 > g.startDay) points.insert(0, (g.startDay, fundValue(f, 0)));
      return points;
    case GoalKind.manual:
      final byDay = <int, double>{};
      for (final c in s.checkinsOf(g.id)) {
        byDay[c.day] = c.value;
      }
      final days = byDay.keys.toList()..sort();
      return [for (final d in days) (d, byDay[d]!)];
    case GoalKind.steps:
      final done = [
        for (final st in s.stepsOf(g.id))
          if (st.doneDay != null) st.doneDay!,
      ]..sort();
      var n = 0.0;
      final byDay = <int, double>{g.startDay: 0};
      for (final d in done) {
        n++;
        byDay[d < g.startDay ? g.startDay : d] = n;
      }
      final days = byDay.keys.toList()..sort();
      return [for (final d in days) (d, byDay[d]!)];
  }
}

/// Текущее значение цели. null, если данных ещё нет.
double? goalValue(Goal g, GoalSources s) {
  if (g.kind == GoalKind.steps) return s.stepsOf(g.id).where((x) => x.doneDay != null).length.toDouble();
  if (g.kind == GoalKind.tracker) {
    final t = s.trackers[g.trackerId];
    return t == null ? null : trackerGoalValue(t, s.entries);
  }
  return goalHistory(g, s).lastOrNull?.$2;
}

/// Значение цели на конец дня [day]. null, если до этого дня данных не было.
double? goalValueAt(Goal g, GoalSources s, int day) {
  if (g.kind == GoalKind.steps) {
    return s.stepsOf(g.id).where((x) => x.doneDay != null && x.doneDay! <= day).length.toDouble();
  }
  double? last;
  for (final (d, v) in goalHistory(g, s)) {
    if (d > day) break;
    last = v;
  }
  return last;
}

enum GoalPace {
  /// Данных пока нет.
  noData,

  /// Срока нет, считаем только прогресс.
  noDeadline,

  /// Опережаешь план.
  ahead,

  /// Идёшь по плану.
  onTrack,

  /// Отстаёшь от плана.
  behind,

  /// Срок прошёл, а цель не взята.
  overdue,

  /// Цель достигнута.
  reached,
}

class GoalStatus {
  GoalStatus({
    required this.current,
    required this.start,
    required this.target,
    required this.fraction,
    required this.pace,
    this.expected,
    this.forecastDay,
    this.perWeekNeeded,
    this.daysLeft,
  });

  final double? current;
  final double start;
  final double target;

  /// Доля пути от 0 до 1.
  final double fraction;
  final GoalPace pace;

  /// Где по плану нужно быть сегодня, если задан срок.
  final double? expected;

  /// Когда цель будет достигнута при текущем темпе.
  final int? forecastDay;

  /// Сколько нужно в неделю, чтобы успеть к сроку. Со знаком направления.
  final double? perWeekNeeded;
  final int? daysLeft;

  bool get reached => pace == GoalPace.reached;

  /// Насколько отстаёшь (плюс) или опережаешь (минус) план в единицах цели.
  double? get gap {
    if (expected == null || current == null) return null;
    return (target >= start) ? expected! - current! : current! - expected!;
  }
}

/// Насколько можно отклониться от линии плана и всё ещё считаться «по плану»: 5% пути.
const _paceTolerance = 0.05;

GoalStatus goalStatus(Goal g, GoalSources s, {required int today}) {
  final b = goalBounds(g, s);
  final current = goalValue(g, s);
  final total = b.target - b.start;
  final up = total >= 0;
  final deadline = g.deadline;
  final daysLeft = deadline == null ? null : daysBetween(today, deadline);
  if (current == null || (g.kind == GoalKind.steps && b.target == 0)) {
    return GoalStatus(current: current, start: b.start, target: b.target, fraction: 0, pace: GoalPace.noData, daysLeft: daysLeft);
  }
  final p = goalProgress(start: b.start, target: b.target, current: current, startDay: g.startDay, today: today);
  if (p.reached || g.achievedDay != null) {
    return GoalStatus(current: current, start: b.start, target: b.target, fraction: 1, pace: GoalPace.reached, daysLeft: daysLeft);
  }
  double? expected;
  double? perWeek;
  var pace = GoalPace.noDeadline;
  if (deadline != null && deadline > g.startDay) {
    final span = daysBetween(g.startDay, deadline);
    final passed = daysBetween(g.startDay, today).clamp(0, span);
    final planFraction = passed / span;
    expected = b.start + total * planFraction;
    if (today > deadline) {
      pace = GoalPace.overdue;
    } else {
      final diff = p.fraction - planFraction;
      pace = diff > _paceTolerance * 2 ? GoalPace.ahead : (diff >= -_paceTolerance ? GoalPace.onTrack : GoalPace.behind);
      final weeks = (daysLeft! + 1) / 7;
      perWeek = (b.target - current) / (weeks < 1 ? 1 : weeks);
    }
  }
  return GoalStatus(
    current: current,
    start: b.start,
    target: b.target,
    fraction: up || total != 0 ? p.fraction : 0,
    pace: pace,
    expected: expected,
    forecastDay: p.forecastDay,
    perWeekNeeded: perWeek,
    daysLeft: daysLeft,
  );
}

String goalPaceLabel(GoalPace p) => switch (p) {
  GoalPace.noData => 'Нет данных',
  GoalPace.noDeadline => 'Без срока',
  GoalPace.ahead => 'Опережаешь',
  GoalPace.onTrack => 'По плану',
  GoalPace.behind => 'Отстаёшь',
  GoalPace.overdue => 'Срок прошёл',
  GoalPace.reached => 'Достигнута',
};

/// Привычки цели из строки «1,5,7».
List<int> parseIds(String? s) => [for (final p in (s ?? '').split(',')) ?int.tryParse(p.trim())];

String? joinIds(Iterable<int> ids) => ids.isEmpty ? null : ids.join(',');

/// Порядок в списке: сначала те, что требуют внимания.
int goalUrgency(GoalStatus st) => switch (st.pace) {
  GoalPace.overdue => 0,
  GoalPace.behind => 1,
  GoalPace.noData => 2,
  GoalPace.onTrack => 3,
  GoalPace.ahead => 4,
  GoalPace.noDeadline => 5,
  GoalPace.reached => 6,
};

/// Ближайший несделанный этап.
GoalStep? nextStep(Goal g, GoalSources s) => s.stepsOf(g.id).where((x) => x.doneDay == null).firstOrNull;
