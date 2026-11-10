import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/database.dart';
import 'package:planer/data/dates.dart';
import 'package:planer/data/time_queries.dart';
import 'package:planer/data/transfer.dart';
import 'package:planer/logic/focus.dart';
import 'package:planer/logic/tasks.dart';
import 'package:planer/services/notifications.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const today = 20261109; // понедельник

  group('быстрый ввод', () {
    test('дата, время, приоритет, оценка и сфера', () {
      final q = parseQuickTask('Урок Docker завтра в 18:00 !1 ~45м #учёба', today: today);
      expect(q.title, 'Урок Docker');
      expect(q.day, 20261110);
      expect(q.time, 18 * 60);
      expect(q.priority, 1);
      expect(q.estimate, 45);
      expect(q.kind, BlockKind.study);
    });

    test('дни недели и даты', () {
      expect(parseQuickTask('Отчёт в пятницу', today: today).day, 20261113);
      expect(parseQuickTask('Отчёт пн', today: today).day, today);
      expect(parseQuickTask('Отчёт во вторник', today: today).day, 20261110);
      expect(parseQuickTask('Врач 15.11', today: today).day, 20261115);
      // Прошедшая дата без года: следующий год.
      expect(parseQuickTask('Праздник 01.01', today: today).day, 20270101);
      expect(parseQuickTask('Сдать 3.12.2026', today: today).day, 20261203);
    });

    test('время без дня ставит сегодня, часы в оценке', () {
      final q = parseQuickTask('Позвонить 9:30 1.5ч', today: today);
      expect(q.day, today);
      expect(q.time, 9 * 60 + 30);
      expect(q.estimate, 90);
      expect(q.title, 'Позвонить');
    });

    test('обычный текст не трогается', () {
      final q = parseQuickTask('Прочитать в метро главу 5', today: today);
      expect(q.title, 'Прочитать в метро главу 5');
      expect(q.day, isNull);
      expect(q.priority, isNull);
    });
  });

  test('следующий день повтора', () {
    expect(nextRepeatDay(TaskRepeat.daily, today, today), 20261110);
    // Пятница по будням: следующий понедельник.
    expect(nextRepeatDay(TaskRepeat.weekdays, 20261113, 20261113), 20261116);
    expect(nextRepeatDay(TaskRepeat.weekly, today, today), 20261116);
    expect(nextRepeatDay(TaskRepeat.monthly, 20260131, 20260131), 20260228);
    // Просроченная ежедневная: следующая не в прошлом.
    expect(nextRepeatDay(TaskRepeat.daily, 20261101, today), 20261110);
  });

  group('база', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('повторяющаяся задача создаёт следующую копию вместе с шагами, а отмена её убирает', () async {
      final id = await db.saveTask(TasksCompanion.insert(title: 'Платёж', day: const Value(today), repeat: const Value(TaskRepeat.weekly)));
      await db.saveTask(TasksCompanion.insert(title: 'Шаг', parentId: Value(id)));
      await db.setTaskDone((await db.taskById(id))!, true, today: today);
      var all = await db.allTasks();
      final copy = all.firstWhere((t) => t.id != id && t.parentId == null);
      expect(copy.day, 20261116);
      expect(copy.doneDay, isNull);
      expect(all.where((t) => t.parentId == copy.id).length, 1);

      await db.setTaskDone((await db.taskById(id))!, false, today: today);
      all = await db.allTasks();
      expect(all.where((t) => t.parentId == null).length, 1);
      expect(all.firstWhere((t) => t.parentId == null).doneDay, isNull);
      expect(all.length, 2);
    });

    test('списки: просрочено, главное, входящие, скоро', () async {
      await db.saveTask(TasksCompanion.insert(title: 'Старое', day: const Value(20261105)));
      await db.saveTask(
        TasksCompanion.insert(title: 'Главное', day: const Value(today), priority: const Value(1), estimate: const Value(60)),
      );
      await db.saveTask(TasksCompanion.insert(title: 'Обычное', day: const Value(today), estimate: const Value(30)));
      await db.saveTask(TasksCompanion.insert(title: 'Идея'));
      await db.saveTask(TasksCompanion.insert(title: 'Потом', day: const Value(20261201)));
      final all = await db.allTasks();
      final t = todayTasks(all, today);
      expect(t.overdue.map((e) => e.title), ['Старое']);
      expect(t.main.map((e) => e.title), ['Главное']);
      expect(t.other.map((e) => e.title), ['Обычное']);
      expect(t.estimateLeft, 90);
      expect(inboxTasks(all).map((e) => e.title), ['Идея']);
      expect(upcomingTasks(all, today)[null]!.map((e) => e.title), ['Потом']);
      expect(suggestTask(t, BlockKind.work)!.title, 'Главное');
    });

    test('таймер: закончившийся отрезок записывается один раз, ранняя остановка пишет минуты', () async {
      final start = DateTime(2026, 11, 9, 18);
      await db.setFocusState(FocusState.start(minutes: 25, now: start, kind: BlockKind.study));
      expect(await db.finishFocusIfDue(now: start.add(const Duration(minutes: 10))), isNull);
      expect(await db.finishFocusIfDue(now: start.add(const Duration(minutes: 26))), 25);
      expect(await db.finishFocusIfDue(now: start.add(const Duration(minutes: 27))), isNull);
      var sessions = await db.select(db.focusSessions).get();
      expect(sessions.single.minutes, 25);
      expect(sessions.single.at, start);

      await db.setFocusState(FocusState.start(minutes: 25, now: start));
      expect(await db.stopFocus(now: start.add(const Duration(minutes: 12, seconds: 30))), 12);
      sessions = await db.select(db.focusSessions).get();
      expect(sessions.length, 2);
      expect(await db.focusState(), isNull);
    });

    test('новые таблицы попадают в файл с данными', () async {
      final id = await db.saveTask(TasksCompanion.insert(title: 'Задача', day: const Value(today)));
      await db.addFocus(at: DateTime(2026, 11, 9, 10), minutes: 25, taskId: id);
      final json = await exportJson(db);
      final other = AppDatabase(NativeDatabase.memory());
      await importJson(other, json);
      expect((await other.allTasks()).single.title, 'Задача');
      expect((await other.select(other.focusSessions).get()).single.taskId, id);
      await other.close();
    });
  });

  test('пауза и продолжение сохраняют остаток', () {
    final start = DateTime(2026, 11, 9, 18);
    final s = FocusState.start(minutes: 25, now: start);
    final paused = s.pause(start.add(const Duration(minutes: 5)));
    expect(paused.paused, isTrue);
    expect(paused.secondsLeft(start.add(const Duration(hours: 1))), 20 * 60);
    final resumed = FocusState.decode(paused.encode())!.resume(start.add(const Duration(hours: 1)));
    expect(resumed.secondsLeft(start.add(const Duration(hours: 1, minutes: 5))), 15 * 60);
  });

  test('итоги недели и точность оценок', () {
    Task task(int id, {int? estimate, int? doneDay}) => Task(
      id: id,
      title: 'Т$id',
      remind: false,
      priority: 4,
      estimate: estimate,
      repeat: TaskRepeat.none,
      doneDay: doneDay,
      sortOrder: 0,
      createdAt: DateTime(2026),
    );
    final tasks = [for (var i = 1; i <= 3; i++) task(i, estimate: 30, doneDay: today)];
    final sessions = [
      for (var i = 1; i <= 3; i++)
        FocusSession(id: i, day: today, at: DateTime(2026, 11, 9, 10), minutes: 45, taskId: i, kind: BlockKind.study),
    ];
    final w = timeWeek(weekStartDay: weekStart(today), tasks: tasks, sessions: sessions, blocks: const []);
    expect(w.focusTotal, 135);
    expect(w.doneTotal, 3);
    expect(w.focusByKind[BlockKind.study], 135);
    expect(w.estimateRatio, closeTo(1.5, 0.001));
    expect(focusStreak(sessions, addDays(today, 1)), 1);
  });

  test('разовые напоминания: задача со временем и конец фокуса', () {
    final now = DateTime(2026, 11, 9, 12);
    final t = Task(
      id: 5,
      title: 'Кредит',
      day: today,
      time: 19 * 60,
      remind: true,
      priority: 2,
      repeat: TaskRepeat.none,
      sortOrder: 0,
      createdAt: now,
    );
    final past = t.copyWith(id: 6, time: const Value(9 * 60));
    final plan = planOnceNotifications(
      tasks: [t, past],
      focus: FocusState.start(minutes: 25, now: now),
      now: now,
    );
    expect(plan.length, 2);
    expect(plan.first.at, DateTime(2026, 11, 9, 19));
    expect(plan.last.id, focusNotificationId);
  });
}
