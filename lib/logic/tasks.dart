/// Задачи: быстрый ввод, повторы, разбивка по спискам и загрузка дня.
library;

import '../data/database.dart';
import '../data/dates.dart';

// ---------------------------------------------------------------------------
// Приоритет и повтор
// ---------------------------------------------------------------------------

const priorityLabels = {1: 'Главное', 2: 'Важное', 3: 'Обычное', 4: 'Без приоритета'};

extension TaskRepeatLabel on TaskRepeat {
  String get label => switch (this) {
    TaskRepeat.none => 'Не повторять',
    TaskRepeat.daily => 'Каждый день',
    TaskRepeat.weekdays => 'По будням',
    TaskRepeat.weekly => 'Каждую неделю',
    TaskRepeat.monthly => 'Каждый месяц',
  };
}

/// Следующий день повтора строго после [today] и после [from].
int nextRepeatDay(TaskRepeat repeat, int from, int today) {
  int step(int d) {
    switch (repeat) {
      case TaskRepeat.none:
        return d;
      case TaskRepeat.daily:
        return addDays(d, 1);
      case TaskRepeat.weekdays:
        var n = addDays(d, 1);
        while (dayFromKey(n).weekday > 5) {
          n = addDays(n, 1);
        }
        return n;
      case TaskRepeat.weekly:
        return addDays(d, 7);
      case TaskRepeat.monthly:
        final date = dayFromKey(d);
        // Число месяца сохраняется, а 31-е в коротком месяце становится последним днём.
        final want = (d % 100);
        final lastDay = DateTime(date.year, date.month + 2, 0).day;
        return dayKey(DateTime(date.year, date.month + 1, want > lastDay ? lastDay : want));
    }
  }

  if (repeat == TaskRepeat.none) return from;
  var d = step(from);
  while (d <= today) {
    d = step(d);
  }
  return d;
}

// ---------------------------------------------------------------------------
// Быстрый ввод
// ---------------------------------------------------------------------------

class QuickTask {
  const QuickTask({required this.title, this.day, this.time, this.priority, this.estimate, this.kind});
  final String title;
  final int? day;
  final int? time;
  final int? priority;
  final int? estimate;
  final BlockKind? kind;
}

const _weekdayWords = {
  'пн': 1,
  'понедельник': 1,
  'вт': 2,
  'вторник': 2,
  'ср': 3,
  'среда': 3,
  'среду': 3,
  'чт': 4,
  'четверг': 4,
  'пт': 5,
  'пятница': 5,
  'пятницу': 5,
  'сб': 6,
  'суббота': 6,
  'субботу': 6,
  'вс': 7,
  'воскресенье': 7,
};

const _kindWords = {
  'работа': BlockKind.work,
  'учеба': BlockKind.study,
  'учёба': BlockKind.study,
  'код': BlockKind.study,
  'спорт': BlockKind.sport,
  'отдых': BlockKind.rest,
  'дом': BlockKind.home,
  'дела': BlockKind.home,
  'дорога': BlockKind.road,
  'еда': BlockKind.food,
  'другое': BlockKind.other,
};

final _time = RegExp(r'^(\d{1,2}):(\d{2})$');
final _date = RegExp(r'^(\d{1,2})\.(\d{1,2})(?:\.(\d{2,4}))?$');
final _estimate = RegExp(r'^~?(\d+(?:[.,]\d+)?)(м|мин|ч|час|часа|часов)$');
final _tilde = RegExp(r'^~(\d+)$');
final _priority = RegExp(r'^!([1-4])?$');

/// Разобрать строку вида «Docker урок завтра в 18:00 !1 ~45м #учёба».
///
/// Понимает: сегодня, завтра, послезавтра, дни недели (пн, в пятницу), дату 12.11,
/// время 18:00, приоритет !1…!4, оценку ~30, 45м, 1.5ч и сферу через #.
/// Всё, что не распознано, остаётся в названии.
QuickTask parseQuickTask(String input, {required int today}) {
  final words = input.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final rest = <String>[];
  int? day, time, priority, estimate;
  BlockKind? kind;

  int? weekdayDay(int weekday) {
    final now = dayFromKey(today).weekday;
    return addDays(today, (weekday - now) % 7);
  }

  int? timeOf(String w) {
    final m = _time.firstMatch(w);
    if (m == null) return null;
    final h = int.parse(m[1]!), min = int.parse(m[2]!);
    if (h > 23 || min > 59) return null;
    return h * 60 + min;
  }

  int? dayOf(String w) {
    switch (w) {
      case 'сегодня':
        return today;
      case 'завтра':
        return addDays(today, 1);
      case 'послезавтра':
        return addDays(today, 2);
    }
    final wd = _weekdayWords[w];
    if (wd != null) return weekdayDay(wd);
    final m = _date.firstMatch(w);
    if (m != null) {
      final d = int.parse(m[1]!), mon = int.parse(m[2]!);
      if (d < 1 || d > 31 || mon < 1 || mon > 12) return null;
      var y = m[3] == null ? today ~/ 10000 : int.parse(m[3]!);
      if (y < 100) y += 2000;
      var key = y * 10000 + mon * 100 + d;
      // Дата без года в прошлом: значит, в следующем году.
      if (m[3] == null && key < today) key += 10000;
      return dayKey(dayFromKey(key));
    }
    return null;
  }

  for (var i = 0; i < words.length; i++) {
    final raw = words[i];
    final w = raw.toLowerCase();
    // «в 18:00», «в пятницу», «во вторник»: предлог съедается вместе со словом.
    if ((w == 'в' || w == 'во') && i + 1 < words.length) {
      final next = words[i + 1].toLowerCase();
      final t = timeOf(next);
      final d = t == null ? dayOf(next) : null;
      if (t != null && time == null) {
        time = t;
        i++;
        continue;
      }
      if (d != null && day == null) {
        day = d;
        i++;
        continue;
      }
    }
    if (time == null) {
      final t = timeOf(w);
      if (t != null) {
        time = t;
        continue;
      }
    }
    if (day == null) {
      final d = dayOf(w);
      if (d != null) {
        day = d;
        continue;
      }
    }
    if (priority == null) {
      final m = _priority.firstMatch(w);
      if (m != null) {
        priority = m[1] == null ? 1 : int.parse(m[1]!);
        continue;
      }
    }
    if (estimate == null) {
      final m = _estimate.firstMatch(w);
      if (m != null) {
        final v = double.parse(m[1]!.replaceAll(',', '.'));
        estimate = (m[2]!.startsWith('ч') ? v * 60 : v).round();
        continue;
      }
      final t = _tilde.firstMatch(w);
      if (t != null) {
        estimate = int.parse(t[1]!);
        continue;
      }
    }
    if (kind == null && w.startsWith('#') && _kindWords.containsKey(w.substring(1))) {
      kind = _kindWords[w.substring(1)];
      continue;
    }
    rest.add(raw);
  }
  // Время без дня: значит, сегодня.
  if (time != null && day == null) day = today;
  return QuickTask(title: rest.join(' '), day: day, time: time, priority: priority, estimate: estimate, kind: kind);
}

// ---------------------------------------------------------------------------
// Списки
// ---------------------------------------------------------------------------

/// Порядок внутри списка: приоритет, потом время, потом ручной порядок.
int compareTasks(Task a, Task b) {
  final p = a.priority.compareTo(b.priority);
  if (p != 0) return p;
  final at = a.time ?? 99999, bt = b.time ?? 99999;
  if (at != bt) return at.compareTo(bt);
  final o = a.sortOrder.compareTo(b.sortOrder);
  if (o != 0) return o;
  return a.id.compareTo(b.id);
}

class TodayTasks {
  const TodayTasks({required this.overdue, required this.main, required this.other, required this.done});
  final List<Task> overdue;

  /// Главные задачи дня (приоритет 1): с них стоит начинать.
  final List<Task> main;
  final List<Task> other;
  final List<Task> done;

  List<Task> get open => [...overdue, ...main, ...other];
  int get total => open.length + done.length;

  /// Сколько минут займут несделанные задачи по оценкам.
  int get estimateLeft => open.fold(0, (s, t) => s + (t.estimate ?? 0));
}

/// Только верхний уровень: шаги показываются внутри задачи.
TodayTasks todayTasks(List<Task> all, int today) {
  final top = all.where((t) => t.parentId == null);
  final overdue = top.where((t) => t.doneDay == null && t.day != null && t.day! < today).toList()
    ..sort((a, b) => a.day!.compareTo(b.day!) != 0 ? a.day!.compareTo(b.day!) : compareTasks(a, b));
  final todays = top.where((t) => t.doneDay == null && t.day == today).toList()..sort(compareTasks);
  final done = top.where((t) => t.doneDay == today).toList()..sort((a, b) => (b.doneAt ?? DateTime(0)).compareTo(a.doneAt ?? DateTime(0)));
  return TodayTasks(
    overdue: overdue,
    main: todays.where((t) => t.priority == 1).toList(),
    other: todays.where((t) => t.priority != 1).toList(),
    done: done,
  );
}

/// Задачи на будущие дни по дням. Ключ null: дальше [days] дней.
Map<int?, List<Task>> upcomingTasks(List<Task> all, int today, {int days = 14}) {
  final last = addDays(today, days);
  final result = <int?, List<Task>>{};
  final list = all.where((t) => t.parentId == null && t.doneDay == null && t.day != null && t.day! > today).toList()
    ..sort((a, b) => a.day!.compareTo(b.day!) != 0 ? a.day!.compareTo(b.day!) : compareTasks(a, b));
  for (final t in list) {
    result.putIfAbsent(t.day! <= last ? t.day : null, () => []).add(t);
  }
  return result;
}

List<Task> inboxTasks(List<Task> all) =>
    all.where((t) => t.parentId == null && t.doneDay == null && t.day == null).toList()..sort(compareTasks);

/// Сделанные задачи, свежие сверху.
List<Task> doneTasks(List<Task> all, {int limit = 60}) {
  final list = all.where((t) => t.parentId == null && t.doneDay != null).toList()
    ..sort((a, b) => (b.doneAt ?? DateTime(0)).compareTo(a.doneAt ?? DateTime(0)));
  return list.take(limit).toList();
}

/// Шаги задачи: сколько сделано из скольких.
({int done, int total}) stepsOf(List<Task> all, int taskId) {
  var done = 0, total = 0;
  for (final t in all) {
    if (t.parentId != taskId) continue;
    total++;
    if (t.doneDay != null) done++;
  }
  return (done: done, total: total);
}

/// Что делать сейчас: главная задача той же сферы, что и текущий блок, иначе любая главная.
Task? suggestTask(TodayTasks today, BlockKind? blockKind) {
  final open = today.open;
  if (open.isEmpty) return null;
  if (blockKind != null) {
    final same = open.where((t) => t.kind == blockKind).toList()..sort(compareTasks);
    if (same.isNotEmpty) return same.first;
  }
  final sorted = [...open]..sort(compareTasks);
  return sorted.first;
}
