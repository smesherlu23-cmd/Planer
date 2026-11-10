import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/goal_queries.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import '../logic/journal.dart';
import '../logic/report.dart';
import 'charts.dart';
import 'common.dart';
import 'icons.dart';
import 'theme.dart';

String journalKindLabel(JournalKind k) => switch (k) {
  JournalKind.day => 'Итог дня',
  JournalKind.week => 'Обзор недели',
  JournalKind.month => 'Обзор месяца',
  JournalKind.note => 'Заметка',
};

IconData journalKindIcon(JournalKind k) => switch (k) {
  JournalKind.day => Icons.edit_note_rounded,
  JournalKind.week => Icons.insights_rounded,
  JournalKind.month => Icons.calendar_month_rounded,
  JournalKind.note => Icons.sticky_note_2_rounded,
};

String _kindHint(JournalKind k) => switch (k) {
  JournalKind.day => 'Настроение, победы, благодарность и главное на завтра',
  JournalKind.week => 'Что получилось, что нет, что меняю',
  JournalKind.month => 'Итоги месяца и фокус на следующий',
  JournalKind.note => 'Любая мысль, идея или запись к цели',
};

/// Порядок видов в меню создания.
const _kindOrder = [JournalKind.day, JournalKind.note, JournalKind.week, JournalKind.month];

IconData moodIcon(int mood) => mood <= 2
    ? Icons.sentiment_very_dissatisfied_rounded
    : mood <= 4
    ? Icons.sentiment_dissatisfied_rounded
    : mood <= 6
    ? Icons.sentiment_neutral_rounded
    : mood <= 8
    ? Icons.sentiment_satisfied_rounded
    : Icons.sentiment_very_satisfied_rounded;

/// Цвет настроения: от красного к зелёному.
Color moodColor(num mood) => Color.lerp(const Color(0xFFEF4444), const Color(0xFF22C55E), ((mood - 1) / 9).clamp(0, 1).toDouble())!;

const _energyLabels = ['без сил', 'вяло', 'норм', 'бодро', 'на максимум'];

/// Подпись даты записи.
String journalDateLabel(JournalEntry e) => switch (e.kind) {
  JournalKind.week => 'неделя с ${formatDay(e.day)}',
  JournalKind.month => monthName(e.day).toLowerCase(),
  _ => dayLabel(e.day),
};

/// Открыть запись. Итог дня, обзор недели и месяца бывают только в одном экземпляре на период:
/// если запись уже есть, откроется она.
Future<void> openJournalEditor(
  BuildContext context, {
  required JournalKind kind,
  required int day,
  JournalEntry? existing,
  int? goalId,
}) async {
  final anchor = journalAnchor(kind, day);
  var e = existing;
  if (e == null && kind != JournalKind.note) e = await context.db.journalFor(kind, anchor);
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => JournalEditScreen(kind: kind, day: anchor, existing: e, goalId: goalId),
    ),
  );
}

Future<void> _createEntry(BuildContext context, {int? day}) async {
  final kind = await showModalBottomSheet<JournalKind>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final k in _kindOrder)
            ListTile(
              leading: ColorIcon(journalKindIcon(k), size: 40, color: Accent.journal),
              title: Text(journalKindLabel(k)),
              subtitle: Text(_kindHint(k)),
              onTap: () => Navigator.pop(context, k),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (kind == null || !context.mounted) return;
  await openJournalEditor(context, kind: kind, day: day ?? todayKey());
}

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return DefaultTabController(
      length: 3,
      child: ScrollFabScope(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Дневник'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Лента'),
                Tab(text: 'Календарь'),
                Tab(text: 'Выводы'),
              ],
            ),
          ),
          floatingActionButton: ScrollFab(
            child: FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _createEntry(context),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Запись'),
            ),
          ),
          body: Watch(
            streams: () => [db.watchAllJournal()],
            builder: (context, v) {
              final entries = v[0] as List<JournalEntry>;
              return TabBarView(
                children: [
                  _Feed(entries: entries),
                  _Calendar(entries: entries),
                  _Insights(entries: entries),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Лента
// ---------------------------------------------------------------------------

class _Feed extends StatefulWidget {
  const _Feed({required this.entries});
  final List<JournalEntry> entries;

  @override
  State<_Feed> createState() => _FeedState();
}

class _FeedState extends State<_Feed> {
  JournalKind? _kind;
  String? _tag;
  String _query = '';
  bool _search = false;

  bool _matches(JournalEntry e) {
    if (_kind != null && e.kind != _kind) return false;
    if (_tag != null && !parseTags(e.tags).contains(_tag)) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return [e.title, e.body, e.wins, e.gratitude, e.lesson, e.focus, e.tags].any((s) => s != null && s.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.entries;
    final today = todayKey();
    final list = all.where(_matches).toList();
    final tags = tagSuggestions(all).where((t) => all.any((e) => parseTags(e.tags).contains(t))).take(12).toList();
    final children = <Widget>[
      _JournalHero(entries: all, today: today),
      _TodayFocus(entries: all, today: today),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            IconButton.filledTonal(
              icon: Icon(_search ? Icons.close_rounded : Icons.search_rounded),
              tooltip: 'Поиск',
              onPressed: () => setState(() {
                _search = !_search;
                if (!_search) _query = '';
              }),
            ),
            const SizedBox(width: 4),
            ChoiceChip(
              label: const Text('Все'),
              showCheckmark: false,
              selected: _kind == null,
              onSelected: (_) => setState(() => _kind = null),
            ),
            for (final k in _kindOrder) ...[
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: Icon(journalKindIcon(k), color: Accent.journal),
                label: Text(journalKindLabel(k)),
                showCheckmark: false,
                selected: _kind == k,
                onSelected: (_) => setState(() => _kind = _kind == k ? null : k),
              ),
            ],
          ],
        ),
      ),
      if (_search)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Искать в записях'),
            onChanged: (q) => setState(() => _query = q.trim()),
          ),
        ),
      if (tags.isNotEmpty)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              for (final t in tags) ...[
                FilterChip(
                  label: Text('#$t'),
                  visualDensity: VisualDensity.compact,
                  selected: _tag == t,
                  onSelected: (on) => setState(() => _tag = on ? t : null),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
    ];
    if (list.isEmpty) {
      children.add(
        EmptyHint(
          all.isEmpty
              ? 'Итог дня занимает две минуты: настроение, пара побед и главное на завтра. '
                    'Через месяц здесь будет видно, что делает твои дни лучше.'
              : 'Ничего не нашлось',
          icon: Icons.auto_stories_rounded,
          action: all.isEmpty
              ? FilledButton.tonal(
                  onPressed: () => openJournalEditor(context, kind: JournalKind.day, day: today),
                  child: const Text('Написать итог дня'),
                )
              : null,
        ),
      );
    } else {
      int? month;
      for (final e in list.take(200)) {
        final m = e.day ~/ 100;
        if (m != month) {
          month = m;
          children.add(SectionTitle(monthName(e.day)));
        }
        children.add(JournalEntryCard(entry: e));
      }
    }
    return ListView(padding: const EdgeInsets.only(bottom: 96), children: children);
  }
}

class _JournalHero extends StatelessWidget {
  const _JournalHero({required this.entries, required this.today});
  final List<JournalEntry> entries;
  final int today;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final streak = journalStreak(entries, today: today);
    final best = journalBestStreak(entries);
    final from = addDays(today, -29);
    final last30 = entries.where((e) => e.day >= from && e.kind == JournalKind.day).toList();
    final mood = average([
      for (final e in last30)
        if (e.mood != null) e.mood!,
    ]);
    final wroteToday = entries.any((e) => e.kind == JournalKind.day && e.day == today);
    return HeroCard(
      colors: dark ? const [Color(0xFFBE185D), Color(0xFF7C3AED)] : const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
      onTap: () => openJournalEditor(context, kind: JournalKind.day, day: today),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streak == 0 ? 'Начни серию сегодня' : 'Серия: ${_daysWord(streak)}',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      wroteToday ? 'Итог дня записан. Можно дополнить.' : 'Итог дня ещё не записан. Нажми, это пара минут.',
                      style: const TextStyle(color: Colors.white70, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: HeroStat(label: '30 дней', value: '${last30.length}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HeroStat(label: 'Среднее', value: mood == null ? '—' : formatNumber(mood)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HeroStat(label: 'Рекорд', value: '$best'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _daysWord(int n) {
  final m10 = n % 10;
  final m100 = n % 100;
  final w = (m10 == 1 && m100 != 11)
      ? 'день'
      : (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14))
      ? 'дня'
      : 'дней';
  return '$n $w';
}

/// «Главное на сегодня» из вчерашнего итога дня.
class _TodayFocus extends StatelessWidget {
  const _TodayFocus({required this.entries, required this.today});
  final List<JournalEntry> entries;
  final int today;

  @override
  Widget build(BuildContext context) {
    final y = entries.where((e) => e.kind == JournalKind.day && e.day == addDays(today, -1)).firstOrNull;
    final week = entries.where((e) => e.kind == JournalKind.week && e.day == addDays(weekStart(today), -7)).firstOrNull;
    final items = [
      if (listLines(y?.focus).isNotEmpty) ('Главное на сегодня', listLines(y!.focus).join('\n')),
      if (listLines(week?.focus).isNotEmpty) ('Фокус недели', listLines(week!.focus).join('\n')),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (label, text) in items) ...[
              Row(
                children: [
                  const Icon(Icons.center_focus_strong_rounded, size: 18, color: Accent.journal),
                  const SizedBox(width: 8),
                  Text(label, style: theme.textTheme.labelLarge?.copyWith(color: Accent.journal)),
                ],
              ),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(height: 1.4)),
              if (label != items.last.$1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class JournalEntryCard extends StatelessWidget {
  const JournalEntryCard({super.key, required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final preview = journalPreview(e);
    final tags = parseTags(e.tags);
    final title = e.title ?? journalKindLabel(e.kind);
    return Card(
      child: InkWell(
        onTap: () => openJournalEditor(context, kind: e.kind, day: e.day, existing: e),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  e.mood != null && e.kind == JournalKind.day
                      ? ColorIcon(moodIcon(e.mood!), size: 40, color: moodColor(e.mood!))
                      : ColorIcon(journalKindIcon(e.kind), size: 40, color: Accent.journal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          [journalDateLabel(e), if (e.energy != null) 'энергия ${e.energy}/5'].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  if (e.mood != null) Pill('${e.mood}', icon: moodIcon(e.mood!), color: moodColor(e.mood!)),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(preview, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.4)),
              ],
              if (listLines(e.focus).isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.center_focus_strong_rounded, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        listLines(e.focus).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ),
                  ],
                ),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final t in tags) Pill('#$t', color: Accent.journal)]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Календарь настроения
// ---------------------------------------------------------------------------

class _Calendar extends StatefulWidget {
  const _Calendar({required this.entries});
  final List<JournalEntry> entries;

  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  late DateTime _month = () {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final today = todayKey();
    final first = dayKey(_month);
    final last = dayKey(DateTime(_month.year, _month.month + 1, 0));
    final days = {
      for (final e in widget.entries)
        if (e.kind == JournalKind.day && e.day >= first && e.day <= last) e.day: e,
    };
    final notes = {
      for (final e in widget.entries)
        if (e.kind == JournalKind.note && e.day >= first && e.day <= last) e.day,
    };
    final moods = [
      for (final e in days.values)
        if (e.mood != null) e.mood!,
    ];
    final avg = average(moods);
    final best = days.values.where((e) => e.mood != null).fold<JournalEntry?>(null, (a, e) => a == null || e.mood! > a.mood! ? e : a);
    final offset = _month.weekday - 1;
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    final isCurrent = _month.year == DateTime.now().year && _month.month == DateTime.now().month;
    final review = widget.entries.where((e) => e.kind == JournalKind.month && e.day == first).firstOrNull;
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                    ),
                    Expanded(
                      child: Text(monthTitle(_month.year, _month.month), textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: isCurrent ? null : () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (final w in weekdayShort)
                      Expanded(
                        child: Center(
                          child: Text(w, style: theme.textTheme.labelSmall?.copyWith(color: muted)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                for (var row = 0; row * 7 < offset + count; row++)
                  Row(
                    children: [
                      for (var col = 0; col < 7; col++)
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final n = row * 7 + col - offset + 1;
                              if (n < 1 || n > count) return const SizedBox(height: 46);
                              final day = dayKey(DateTime(_month.year, _month.month, n));
                              final e = days[day];
                              final future = day > today;
                              final color = e?.mood != null ? moodColor(e!.mood!) : null;
                              return Padding(
                                padding: const EdgeInsets.all(2.5),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: future ? null : () => openJournalEditor(context, kind: JournalKind.day, day: day, existing: e),
                                  child: Container(
                                    height: 41,
                                    decoration: BoxDecoration(
                                      color:
                                          color ??
                                          (e != null
                                              ? Accent.journal.withValues(alpha: 0.18)
                                              : scheme.surfaceContainerHighest.withValues(alpha: future ? 0.25 : 0.6)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: day == today ? Border.all(color: scheme.primary, width: 2) : null,
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Text(
                                          '$n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: color != null
                                                ? Colors.white
                                                : (future ? muted.withValues(alpha: 0.5) : scheme.onSurface),
                                          ),
                                        ),
                                        if (notes.contains(day))
                                          Positioned(
                                            bottom: 4,
                                            child: Container(
                                              width: 4,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: color != null ? Colors.white : Accent.journal,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('1', style: theme.textTheme.labelSmall?.copyWith(color: muted)),
                    const SizedBox(width: 6),
                    for (var i = 1; i <= 10; i++)
                      Container(
                        width: 14,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(color: moodColor(i), borderRadius: BorderRadius.circular(2)),
                      ),
                    const SizedBox(width: 6),
                    Text('10', style: theme.textTheme.labelSmall?.copyWith(color: muted)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Итогов дня', value: '${days.length}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(label: 'Настроение', value: avg == null ? '—' : formatNumber(avg)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(label: 'Лучший день', value: best == null ? '—' : formatDay(best.day)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: FilledButton.tonalIcon(
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(review == null ? 'Написать обзор месяца' : 'Открыть обзор месяца'),
            onPressed: () => openJournalEditor(context, kind: JournalKind.month, day: first, existing: review),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Выводы
// ---------------------------------------------------------------------------

class _Insights extends StatelessWidget {
  const _Insights({required this.entries});
  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final today = todayKey();
    final dayEntries = entries.where((e) => e.kind == JournalKind.day).toList();
    final withMood = dayEntries.where((e) => e.mood != null).toList();
    if (withMood.length < 3) {
      return ListView(
        children: const [
          EmptyHint(
            'Выводы появятся, когда будет хотя бы 3 итога дня с настроением. '
            'Отмечай теги дня: «спорт», «плохой сон», «код». Так станет видно, что поднимает настроение, а что тянет вниз.',
            icon: Icons.insights_rounded,
          ),
        ],
      );
    }
    final series = [
      for (final (d, m) in moodSeries(entries, from: addDays(today, -29), to: today))
        if (m != null) (d, m.toDouble()),
    ];
    final byWeekday = moodByWeekday(entries);
    final tags = tagMoods(entries);
    final up = tags.where((t) => t.delta >= 0.3).take(5).toList();
    final down = tags.where((t) => t.delta <= -0.3).take(5).toList();
    final energy = average([
      for (final e in dayEntries.where((e) => e.day >= addDays(today, -29)))
        if (e.energy != null) e.energy!,
    ]);
    final bestWd = () {
      double? best;
      var idx = -1;
      for (var i = 0; i < 7; i++) {
        if (byWeekday[i] != null && (best == null || byWeekday[i]! > best)) {
          best = byWeekday[i];
          idx = i;
        }
      }
      return idx;
    }();
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const SectionTitle('Настроение за 30 дней'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LineChart(points: series, color: Accent.journal, height: 160),
                if (energy != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Средняя энергия: ${formatNumber(energy)} из 5 (${_energyLabels[(energy.round() - 1).clamp(0, 4)]})',
                      style: TextStyle(color: muted),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SectionTitle('По дням недели'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BarChart(
                  bars: [for (var i = 0; i < 7; i++) (weekdayShort[i], byWeekday[i])],
                  color: Accent.journal.withValues(alpha: 0.55),
                  goodColor: Accent.journal,
                  target: average([for (final m in withMood) m.mood!]),
                  height: 130,
                ),
                if (bestWd >= 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Лучше всего обычно в ${_weekdayAcc[bestWd]}. Линия: среднее за всё время.',
                      style: TextStyle(color: muted),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SectionTitle('Что влияет на настроение'),
        if (up.isEmpty && down.isEmpty)
          const Card(child: EmptyHint('Отмечай теги в итогах дня. Когда тег встретится хотя бы дважды, здесь появится его влияние.'))
        else
          GroupCard(
            children: [
              for (final t in [...up, ...down])
                ListTile(
                  leading: ColorIcon(
                    t.delta > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 40,
                    color: t.delta > 0 ? Accent.habits : const Color(0xFFEF4444),
                  ),
                  title: Text('#${t.tag}'),
                  subtitle: Text('${_daysWord(t.days)}, в среднем ${formatNumber(t.withTag)} против ${formatNumber(t.without!)}'),
                  trailing: Text(
                    '${t.delta > 0 ? '+' : '−'}${formatNumber(t.delta.abs())}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: t.delta > 0 ? Accent.habits : const Color(0xFFEF4444)),
                  ),
                ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Это не доказательство причины, а подсказка: на что посмотреть внимательнее.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

const _weekdayAcc = ['понедельник', 'вторник', 'среду', 'четверг', 'пятницу', 'субботу', 'воскресенье'];

// ---------------------------------------------------------------------------
// Выбор настроения, энергии и тегов
// ---------------------------------------------------------------------------

/// Настроение от 1 до 10 одной строкой.
class MoodPicker extends StatelessWidget {
  const MoodPicker({super.key, required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 1; i <= 10; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => onChanged(value == i ? null : i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == i ? moodColor(i) : moodColor(i).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$i',
                    style: TextStyle(fontWeight: FontWeight.w700, color: value == i ? Colors.white : scheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EnergyPicker extends StatelessWidget {
  const _EnergyPicker({required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 1; i <= 5; i++)
          ChoiceChip(
            avatar: Icon(Icons.bolt_rounded, size: 18, color: value == i ? null : Accent.reminders),
            label: Text(_energyLabels[i - 1]),
            showCheckmark: false,
            selected: value == i,
            onSelected: (on) => onChanged(on ? i : null),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Редактор записи
// ---------------------------------------------------------------------------

class JournalEditScreen extends StatefulWidget {
  const JournalEditScreen({super.key, required this.kind, required this.day, this.existing, this.goalId});
  final JournalKind kind;
  final int day;
  final JournalEntry? existing;
  final int? goalId;

  @override
  State<JournalEditScreen> createState() => _JournalEditScreenState();
}

class _JournalEditScreenState extends State<JournalEditScreen> {
  late final _e = widget.existing;
  late final _title = TextEditingController(text: _e?.title ?? '');
  late final _body = TextEditingController(text: _e?.body ?? '');
  late final _wins = TextEditingController(text: _e?.wins ?? '');
  late final _gratitude = TextEditingController(text: _e?.gratitude ?? '');
  late final _lesson = TextEditingController(text: _e?.lesson ?? '');
  late final _focus = TextEditingController(text: _e?.focus ?? '');
  late int? _mood = _e?.mood;
  late int? _energy = _e?.energy;
  late final Set<String> _tags = parseTags(_e?.tags).toSet();
  late int _day = _e?.day ?? widget.day;
  late int? _goalId = _e?.goalId ?? widget.goalId;

  JournalKind get kind => widget.kind;

  Future<void> _save() async {
    final db = context.db;
    final companion = JournalEntriesCompanion(
      id: _e == null ? const Value.absent() : Value(_e.id),
      kind: Value(kind),
      day: Value(_day),
      mood: Value(_mood),
      energy: Value(_energy),
      tags: Value(joinTags(_tags)),
      title: Value(emptyToNull(_title.text)),
      body: Value(_body.text.trimRight()),
      wins: Value(emptyToNull(_wins.text)),
      gratitude: Value(emptyToNull(_gratitude.text)),
      lesson: Value(emptyToNull(_lesson.text)),
      focus: Value(emptyToNull(_focus.text)),
      goalId: Value(_goalId),
    );
    final empty =
        _mood == null &&
        _energy == null &&
        _tags.isEmpty &&
        [_title, _body, _wins, _gratitude, _lesson, _focus].every((c) => c.text.trim().isEmpty);
    if (_e == null && empty) {
      Navigator.pop(context);
      return;
    }
    await db.saveJournal(companion);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addTag() async {
    final c = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый тег'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'например: смена, тренировка, свидание'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Добавить')),
        ],
      ),
    );
    final t = tag?.trim().toLowerCase().replaceAll(',', ' ');
    if (t != null && t.isNotEmpty) setState(() => _tags.add(t));
  }

  Widget _field(TextEditingController c, String label, String field, {IconData? icon, int minLines = 2}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        minLines: minLines,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          hintText: journalFieldHint(kind, field),
          alignLabelWithHint: true,
          prefixIcon: icon == null ? null : Padding(padding: const EdgeInsets.only(bottom: 0), child: Icon(icon)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final f = journalFields(kind);
    final title = switch (kind) {
      JournalKind.day => 'Итог дня, ${dayLabel(_day)}',
      JournalKind.week => 'Неделя с ${formatDay(_day)}',
      JournalKind.month => 'Обзор: ${monthName(_day).toLowerCase()}',
      JournalKind.note => _e == null ? 'Новая заметка' : 'Заметка',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_e != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Удалить',
              onPressed: () async {
                if (await confirm(context, 'Удалить запись?', ok: 'Удалить', danger: true)) {
                  await db.deleteById(db.journalEntries, _e.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          IconButton(icon: const Icon(Icons.check_rounded), tooltip: 'Сохранить', onPressed: _save),
        ],
      ),
      body: Watch(
        streams: () => [db.watchAllJournal(), db.watchGoals()],
        builder: (context, v) {
          final all = v[0] as List<JournalEntry>;
          final goals = v[1] as List<Goal>;
          final suggestions = {..._tags, ...tagSuggestions(all)}.take(24).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (kind == JournalKind.week || kind == JournalKind.month) _PeriodSummary(kind: kind, day: _day),
              if (kind != JournalKind.note) ...[
                Text(_mood == null ? 'Настроение' : 'Настроение: $_mood из 10', style: theme.textTheme.titleSmall),
                const SizedBox(height: 10),
                MoodPicker(value: _mood, onChanged: (m) => setState(() => _mood = m)),
                const SizedBox(height: 18),
              ],
              if (kind == JournalKind.day) ...[
                Text('Энергия', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _EnergyPicker(value: _energy, onChanged: (e) => setState(() => _energy = e)),
                const SizedBox(height: 18),
              ],
              if (kind == JournalKind.day || kind == JournalKind.note) ...[
                Text(kind == JournalKind.day ? 'Что было сегодня' : 'Теги', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in suggestions)
                      FilterChip(
                        label: Text(t),
                        selected: _tags.contains(t),
                        onSelected: (on) => setState(() => on ? _tags.add(t) : _tags.remove(t)),
                      ),
                    ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: const Text('свой'), onPressed: _addTag),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              if (kind == JournalKind.note) ...[
                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Заголовок (необязательно)'),
                ),
                DayTile(day: _day, onChanged: (d) => setState(() => _day = d ?? _day)),
                if (goals.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    initialValue: goals.any((g) => g.id == _goalId) ? _goalId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'К цели (необязательно)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Без цели')),
                      for (final g in goals) DropdownMenuItem(value: g.id, child: Text(g.name)),
                    ],
                    onChanged: (id) => setState(() => _goalId = id),
                  ),
                const SizedBox(height: 14),
                _PromptCard(
                  day: _day,
                  onUse: (p) {
                    final sep = _body.text.trim().isEmpty ? '' : '\n\n';
                    _body.text = '${_body.text.trimRight()}$sep$p\n';
                    _body.selection = TextSelection.collapsed(offset: _body.text.length);
                  },
                ),
                const SizedBox(height: 14),
              ],
              if (f.wins != null) _field(_wins, f.wins!, 'wins', icon: Icons.emoji_events_outlined),
              if (f.gratitude != null) _field(_gratitude, f.gratitude!, 'gratitude', icon: Icons.favorite_border_rounded, minLines: 1),
              if (f.lesson != null) _field(_lesson, f.lesson!, 'lesson', icon: Icons.school_outlined, minLines: 1),
              if (f.focus != null) _field(_focus, f.focus!, 'focus', icon: Icons.center_focus_strong_outlined, minLines: 1),
              _field(_body, f.body, 'body', minLines: kind == JournalKind.note ? 8 : 3),
              if (kind == JournalKind.day)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Хватит и одного поля. Главное писать каждый день: через месяц станет видно, что делает дни лучше.',
                    style: TextStyle(color: muted, height: 1.35),
                  ),
                ),
              FilledButton(onPressed: _save, child: const Text('Сохранить')),
            ],
          );
        },
      ),
    );
  }
}

class _PromptCard extends StatefulWidget {
  const _PromptCard({required this.day, required this.onUse});
  final int day;
  final ValueChanged<String> onUse;

  @override
  State<_PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<_PromptCard> {
  late int _shift = 0;

  @override
  Widget build(BuildContext context) {
    final prompt = promptOfDay(addDays(widget.day, _shift));
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
        child: Row(
          children: [
            const Icon(Icons.psychology_alt_rounded, color: Accent.journal),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => widget.onUse(prompt),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Вопрос для размышления', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Accent.journal)),
                    const SizedBox(height: 2),
                    Text(prompt, style: const TextStyle(height: 1.35)),
                  ],
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: 'Другой вопрос', onPressed: () => setState(() => _shift++)),
          ],
        ),
      ),
    );
  }
}

/// Цифры недели или месяца над обзором: чтобы писать по фактам, а не по ощущениям.
class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({required this.kind, required this.day});
  final JournalKind kind;
  final int day;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final period = kind == JournalKind.month ? ReportPeriod.month : ReportPeriod.week;
    return FutureBuilder<WeekReport>(
      future: buildReport(db, period, day, compare: false),
      builder: (context, snap) {
        final r = snap.data;
        if (r == null) return const SizedBox(height: 8);
        final theme = Theme.of(context);
        final muted = theme.colorScheme.onSurfaceVariant;
        final facts = [
          if (r.habitsPlanned > 0) 'привычки ${r.habitsDone} из ${r.habitsPlanned}',
          if (r.workoutsPlanned > 0 || r.workoutsDone > 0) 'тренировки ${r.workoutsDone} из ${r.workoutsPlanned}',
          if (r.dayNotes > 0) 'итогов дня ${r.dayNotes}',
          if (r.moodAvg != null) 'настроение ${formatNumber(r.moodAvg!)}',
          if (r.expenses > 0) 'расходы ${formatMoney(r.expenses)}',
        ];
        final goals = r.goals.where((g) => g.delta != null && g.delta != 0).take(4).toList();
        if (facts.isEmpty && goals.isEmpty && r.wins.isEmpty) return const SizedBox(height: 8);
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Факты ${kind == JournalKind.month ? 'месяца' : 'недели'}', style: theme.textTheme.titleSmall),
                  if (facts.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(facts.join(' · '), style: TextStyle(color: muted, height: 1.4)),
                  ],
                  for (final g in goals)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${g.goal.name}: ${g.text}', style: const TextStyle(height: 1.35)),
                    ),
                  if (r.wins.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Победы из итогов дня', style: theme.textTheme.labelLarge?.copyWith(color: muted)),
                    for (final (_, w) in r.wins.take(8))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('• $w', style: const TextStyle(height: 1.3)),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
