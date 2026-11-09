/// Работа с датами.
///
/// День хранится в базе как целое число вида 20261108 (год, месяц, день).
/// Так его легко сравнивать, сортировать и группировать.
library;

int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

DateTime dayFromKey(int key) => DateTime(key ~/ 10000, (key ~/ 100) % 100, key % 100);

int todayKey([DateTime? now]) => dayKey(now ?? DateTime.now());

int addDays(int key, int days) {
  final d = dayFromKey(key);
  return dayKey(DateTime(d.year, d.month, d.day + days));
}

/// Понедельник недели, в которую входит день.
int weekStart(int key) {
  final d = dayFromKey(key);
  return dayKey(DateTime(d.year, d.month, d.day - (d.weekday - 1)));
}

int daysBetween(int fromKey, int toKey) {
  final a = dayFromKey(fromKey);
  final b = dayFromKey(toKey);
  return DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}

/// Маска дней недели: бит 0 = понедельник, бит 6 = воскресенье.
const int everyDay = 127;
const int weekdaysOnly = 31;

bool maskHasWeekday(int mask, int weekday) => (mask & (1 << (weekday - 1))) != 0;

bool maskHasDay(int mask, int key) => maskHasWeekday(mask, dayFromKey(key).weekday);

int maskFromWeekdays(Iterable<int> weekdays) {
  var m = 0;
  for (final w in weekdays) {
    m |= 1 << (w - 1);
  }
  return m;
}

List<int> weekdaysFromMask(int mask) => [
  for (var w = 1; w <= 7; w++)
    if (maskHasWeekday(mask, w)) w,
];

const weekdayShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

String maskLabel(int mask) {
  if (mask == everyDay) return 'каждый день';
  if (mask == weekdaysOnly) return 'по будням';
  if (mask == 0) return 'без расписания';
  return weekdaysFromMask(mask).map((w) => weekdayShort[w - 1]).join(', ');
}

const _months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];

const _monthsNominative = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

const _weekdaysLong = ['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'];

String formatDay(int key, {bool withYear = false}) {
  final d = dayFromKey(key);
  final base = '${d.day} ${_months[d.month - 1]}';
  return withYear ? '$base ${d.year}' : base;
}

String formatDayLong(int key) {
  final d = dayFromKey(key);
  return '${_weekdaysLong[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';
}

String monthTitle(int year, int month) => '${_monthsNominative[month - 1]} $year';

/// Время в минутах от полуночи -> "07:30".
String formatMinutes(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// Длительность в минутах -> "1 ч 45 мин".
String formatDuration(num minutes) {
  final total = minutes.round();
  final h = total ~/ 60;
  final m = total % 60;
  if (h == 0) return '$m мин';
  if (m == 0) return '$h ч';
  return '$h ч $m мин';
}

/// Месяц как число yyyymm.
int monthKey(DateTime d) => d.year * 100 + d.month;

DateTime monthFromKey(int key) => DateTime(key ~/ 100, key % 100);

/// Сколько дней месяца осталось, включая сегодня. Для прошлых месяцев 0, для будущих все дни.
int daysLeftInMonth(DateTime month, DateTime now) {
  final last = DateTime(month.year, month.month + 1, 0);
  if (!now.isBefore(DateTime(month.year, month.month + 1))) return 0;
  if (now.isBefore(month)) return last.day;
  return last.day - now.day + 1;
}
