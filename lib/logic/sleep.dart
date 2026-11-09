/// Сон: цели, длительность, «вовремя ли лёг», статистика.
library;

import '../data/database.dart';
import '../data/dates.dart';

/// Цели по сну из настроек.
class SleepGoals {
  const SleepGoals({required this.bed, required this.wake, required this.duration, this.remindBefore, this.onToday = false});

  factory SleepGoals.from(Map<String, String> s) => SleepGoals(
    bed: int.tryParse(s[keyBed] ?? '') ?? 23 * 60,
    wake: int.tryParse(s[keyWake] ?? '') ?? 7 * 60,
    duration: int.tryParse(s[keyDuration] ?? '') ?? 8 * 60,
    remindBefore: int.tryParse(s[keyRemind] ?? ''),
    onToday: s[keyOn] == '1',
  );

  static const keyBed = 'sleep_bed';
  static const keyWake = 'sleep_wake';
  static const keyDuration = 'sleep_goal';
  static const keyRemind = 'sleep_remind';
  static const keyOn = 'sleep_on';

  /// Момент «лёг спать», пока ещё не встал.
  static const keyStarted = 'sleep_started';

  /// Отбой и подъём в минутах от полуночи.
  final int bed;
  final int wake;

  /// Сколько спать, в минутах.
  final int duration;

  /// За сколько минут до отбоя напомнить. null: не напоминать.
  final int? remindBefore;

  /// Показывать сон на экране «Сегодня».
  final bool onToday;
}

int sleepMinutes(SleepLog l) => l.wakeAt.difference(l.bedAt).inMinutes;

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
  });

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
  );
}

/// Сколько минут осталось до отбоя. Отрицательное число: отбой уже прошёл.
int minutesUntilBed(DateTime now, int goalBed) {
  final diff = _fromNoon(goalBed) - _fromNoon(minutesOfDay(now));
  return diff;
}
