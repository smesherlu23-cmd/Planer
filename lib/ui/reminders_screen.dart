import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import 'common.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Scaffold(
      appBar: AppBar(title: const Text('Напоминания')),
      floatingActionButton: FloatingActionButton(heroTag: null, onPressed: () => editReminder(context, null), child: const Icon(Icons.add)),
      body: Watch(
        streams: () => [db.watchReminders(), db.watchHabits(), db.watchTrackers(), db.watchPrograms()],
        builder: (context, v) {
          final reminders = v[0] as List<Reminder>;
          final habits = (v[1] as List<Habit>).where((h) => h.reminderMinutes != null).toList();
          final trackers = (v[2] as List<Tracker>).where((t) => t.reminderMinutes != null && t.daysMask != 0).toList();
          final programs = (v[3] as List<Program>).where((p) => p.reminderMinutes != null && p.daysMask != 0).toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              const SectionTitle('Свои напоминания'),
              if (reminders.isEmpty) const EmptyHint('Например, «Итог дня» в 22:30 или «Обзор недели» в воскресенье.'),
              for (final r in reminders)
                SwitchListTile(
                  title: Text(r.title),
                  subtitle: Text('${formatMinutes(r.minutes)} · ${maskLabel(r.daysMask)}${r.body == null ? '' : '\n${r.body}'}'),
                  isThreeLine: r.body != null,
                  value: r.enabled,
                  onChanged: (on) => db.saveReminder(RemindersCompanion(id: Value(r.id), enabled: Value(on))),
                  secondary: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => editReminder(context, r)),
                ),
              if (habits.isNotEmpty || trackers.isNotEmpty || programs.isNotEmpty) ...[
                const SectionTitle('Из привычек, трекеров и тренировок'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Меняются в настройках самой привычки, трекера или программы.'),
                ),
                for (final h in habits)
                  ListTile(
                    dense: true,
                    title: Text('${h.icon} ${h.name}'),
                    trailing: Text('${formatMinutes(h.reminderMinutes!)} · ${maskLabel(h.daysMask)}'),
                  ),
                for (final t in trackers)
                  ListTile(
                    dense: true,
                    title: Text('${t.icon} ${t.name}'),
                    trailing: Text('${formatMinutes(t.reminderMinutes!)} · ${maskLabel(t.daysMask)}'),
                  ),
                for (final p in programs)
                  ListTile(
                    dense: true,
                    title: Text('🏋️ ${p.name}'),
                    trailing: Text('${formatMinutes(p.reminderMinutes!)} · ${maskLabel(p.daysMask)}'),
                  ),
              ],
            ],
          );
        },
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
