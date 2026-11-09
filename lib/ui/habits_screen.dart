import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/icon_keys.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import 'charts.dart';
import 'common.dart';
import 'icons.dart';
import 'theme.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key, this.archived = false});
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    final monday = weekStart(today);
    final archiveButton = IconButton(
      tooltip: 'Архив',
      icon: const Icon(Icons.inventory_2_outlined),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitsScreen(archived: true))),
    );
    return Scaffold(
      appBar: archived ? AppBar(title: const Text('Привычки в архиве')) : null,
      floatingActionButton: archived
          ? null
          : FloatingActionButton(
              heroTag: null,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitEditScreen())),
              child: const Icon(Icons.add_rounded),
            ),
      body: Watch(
        deps: [today],
        streams: () => [db.watchHabits(archived: archived), db.watchAllHabitLogs()],
        builder: (context, v) {
          final habits = v[0] as List<Habit>;
          final logs = v[1] as List<HabitLog>;
          final done = <int, Set<int>>{};
          for (final l in logs) {
            done.putIfAbsent(l.habitId, () => {}).add(l.day);
          }
          var planned = 0, doneWeek = 0;
          for (final h in habits) {
            final c = habitCompletion(daysMask: h.daysMask, doneDays: done[h.id] ?? const {}, from: monday, to: today);
            planned += c.planned;
            doneWeek += c.done;
          }
          return ListView(
            padding: EdgeInsets.only(top: archived ? 8 : 0, bottom: 100),
            children: [
              if (!archived)
                PageHeader(
                  overline: planned == 0 ? 'эта неделя' : 'эта неделя · $doneWeek из $planned',
                  title: 'Привычки',
                  actions: [archiveButton],
                ),
              if (habits.isEmpty)
                EmptyHint(
                  archived
                      ? 'В архиве пусто.'
                      : 'Привычка это регулярное действие с расписанием. Например, «Отбой до 23:00» каждый день или «Код» по будням.',
                  icon: archived ? Icons.inventory_2_outlined : Icons.check_circle_outline_rounded,
                ),
              for (final h in habits) _HabitCard(habit: h, done: done[h.id] ?? const {}, today: today, monday: monday),
            ],
          );
        },
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.habit, required this.done, required this.today, required this.monday});
  final Habit habit;
  final Set<int> done;
  final int today;
  final int monday;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final streak = currentStreak(daysMask: habit.daysMask, doneDays: done, today: today);
    final month = habitCompletion(daysMask: habit.daysMask, doneDays: done, from: addDays(today, -29), to: today);
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: habit.id))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ItemIcon(habit.icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          [
                            maskLabel(habit.daysMask),
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
                          final isDone = done.contains(day);
                          final planned = maskHasDay(habit.daysMask, day);
                          final future = day > today;
                          final isToday = day == today;
                          final bg = isDone
                              ? Accent.habits
                              : planned
                              ? scheme.surfaceContainerHighest
                              : scheme.surfaceContainerHighest.withValues(alpha: 0.4);
                          return GestureDetector(
                            onTap: future ? null : () => db.setHabitDone(habit.id, day, done: !isDone),
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
                                  child: isDone ? const Icon(Icons.check_rounded, size: 20, color: Colors.white) : null,
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

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});
  final int habitId;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    return Watch(
      deps: [habitId],
      streams: () => [(db.select(db.habits)..where((t) => t.id.equals(habitId))).watchSingleOrNull(), db.watchLogsOfHabit(habitId)],
      builder: (context, v) {
        final h = v[0] as Habit?;
        if (h == null) return const Scaffold(body: Center(child: Text('Привычка удалена')));
        final logs = v[1] as List<HabitLog>;
        final byDay = {for (final l in logs) l.day: l};
        final done = byDay.keys.toSet();
        final streak = currentStreak(daysMask: h.daysMask, doneDays: done, today: today);
        final m30 = habitCompletion(daysMask: h.daysMask, doneDays: done, from: addDays(today, -29), to: today);
        final minimums = logs.where((l) => l.minimum).length;
        return Scaffold(
          appBar: AppBar(
            leading: ItemIcon(h.icon, size: 40),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    ItemIcon(h.icon, size: 56),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [maskLabel(h.daysMask), if (h.reminderMinutes != null) 'в ${formatMinutes(h.reminderMinutes!)}'].join(' · '),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (h.minimumText != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Минимум: ${h.minimumText}',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    children: [
                      _Stat(label: 'серия', value: '$streak', color: Accent.workouts),
                      _Stat(
                        label: 'за 30 дней',
                        value: m30.planned == 0 ? '—' : '${(100 * m30.done / m30.planned).round()}%',
                        color: Accent.habits,
                      ),
                      _Stat(label: 'всего', value: '${logs.length}'),
                      _Stat(label: 'минимумом', value: '$minimums'),
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
                      Text('Последние 16 недель', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Нажми на день, чтобы поставить или снять отметку. Бледные: засчитан минимум.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 14),
                      DayGrid(
                        today: today,
                        weeks: 16,
                        color: Accent.habits,
                        isDone: done.contains,
                        isPlanned: (d) => maskHasDay(h.daysMask, d),
                        isMinimum: (d) => byDay[d]?.minimum ?? false,
                        onTap: (d) => db.setHabitDone(h.id, d, done: !done.contains(d)),
                      ),
                    ],
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
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class HabitEditScreen extends StatefulWidget {
  const HabitEditScreen({super.key, this.habit});
  final Habit? habit;

  @override
  State<HabitEditScreen> createState() => _HabitEditScreenState();
}

class _HabitEditScreenState extends State<HabitEditScreen> {
  late final _name = TextEditingController(text: widget.habit?.name ?? '');
  late String _icon = iconKeyFor(widget.habit?.icon) ?? 'check';
  late final _minimum = TextEditingController(text: widget.habit?.minimumText ?? '');
  late int _mask = widget.habit?.daysMask ?? everyDay;
  late int? _reminder = widget.habit?.reminderMinutes;
  late int? _trackerId = widget.habit?.trackerId;

  bool get _isNew => widget.habit == null;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return showSnack(context, 'Введи название');
    if (_mask == 0) return showSnack(context, 'Выбери хотя бы один день');
    await context.db.saveHabit(
      HabitsCompanion(
        id: _isNew ? const Value.absent() : Value(widget.habit!.id),
        name: Value(name),
        icon: Value(_icon),
        daysMask: Value(_mask),
        reminderMinutes: Value(_reminder),
        minimumText: Value(emptyToNull(_minimum.text)),
        trackerId: Value(_trackerId),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final h = widget.habit;
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
                  autofocus: _isNew,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Дни', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DaysPicker(mask: _mask, onChanged: (m) => setState(() => _mask = m)),
          const SizedBox(height: 8),
          ReminderTile(minutes: _reminder, onChanged: (m) => setState(() => _reminder = m)),
          const SizedBox(height: 8),
          TextField(
            controller: _minimum,
            decoration: const InputDecoration(labelText: 'Минимум в тяжёлый день', hintText: 'Например: 20 минут кода'),
          ),
          const SizedBox(height: 16),
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
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
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
