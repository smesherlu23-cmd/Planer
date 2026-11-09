import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/database.dart';
import 'package:planer/data/dates.dart';
import 'package:planer/data/queries.dart';
import 'package:planer/data/templates.dart';
import 'package:planer/data/transfer.dart';
import 'package:planer/services/notifications.dart';

AppDatabase memoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  test('шаблон «Мой план» создаёт записи и не падает', () async {
    await applyTemplate(db, 'my_plan', today: 20261109);
    // Отбой теперь ведёт раздел «Сон», отдельной привычки нет.
    expect((await db.select(db.habits).get()).length, 2);
    expect((await db.select(db.trackers).get()).length, 5);
    expect((await db.select(db.goals).get()).length, 5);
    expect((await db.select(db.funds).get()).length, 3);
    expect((await db.select(db.programs).get()).length, 3);
    expect((await db.select(db.programExercises).get()).length, 16);
    expect((await db.select(db.categories).get()).length, 11);
    expect((await db.select(db.reminders).get()).length, 2);
    expect((await db.select(db.foods).get()).length, 10);
    expect((await db.select(db.timeBlocks).get()).length, 10);
    expect((await db.select(db.budgetLines).get()).length, 7);
    final settings = await db.watchAllSettings().first;
    expect(settings['sleep_on'], '1');
    expect(settings['food_kcal'], '3000');
  });

  test('запись в трекер отмечает привязанную привычку', () async {
    final t = await db.saveTracker(TrackersCompanion.insert(name: 'Код', kind: TrackerKind.duration));
    final h = await db.saveHabit(HabitsCompanion.insert(name: 'Код', trackerId: Value(t)));
    await db.addEntry(t, 45, day: 20261109);
    await db.addEntry(t, 30, day: 20261109);
    final logs = await db.select(db.habitLogs).get();
    expect(logs.length, 1);
    expect(logs.single.habitId, h);
    expect(logs.single.day, 20261109);
  });

  test('ответ «нет» в трекере да/нет не отмечает привычку', () async {
    final t = await db.saveTracker(TrackersCompanion.insert(name: 'Прогулка', kind: TrackerKind.yesNo));
    await db.saveHabit(HabitsCompanion.insert(name: 'Прогулка', trackerId: Value(t)));
    await db.addEntry(t, 0, day: 20261109);
    expect(await db.select(db.habitLogs).get(), isEmpty);
  });

  test('экспорт и импорт возвращают те же данные', () async {
    await applyTemplate(db, 'my_plan', today: 20261109);
    final h = (await db.select(db.habits).get()).first;
    await db.setHabitDone(h.id, 20261109, done: true, minimum: true);
    final fund = (await db.select(db.funds).get()).first;
    await db.addFundMove(fund.id, 12000, day: 20261110, note: 'платёж');
    await db.setSetting('setup_done', '1');
    final json = await exportJson(db);

    final other = memoryDb();
    addTearDown(other.close);
    // Во второй базе уже есть свои данные: импорт должен их заменить.
    await applyTemplate(other, 'basic');
    await other.saveHabit(HabitsCompanion.insert(name: 'Лишняя'));
    final summary = await importJson(other, json);
    expect(summary.total, greaterThan(40));

    final again = await exportJson(other);
    String strip(String s) => s.replaceFirst(RegExp(r'"exportedAt": "[^"]*"'), '');
    expect(strip(again), strip(json));

    final habits = await other.select(other.habits).get();
    expect(habits.map((h) => h.name), isNot(contains('Лишняя')));
    final logs = await other.select(other.habitLogs).get();
    expect(logs.single.minimum, isTrue);
    // Новые записи после импорта получают свободные id.
    final newId = await other.saveHabit(HabitsCompanion.insert(name: 'Новая'));
    expect(newId, greaterThan(habits.map((h) => h.id).reduce((a, b) => a > b ? a : b)));
  });

  test('импорт чужого файла не трогает базу', () async {
    await applyTemplate(db, 'basic');
    expect(() => importJson(db, '{"app":"other"}'), throwsA(isA<ImportException>()));
    expect(() => importJson(db, 'not json'), throwsA(isA<ImportException>()));
    expect(() => importJson(db, '{"app":"planer","format":99,"tables":{}}'), throwsA(isA<ImportException>()));
    expect((await db.select(db.categories).get()).length, 11);
  });

  test('сломанная строка откатывает весь импорт', () async {
    await applyTemplate(db, 'basic');
    const bad = '{"app":"planer","format":1,"schema":1,"tables":{"habits":[{"id":1,"name":null}]}}';
    await expectLater(importJson(db, bad), throwsA(anything));
    expect((await db.select(db.categories).get()).length, 11);
  });

  test('значение долга и копилки', () async {
    final debt = await db.saveFund(FundsCompanion.insert(name: 'Д', kind: FundKind.debt, initialAmount: const Value(1000)));
    final save = await db.saveFund(FundsCompanion.insert(name: 'К', kind: FundKind.savings, initialAmount: const Value(100)));
    await db.addFundMove(debt, 300);
    await db.addFundMove(debt, 900);
    await db.addFundMove(save, 50);
    await db.addFundMove(save, -20);
    final values = await db.watchFundValues().first;
    expect(values[debt], 0);
    expect(values[save], 130);
  });

  test('удаление привычки удаляет её отметки', () async {
    final h = await db.saveHabit(HabitsCompanion.insert(name: 'Х'));
    await db.setHabitDone(h, 20261109, done: true);
    await db.deleteById(db.habits, h);
    expect(await db.select(db.habitLogs).get(), isEmpty);
  });

  test('напоминания тренировок в одно время объединяются', () async {
    await applyTemplate(db, 'my_plan', today: 20261109);
    final plan = planNotifications(
      habits: await db.select(db.habits).get(),
      trackers: await db.select(db.trackers).get(),
      programs: await db.select(db.programs).get(),
      reminders: await db.select(db.reminders).get(),
    );
    final workouts = plan.where((p) => p.title.contains('Тренировка')).toList();
    expect(workouts.length, 3); // пн, ср, пт
    expect(workouts.first.body, contains('Тренировка A'));
    expect(workouts.first.body, contains('Тренировка B'));
    final ids = <int>{};
    for (final p in plan) {
      for (final w in weekdaysFromMask(p.daysMask)) {
        expect(ids.add(p.baseId * 10 + w), isTrue, reason: 'id повторяется');
      }
    }
  });
}
