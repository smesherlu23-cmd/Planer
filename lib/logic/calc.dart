/// Чистые расчёты без базы и интерфейса. Их легко тестировать.
library;

import 'dart:math' as math;

import '../data/dates.dart';

// ---------------------------------------------------------------------------
// Привычки
// ---------------------------------------------------------------------------

/// Текущая серия привычки: сколько запланированных дней подряд она выполнена.
///
/// Считаем назад от сегодня. Если сегодня ещё не отмечено, это серию не рвёт:
/// день ещё не закончился. Дни вне расписания пропускаются.
int currentStreak({required int daysMask, required Set<int> doneDays, required int today, int? firstDay}) {
  if (daysMask == 0) return 0;
  var day = today;
  if (!doneDays.contains(day)) day = addDays(day, -1);
  var streak = 0;
  // Ограничение на всякий случай: не дальше 10 лет назад.
  for (var i = 0; i < 3660; i++) {
    if (firstDay != null && day < firstDay) break;
    if (maskHasDay(daysMask, day)) {
      if (doneDays.contains(day)) {
        streak++;
      } else {
        break;
      }
    }
    day = addDays(day, -1);
  }
  return streak;
}

/// Сколько раз привычка была запланирована и сколько выполнена за период.
({int planned, int done}) habitCompletion({required int daysMask, required Set<int> doneDays, required int from, required int to}) {
  var planned = 0;
  var done = 0;
  for (var d = from; d <= to; d = addDays(d, 1)) {
    if (maskHasDay(daysMask, d)) {
      planned++;
      if (doneDays.contains(d)) done++;
    }
  }
  return (planned: planned, done: done);
}

// ---------------------------------------------------------------------------
// Цели
// ---------------------------------------------------------------------------

class GoalProgress {
  const GoalProgress({required this.current, required this.fraction, required this.reached, this.forecastDay});

  final double current;

  /// Доля пути от старта до цели, от 0 до 1.
  final double fraction;
  final bool reached;

  /// Когда цель будет достигнута при текущем темпе. null, если данных мало
  /// или движение идёт не в ту сторону.
  final int? forecastDay;
}

GoalProgress goalProgress({
  required double start,
  required double target,
  required double current,
  required int startDay,
  required int today,
  int minDaysForForecast = 7,
}) {
  final total = target - start;
  final up = total >= 0;
  final reached = up ? current >= target : current <= target;
  final fraction = total == 0 ? 1.0 : ((current - start) / total).clamp(0.0, 1.0).toDouble();
  int? forecast;
  final elapsed = daysBetween(startDay, today);
  if (!reached && elapsed >= minDaysForForecast) {
    final rate = (current - start) / elapsed; // в день
    final remaining = target - current;
    if (rate != 0 && remaining / rate > 0) {
      final daysLeft = (remaining / rate).ceil();
      if (daysLeft < 365 * 30) forecast = addDays(today, daysLeft);
    }
  }
  return GoalProgress(current: current, fraction: fraction, reached: reached, forecastDay: forecast);
}

// ---------------------------------------------------------------------------
// Деньги
// ---------------------------------------------------------------------------

/// Сколько месяцев нужно, чтобы закрыть долг ежемесячными платежами.
/// null, если платёж не покрывает проценты.
int? monthsToPayOff({required double balance, required double monthlyPayment, double? annualRatePercent}) {
  if (balance <= 0) return 0;
  if (monthlyPayment <= 0) return null;
  final r = (annualRatePercent ?? 0) / 100 / 12;
  var b = balance;
  var months = 0;
  while (b > 0.005) {
    final next = b * (1 + r) - monthlyPayment;
    if (next >= b) return null;
    b = next;
    months++;
    if (months > 1200) return null;
  }
  return months;
}

/// Сколько месяцев копить до цели ежемесячными взносами.
int? monthsToSave({required double balance, required double target, required double monthly}) {
  if (balance >= target) return 0;
  if (monthly <= 0) return null;
  return ((target - balance) / monthly).ceil();
}

/// Дата через n месяцев (примерно, тот же день месяца).
int addMonths(int key, int months) {
  final d = dayFromKey(key);
  final targetMonth = DateTime(d.year, d.month + months, 1);
  final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
  return dayKey(DateTime(targetMonth.year, targetMonth.month, math.min(d.day, lastDay)));
}

// ---------------------------------------------------------------------------
// Тренировки
// ---------------------------------------------------------------------------

/// Пора ли усложнять упражнение: в прошлый раз во всех подходах
/// дошёл до верхней границы повторов.
bool readyToProgress({required int plannedSets, required int repsMax, required List<int> lastReps}) {
  if (lastReps.length < plannedSets || lastReps.isEmpty) return false;
  return lastReps.every((r) => r >= repsMax);
}

// ---------------------------------------------------------------------------
// Форматирование
// ---------------------------------------------------------------------------

String formatMoney(num value) {
  final negative = value < 0;
  final s = value.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '${negative ? '−' : ''}$buf ₽';
}

String formatNumber(num value, {int maxDecimals = 1}) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(maxDecimals).replaceAll('.', ',');
}

double? parseNumber(String text) => double.tryParse(text.trim().replaceAll(',', '.').replaceAll(' ', ''));
