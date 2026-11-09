/// Сон: цели, длительность, «вовремя ли лёг», статистика.
library;

import 'dart:math' as math;

import '../data/database.dart';
import '../data/dates.dart';
import 'minimum.dart';

/// Цели по сну из настроек.
class SleepGoals {
  const SleepGoals({required this.bed, required this.wake, required this.duration, this.minimum, this.remindBefore, this.onToday = false});

  factory SleepGoals.from(Map<String, String> s) => SleepGoals(
    bed: int.tryParse(s[keyBed] ?? '') ?? 23 * 60,
    wake: int.tryParse(s[keyWake] ?? '') ?? 7 * 60,
    duration: int.tryParse(s[keyDuration] ?? '') ?? 8 * 60,
    minimum: int.tryParse(s[keyMinimum] ?? ''),
    remindBefore: int.tryParse(s[keyRemind] ?? ''),
    onToday: s[keyOn] == '1',
  );

  static const keyBed = 'sleep_bed';
  static const keyWake = 'sleep_wake';
  static const keyDuration = 'sleep_goal';
  static const keyMinimum = 'sleep_min';
  static const keyRemind = 'sleep_remind';
  static const keyOn = 'sleep_on';

  /// Момент «лёг спать», пока ещё не встал.
  static const keyStarted = 'sleep_started';

  /// Отбой и подъём в минутах от полуночи.
  final int bed;
  final int wake;

  /// Сколько спать, в минутах.
  final int duration;

  /// Минимум сна, в минутах. Меньше него ночь считается короткой. null: без минимума.
  final int? minimum;

  /// За сколько минут до отбоя напомнить. null: не напоминать.
  final int? remindBefore;

  /// Показывать сон на экране «Сегодня».
  final bool onToday;
}

int sleepMinutes(SleepLog l) => l.wakeAt.difference(l.bedAt).inMinutes;

/// Ночь по длительности: норма (с запасом 10 минут), минимум или меньше.
Level sleepLevel(SleepLog l, SleepGoals g) =>
    levelOf(sleepMinutes(l).toDouble(), goal: g.duration - 10.0, min: g.minimum?.toDouble() ?? (g.duration - 10.0));

int minutesOfDay(DateTime t) => t.hour * 60 + t.minute;

/// Минуты от полудня: 23:30 → 690, 00:30 → 750. Так отбой до и после полуночи сравнивается и усредняется правильно.
int _fromNoon(int minutesOfDay) => (minutesOfDay - 720) % 1440;

int _toClock(int fromNoon) => (fromNoon + 720) % 1440;

/// Лёг вовремя: не позже цели плюс 15 минут.
bool wentToBedOnTime(SleepLog l, int goalBed) => _fromNoon(minutesOfDay(l.bedAt)) <= _fromNoon(goalBed) + 15;

/// Когда лёг и когда встал, по дню пробуждения и времени на часах.
/// Если время отбоя позже времени подъёма, значит лёг накануне.
({DateTime bedAt, DateTime wakeAt}) sleepTimes({required int wakeDay, required int bedMinutes, required int wakeMinutes}) {
  final d = dayFromKey(wakeDay);
  final wakeAt = DateTime(d.year, d.month, d.day, wakeMinutes ~/ 60, wakeMinutes % 60);
  final bedDay = bedMinutes > wakeMinutes ? d.subtract(const Duration(days: 1)) : d;
  final bedAt = DateTime(bedDay.year, bedDay.month, bedDay.day, bedMinutes ~/ 60, bedMinutes % 60);
  return (bedAt: bedAt, wakeAt: wakeAt);
}

class SleepStats {
  const SleepStats({
    required this.nights,
    required this.avgDuration,
    required this.avgBed,
    required this.avgWake,
    required this.onTime,
    required this.debt,
    required this.streak,
    this.full = 0,
    this.minimum = 0,
  });

  /// Сколько ночей выспался по норме и сколько только по минимуму.
  final int full;
  final int minimum;

  /// Сколько ночей записано за период.
  final int nights;

  /// Средняя длительность, минуты.
  final int? avgDuration;

  /// Средний отбой и подъём, минуты от полуночи.
  final int? avgBed;
  final int? avgWake;

  /// Сколько ночей лёг вовремя.
  final int onTime;

  /// Недосып за период: сумма нехватки до цели, минуты.
  final int debt;

  /// Сколько ночей подряд, до сегодняшней включительно, лёг вовремя.
  final int streak;
}

SleepStats sleepStats(Iterable<SleepLog> all, SleepGoals g, {required int from, required int to, required int today}) {
  final logs = all.where((l) => l.day >= from && l.day <= to).toList();
  int? avg(Iterable<int> xs) => xs.isEmpty ? null : (xs.reduce((a, b) => a + b) / xs.length).round();
  final avgBed = avg(logs.map((l) => _fromNoon(minutesOfDay(l.bedAt))));
  final avgWake = avg(logs.map((l) => minutesOfDay(l.wakeAt)));
  final byDay = {for (final l in all) l.day: l};
  var streak = 0;
  // Если за сегодня ещё нет записи, серию считаем со вчерашней ночи.
  var day = byDay.containsKey(today) ? today : addDays(today, -1);
  while (true) {
    final l = byDay[day];
    if (l == null || !wentToBedOnTime(l, g.bed)) break;
    streak++;
    day = addDays(day, -1);
  }
  return SleepStats(
    nights: logs.length,
    avgDuration: avg(logs.map(sleepMinutes)),
    avgBed: avgBed == null ? null : _toClock(avgBed),
    avgWake: avgWake,
    onTime: logs.where((l) => wentToBedOnTime(l, g.bed)).length,
    debt: logs.fold(0, (a, l) => a + (g.duration - sleepMinutes(l)).clamp(0, 24 * 60)),
    streak: streak,
    full: logs.where((l) => sleepLevel(l, g) == Level.full).length,
    minimum: logs.where((l) => sleepLevel(l, g) == Level.minimum).length,
  );
}

/// Сколько минут осталось до отбоя. Отрицательное число: отбой уже прошёл.
int minutesUntilBed(DateTime now, int goalBed) {
  final diff = _fromNoon(goalBed) - _fromNoon(minutesOfDay(now));
  return diff;
}

// ---------------------------------------------------------------------------
// Дневник сна и разбор
//
// Источники:
// - Consensus Sleep Diary (Carney и др., 2012, Sleep): засыпание, пробуждения ночью,
//   время без сна, эффективность сна. Стандарт для КПТ-Б (когнитивно-поведенческой терапии бессонницы).
// - Эффективность сна 85% и выше считается нормой (критерий КПТ-Б).
// - Hirshkowitz и др., 2015 (National Sleep Foundation): взрослым 18–64 лет 7–9 часов.
// - Phillips и др., 2017; Windred и др., 2024: регулярность сна связана со здоровьем
//   не меньше, чем длительность. Поэтому считаем разброс отбоя и подъёма.
// - Wittmann и др., 2006: социальный джетлаг, разница середины сна в выходные и будни.
// - Roenneberg и др.: хронотип по середине сна в свободные дни.
// - Drake и др., 2013; Gardiner и др., 2023 (метаанализ): кофеин мешает сну и за 6 часов,
//   для кофе безопасный отступ около 8–9 часов.
// ---------------------------------------------------------------------------

/// Сколько реально спал: время в постели минус засыпание и время без сна ночью.
int actualSleepMinutes(SleepLog l) => (sleepMinutes(l) - (l.latency ?? 0) - (l.awakeMinutes ?? 0)).clamp(0, 24 * 60).toInt();

/// Эффективность сна в процентах. null: дневник не заполнен.
int? sleepEfficiency(SleepLog l) {
  if (l.latency == null && l.awakeMinutes == null) return null;
  final tib = sleepMinutes(l);
  if (tib <= 0) return null;
  return (100 * actualSleepMinutes(l) / tib).round();
}

/// Середина сна, минуты от полуночи.
int sleepMidpoint(SleepLog l) {
  final mid = l.bedAt.add(Duration(minutes: sleepMinutes(l) ~/ 2));
  return minutesOfDay(mid);
}

/// Выходной день по дню пробуждения: суббота и воскресенье.
bool isFreeDay(int day) => dayFromKey(day).weekday >= 6;

double? _sd(List<int> xs) {
  if (xs.length < 3) return null;
  final mean = xs.reduce((a, b) => a + b) / xs.length;
  final v = xs.fold<double>(0, (a, x) => a + (x - mean) * (x - mean)) / (xs.length - 1);
  return math.sqrt(v);
}

int? _avgClock(Iterable<int> minutes) {
  final xs = minutes.map(_fromNoon).toList();
  if (xs.isEmpty) return null;
  return _toClock((xs.reduce((a, b) => a + b) / xs.length).round());
}

class SleepRhythm {
  const SleepRhythm({this.bedSpread, this.wakeSpread, this.socialJetlag, this.midFree, this.midWork});

  /// Разброс отбоя и подъёма (стандартное отклонение), минуты.
  final int? bedSpread;
  final int? wakeSpread;

  /// Разница середины сна в выходные и будни, минуты. null: мало данных.
  final int? socialJetlag;

  /// Средняя середина сна в выходные и в будни, минуты от полуночи.
  final int? midFree;
  final int? midWork;

  /// Хронотип по середине сна в выходные (или в любые дни, если выходных мало).
  String? get chronotype {
    final mid = midFree ?? midWork;
    if (mid == null) return null;
    final m = _fromNoon(mid);
    if (m < _fromNoon(3 * 60)) return 'жаворонок';
    if (m < _fromNoon(4 * 60 + 30)) return 'скорее жаворонок';
    if (m < _fromNoon(5 * 60 + 30)) return 'голубь';
    if (m < _fromNoon(6 * 60 + 30)) return 'скорее сова';
    return 'сова';
  }
}

SleepRhythm sleepRhythm(Iterable<SleepLog> all, {required int from, required int to}) {
  final logs = all.where((l) => l.day >= from && l.day <= to).toList();
  final bedSd = _sd([for (final l in logs) _fromNoon(minutesOfDay(l.bedAt))]);
  final wakeSd = _sd([for (final l in logs) minutesOfDay(l.wakeAt)]);
  final free = [
    for (final l in logs)
      if (isFreeDay(l.day)) sleepMidpoint(l),
  ];
  final work = [
    for (final l in logs)
      if (!isFreeDay(l.day)) sleepMidpoint(l),
  ];
  final midFree = _avgClock(free);
  final midWork = _avgClock(work);
  int? jetlag;
  if (free.length >= 2 && work.length >= 3) {
    jetlag = (_fromNoon(midFree!) - _fromNoon(midWork!)).abs();
  }
  return SleepRhythm(
    bedSpread: bedSd?.round(),
    wakeSpread: wakeSd?.round(),
    socialJetlag: jetlag,
    midFree: free.length >= 2 ? midFree : null,
    midWork: midWork,
  );
}

/// Средний подъём и средняя эффективность, засыпание.
({int? avgLatency, int? avgEfficiency, int? avgActual}) sleepDiaryStats(Iterable<SleepLog> all, {required int from, required int to}) {
  final logs = all.where((l) => l.day >= from && l.day <= to).toList();
  int? avg(Iterable<int> xs) => xs.isEmpty ? null : (xs.reduce((a, b) => a + b) / xs.length).round();
  return (
    avgLatency: avg(logs.map((l) => l.latency).whereType<int>()),
    avgEfficiency: avg(logs.map(sleepEfficiency).whereType<int>()),
    avgActual: avg(logs.where((l) => l.latency != null || l.awakeMinutes != null).map(actualSleepMinutes)),
  );
}

/// Что было вечером: факторы, которые отмечаются в записи ночи.
class SleepFactor {
  const SleepFactor(this.key, this.label, this.hint);
  final String key;
  final String label;
  final String hint;
}

const sleepFactors = [
  SleepFactor('coffee', 'Кофе после обеда', 'Кофеин держится в крови 5–6 часов, отступ до сна около 8 часов'),
  SleepFactor('alcohol', 'Алкоголь', 'Помогает уснуть, но дробит сон во второй половине ночи'),
  SleepFactor('screen', 'Экран в кровати', 'Яркий свет и лента перед сном отодвигают засыпание'),
  SleepFactor('late_food', 'Поздний ужин', 'Плотная еда позже чем за 2–3 часа до сна'),
  SleepFactor('workout', 'Тренировка', 'Днём улучшает сон; тяжёлая позже чем за час до сна может мешать'),
  SleepFactor('stress', 'Стресс', 'Мысли крутятся: помогает выписать их на бумагу до сна'),
  SleepFactor('nap', 'Дневной сон', 'Короткий до 20–30 минут и до 15:00 не мешает ночному'),
  SleepFactor('games', 'Игры допоздна', 'Азарт и свет экрана бодрят'),
  SleepFactor('walk', 'Прогулка', 'Дневной свет и движение помогают уснуть'),
  SleepFactor('reading', 'Чтение', 'Бумажная книга вместо телефона'),
];

SleepFactor? sleepFactor(String key) {
  for (final f in sleepFactors) {
    if (f.key == key) return f;
  }
  return null;
}

Set<String> sleepTags(SleepLog l) => {
  for (final t in (l.tags ?? '').split(','))
    if (t.trim().isNotEmpty) t.trim(),
};

String? joinSleepTags(Iterable<String> tags) => tags.isEmpty ? null : tags.join(',');

/// Как фактор связан со сном: средний сон и самочувствие с ним и без него.
class FactorImpact {
  const FactorImpact({
    required this.factor,
    required this.withCount,
    required this.withoutCount,
    required this.durationDiff,
    this.qualityDiff,
  });
  final SleepFactor factor;
  final int withCount;
  final int withoutCount;

  /// Разница среднего сна, минуты: с фактором минус без него.
  final int durationDiff;

  /// Разница среднего самочувствия по шкале 1–5.
  final double? qualityDiff;
}

/// Факторы, по которым уже хватает данных: хотя бы 3 ночи с ним и 3 без него.
List<FactorImpact> factorImpacts(Iterable<SleepLog> logs, {int minNights = 3}) {
  final out = <FactorImpact>[];
  final list = logs.toList();
  for (final f in sleepFactors) {
    final yes = list.where((l) => sleepTags(l).contains(f.key)).toList();
    final no = list.where((l) => !sleepTags(l).contains(f.key)).toList();
    if (yes.length < minNights || no.length < minNights) continue;
    double avg(Iterable<num> xs) => xs.isEmpty ? 0 : xs.fold<num>(0, (a, b) => a + b) / xs.length;
    final qy = yes.map((l) => l.quality).whereType<int>().toList();
    final qn = no.map((l) => l.quality).whereType<int>().toList();
    out.add(
      FactorImpact(
        factor: f,
        withCount: yes.length,
        withoutCount: no.length,
        durationDiff: (avg(yes.map(actualSleepMinutes)) - avg(no.map(actualSleepMinutes))).round(),
        qualityDiff: qy.length >= 2 && qn.length >= 2 ? avg(qy) - avg(qn) : null,
      ),
    );
  }
  out.sort((a, b) => a.durationDiff.abs().compareTo(b.durationDiff.abs()) * -1);
  return out;
}

/// Когда ложиться, чтобы встать в [wake]: полные циклы по 90 минут плюс время на засыпание.
/// Циклы это ориентир, а не закон: их длина у людей от 70 до 120 минут.
List<({int cycles, int bed, int sleep})> bedtimesFor(int wake, {int latency = 15}) => [
  for (final c in [6, 5, 4]) (cycles: c, bed: (wake - c * 90 - latency) % 1440, sleep: c * 90),
];

/// Когда вставать, если лечь сейчас.
List<({int cycles, int wake, int sleep})> wakeTimesFor(int bed, {int latency = 15}) => [
  for (final c in [4, 5, 6]) (cycles: c, wake: (bed + latency + c * 90) % 1440, sleep: c * 90),
];

/// Вечерний план от времени отбоя: что и когда закончить.
List<({int at, String title, String hint})> eveningPlan(int bed) => [
  (at: (bed - 8 * 60) % 1440, title: 'Последний кофе', hint: 'Кофеин мешает сну даже за 6 часов'),
  (at: (bed - 3 * 60) % 1440, title: 'Последняя плотная еда', hint: 'Лёгкий перекус потом можно'),
  (at: (bed - 2 * 60) % 1440, title: 'Закончить тренировку', hint: 'Тяжёлая нагрузка бодрит ещё час-два'),
  (at: (bed - 60) % 1440, title: 'Приглушить свет, отложить телефон', hint: 'Душ, книга, план на завтра'),
  (at: bed, title: 'Отбой', hint: 'Не уснул за 20 минут: встань и займись спокойным делом'),
];

/// Недосып за 14 ночей: сумма нехватки до цели. Ночи без записи не считаются.
int sleepDebt(Iterable<SleepLog> all, SleepGoals g, {required int today, int nights = 14}) {
  final from = addDays(today, -(nights - 1));
  return all
      .where((l) => l.day >= from && l.day <= today)
      .fold(0, (a, l) => a + (g.duration - actualSleepMinutes(l)).clamp(0, 24 * 60).toInt());
}
