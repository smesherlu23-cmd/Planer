/// Как показывать и сводить значения трекеров, целей и копилок.
library;

import '../data/database.dart';
import '../data/dates.dart';
import 'calc.dart';

/// Значение трекера за один день.
/// Время складывается, остальное берётся последним за день.
double? dayValue(Tracker t, Iterable<TrackerEntry> entriesOfDay) {
  final list = entriesOfDay.where((e) => e.trackerId == t.id).toList();
  if (list.isEmpty) return null;
  if (t.kind == TrackerKind.duration) return list.fold<double>(0, (a, e) => a + e.value);
  list.sort(_byTime);
  return list.last.value;
}

int _byTime(TrackerEntry a, TrackerEntry b) {
  final d = a.day.compareTo(b.day);
  return d != 0 ? d : a.at.compareTo(b.at);
}

String formatTrackerValue(Tracker t, double v) {
  switch (t.kind) {
    case TrackerKind.duration:
      return formatDuration(v);
    case TrackerKind.yesNo:
      return v > 0 ? 'да' : 'нет';
    case TrackerKind.scale10:
      return '${formatNumber(v)} из 10';
    case TrackerKind.number:
      return t.unit == null ? formatNumber(v, maxDecimals: 2) : '${formatNumber(v, maxDecimals: 2)} ${t.unit}';
  }
}

String trackerKindLabel(TrackerKind k) => switch (k) {
  TrackerKind.number => 'Число',
  TrackerKind.scale10 => 'Оценка 1–10',
  TrackerKind.duration => 'Время',
  TrackerKind.yesNo => 'Да или нет',
};

/// Значения по дням, по возрастанию даты. Для графика.
List<(int day, double value)> dailySeries(Tracker t, Iterable<TrackerEntry> entries) {
  final byDay = <int, List<TrackerEntry>>{};
  for (final e in entries) {
    if (e.trackerId == t.id) byDay.putIfAbsent(e.day, () => []).add(e);
  }
  final days = byDay.keys.toList()..sort();
  return [for (final d in days) (d, dayValue(t, byDay[d]!)!)];
}

/// Сводка трекера за период: время суммой, оценки средним,
/// да/нет числом «да», число последним значением.
({double? value, String label}) periodSummary(Tracker t, Iterable<TrackerEntry> entries) {
  final series = dailySeries(t, entries);
  if (series.isEmpty) return (value: null, label: 'нет записей');
  switch (t.kind) {
    case TrackerKind.duration:
      final sum = series.fold<double>(0, (a, s) => a + s.$2);
      return (value: sum, label: 'всего ${formatDuration(sum)}, ${series.length} дн.');
    case TrackerKind.scale10:
      final avg = series.fold<double>(0, (a, s) => a + s.$2) / series.length;
      return (value: avg, label: 'в среднем ${formatNumber(avg)} из 10');
    case TrackerKind.yesNo:
      final yes = series.where((s) => s.$2 > 0).length;
      return (value: yes.toDouble(), label: 'да: $yes из ${series.length} дн.');
    case TrackerKind.number:
      final last = series.last.$2;
      return (value: last, label: 'последнее: ${formatTrackerValue(t, last)}');
  }
}

/// Текущее значение для цели по трекеру.
double? trackerGoalValue(Tracker t, Iterable<TrackerEntry> allEntries) {
  final series = dailySeries(t, allEntries);
  if (series.isEmpty) return null;
  switch (t.kind) {
    case TrackerKind.duration:
      // Цель по времени считаем в часах: «100 часов кода».
      return series.fold<double>(0, (a, s) => a + s.$2) / 60;
    case TrackerKind.yesNo:
      return series.where((s) => s.$2 > 0).length.toDouble();
    case TrackerKind.number:
    case TrackerKind.scale10:
      return series.last.$2;
  }
}

String goalUnit(Tracker? t) {
  if (t == null) return '';
  return switch (t.kind) {
    TrackerKind.duration => 'ч',
    TrackerKind.yesNo => 'дн.',
    TrackerKind.scale10 => 'из 10',
    TrackerKind.number => t.unit ?? '',
  };
}

/// Какую тренировку предложить сегодня: ту, что делали давно (или ещё ни разу).
/// При чередовании A и B это само даёт A–B–A, B–A–B.
Program? suggestProgram(List<Program> scheduled, List<WorkoutSession> sessions) {
  if (scheduled.isEmpty) return null;
  int lastDay(Program p) {
    var best = 0;
    for (final s in sessions) {
      if (s.programId == p.id && s.day > best) best = s.day;
    }
    return best;
  }

  final sorted = [...scheduled]
    ..sort((a, b) {
      final c = lastDay(a).compareTo(lastDay(b));
      if (c != 0) return c;
      final o = a.sortOrder.compareTo(b.sortOrder);
      return o != 0 ? o : a.id.compareTo(b.id);
    });
  return sorted.first;
}

/// Прогноз по копилке или долгу в месяцах. null, если посчитать нельзя.
({int? months, String text}) fundForecast(Fund f, double value, {double? recentMonthly}) {
  if (f.kind == FundKind.debt) {
    if (value <= 0) return (months: 0, text: 'Долг закрыт!');
    final pay = f.monthlyAmount;
    if (pay == null || pay <= 0) return (months: null, text: 'Укажи платёж в месяц, чтобы увидеть срок');
    final m = monthsToPayOff(balance: value, monthlyPayment: pay, annualRatePercent: f.interestRate);
    if (m == null) return (months: null, text: 'Платёж не покрывает проценты');
    final when = addMonths(todayKey(), m);
    final note = f.interestRate == null ? ', без учёта процентов' : '';
    return (months: m, text: 'Закроешь примерно в ${_monthName(when)} ($m мес.$note)');
  }
  final target = f.target;
  if (target == null) return (months: null, text: '');
  if (value >= target) return (months: 0, text: 'Накоплено!');
  final planned = f.monthlyAmount;
  final pace = (planned != null && planned > 0) ? planned : recentMonthly;
  if (pace == null || pace <= 0) return (months: null, text: 'Укажи взнос в месяц, чтобы увидеть срок');
  final m = monthsToSave(balance: value, target: target, monthly: pace)!;
  final when = addMonths(todayKey(), m);
  final how = planned != null && planned > 0 ? '' : ' при текущем темпе ${formatMoney(pace)} в месяц';
  return (months: m, text: 'Накопишь примерно в ${_monthName(when)}$how ($m мес.)');
}

const _monthsPrepositional = [
  'январе',
  'феврале',
  'марте',
  'апреле',
  'мае',
  'июне',
  'июле',
  'августе',
  'сентябре',
  'октябре',
  'ноябре',
  'декабре',
];

String _monthName(int key) {
  final d = dayFromKey(key);
  return '${_monthsPrepositional[d.month - 1]} ${d.year}';
}

/// Средний чистый взнос в месяц за последние 90 дней.
double? recentMonthlyPace(Iterable<FundMove> moves, int fundId, {int? today}) {
  final t = today ?? todayKey();
  final from = addDays(t, -90);
  final relevant = moves.where((m) => m.fundId == fundId && m.day > from && m.day <= t).toList();
  if (relevant.isEmpty) return null;
  final sum = relevant.fold<double>(0, (a, m) => a + m.amount);
  return sum / 3;
}
