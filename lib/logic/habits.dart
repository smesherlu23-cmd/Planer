/// Привычки: расписание, серии, сила привычки, пропуски, статистика.
///
/// Опора на исследования:
/// - Lally и др., 2010 (European Journal of Social Psychology): до автоматизма в среднем 66 дней
///   (от 18 до 254), а один пропуск на формирование почти не влияет. Отсюда «сила привычки»
///   вместо хрупкой серии и правило «не пропускай дважды».
/// - Gollwitzer и Sheeran, 2006 (метаанализ 94 исследований): план «если X, то сделаю Y»
///   заметно повышает выполнение (d = 0,65). Отсюда поле «якорь».
/// - Формула силы как в Loop Habit Tracker: экспоненциальное сглаживание, вес отметки
///   за последние ~2 недели примерно половина.
library;

import 'dart:math' as math;

import '../data/dates.dart';

/// Что нужно расчётам от привычки. Отвязано от таблицы, чтобы легко тестировать.
class HabitPlan {
  const HabitPlan({this.daysMask = everyDay, this.perWeek, this.firstDay});

  /// Дни недели, когда привычка запланирована (если не задано [perWeek]).
  final int daysMask;

  /// N раз в неделю, в любые дни.
  final int? perWeek;

  /// День создания: раньше него пропуски не считаются.
  final int? firstDay;

  bool get weekly => perWeek != null && perWeek! > 0;

  /// Запланирован ли конкретный день. Для «N раз в неделю» запланирован каждый день: можно сделать в любой.
  bool scheduled(int day) => weekly || maskHasDay(daysMask, day);

  /// Сколько раз в среднем в день: для силы привычки.
  double get perDay => weekly ? perWeek!.clamp(1, 7) / 7 : weekdaysFromMask(daysMask).length / 7;
}

/// Отметки привычки: сделанные дни и дни пропуска по уважительной причине.
class HabitMarks {
  const HabitMarks({this.done = const {}, this.skipped = const {}});
  final Set<int> done;
  final Set<int> skipped;
}

/// Сколько отметок за неделю, начиная с понедельника [monday], до [to] включительно.
int doneInWeek(HabitMarks m, int monday, {int? to}) {
  var n = 0;
  for (var i = 0; i < 7; i++) {
    final d = addDays(monday, i);
    if (to != null && d > to) break;
    if (m.done.contains(d)) n++;
  }
  return n;
}

/// Пропуски по уважительной причине в неделе: уменьшают план «N раз в неделю».
int skippedInWeek(HabitMarks m, int monday) {
  var n = 0;
  for (var i = 0; i < 7; i++) {
    if (m.skipped.contains(addDays(monday, i))) n++;
  }
  return n;
}

/// План на неделю для «N раз в неделю» с учётом пропусков.
int weekQuota(HabitPlan p, HabitMarks m, int monday) => math.max(0, (p.perWeek ?? 0) - skippedInWeek(m, monday));

/// Текущая серия.
///
/// По дням: запланированные дни подряд, где сделано. Сегодня, если ещё не отмечено, серию не рвёт.
/// Пропуск по уважительной причине серию не рвёт и не увеличивает.
/// Для «N раз в неделю» серия в неделях: сколько недель подряд выполнен план (текущая неделя
/// засчитывается, если план уже выполнен, и не рвёт серию, пока идёт).
int habitStreak(HabitPlan p, HabitMarks m, int today) {
  if (p.weekly) {
    var week = weekStart(today);
    var streak = 0;
    if (doneInWeek(m, week) >= weekQuota(p, m, week) && weekQuota(p, m, week) > 0) streak++;
    week = addDays(week, -7);
    for (var i = 0; i < 520; i++) {
      if (p.firstDay != null && addDays(week, 6) < p.firstDay!) break;
      final quota = weekQuota(p, m, week);
      if (quota > 0 && doneInWeek(m, week) < quota) break;
      if (quota > 0) streak++;
      week = addDays(week, -7);
    }
    return streak;
  }
  if (p.daysMask == 0) return 0;
  var day = today;
  if (!m.done.contains(day)) day = addDays(day, -1);
  var streak = 0;
  for (var i = 0; i < 3660; i++) {
    if (p.firstDay != null && day < p.firstDay!) break;
    if (p.scheduled(day) && !m.skipped.contains(day)) {
      if (!m.done.contains(day)) break;
      streak++;
    } else if (m.done.contains(day)) {
      // Сделал во внеплановый день: тоже плюс.
      streak++;
    }
    day = addDays(day, -1);
  }
  return streak;
}

/// Лучшая серия за всю историю, в тех же единицах, что [habitStreak].
int bestStreak(HabitPlan p, HabitMarks m, int today) {
  if (m.done.isEmpty) return 0;
  final first = [p.firstDay, m.done.reduce(math.min)].whereType<int>().reduce(math.min);
  var best = 0, run = 0;
  if (p.weekly) {
    for (var week = weekStart(first); week <= today; week = addDays(week, 7)) {
      final quota = weekQuota(p, m, week);
      if (quota == 0) continue;
      final current = week == weekStart(today);
      if (doneInWeek(m, week) >= quota) {
        run++;
      } else if (!current) {
        run = 0;
      }
      best = math.max(best, run);
    }
    return best;
  }
  for (var d = first; d <= today; d = addDays(d, 1)) {
    if (m.done.contains(d)) {
      run++;
    } else if (p.scheduled(d) && !m.skipped.contains(d) && d != today) {
      run = 0;
    }
    best = math.max(best, run);
  }
  return best;
}

/// Выполнение за период: сколько было запланировано и сколько сделано (в рамках плана).
({int planned, int done}) habitRate(HabitPlan p, HabitMarks m, {required int from, required int to}) {
  final start = p.firstDay == null ? from : math.max(from, p.firstDay!);
  if (start > to) return (planned: 0, done: 0);
  if (p.weekly) {
    var planned = 0, done = 0;
    for (var week = weekStart(start); week <= to; week = addDays(week, 7)) {
      // Неполные недели по краям периода считаем пропорционально.
      final a = math.max(week, start), b = math.min(addDays(week, 6), to);
      final days = daysBetween(a, b) + 1;
      final quota = weekQuota(p, m, week);
      final part = days >= 7 ? quota : (quota * days / 7).ceil();
      var got = 0;
      for (var d = a; d <= b; d = addDays(d, 1)) {
        if (m.done.contains(d)) got++;
      }
      planned += part;
      done += math.min(got, part);
    }
    return (planned: planned, done: done);
  }
  var planned = 0, done = 0;
  for (var d = start; d <= to; d = addDays(d, 1)) {
    if (!p.scheduled(d) || m.skipped.contains(d)) continue;
    // Последний день периода (обычно сегодня) ещё идёт: не отмечен, значит пока не считаем.
    if (d == to && !m.done.contains(d)) continue;
    planned++;
    if (m.done.contains(d)) done++;
  }
  return (planned: planned, done: done);
}

/// Сила привычки от 0 до 1 на каждый день, как в Loop Habit Tracker.
///
/// Каждый запланированный день сила сдвигается к 1 (сделано) или к 0 (не сделано).
/// Множитель подобран так, что вклад дня падает вдвое примерно за 13 повторений.
/// Пропуск по уважительной причине силу не меняет. Сегодняшний день, пока не отмечен, не штрафуется.
List<double> strengthSeries(HabitPlan p, HabitMarks m, {required int from, required int to}) {
  final out = <double>[];
  var score = 0.0;
  final start = p.firstDay ?? from;
  final first = math.min(start, m.done.isEmpty ? start : m.done.reduce(math.min));
  if (p.weekly) {
    // «N раз в неделю»: сила пересчитывается по итогам каждой прошедшей недели, полувес около 3 недель.
    final mult = math.pow(0.5, 1 / 3).toDouble();
    for (var d = math.min(first, from); d <= to; d = addDays(d, 1)) {
      final week = weekStart(d);
      final weekEnd = addDays(week, 6);
      final quota = weekQuota(p, m, week);
      final got = doneInWeek(m, week, to: d);
      final ended = d == weekEnd && (d != to || got >= quota);
      final reachedNow = d == to && d != weekEnd && quota > 0 && got >= quota;
      if (week >= weekStart(first) && quota > 0 && ended) {
        score = score * mult + math.min(1.0, got / quota) * (1 - mult);
      }
      if (d >= from) out.add(reachedNow ? score * mult + (1 - mult) : score);
    }
    return out;
  }
  // Учитываются только запланированные дни, поэтому полувес 13 повторений, а не 13 календарных дней.
  final mult = math.pow(0.5, 1 / 13).toDouble();
  for (var d = math.min(first, from); d <= to; d = addDays(d, 1)) {
    final done = m.done.contains(d);
    final countable = d >= first && !m.skipped.contains(d) && (d != to || done);
    if (countable && (p.scheduled(d) || done)) {
      score = score * mult + (done ? 1 - mult : 0);
    }
    if (d >= from) out.add(score);
  }
  return out;
}

double habitStrength(HabitPlan p, HabitMarks m, int today) {
  final s = strengthSeries(p, m, from: today, to: today);
  return s.isEmpty ? 0 : s.last;
}

/// «Не пропускай дважды»: прошлый запланированный день пропущен, а сегодня ещё не сделано.
bool missedLastTime(HabitPlan p, HabitMarks m, int today) {
  if (p.weekly || m.done.contains(today) || !p.scheduled(today)) return false;
  var d = addDays(today, -1);
  for (var i = 0; i < 7; i++) {
    if (p.firstDay != null && d < p.firstDay!) return false;
    if (p.scheduled(d) && !m.skipped.contains(d)) return !m.done.contains(d);
    d = addDays(d, -1);
  }
  return false;
}

/// Доля выполнения по дням недели (Пн..Вс) за период. null: в этот день недели не было плана.
List<double?> weekdayRates(HabitPlan p, HabitMarks m, {required int from, required int to}) {
  final planned = List.filled(7, 0), done = List.filled(7, 0);
  final start = p.firstDay == null ? from : math.max(from, p.firstDay!);
  for (var d = start; d <= to; d = addDays(d, 1)) {
    final w = dayFromKey(d).weekday - 1;
    if (m.skipped.contains(d) || (d == to && !m.done.contains(d))) continue;
    if (p.scheduled(d)) {
      planned[w]++;
      if (m.done.contains(d)) done[w]++;
    }
  }
  return [for (var i = 0; i < 7; i++) planned[i] == 0 ? null : done[i] / planned[i]];
}

/// Сколько дней прошло с начала: для шкалы «на автоматизм в среднем 66 дней».
const habitFormationDays = 66;

int habitAgeDays(int firstDay, int today) => math.max(0, daysBetween(firstDay, today) + 1);

/// Время дня.
const partsOfDay = ['В любое время', 'Утро', 'День', 'Вечер'];

/// Подпись силы привычки.
String strengthLabel(double s) {
  if (s >= 0.8) return 'крепкая';
  if (s >= 0.5) return 'закрепляется';
  if (s >= 0.2) return 'формируется';
  return 'только начата';
}
