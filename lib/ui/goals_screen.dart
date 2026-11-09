import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/goal_queries.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import '../logic/goals.dart';
import '../logic/minimum.dart';
import '../logic/values.dart';
import 'charts.dart';
import 'common.dart';
import 'icons.dart';
import 'journal_screen.dart';
import 'money_screen.dart';
import 'theme.dart';
import 'trackers_screen.dart';

/// Текущее значение цели и подпись к нему. Оставлено для старого кода: новые экраны берут [goalStatus].
({double? current, String unit, bool money}) goalCurrent(
  Goal g, {
  required Map<int, Tracker> trackers,
  required List<TrackerEntry> entries,
  required Map<int, double> fundValues,
}) {
  switch (g.kind) {
    case GoalKind.tracker:
      final t = trackers[g.trackerId];
      if (t == null) return (current: null, unit: '', money: false);
      return (current: trackerGoalValue(t, entries), unit: goalUnit(t), money: false);
    case GoalKind.fund:
      return (current: fundValues[g.fundId], unit: '₽', money: true);
    case GoalKind.manual:
    case GoalKind.steps:
      return (current: null, unit: g.unit ?? '', money: false);
  }
}

IconData goalAreaIcon(GoalArea? a) => switch (a) {
  GoalArea.health => Icons.favorite_rounded,
  GoalArea.money => Icons.savings_rounded,
  GoalArea.career => Icons.work_rounded,
  GoalArea.study => Icons.school_rounded,
  GoalArea.relations => Icons.people_alt_rounded,
  GoalArea.hobby => Icons.sports_esports_rounded,
  GoalArea.other || null => Icons.flag_rounded,
};

Color goalAreaColor(GoalArea? a) => switch (a) {
  GoalArea.health => Accent.habits,
  GoalArea.money => Accent.money,
  GoalArea.career => Accent.trackers,
  GoalArea.study => Accent.sleep,
  GoalArea.relations => Accent.journal,
  GoalArea.hobby => Accent.workouts,
  GoalArea.other || null => Accent.goals,
};

Color goalPaceColor(GoalPace p, ColorScheme scheme) => switch (p) {
  GoalPace.reached || GoalPace.ahead => Accent.habits,
  GoalPace.onTrack => Accent.trackers,
  GoalPace.behind => Accent.workouts,
  GoalPace.overdue => scheme.error,
  GoalPace.noData || GoalPace.noDeadline => scheme.onSurfaceVariant,
};

IconData goalPaceIcon(GoalPace p) => switch (p) {
  GoalPace.reached => Icons.emoji_events_rounded,
  GoalPace.ahead => Icons.rocket_launch_rounded,
  GoalPace.onTrack => Icons.check_circle_rounded,
  GoalPace.behind => Icons.trending_down_rounded,
  GoalPace.overdue => Icons.event_busy_rounded,
  GoalPace.noData => Icons.hourglass_empty_rounded,
  GoalPace.noDeadline => Icons.all_inclusive_rounded,
};

String _signed(Goal g, GoalSources s, double v) {
  final abs = goalIsMoney(g) ? formatMoney(v.abs()) : formatGoalValue(g, s, v.abs());
  return abs;
}

/// Короткая подсказка под карточкой: что делать дальше.
String? goalAdvice(Goal g, GoalStatus st, GoalSources s, {required int today}) {
  switch (st.pace) {
    case GoalPace.reached:
      return g.achievedDay == null ? 'Цель взята! Отметь её достигнутой.' : null;
    case GoalPace.behind:
    case GoalPace.onTrack:
    case GoalPace.ahead:
      final per = st.perWeekNeeded;
      if (g.kind == GoalKind.steps) {
        final next = nextStep(g, s);
        return next == null ? null : 'Следующий шаг: ${next.title}';
      }
      if (per == null || per == 0) return null;
      return 'Чтобы успеть: ${_signed(g, s, per)} в неделю';
    case GoalPace.overdue:
      return 'Срок прошёл. Поставь новый срок или измени цель.';
    case GoalPace.noData:
      return switch (g.kind) {
        GoalKind.steps => 'Добавь этапы, чтобы видеть прогресс',
        GoalKind.manual => 'Отметь текущее значение',
        _ => 'Пока нет данных',
      };
    case GoalPace.noDeadline:
      if (g.kind == GoalKind.steps) {
        final next = nextStep(g, s);
        return next == null ? null : 'Следующий шаг: ${next.title}';
      }
      return st.forecastDay == null ? null : 'При текущем темпе: ${formatDay(st.forecastDay!, withYear: true)}';
  }
}

enum _GoalFilter { active, achieved, archived }

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  var _filter = _GoalFilter.active;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return ScrollFabScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Цели')),
        floatingActionButton: ScrollFab(
          child: FloatingActionButton.extended(
            heroTag: null,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalEditScreen())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Цель'),
          ),
        ),
        body: Watch(
          streams: () => [db.watchAllGoals(), db.watchGoalSources()],
          builder: (context, v) {
            final all = v[0] as List<Goal>;
            final sources = v[1] as GoalSources;
            final today = todayKey();
            final statuses = {for (final g in all) g.id: goalStatus(g, sources, today: today)};
            final active = all.where((g) => !g.archived && g.achievedDay == null).toList();
            final achieved = all.where((g) => !g.archived && g.achievedDay != null).toList()
              ..sort((a, b) => b.achievedDay!.compareTo(a.achievedDay!));
            final archived = all.where((g) => g.archived).toList();
            final shown = switch (_filter) {
              _GoalFilter.active => active,
              _GoalFilter.achieved => achieved,
              _GoalFilter.archived => archived,
            };
            final children = <Widget>[
              _GoalsHero(active: active, achieved: achieved, statuses: statuses, today: today),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SegmentedButton<_GoalFilter>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: _GoalFilter.active, label: Text('В работе · ${active.length}')),
                    ButtonSegment(value: _GoalFilter.achieved, label: Text('Взяты · ${achieved.length}')),
                    ButtonSegment(value: _GoalFilter.archived, label: Text('Архив · ${archived.length}')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ),
            ];
            if (shown.isEmpty) {
              children.add(
                EmptyHint(switch (_filter) {
                  _GoalFilter.active =>
                    'Цель это результат к сроку: «Вес 73 кг к маю», «Закрыть кредит», «Сделать резюме». '
                        'Добавь мотив и план на случай препятствий: так цели достигаются чаще.',
                  _GoalFilter.achieved => 'Здесь будут взятые цели. Первая уже ближе, чем кажется.',
                  _GoalFilter.archived => 'Архив пуст.',
                }, icon: Icons.flag_rounded),
              );
            } else if (_filter == _GoalFilter.active) {
              // Группы по сферам жизни, внутри сначала то, что требует внимания.
              final byArea = <GoalArea?, List<Goal>>{};
              for (final g in shown) {
                byArea.putIfAbsent(g.area, () => []).add(g);
              }
              final areas = byArea.keys.toList()..sort((a, b) => (a?.index ?? 99).compareTo(b?.index ?? 99));
              for (final a in areas) {
                final list = byArea[a]!..sort((x, y) => goalUrgency(statuses[x.id]!).compareTo(goalUrgency(statuses[y.id]!)));
                if (areas.length > 1 || a != null) {
                  children.add(SectionTitle(goalAreaLabel(a)));
                } else {
                  children.add(const SizedBox(height: 8));
                }
                for (final g in list) {
                  children.add(_GoalCard(goal: g, status: statuses[g.id]!, sources: sources, today: today));
                }
              }
            } else {
              children.add(const SizedBox(height: 8));
              for (final g in shown) {
                children.add(_GoalCard(goal: g, status: statuses[g.id]!, sources: sources, today: today));
              }
            }
            return ListView(padding: const EdgeInsets.only(bottom: 96), children: children);
          },
        ),
      ),
    );
  }
}

class _GoalsHero extends StatelessWidget {
  const _GoalsHero({required this.active, required this.achieved, required this.statuses, required this.today});
  final List<Goal> active;
  final List<Goal> achieved;
  final Map<int, GoalStatus> statuses;
  final int today;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final withDeadline = active.where((g) => statuses[g.id]!.expected != null).toList();
    final onPlan = withDeadline.where((g) {
      final p = statuses[g.id]!.pace;
      return p == GoalPace.onTrack || p == GoalPace.ahead;
    }).length;
    final attention = active.where((g) {
      final p = statuses[g.id]!.pace;
      return p == GoalPace.behind || p == GoalPace.overdue || (p == GoalPace.reached && g.achievedDay == null);
    }).toList();
    final year = today ~/ 10000;
    final thisYear = achieved.where((g) => g.achievedDay! ~/ 10000 == year).length;
    final avg = active.isEmpty ? 0.0 : active.fold<double>(0, (a, g) => a + statuses[g.id]!.fraction) / active.length;
    return HeroCard(
      colors: dark ? const [Color(0xFF7E22CE), Color(0xFF4338CA)] : const [Color(0xFFA855F7), Color(0xFF6366F1)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgressRing(
                value: avg,
                size: 64,
                stroke: 7,
                color: Colors.white,
                child: Text(
                  '${(avg * 100).round()}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active.isEmpty ? 'Нет целей в работе' : 'В среднем пройдено',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      attention.isEmpty
                          ? (active.isEmpty ? 'Поставь первую цель' : 'Всё идёт по плану')
                          : 'Внимания требуют: ${attention.map((g) => g.name).join(', ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                child: HeroStat(label: 'В работе', value: '${active.length}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HeroStat(label: 'По плану', value: withDeadline.isEmpty ? '—' : '$onPlan из ${withDeadline.length}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HeroStat(label: 'Взято', value: '$thisYear'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.status, required this.sources, required this.today});
  final Goal goal;
  final GoalStatus status;
  final GoalSources sources;
  final int today;

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final st = status;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final color = st.reached ? Accent.habits : goalAreaColor(g.area);
    final paceColor = goalPaceColor(st.pace, scheme);
    final cur = st.current;
    String f(double v) => formatGoalValue(g, sources, v);
    final minReached =
        !st.reached &&
        g.kind != GoalKind.steps &&
        goalMinimumReached(start: g.startValue, target: g.targetValue, minimum: g.minimumValue, current: cur);
    final advice = goalAdvice(g, st, sources, today: today);
    final history = goalHistory(g, sources);
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: g.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProgressRing(
                    value: st.fraction,
                    size: 60,
                    stroke: 7,
                    color: color,
                    child: st.reached
                        ? Icon(Icons.check_rounded, color: color)
                        : Text('${(st.fraction * 100).round()}%', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          g.kind == GoalKind.steps
                              ? (st.target == 0
                                    ? 'Этапов пока нет'
                                    : 'сделано ${formatNumber(cur ?? 0)} из ${formatNumber(st.target)} этапов')
                              : [cur == null ? 'Пока нет данных' : 'сейчас ${f(cur)}', 'цель ${f(st.target)}'].join(' · '),
                          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  if (history.length >= 3 && g.kind != GoalKind.steps)
                    Sparkline(values: [for (final (_, v) in history.skip(history.length > 30 ? history.length - 30 : 0)) v], color: color),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Pill(
                    g.achievedDay != null ? 'Взята ${formatDay(g.achievedDay!, withYear: true)}' : goalPaceLabel(st.pace),
                    icon: goalPaceIcon(st.pace),
                    color: paceColor,
                  ),
                  if (minReached) const Pill('Минимум взят', icon: Icons.contrast_rounded, color: Accent.reminders),
                  if (st.daysLeft != null && g.achievedDay == null)
                    Pill(
                      st.daysLeft! >= 0
                          ? 'до ${formatDay(g.deadline!)} · ${_daysText(st.daysLeft!)}'
                          : 'срок был ${formatDay(g.deadline!)}',
                      icon: Icons.event_rounded,
                      color: st.daysLeft! < 0 && !st.reached ? scheme.error : null,
                    ),
                ],
              ),
              if (advice != null && g.achievedDay == null) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(advice, style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _daysText(int days) {
  if (days == 0) return 'сегодня';
  if (days < 60) return 'осталось $days дн.';
  final months = (days / 30.4).round();
  return 'осталось ~$months мес.';
}

// ---------------------------------------------------------------------------
// Карточка цели
// ---------------------------------------------------------------------------

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final int goalId;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Watch(
      deps: [goalId],
      streams: () => [db.watchGoal(goalId), db.watchGoalSources(), db.watchHabits(), db.watchAllHabitLogs(), db.watchGoalNotes(goalId)],
      builder: (context, v) {
        final g = v[0] as Goal?;
        if (g == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Цель удалена')),
          );
        }
        final s = v[1] as GoalSources;
        final habits = v[2] as List<Habit>;
        final logs = v[3] as List<HabitLog>;
        final notes = v[4] as List<JournalEntry>;
        final today = todayKey();
        final st = goalStatus(g, s, today: today);
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final muted = scheme.onSurfaceVariant;
        String f(double v) => formatGoalValue(g, s, v);
        final history = goalHistory(g, s);
        final steps = s.stepsOf(g.id);
        final checkins = s.checkinsOf(g.id).reversed.toList();
        final linked = [for (final id in parseIds(g.habitIds)) ?habits.where((h) => h.id == id).firstOrNull];
        final tracker = s.trackers[g.trackerId];
        final dark = theme.brightness == Brightness.dark;
        final areaColor = goalAreaColor(g.area);

        Widget? fab;
        if (g.kind == GoalKind.manual) {
          fab = FloatingActionButton.extended(
            heroTag: null,
            onPressed: () => showCheckinSheet(context, g, current: st.current),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Отметить'),
          );
        } else if (g.kind == GoalKind.steps) {
          fab = FloatingActionButton.extended(
            heroTag: null,
            onPressed: () => showStepSheet(context, g),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Этап'),
          );
        } else if (g.kind == GoalKind.tracker && tracker != null) {
          fab = FloatingActionButton.extended(
            heroTag: null,
            onPressed: () => showEntryDialog(context, tracker),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Записать'),
          );
        }

        return ScrollFabScope(
          child: Scaffold(
            appBar: AppBar(
              title: Text(g.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Изменить',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalEditScreen(goal: g))),
                ),
              ],
            ),
            floatingActionButton: g.archived || fab == null ? null : ScrollFab(child: fab),
            body: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                HeroCard(
                  colors: dark
                      ? [Color.lerp(areaColor, Colors.black, 0.35)!, const Color(0xFF4338CA)]
                      : [areaColor, const Color(0xFF6366F1)],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ProgressRing(
                            value: st.fraction,
                            size: 84,
                            stroke: 9,
                            color: Colors.white,
                            child: st.reached
                                ? const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32)
                                : Text(
                                    '${(st.fraction * 100).round()}%',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(goalAreaIcon(g.area), color: Colors.white70, size: 16),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(goalAreaLabel(g.area), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  g.achievedDay != null ? 'Взята ${formatDay(g.achievedDay!, withYear: true)}' : goalPaceLabel(st.pace),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                                ),
                                if (st.gap != null && !st.reached && st.pace != GoalPace.overdue && st.gap!.abs() > 0)
                                  Text(
                                    st.gap! > 0
                                        ? 'Отстаёшь от плана на ${_signed(g, s, st.gap!)}'
                                        : 'Впереди плана на ${_signed(g, s, st.gap!)}',
                                    style: const TextStyle(color: Colors.white70, height: 1.3),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (g.kind == GoalKind.steps)
                        Row(
                          children: [
                            Expanded(
                              child: HeroStat(label: 'Сделано', value: formatNumber(st.current ?? 0)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: HeroStat(label: 'Этапов', value: formatNumber(st.target)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: HeroStat(label: 'Срок', value: g.deadline == null ? '—' : formatDay(g.deadline!)),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: HeroStat(label: 'Старт', value: f(st.start)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: HeroStat(label: 'Сейчас', value: st.current == null ? '—' : f(st.current!)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: HeroStat(label: 'Цель', value: f(st.target)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (st.reached && g.achievedDay == null && !g.archived)
                  _Banner(
                    icon: Icons.emoji_events_rounded,
                    color: Accent.habits,
                    text: 'Цель достигнута! Отметь её, чтобы она ушла во «Взятые», и запиши, что помогло.',
                    action: 'Отметить',
                    onTap: () => context.db.setGoalAchieved(g.id, today),
                  )
                else if (g.achievedDay != null)
                  _Banner(
                    icon: Icons.replay_rounded,
                    color: muted,
                    text: 'Цель во «Взятых». Если хочешь продолжить, верни её в работу.',
                    action: 'В работу',
                    onTap: () => context.db.setGoalAchieved(g.id, null),
                  ),
                _AnalysisCard(goal: g, status: st, sources: s, today: today),
                if (history.length >= 2 && g.kind != GoalKind.steps) ...[
                  const SectionTitle('Динамика'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
                      child: LineChart(
                        points: history.length > 120 ? history.sublist(history.length - 120) : history,
                        target: st.target,
                        color: areaColor,
                      ),
                    ),
                  ),
                ],
                if (g.kind == GoalKind.steps || steps.isNotEmpty) ...[
                  SectionTitle(
                    g.kind == GoalKind.steps ? 'Этапы' : 'Вехи',
                    trailing: IconButton(
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Добавить',
                      onPressed: () => showStepSheet(context, g),
                    ),
                  ),
                  if (steps.isEmpty)
                    const Card(child: EmptyHint('Разбей цель на шаги: каждый на день-два работы.', icon: Icons.checklist_rounded))
                  else
                    GroupCard(
                      children: [for (final x in steps) _StepTile(step: x, goal: g, today: today)],
                    ),
                ],
                if (g.kind == GoalKind.manual) ...[
                  const SectionTitle('Отметки'),
                  if (checkins.isEmpty)
                    const Card(child: EmptyHint('Отмечай значение, когда оно меняется. Из отметок строятся график и прогноз.'))
                  else
                    GroupCard(
                      children: [
                        for (final c in checkins.take(20))
                          ListTile(
                            title: Text(f(c.value)),
                            subtitle: Text([dayLabel(c.day), if (c.note != null) c.note!].join(' · ')),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Удалить',
                              onPressed: () => context.db.deleteById(context.db.goalCheckins, c.id),
                            ),
                          ),
                      ],
                    ),
                ],
                if (g.kind != GoalKind.steps && g.kind != GoalKind.manual) _SourceTile(goal: g, sources: s),
                const SectionTitle('Зачем и план'),
                _MotivationCard(goal: g),
                SectionTitle(
                  'Привычки, которые ведут к цели',
                  trailing: IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'Выбрать',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalEditScreen(goal: g))),
                  ),
                ),
                if (linked.isEmpty)
                  const Card(
                    child: EmptyHint(
                      'Результат это следствие ежедневных действий. Привяжи привычки, которые двигают цель, и следи за ними здесь.',
                      icon: Icons.repeat_rounded,
                    ),
                  )
                else
                  GroupCard(
                    children: [for (final h in linked) _HabitLeadTile(habit: h, logs: logs, today: today)],
                  ),
                SectionTitle(
                  'Заметки',
                  trailing: IconButton(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Добавить заметку',
                    onPressed: () => openJournalEditor(context, kind: JournalKind.note, day: today, goalId: g.id),
                  ),
                ),
                if (notes.isEmpty)
                  const Card(child: EmptyHint('Мысли по цели: что помогло, что мешает, что попробовать.'))
                else
                  for (final n in notes.take(10)) JournalEntryCard(entry: n),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text, required this.action, required this.onTap});
  final IconData icon;
  final Color color;
  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
            TextButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

/// Разбор темпа: где по плану, сколько нужно в неделю, прогноз, минимум.
class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.goal, required this.status, required this.sources, required this.today});
  final Goal goal;
  final GoalStatus status;
  final GoalSources sources;
  final int today;

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final st = status;
    String f(double v) => formatGoalValue(g, sources, v);
    final rows = <(IconData, String)>[];
    if (st.reached) {
      rows.add((Icons.emoji_events_rounded, 'Цель достигнута. Подумай, что дальше: новая планка или поддержка результата.'));
    } else {
      if (st.expected != null && st.pace != GoalPace.overdue && g.kind != GoalKind.steps) {
        rows.add((Icons.timeline_rounded, 'По плану сегодня должно быть ${f(st.expected!)}'));
      }
      if (st.perWeekNeeded != null && g.kind != GoalKind.steps) {
        rows.add((Icons.speed_rounded, 'Чтобы успеть к ${formatDay(g.deadline!)}: ${_signed(g, sources, st.perWeekNeeded!)} в неделю'));
      } else if (st.perWeekNeeded != null && g.kind == GoalKind.steps && st.daysLeft != null) {
        final left = st.target - (st.current ?? 0);
        rows.add((
          Icons.speed_rounded,
          'Осталось этапов: ${formatNumber(left)} за ${_daysText(st.daysLeft!).replaceFirst('осталось ', '')}',
        ));
      }
      if (st.forecastDay != null) {
        final late = g.deadline != null && st.forecastDay! > g.deadline!;
        rows.add((
          late ? Icons.warning_amber_rounded : Icons.trending_up_rounded,
          'При текущем темпе: ${formatDay(st.forecastDay!, withYear: true)}${late ? ', позже срока' : ''}',
        ));
      } else if (st.current != null && daysBetween(g.startDay, today) < 7 && g.kind != GoalKind.steps) {
        rows.add((Icons.hourglass_top_rounded, 'Прогноз появится через неделю данных'));
      }
      if (g.minimumValue != null && g.kind != GoalKind.steps) {
        final ok = goalMinimumReached(start: g.startValue, target: g.targetValue, minimum: g.minimumValue, current: st.current);
        rows.add((ok ? Icons.contrast_rounded : Icons.flag_outlined, 'Минимум ${f(g.minimumValue!)}${ok ? ': уже взят' : ''}'));
      }
      if (g.deadline == null) rows.add((Icons.event_outlined, 'Без срока цель легко откладывать. Поставь дату, и появится план.'));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          children: [
            for (final (icon, text) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: muted),
                    const SizedBox(width: 10),
                    Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.goal, required this.sources});
  final Goal goal;
  final GoalSources sources;

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final t = sources.trackers[g.trackerId];
    final fund = sources.funds[g.fundId];
    if (t == null && fund == null) {
      return const Card(child: EmptyHint('Источник цели удалён. Выбери другой в настройках цели.'));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GroupCard(
        children: [
          ListTile(
            leading: t != null ? ItemIcon(t.icon, size: 40, fallback: 'chart') : ItemIcon(fund!.icon, size: 40, fallback: 'savings'),
            title: Text(t?.name ?? fund!.name),
            subtitle: Text(t != null ? 'Значение берётся из трекера' : 'Значение берётся из раздела «Деньги»'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => t != null ? TrackerDetailScreen(trackerId: t.id) : FundDetailScreen(fundId: fund!.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step, required this.goal, required this.today});
  final GoalStep step;
  final Goal goal;
  final int today;

  @override
  Widget build(BuildContext context) {
    final x = step;
    final done = x.doneDay != null;
    final scheme = Theme.of(context).colorScheme;
    final overdue = !done && x.dueDay != null && x.dueDay! < today;
    return ListTile(
      leading: Checkbox(value: done, onChanged: (v) => context.db.setGoalStepDone(x.id, v ?? false)),
      title: Text(
        x.title,
        style: done ? TextStyle(decoration: TextDecoration.lineThrough, color: scheme.onSurfaceVariant) : null,
      ),
      subtitle: done
          ? Text('сделано ${dayLabel(x.doneDay!)}')
          : x.dueDay == null
          ? null
          : Text('до ${dayLabel(x.dueDay!)}', style: TextStyle(color: overdue ? scheme.error : null)),
      onTap: () => showStepSheet(context, goal, existing: x),
    );
  }
}

class _HabitLeadTile extends StatelessWidget {
  const _HabitLeadTile({required this.habit, required this.logs, required this.today});
  final Habit habit;
  final List<HabitLog> logs;
  final int today;

  @override
  Widget build(BuildContext context) {
    final h = habit;
    final done = {
      for (final l in logs)
        if (l.habitId == h.id) l.day,
    };
    final week = habitCompletion(daysMask: h.daysMask, doneDays: done, from: weekStart(today), to: today);
    final month = habitCompletion(daysMask: h.daysMask, doneDays: done, from: addDays(today, -27), to: today);
    final rate = month.planned == 0 ? null : month.done / month.planned;
    final streak = currentStreak(daysMask: h.daysMask, doneDays: done, today: today);
    return ListTile(
      leading: ItemIcon(h.icon, size: 40),
      title: Text(h.name),
      subtitle: Text(
        [
          'неделя ${week.done} из ${week.planned}',
          if (rate != null) '4 недели ${(rate * 100).round()}%',
          if (streak > 1) 'серия $streak',
        ].join(' · '),
      ),
      trailing: rate == null
          ? null
          : ProgressRing(
              value: rate,
              size: 34,
              stroke: 4,
              color: rate >= 0.8 ? Accent.habits : (rate >= 0.5 ? Accent.reminders : Accent.workouts),
            ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    if (g.why == null && g.obstacle == null && g.plan == null) {
      return Card(
        child: EmptyHint(
          'Запиши, зачем тебе эта цель, что может помешать и что ты сделаешь, если помешает. '
          'План «если…, то…» заметно повышает шанс дойти до конца.',
          icon: Icons.psychology_alt_rounded,
          action: FilledButton.tonal(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalEditScreen(goal: g, focusMotivation: true))),
            child: const Text('Заполнить'),
          ),
        ),
      );
    }
    Widget block(IconData icon, String label, String text, Color color) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ColorIcon(icon, color: color, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelLarge?.copyWith(color: muted)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalEditScreen(goal: g, focusMotivation: true))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            children: [
              if (g.why != null) block(Icons.favorite_rounded, 'Зачем', g.why!, Accent.journal),
              if (g.obstacle != null) block(Icons.block_rounded, 'Что может помешать', g.obstacle!, Accent.workouts),
              if (g.plan != null) block(Icons.alt_route_rounded, 'Если это случится, я…', g.plan!, Accent.trackers),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Листы: отметка и этап
// ---------------------------------------------------------------------------

Future<void> showCheckinSheet(BuildContext context, Goal g, {double? current}) {
  return showFormSheet(context, (_) => _CheckinForm(goal: g, current: current));
}

class _CheckinForm extends StatefulWidget {
  const _CheckinForm({required this.goal, this.current});
  final Goal goal;
  final double? current;

  @override
  State<_CheckinForm> createState() => _CheckinFormState();
}

class _CheckinFormState extends State<_CheckinForm> {
  late final _value = TextEditingController(text: widget.current == null ? '' : formatNumber(widget.current!, maxDecimals: 2));
  final _note = TextEditingController();
  var _day = todayKey();

  Future<void> _save() async {
    final v = parseNumber(_value.text);
    if (v == null) return showSnack(context, 'Введи значение');
    await context.db.addGoalCheckin(widget.goal.id, v, day: _day, note: emptyToNull(_note.text));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.goal.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        NumberField(controller: _value, label: 'Сколько сейчас', suffix: widget.goal.unit, autofocus: true, allowNegative: true),
        DayTile(day: _day, onChanged: (d) => setState(() => _day = d ?? _day)),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Заметка (необязательно)'),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Сохранить')),
      ],
    );
  }
}

Future<void> showStepSheet(BuildContext context, Goal g, {GoalStep? existing}) {
  return showFormSheet(context, (_) => _StepForm(goal: g, existing: existing));
}

class _StepForm extends StatefulWidget {
  const _StepForm({required this.goal, this.existing});
  final Goal goal;
  final GoalStep? existing;

  @override
  State<_StepForm> createState() => _StepFormState();
}

class _StepFormState extends State<_StepForm> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late int? _due = widget.existing?.dueDay;

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return showSnack(context, 'Введи название этапа');
    final db = context.db;
    if (widget.existing == null) {
      await db.addGoalStep(widget.goal.id, title, dueDay: _due);
    } else {
      await db.updateGoalStep(widget.existing!.id, title: title, dueDay: Value(_due));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.existing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(e == null ? 'Новый этап' : 'Этап', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextField(
          controller: _title,
          autofocus: e == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Что сделать', hintText: 'Например: Пройти раздел про FastAPI'),
          onSubmitted: (_) => _save(),
        ),
        DayTile(title: 'Срок этапа', day: _due, allowClear: true, onChanged: (d) => setState(() => _due = d)),
        const SizedBox(height: 8),
        FilledButton(onPressed: _save, child: const Text('Сохранить')),
        if (e != null)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Удалить этап'),
            onPressed: () async {
              await context.db.deleteById(context.db.goalSteps, e.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Создание и правка цели
// ---------------------------------------------------------------------------

class GoalEditScreen extends StatefulWidget {
  const GoalEditScreen({super.key, this.goal, this.focusMotivation = false});
  final Goal? goal;

  /// Открыть сразу на блоке «Зачем и план».
  final bool focusMotivation;

  @override
  State<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends State<GoalEditScreen> {
  late final _name = TextEditingController(text: widget.goal?.name ?? '');
  late GoalKind _kind = widget.goal?.kind ?? GoalKind.tracker;
  late GoalArea? _area = widget.goal?.area;
  late int? _trackerId = widget.goal?.trackerId;
  late int? _fundId = widget.goal?.fundId;
  late final _start = TextEditingController(text: widget.goal == null ? '' : formatNumber(widget.goal!.startValue, maxDecimals: 2));
  late final _target = TextEditingController(text: widget.goal == null ? '' : formatNumber(widget.goal!.targetValue, maxDecimals: 2));
  late final _minimum = TextEditingController(
    text: widget.goal?.minimumValue == null ? '' : formatNumber(widget.goal!.minimumValue!, maxDecimals: 2),
  );
  late final _unit = TextEditingController(text: widget.goal?.unit ?? '');
  late final _why = TextEditingController(text: widget.goal?.why ?? '');
  late final _obstacle = TextEditingController(text: widget.goal?.obstacle ?? '');
  late final _plan = TextEditingController(text: widget.goal?.plan ?? '');
  final _steps = TextEditingController();
  late int? _deadline = widget.goal?.deadline;
  late final Set<int> _habits = parseIds(widget.goal?.habitIds).toSet();
  final _motivationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focusMotivation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _motivationKey.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
      });
    }
  }

  bool get _numeric => _kind != GoalKind.steps;

  Future<void> _save() async {
    final start = parseNumber(_start.text);
    final target = parseNumber(_target.text);
    if (_name.text.trim().isEmpty) return showSnack(context, 'Введи название');
    if (_kind == GoalKind.tracker && _trackerId == null) return showSnack(context, 'Выбери трекер');
    if (_kind == GoalKind.fund && _fundId == null) return showSnack(context, 'Выбери копилку или долг');
    if (_numeric && (start == null || target == null)) return showSnack(context, 'Укажи старт и цель');
    if (_numeric && start == target) return showSnack(context, 'Цель должна отличаться от старта');
    final minimum = _numeric ? parseNumber(_minimum.text) : null;
    if (minimum != null && (minimum - start!) * (target! - minimum) <= 0) {
      return showSnack(context, 'Минимум должен быть между стартом и целью');
    }
    final db = context.db;
    final id = await db.saveGoal(
      GoalsCompanion(
        id: widget.goal == null ? const Value.absent() : Value(widget.goal!.id),
        name: Value(_name.text.trim()),
        kind: Value(_kind),
        area: Value(_area),
        trackerId: Value(_kind == GoalKind.tracker ? _trackerId : null),
        fundId: Value(_kind == GoalKind.fund ? _fundId : null),
        startValue: Value(start ?? 0),
        targetValue: Value(target ?? 0),
        minimumValue: Value(minimum),
        unit: Value(_kind == GoalKind.manual ? emptyToNull(_unit.text) : null),
        deadline: Value(_deadline),
        why: Value(emptyToNull(_why.text)),
        obstacle: Value(emptyToNull(_obstacle.text)),
        plan: Value(emptyToNull(_plan.text)),
        habitIds: Value(joinIds(_habits)),
        startDay: widget.goal == null ? Value(todayKey()) : const Value.absent(),
      ),
    );
    // Первая отметка ручной цели: стартовое значение.
    if (widget.goal == null && _kind == GoalKind.manual && start != null) {
      await db.addGoalCheckin(id, start);
    }
    for (final line in _steps.text.split('\n')) {
      if (line.trim().isNotEmpty) await db.addGoalStep(id, line.trim());
    }
    if (!mounted) return;
    if (widget.goal == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: id)));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final g = widget.goal;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: Text(g == null ? 'Новая цель' : 'Настройки цели')),
      body: Watch(
        streams: () => [db.watchTrackers(), db.watchFunds(), db.watchAllEntries(), db.watchFundValues(), db.watchHabits()],
        builder: (context, v) {
          final trackers = v[0] as List<Tracker>;
          final funds = v[1] as List<Fund>;
          final entries = v[2] as List<TrackerEntry>;
          final fundValues = v[3] as Map<int, double>;
          final habits = v[4] as List<Habit>;
          final trackerMap = {for (final t in trackers) t.id: t};
          String? hint;
          if (_kind == GoalKind.tracker && trackerMap[_trackerId] != null) {
            final t = trackerMap[_trackerId]!;
            final cur = trackerGoalValue(t, entries);
            hint = [
              if (t.kind == TrackerKind.duration) 'Цель по времени считается в часах суммарно.',
              if (t.kind == TrackerKind.yesNo) 'Цель считается в днях с ответом «да».',
              if (cur != null) 'Сейчас: ${formatNumber(cur)} ${goalUnit(t)}',
            ].join(' ');
          } else if (_kind == GoalKind.fund && _fundId != null && fundValues[_fundId] != null) {
            hint = 'Сейчас: ${formatMoney(fundValues[_fundId]!)}';
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Название', hintText: 'Например: Вес 73 кг'),
              ),
              const SizedBox(height: 20),
              Text('Сфера', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in GoalArea.values)
                    ChoiceChip(
                      avatar: Icon(goalAreaIcon(a), color: goalAreaColor(a), size: 18),
                      label: Text(goalAreaLabel(a)),
                      showCheckmark: false,
                      selected: _area == a,
                      onSelected: (on) => setState(() => _area = on ? a : null),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Как считать прогресс', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in GoalKind.values)
                    ChoiceChip(
                      label: Text(goalKindLabel(k)),
                      showCheckmark: false,
                      selected: _kind == k,
                      onSelected: g != null && g.kind != k && (g.kind == GoalKind.steps || k == GoalKind.steps)
                          ? null
                          : (_) => setState(() => _kind = k),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(goalKindHint(_kind), style: TextStyle(color: muted, height: 1.35)),
              ),
              const SizedBox(height: 16),
              if (_kind == GoalKind.tracker)
                DropdownButtonFormField<int>(
                  initialValue: trackerMap.containsKey(_trackerId) ? _trackerId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Трекер'),
                  items: [for (final t in trackers) DropdownMenuItem(value: t.id, child: Text(t.name))],
                  onChanged: (id) => setState(() {
                    _trackerId = id;
                    final t = trackerMap[id];
                    final cur = t == null ? null : trackerGoalValue(t, entries);
                    if (_start.text.isEmpty && cur != null) _start.text = formatNumber(cur, maxDecimals: 2);
                  }),
                ),
              if (_kind == GoalKind.fund)
                DropdownButtonFormField<int>(
                  initialValue: funds.any((f) => f.id == _fundId) ? _fundId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Копилка или долг'),
                  items: [for (final f in funds) DropdownMenuItem(value: f.id, child: Text(f.name))],
                  onChanged: (id) => setState(() {
                    _fundId = id;
                    final f = funds.where((f) => f.id == id).firstOrNull;
                    if (f == null) return;
                    if (_start.text.isEmpty) _start.text = formatNumber(fundValues[id] ?? f.initialAmount);
                    if (_target.text.isEmpty) {
                      final t = f.kind == FundKind.debt ? 0.0 : f.target;
                      if (t != null) _target.text = formatNumber(t);
                    }
                    _area ??= GoalArea.money;
                  }),
                ),
              if (_kind == GoalKind.manual)
                TextField(
                  controller: _unit,
                  decoration: const InputDecoration(labelText: 'Единица', hintText: 'книг, уровень, клиентов'),
                ),
              if (hint != null && hint.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(hint)),
              if (_numeric) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: NumberField(controller: _start, label: 'Старт', allowNegative: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NumberField(controller: _target, label: 'Цель', allowNegative: true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                NumberField(controller: _minimum, label: 'Минимум (необязательно)', allowNegative: true),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Результат, который уже можно считать успехом, если до цели не дотянешь. Например, цель 73 кг, минимум 71.',
                    style: TextStyle(color: muted),
                  ),
                ),
              ],
              if (_kind == GoalKind.steps && g == null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _steps,
                  minLines: 3,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Этапы, по строке на каждый',
                    hintText: 'Повторить Python\nСделать проект на FastAPI\nСобрать резюме',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
              DayTile(title: 'Срок', day: _deadline, allowClear: true, onChanged: (d) => setState(() => _deadline = d)),
              const SizedBox(height: 8),
              Text('Зачем и план', key: _motivationKey, style: theme.textTheme.titleSmall),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Метод WOOP: желание, результат, препятствие, план. Помогает не сдаться на первом сбое.',
                  style: TextStyle(color: muted, height: 1.35),
                ),
              ),
              TextField(
                controller: _why,
                minLines: 1,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Зачем мне это', hintText: 'Что изменится, когда достигну'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _obstacle,
                minLines: 1,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Что может помешать', hintText: 'Усталость после смены'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _plan,
                minLines: 1,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Если это случится, я…', hintText: 'сделаю минимум: 15 минут вместо часа'),
              ),
              if (habits.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Привычки, которые ведут к цели', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final h in habits)
                      FilterChip(
                        label: Text(h.name),
                        selected: _habits.contains(h.id),
                        onSelected: (on) => setState(() => on ? _habits.add(h.id) : _habits.remove(h.id)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: const Text('Сохранить')),
              if (g != null) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: Icon(g.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
                  label: Text(g.archived ? 'Вернуть из архива' : 'В архив'),
                  onPressed: () async {
                    await db.setArchived(db.goals, g.id, !g.archived);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить цель'),
                  onPressed: () async {
                    if (await confirm(
                      context,
                      'Удалить цель?',
                      text: 'Этапы и отметки цели удалятся. Данные трекера или копилки останутся.',
                      ok: 'Удалить',
                      danger: true,
                    )) {
                      await db.deleteById(db.goals, g.id);
                      // Настройки открываются из карточки цели: закрываем и её.
                      if (context.mounted) {
                        Navigator.of(context)
                          ..pop()
                          ..pop();
                      }
                    }
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
