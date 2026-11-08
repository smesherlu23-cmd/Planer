import 'package:flutter/material.dart';

import 'goals_screen.dart';
import 'journal_screen.dart';
import 'reminders_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'trackers_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    return Scaffold(
      appBar: AppBar(title: const Text('Ещё')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('Трекеры'),
            subtitle: const Text('Вес, время кода, Faceit и любые другие величины'),
            onTap: () => open(const TrackersScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Цели'),
            subtitle: const Text('Прогресс и прогноз, когда дойдёшь'),
            onTap: () => open(const GoalsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: const Text('Записи'),
            subtitle: const Text('Итоги дня, обзоры недели, заметки'),
            onTap: () => open(const JournalScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.insights),
            title: const Text('Отчёт недели'),
            subtitle: const Text('Всё за неделю на одном экране'),
            onTap: () => open(const ReportScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Напоминания'),
            onTap: () => open(const RemindersScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Настройки и данные'),
            subtitle: const Text('Сохранить или загрузить файл, шаблоны'),
            onTap: () => open(const SettingsScreen()),
          ),
        ],
      ),
    );
  }
}
