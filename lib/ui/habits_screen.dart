import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/habit_queries.dart';
import '../data/icon_keys.dart';
import '../data/queries.dart';
import '../logic/habits.dart';
import 'charts.dart';
import 'common.dart';
import 'icons.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// Данные экрана
// ---------------------------------------------------------------------------

/// Всё по привычкам, собранное из потоков базы.
class _HabitData {
  _HabitData(this.habits, List<HabitLog> logs, List<HabitDay> days, this.hardDays, this.today) {
    for (final l in logs) {
      logsBy.putIfAbsent(l.habitId, () => {})[l.day] = l;
    }
    for (final d in days) {
      daysBy.putIfAbsent(d.habitId, () => {})[d.day] = d;
    }
    for (final h in habits) {
      marks[h.id] = HabitMarks(
        done: (logsBy[h.id] ?? const {}).keys.toSet(),
        skipped: {
          for (final d in (daysBy[h.id] ?? const <int, HabitDay>{}).values)
            if (d.skipped) d.day,
        },
      );
      plans[h.id] = planOf(h, marks[h.id]);
    }
  }

  final List<Habit> habits;
  final Set<int> hardDays;
  final int today;
  final logsBy = <int, Map<int, HabitLog>>{};
  final daysBy = <int, Map<int, HabitDay>>{};
  final marks = <int, HabitMarks>{};
  final plans = <int, HabitPlan>{};

  HabitLog? log(Habit h, int day) => logsBy[h.id]?[day];
  HabitDay? dayInfo(Habit h, int day) => daysBy[h.id]?[day];

  /// Нужно ли сделать сегодня: день по расписанию или «N раз в неделю», план которой ещё не выполнен.
  bool dueToday(Habit h) {
    final p = plans[h.id]!;
    if (p.weekly) {
      final m = marks[h.id]!;
      final monday = weekStart(today);
      return m.done.contains(today) || doneInWeek(m, monday) < weekQuota(p, m, monday);
    }
    return p.scheduled(today);
  }
}

List<Stream<Object?>> _habitStreams(AppDatabase db, {bool archived = false}) => [
  db.watchHabits(archived: archived),
  db.watchAllHabitLogs(),
  db.watchAllHabitDays(),
  db.watchHardDays(),
];

_HabitData _dataOf(List<Object?> v, int today) =>
    _HabitData(v[0] as List<Habit>, v[1] as List<HabitLog>, v[2] as List<HabitDay>, v[3] as Set<int>, today);

String _num(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

String _days(int n) => _plural(n, 'день', 'дня', 'дней');

String _weeks(int n) => _plural(n, 'неделя', 'недели', 'недель');

String _plural(int n, String one, String few, String many) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return one;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
  return many;
}

String _schedule(Habit h) =>
    h.perWeek != null ? '${h.perWeek} ${_plural(h.perWeek!, 'раз', 'раза', 'раз')} в неделю' : maskLabel(h.daysMask);

String _streakText(Habit h, int n) => h.perWeek != null ? '$n ${_weeks(n)}' : '$n ${_days(n)}';

bool _quit(Habit h) => h.kind == 1;

List<Color> _heroColors(BuildContext context) => Theme.of(context).brightness == Brightness.dark
    ? const [Color(0xFF15803D), Color(0xFF0F766E)]
    : const [Color(0xFF16A34A), Color(0xFF0D9488)];

// ---------------------------------------------------------------------------
// Главный экран
// ---------------------------------------------------------------------------

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key, this.archived = false});
  final bool archived;

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    if (widget.archived) return _ArchiveScreen(today: today);
    return ScrollFabScope(
      child: Scaffold(
        floatingActionButton: ScrollFab(
          child: FloatingActionButton(heroTag: null, onPressed: () => showAddHabit(context), child: const Icon(Icons.add_rounded)),
        ),
        body: Watch(
          deps: [today],
          streams: () => _habitStreams(db),
          builder: (context, v) {
            final data = _dataOf(v, today);
            return ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                PageHeader(
                  overline: formatDayLong(today),
                  title: 'Привычки',
                  actions: [
                    if (data.habits.length > 1)
                      IconButton(
                        tooltip: 'Порядок',
                        icon: const Icon(Icons.swap_vert_rounded),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ReorderScreen())),
                      ),
                    IconButton(
                      tooltip: 'Архив',
                      icon: const Icon(Icons.inventory_2_outlined),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitsScreen(archived: true))),
                    ),
                  ],
                ),
                if (data.habits.isEmpty)
                  EmptyHint(
                    'Привычка это небольшое регулярное действие. Начни с одной-двух и привяжи к тому, что уже делаешь каждый день: '
                    '«после утреннего чая 10 отжиманий».',
                    icon: Icons.check_circle_outline_rounded,
                    action: FilledButton.tonal(onPressed: () => showAddHabit(context), child: const Text('Выбрать привычку')),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Сегодня')),
                        ButtonSegment(value: 1, label: Text('Неделя')),
                        ButtonSegment(value: 2, label: Text('Итоги')),
                      ],
                      selected: {_tab},
                      onSelectionChanged: (s) => setState(() => _tab = s.first),
                    ),
                  ),
                  ...switch (_tab) {
                    0 => _todayView(context, data),
                    1 => _weekView(context, data),
                    _ => _statsView(context, data),
                  },
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _todayView(BuildContext context, _HabitData data) {
    final due = data.habits.where(data.dueToday).toList();
    final rest = data.habits.where((h) => !data.dueToday(h)).toList();
    final done = due.where((h) => data.log(h, data.today) != null).length;
    final strength = data.habits.isEmpty
        ? 0.0
        : data.habits.map((h) => habitStrength(data.plans[h.id]!, data.marks[h.id]!, data.today)).reduce((a, b) => a + b) /
              data.habits.length;
    final hard = data.hardDays.contains(data.today);
    return [
      HeroCard(
        colors: _heroColors(context),
        child: Row(
          children: [
            ProgressRing(
              value: due.isEmpty ? 1 : done / due.length,
              size: 84,
              stroke: 9,
              color: Colors.white,
              trackColor: Colors.white24,
              child: Text('$done/${due.length}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    due.isEmpty
                        ? 'Сегодня ничего не запланировано'
                        : done == due.length
                        ? 'Всё на сегодня сделано'
                        : 'Осталось ${due.length - done}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hard ? 'Тяжёлый день: хватит и минимума' : 'Средняя сила привычек ${(strength * 100).round()}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      for (final part in const [1, 2, 3, 0])
        if (due.any((h) => h.partOfDay == part)) ...[
          SectionTitle(partsOfDay[part]),
          for (final h in due.where((h) => h.partOfDay == part)) _HabitTile(habit: h, data: data, hard: hard),
        ],
      if (rest.isNotEmpty) ...[
        const SectionTitle('Сегодня по плану отдых'),
        for (final h in rest) _HabitTile(habit: h, data: data, hard: hard, dimmed: true),
      ],
    ];
  }

  List<Widget> _weekView(BuildContext context, _HabitData data) {
    final monday = weekStart(data.today);
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Text(
          'Нажми на день, чтобы отметить. Долгое нажатие: пропуск, минимум, заметка.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      for (final h in data.habits) _WeekCard(habit: h, data: data, monday: monday),
    ];
  }

  List<Widget> _statsView(BuildContext context, _HabitData data) {
    final today = data.today;
    final from = addDays(today, -29);
    var planned = 0, done = 0;
    for (final h in data.habits) {
      final r = habitRate(data.plans[h.id]!, data.marks[h.id]!, from: from, to: today);
      planned += r.planned;
      done += r.done;
    }
    // Идеальные дни: всё запланированное сделано.
    var perfect = 0;
    final dayShare = <int, double>{};
    for (var d = addDays(today, -7 * 16 + 1); d <= today; d = addDays(d, 1)) {
      var p = 0, ok = 0;
      for (final h in data.habits) {
        final plan = data.plans[h.id]!, m = data.marks[h.id]!;
        if (plan.firstDay != null && d < plan.firstDay!) continue;
        if (plan.weekly || m.skipped.contains(d) || !plan.scheduled(d)) continue;
        p++;
        if (m.done.contains(d)) ok++;
      }
      // Привычки «N раз в неделю» добавляют к дню только сделанное.
      for (final h in data.habits.where((h) => data.plans[h.id]!.weekly)) {
        if (data.marks[h.id]!.done.contains(d)) {
          p++;
          ok++;
        }
      }
      if (p > 0) {
        dayShare[d] = ok / p;
        if (d >= from && ok == p) perfect++;
      }
    }
    final weekday = List<double>.filled(7, 0), weekdayN = List<int>.filled(7, 0);
    for (final h in data.habits) {
      final r = weekdayRates(data.plans[h.id]!, data.marks[h.id]!, from: addDays(today, -55), to: today);
      for (var i = 0; i < 7; i++) {
        if (r[i] != null) {
          weekday[i] += r[i]!;
          weekdayN[i]++;
        }
      }
    }
    final rates = [for (var i = 0; i < 7; i++) weekdayN[i] == 0 ? null : weekday[i] / weekdayN[i]];
    final known = [
      for (var i = 0; i < 7; i++)
        if (rates[i] != null) i,
    ];
    int? best, worst;
    for (final i in known) {
      if (best == null || rates[i]! > rates[best]!) best = i;
      if (worst == null || rates[i]! < rates[worst]!) worst = i;
    }
    final ranked = [...data.habits]
      ..sort(
        (a, b) => habitStrength(
          data.plans[b.id]!,
          data.marks[b.id]!,
          today,
        ).compareTo(habitStrength(data.plans[a.id]!, data.marks[a.id]!, today)),
      );
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            children: [
              _Stat(label: 'за 30 дней', value: planned == 0 ? '—' : '${(100 * done / planned).round()}%', color: Accent.habits),
              _Stat(label: 'идеальных дней', value: '$perfect'),
              _Stat(label: 'отметок', value: '$done'),
            ],
          ),
        ),
      ),
      const SectionTitle('16 недель'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShareGrid(today: today, weeks: 16, share: (d) => dayShare[d]),
              const SizedBox(height: 10),
              Text('Чем ярче день, тем больше привычек выполнено', style: TextStyle(color: muted, fontSize: 12)),
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
                bars: [for (var i = 0; i < 7; i++) (weekdayShort[i], rates[i] == null ? null : rates[i]! * 100)],
                target: 80,
                color: Accent.habits.withValues(alpha: 0.35),
                goodColor: Accent.habits,
                height: 130,
              ),
              if (best != null && worst != null && best != worst) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Лучше всего получается в ${_weekdayIn[best]}, хуже всего в ${_weekdayIn[worst]}. '
                    'На слабый день поставь привычки попроще или задай минимум.',
                    style: TextStyle(color: muted, height: 1.35),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      const SectionTitle('Сила привычек'),
      GroupCard(
        children: [
          for (final h in ranked)
            Builder(
              builder: (context) {
                final s = habitStrength(data.plans[h.id]!, data.marks[h.id]!, today);
                return ListTile(
                  leading: ItemIcon(h.icon, size: 40),
                  title: Text(h.name),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ProgressLine(value: s, color: Accent.habits, height: 6),
                  ),
                  trailing: Text('${(s * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: h.id))),
                );
              },
            ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Text(
          'Сила растёт с каждой отметкой и медленно падает при пропусках, поэтому один пропуск не обнуляет работу. '
          'В исследовании Lally (2010) на автоматизм уходило в среднем 66 дней.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.35),
        ),
      ),
    ];
  }
}

const _weekdayIn = ['понедельник', 'вторник', 'среду', 'четверг', 'пятницу', 'субботу', 'воскресенье'];

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Сетка дней с яркостью по доле выполненного.
class _ShareGrid extends StatelessWidget {
  const _ShareGrid({required this.today, required this.weeks, required this.share});
  final int today;
  final int weeks;
  final double? Function(int day) share;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = addDays(weekStart(today), -7 * (weeks - 1));
    return LayoutBuilder(
      builder: (context, c) {
        final cell = ((c.maxWidth - 24) / weeks - 3).clamp(4.0, 28.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                for (var d = 0; d < 7; d++)
                  SizedBox(
                    height: cell + 3,
                    width: 22,
                    child: Text(d.isEven ? weekdayShort[d] : '', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                  ),
              ],
            ),
            for (var w = 0; w < weeks; w++)
              Column(
                children: [
                  for (var d = 0; d < 7; d++)
                    Builder(
                      builder: (context) {
                        final day = addDays(start, w * 7 + d);
                        final s = day > today ? null : share(day);
                        return Container(
                          width: cell,
                          height: cell,
                          margin: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: day > today
                                ? Colors.transparent
                                : s == null || s == 0
                                ? scheme.surfaceContainerHighest
                                : Accent.habits.withValues(alpha: 0.25 + 0.75 * s),
                            borderRadius: BorderRadius.circular(4),
                            border: day == today ? Border.all(color: scheme.primary, width: 1.5) : null,
                          ),
                        );
                      },
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Строка привычки на сегодня
// ---------------------------------------------------------------------------

class _HabitTile extends StatelessWidget {
  const _HabitTile({required this.habit, required this.data, required this.hard, this.dimmed = false});
  final Habit habit;
  final _HabitData data;
  final bool hard;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final h = habit;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = data.today;
    final log = data.log(h, today);
    final info = data.dayInfo(h, today);
    final plan = data.plans[h.id]!, marks = data.marks[h.id]!;
    final streak = habitStreak(plan, marks, today);
    final done = log != null;
    final skipped = info?.skipped ?? false;
    final missed = missedLastTime(plan, marks, today);
    final value = info?.value ?? 0;
    final monday = weekStart(today);

    final lines = <String>[
      if (h.target != null) '${_num(value)} из ${_num(h.target!)}${h.unit == null ? '' : ' ${h.unit}'}',
      if (plan.weekly) '${doneInWeek(marks, monday)} из ${weekQuota(plan, marks, monday)} на этой неделе',
      if (hard && h.minimumText != null && !done) 'Минимум: ${h.minimumText}' else if (h.cue != null && !done) 'После того как ${h.cue}',
    ];

    Widget trailing;
    if (h.target != null && !done && !skipped) {
      trailing = _CountButton(
        value: value,
        target: h.target!,
        onTap: () {
          HapticFeedback.lightImpact();
          context.db.setHabitValue(h, today, value + _step(h.target!));
        },
      );
    } else {
      trailing = GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (skipped) {
            context.db.setHabitSkipped(h.id, today, false);
          } else {
            context.db.toggleHabit(h, today, done: !done, minimum: !done && hard && h.minimumText != null);
          }
        },
        child: skipped
            ? Icon(Icons.redo_rounded, color: scheme.onSurfaceVariant, size: 30)
            : CheckDot(checked: done, half: done && log.minimum, color: Accent.habits),
      );
    }

    return Opacity(
      opacity: dimmed && !done ? 0.6 : 1,
      child: Card(
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: h.id))),
          onLongPress: () => showHabitDaySheet(context, h, today),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                ItemIcon(h.icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: done && !_quit(h) ? TextDecoration.lineThrough : null,
                          decorationColor: scheme.onSurfaceVariant,
                        ),
                      ),
                      for (final l in lines)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            l,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      if (h.target != null && !done && !skipped)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 8),
                          child: ProgressLine(value: (value / h.target!).clamp(0, 1).toDouble(), color: Accent.habits, height: 5),
                        ),
                      if (streak > 0 || skipped || missed || (done && log.minimum))
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (streak > 0)
                                Pill(
                                  _quit(h) ? '${_streakText(h, streak)} чисто' : _streakText(h, streak),
                                  icon: Icons.local_fire_department_rounded,
                                  color: Accent.workouts,
                                ),
                              if (done && log.minimum) const Pill('минимум', color: Accent.reminders),
                              if (skipped) const Pill('пропуск по причине'),
                              if (missed && !skipped) Pill('не пропускай дважды', icon: Icons.priority_high_rounded, color: scheme.error),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Шаг кнопки «+» у привычки-количества.
double _step(double target) => target >= 1000 ? 250 : (target >= 100 ? 10 : 1);

class _CountButton extends StatelessWidget {
  const _CountButton({required this.value, required this.target, required this.onTap});
  final double value;
  final double target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ProgressRing(value: (value / target).clamp(0, 1).toDouble(), size: 46, stroke: 4, color: Accent.habits),
          IconButton(
            tooltip: '+${_num(_step(target))}',
            onPressed: onTap,
            icon: const Icon(Icons.add_rounded, color: Accent.habits),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Неделя
// ---------------------------------------------------------------------------

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.habit, required this.data, required this.monday});
  final Habit habit;
  final _HabitData data;
  final int monday;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final h = habit;
    final today = data.today;
    final plan = data.plans[h.id]!, marks = data.marks[h.id]!;
    final streak = habitStreak(plan, marks, today);
    final month = habitRate(plan, marks, from: addDays(today, -29), to: today);
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: h.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ItemIcon(h.icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          [
                            _schedule(h),
                            if (plan.weekly) '${doneInWeek(marks, monday)} из ${weekQuota(plan, marks, monday)}',
                            if (month.planned > 0) '${(100 * month.done / month.planned).round()}% за 30 дней',
                          ].join(' · '),
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (streak > 0) Pill('$streak', icon: Icons.local_fire_department_rounded, color: Accent.workouts),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final day = addDays(monday, i);
                          final log = data.log(h, day);
                          final isDone = log != null;
                          final skipped = marks.skipped.contains(day);
                          final planned = plan.scheduled(day) && !plan.weekly;
                          final future = day > today;
                          final isToday = day == today;
                          final bg = isDone
                              ? (log.minimum ? Accent.habits.withValues(alpha: 0.55) : Accent.habits)
                              : planned
                              ? scheme.surfaceContainerHighest
                              : scheme.surfaceContainerHighest.withValues(alpha: plan.weekly ? 0.8 : 0.4);
                          return GestureDetector(
                            onTap: future ? null : () => db.toggleHabit(h, day, done: !isDone),
                            onLongPress: future ? null : () => showHabitDaySheet(context, h, day),
                            child: Column(
                              children: [
                                Text(
                                  weekdayShort[i],
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isToday ? scheme.onSurface : scheme.onSurfaceVariant,
                                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 34,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: future && !isDone ? Colors.transparent : bg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: isToday && !isDone
                                        ? Border.all(color: Accent.habits, width: 2)
                                        : future
                                        ? Border.all(color: scheme.outlineVariant)
                                        : null,
                                  ),
                                  child: isDone
                                      ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                                      : skipped
                                      ? Icon(Icons.redo_rounded, size: 18, color: scheme.onSurfaceVariant)
                                      : null,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// День привычки: сделано, минимум, пропуск, количество, заметка
// ---------------------------------------------------------------------------

Future<void> showHabitDaySheet(BuildContext context, Habit habit, int day) async {
  final db = context.db;
  final log = await db.habitLogOn(habit.id, day);
  final info = await db.habitDayOn(habit.id, day);
  if (!context.mounted) return;
  await showFormSheet(context, (_) => _DayForm(habit: habit, day: day, log: log, info: info));
}

class _DayForm extends StatefulWidget {
  const _DayForm({required this.habit, required this.day, this.log, this.info});
  final Habit habit;
  final int day;
  final HabitLog? log;
  final HabitDay? info;

  @override
  State<_DayForm> createState() => _DayFormState();
}

class _DayFormState extends State<_DayForm> {
  late final _note = TextEditingController(text: widget.info?.note ?? '');
  late final _value = TextEditingController(text: widget.info?.value == null ? '' : _num(widget.info!.value!));

  Future<void> _done(Future<void> Function() action) async {
    final db = context.db;
    final h = widget.habit;
    final nav = Navigator.of(context);
    await action();
    if (h.target != null && _value.text.trim().isNotEmpty) {
      final v = double.tryParse(_value.text.replaceAll(',', '.').trim());
      if (v != null) await db.setHabitValue(h, widget.day, v);
    }
    await db.setHabitNote(h.id, widget.day, _note.text);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final h = widget.habit;
    final day = widget.day;
    final log = widget.log;
    final done = log != null;
    final skipped = widget.info?.skipped ?? false;
    final theme = Theme.of(context);
    Widget option(IconData icon, String title, String? subtitle, bool selected, Future<void> Function() onTap) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: selected ? Accent.habits : null),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: selected ? const Icon(Icons.check_rounded, color: Accent.habits) : null,
      onTap: () => _done(onTap),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(h.name, style: theme.textTheme.titleLarge),
        Text(
          dayLabel(day, today: todayKey()),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (h.target != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Сколько сделано', suffixText: 'из ${_num(h.target!)} ${h.unit ?? ''}'.trim()),
            ),
          ),
        option(
          Icons.check_circle_rounded,
          _quit(h) ? 'Держался' : 'Сделано полностью',
          null,
          done && !log.minimum,
          () => db.toggleHabit(h, day, done: true),
        ),
        if (h.minimumText != null || !_quit(h))
          option(
            Icons.contrast_rounded,
            'Сделан минимум',
            h.minimumText ?? 'Меньше обычного, но цепочка не рвётся',
            done && log.minimum,
            () => db.toggleHabit(h, day, done: true, minimum: true),
          ),
        option(
          Icons.redo_rounded,
          'Пропуск по причине',
          'Болезнь, дорога: серия не прервётся',
          skipped,
          () => db.setHabitSkipped(h.id, day, true),
        ),
        option(
          Icons.radio_button_unchecked_rounded,
          _quit(h) ? 'Сорвался' : 'Не сделано',
          _quit(h) ? 'Ничего страшного: важен следующий день' : null,
          !done && !skipped,
          () async {
            await db.setHabitSkipped(h.id, day, false);
            await db.toggleHabit(h, day, done: false);
          },
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Заметка о дне', hintText: 'Что помогло или помешало'),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: () => _done(() async {}), child: const Text('Сохранить')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Карточка привычки
// ---------------------------------------------------------------------------

class HabitDetailScreen extends StatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});
  final int habitId;

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late int _month = () {
    final d = DateTime.now();
    return d.year * 12 + d.month - 1;
  }();

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    return Watch(
      deps: [widget.habitId],
      streams: () => [
        (db.select(db.habits)..where((t) => t.id.equals(widget.habitId))).watchSingleOrNull(),
        db.watchLogsOfHabit(widget.habitId),
        db.watchHabitDaysOf(widget.habitId),
      ],
      builder: (context, v) {
        final h = v[0] as Habit?;
        if (h == null) return const Scaffold(body: Center(child: Text('Привычка удалена')));
        final logs = v[1] as List<HabitLog>;
        final days = v[2] as List<HabitDay>;
        final byDay = {for (final l in logs) l.day: l};
        final infoBy = {for (final d in days) d.day: d};
        final marks = marksOf(h.id, logs, days);
        final plan = planOf(h, marks);
        final streak = habitStreak(plan, marks, today);
        final best = bestStreak(plan, marks, today);
        final strength = habitStrength(plan, marks, today);
        final m30 = habitRate(plan, marks, from: addDays(today, -29), to: today);
        final series = strengthSeries(plan, marks, from: addDays(today, -89), to: today);
        final age = habitAgeDays(plan.firstDay ?? today, today);
        final rates = weekdayRates(plan, marks, from: addDays(today, -83), to: today);
        final notes = days.where((d) => d.note != null).toList()..sort((a, b) => b.day.compareTo(a.day));
        final theme = Theme.of(context);
        final muted = theme.colorScheme.onSurfaceVariant;
        return Scaffold(
          appBar: AppBar(
            title: Text(h.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Изменить',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HabitEditScreen(habit: h))),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              HeroCard(
                colors: _heroColors(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProgressRing(
                          value: strength,
                          size: 76,
                          stroke: 8,
                          color: Colors.white,
                          trackColor: Colors.white24,
                          child: Text('${(strength * 100).round()}%', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Сила привычки: ${strengthLabel(strength)}',
                                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  _schedule(h),
                                  if (h.target != null) '${_num(h.target!)} ${h.unit ?? ''}'.trim(),
                                  if (h.reminderMinutes != null) 'в ${formatMinutes(h.reminderMinutes!)}',
                                ].join(' · '),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (h.cue != null || h.why != null || h.minimumText != null) ...[
                      const SizedBox(height: 14),
                      if (h.cue != null)
                        _HeroLine(Icons.link_rounded, 'После того как ${h.cue}, ${_quit(h) ? 'не ' : ''}${h.name.toLowerCase()}'),
                      if (h.why != null) _HeroLine(Icons.favorite_rounded, h.why!),
                      if (h.minimumText != null) _HeroLine(Icons.contrast_rounded, 'Минимум: ${h.minimumText}'),
                    ],
                  ],
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    children: [
                      _Stat(label: _quit(h) ? 'чисто сейчас' : 'серия', value: '$streak', color: Accent.workouts),
                      _Stat(label: 'лучшая', value: '$best'),
                      _Stat(
                        label: 'за 30 дней',
                        value: m30.planned == 0 ? '—' : '${(100 * m30.done / m30.planned).round()}%',
                        color: Accent.habits,
                      ),
                      _Stat(label: 'всего', value: '${logs.length}'),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Путь к автоматизму', style: theme.textTheme.titleSmall)),
                          Text(
                            age >= habitFormationDays ? '$age ${_days(age)}' : 'день $age из ~$habitFormationDays',
                            style: TextStyle(color: muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ProgressLine(value: (age / habitFormationDays).clamp(0, 1).toDouble(), color: Accent.habits, height: 8),
                      const SizedBox(height: 8),
                      Text(
                        age >= habitFormationDays ? 'Средний срок пройден. Дальше привычка держится сама, если не бросать надолго.' : 'В среднем привычка становится автоматической за 66 дней (от 18 до 254). Один пропуск почти не мешает, главное не пропускать дважды.',
                        style: TextStyle(color: muted, fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
              const SectionTitle('Календарь'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                  child: _MonthCalendar(
                    month: _month,
                    today: today,
                    onMonth: (m) => setState(() => _month = m),
                    cell: (day) {
                      final log = byDay[day];
                      return (
                        done: log != null,
                        minimum: log?.minimum ?? false,
                        skipped: infoBy[day]?.skipped ?? false,
                        planned: plan.scheduled(day) && !plan.weekly,
                        note: infoBy[day]?.note != null,
                      );
                    },
                    onTap: (d) => db.toggleHabit(h, d, done: !byDay.containsKey(d)),
                    onLongPress: (d) => showHabitDaySheet(context, h, d),
                  ),
                ),
              ),
              if (h.target != null) ...[
                const SectionTitle('Последние 2 недели'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                    child: BarChart(
                      bars: [
                        for (var i = 13; i >= 0; i--)
                          (
                            weekdayShort[dayFromKey(addDays(today, -i)).weekday - 1].substring(0, 1),
                            infoBy[addDays(today, -i)]?.value ?? (byDay.containsKey(addDays(today, -i)) ? h.target : null),
                          ),
                      ],
                      target: h.target,
                      color: Accent.habits.withValues(alpha: 0.35),
                      goodColor: Accent.habits,
                    ),
                  ),
                ),
              ],
              const SectionTitle('Сила за 90 дней'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: LineChart(
                    points: [for (var i = 0; i < series.length; i++) (addDays(today, -series.length + 1 + i), series[i] * 100)],
                    color: Accent.habits,
                    height: 160,
                  ),
                ),
              ),
              if (!plan.weekly && rates.whereType<double>().length > 1) ...[
                const SectionTitle('По дням недели'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                    child: BarChart(
                      bars: [for (var i = 0; i < 7; i++) (weekdayShort[i], rates[i] == null ? null : rates[i]! * 100)],
                      target: 80,
                      color: Accent.habits.withValues(alpha: 0.35),
                      goodColor: Accent.habits,
                      height: 120,
                    ),
                  ),
                ),
              ],
              if (notes.isNotEmpty) ...[
                const SectionTitle('Заметки'),
                GroupCard(
                  children: [
                    for (final n in notes.take(10))
                      ListTile(
                        title: Text(n.note!),
                        subtitle: Text(dayLabel(n.day, today: today)),
                        onTap: () => showHabitDaySheet(context, h, n.day),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HeroLine extends StatelessWidget {
  const _HeroLine(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

typedef _Cell = ({bool done, bool minimum, bool skipped, bool planned, bool note});

/// Календарь месяца с отметками.
class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.today,
    required this.onMonth,
    required this.cell,
    required this.onTap,
    required this.onLongPress,
  });

  /// Месяц как год * 12 + (месяц - 1).
  final int month;
  final int today;
  final ValueChanged<int> onMonth;
  final _Cell Function(int day) cell;
  final ValueChanged<int> onTap;
  final ValueChanged<int> onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final year = month ~/ 12, m = month % 12 + 1;
    final first = DateTime(year, m, 1);
    final daysIn = DateTime(year, m + 1, 0).day;
    final offset = first.weekday - 1;
    final now = DateTime.now();
    final isCurrent = year == now.year && m == now.month;
    final rows = ((offset + daysIn) / 7).ceil();
    return Column(
      children: [
        Row(
          children: [
            IconButton(onPressed: () => onMonth(month - 1), icon: const Icon(Icons.chevron_left_rounded)),
            Expanded(
              child: Text(monthTitle(year, m), textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
            ),
            IconButton(onPressed: isCurrent ? null : () => onMonth(month + 1), icon: const Icon(Icons.chevron_right_rounded)),
          ],
        ),
        Row(
          children: [
            for (final w in weekdayShort)
              Expanded(
                child: Center(
                  child: Text(w, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final n = r * 7 + c - offset + 1;
                      if (n < 1 || n > daysIn) return const SizedBox(height: 42);
                      final day = year * 10000 + m * 100 + n;
                      final future = day > today;
                      final s = cell(day);
                      final bg = s.done
                          ? (s.minimum ? Accent.habits.withValues(alpha: 0.5) : Accent.habits)
                          : s.planned && !future
                          ? scheme.surfaceContainerHighest
                          : Colors.transparent;
                      return GestureDetector(
                        onTap: future ? null : () => onTap(day),
                        onLongPress: future ? null : () => onLongPress(day),
                        child: Container(
                          height: 38,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: bg,
                            shape: BoxShape.circle,
                            border: day == today ? Border.all(color: Accent.habits, width: 2) : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              s.skipped
                                  ? Icon(Icons.redo_rounded, size: 16, color: scheme.onSurfaceVariant)
                                  : Text(
                                      '$n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: s.done ? Colors.white : (future ? scheme.outline : scheme.onSurface),
                                      ),
                                    ),
                              if (s.note)
                                Positioned(
                                  bottom: 4,
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(color: s.done ? Colors.white : Accent.habits, shape: BoxShape.circle),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Архив и порядок
// ---------------------------------------------------------------------------

class _ArchiveScreen extends StatelessWidget {
  const _ArchiveScreen({required this.today});
  final int today;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Scaffold(
      appBar: AppBar(title: const Text('Привычки в архиве')),
      body: Watch(
        streams: () => _habitStreams(db, archived: true),
        builder: (context, v) {
          final data = _dataOf(v, today);
          if (data.habits.isEmpty) return const EmptyHint('В архиве пусто.', icon: Icons.inventory_2_outlined);
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: [for (final h in data.habits) _WeekCard(habit: h, data: data, monday: weekStart(today))],
          );
        },
      ),
    );
  }
}

class _ReorderScreen extends StatelessWidget {
  const _ReorderScreen();

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Scaffold(
      appBar: AppBar(title: const Text('Порядок привычек')),
      body: StreamBuilder<List<Habit>>(
        stream: db.watchHabits(),
        builder: (context, snap) {
          final habits = snap.data ?? const <Habit>[];
          return ReorderableListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            onReorderItem: (from, to) {
              final ids = [for (final h in habits) h.id];
              final id = ids.removeAt(from);
              ids.insert(to, id);
              db.reorderHabits(ids);
            },
            children: [
              for (final h in habits)
                ListTile(
                  key: ValueKey(h.id),
                  leading: ItemIcon(h.icon, size: 40),
                  title: Text(h.name),
                  subtitle: Text('${partsOfDay[h.partOfDay]} · ${_schedule(h)}'),
                  trailing: const Icon(Icons.drag_handle_rounded),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Новая привычка: идеи
// ---------------------------------------------------------------------------

/// Готовая идея привычки с якорем и минимумом.
class HabitIdea {
  const HabitIdea(this.name, this.icon, {this.part = 0, this.cue, this.minimum, this.target, this.unit, this.kind = 0, this.why});
  final String name;
  final String icon;
  final int part;
  final String? cue;
  final String? minimum;
  final double? target;
  final String? unit;
  final int kind;
  final String? why;
}

const habitIdeas = [
  HabitIdea('Стакан воды утром', 'water', part: 1, cue: 'проснусь', why: 'Проснуться и начать день с простого дела'),
  HabitIdea('Отжимания', 'fitness', part: 1, cue: 'почищу зубы утром', target: 30, unit: 'раз', minimum: '5 отжиманий'),
  HabitIdea('Вода', 'water', target: 8, unit: 'стаканов', minimum: '4 стакана'),
  HabitIdea('Программирование', 'code', part: 3, cue: 'поужинаю', minimum: '20 минут кода', why: 'Вернуться в IT'),
  HabitIdea('Чтение', 'book', part: 3, cue: 'лягу в кровать', target: 20, unit: 'страниц', minimum: '1 страница'),
  HabitIdea('Прогулка', 'run', part: 2, target: 8000, unit: 'шагов', minimum: '10 минут на улице'),
  HabitIdea('Растяжка', 'yoga', part: 3, cue: 'выключу компьютер', minimum: '2 минуты'),
  HabitIdea('План на завтра', 'note', part: 3, cue: 'закончу ужин', minimum: 'Одна главная задача'),
  HabitIdea('Английский', 'school', cue: 'сяду в автобус', target: 15, unit: 'минут', minimum: '5 слов'),
  HabitIdea('Без телефона в кровати', 'phone', part: 3, kind: 1, cue: 'лягу спать', why: 'Засыпать быстрее и высыпаться'),
  HabitIdea('Без сладкого', 'fastfood', kind: 1, why: 'Меньше скачков энергии'),
  HabitIdea('Без энергетиков', 'coffee', kind: 1, why: 'Нормальный сон и пульс'),
  HabitIdea('Медитация', 'brain', part: 1, cue: 'выпью кофе', target: 10, unit: 'минут', minimum: '1 минута дыхания'),
];

Future<void> showAddHabit(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (sheet, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text('Новая привычка', style: Theme.of(sheet).textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Начни с маленького шага и привяжи его к тому, что уже делаешь. Всё можно поменять перед сохранением.',
              style: TextStyle(color: Theme.of(sheet).colorScheme.onSurfaceVariant),
            ),
          ),
          ListTile(
            leading: const ColorIcon(Icons.edit_rounded, color: Accent.habits, size: 40),
            title: const Text('Своя привычка'),
            onTap: () {
              Navigator.pop(sheet);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitEditScreen()));
            },
          ),
          const Divider(),
          for (final idea in habitIdeas)
            ListTile(
              leading: ItemIcon(idea.icon, size: 40),
              title: Text(idea.name),
              subtitle: Text(
                [
                  if (idea.kind == 1) 'бросить',
                  if (idea.target != null) '${_num(idea.target!)} ${idea.unit}',
                  if (idea.cue != null) 'после того как ${idea.cue}',
                ].join(' · '),
              ),
              onTap: () {
                Navigator.pop(sheet);
                Navigator.push(context, MaterialPageRoute(builder: (_) => HabitEditScreen(idea: idea)));
              },
            ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Редактирование
// ---------------------------------------------------------------------------

class HabitEditScreen extends StatefulWidget {
  const HabitEditScreen({super.key, this.habit, this.idea});
  final Habit? habit;
  final HabitIdea? idea;

  @override
  State<HabitEditScreen> createState() => _HabitEditScreenState();
}

class _HabitEditScreenState extends State<HabitEditScreen> {
  late final _name = TextEditingController(text: widget.habit?.name ?? widget.idea?.name ?? '');
  late String _icon = iconKeyFor(widget.habit?.icon ?? widget.idea?.icon) ?? 'check';
  late final _minimum = TextEditingController(text: widget.habit?.minimumText ?? widget.idea?.minimum ?? '');
  late final _cue = TextEditingController(text: widget.habit?.cue ?? widget.idea?.cue ?? '');
  late final _why = TextEditingController(text: widget.habit?.why ?? widget.idea?.why ?? '');
  late final _target = TextEditingController(
    text: (widget.habit?.target ?? widget.idea?.target) == null ? '' : _num((widget.habit?.target ?? widget.idea?.target)!),
  );
  late final _unit = TextEditingController(text: widget.habit?.unit ?? widget.idea?.unit ?? '');
  late int _kind = widget.habit?.kind ?? widget.idea?.kind ?? 0;
  late bool _counted = (widget.habit?.target ?? widget.idea?.target) != null;
  late int _mask = widget.habit?.daysMask ?? everyDay;
  late int? _perWeek = widget.habit?.perWeek;
  late int _part = widget.habit?.partOfDay ?? widget.idea?.part ?? 0;
  late int? _reminder = widget.habit?.reminderMinutes;
  late int? _trackerId = widget.habit?.trackerId;

  bool get _isNew => widget.habit == null;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return showSnack(context, 'Введи название');
    if (_perWeek == null && _mask == 0) return showSnack(context, 'Выбери хотя бы один день');
    double? target;
    if (_counted && _kind == 0) {
      target = double.tryParse(_target.text.replaceAll(',', '.').trim());
      if (target == null || target <= 0) return showSnack(context, 'Укажи цель в день, например 8');
    }
    await context.db.saveHabit(
      HabitsCompanion(
        id: _isNew ? const Value.absent() : Value(widget.habit!.id),
        name: Value(name),
        icon: Value(_icon),
        daysMask: Value(_perWeek == null ? _mask : everyDay),
        perWeek: Value(_perWeek),
        reminderMinutes: Value(_reminder),
        minimumText: Value(emptyToNull(_minimum.text)),
        trackerId: Value(_trackerId),
        kind: Value(_kind),
        target: Value(target),
        unit: Value(target == null ? null : emptyToNull(_unit.text)),
        partOfDay: Value(_part),
        cue: Value(emptyToNull(_cue.text)),
        why: Value(emptyToNull(_why.text)),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final h = widget.habit;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: theme.textTheme.titleSmall),
    );
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Новая привычка' : 'Привычка')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconField(value: _icon, onChanged: (v) => setState(() => _icon = v)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  autofocus: _isNew && widget.idea == null,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
              ),
            ],
          ),
          label('Что делаем'),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('Делать'), icon: Icon(Icons.add_task_rounded)),
              ButtonSegment(value: 1, label: Text('Бросить'), icon: Icon(Icons.block_rounded)),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          if (_kind == 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Каждый день без срыва отмечай как сделанный. Серия покажет, сколько дней ты держишься.',
                style: TextStyle(color: muted),
              ),
            ),
          if (_kind == 0) ...[
            label('Как отмечать'),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Галочкой')),
                ButtonSegment(value: true, label: Text('Количеством')),
              ],
              selected: {_counted},
              onSelectionChanged: (s) => setState(() => _counted = s.first),
            ),
            if (_counted)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _target,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Цель в день'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _unit,
                        decoration: const InputDecoration(labelText: 'Единица', hintText: 'стаканов, страниц'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          label('Как часто'),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('По дням')),
              ButtonSegment(value: true, label: Text('Раз в неделю')),
            ],
            selected: {_perWeek != null},
            onSelectionChanged: (s) => setState(() => _perWeek = s.first ? 3 : null),
          ),
          const SizedBox(height: 12),
          if (_perWeek == null)
            DaysPicker(mask: _mask, onChanged: (m) => setState(() => _mask = m))
          else
            Wrap(
              spacing: 8,
              children: [
                for (var n = 1; n <= 6; n++)
                  ChoiceChip(
                    showCheckmark: false,
                    label: Text('$n'),
                    selected: _perWeek == n,
                    onSelected: (_) => setState(() => _perWeek = n),
                  ),
              ],
            ),
          if (_perWeek != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('В любые дни недели: удобно для спорта и дел без жёсткого расписания', style: TextStyle(color: muted)),
            ),
          label('Время дня'),
          Wrap(
            spacing: 8,
            children: [
              for (final p in const [1, 2, 3, 0])
                ChoiceChip(
                  showCheckmark: false,
                  label: Text(partsOfDay[p]),
                  selected: _part == p,
                  onSelected: (_) => setState(() => _part = p),
                ),
            ],
          ),
          label('Якорь и смысл'),
          TextField(
            controller: _cue,
            decoration: const InputDecoration(
              labelText: 'После того как…',
              hintText: 'выпью утренний чай',
              helperText: 'Привязка к уже привычному делу заметно повышает шанс не забыть',
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _why,
            decoration: const InputDecoration(labelText: 'Зачем это мне', hintText: 'Например: вернуться в IT'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minimum,
            decoration: const InputDecoration(labelText: 'Минимум в тяжёлый день', hintText: 'Например: 20 минут кода'),
          ),
          const SizedBox(height: 8),
          ReminderTile(minutes: _reminder, onChanged: (m) => setState(() => _reminder = m)),
          const SizedBox(height: 8),
          StreamBuilder<List<Tracker>>(
            stream: db.watchTrackers(),
            builder: (context, snap) {
              final trackers = snap.data ?? const <Tracker>[];
              final exists = trackers.any((t) => t.id == _trackerId);
              return DropdownButtonFormField<int?>(
                initialValue: exists ? _trackerId : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Отмечать саму по трекеру',
                  helperText: 'Например, «Код» отметится, когда запишешь время в трекер «Время кода»',
                  helperMaxLines: 2,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Нет, отмечаю сам')),
                  for (final t in trackers) DropdownMenuItem(value: t.id, child: Text(t.name)),
                ],
                onChanged: (v) => setState(() => _trackerId = v),
              );
            },
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Сохранить')),
          if (h != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: Icon(h.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
              label: Text(h.archived ? 'Вернуть из архива' : 'В архив'),
              onPressed: () async {
                await db.setArchived(db.habits, h.id, !h.archived);
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Удалить вместе с отметками'),
              onPressed: () async {
                if (await confirm(
                  context,
                  'Удалить привычку?',
                  text: 'Все отметки тоже удалятся. Чтобы просто убрать её с глаз, отправь в архив.',
                  ok: 'Удалить',
                  danger: true,
                )) {
                  await db.deleteById(db.habits, h.id);
                  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
