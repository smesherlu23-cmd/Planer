import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/exercise_catalog.dart';
import '../data/queries.dart';
import '../data/workout_queries.dart';
import '../logic/calc.dart';
import '../logic/values.dart';
import '../logic/workout.dart';
import 'common.dart';
import 'theme.dart';
import 'workout_progress.dart';
import 'workout_session_screen.dart';

export 'workout_progress.dart' show ExerciseScreen;
export 'workout_session_screen.dart' show SessionScreen, SessionViewScreen;

/// «Спорт»: обзор недели и программ, история и прогресс.
class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Watch(
      streams: () => [
        db.watchPrograms(),
        db.watchSessions(),
        db.watchAllSets(),
        db.watchAllExercises(),
        db.watchSportGoals(),
        db.watchWorkoutDraft(),
      ],
      builder: (context, v) {
        final data = SportData(
          programs: v[0] as List<Program>,
          sessions: v[1] as List<WorkoutSession>,
          sets: v[2] as List<SessionSet>,
          exercises: v[3] as List<ProgramExercise>,
          goals: v[4] as Map<String, int>,
          draft: v[5] as WorkoutDraft?,
          today: todayKey(),
        );
        return DefaultTabController(
          length: 3,
          child: ScrollFabScope(
            child: Scaffold(
              floatingActionButton: ScrollFab(child: _StartFab(data: data)),
              body: Column(
                children: [
                  PageHeader(
                    overline: data.plannedPerWeek == 0
                        ? 'спорт'
                        : 'дни: ${maskLabel(data.programs.fold<int>(0, (m, p) => m | p.daysMask))}',
                    title: 'Тренировки',
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Обзор'),
                      Tab(text: 'История'),
                      Tab(text: 'Прогресс'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _OverviewTab(data: data),
                        HistoryTab(data: data),
                        ProgressTab(data: data),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Программа, которую стоит делать сейчас: из сегодняшних, иначе ближайшая по расписанию, иначе любая.
Program? nextProgram(SportData data) {
  final active = data.programs;
  if (active.isEmpty) return null;
  for (var i = 0; i < 7; i++) {
    final day = addDays(data.today, i);
    final list = active.where((p) => maskHasDay(p.daysMask, day)).toList();
    if (list.isNotEmpty) return suggestProgram(list, data.sessions);
  }
  return suggestProgram(active, data.sessions);
}

class _StartFab extends StatelessWidget {
  const _StartFab({required this.data});
  final SportData data;

  @override
  Widget build(BuildContext context) {
    final draft = data.draft;
    if (draft != null && data.programs.any((p) => p.id == draft.programId)) {
      return FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: Accent.workouts,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(programId: draft.programId))),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Продолжить'),
      );
    }
    final next = nextProgram(data);
    if (next == null) {
      return FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgramEditScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Программа'),
      );
    }
    return FloatingActionButton.extended(
      heroTag: null,
      backgroundColor: Accent.workouts,
      foregroundColor: Colors.white,
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(programId: next.id))),
      icon: const Icon(Icons.play_arrow_rounded),
      label: Text('Начать: ${next.name}'),
    );
  }
}

// ---------------------------------------------------------------------------
// Обзор
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.data});
  final SportData data;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final today = data.today;
    final weekFrom = weekStart(today);
    final weekSessions = data.sessions.where((s) => s.day >= weekFrom && s.day <= today).toList();
    final doneDays = {for (final s in weekSessions) s.day};
    final plannedDays = data.programs.fold<int>(0, (m, p) => m | p.daysMask);
    final plannedThisWeek = data.plannedPerWeek;
    final streak = weekStreak(sessionDays: data.sessions.map((s) => s.day), perWeek: plannedThisWeek, today: today);
    final next = nextProgram(data);
    final draft = data.draft;
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        if (draft != null) _DraftCard(draft: draft),
        HeroCard(
          colors: dark ? const [Color(0xFFC2410C), Color(0xFFBE185D)] : const [Color(0xFFEA580C), Color(0xFFDB2777)],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'На этой неделе',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (streak > 0) HeroChip('$streak нед. подряд', icon: Icons.local_fire_department_rounded),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                plannedThisWeek == 0
                    ? '${weekSessions.length} ${_trainings(weekSessions.length)}'
                    : '${weekSessions.length} из $plannedThisWeek',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    _WeekDot(
                      label: weekdayShort[i],
                      day: addDays(weekFrom, i),
                      today: today,
                      done: doneDays.contains(addDays(weekFrom, i)),
                      planned: maskHasWeekday(plannedDays, i + 1),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (next != null && draft == null) _NextCard(program: next, data: data),
        SectionTitle(
          'Программы',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () => showReadyPrograms(context),
                icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                label: const Text('Готовые'),
              ),
              IconButton(
                tooltip: 'Новая программа',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgramEditScreen())),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        if (data.programs.isEmpty)
          Card(
            child: EmptyHint(
              'Программа это список упражнений с подходами и повторами. Возьми готовую или собери свою.',
              icon: Icons.fitness_center_rounded,
              action: FilledButton.tonal(onPressed: () => showReadyPrograms(context), child: const Text('Готовые программы')),
            ),
          ),
        for (final p in data.programs) _ProgramCard(program: p, data: data),
      ],
    );
  }
}

/// Незаконченная тренировка: продолжить или удалить.
class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft});
  final WorkoutDraft draft;

  @override
  Widget build(BuildContext context) {
    final done = draft.exercises.fold<int>(0, (a, e) => a + e.sets.where((s) => s.$3).length);
    final minutes = DateTime.now().difference(draft.startedAt).inMinutes;
    return Card(
      color: Accent.workouts.withValues(alpha: 0.14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timelapse_rounded, color: Accent.workouts),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Тренировка не закончена', style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${draft.programName} · подходов: $done · начата ${minutes < 60 ? '$minutes мин' : formatDuration(minutes)} назад',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    if (await confirm(context, 'Удалить незаконченную тренировку?', ok: 'Удалить', danger: true)) {
                      if (context.mounted) await context.db.saveWorkoutDraft(null);
                    }
                  },
                  child: const Text('Удалить'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Accent.workouts, foregroundColor: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(programId: draft.programId))),
                  child: const Text('Продолжить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Следующая тренировка: что будет и что пора усложнить.
class _NextCard extends StatelessWidget {
  const _NextCard({required this.program, required this.data});
  final Program program;
  final SportData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final exercises = data.exercises.where((e) => e.programId == program.id).toList()
      ..sort((a, b) => a.sortOrder != b.sortOrder ? a.sortOrder.compareTo(b.sortOrder) : a.id.compareTo(b.id));
    final today = data.today;
    var when = 'Когда удобно';
    for (var i = 0; i < 7; i++) {
      final d = addDays(today, i);
      if (maskHasDay(program.daysMask, d)) {
        when = i == 0 ? 'Сегодня' : (i == 1 ? 'Завтра' : capitalizeFirst(formatDayLong(d)));
        break;
      }
    }
    final doneToday = data.sessions.any((s) => s.day == today && s.programId == program.id);
    final ready = <String>[];
    for (final e in exercises) {
      final last = data.byExercise[e.name]?.firstOrNull?.sets ?? const <SessionSet>[];
      if (readyToProgress(plannedSets: e.sets, repsMax: e.repsMax, lastReps: [for (final s in last) s.reps])) ready.add(e.name);
    }
    final minutes = estimateMinutes(exercises);
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramDetailScreen(programId: program.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doneToday ? 'СЕГОДНЯ СДЕЛАНО · ДАЛЬШЕ' : 'СЛЕДУЮЩАЯ · ${when.toUpperCase()}',
                style: theme.textTheme.labelMedium?.copyWith(color: Accent.workouts, letterSpacing: 0.6, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(program.name, style: theme.textTheme.titleLarge),
              Text('${exercises.length} упр. · около $minutes мин', style: TextStyle(color: muted)),
              const SizedBox(height: 10),
              for (final e in exercises.take(6))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        ready.contains(e.name) ? Icons.trending_up_rounded : Icons.circle,
                        size: ready.contains(e.name) ? 16 : 6,
                        color: ready.contains(e.name) ? Accent.workouts : muted,
                      ),
                      SizedBox(width: ready.contains(e.name) ? 6 : 11),
                      Expanded(child: Text(e.name, overflow: TextOverflow.ellipsis)),
                      Text(planLabel(e), style: TextStyle(color: muted, fontSize: 13)),
                    ],
                  ),
                ),
              if (ready.isNotEmpty) ...[
                const SizedBox(height: 10),
                Pill(
                  ready.length == 1 ? 'Пора усложнять: ${ready.first}' : 'Пора усложнять: ${ready.length} упр.',
                  icon: Icons.trending_up_rounded,
                  color: Accent.workouts,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Примерная длительность: подход около 40 секунд плюс отдых, и 5 минут разминки.
int estimateMinutes(List<ProgramExercise> exercises) {
  var sec = 300;
  for (final e in exercises) {
    sec += e.sets * 40 + (e.sets - 1).clamp(0, 99) * restOf(e) + 60;
  }
  return (sec / 60 / 5).round() * 5;
}

String _trainings(int n) {
  final mod10 = n % 10, mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return 'тренировка';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'тренировки';
  return 'тренировок';
}

/// День недели в карточке недели: галочка, если тренировка была.
class _WeekDot extends StatelessWidget {
  const _WeekDot({required this.label, required this.day, required this.today, required this.done, required this.planned});
  final String label;
  final int day;
  final int today;
  final bool done;
  final bool planned;

  @override
  Widget build(BuildContext context) {
    final missed = planned && !done && day < today;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: day == today ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? Colors.white : Colors.white.withValues(alpha: planned ? 0.22 : 0.08),
            border: day == today && !done ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: done
              ? const Icon(Icons.check_rounded, color: Color(0xFFEA580C), size: 20)
              : missed
              ? const Icon(Icons.close_rounded, color: Colors.white60, size: 16)
              : null,
        ),
      ],
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program, required this.data});
  final Program program;
  final SportData data;

  @override
  Widget build(BuildContext context) {
    final p = program;
    final theme = Theme.of(context);
    final today = data.today;
    final last = data.sessions.where((s) => s.programId == p.id).firstOrNull;
    final isToday = maskHasDay(p.daysMask, today);
    final doneToday = last?.day == today;
    final count = data.exercises.where((e) => e.programId == p.id).length;
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramDetailScreen(programId: p.id))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              const IconBadge(Icons.fitness_center_rounded, color: Accent.workouts, size: 44, soft: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(p.name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Pill(doneToday ? 'сделано' : 'сегодня', color: doneToday ? Accent.habits : Accent.workouts),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        p.daysMask == 0 ? 'без расписания' : maskLabel(p.daysMask),
                        '$count упр.',
                        if (p.reminderMinutes != null) formatMinutes(p.reminderMinutes!),
                      ].join(' · '),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      last == null ? 'ещё не было' : 'последняя: ${dayLabel(last.day)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: 'Начать',
                style: IconButton.styleFrom(backgroundColor: Accent.workouts, foregroundColor: Colors.white),
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(programId: p.id))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Готовые программы из справочника.
Future<void> showReadyPrograms(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (sheet, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('Готовые программы', style: Theme.of(sheet).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Для дома, без веса на позвоночник. Добавятся как обычные программы: всё можно поменять.',
            style: TextStyle(color: Theme.of(sheet).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (final r in readyPrograms)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: Theme.of(sheet).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      [r.description, if (r.weekdays.isNotEmpty) maskLabel(maskFromWeekdays(r.weekdays))].join(' '),
                      style: TextStyle(color: Theme.of(sheet).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(r.exercises.join(' · '), style: const TextStyle(fontSize: 13, height: 1.35)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final id = await sheet.db.addReadyProgram(r);
                          if (!sheet.mounted) return;
                          Navigator.pop(sheet);
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramDetailScreen(programId: id)));
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Добавить'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Программа
// ---------------------------------------------------------------------------

String planLabel(ProgramExercise e) {
  final reps = e.repsMin == e.repsMax ? '${e.repsMin}' : '${e.repsMin}–${e.repsMax}';
  return '${e.sets} × $reps ${e.unit}';
}

class ProgramDetailScreen extends StatelessWidget {
  const ProgramDetailScreen({super.key, required this.programId});
  final int programId;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Watch(
      deps: [programId],
      streams: () => [(db.select(db.programs)..where((t) => t.id.equals(programId))).watchSingleOrNull(), db.watchExercises(programId)],
      builder: (context, v) {
        final p = v[0] as Program?;
        if (p == null) return const Scaffold(body: Center(child: Text('Программа удалена')));
        final exercises = v[1] as List<ProgramExercise>;
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        final muscles = <Muscle>{for (final e in exercises) ?muscleOf(e.name, e.muscle)};
        return ScrollFabScope(
          child: Scaffold(
            appBar: AppBar(
              title: Text(p.name),
              actions: [
                IconButton(
                  tooltip: 'Изменить',
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramEditScreen(program: p))),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'copy') {
                      final id = await db.duplicateProgram(p);
                      if (context.mounted) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProgramDetailScreen(programId: id)));
                      }
                    }
                  },
                  itemBuilder: (_) => const [PopupMenuItem(value: 'copy', child: Text('Сделать копию'))],
                ),
              ],
            ),
            floatingActionButton: ScrollFab(
              child: exercises.isEmpty
                  ? null
                  : FloatingActionButton.extended(
                      heroTag: null,
                      backgroundColor: Accent.workouts,
                      foregroundColor: Colors.white,
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(programId: p.id))),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Начать'),
                    ),
            ),
            body: ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Pill(p.daysMask == 0 ? 'без расписания' : maskLabel(p.daysMask), color: Accent.workouts),
                      if (p.reminderMinutes != null) Pill(formatMinutes(p.reminderMinutes!), icon: Icons.alarm_rounded),
                      Pill('${exercises.length} упр.'),
                      if (exercises.isNotEmpty) Pill('около ${estimateMinutes(exercises)} мин', icon: Icons.timer_outlined),
                      for (final m in muscles) Pill(m.label),
                    ],
                  ),
                ),
                if (p.note != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Text(p.note!, style: TextStyle(color: muted, height: 1.4)),
                  ),
                SectionTitle(
                  'Упражнения',
                  trailing: IconButton(
                    tooltip: 'Упражнение',
                    onPressed: () => editExercise(context, p.id, null),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                if (exercises.isEmpty)
                  Card(
                    child: EmptyHint(
                      'Добавь первое упражнение',
                      icon: Icons.fitness_center_rounded,
                      action: FilledButton.tonal(onPressed: () => editExercise(context, p.id, null), child: const Text('Добавить')),
                    ),
                  ),
                if (exercises.isNotEmpty)
                  Card(
                    child: ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorderItem: (from, to) {
                        final ids = [for (final e in exercises) e.id];
                        final id = ids.removeAt(from);
                        ids.insert(to, id);
                        db.reorderExercises(ids);
                      },
                      children: [
                        for (final (i, e) in exercises.indexed)
                          ListTile(
                            key: ValueKey(e.id),
                            leading: SizedBox(
                              width: 40,
                              child: Center(child: NumberBadge(i + 1, color: Accent.workouts)),
                            ),
                            title: Text(e.name),
                            subtitle: Text(
                              [
                                [planLabel(e), 'отдых ${formatRest(restOf(e))}', ?muscleOf(e.name, e.muscle)?.label].join(' · '),
                                if (e.note != null) e.note!,
                              ].join('\n'),
                            ),
                            isThreeLine: e.note != null,
                            onTap: () => editExercise(context, p.id, e),
                            trailing: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle_rounded)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

const _restOptions = [30, 45, 60, 90, 120, 180];

Future<void> editExercise(BuildContext context, int programId, ProgramExercise? e) async {
  // Новое упражнение: сначала выбрать из справочника, потом поправить цифры.
  String? picked;
  if (e == null) {
    picked = await pickExerciseName(context);
    if (picked == null || !context.mounted) return;
  }
  final cat = catalogExercise(picked ?? e!.name);
  final name = TextEditingController(text: e?.name ?? cat?.name ?? picked);
  final sets = TextEditingController(text: '${e?.sets ?? cat?.sets ?? 3}');
  final min = TextEditingController(text: '${e?.repsMin ?? cat?.repsMin ?? 8}');
  final max = TextEditingController(text: '${e?.repsMax ?? cat?.repsMax ?? 12}');
  final note = TextEditingController(text: e?.note ?? cat?.hint ?? '');
  var unit = e?.unit ?? cat?.unit ?? 'повт';
  var rest = e != null ? restOf(e) : cat?.restSec ?? 90;
  var muscle = muscleOf(name.text, e?.muscle);
  Widget intField(TextEditingController c, String label) => Expanded(
    child: TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    ),
  );
  if (!context.mounted) return;
  await showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Упражнение'),
          ),
          if (cat?.spineLoad ?? false) ...[
            const SizedBox(height: 8),
            const Pill(
              'Осевая нагрузка на позвоночник: только если разрешил врач',
              icon: Icons.warning_amber_rounded,
              color: Accent.reminders,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              intField(sets, 'Подходы'),
              const SizedBox(width: 8),
              intField(min, 'От'),
              const SizedBox(width: 8),
              intField(max, 'До'),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'повт', label: Text('Повторы')),
              ButtonSegment(value: 'сек', label: Text('Секунды')),
            ],
            selected: {unit},
            onSelectionChanged: (s) => setState(() => unit = s.first),
          ),
          const SizedBox(height: 16),
          Text('Отдых между подходами', style: Theme.of(sheet).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in _restOptions)
                ChoiceChip(label: Text(formatRest(r)), selected: rest == r, onSelected: (_) => setState(() => rest = r)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Мышцы', style: Theme.of(sheet).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in Muscle.values)
                ChoiceChip(label: Text(m.label), selected: muscle == m, onSelected: (s) => setState(() => muscle = s ? m : null)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Подсказка: техника, как усложнить'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final s = int.tryParse(sets.text) ?? 0;
              final lo = int.tryParse(min.text) ?? 0;
              final hi = int.tryParse(max.text) ?? lo;
              if (name.text.trim().isEmpty || s <= 0 || lo <= 0) return showSnack(sheet, 'Заполни название, подходы и повторы');
              final n = name.text.trim();
              // Мышцу храним, только если она отличается от справочника: тогда справочник можно улучшать.
              final catMuscle = catalogExercise(n)?.muscle;
              await sheet.db.saveExercise(
                ProgramExercisesCompanion(
                  id: e == null ? const Value.absent() : Value(e.id),
                  programId: Value(programId),
                  name: Value(n),
                  sets: Value(s),
                  repsMin: Value(lo),
                  repsMax: Value(hi < lo ? lo : hi),
                  unit: Value(unit),
                  note: Value(emptyToNull(note.text)),
                  restSec: Value(rest == catalogExercise(n)?.restSec ? null : rest),
                  muscle: Value(muscle == catMuscle ? null : muscle?.name),
                ),
              );
              if (sheet.mounted) Navigator.pop(sheet);
            },
            child: const Text('Сохранить'),
          ),
          if (e != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(sheet).colorScheme.error),
              onPressed: () async {
                await sheet.db.deleteById(sheet.db.programExercises, e.id);
                if (sheet.mounted) Navigator.pop(sheet);
              },
              child: const Text('Удалить упражнение'),
            ),
        ],
      ),
    ),
  );
}

class ProgramEditScreen extends StatefulWidget {
  const ProgramEditScreen({super.key, this.program});
  final Program? program;

  @override
  State<ProgramEditScreen> createState() => _ProgramEditScreenState();
}

class _ProgramEditScreenState extends State<ProgramEditScreen> {
  late final _name = TextEditingController(text: widget.program?.name ?? '');
  late final _note = TextEditingController(text: widget.program?.note ?? '');
  late final _minSets = TextEditingController(text: '${widget.program?.minSets ?? 1}');
  late final _minimum = TextEditingController(text: widget.program?.minimumText ?? '');
  late int _mask = widget.program?.daysMask ?? 0;
  late int? _reminder = widget.program?.reminderMinutes;

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return showSnack(context, 'Введи название');
    final id = await context.db.saveProgram(
      ProgramsCompanion(
        id: widget.program == null ? const Value.absent() : Value(widget.program!.id),
        name: Value(_name.text.trim()),
        daysMask: Value(_mask),
        reminderMinutes: Value(_mask == 0 ? null : _reminder),
        note: Value(emptyToNull(_note.text)),
        minSets: Value(int.tryParse(_minSets.text.trim())?.clamp(1, 20)),
        minimumText: Value(emptyToNull(_minimum.text)),
      ),
    );
    if (!mounted) return;
    if (widget.program == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProgramDetailScreen(programId: id)));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final p = widget.program;
    return Scaffold(
      appBar: AppBar(title: Text(p == null ? 'Новая программа' : 'Программа')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            autofocus: p == null,
            decoration: const InputDecoration(labelText: 'Название'),
          ),
          const SizedBox(height: 20),
          Text('Дни', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          const Text('Если у двух программ одни и те же дни, предложена будет та, что была давно. Так A и B чередуются сами.'),
          const SizedBox(height: 8),
          DaysPicker(mask: _mask, onChanged: (m) => setState(() => _mask = m)),
          TextButton(onPressed: () => setState(() => _mask = 0), child: const Text('Без расписания')),
          if (_mask != 0) ReminderTile(minutes: _reminder, onChanged: (m) => setState(() => _reminder = m)),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Заметка: разминка, правила'),
          ),
          const SizedBox(height: 20),
          Text('Минимум на тяжёлый день', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          const Text('Облегчённая версия: меньше подходов. Она тоже засчитывается, но отмечается как минимум.'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _minSets,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Подходов'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _minimum,
                  decoration: const InputDecoration(labelText: 'Что ещё сделать', hintText: 'Разминка и спина'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Сохранить')),
          if (p != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.archive_outlined),
              label: const Text('В архив'),
              onPressed: () async {
                await db.setArchived(db.programs, p.id, true);
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Удалить программу'),
              onPressed: () async {
                if (await confirm(context, 'Удалить «${p.name}»?', text: 'История тренировок останется.', ok: 'Удалить', danger: true)) {
                  await db.deleteById(db.programs, p.id);
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
