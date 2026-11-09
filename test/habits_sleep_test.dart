import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/database.dart';
import 'package:planer/data/dates.dart';
import 'package:planer/data/habit_queries.dart';
import 'package:planer/data/queries.dart';
import 'package:planer/logic/habits.dart';
import 'package:planer/logic/sleep.dart';

// Понедельник.
const mon = 20261109;

Set<int> days(List<int> offsets) => {for (final o in offsets) addDays(mon, o)};

SleepLog night(int id, int wakeDay, int bed, int wake, {int? latency, int? awake, String? tags, int? quality}) {
  final t = sleepTimes(wakeDay: wakeDay, bedMinutes: bed, wakeMinutes: wake);
  return SleepLog(
    id: id,
    day: wakeDay,
    bedAt: t.bedAt,
    wakeAt: t.wakeAt,
    latency: latency,
    awakeMinutes: awake,
    awakenings: awake == null ? null : 1,
    tags: tags,
    quality: quality,
  );
}

void main() {
  group('привычки', () {
    test('пропуск по причине не рвёт серию, обычный пропуск рвёт', () {
      const p = HabitPlan(firstDay: mon);
      final today = addDays(mon, 6);
      expect(habitStreak(p, HabitMarks(done: days([2, 3, 4, 5, 6])), today), 5);
      expect(habitStreak(p, HabitMarks(done: days([0, 1, 2, 4, 5, 6]), skipped: days([3])), today), 6);
      expect(habitStreak(p, HabitMarks(done: days([0, 1, 2, 4, 5, 6])), today), 3);
      // Сегодня ещё не отмечено: серия идёт со вчера.
      expect(habitStreak(p, HabitMarks(done: days([3, 4, 5])), today), 3);
    });

    test('лучшая серия и выполнение за период', () {
      const p = HabitPlan(firstDay: mon);
      final m = HabitMarks(done: days([0, 1, 2, 3, 5, 6]), skipped: const {});
      expect(bestStreak(p, m, addDays(mon, 6)), 4);
      final r = habitRate(p, m, from: mon, to: addDays(mon, 6));
      expect(r.planned, 7);
      expect(r.done, 6);
      final skip = habitRate(
        p,
        HabitMarks(done: m.done, skipped: days([4])),
        from: mon,
        to: addDays(mon, 6),
      );
      expect(skip.planned, 6);
      expect(skip.done, 6);
    });

    test('N раз в неделю: серия в неделях, план уменьшается на пропуски', () {
      const p = HabitPlan(perWeek: 3, firstDay: 20261019);
      // Три прошлые недели по 3 раза, текущая пока 1 раз.
      final done = <int>{};
      for (final w in [-21, -14, -7]) {
        done.addAll(days([w, w + 2, w + 4]));
      }
      done.add(mon);
      final m = HabitMarks(done: done);
      expect(habitStreak(p, m, addDays(mon, 2)), 3);
      // Текущая неделя выполнена: плюс одна.
      final full = HabitMarks(
        done: {
          ...done,
          ...days([1, 2]),
        },
      );
      expect(habitStreak(p, full, addDays(mon, 2)), 4);
      // Неделя с двумя пропусками по причине: хватает одного раза.
      final sick = HabitMarks(
        done: {
          ...days([-21, -19, -17, -14]),
          ...days([-7, -5, -3]),
          mon,
        },
        skipped: days([-13, -12]),
      );
      expect(weekQuota(p, sick, addDays(mon, -14)), 1);
      expect(habitStreak(p, sick, addDays(mon, 2)), 3);
    });

    test('сила привычки растёт с отметками и не обнуляется от одного пропуска', () {
      const p = HabitPlan(firstDay: 20260901);
      final all = <int>{};
      for (var d = 20260901; d <= mon; d = addDays(d, 1)) {
        all.add(d);
      }
      final full = habitStrength(p, HabitMarks(done: all), mon);
      expect(full, greaterThan(0.95));
      final oneMiss = habitStrength(p, HabitMarks(done: all.difference({addDays(mon, -1)})), mon);
      expect(oneMiss, greaterThan(0.9));
      expect(oneMiss, lessThan(full));
      final fresh = habitStrength(const HabitPlan(firstDay: mon), HabitMarks(done: {mon}), mon);
      expect(fresh, closeTo(0.05, 0.02));
    });

    test('«не пропускай дважды» только после пропуска', () {
      const p = HabitPlan(firstDay: 20261101);
      expect(missedLastTime(p, HabitMarks(done: days([-2])), mon), isTrue);
      expect(missedLastTime(p, HabitMarks(done: days([-1])), mon), isFalse);
      expect(missedLastTime(p, HabitMarks(done: days([-2]), skipped: days([-1])), mon), isFalse);
      expect(missedLastTime(p, HabitMarks(done: days([-2, 0])), mon), isFalse);
    });

    test('доля по дням недели', () {
      final p = HabitPlan(daysMask: maskFromWeekdays([1, 3]), firstDay: addDays(mon, -14));
      final r = weekdayRates(
        p,
        HabitMarks(done: days([-14, -7, 0, -12])),
        from: addDays(mon, -14),
        to: mon,
      );
      expect(r[0], 1.0);
      expect(r[2], 0.5);
      expect(r[1], isNull);
    });

    test('количество за день отмечает привычку, пропуск снимает отметку', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final id = await db.saveHabit(HabitsCompanion.insert(name: 'Вода', target: const Value(8), unit: const Value('стаканов')));
      final h = (await db.select(db.habits).get()).single;
      await db.setHabitValue(h, mon, 5);
      expect(await db.habitLogOn(id, mon), isNull);
      await db.setHabitValue(h, mon, 8);
      expect(await db.habitLogOn(id, mon), isNotNull);
      await db.setHabitValue(h, mon, 7);
      expect(await db.habitLogOn(id, mon), isNull);
      await db.toggleHabit(h, mon, done: true);
      expect((await db.habitDayOn(id, mon))!.value, 8);
      await db.setHabitSkipped(id, mon, true);
      expect(await db.habitLogOn(id, mon), isNull);
      expect((await db.habitDayOn(id, mon))!.skipped, isTrue);
      await db.setHabitNote(id, mon, 'простыл');
      await db.setHabitSkipped(id, mon, false);
      await db.setHabitValue(h, mon, 0);
      expect((await db.habitDayOn(id, mon))!.note, 'простыл');
      await db.setHabitNote(id, mon, '');
      expect(await db.habitDayOn(id, mon), isNull);
    });
  });

  group('сон', () {
    test('эффективность и фактический сон по дневнику', () {
      final l = night(1, mon, 23 * 60, 7 * 60, latency: 30, awake: 18);
      expect(sleepMinutes(l), 480);
      expect(actualSleepMinutes(l), 432);
      expect(sleepEfficiency(l), 90);
      expect(sleepEfficiency(night(2, mon, 23 * 60, 7 * 60)), isNull);
    });

    test('режим: разброс, социальный джетлаг и хронотип', () {
      final logs = [
        for (var i = 0; i < 5; i++) night(i, addDays(mon, i), 23 * 60, 7 * 60),
        night(5, addDays(mon, 5), 60, 10 * 60),
        night(6, addDays(mon, 6), 60, 10 * 60),
      ];
      final r = sleepRhythm(logs, from: mon, to: addDays(mon, 6));
      // Будни: середина сна в 03:00, выходные: в 05:30.
      expect(r.midWork, 3 * 60);
      expect(r.midFree, 5 * 60 + 30);
      expect(r.socialJetlag, 150);
      expect(r.chronotype, 'скорее сова');
      expect(r.bedSpread, greaterThan(0));
      final even = sleepRhythm([for (var i = 0; i < 5; i++) night(i, addDays(mon, i), 23 * 60, 7 * 60)], from: mon, to: addDays(mon, 6));
      expect(even.bedSpread, 0);
      expect(even.socialJetlag, isNull);
    });

    test('влияние факторов считается при 3 ночах с ним и без', () {
      final logs = [
        for (var i = 0; i < 3; i++) night(i, addDays(mon, i), 23 * 60, 7 * 60, quality: 4),
        for (var i = 3; i < 6; i++) night(i, addDays(mon, i), 23 * 60, 6 * 60, tags: 'coffee,screen', quality: 2),
      ];
      final impacts = factorImpacts(logs);
      final coffee = impacts.firstWhere((i) => i.factor.key == 'coffee');
      expect(coffee.durationDiff, -60);
      expect(coffee.qualityDiff, -2);
      expect(impacts.any((i) => i.factor.key == 'alcohol'), isFalse);
      expect(sleepTags(logs.last), {'coffee', 'screen'});
      expect(joinSleepTags(<String>[]), isNull);
    });

    test('калькулятор циклов, вечерний план и недосып', () {
      final beds = bedtimesFor(7 * 60);
      expect(beds.first.bed, 21 * 60 + 45);
      expect(beds[1].bed, 23 * 60 + 15);
      expect(wakeTimesFor(23 * 60).last.wake, 8 * 60 + 15);
      final plan = eveningPlan(30);
      expect(plan.first.at, 16 * 60 + 30);
      expect(plan.last.at, 30);
      const g = SleepGoals(bed: 23 * 60, wake: 7 * 60, duration: 8 * 60);
      final logs = [night(1, mon, 23 * 60, 6 * 60), night(2, addDays(mon, -1), 23 * 60, 7 * 60, latency: 30)];
      expect(sleepDebt(logs, g, today: mon), 90);
    });
  });

  test('переход с версии 4: новые поля привычек и дневника сна', () async {
    final dir = await Directory.systemTemp.createTemp('planer_migration5');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final current = AppDatabase(NativeDatabase(file));
    await current.saveHabit(HabitsCompanion.insert(name: 'Код'));
    await current.customStatement('DROP TABLE "habit_days"');
    for (final c in ['kind', 'target', 'unit', 'per_week', 'part_of_day', 'cue', 'why']) {
      await current.customStatement('ALTER TABLE "habits" DROP COLUMN "$c"');
    }
    for (final c in ['latency', 'awakenings', 'awake_minutes', 'tags']) {
      await current.customStatement('ALTER TABLE "sleep_logs" DROP COLUMN "$c"');
    }
    await current.customStatement('PRAGMA user_version = 4');
    await current.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final h = (await db.select(db.habits).get()).single;
    expect(h.kind, 0);
    expect(h.partOfDay, 0);
    expect(h.target, isNull);
    await db.setHabitSkipped(h.id, mon, true);
    expect((await db.habitDayOn(h.id, mon))!.skipped, isTrue);
    final t = sleepTimes(wakeDay: mon, bedMinutes: 23 * 60, wakeMinutes: 7 * 60);
    await db.saveSleep(
      SleepLogsCompanion.insert(day: mon, bedAt: t.bedAt, wakeAt: t.wakeAt, latency: const Value(20), tags: const Value('coffee')),
    );
    expect((await db.sleepBetween(mon, mon)).single.latency, 20);
  });
}
