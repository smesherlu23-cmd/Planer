import 'package:flutter/material.dart';

import '../data/templates.dart';
import 'common.dart';
import 'theme.dart';

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
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
              ),
            ),
            const SizedBox(height: 20),
            Text('Planer', style: text.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Привычки, трекеры, цели, деньги, тренировки и записи в одном месте. Всё хранится только на телефоне.',
              style: text.bodyLarge?.copyWith(color: muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Pill('✅ Привычки', color: Accent.habits),
                Pill('📈 Трекеры', color: Accent.trackers),
                Pill('🎯 Цели', color: Accent.goals),
                Pill('💰 Деньги', color: Accent.money),
                Pill('💪 Спорт', color: Accent.workouts),
                Pill('📝 Записи', color: Accent.journal),
              ],
            ),
            const SizedBox(height: 36),
            Text('С чего начнём?', style: text.titleLarge),
            const SizedBox(height: 12),
            for (final t in templates)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: _busy ? null : () => _start(t),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EmojiAvatar(t.id == 'my_plan' ? '🗺️' : '✨', size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title, style: text.titleMedium),
                              const SizedBox(height: 4),
                              Text(t.description, style: TextStyle(color: muted, height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: muted),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Шаблон просто создаёт обычные записи. Потом всё можно поменять, удалить или добавить своё.',
              style: TextStyle(color: muted, height: 1.4),
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
