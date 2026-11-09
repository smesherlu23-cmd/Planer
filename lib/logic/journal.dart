/// Дневник: структура записей, теги, серии и выводы по настроению.
///
/// Итог дня собран из коротких полей, как в «Дневнике пяти минут» и Daylio:
/// настроение и энергия, что было за день (теги), победы, благодарность,
/// урок и главное на завтра. Обзоры недели и месяца идут по схеме
/// «что получилось, что нет, что меняю» (ретроспектива).
library;

import '../data/database.dart';
import '../data/dates.dart';

/// Подписи полей для каждого вида записи. null: поля у этого вида нет.
class JournalFields {
  const JournalFields({this.wins, this.gratitude, this.lesson, this.focus, this.body = 'Мысли'});
  final String? wins;
  final String? gratitude;
  final String? lesson;
  final String? focus;
  final String body;
}

JournalFields journalFields(JournalKind k) => switch (k) {
  JournalKind.day => const JournalFields(
    wins: 'Победы дня',
    gratitude: 'За что благодарен',
    lesson: 'Что улучшить',
    focus: 'Главное на завтра',
    body: 'Мысли и события',
  ),
  JournalKind.week => const JournalFields(
    wins: 'Что получилось',
    lesson: 'Что не получилось и почему',
    focus: 'Главное на следующую неделю',
    body: 'Заметки',
  ),
  JournalKind.month => const JournalFields(
    wins: 'Главные достижения месяца',
    lesson: 'Что мешало, что меняю',
    focus: 'Фокус на следующий месяц',
    body: 'Заметки',
  ),
  JournalKind.note => const JournalFields(body: 'Текст'),
};

/// Подсказки к полям.
String? journalFieldHint(JournalKind k, String field) => switch ((k, field)) {
  (JournalKind.day, 'wins') => 'По строке на дело: час кода, тренировка, лёг вовремя',
  (JournalKind.day, 'gratitude') => 'Мелочи тоже считаются',
  (JournalKind.day, 'lesson') => 'Одна вещь, которую сделаю иначе',
  (JournalKind.day, 'focus') => 'Одно дело, которое сделаю в первую очередь',
  (JournalKind.week, 'wins') => 'Победы, даже маленькие',
  (JournalKind.week, 'lesson') => 'Без самокритики: что помешало',
  (JournalKind.week, 'focus') => '1–3 главных дела',
  (JournalKind.month, 'focus') => 'Одна-две цели месяца',
  _ => null,
};

/// Теги, которые предлагаются, пока своих мало.
const defaultTags = [
  'работа',
  'спорт',
  'код',
  'учёба',
  'семья',
  'друзья',
  'игры',
  'прогулка',
  'отдых',
  'хороший сон',
  'плохой сон',
  'стресс',
  'болезнь',
  'деньги',
];

List<String> parseTags(String? s) => [
  for (final t in (s ?? '').split(','))
    if (t.trim().isNotEmpty) t.trim().toLowerCase(),
];

String? joinTags(Iterable<String> tags) {
  final list = {for (final t in tags) t.trim().toLowerCase()}.where((t) => t.isNotEmpty).toList();
  return list.isEmpty ? null : list.join(', ');
}

/// Строки списка без пустых и без номеров «1.», «-».
List<String> listLines(String? s) => [
  for (final l in (s ?? '').split('\n'))
    if (l.replaceFirst(RegExp(r'^\s*(\d+[.)]|[-•*])\s*'), '').trim() case final t when t.isNotEmpty) t,
];

/// Теги по частоте: свои сначала, потом стандартные.
List<String> tagSuggestions(Iterable<JournalEntry> entries) {
  final count = <String, int>{};
  for (final e in entries) {
    for (final t in parseTags(e.tags)) {
      count[t] = (count[t] ?? 0) + 1;
    }
  }
  final own = count.keys.toList()..sort((a, b) => count[b]!.compareTo(count[a]!));
  return [...own, ...defaultTags.where((t) => !count.containsKey(t))];
}

/// Есть ли в записи что-то кроме пустого шаблона.
bool journalHasContent(JournalEntry e) =>
    e.mood != null ||
    [e.body, e.wins, e.gratitude, e.lesson, e.focus, e.title].any((s) => s != null && listLines(s).isNotEmpty) ||
    parseTags(e.tags).isNotEmpty;

/// Короткий текст записи для ленты.
String journalPreview(JournalEntry e) {
  final parts = [
    ...listLines(e.wins),
    ...listLines(e.body).where((l) => !RegExp(r'^Что (сделал|получилось|не получилось|меняю).*:$').hasMatch(l)),
    ...listLines(e.gratitude),
  ];
  return parts.join(' · ');
}

/// Серия итогов дня: сколько дней подряд есть запись. Сегодняшний пропуск серию не рвёт.
int journalStreak(Iterable<JournalEntry> entries, {required int today}) {
  final days = {
    for (final e in entries)
      if (e.kind == JournalKind.day) e.day,
  };
  var d = days.contains(today) ? today : addDays(today, -1);
  var n = 0;
  while (days.contains(d)) {
    n++;
    d = addDays(d, -1);
  }
  return n;
}

/// Лучшая серия за всё время.
int journalBestStreak(Iterable<JournalEntry> entries) {
  final days = {
    for (final e in entries)
      if (e.kind == JournalKind.day) e.day,
  }.toList()..sort();
  var best = 0;
  var cur = 0;
  int? prev;
  for (final d in days) {
    cur = prev != null && addDays(prev, 1) == d ? cur + 1 : 1;
    if (cur > best) best = cur;
    prev = d;
  }
  return best;
}

double? average(Iterable<num> values) {
  final list = values.toList();
  if (list.isEmpty) return null;
  return list.fold<double>(0, (a, b) => a + b) / list.length;
}

/// Как тег связан с настроением: среднее в дни с тегом и в остальные.
class TagMood {
  TagMood(this.tag, this.days, this.withTag, this.without);
  final String tag;
  final int days;
  final double withTag;
  final double? without;

  double get delta => without == null ? 0 : withTag - without!;
}

/// Влияние тегов на настроение. Учитываются теги, встретившиеся хотя бы [minDays] раз.
List<TagMood> tagMoods(Iterable<JournalEntry> entries, {int minDays = 2}) {
  final days = [
    for (final e in entries)
      if (e.kind == JournalKind.day && e.mood != null) e,
  ];
  final tags = {for (final e in days) ...parseTags(e.tags)};
  final result = <TagMood>[];
  for (final t in tags) {
    final withT = [
      for (final e in days)
        if (parseTags(e.tags).contains(t)) e.mood!,
    ];
    if (withT.length < minDays) continue;
    final rest = [
      for (final e in days)
        if (!parseTags(e.tags).contains(t)) e.mood!,
    ];
    result.add(TagMood(t, withT.length, average(withT)!, average(rest)));
  }
  result.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
  return result;
}

/// Среднее настроение по дням недели: индекс 0 = понедельник. null: записей нет.
List<double?> moodByWeekday(Iterable<JournalEntry> entries) {
  final sums = List<List<int>>.generate(7, (_) => []);
  for (final e in entries) {
    if (e.kind == JournalKind.day && e.mood != null) sums[dayFromKey(e.day).weekday - 1].add(e.mood!);
  }
  return [for (final s in sums) average(s)];
}

/// Настроение по дням за период: день и оценка (или null).
List<(int day, int? mood)> moodSeries(Iterable<JournalEntry> entries, {required int from, required int to}) {
  final byDay = {
    for (final e in entries)
      if (e.kind == JournalKind.day && e.mood != null) e.day: e.mood,
  };
  return [for (var d = from; d <= to; d = addDays(d, 1)) (d, byDay[d])];
}

/// Вопросы для размышления в заметке. Меняются каждый день.
const reflectionPrompts = [
  'Что сегодня дало больше всего энергии?',
  'Что я откладываю и почему?',
  'Какой маленький шаг к главной цели можно сделать завтра?',
  'Чем я горжусь за последнюю неделю?',
  'Что бы я сказал себе год назад?',
  'Что отнимает время, но ничего не даёт?',
  'Кому я благодарен и сказал ли я ему об этом?',
  'Каким я хочу быть через год? Что для этого нужно делать каждый день?',
  'Что сегодня пошло не по плану и чему это научило?',
  'Какая привычка сильнее всего меняет мои дни?',
  'Где я был слишком строг к себе?',
  'Что меня сейчас тревожит? Что из этого я могу контролировать?',
  'Какой навык сейчас важнее всего прокачать?',
  'Как выглядит мой идеальный обычный день?',
];

String promptOfDay(int day) => reflectionPrompts[daysBetween(20260101, day).abs() % reflectionPrompts.length];

/// Ключ записи-обзора: для недели понедельник, для месяца первое число.
int journalAnchor(JournalKind k, int day) => switch (k) {
  JournalKind.week => weekStart(day),
  JournalKind.month => day ~/ 100 * 100 + 1,
  _ => day,
};

String monthName(int day) {
  final d = dayFromKey(day);
  return monthTitle(d.year, d.month);
}
