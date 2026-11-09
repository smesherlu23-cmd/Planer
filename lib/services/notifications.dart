/// Локальные напоминания. Работают без интернета и без сервера.
///
/// Каждый раз, когда меняются привычки, трекеры, программы или напоминания,
/// всё расписание пересоздаётся заново. Так проще и надёжнее, чем
/// отслеживать изменения по одному.
library;

import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate, TableUpdateQuery;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/database.dart';
import '../data/dates.dart';
import '../logic/sleep.dart';

/// Одно повторяющееся напоминание: в какие дни недели и во сколько.
class PlannedNotification {
  const PlannedNotification({required this.baseId, required this.title, required this.body, required this.daysMask, required this.minutes});

  /// Уникальный номер. Итоговый id уведомления = baseId * 10 + день недели.
  final int baseId;
  final String title;
  final String body;
  final int daysMask;
  final int minutes;
}

/// Собрать список напоминаний из базы. Чистая функция, её легко проверить.
List<PlannedNotification> planNotifications({
  required List<Habit> habits,
  required List<Tracker> trackers,
  required List<Program> programs,
  required List<Reminder> reminders,
  SleepGoals? sleep,
}) {
  final result = <PlannedNotification>[];
  for (final h in habits) {
    if (h.archived || h.reminderMinutes == null || h.daysMask == 0) continue;
    result.add(
      PlannedNotification(
        baseId: 100000 + h.id,
        title: h.name,
        body: h.minimumText == null ? 'Пора сделать и отметить.' : 'Если день тяжёлый, хватит минимума: ${h.minimumText}',
        daysMask: h.daysMask,
        minutes: h.reminderMinutes!,
      ),
    );
  }
  for (final t in trackers) {
    if (t.archived || t.reminderMinutes == null || t.daysMask == 0) continue;
    result.add(
      PlannedNotification(
        baseId: 200000 + t.id,
        title: t.name,
        body: 'Запиши значение за сегодня.',
        daysMask: t.daysMask,
        minutes: t.reminderMinutes!,
      ),
    );
  }
  // Программы с одинаковым временем объединяем: при чередовании A и B
  // в один день не нужно два уведомления.
  final byTime = <(int, int), List<String>>{};
  for (final p in programs) {
    if (p.archived || p.reminderMinutes == null || p.daysMask == 0) continue;
    for (final w in weekdaysFromMask(p.daysMask)) {
      byTime.putIfAbsent((w, p.reminderMinutes!), () => []).add(p.name);
    }
  }
  for (final e in byTime.entries) {
    final (weekday, minutes) = e.key;
    final names = e.value;
    result.add(
      PlannedNotification(
        baseId: 300000 + minutes * 10 + weekday,
        title: 'Тренировка',
        body: names.length == 1 ? names.first : 'Одна из: ${names.join(', ')}',
        daysMask: maskFromWeekdays([weekday]),
        minutes: minutes,
      ),
    );
  }
  for (final r in reminders) {
    if (!r.enabled || r.daysMask == 0) continue;
    result.add(PlannedNotification(baseId: 400000 + r.id, title: r.title, body: r.body ?? '', daysMask: r.daysMask, minutes: r.minutes));
  }
  final before = sleep?.remindBefore;
  if (sleep != null && before != null) {
    result.add(
      PlannedNotification(
        baseId: 500000,
        title: 'Скоро отбой',
        body: 'Через ${formatDuration(before)} спать, отбой в ${formatMinutes(sleep.bed)}. Отложи телефон и нажми «Ложусь спать».',
        daysMask: everyDay,
        minutes: (sleep.bed - before) % (24 * 60),
      ),
    );
  }
  return result;
}

class NotificationService {
  NotificationService(this.db);

  final AppDatabase db;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  StreamSubscription<Set<TableUpdate>>? _sub;
  Timer? _debounce;

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    if (!_supported) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
      }
      await _plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_planer')));
      _ready = true;
    } on PlatformException catch (e) {
      debugPrint('Уведомления недоступны: $e');
      return;
    }
    // Любое изменение расписаний пересоздаёт напоминания.
    _sub = db
        .tableUpdates(TableUpdateQuery.onAllTables([db.habits, db.trackers, db.programs, db.reminders, db.settings]))
        .listen((_) => _scheduleSoon());
    await reschedule();
  }

  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
  }

  void _scheduleSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), reschedule);
  }

  /// Попросить разрешение на уведомления (Android 13+).
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    return await _android?.requestNotificationsPermission() ?? false;
  }

  Future<bool> notificationsEnabled() async {
    if (!_ready) return false;
    return await _android?.areNotificationsEnabled() ?? false;
  }

  Future<bool> canExact() async {
    if (!_ready) return false;
    return await _android?.canScheduleExactNotifications() ?? false;
  }

  /// Открыть системную настройку точных будильников.
  Future<void> requestExact() async {
    if (!_ready) return;
    await _android?.requestExactAlarmsPermission();
    await reschedule();
  }

  Future<void> showTest() async {
    if (!_ready) return;
    await _plugin.show(id: 1, title: 'Planer', body: 'Так будут выглядеть напоминания.', notificationDetails: _details);
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Напоминания',
      channelDescription: 'Привычки, трекеры, тренировки и свои напоминания',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<int> reschedule() async {
    if (!_ready) return 0;
    final plan = planNotifications(
      habits: await db.select(db.habits).get(),
      trackers: await db.select(db.trackers).get(),
      programs: await db.select(db.programs).get(),
      reminders: await db.select(db.reminders).get(),
      sleep: SleepGoals.from({for (final r in await db.select(db.settings).get()) r.key: r.value}),
    );
    final mode = await canExact() ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
    await _plugin.cancelAll();
    var count = 0;
    for (final n in plan) {
      for (final weekday in weekdaysFromMask(n.daysMask)) {
        await _plugin.zonedSchedule(
          id: n.baseId * 10 + weekday,
          title: n.title,
          body: n.body,
          scheduledDate: nextInstance(weekday, n.minutes, tz.TZDateTime.now(tz.local)),
          notificationDetails: _details,
          androidScheduleMode: mode,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        count++;
      }
    }
    return count;
  }
}

/// Ближайший момент с нужным днём недели и временем, строго в будущем.
tz.TZDateTime nextInstance(int weekday, int minutes, tz.TZDateTime now) {
  var t = tz.TZDateTime(now.location, now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
  while (t.weekday != weekday || !t.isAfter(now)) {
    t = tz.TZDateTime(now.location, t.year, t.month, t.day + 1, minutes ~/ 60, minutes % 60);
  }
  return t;
}
