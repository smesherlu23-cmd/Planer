import 'package:flutter/material.dart';

import '../data/templates.dart';
import 'common.dart';

/// Первый запуск: выбрать шаблон или начать с чистого листа.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  var _busy = false;

  Future<void> _start(TemplateInfo t) async {
    setState(() => _busy = true);
    final db = context.db;
    final notifications = context.notifications;
    try {
      await applyTemplate(db, t.id);
      await notifications.requestPermission();
      await db.setSetting('setup_done', '1');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, 'Не получилось: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Text('Planer', style: text.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Привычки, трекеры, цели, деньги, тренировки и записи в одном месте. Всё хранится только на телефоне.',
              style: text.bodyLarge,
            ),
            const SizedBox(height: 32),
            Text('С чего начнём?', style: text.titleMedium),
            const SizedBox(height: 12),
            for (final t in templates)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(t.title, style: text.titleMedium),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(t.description)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy ? null : () => _start(t),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Шаблон просто создаёт обычные записи. Потом всё можно поменять, удалить или добавить своё.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
