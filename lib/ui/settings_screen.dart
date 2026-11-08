import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/templates.dart';
import '../data/transfer.dart';
import 'common.dart';
import 'theme.dart';

const _backupName = 'before-import.json';

Future<File> _backupFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, _backupName));
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _busy = false;
  bool? _notifOn;
  bool? _exact;
  bool _hasBackup = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final n = context.notifications;
    final on = await n.notificationsEnabled();
    final exact = await n.canExact();
    var backup = false;
    try {
      backup = await (await _backupFile()).exists();
    } catch (_) {
      // Нет доступа к папке приложения: просто не показываем кнопку возврата.
    }
    if (mounted) {
      setState(() {
        _notifOn = on;
        _exact = exact;
        _hasBackup = backup;
      });
    }
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
    } catch (e) {
      if (mounted) showSnack(context, 'Не получилось: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveToFile() => _run(() async {
    final json = await exportJson(context.db);
    final uri = await FilePicker.saveFile(
      fileName: exportFileName(),
      bytes: utf8.encode(json),
      mimeType: 'application/json',
      dialogTitle: 'Куда сохранить данные',
    );
    if (uri != null && mounted) showSnack(context, 'Сохранено');
  });

  Future<void> _share() => _run(() async {
    final json = await exportJson(context.db);
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, exportFileName()));
    await file.writeAsString(json);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Данные Planer',
      ),
    );
  });

  Future<void> _import() async {
    final db = context.db;
    final files = await FilePicker.pickFiles(dialogTitle: 'Файл Planer (.json)');
    if (files.isEmpty || !mounted) return;
    final String json;
    try {
      json = await files.first.xFile.readAsString();
    } catch (e) {
      if (mounted) showSnack(context, 'Не получилось прочитать файл');
      return;
    }
    final ImportSummary summary;
    try {
      summary = inspectImport(db, json);
    } on ImportException catch (e) {
      if (mounted) showSnack(context, e.message);
      return;
    }
    if (!mounted) return;
    final ok = await confirm(
      context,
      'Заменить все данные?',
      text:
          'В файле ${summary.total} записей. Всё, что сейчас в приложении, заменится данными из файла. '
          'Текущие данные я сначала сохраню, и их можно будет вернуть кнопкой «Вернуть данные до импорта».',
      ok: 'Заменить',
      danger: true,
    );
    if (!ok || !mounted) return;
    await _run(() async {
      final backup = await _backupFile();
      await backup.writeAsString(await exportJson(db));
      await importJson(db, json);
      if (mounted) showSnack(context, 'Данные загружены');
      await _refresh();
    });
  }

  Future<void> _restore() async {
    final db = context.db;
    final ok = await confirm(
      context,
      'Вернуть данные до импорта?',
      text: 'Текущие данные заменятся теми, что были перед последней загрузкой файла.',
      ok: 'Вернуть',
      danger: true,
    );
    if (!ok) return;
    await _run(() async {
      final backup = await _backupFile();
      await importJson(db, await backup.readAsString());
      await backup.delete();
      if (mounted) showSnack(context, 'Данные возвращены');
      await _refresh();
    });
  }

  Future<void> _addTemplate(TemplateInfo t) async {
    final ok = await confirm(
      context,
      'Добавить «${t.title}»?',
      text: '${t.description}\n\nТекущие данные не удаляются, шаблон добавится к ним.',
      ok: 'Добавить',
    );
    if (!ok || !mounted) return;
    await _run(() async {
      await applyTemplate(context.db, t.id);
      if (mounted) showSnack(context, 'Шаблон добавлен');
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = context.notifications;
    final db = context.db;
    final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки и данные')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (_busy) const LinearProgressIndicator(),
            const SectionTitle('Оформление'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<String?>(
                stream: db.watchSetting('theme'),
                builder: (context, snap) => SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'system', label: Text('Как в системе'), icon: Icon(Icons.brightness_auto_outlined)),
                    ButtonSegment(value: 'light', label: Text('Светлая'), icon: Icon(Icons.light_mode_outlined)),
                    ButtonSegment(value: 'dark', label: Text('Тёмная'), icon: Icon(Icons.dark_mode_outlined)),
                  ],
                  selected: {snap.data ?? 'system'},
                  onSelectionChanged: (v) => db.setSetting('theme', v.first == 'system' ? null : v.first),
                ),
              ),
            ),
            const SectionTitle('Данные'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Все данные хранятся только на этом телефоне. Файл с ними можно сохранить, отправить себе или Claude, '
                'а потом загрузить на другом телефоне.',
                style: muted,
              ),
            ),
            GroupCard(
              children: [
                ListTile(
                  leading: const IconBadge(Icons.save_alt_rounded, color: Accent.trackers),
                  title: const Text('Сохранить в файл'),
                  subtitle: const Text('Выбрать папку на телефоне'),
                  onTap: _saveToFile,
                ),
                ListTile(
                  leading: const IconBadge(Icons.ios_share_rounded, color: Accent.goals),
                  title: const Text('Отправить файл'),
                  subtitle: const Text('В Telegram, на почту, в облако'),
                  onTap: _share,
                ),
                ListTile(
                  leading: const IconBadge(Icons.upload_file_rounded, color: Accent.workouts),
                  title: const Text('Загрузить из файла'),
                  subtitle: const Text('Заменит все текущие данные'),
                  onTap: _import,
                ),
                if (_hasBackup)
                  ListTile(
                    leading: const IconBadge(Icons.restore_rounded, color: Accent.settings),
                    title: const Text('Вернуть данные до импорта'),
                    onTap: _restore,
                  ),
              ],
            ),
            const SectionTitle('Напоминания'),
            GroupCard(
              children: [
                ListTile(
                  leading: IconBadge(
                    _notifOn == true ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                    color: _notifOn == true ? Accent.habits : Accent.settings,
                  ),
                  title: Text(_notifOn == true ? 'Уведомления разрешены' : 'Уведомления выключены'),
                  subtitle: _notifOn == true ? null : const Text('Нажми, чтобы разрешить'),
                  onTap: () async {
                    await n.requestPermission();
                    await _refresh();
                  },
                ),
                ListTile(
                  leading: IconBadge(Icons.alarm_rounded, color: _exact == true ? Accent.habits : Accent.settings),
                  title: Text(_exact == true ? 'Точное время включено' : 'Точное время выключено'),
                  subtitle: Text(
                    _exact == true
                        ? 'Напоминания приходят минута в минуту'
                        : 'Без него Android может сдвигать напоминания на несколько минут. Нажми, чтобы включить',
                  ),
                  onTap: () async {
                    await n.requestExact();
                    await _refresh();
                  },
                ),
                ListTile(
                  leading: const IconBadge(Icons.notification_add_rounded, color: Accent.reminders),
                  title: const Text('Проверить уведомление'),
                  onTap: () async {
                    await n.showTest();
                    final count = await n.reschedule();
                    if (context.mounted) showSnack(context, 'Запланировано напоминаний на неделю: $count');
                  },
                ),
              ],
            ),
            const SectionTitle('Шаблоны'),
            GroupCard(
              children: [
                for (final t in templates)
                  ListTile(
                    leading: const IconBadge(Icons.library_add_rounded, color: Accent.report),
                    title: Text('Добавить «${t.title}»'),
                    subtitle: Text(t.description),
                    onTap: () => _addTemplate(t),
                  ),
              ],
            ),
            const SectionTitle('О приложении'),
            const GroupCard(
              children: [
                ListTile(
                  leading: IconBadge(Icons.check_rounded, color: Color(0xFF6366F1)),
                  title: Text('Planer'),
                  subtitle: Text('Личный органайзер. Работает без интернета, ничего никуда не отправляет.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
