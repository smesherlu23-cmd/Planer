import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/exercise_catalog.dart';
import '../data/queries.dart';
import '../data/workout_queries.dart';
import '../logic/calc.dart';
import '../logic/minimum.dart';
import '../logic/workout.dart';
import 'common.dart';
import 'theme.dart';
import 'workout_progress.dart';

// ---------------------------------------------------------------------------
// Проведение тренировки
// ---------------------------------------------------------------------------

/// Тренировка по программе: подходы с галочками, таймер отдыха, подсказки прогрессии.
/// Всё введённое сразу сохраняется в черновик, поэтому закрыть приложение посреди тренировки не страшно.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.programId, this.light = false});
  final int programId;

  /// Облегчённая версия на тяжёлый день: меньше подходов.
  final bool light;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SetRow {
  _SetRow({required this.target, int? reps, double? weight, this.done = false})
    : reps = TextEditingController(text: reps?.toString() ?? ''),
      weight = TextEditingController(text: weight == null ? '' : formatNumber(weight));

  int target;
  final TextEditingController reps;
  final TextEditingController weight;
  bool done;

  /// Секундомер для упражнений на время.
  DateTime? runningSince;

  int? get value => int.tryParse(reps.text.trim());

  void dispose() {
    reps.dispose();
    weight.dispose();
  }
}

class _ExerciseState {
  _ExerciseState({
    required this.exerciseId,
    required this.name,
    required this.plannedSets,
    required this.repsMin,
    required this.repsMax,
    required this.unit,
    required this.rest,
    required this.note,
    required this.muscle,
    required this.history,
  });

  final int? exerciseId;
  final String name;
  final int plannedSets;
  final int repsMin;
  final int repsMax;
  final String unit;
  final int rest;
  final String? note;
  final Muscle? muscle;

  /// Прошлые тренировки с этим упражнением, от новых к старым.
  final List<ExerciseSession> history;
  final rows = <_SetRow>[];
  late Advice advice;
  var showWeight = false;

  List<SessionSet> get last => history.isEmpty ? const [] : history.first.sets;
  bool get timed => unit == 'сек';
  ExerciseRecords get records => recordsOf(history.expand((h) => h.sets));

  int targetFor(int i) {
    if (i < advice.targets.length) return advice.targets[i];
    return advice.targets.isEmpty ? repsMin : advice.targets.last;
  }

  void addRow({int? reps, double? weight, bool done = false}) {
    final i = rows.length;
    final w = weight ?? (i < last.length ? last[i].weight : (last.isNotEmpty ? last.last.weight : null));
    rows.add(_SetRow(target: targetFor(i), reps: reps, weight: w, done: done));
  }
}

class _SessionScreenState extends State<SessionScreen> {
  Program? _program;
  List<_ExerciseState>? _exercises;
  final _note = TextEditingController();
  var _day = todayKey();
  var _saving = false;
  late var _light = widget.light;
  late DateTime _startedAt = DateTime.now();

  /// Отдых: когда закончится и сколько длился.
  DateTime? _restEnd;
  var _restTotal = 0;
  final _tick = ValueNotifier(0);
  Timer? _ticker;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _saveDebounce?.cancel();
    _tick.dispose();
    _note.dispose();
    for (final e in _exercises ?? const <_ExerciseState>[]) {
      for (final r in e.rows) {
        r.dispose();
      }
    }
    super.dispose();
  }

  void _onTick() {
    _tick.value++;
    final end = _restEnd;
    if (end != null && !DateTime.now().isBefore(end)) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      setState(() => _restEnd = null);
    }
  }

  Future<void> _load() async {
    final db = context.db;
    final p = await (db.select(db.programs)..where((t) => t.id.equals(widget.programId))).getSingle();
    final draft = await db.workoutDraft();
    if (draft != null && draft.programId != p.id && mounted) {
      final replace = await confirm(
        context,
        'Есть незаконченная тренировка',
        text: '«${draft.programName}» не сохранена. Удалить её и начать «${p.name}»?',
        ok: 'Начать новую',
        danger: true,
      );
      if (!replace) {
        if (mounted) Navigator.pop(context);
        return;
      }
    }
    final resume = draft != null && draft.programId == p.id ? draft : null;
    final exercises = await db.exercisesOf(p.id);
    final states = <_ExerciseState>[];
    Future<_ExerciseState> build(ProgramExercise? e, {String? name}) async {
      final n = e?.name ?? name!;
      final cat = catalogExercise(n);
      final history = await db.exerciseHistory(n);
      final st = _ExerciseState(
        exerciseId: e?.id,
        name: n,
        plannedSets: e?.sets ?? cat?.sets ?? 3,
        repsMin: e?.repsMin ?? cat?.repsMin ?? 8,
        repsMax: e?.repsMax ?? cat?.repsMax ?? 12,
        unit: e?.unit ?? cat?.unit ?? 'повт',
        rest: e != null ? restOf(e) : cat?.restSec ?? 90,
        note: e?.note ?? cat?.hint,
        muscle: muscleOf(n, e?.muscle),
        history: history,
      );
      st.advice = adviseNext(
        name: n,
        sets: st.plannedSets,
        repsMin: st.repsMin,
        repsMax: st.repsMax,
        unit: st.unit,
        last: [for (final s in st.last) s.reps],
        history: [for (final h in history.reversed.take(8)) totalReps(h.sets)],
        note: st.note,
        weighted: st.last.any((s) => (s.weight ?? 0) > 0),
      );
      st.showWeight = st.last.any((s) => (s.weight ?? 0) > 0);
      return st;
    }

    if (resume != null) {
      for (final d in resume.exercises) {
        final e = exercises.where((x) => x.id == d.exerciseId).firstOrNull;
        final st = await build(e, name: d.name);
        for (final (r, w, done) in d.sets) {
          st.addRow(reps: r, weight: w, done: done);
        }
        if (d.sets.any((s) => s.$2 != null)) st.showWeight = true;
        states.add(st);
      }
    } else {
      for (final e in exercises) {
        final st = await build(e);
        final n = _light ? lightSets(p, e) : e.sets;
        for (var i = 0; i < n; i++) {
          st.addRow();
        }
        states.add(st);
      }
    }
    if (!mounted) return;
    setState(() {
      _program = p;
      _exercises = states;
      if (resume != null) {
        _startedAt = resume.startedAt;
        _day = resume.day;
        _light = resume.light;
        _note.text = resume.note;
      }
    });
    if (resume == null) _persist();
  }

  /// Сохранить черновик через полсекунды после последнего изменения.
  void _changed() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _persist);
  }

  Future<void> _persist() async {
    final p = _program, list = _exercises;
    if (p == null || list == null) return;
    await context.db.saveWorkoutDraft(
      WorkoutDraft(
        programId: p.id,
        programName: p.name,
        startedAt: _startedAt,
        day: _day,
        light: _light,
        note: _note.text,
        exercises: [
          for (final e in list)
            DraftExercise(
              exerciseId: e.exerciseId,
              name: e.name,
              sets: [for (final r in e.rows) (r.value, e.showWeight ? parseNumber(r.weight.text) : null, r.done)],
            ),
        ],
      ),
    );
  }

  /// Переключить облегчённую версию: убрать лишние пустые подходы или вернуть их.
  Future<void> _setLight(bool light) async {
    final exercises = await context.db.exercisesOf(_program!.id);
    setState(() {
      _light = light;
      for (final st in _exercises!) {
        final e = exercises.where((x) => x.id == st.exerciseId).firstOrNull;
        if (e == null) continue;
        final want = light ? lightSets(_program!, e) : e.sets;
        while (st.rows.length < want) {
          st.addRow();
        }
        while (st.rows.length > want && !st.rows.last.done && st.rows.last.reps.text.trim().isEmpty) {
          _disposeLater(st.rows.removeLast());
        }
      }
    });
    _changed();
  }

  /// Поле ещё нарисовано в этом кадре: освобождаем контроллеры после него.
  void _disposeLater(_SetRow r) => WidgetsBinding.instance.addPostFrameCallback((_) => r.dispose());

  void _toggleDone(_ExerciseState e, _SetRow r) {
    setState(() {
      if (r.done) {
        r.done = false;
      } else {
        if (r.value == null || r.value == 0) r.reps.text = '${r.target}';
        r.done = true;
        r.runningSince = null;
        _startRest(e.rest);
      }
    });
    HapticFeedback.selectionClick();
    _changed();
  }

  void _startRest(int seconds) {
    if (seconds <= 0) return;
    _restTotal = seconds;
    _restEnd = DateTime.now().add(Duration(seconds: seconds));
  }

  void _toggleStopwatch(_ExerciseState e, _SetRow r) {
    setState(() {
      if (r.runningSince == null) {
        r.runningSince = DateTime.now();
        _restEnd = null;
      } else {
        final secs = DateTime.now().difference(r.runningSince!).inSeconds;
        r.runningSince = null;
        r.reps.text = '$secs';
        r.done = true;
        _startRest(e.rest);
      }
    });
    _changed();
  }

  Future<void> _addExercise() async {
    final used = {for (final e in _exercises!) e.name.toLowerCase()};
    final name = await pickExerciseName(context, exclude: used);
    if (name == null || !mounted) return;
    final cat = catalogExercise(name);
    final history = await context.db.exerciseHistory(name);
    final st = _ExerciseState(
      exerciseId: null,
      name: cat?.name ?? name,
      plannedSets: cat?.sets ?? 3,
      repsMin: cat?.repsMin ?? 8,
      repsMax: cat?.repsMax ?? 12,
      unit: cat?.unit ?? 'повт',
      rest: cat?.restSec ?? 90,
      note: cat?.hint,
      muscle: cat?.muscle,
      history: history,
    );
    st.advice = adviseNext(
      name: st.name,
      sets: st.plannedSets,
      repsMin: st.repsMin,
      repsMax: st.repsMax,
      unit: st.unit,
      last: [for (final s in st.last) s.reps],
    );
    for (var i = 0; i < st.plannedSets; i++) {
      st.addRow();
    }
    setState(() => _exercises!.add(st));
    _changed();
  }

  int get _doneSets => _exercises?.fold<int>(0, (a, e) => a + e.rows.where((r) => r.done).length) ?? 0;
  int get _totalSets => _exercises?.fold<int>(0, (a, e) => a + e.rows.length) ?? 0;

  Future<void> _finish() async {
    final list = _exercises!;
    final sets = <SessionSetsCompanion>[];
    for (final e in list) {
      var index = 0;
      for (final r in e.rows) {
        final reps = r.value;
        if (!r.done || reps == null || reps <= 0) continue;
        sets.add(
          SessionSetsCompanion.insert(
            sessionId: 0, // заменится при сохранении
            exerciseId: Value(e.exerciseId),
            exerciseName: e.name,
            setIndex: index++,
            reps: reps,
            weight: Value(e.showWeight ? parseNumber(r.weight.text) : null),
          ),
        );
      }
    }
    if (sets.isEmpty) return showSnack(context, 'Отметь галочкой хотя бы один сделанный подход');
    final left = _totalSets - _doneSets;
    if (left > 0 &&
        !await confirm(
          context,
          'Завершить тренировку?',
          text: 'Не отмечено подходов: $left. Сохранятся только отмеченные.',
          ok: 'Завершить',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => _saving = true);
    final db = context.db;
    final program = _program!;
    final planned = (await db.exercisesOf(program.id)).fold<int>(0, (a, e) => a + e.sets);
    final minimum = sessionIsMinimum(plannedSets: planned, doneSets: sets.length);
    final duration = DateTime.now().difference(_startedAt).inSeconds.clamp(0, 5 * 3600);
    final id = await db.saveWorkout(
      programId: program.id,
      programName: program.name,
      day: _day,
      sets: sets,
      note: emptyToNull(_note.text),
      minimum: minimum,
      durationSec: duration,
    );
    await db.saveWorkoutDraft(null);
    // Рекорды и сравнение с прошлым разом.
    final records = <String>[];
    final compare = <(String, int now, int? before, String unit)>[];
    for (final e in list) {
      final now = [
        for (final s in sets)
          if (s.exerciseName.value == e.name)
            SessionSet(id: 0, sessionId: id, exerciseName: e.name, setIndex: s.setIndex.value, reps: s.reps.value, weight: s.weight.value),
      ];
      if (now.isEmpty) continue;
      for (final r in newRecords(e.unit, e.history.expand((h) => h.sets), now)) {
        records.add('${e.name}: $r');
      }
      compare.add((e.name, totalReps(now), e.last.isEmpty ? null : totalReps(e.last), e.unit));
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          sessionId: id,
          durationSec: duration,
          sets: sets.length,
          minimum: minimum,
          records: records,
          compare: compare,
          tonnage: tonnage([
            for (final s in sets)
              SessionSet(id: 0, sessionId: id, exerciseName: '', setIndex: 0, reps: s.reps.value, weight: s.weight.value),
          ]),
        ),
      ),
    );
  }

  /// Выход посреди тренировки: оставить черновик или удалить.
  Future<void> _leave() async {
    final touched = _exercises?.any((e) => e.rows.any((r) => r.done || r.reps.text.trim().isNotEmpty)) ?? false;
    if (!touched) {
      await context.db.saveWorkoutDraft(null);
      if (mounted) Navigator.pop(context);
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из тренировки?'),
        content: const Text('Можно вернуться к ней позже: всё отмеченное сохранено.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, 'drop'),
            child: const Text('Удалить'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Остаться')),
          FilledButton(onPressed: () => Navigator.pop(context, 'later'), child: const Text('Позже')),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    _saveDebounce?.cancel();
    if (choice == 'drop') {
      await context.db.saveWorkoutDraft(null);
    } else {
      await _persist();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final list = _exercises;
    final p = _program;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p?.name ?? 'Тренировка', overflow: TextOverflow.ellipsis),
              ValueListenableBuilder(
                valueListenable: _tick,
                builder: (context, _, _) => Text(
                  formatClock(DateTime.now().difference(_startedAt).inSeconds.clamp(0, 99 * 3600)),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (list != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChip(label: const Text('Минимум'), selected: _light, onSelected: _setLight),
              ),
          ],
        ),
        bottomNavigationBar: list == null ? null : _bottomBar(context),
        body: list == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (_light)
                    Card(
                      color: Accent.reminders.withValues(alpha: 0.14),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          [
                            'Облегчённая версия: по ${p!.minSets ?? 1} подх. на упражнение.',
                            ?p.minimumText,
                            'Сохранится как минимум.',
                          ].join(' '),
                          style: const TextStyle(height: 1.35),
                        ),
                      ),
                    ),
                  if (p!.note != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Text(p.note!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
                    ),
                  for (final (i, e) in list.indexed)
                    _ExerciseCard(
                      index: i,
                      state: e,
                      tick: _tick,
                      onToggle: (r) => _toggleDone(e, r),
                      onStopwatch: (r) => _toggleStopwatch(e, r),
                      onChanged: _changed,
                      onAddSet: () {
                        setState(() => e.addRow());
                        _changed();
                      },
                      onRemoveSet: e.rows.length <= 1
                          ? null
                          : () {
                              setState(() => _disposeLater(e.rows.removeLast()));
                              _changed();
                            },
                      onShowWeight: () {
                        setState(() => e.showWeight = true);
                        _changed();
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: OutlinedButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Добавить упражнение'),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        children: [
                          DayTile(
                            day: _day,
                            onChanged: (d) {
                              setState(() => _day = d ?? _day);
                              _changed();
                            },
                          ),
                          TextField(
                            controller: _note,
                            onChanged: (_) => _changed(),
                            decoration: const InputDecoration(labelText: 'Заметка (необязательно)'),
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

  Widget _bottomBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _totalSets, done = _doneSets;
    return SafeArea(
      child: Material(
        color: scheme.surfaceContainer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_restEnd != null)
              ValueListenableBuilder(
                valueListenable: _tick,
                builder: (context, _, _) {
                  final left = _restEnd == null ? 0 : _restEnd!.difference(DateTime.now()).inSeconds + 1;
                  return Container(
                    color: Accent.workouts.withValues(alpha: 0.14),
                    padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Accent.workouts),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Отдых ${formatClock(left.clamp(0, 3600))}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(height: 4),
                              ProgressLine(value: _restTotal == 0 ? 0 : 1 - left / _restTotal, color: Accent.workouts, height: 5),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => setState(() => _restEnd = _restEnd!.subtract(const Duration(seconds: 15))),
                          child: const Text('−15'),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _restEnd = _restEnd!.add(const Duration(seconds: 15));
                            _restTotal += 15;
                          }),
                          child: const Text('+15'),
                        ),
                        IconButton(
                          tooltip: 'Пропустить отдых',
                          onPressed: () => setState(() => _restEnd = null),
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                      ],
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Подходов: $done из $total', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ProgressLine(value: total == 0 ? 0 : done / total, color: Accent.habits, height: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Accent.workouts, foregroundColor: Colors.white),
                    onPressed: _saving ? null : _finish,
                    icon: const Icon(Icons.flag_rounded),
                    label: const Text('Завершить'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.index,
    required this.state,
    required this.tick,
    required this.onToggle,
    required this.onStopwatch,
    required this.onChanged,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onShowWeight,
  });
  final int index;
  final _ExerciseState state;
  final ValueNotifier<int> tick;
  final void Function(_SetRow) onToggle;
  final void Function(_SetRow) onStopwatch;
  final VoidCallback onChanged;
  final VoidCallback onAddSet;
  final VoidCallback? onRemoveSet;
  final VoidCallback onShowWeight;

  @override
  Widget build(BuildContext context) {
    final e = state;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final allDone = e.rows.isNotEmpty && e.rows.every((r) => r.done);
    final reps = e.repsMin == e.repsMax ? '${e.repsMin}' : '${e.repsMin}–${e.repsMax}';
    final rec = e.records;
    final (adviceColor, adviceIcon) = switch (e.advice.kind) {
      AdviceKind.levelUp => (Accent.workouts, Icons.trending_up_rounded),
      AdviceKind.stalled => (Accent.reminders, Icons.pause_circle_outline_rounded),
      AdviceKind.tooHard => (Accent.reminders, Icons.south_rounded),
      _ => (Accent.trackers, Icons.flag_outlined),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseScreen(name: e.name))),
              child: Row(
                children: [
                  allDone
                      ? const IconBadge(Icons.check_rounded, color: Accent.habits, size: 36)
                      : NumberBadge(index + 1, color: Accent.workouts),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name, style: theme.textTheme.titleMedium),
                        Text(
                          [
                            '${e.plannedSets} × $reps ${e.unit}',
                            'отдых ${formatRest(e.rest)}',
                            if (rec.bestSet > 0) 'рекорд ${rec.bestSet}',
                          ].join(' · '),
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(color: adviceColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(adviceIcon, color: adviceColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.advice.text, style: const TextStyle(height: 1.3, fontSize: 13))),
                ],
              ),
            ),
            if (e.note != null && e.advice.kind != AdviceKind.levelUp)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(e.note!, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.3, fontSize: 13)),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                children: [
                  _head(context, 'Подх.', 40),
                  _head(context, 'Прошлый', 64),
                  Expanded(child: Center(child: _head(context, e.timed ? 'Секунды' : 'Повторы', null))),
                  if (e.showWeight) _head(context, 'Кг', 64),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            for (final (i, r) in e.rows.indexed)
              _SetRowView(
                index: i,
                row: r,
                last: i < e.last.length ? e.last[i] : null,
                timed: e.timed,
                showWeight: e.showWeight,
                tick: tick,
                onToggle: () => onToggle(r),
                onStopwatch: () => onStopwatch(r),
                onChanged: onChanged,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Accent.workouts, padding: const EdgeInsets.symmetric(horizontal: 8)),
                  onPressed: onAddSet,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Подход'),
                ),
                if (onRemoveSet != null)
                  IconButton(
                    tooltip: 'Убрать подход',
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemoveSet,
                    icon: Icon(Icons.remove_rounded, size: 18, color: scheme.onSurfaceVariant),
                  ),
                const Spacer(),
                if (!e.showWeight)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: onShowWeight,
                    icon: const Icon(Icons.fitness_center_rounded, size: 16),
                    label: const Text('С весом'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _head(BuildContext context, String text, double? width) {
    final t = Text(
      text,
      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
    );
    return width == null ? t : SizedBox(width: width, child: t);
  }
}

class _SetRowView extends StatelessWidget {
  const _SetRowView({
    required this.index,
    required this.row,
    required this.last,
    required this.timed,
    required this.showWeight,
    required this.tick,
    required this.onToggle,
    required this.onStopwatch,
    required this.onChanged,
  });
  final int index;
  final _SetRow row;
  final SessionSet? last;
  final bool timed;
  final bool showWeight;
  final ValueNotifier<int> tick;
  final VoidCallback onToggle;
  final VoidCallback onStopwatch;
  final VoidCallback onChanged;

  void _step(int delta) {
    final v = (row.value ?? row.target) + delta;
    row.reps.text = '${v < 0 ? 0 : v}';
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = row.done;
    final lastText = last == null ? '—' : '${last!.reps}${(last!.weight ?? 0) > 0 ? ' × ${formatNumber(last!.weight!)}' : ''}';
    final step = timed ? 5 : 1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(color: done ? Accent.habits.withValues(alpha: 0.12) : null, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(fontWeight: FontWeight.w700, color: done ? Accent.habits : scheme.onSurfaceVariant),
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              lastText,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundIcon(icon: Icons.remove_rounded, onTap: done ? null : () => _step(-step)),
                SizedBox(
                  width: 46,
                  child: TextField(
                    controller: row.reps,
                    enabled: !done,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    onChanged: (_) => onChanged(),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    decoration: InputDecoration(
                      hintText: '${row.target}',
                      hintStyle: TextStyle(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                _RoundIcon(icon: Icons.add_rounded, onTap: done ? null : () => _step(step)),
              ],
            ),
          ),
          if (showWeight)
            SizedBox(
              width: 64,
              child: TextField(
                controller: row.weight,
                enabled: !done,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                onChanged: (_) => onChanged(),
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: '0',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                ),
              ),
            ),
          const SizedBox(width: 4),
          if (timed && !done)
            ValueListenableBuilder(
              valueListenable: tick,
              builder: (context, _, _) {
                final since = row.runningSince;
                return SizedBox(
                  width: 44,
                  child: IconButton.filledTonal(
                    tooltip: since == null ? 'Секундомер' : 'Стоп',
                    onPressed: onStopwatch,
                    icon: since == null
                        ? const Icon(Icons.play_arrow_rounded)
                        : Text(
                            '${DateTime.now().difference(since).inSeconds}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                  ),
                );
              },
            )
          else
            SizedBox(
              width: 44,
              child: IconButton.filled(
                tooltip: done ? 'Снять отметку' : 'Подход сделан',
                onPressed: onToggle,
                style: IconButton.styleFrom(
                  backgroundColor: done ? Accent.habits : scheme.surfaceContainerHighest,
                  foregroundColor: done ? Colors.white : scheme.onSurfaceVariant,
                ),
                icon: const Icon(Icons.check_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)),
      ),
    );
  }
}

/// Выбрать упражнение: из справочника, из своих прошлых или ввести новое.
Future<String?> pickExerciseName(BuildContext context, {Set<String> exclude = const {}}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ExercisePicker(exclude: exclude),
  );
}

class _ExercisePicker extends StatefulWidget {
  const _ExercisePicker({required this.exclude});
  final Set<String> exclude;

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  final _query = TextEditingController();
  Muscle? _muscle;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final items = [
      for (final e in exerciseCatalog)
        if (!widget.exclude.contains(e.name.toLowerCase()) &&
            (_muscle == null || e.muscle == _muscle) &&
            (q.isEmpty || e.name.toLowerCase().contains(q)))
          e,
    ];
    final exact = exerciseCatalog.any((e) => e.name.toLowerCase() == q);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: false,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Название упражнения'),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final m in Muscle.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(m.label),
                        selected: _muscle == m,
                        onSelected: (s) => setState(() => _muscle = s ? m : null),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (q.isNotEmpty && !exact)
                    ListTile(
                      leading: const Icon(Icons.add_rounded),
                      title: Text('Своё: «${_query.text.trim()}»'),
                      onTap: () => Navigator.pop(context, _query.text.trim()),
                    ),
                  for (final e in items)
                    ListTile(
                      title: Text(e.name),
                      subtitle: Text(
                        [
                          e.muscle.label,
                          '${e.sets} × ${e.repsMin == e.repsMax ? e.repsMin : '${e.repsMin}–${e.repsMax}'} ${e.unit}',
                          if (e.spineLoad) 'нагрузка на позвоночник',
                        ].join(' · '),
                      ),
                      onTap: () => Navigator.pop(context, e.name),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Итоги тренировки
// ---------------------------------------------------------------------------

const feelLabels = ['Тяжело', 'Так себе', 'Нормально', 'Хорошо', 'Отлично'];
const feelIcons = [
  Icons.sentiment_very_dissatisfied_rounded,
  Icons.sentiment_dissatisfied_rounded,
  Icons.sentiment_neutral_rounded,
  Icons.sentiment_satisfied_rounded,
  Icons.sentiment_very_satisfied_rounded,
];

class WorkoutSummaryScreen extends StatefulWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.sessionId,
    required this.durationSec,
    required this.sets,
    required this.minimum,
    required this.records,
    required this.compare,
    required this.tonnage,
  });
  final int sessionId;
  final int durationSec;
  final int sets;
  final bool minimum;
  final List<String> records;
  final List<(String name, int now, int? before, String unit)> compare;
  final double tonnage;

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  int? _feel;
  final _note = TextEditingController();

  Future<void> _done() async {
    await context.db.updateSessionInfo(widget.sessionId, feel: _feel, note: emptyToNull(_note.text));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final reps = widget.compare.fold<int>(0, (a, c) => a + (c.$4 == 'сек' ? 0 : c.$2));
    return Scaffold(
      appBar: AppBar(title: const Text('Итоги'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          HeroCard(
            colors: dark ? const [Color(0xFFC2410C), Color(0xFFBE185D)] : const [Color(0xFFEA580C), Color(0xFFDB2777)],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.minimum ? 'Минимум сделан. Это тоже засчитывается' : 'Тренировка завершена',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(formatClock(widget.durationSec), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: HeroStat(label: 'Подходов', value: '${widget.sets}'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HeroStat(label: 'Повторов', value: '$reps'),
                    ),
                    if (widget.tonnage > 0) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: HeroStat(label: 'Тоннаж', value: '${formatNumber(widget.tonnage, maxDecimals: 0)} кг'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (widget.records.isNotEmpty) ...[
            const SectionTitle('Новые рекорды'),
            GroupCard(
              children: [
                for (final r in widget.records)
                  ListTile(
                    leading: const IconBadge(Icons.emoji_events_rounded, color: Accent.money, soft: true),
                    title: Text(r),
                  ),
              ],
            ),
          ],
          const SectionTitle('В сравнении с прошлым разом'),
          GroupCard(
            children: [
              for (final (name, now, before, unit) in widget.compare)
                ListTile(
                  title: Text(name),
                  subtitle: Text('$now ${unit == 'сек' ? 'сек' : 'повт.'} за тренировку'),
                  trailing: before == null
                      ? const Pill('впервые')
                      : Pill(
                          now == before ? 'как в прошлый раз' : '${now > before ? '+' : '−'}${(now - before).abs()}',
                          color: now > before ? Accent.habits : (now < before ? Accent.reminders : null),
                        ),
                ),
            ],
          ),
          const SectionTitle('Как ощущения?'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var i = 0; i < 5; i++)
                        IconButton(
                          tooltip: feelLabels[i],
                          iconSize: 34,
                          isSelected: _feel == i + 1,
                          color: _feel == i + 1 ? Accent.workouts : scheme.onSurfaceVariant,
                          onPressed: () => setState(() => _feel = i + 1),
                          icon: Icon(feelIcons[i]),
                        ),
                    ],
                  ),
                  if (_feel != null) Text(feelLabels[_feel! - 1], style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _note,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Заметка: что болело, что получилось'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Accent.workouts, foregroundColor: Colors.white),
              onPressed: _done,
              child: const Text('Готово'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Просмотр проведённой тренировки
// ---------------------------------------------------------------------------

class SessionViewScreen extends StatelessWidget {
  const SessionViewScreen({super.key, required this.sessionId});
  final int sessionId;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Watch(
      deps: [sessionId],
      streams: () => [
        (db.select(db.workoutSessions)..where((t) => t.id.equals(sessionId))).watchSingleOrNull(),
        (db.select(db.sessionSets)..where((t) => t.sessionId.equals(sessionId))).watch(),
      ],
      builder: (context, v) {
        final s = v[0] as WorkoutSession?;
        if (s == null) return const Scaffold(body: Center(child: Text('Удалено')));
        final sets = [...v[1] as List<SessionSet>]..sort((a, b) => a.id.compareTo(b.id));
        final byExercise = <String, List<SessionSet>>{};
        for (final x in sets) {
          byExercise.putIfAbsent(x.exerciseName, () => []).add(x);
        }
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        final reps = sets.fold<int>(0, (a, x) => a + x.reps);
        final tons = tonnage(sets);
        return Scaffold(
          appBar: AppBar(
            title: Text(s.programName),
            actions: [
              IconButton(
                tooltip: 'Удалить',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  if (await confirm(context, 'Удалить тренировку?', ok: 'Удалить', danger: true)) {
                    await db.deleteById(db.workoutSessions, s.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  '${capitalizeFirst(formatDayLong(s.day))}${s.minimum ? ' · облегчённая, засчитан минимум' : ''}',
                  style: TextStyle(color: muted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (s.durationSec != null) Pill(formatClock(s.durationSec!), icon: Icons.timer_outlined, color: Accent.workouts),
                    Pill('${sets.length} подх.'),
                    Pill('$reps повт.'),
                    if (tons > 0) Pill('${formatNumber(tons, maxDecimals: 0)} кг'),
                    if (s.feel != null) Pill(feelLabels[s.feel! - 1], icon: feelIcons[s.feel! - 1], color: Accent.habits),
                  ],
                ),
              ),
              if (s.note != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(s.note!, style: const TextStyle(height: 1.4)),
                  ),
                ),
              GroupCard(
                children: [
                  for (final (i, e) in byExercise.entries.indexed)
                    ListTile(
                      leading: SizedBox(
                        width: 40,
                        child: Center(child: NumberBadge(i + 1, color: Accent.workouts)),
                      ),
                      title: Text(e.key),
                      subtitle: Text(formatSets(e.value)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseScreen(name: e.key))),
                    ),
                ],
              ),
              if (s.programId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(programId: s.programId!))),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Сделать эту программу ещё раз'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// "10 · 10 · 9" или "8×5 · 8×5 · 7×5 кг".
String formatSets(List<SessionSet> sets) {
  final weighted = sets.any((s) => (s.weight ?? 0) > 0);
  if (!weighted) return sets.map((x) => '${x.reps}').join(' · ');
  return '${sets.map((x) => (x.weight ?? 0) > 0 ? '${x.reps}×${formatNumber(x.weight!)}' : '${x.reps}').join(' · ')} кг';
}

String capitalizeFirst(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
