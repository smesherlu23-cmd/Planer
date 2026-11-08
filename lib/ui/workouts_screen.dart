import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import 'common.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Scaffold(
      appBar: AppBar(title: const Text('Тренировки')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgramEditScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Программа'),
      ),
      body: Watch(
        streams: () => [db.watchPrograms(), db.watchSessions()],
        builder: (context, v) {
          final programs = v[0] as List<Program>;
          final sessions = v[1] as List<WorkoutSession>;
          final today = todayKey();
          final weekFrom = weekStart(today);
          final thisWeek = sessions.where((s) => s.day >= weekFrom && s.day <= today).length;
          final plannedDays = programs.fold<int>(0, (m, p) => m | p.daysMask);
          final plannedThisWeek = weekdaysFromMask(plannedDays).length;
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (plannedThisWeek > 0)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text('На этой неделе: $thisWeek из $plannedThisWeek'),
                    subtitle: Text('Дни тренировок: ${maskLabel(plannedDays)}'),
                  ),
                ),
              const SectionTitle('Программы'),
              if (programs.isEmpty) const EmptyHint('Программа это список упражнений с подходами и повторами. Например, «Тренировка A».'),
              for (final p in programs)
                Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      [
                        p.daysMask == 0 ? 'без расписания' : maskLabel(p.daysMask),
                        if (p.reminderMinutes != null) formatMinutes(p.reminderMinutes!),
                        _lastLabel(p, sessions),
                      ].join(' · '),
                    ),
                    trailing: IconButton.filledTonal(
                      tooltip: 'Начать',
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(programId: p.id))),
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramDetailScreen(programId: p.id))),
                  ),
                ),
              const SectionTitle('История'),
              if (sessions.isEmpty) const EmptyHint('Здесь будут проведённые тренировки'),
              for (final s in sessions.take(50))
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(s.programName),
                  subtitle: Text(dayLabel(s.day)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionViewScreen(sessionId: s.id))),
                ),
            ],
          );
        },
      ),
    );
  }

  String _lastLabel(Program p, List<WorkoutSession> sessions) {
    final last = sessions.where((s) => s.programId == p.id).firstOrNull;
    return last == null ? 'ещё не было' : 'была ${dayLabel(last.day)}';
  }
}

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
        return Scaffold(
          appBar: AppBar(
            title: Text(p.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramEditScreen(program: p))),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: null,
            onPressed: exercises.isEmpty
                ? null
                : () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(programId: p.id))),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Начать'),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (p.note != null) Padding(padding: const EdgeInsets.all(16), child: Text(p.note!)),
              const SectionTitle('Упражнения'),
              if (exercises.isEmpty) const EmptyHint('Добавь первое упражнение'),
              for (final e in exercises)
                ListTile(
                  title: Text(e.name),
                  subtitle: Text([planLabel(e), if (e.note != null) e.note!].join('\n')),
                  isThreeLine: e.note != null,
                  onTap: () => editExercise(context, p.id, e),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => editExercise(context, p.id, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Упражнение'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> editExercise(BuildContext context, int programId, ProgramExercise? e) {
  final name = TextEditingController(text: e?.name ?? '');
  final sets = TextEditingController(text: '${e?.sets ?? 3}');
  final min = TextEditingController(text: '${e?.repsMin ?? 8}');
  final max = TextEditingController(text: '${e?.repsMax ?? 12}');
  final note = TextEditingController(text: e?.note ?? '');
  var unit = e?.unit ?? 'повт';
  Widget intField(TextEditingController c, String label) => Expanded(
    child: TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    ),
  );
  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            autofocus: e == null,
            decoration: const InputDecoration(labelText: 'Упражнение'),
          ),
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
              await sheet.db.saveExercise(
                ProgramExercisesCompanion(
                  id: e == null ? const Value.absent() : Value(e.id),
                  programId: Value(programId),
                  name: Value(name.text.trim()),
                  sets: Value(s),
                  repsMin: Value(lo),
                  repsMax: Value(hi < lo ? lo : hi),
                  unit: Value(unit),
                  note: Value(emptyToNull(note.text)),
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
          const Text('Если у двух программ одни и те же дни, на «Сегодня» будет предложена та, что была давно. Так A и B чередуются сами.'),
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

// ---------------------------------------------------------------------------
// Проведение тренировки
// ---------------------------------------------------------------------------

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.programId});
  final int programId;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _ExerciseInput {
  _ExerciseInput(this.exercise, this.last)
    : reps = [for (var i = 0; i < exercise.sets; i++) TextEditingController()],
      weight = TextEditingController(text: last.isNotEmpty && last.first.weight != null ? formatNumber(last.first.weight!) : '');

  final ProgramExercise exercise;
  final List<SessionSet> last;
  final List<TextEditingController> reps;
  final TextEditingController weight;

  /// Поле веса показываем, только если он нужен: был в прошлый раз или его добавили.
  late bool showWeight = weight.text.isNotEmpty;
}

class _SessionScreenState extends State<SessionScreen> {
  Program? _program;
  List<_ExerciseInput>? _inputs;
  final _note = TextEditingController();
  var _day = todayKey();
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = context.db;
    final p = await (db.select(db.programs)..where((t) => t.id.equals(widget.programId))).getSingle();
    final exercises = await db.exercisesOf(p.id);
    final last = await db.lastSetsForProgram(p.id);
    if (!mounted) return;
    setState(() {
      _program = p;
      _inputs = [for (final e in exercises) _ExerciseInput(e, last[e.id] ?? const [])];
    });
  }

  Future<void> _save() async {
    final inputs = _inputs!;
    final sets = <SessionSetsCompanion>[];
    for (final input in inputs) {
      final w = parseNumber(input.weight.text);
      for (var i = 0; i < input.reps.length; i++) {
        final r = int.tryParse(input.reps[i].text.trim());
        if (r == null) continue;
        sets.add(
          SessionSetsCompanion.insert(
            sessionId: 0, // заменится при сохранении
            exerciseId: Value(input.exercise.id),
            exerciseName: input.exercise.name,
            setIndex: i,
            reps: r,
            weight: Value(w),
          ),
        );
      }
    }
    if (sets.isEmpty) return showSnack(context, 'Запиши хотя бы один подход');
    setState(() => _saving = true);
    await context.db.saveSession(program: _program!, day: _day, sets: sets, note: emptyToNull(_note.text));
    if (mounted) {
      showSnack(context, 'Тренировка записана 💪');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputs = _inputs;
    return Scaffold(
      appBar: AppBar(title: Text(_program?.name ?? 'Тренировка')),
      body: inputs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (_program!.note != null) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Text(_program!.note!)),
                for (final input in inputs)
                  _ExerciseCard(
                    input: input,
                    onAddSet: () => setState(() => input.reps.add(TextEditingController())),
                    onShowWeight: () => setState(() => input.showWeight = true),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      DayTile(day: _day, onChanged: (d) => setState(() => _day = d ?? _day)),
                      TextField(
                        controller: _note,
                        decoration: const InputDecoration(labelText: 'Как прошло (необязательно)'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(onPressed: _saving ? null : _save, child: const Text('Сохранить тренировку')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.input, required this.onAddSet, required this.onShowWeight});
  final _ExerciseInput input;
  final VoidCallback onAddSet;
  final VoidCallback onShowWeight;

  @override
  Widget build(BuildContext context) {
    final e = input.exercise;
    final lastReps = [for (final s in input.last) s.reps];
    final ready = readyToProgress(plannedSets: e.sets, repsMax: e.repsMax, lastReps: lastReps);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.name, style: Theme.of(context).textTheme.titleMedium),
            Text(planLabel(e), style: TextStyle(color: scheme.onSurfaceVariant)),
            if (lastReps.isNotEmpty)
              Text(
                'В прошлый раз: ${lastReps.join(', ')}${input.last.first.weight != null ? ' · ${formatNumber(input.last.first.weight!)} кг' : ''}',
              ),
            if (ready)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '⬆️ В прошлый раз все подходы на верхней границе. Пора усложнять${e.note != null ? ': ${e.note}' : '.'}',
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              )
            else if (e.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(e.note!, style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < input.reps.length; i++)
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: input.reps[i],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: '${i + 1}',
                        hintText: i < lastReps.length ? '${lastReps[i]}' : null,
                        isDense: true,
                      ),
                    ),
                  ),
                IconButton(onPressed: onAddSet, icon: const Icon(Icons.add), tooltip: 'Ещё подход'),
                if (input.showWeight)
                  SizedBox(
                    width: 96,
                    child: TextField(
                      controller: input.weight,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Вес', suffixText: 'кг', isDense: true),
                    ),
                  )
                else
                  TextButton(onPressed: onShowWeight, child: const Text('+ вес')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SessionViewScreen extends StatelessWidget {
  const SessionViewScreen({super.key, required this.sessionId});
  final int sessionId;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return FutureBuilder(
      future: Future.wait([(db.select(db.workoutSessions)..where((t) => t.id.equals(sessionId))).getSingleOrNull(), db.setsOf(sessionId)]),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final s = snap.data![0] as WorkoutSession?;
        if (s == null) return const Scaffold(body: Center(child: Text('Удалено')));
        final sets = snap.data![1] as List<SessionSet>;
        final byExercise = <String, List<SessionSet>>{};
        for (final x in sets) {
          byExercise.putIfAbsent(x.exerciseName, () => []).add(x);
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(s.programName),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
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
            padding: const EdgeInsets.all(16),
            children: [
              Text(formatDayLong(s.day), style: Theme.of(context).textTheme.titleMedium),
              if (s.note != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(s.note!)),
              const SizedBox(height: 8),
              for (final e in byExercise.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.key),
                  subtitle: Text(
                    e.value.map((x) => '${x.reps}').join(', ') +
                        (e.value.first.weight != null ? ' · ${formatNumber(e.value.first.weight!)} кг' : ''),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
