import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/exercise_catalog.dart';
import '../data/queries.dart';
import '../data/workout_queries.dart';
import '../logic/calc.dart';
import '../logic/workout.dart';
import 'charts.dart';
import 'common.dart';
import 'theme.dart';
import 'workout_session_screen.dart';

/// Всё, что нужно вкладкам спорта, одним набором.
class SportData {
  SportData({
    required this.programs,
    required this.sessions,
    required this.sets,
    required this.exercises,
    required this.goals,
    required this.draft,
    required this.today,
  });

  final List<Program> programs;

  /// От новых к старым.
  final List<WorkoutSession> sessions;
  final List<SessionSet> sets;
  final List<ProgramExercise> exercises;
  final Map<String, int> goals;
  final WorkoutDraft? draft;
  final int today;

  late final Map<int, WorkoutSession> sessionById = {for (final s in sessions) s.id: s};

  /// Подходы по тренировкам.
  late final Map<int, List<SessionSet>> setsBySession = () {
    final m = <int, List<SessionSet>>{};
    for (final s in sets) {
      m.putIfAbsent(s.sessionId, () => []).add(s);
    }
    return m;
  }();

  /// Своя мышца у упражнений программ: перекрывает справочник.
  late final Map<String, Muscle> muscleByName = {
    for (final e in exercises)
      if (Muscle.byKey(e.muscle) != null) e.name: Muscle.byKey(e.muscle)!,
  };

  late final int plannedPerWeek = weekdaysFromMask(programs.fold<int>(0, (m, p) => m | p.daysMask)).length;

  /// Упражнения по названию: тренировки от новых к старым.
  late final Map<String, List<ExerciseSession>> byExercise = () {
    final m = <String, List<ExerciseSession>>{};
    for (final s in sessions) {
      final list = setsBySession[s.id];
      if (list == null) continue;
      final groups = <String, List<SessionSet>>{};
      for (final x in list) {
        groups.putIfAbsent(x.exerciseName, () => []).add(x);
      }
      for (final g in groups.entries) {
        m.putIfAbsent(g.key, () => []).add(ExerciseSession(s, g.value));
      }
    }
    return m;
  }();

  Iterable<SessionSet> setsBetween(int from, int to) sync* {
    for (final s in sessions) {
      if (s.day < from || s.day > to) continue;
      yield* setsBySession[s.id] ?? const [];
    }
  }
}

// ---------------------------------------------------------------------------
// История
// ---------------------------------------------------------------------------

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key, required this.data});
  final SportData data;

  @override
  Widget build(BuildContext context) {
    final sessions = data.sessions;
    final days = {for (final s in sessions) s.day};
    final fullDays = {
      for (final s in sessions)
        if (!s.minimum) s.day,
    };
    final planned = data.programs.fold<int>(0, (m, p) => m | p.daysMask);
    final theme = Theme.of(context);
    final items = <Widget>[];
    int? month;
    for (final s in sessions) {
      final m = s.day ~/ 100;
      if (m != month) {
        month = m;
        final count = sessions.where((x) => x.day ~/ 100 == m).length;
        items.add(SectionTitle('${capitalizeFirst(monthTitle(m ~/ 100, m % 100))} · $count'));
      }
      items.add(_SessionTile(session: s, sets: data.setsBySession[s.id] ?? const []));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Последние 16 недель', style: theme.textTheme.titleSmall),
                const SizedBox(height: 10),
                DayGrid(
                  today: data.today,
                  weeks: 16,
                  color: Accent.workouts,
                  isDone: days.contains,
                  isPlanned: (d) => maskHasDay(planned, d),
                  isMinimum: (d) => !fullDays.contains(d),
                  onTap: (d) {
                    final s = sessions.where((x) => x.day == d).firstOrNull;
                    if (s != null) Navigator.push(context, MaterialPageRoute(builder: (_) => SessionViewScreen(sessionId: s.id)));
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Яркий квадрат: тренировка, бледный: минимум, серый: день по плану.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        if (sessions.isEmpty) const Card(child: EmptyHint('Здесь будут проведённые тренировки', icon: Icons.history_rounded)),
        ...items,
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.sets});
  final WorkoutSession session;
  final List<SessionSet> sets;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final names = <String>{for (final x in sets) x.exerciseName};
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
        leading: s.minimum
            ? const IconBadge(Icons.contrast_rounded, color: Accent.reminders, soft: true)
            : const IconBadge(Icons.fitness_center_rounded, color: Accent.workouts, soft: true),
        title: Text(s.programName),
        subtitle: Text(
          [
            capitalizeFirst(formatDay(s.day)),
            if (s.durationSec != null) '${(s.durationSec! / 60).round()} мин',
            '${sets.length} подх.',
            '${names.length} упр.',
          ].join(' · '),
        ),
        trailing: s.minimum
            ? const Pill('минимум', color: Accent.reminders)
            : s.feel != null
            ? Icon(feelIcons[s.feel! - 1], color: Accent.habits)
            : const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionViewScreen(sessionId: s.id))),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Прогресс
// ---------------------------------------------------------------------------

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key, required this.data});
  final SportData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dark = theme.brightness == Brightness.dark;
    final today = data.today;
    final days = [for (final s in data.sessions) s.day];
    final perWeek = sessionsPerWeek(days, today: today);
    final streak = weekStreak(sessionDays: days, perWeek: data.plannedPerWeek, today: today);
    final monthCount = data.sessions.where((s) => s.day ~/ 100 == today ~/ 100).length;
    final totalSec = data.sessions.fold<int>(0, (a, s) => a + (s.durationSec ?? 0));
    final muscles = muscleSets(data.setsBetween(addDays(today, -6), today), muscleByName: data.muscleByName);
    final setsPerWeek = [for (final (start, _) in perWeek) (start, data.setsBetween(start, addDays(start, 6)).length)];
    final exercises = data.byExercise.entries.toList()..sort((a, b) => b.value.first.session.day.compareTo(a.value.first.session.day));

    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        HeroCard(
          colors: dark ? const [Color(0xFF7C2D12), Color(0xFF9D174D)] : const [Color(0xFFF97316), Color(0xFFE11D48)],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Недель подряд по плану',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('$streak', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
                  const SizedBox(width: 8),
                  if (streak > 0) const Icon(Icons.local_fire_department_rounded, color: Colors.white),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: HeroStat(label: 'Всего', value: '${data.sessions.length}'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: HeroStat(label: 'В этом месяце', value: '$monthCount'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: HeroStat(label: 'Время', value: totalSec == 0 ? '—' : formatDuration(totalSec / 60)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionTitle('Тренировок в неделю'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: BarChart(
              bars: [for (final (start, n) in perWeek) (_weekLabel(start), n.toDouble())],
              color: Accent.workouts.withValues(alpha: 0.55),
              goodColor: Accent.workouts,
              target: data.plannedPerWeek == 0 ? null : data.plannedPerWeek.toDouble(),
            ),
          ),
        ),
        const SectionTitle('Рабочих подходов в неделю'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: BarChart(bars: [for (final (start, n) in setsPerWeek) (_weekLabel(start), n.toDouble())], color: Accent.trackers),
          ),
        ),
        const SectionTitle('Нагрузка на мышцы за 7 дней'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Для роста мышц обычно советуют $weeklySetsLow–$weeklySetsHigh рабочих подходов на группу в неделю. '
                  'Вспомогательная работа идёт за половину подхода.',
                  style: TextStyle(color: muted, height: 1.35, fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (final m in Muscle.values.where((m) => m.countsVolume)) _MuscleRow(muscle: m, sets: muscles[m] ?? 0),
              ],
            ),
          ),
        ),
        SectionTitle(
          'Цели',
          trailing: IconButton(
            tooltip: 'Цель по упражнению',
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final name = await pickExerciseName(context);
              if (name != null && context.mounted) await editSportGoal(context, name, data.goals[name]);
            },
          ),
        ),
        if (data.goals.isEmpty)
          const Card(
            child: EmptyHint('Поставь цель по упражнению: например, 15 подтягиваний или 30 отжиманий подряд.', icon: Icons.flag_outlined),
          ),
        for (final g in data.goals.entries) _GoalCard(name: g.key, target: g.value, sessions: data.byExercise[g.key] ?? const []),
        const SectionTitle('Упражнения'),
        if (exercises.isEmpty)
          const Card(child: EmptyHint('Проведи первую тренировку, и здесь появятся рекорды', icon: Icons.emoji_events_outlined)),
        if (exercises.isNotEmpty)
          GroupCard(
            children: [
              for (final e in exercises)
                ListTile(
                  title: Text(e.key),
                  subtitle: Text(
                    [
                      ?muscleOf(e.key, data.muscleByName[e.key]?.name)?.label,
                      'рекорд ${recordsOf(e.value.expand((x) => x.sets)).bestSet}',
                      '${e.value.length} трен.',
                    ].join(' · '),
                  ),
                  trailing: Sparkline(
                    values: [for (final x in e.value.take(10).toList().reversed) x.sets.map((s) => s.reps).reduce(math.max).toDouble()],
                    color: Accent.workouts,
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseScreen(name: e.key))),
                ),
            ],
          ),
      ],
    );
  }
}

String _weekLabel(int start) => '${dayFromKey(start).day}.${dayFromKey(start).month.toString().padLeft(2, '0')}';

class _MuscleRow extends StatelessWidget {
  const _MuscleRow({required this.muscle, required this.sets});
  final Muscle muscle;
  final double sets;

  @override
  Widget build(BuildContext context) {
    final color = sets >= weeklySetsLow ? Accent.habits : (sets > 0 ? Accent.workouts : Theme.of(context).colorScheme.outline);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(muscle.label)),
          Expanded(
            child: ProgressLine(value: sets / weeklySetsHigh, color: color, height: 8),
          ),
          SizedBox(
            width: 52,
            child: Text(
              formatNumber(sets),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.name, required this.target, required this.sessions});
  final String name;
  final int target;
  final List<ExerciseSession> sessions;

  @override
  Widget build(BuildContext context) {
    final best = recordsOf(sessions.expand((s) => s.sets)).bestSet;
    final done = best >= target;
    final unit = catalogExercise(name)?.unit == 'сек' ? 'сек' : 'повт.';
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseScreen(name: name))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium)),
                  if (done) const Pill('достигнута', icon: Icons.emoji_events_rounded, color: Accent.money),
                ],
              ),
              const SizedBox(height: 8),
              ProgressLine(value: target == 0 ? 0 : best / target, color: done ? Accent.money : Accent.workouts),
              const SizedBox(height: 6),
              Text('Лучший подход $best из $target $unit', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> editSportGoal(BuildContext context, String name, int? current) {
  final c = TextEditingController(text: current?.toString() ?? '');
  return showFormSheet(
    context,
    (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Цель: $name', style: Theme.of(sheet).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text('Сколько повторов (или секунд) за один подход.'),
        const SizedBox(height: 12),
        TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Подряд за подход'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            await sheet.db.setSportGoal(name, int.tryParse(c.text.trim()));
            if (sheet.mounted) Navigator.pop(sheet);
          },
          child: const Text('Сохранить'),
        ),
        if (current != null)
          TextButton(
            onPressed: () async {
              await sheet.db.setSportGoal(name, null);
              if (sheet.mounted) Navigator.pop(sheet);
            },
            child: const Text('Убрать цель'),
          ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Карточка упражнения
// ---------------------------------------------------------------------------

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key, required this.name});
  final String name;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  var _byTotal = false;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final cat = catalogExercise(widget.name);
    final chain = exerciseChains[cat?.chain];
    return Watch(
      deps: [widget.name],
      streams: () => [db.watchAllSets(), db.watchSessions(), db.watchSportGoals(), db.watchAllExercises()],
      builder: (context, v) {
        final data = SportData(
          programs: const [],
          sessions: v[1] as List<WorkoutSession>,
          sets: v[0] as List<SessionSet>,
          exercises: v[3] as List<ProgramExercise>,
          goals: v[2] as Map<String, int>,
          draft: null,
          today: todayKey(),
        );
        final history = data.byExercise[widget.name] ?? const <ExerciseSession>[];
        final rec = recordsOf(history.expand((h) => h.sets));
        final goal = data.goals[widget.name];
        final muscle = muscleOf(widget.name, data.muscleByName[widget.name]?.name);
        final own = data.exercises.where((e) => e.name == widget.name).firstOrNull;
        final u = (own?.unit ?? cat?.unit) == 'сек' ? 'сек' : 'повт.';
        final theme = Theme.of(context);
        final muted = theme.colorScheme.onSurfaceVariant;
        final points = <(int, double)>[];
        for (final h in history.reversed) {
          final value = _byTotal ? totalReps(h.sets).toDouble() : h.sets.map((s) => s.reps).reduce(math.max).toDouble();
          if (points.isNotEmpty && points.last.$1 == h.session.day) {
            points[points.length - 1] = (h.session.day, math.max(points.last.$2, value));
          } else {
            points.add((h.session.day, value));
          }
        }
        return Scaffold(
          appBar: AppBar(title: Text(widget.name)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (muscle != null) Pill(muscle.label, color: Accent.workouts),
                    for (final m in cat?.secondary ?? const <Muscle>[]) Pill(m.label),
                    if (cat != null) Pill('отдых ${formatRest(cat.restSec)}', icon: Icons.timer_outlined),
                    if (cat?.spineLoad ?? false)
                      const Pill('нагрузка на позвоночник', icon: Icons.warning_amber_rounded, color: Accent.reminders),
                  ],
                ),
              ),
              if (cat?.hint != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(cat!.hint!, style: TextStyle(color: muted, height: 1.35)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(label: 'Лучший подход', value: rec.bestSet == 0 ? '—' : '${rec.bestSet} $u'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Stat(label: 'За тренировку', value: rec.bestTotal == 0 ? '—' : '${rec.bestTotal} $u'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Stat(label: 'Тренировок', value: '${rec.sessions}'),
                    ),
                  ],
                ),
              ),
              if (rec.maxWeight != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Stat(label: 'Макс. вес', value: '${formatNumber(rec.maxWeight!)} кг'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Stat(label: 'Расчётный максимум', value: '${formatNumber(rec.bestMax!)} кг'),
                      ),
                    ],
                  ),
                ),
              SectionTitle(
                'Цель',
                trailing: TextButton(
                  onPressed: () => editSportGoal(context, widget.name, goal),
                  child: Text(goal == null ? 'Поставить' : 'Изменить'),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: goal == null
                      ? Text('Например, 15 подряд. Прогресс к цели виден на вкладке «Прогресс».', style: TextStyle(color: muted))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${rec.bestSet} из $goal $u подряд', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            ProgressLine(value: rec.bestSet / goal, color: rec.bestSet >= goal ? Accent.money : Accent.workouts),
                          ],
                        ),
                ),
              ),
              SectionTitle(
                'Динамика',
                trailing: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('Подход')),
                    ButtonSegment(value: true, label: Text('Всего')),
                  ],
                  selected: {_byTotal},
                  onSelectionChanged: (s) => setState(() => _byTotal = s.first),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: LineChart(points: points, color: Accent.workouts, target: _byTotal ? null : goal?.toDouble()),
                ),
              ),
              if (chain != null) ...[
                const SectionTitle('Лестница усложнения'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        for (final (i, step) in chain.indexed)
                          ListTile(
                            dense: true,
                            leading: NumberBadge(i + 1, color: step == cat!.name ? Accent.workouts : muted, size: 30),
                            title: Text(step, style: TextStyle(fontWeight: step == cat.name ? FontWeight.w700 : FontWeight.w400)),
                            trailing: step == cat.name ? const Pill('сейчас', color: Accent.workouts) : null,
                            onTap: step == cat.name
                                ? null
                                : () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ExerciseScreen(name: step))),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Text(
                            'Когда во всех подходах верхняя граница повторов, переходи на ступень выше и начинай снова с нижней границы.',
                            style: TextStyle(color: muted, fontSize: 13, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SectionTitle('История'),
              if (history.isEmpty) const Card(child: EmptyHint('Это упражнение ещё не делал', icon: Icons.history_rounded)),
              if (history.isNotEmpty)
                GroupCard(
                  children: [
                    for (final h in history.take(30))
                      ListTile(
                        title: Text(formatSets(h.sets)),
                        subtitle: Text('${capitalizeFirst(formatDay(h.session.day))} · ${h.session.programName}'),
                        trailing: Text('${totalReps(h.sets)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionViewScreen(sessionId: h.session.id))),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
