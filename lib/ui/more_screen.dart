import 'package:flutter/material.dart';

import 'common.dart';
import 'goals_screen.dart';
import 'journal_screen.dart';
import 'reminders_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';
import 'trackers_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    final tiles = [
      _Tile(
        icon: Icons.show_chart_rounded,
        color: Accent.trackers,
        title: 'Трекеры',
        subtitle: 'Вес, время, Faceit',
        onTap: () => open(const TrackersScreen()),
      ),
      _Tile(
        icon: Icons.flag_rounded,
        color: Accent.goals,
        title: 'Цели',
        subtitle: 'Прогресс и прогноз',
        onTap: () => open(const GoalsScreen()),
      ),
      _Tile(
        icon: Icons.auto_stories_rounded,
        color: Accent.journal,
        title: 'Записи',
        subtitle: 'Итоги дня и недели',
        onTap: () => open(const JournalScreen()),
      ),
      _Tile(
        icon: Icons.insights_rounded,
        color: Accent.report,
        title: 'Отчёт недели',
        subtitle: 'Всё на одном экране',
        onTap: () => open(const ReportScreen()),
      ),
    ];
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const PageHeader(title: 'Ещё'),
          // Плитки по две в ряд. Высота по содержимому, чтобы крупный шрифт в системе ничего не обрезал.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < tiles.length; i += 2)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: tiles[i]),
                        Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GroupCard(
            children: [
              ListTile(
                leading: const IconBadge(Icons.notifications_rounded, color: Accent.reminders),
                title: const Text('Напоминания'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => open(const RemindersScreen()),
              ),
              ListTile(
                leading: const IconBadge(Icons.settings_rounded, color: Accent.settings),
                title: const Text('Настройки и данные'),
                subtitle: const Text('Тема, файл с данными, шаблоны'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => open(const SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon, color: color, size: 42),
              const SizedBox(height: 22),
              Text(title, style: theme.textTheme.titleMedium),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
