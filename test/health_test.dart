import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/database.dart';
import 'package:planer/data/dates.dart';
import 'package:planer/data/icon_keys.dart';
import 'package:planer/data/queries.dart';
import 'package:planer/logic/food.dart';
import 'package:planer/logic/sleep.dart';
import 'package:planer/services/notifications.dart';

SleepLog night(int id, int wakeDay, int bed, int wake) {
  final t = sleepTimes(wakeDay: wakeDay, bedMinutes: bed, wakeMinutes: wake);
  return SleepLog(id: id, day: wakeDay, bedAt: t.bedAt, wakeAt: t.wakeAt);
}

/// Убрать из базы всё, что появилось в версии 3.
Future<void> downgradeToV2(AppDatabase db) async {
  for (final t in ['budget_lines', 'time_blocks', 'hard_days']) {
    await db.customStatement('DROP TABLE "$t"');
  }
  for (final (table, column) in [
    ('trackers', 'daily_goal'),
    ('trackers', 'daily_min'),
    ('goals', 'minimum_value'),
    ('programs', 'min_sets'),
    ('programs', 'minimum_text'),
    ('workout_sessions', 'minimum'),
  ]) {
    await db.customStatement('ALTER TABLE "$table" DROP COLUMN "$column"');
  }
  await db.customStatement('PRAGMA user_version = 2');
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('отбой до полуночи считается вчерашним днём', () {
    final t = sleepTimes(wakeDay: 20261109, bedMinutes: 23 * 60 + 30, wakeMinutes: 7 * 60);
    expect(t.bedAt, DateTime(2026, 11, 8, 23, 30));
    expect(t.wakeAt, DateTime(2026, 11, 9, 7));
    final after = sleepTimes(wakeDay: 20261109, bedMinutes: 30, wakeMinutes: 8 * 60);
    expect(after.bedAt, DateTime(2026, 11, 9, 0, 30));
  });

  test('статистика сна: среднее, вовремя, серия, недосып', () {
    const g = SleepGoals(bed: 23 * 60, wake: 7 * 60, duration: 8 * 60);
    final logs = [
      night(1, 20261105, 23 * 60, 7 * 60), // 8 ч, вовремя
      night(2, 20261106, 0 * 60 + 30, 7 * 60), // 6,5 ч, поздно
      night(3, 20261107, 22 * 60 + 50, 7 * 60), // 8 ч 10 мин, вовремя
      night(4, 20261108, 23 * 60 + 10, 7 * 60), // 7 ч 50 мин, вовремя (в пределах 15 минут)
      night(5, 20261109, 23 * 60, 6 * 60), // 7 ч, вовремя
    ];
    final s = sleepStats(logs, g, from: 20261103, to: 20261109, today: 20261109);
    expect(s.nights, 5);
    expect(s.onTime, 4);
    expect(s.streak, 3);
    // Недосып: 90 + 10 + 60 минут.
    expect(s.debt, 160);
    // Средний отбой около 23:18, а не «средне между 23:00 и 00:30» по часам.
    expect(s.avgBed, inInclusiveRange(23 * 60 + 10, 23 * 60 + 25));
    expect(minutesUntilBed(DateTime(2026, 11, 9, 22), 23 * 60), 60);
  });

  test('питание: итог дня и норма калорий', () {
    final meals = [
      Meal(id: 1, day: 20261109, at: DateTime(2026, 11, 9, 8), name: 'Завтрак', icon: 'breakfast', kcal: 700, protein: 30),
      Meal(id: 2, day: 20261109, at: DateTime(2026, 11, 9, 13), name: 'Обед', icon: 'lunch', kcal: 750, protein: 50),
      Meal(id: 3, day: 20261108, at: DateTime(2026, 11, 8, 13), name: 'Обед', icon: 'lunch', kcal: 750, protein: 50),
    ];
    final water = [
      WaterLog(id: 1, day: 20261109, at: DateTime(2026, 11, 9, 9), ml: 250),
      WaterLog(id: 2, day: 20261109, at: DateTime(2026, 11, 9, 12), ml: 250),
    ];
    final d = dayFood(20261109, meals, water);
    expect(d.kcal, 1450);
    expect(d.protein, 80);
    expect(d.water, 500);
    final gain = FoodGoals.from({'food_kcal': '3000', 'food_mode': 'gain'});
    expect(kcalOnTarget(2700, gain), isTrue);
    expect(kcalOnTarget(2600, gain), isFalse);
    final lose = FoodGoals.from({'food_kcal': '2000', 'food_mode': 'lose'});
    expect(kcalOnTarget(2150, lose), isTrue);
    expect(kcalOnTarget(2300, lose), isFalse);
  });

  test('подсказка по весу на наборе массы', () {
    const today = 20261121;
    List<(int, double)> series(double perDay) => [for (var i = 0; i <= 14; i++) (addDays(today, -14 + i), 67 + i * perDay)];
    expect(weightAdvice(series(0.0), FoodMode.gain, today: today)!.adjust, isTrue);
    expect(weightAdvice(series(0.03), FoodMode.gain, today: today)!.adjust, isFalse);
    expect(weightAdvice(series(0.1), FoodMode.gain, today: today)!.adjust, isTrue);
    // Мало дней: подсказки нет.
    expect(weightAdvice([(today - 3, 67.0), (today, 67.5)], FoodMode.gain, today: today), isNull);
  });

  test('блюдо в один тап, вода и сон в базе', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.saveFood(FoodsCompanion.insert(name: 'Творог', kcal: 250, protein: const Value(30)));
    final food = (await db.watchFoods().first).single;
    await db.eatFood(food, day: 20261109);
    await db.addWater(250, day: 20261109);
    await db.addWater(250, day: 20261109);
    await db.undoWater(20261109);
    final meals = await db.mealsBetween(20261109, 20261109);
    expect(meals.single.name, 'Творог');
    expect(meals.single.foodId, food.id);
    expect((await db.waterBetween(20261109, 20261109)).length, 1);

    // Вторая запись сна за тот же день заменяет первую.
    final t = sleepTimes(wakeDay: 20261109, bedMinutes: 23 * 60, wakeMinutes: 7 * 60);
    await db.saveSleep(SleepLogsCompanion.insert(day: 20261109, bedAt: t.bedAt, wakeAt: t.wakeAt));
    await db.saveSleep(SleepLogsCompanion.insert(day: 20261109, bedAt: t.bedAt, wakeAt: t.wakeAt, quality: const Value(4)));
    final logs = await db.sleepBetween(20261109, 20261109);
    expect(logs.single.quality, 4);
  });

  test('напоминание «скоро отбой» за полчаса до цели', () {
    final plan = planNotifications(
      habits: const [],
      trackers: const [],
      programs: const [],
      reminders: const [],
      sleep: const SleepGoals(bed: 15, wake: 7 * 60, duration: 8 * 60, remindBefore: 30),
    );
    expect(plan.single.title, 'Скоро отбой');
    expect(plan.single.minutes, 1440 - 15);
    expect(plan.single.daysMask, 127);
  });

  test('старые эмодзи переводятся в ключи иконок', () {
    expect(iconKeyFor('😴'), 'bedtime');
    expect(iconKeyFor('⚖️'), 'scale');
    expect(iconKeyFor('code'), 'code');
    expect(iconKeyFor(null), isNull);
  });

  test('переход со старой версии базы: новые таблицы и иконки вместо эмодзи', () async {
    final dir = await Directory.systemTemp.createTemp('planer_migration');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    // Делаем базу «как в версии 1»: без таблиц сна и питания, с эмодзи в иконках.
    final current = AppDatabase(NativeDatabase(file));
    await current.saveHabit(HabitsCompanion.insert(name: 'Код', icon: const Value('💻')));
    await current.saveHabit(HabitsCompanion.insert(name: 'Своя', icon: const Value('🦄')));
    await downgradeToV2(current);
    for (final t in ['water_logs', 'meals', 'foods', 'sleep_logs']) {
      await current.customStatement('DROP TABLE "$t"');
    }
    await current.customStatement('PRAGMA user_version = 1');
    await current.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final habits = await db.select(db.habits).get();
    expect(habits.map((h) => h.icon), ['code', '🦄']);
    await db.addWater(250, day: 20261109);
    expect((await db.waterBetween(20261109, 20261109)).single.ml, 250);
  });

  test('переход с версии 2: тяжёлый день из настройки переезжает в таблицу', () async {
    final dir = await Directory.systemTemp.createTemp('planer_migration3');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final current = AppDatabase(NativeDatabase(file));
    await current.saveTracker(TrackersCompanion.insert(name: 'Код', kind: TrackerKind.duration));
    await downgradeToV2(current);
    await current.customStatement("INSERT INTO settings (key, value) VALUES ('bad_day', '20261109')");
    await current.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect(await db.isHardDay(20261109), isTrue);
    expect((await db.watchAllSettings().first).containsKey('bad_day'), isFalse);
    final t = (await db.select(db.trackers).get()).single;
    expect(t.dailyGoal, isNull);
  });
}
