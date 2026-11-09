import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import 'common.dart';
import 'icons.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Scaffold(
      appBar: AppBar(title: const Text('Напоминания')),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => editReminder(context, null),
        child: const Icon(Icons.add_rounded),
      ),
      body: Watch(
        streams: () => [db.watchReminders(), db.watchHabits(), db.watchTrackers(), db.watchPrograms()],
        builder: (context, v) {
          final reminders = v[0] as List<Reminder>;
          final habits = (v[1] as List<Habit>).where((h) => h.reminderMinutes != null).toList();
          final trackers = (v[2] as List<Tracker>).where((t) => t.reminderMinutes != null && t.daysMask != 0).toList();
          final programs = (v[3] as List<Program>).where((p) => p.reminderMinutes != null && p.daysMask != 0).toList();
          final muted = Theme.of(context).colorScheme.onSurfaceVariant;
          Widget linked(String icon, String fallback, String name, int minutes, int mask) => ListTile(
            leading: ItemIcon(icon, size: 40, fallback: fallback),
            title: Text(name),
            subtitle: Text(maskLabel(mask)),
            trailing: Text(
              formatMinutes(minutes),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFeatures: [FontFeature.tabularFigures()]),
            ),
          );
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              const SectionTitle('Свои напоминания'),
              if (reminders.isEmpty)
                const Card(
                  child: EmptyHint(
                    'Например, «Итог дня» в 22:30 или «Обзор недели» в воскресенье.',
                    icon: Icons.notifications_none_rounded,
                  ),
                ),
              for (final r in reminders) _ReminderCard(reminder: r),
              if (habits.isNotEmpty || trackers.isNotEmpty || programs.isNotEmpty) ...[
                const SectionTitle('Из привычек, трекеров и тренировок'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('Меняются в настройках самой привычки, трекера или программы.', style: TextStyle(color: muted)),
                ),
                GroupCard(
                  children: [
                    for (final h in habits) linked(h.icon, 'check', h.name, h.reminderMinutes!, h.daysMask),
                    for (final t in trackers) linked(t.icon, 'chart', t.name, t.reminderMinutes!, t.daysMask),
                    for (final p in programs) linked('fitness', 'fitness', p.name, p.reminderMinutes!, p.daysMask),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder});
  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final r = reminder;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      child: InkWell(
        onTap: () => editReminder(context, r),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: r.enabled ? 1 : 0.45,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatMinutes(r.minutes),
                        style: theme.textTheme.headlineMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      const SizedBox(height: 2),
                      Text(r.title, style: theme.textTheme.titleSmall),
                      Text(
                        [maskLabel(r.daysMask), if (r.body != null) r.body!].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ),
              Switch(
                value: r.enabled,
                onChanged: (on) => context.db.saveReminder(RemindersCompanion(id: Value(r.id), enabled: Value(on))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> editReminder(BuildContext context, Reminder? r) {
  final title = TextEditingController(text: r?.title ?? '');
  final body = TextEditingController(text: r?.body ?? '');
  var minutes = r?.minutes ?? 21 * 60;
  var mask = r?.daysMask ?? everyDay;
  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            autofocus: r == null,
            decoration: const InputDecoration(labelText: 'Заголовок'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: body,
            decoration: const InputDecoration(labelText: 'Текст (необязательно)'),
          ),
          ReminderTile(title: 'Время', minutes: minutes, onChanged: (m) => setState(() => minutes = m ?? minutes)),
          DaysPicker(mask: mask, onChanged: (m) => setState(() => mask = m)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              if (title.text.trim().isEmpty) return showSnack(sheet, 'Введи заголовок');
              if (mask == 0) return showSnack(sheet, 'Выбери дни');
              await sheet.db.saveReminder(
                RemindersCompanion(
                  id: r == null ? const Value.absent() : Value(r.id),
                  title: Value(title.text.trim()),
                  body: Value(emptyToNull(body.text)),
                  minutes: Value(minutes),
                  daysMask: Value(mask),
                ),
              );
              if (sheet.mounted) Navigator.pop(sheet);
            },
            child: const Text('Сохранить'),
          ),
          if (r != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(sheet).colorScheme.error),
              onPressed: () async {
                await sheet.db.deleteById(sheet.db.reminders, r.id);
                if (sheet.mounted) Navigator.pop(sheet);
              },
              child: const Text('Удалить'),
            ),
        ],
      ),
    ),
  );
}
