import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../data/time_queries.dart';
import '../logic/day_plan.dart';
import '../logic/focus.dart';
import '../logic/tasks.dart';
import 'common.dart';
import 'day_plan_screen.dart';

Color priorityColor(int p, ColorScheme scheme) => switch (p) {
  1 => const Color(0xFFEF4444),
  2 => const Color(0xFFF59E0B),
  3 => const Color(0xFF3B82F6),
  _ => scheme.outline,
};

const _heroColors = [Color(0xFF4F46E5), Color(0xFF7C3AED)];

enum TaskView { today, upcoming, inbox, done }

extension on TaskView {
  String get label => switch (this) {
    TaskView.today => 'Сегодня',
    TaskView.upcoming => 'Скоро',
    TaskView.inbox => 'Входящие',
    TaskView.done => 'Готово',
  };
}

/// Вкладка «Задачи»: сегодня, ближайшие дни, входящие и сделанное.
class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  var _view = TaskView.today;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    return Watch(
      streams: () => [db.watchTasks(), db.watchTimeBlocks(), db.watchAllSettings(), db.watchFocus(from: today)],
      builder: (context, v) {
        final all = v[0] as List<Task>;
        final blocks = todayBlocks(v[1] as List<TimeBlock>, v[2] as Map<String, String>);
        final focus = v[3] as List<FocusSession>;
        final inboxCount = inboxTasks(all).length;
        return ScrollFabScope(
          child: Scaffold(
            appBar: AppBar(title: const Text('Задачи')),
            floatingActionButton: ScrollFab(
              child: FloatingActionButton.extended(
                heroTag: null,
                onPressed: () => showTaskSheet(context, day: _view == TaskView.inbox ? null : today, inbox: _view == TaskView.inbox),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Задача'),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Row(
                    children: [
                      for (final view in TaskView.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(view == TaskView.inbox && inboxCount > 0 ? '${view.label} $inboxCount' : view.label),
                            selected: _view == view,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _view = view),
                          ),
                        ),
                    ],
                  ),
                ),
                ...switch (_view) {
                  TaskView.today => _today(context, all, today, blocks, focus),
                  TaskView.upcoming => _upcoming(context, all, today),
                  TaskView.inbox => _inbox(context, all),
                  TaskView.done => _done(context, all, today),
                },
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _today(BuildContext context, List<Task> all, int today, List<PlanBlock> blocks, List<FocusSession> focus) {
    final t = todayTasks(all, today);
    final focusToday = focus.where((s) => s.day == today).fold(0, (a, s) => a + s.minutes);
    final free = blocks.isEmpty ? null : distribution(blocks).free;
    final over = free != null && t.estimateLeft > free;
    return [
      HeroCard(
        colors: _heroColors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDayLong(today),
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  t.total == 0 ? 'Пусто' : '${t.done.length} из ${t.total}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.1),
                ),
                const SizedBox(width: 8),
                if (t.total > 0)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text('сделано', style: TextStyle(color: Colors.white70)),
                  ),
              ],
            ),
            if (t.total > 0) ...[const SizedBox(height: 10), ProgressLine(value: t.done.length / t.total, color: Colors.white, height: 8)],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: HeroStat(label: 'Осталось по оценке', value: t.estimateLeft == 0 ? '—' : formatDuration(t.estimateLeft)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: HeroStat(label: 'Фокус сегодня', value: focusToday == 0 ? '—' : formatDuration(focusToday)),
                ),
                if (free != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: HeroStat(label: 'Свободно по плану', value: formatDuration(free)),
                  ),
                ],
              ],
            ),
            if (over) ...[
              const SizedBox(height: 10),
              const HeroChip('Задач больше, чем свободного времени. Перенеси лишнее.', icon: Icons.warning_amber_rounded),
            ],
          ],
        ),
      ),
      if (t.total == 0)
        const Card(
          child: EmptyHint(
            'На сегодня задач нет. Добавь 1–3 главных дела дня: с ними день точно не пройдёт впустую.',
            icon: Icons.task_alt_rounded,
          ),
        ),
      if (t.overdue.isNotEmpty) ...[
        SectionTitle(
          'Просрочено',
          trailing: TextButton(
            onPressed: () => context.db.moveTasks(t.overdue.map((e) => e.id), today),
            child: const Text('Всё на сегодня'),
          ),
        ),
        GroupCard(
          children: [for (final x in t.overdue) TaskTile(task: x, all: all, showDay: true)],
        ),
      ],
      if (t.main.isNotEmpty) ...[
        const SectionTitle('Главное'),
        GroupCard(
          children: [for (final x in t.main) TaskTile(task: x, all: all)],
        ),
        if (t.main.length > 3)
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text('Главных больше трёх. Обычно за день реально сделать 1–3 больших дела.'),
          ),
      ],
      if (t.other.isNotEmpty) ...[
        SectionTitle(t.main.isEmpty ? 'Задачи' : 'Остальное'),
        GroupCard(
          children: [for (final x in t.other) TaskTile(task: x, all: all)],
        ),
      ],
      if (t.done.isNotEmpty) ...[
        SectionTitle('Сделано сегодня · ${t.done.length}'),
        GroupCard(
          children: [for (final x in t.done) TaskTile(task: x, all: all)],
        ),
      ],
      if (t.total > 0 && t.main.isEmpty && t.other.isNotEmpty)
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Text('Совет: отметь одно-два дела как «Главное» и начни с них, пока больше всего сил.'),
        ),
    ];
  }

  List<Widget> _upcoming(BuildContext context, List<Task> all, int today) {
    final groups = upcomingTasks(all, today);
    if (groups.isEmpty) {
      return const [
        Card(
          child: EmptyHint(
            'Здесь будут задачи на ближайшие дни. Напиши в названии «завтра» или «в пятницу», и дата поставится сама.',
            icon: Icons.event_note_rounded,
          ),
        ),
      ];
    }
    return [
      for (final e in groups.entries) ...[
        SectionTitle(e.key == null ? 'Позже' : _dayTitle(e.key!, today)),
        GroupCard(
          children: [for (final x in e.value) TaskTile(task: x, all: all, showDay: e.key == null)],
        ),
      ],
    ];
  }

  List<Widget> _inbox(BuildContext context, List<Task> all) {
    final list = inboxTasks(all);
    return [
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 6, 24, 6),
        child: Text('Сюда скидывай всё, что пришло в голову, чтобы не держать в памяти. Раз в день разбирай: назначь день или удали.'),
      ),
      if (list.isEmpty)
        const Card(child: EmptyHint('Входящие пусты. Голова свободна.', icon: Icons.inbox_rounded))
      else
        GroupCard(
          children: [for (final x in list) TaskTile(task: x, all: all)],
        ),
    ];
  }

  List<Widget> _done(BuildContext context, List<Task> all, int today) {
    final list = doneTasks(all);
    if (list.isEmpty) {
      return const [Card(child: EmptyHint('Пока ничего не сделано. Отмечай задачи кружком слева.', icon: Icons.done_all_rounded))];
    }
    final byDay = <int, List<Task>>{};
    for (final t in list) {
      byDay.putIfAbsent(t.doneDay!, () => []).add(t);
    }
    return [
      for (final e in byDay.entries) ...[
        SectionTitle('${_dayTitle(e.key, today)} · ${e.value.length}'),
        GroupCard(
          children: [for (final x in e.value) TaskTile(task: x, all: all)],
        ),
      ],
    ];
  }
}

String _dayTitle(int day, int today) {
  final label = dayLabel(day, today: today);
  final long = formatDayLong(day);
  if (label == 'сегодня' || label == 'завтра' || label == 'вчера') {
    return '${label[0].toUpperCase()}${label.substring(1)}, ${long.split(', ').first}';
  }
  return long[0].toUpperCase() + long.substring(1);
}

/// Строка задачи: кружок отметки, название, детали и кнопка фокуса.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, required this.all, this.showDay = false, this.compact = false});
  final Task task;
  final List<Task> all;
  final bool showDay;

  /// Без кнопки фокуса: для карточек на других экранах.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final t = task;
    final done = t.doneDay != null;
    final today = todayKey();
    final steps = stepsOf(all, t.id);
    final overdue = !done && t.day != null && t.day! < today;
    final pc = priorityColor(t.priority, scheme);
    final details = <Widget>[
      if (showDay && t.day != null)
        Pill(
          dayLabel(t.day!, today: today),
          icon: Icons.event_rounded,
          color: overdue ? scheme.error : null,
        ),
      if (t.time != null) Pill(formatMinutes(t.time!), icon: t.remind ? Icons.notifications_active_outlined : Icons.schedule_rounded),
      if (t.estimate != null) Pill(formatDuration(t.estimate!), icon: Icons.hourglass_bottom_rounded),
      if (steps.total > 0) Pill('${steps.done}/${steps.total}', icon: Icons.checklist_rounded),
      if (t.kind != null) Pill(t.kind!.label, color: kindColor(t.kind!)),
      if (t.repeat != TaskRepeat.none) Icon(Icons.repeat_rounded, size: 16, color: muted),
    ];
    return InkWell(
      onTap: () => showTaskSheet(context, existing: t),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
        child: Row(
          children: [
            IconButton(
              tooltip: done ? 'Вернуть' : 'Сделано',
              onPressed: () => context.db.setTaskDone(t, !done),
              icon: _PriorityCheck(checked: done, color: pc, strong: t.priority < 4),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? muted : null,
                    ),
                  ),
                  if (details.isNotEmpty && !done) ...[
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: details),
                  ],
                ],
              ),
            ),
            if (!done && !compact)
              IconButton(
                tooltip: 'Фокус на задаче',
                icon: Icon(Icons.play_circle_outline_rounded, color: scheme.primary),
                onPressed: () => startFocusOn(context, t),
              ),
          ],
        ),
      ),
    );
  }
}

class _PriorityCheck extends StatelessWidget {
  const _PriorityCheck({required this.checked, required this.color, required this.strong});
  final bool checked;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? color : (strong ? color.withValues(alpha: 0.12) : Colors.transparent),
        border: Border.all(color: checked ? Colors.transparent : color, width: 2),
      ),
      child: checked ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
    );
  }
}

/// Запустить таймер фокуса на задаче и открыть вкладку «Фокус».
Future<void> startFocusOn(BuildContext context, Task task) async {
  final db = context.db;
  final running = await db.focusState();
  if (!context.mounted) return;
  if (running != null && !running.finished(DateTime.now())) {
    showSnack(context, 'Таймер уже идёт');
  } else {
    final minutes = int.tryParse(await db.getSetting('focus_minutes') ?? '') ?? 25;
    await db.setFocusState(FocusState.start(minutes: minutes, taskId: task.id, kind: task.kind));
  }
  if (context.mounted) TimeModule.maybeOf(context)?.openTab(TimeTab.focus);
}

// ---------------------------------------------------------------------------
// Задача: создание и изменение
// ---------------------------------------------------------------------------

Future<void> showTaskSheet(BuildContext context, {Task? existing, int? day, bool inbox = false, int? parentId}) {
  final today = todayKey();
  final title = TextEditingController(text: existing?.title ?? '');
  final note = TextEditingController(text: existing?.note ?? '');
  final stepInput = TextEditingController();
  int? taskDay = existing != null ? existing.day : (inbox ? null : (day ?? today));
  var time = existing?.time;
  var remind = existing?.remind ?? false;
  var priority = existing?.priority ?? 4;
  var estimate = existing?.estimate;
  var kind = existing?.kind;
  var repeat = existing?.repeat ?? TaskRepeat.none;
  final newSteps = <String>[];
  // Новая задача: только главное, чтобы записать за пару секунд. Остальное по кнопке.
  var more = existing != null;

  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) {
        final theme = Theme.of(sheet);
        final scheme = theme.colorScheme;
        Future<void> save() async {
          var name = title.text.trim();
          var d = taskDay, tm = time, p = priority, est = estimate;
          var k = kind;
          if (existing == null) {
            // Быстрый ввод: «завтра в 18:00 !1 ~30м #учёба» превращается в поля.
            final q = parseQuickTask(name, today: today);
            if (q.title.isNotEmpty) name = q.title;
            d = q.day ?? d;
            tm = q.time ?? tm;
            p = q.priority ?? p;
            est = q.estimate ?? est;
            k = q.kind ?? k;
          }
          if (name.isEmpty) return showSnack(sheet, 'Напиши, что нужно сделать');
          final db = sheet.db;
          final id = await db.saveTask(
            TasksCompanion(
              id: existing == null ? const Value.absent() : Value(existing.id),
              title: Value(name),
              note: Value(emptyToNull(note.text)),
              parentId: existing == null ? Value(parentId) : const Value.absent(),
              day: Value(d),
              time: Value(tm),
              remind: Value(tm != null && remind),
              priority: Value(p),
              estimate: Value(est),
              kind: Value(k),
              repeat: Value(repeat),
            ),
          );
          for (final s in newSteps) {
            await db.saveTask(TasksCompanion.insert(title: s, parentId: Value(id)));
          }
          if (remind && tm != null && sheet.mounted) await sheet.notifications.requestPermission();
          if (sheet.mounted) Navigator.pop(sheet);
        }

        Future<void> pickDate() async {
          final d = await showDatePicker(
            context: sheet,
            initialDate: dayFromKey(taskDay ?? today),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (d != null) setState(() => taskDay = dayKey(d));
        }

        Future<void> pickTime() async {
          final m = time ?? 18 * 60;
          final t = await showTimePicker(
            context: sheet,
            initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
          );
          if (t != null) {
            setState(() {
              time = t.hour * 60 + t.minute;
              taskDay ??= today;
            });
          }
        }

        final isCustomDay = taskDay != null && taskDay != today && taskDay != addDays(today, 1);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              existing == null ? (parentId == null ? 'Новая задача' : 'Новый шаг') : (existing.parentId == null ? 'Задача' : 'Шаг'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: title,
              autofocus: existing == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Что сделать',
                helperText: existing == null && parentId == null ? 'Можно сразу: «завтра в 18:00 !1 ~30м #учёба»' : null,
                helperMaxLines: 2,
              ),
              onSubmitted: (_) => save(),
            ),
            if (parentId == null && existing?.parentId == null) ...[
              const SizedBox(height: 14),
              Text('Когда', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(label: const Text('Сегодня'), selected: taskDay == today, onSelected: (_) => setState(() => taskDay = today)),
                  ChoiceChip(
                    label: const Text('Завтра'),
                    selected: taskDay == addDays(today, 1),
                    onSelected: (_) => setState(() => taskDay = addDays(today, 1)),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.event_rounded, size: 18),
                    label: Text(isCustomDay ? dayLabel(taskDay!, today: today) : 'Дата'),
                    selected: isCustomDay,
                    onSelected: (_) => pickDate(),
                  ),
                  ChoiceChip(
                    label: const Text('Без даты'),
                    selected: taskDay == null,
                    onSelected: (_) => setState(() {
                      taskDay = null;
                      time = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: pickTime,
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(time == null ? 'Время' : formatMinutes(time!)),
                    ),
                  ),
                  if (time != null) ...[
                    IconButton(tooltip: 'Без времени', onPressed: () => setState(() => time = null), icon: const Icon(Icons.close_rounded)),
                    FilterChip(
                      avatar: const Icon(Icons.notifications_outlined, size: 18),
                      label: const Text('Напомнить'),
                      selected: remind,
                      onSelected: (v) => setState(() => remind = v),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text('Приоритет', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final p in [1, 2, 3, 4])
                    ChoiceChip(
                      showCheckmark: false,
                      avatar: Icon(Icons.flag_rounded, size: 18, color: priorityColor(p, scheme)),
                      label: Text(priorityLabels[p]!),
                      selected: priority == p,
                      onSelected: (_) => setState(() => priority = p),
                    ),
                ],
              ),
              if (!more)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () => setState(() => more = true),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: const Text('Оценка, сфера, шаги, повтор'),
                  ),
                )
              else ...[
                const SizedBox(height: 14),
                Text('Сколько займёт', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in [15, 30, 60, 90, 120, 180])
                      ChoiceChip(
                        label: Text(formatDuration(m)),
                        selected: estimate == m,
                        onSelected: (on) => setState(() => estimate = on ? m : null),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Сфера', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final k in BlockKind.values)
                      if (k != BlockKind.sleep)
                        ChoiceChip(
                          showCheckmark: false,
                          avatar: CircleAvatar(backgroundColor: kindColor(k), radius: 5),
                          label: Text(k.label),
                          selected: kind == k,
                          onSelected: (on) => setState(() => kind = on ? k : null),
                        ),
                  ],
                ),
                _StepsEditor(existing: existing, pending: newSteps, input: stepInput, onChanged: () => setState(() {})),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Заметка'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TaskRepeat>(
                  initialValue: repeat,
                  decoration: const InputDecoration(labelText: 'Повтор', prefixIcon: Icon(Icons.repeat_rounded)),
                  items: [for (final r in TaskRepeat.values) DropdownMenuItem(value: r, child: Text(r.label))],
                  onChanged: (r) => setState(() => repeat = r ?? TaskRepeat.none),
                ),
              ],
            ],
            const SizedBox(height: 14),
            FilledButton(onPressed: save, child: const Text('Сохранить')),
            if (existing != null) ...[
              if (existing.doneDay == null && existing.parentId == null)
                TextButton.icon(
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('Фокус на задаче'),
                  onPressed: () {
                    Navigator.pop(sheet);
                    startFocusOn(context, existing);
                  },
                ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: scheme.error),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(existing.parentId == null ? 'Удалить задачу' : 'Удалить шаг'),
                onPressed: () async {
                  await sheet.db.deleteTask(existing.id);
                  if (sheet.mounted) Navigator.pop(sheet);
                },
              ),
            ],
          ],
        );
      },
    ),
  );
}

/// Шаги большой задачи: список с отметками и поле для нового шага.
class _StepsEditor extends StatelessWidget {
  const _StepsEditor({required this.existing, required this.pending, required this.input, required this.onChanged});
  final Task? existing;
  final List<String> pending;
  final TextEditingController input;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = context.db;
    final id = existing?.id;

    void add() {
      final s = input.text.trim();
      if (s.isEmpty) return;
      if (id == null) {
        pending.add(s);
      } else {
        db.saveTask(TasksCompanion.insert(title: s, parentId: Value(id)));
      }
      input.clear();
      onChanged();
    }

    Widget field() => TextField(
      controller: input,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: 'Добавить шаг',
        prefixIcon: const Icon(Icons.add_rounded),
        suffixIcon: IconButton(icon: const Icon(Icons.keyboard_return_rounded), onPressed: add),
      ),
      onSubmitted: (_) => add(),
    );

    final header = Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text('Шаги', style: theme.textTheme.labelLarge),
    );

    if (id == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          for (final (i, s) in pending.indexed)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.radio_button_unchecked_rounded),
              title: Text(s),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  pending.removeAt(i);
                  onChanged();
                },
              ),
            ),
          field(),
        ],
      );
    }
    return StreamBuilder<List<Task>>(
      stream: db.watchTasks(),
      builder: (context, snap) {
        final steps = (snap.data ?? const <Task>[]).where((t) => t.parentId == id).toList()..sort(compareTasks);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            for (final s in steps)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Checkbox(value: s.doneDay != null, onChanged: (v) => db.setTaskDone(s, v ?? false)),
                title: Text(s.title, style: TextStyle(decoration: s.doneDay != null ? TextDecoration.lineThrough : null)),
                trailing: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => db.deleteTask(s.id)),
              ),
            field(),
          ],
        );
      },
    );
  }
}
