import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/database.dart';
import 'package:planer/data/dates.dart';
import 'package:planer/data/goal_queries.dart';
import 'package:planer/data/queries.dart';
import 'package:planer/data/transfer.dart';
import 'package:planer/logic/goals.dart';
import 'package:planer/logic/journal.dart';
import 'package:planer/logic/report.dart';

const today = 20261109;

Goal goal({
  int id = 1,
  GoalKind kind = GoalKind.manual,
  double start = 0,
  double target = 10,
  int startDay = 20261001,
  int? deadline,
  int? achievedDay,
}) => Goal(
  id: id,
  name: 'Цель',
  kind: kind,
  startValue: start,
  targetValue: target,
  startDay: startDay,
  deadline: deadline,
  achievedDay: achievedDay,
  archived: false,
  sortOrder: 0,
);

GoalCheckin checkin(int day, double value, {int goalId = 1}) => GoalCheckin(id: day, goalId: goalId, day: day, value: value);

JournalEntry dayEntry(int day, {int? mood, String? tags, String? wins}) =>
    JournalEntry(id: day, kind: JournalKind.day, day: day, at: DateTime(2026), mood: mood, body: '', tags: tags, wins: wins);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('цели', () {
    test('ручная цель: значение и история по отметкам', () {
      final g = goal();
      final s = GoalSources(checkins: [checkin(20261005, 2), checkin(20261020, 5), checkin(20261020, 6)]);
      expect(goalValue(g, s), 6);
      expect(goalValueAt(g, s, 20261010), 2);
      expect(goalValueAt(g, s, 20261001), isNull);
    });

    test('цель из этапов: прогресс по сделанным', () {
      final g = goal(kind: GoalKind.steps);
      final s = GoalSources(
        steps: [
          GoalStep(id: 1, goalId: 1, title: 'А', doneDay: 20261003, sortOrder: 1),
          GoalStep(id: 2, goalId: 1, title: 'Б', doneDay: 20261010, sortOrder: 2),
          GoalStep(id: 3, goalId: 1, title: 'В', sortOrder: 3),
          GoalStep(id: 4, goalId: 1, title: 'Г', sortOrder: 4),
        ],
      );
      final st = goalStatus(g, s, today: today);
      expect(st.target, 4);
      expect(st.current, 2);
      expect(st.fraction, 0.5);
      expect(nextStep(g, s)!.title, 'В');
      expect(goalValueAt(g, s, 20261005), 1);
      expect(goalHistory(g, s).last, (20261010, 2.0));
    });

    test('темп: по плану, отстаёшь, опережаешь, срок прошёл', () {
      // 100 дней от старта до срока, прошло 40: по плану 4 из 10.
      const start = 20261001;
      final deadline = addDays(start, 100);
      final now = addDays(start, 40);
      GoalPace pace(double v) => goalStatus(
        goal(startDay: start, deadline: deadline),
        GoalSources(checkins: [checkin(addDays(start, 10), v)]),
        today: now,
      ).pace;
      expect(pace(4), GoalPace.onTrack);
      expect(pace(2), GoalPace.behind);
      expect(pace(6), GoalPace.ahead);
      expect(pace(10), GoalPace.reached);
      final late = goalStatus(
        goal(startDay: start, deadline: deadline),
        GoalSources(checkins: [checkin(start, 3)]),
        today: addDays(deadline, 1),
      );
      expect(late.pace, GoalPace.overdue);
    });

    test('нужно в неделю, чтобы успеть, и отставание от плана', () {
      const start = 20261001;
      final st = goalStatus(
        goal(startDay: start, deadline: addDays(start, 70), target: 10),
        GoalSources(checkins: [checkin(start, 1)]),
        today: addDays(start, 34),
      );
      // Осталось 9 за 36 дней (5 недель с небольшим).
      expect(st.perWeekNeeded, closeTo(9 / (37 / 7), 0.01));
      expect(st.expected, closeTo(10 * 34 / 70, 0.01));
      expect(st.gap, closeTo(10 * 34 / 70 - 1, 0.01));
    });

    test('цель на снижение: долг уменьшается', () {
      final fund = Fund(
        id: 7,
        name: 'Кредит',
        icon: 'x',
        kind: FundKind.debt,
        initialAmount: 100000,
        archived: false,
        sortOrder: 0,
        createdAt: DateTime(2026),
      );
      final g = Goal(
        id: 1,
        name: 'Закрыть кредит',
        kind: GoalKind.fund,
        fundId: 7,
        startValue: 100000,
        targetValue: 0,
        startDay: 20261001,
        archived: false,
        sortOrder: 0,
      );
      final s = GoalSources(
        funds: {7: fund},
        fundMoves: [FundMove(id: 1, fundId: 7, amount: 25000, day: 20261015), FundMove(id: 2, fundId: 7, amount: 25000, day: 20261101)],
      );
      final st = goalStatus(g, s, today: today);
      expect(st.current, 50000);
      expect(st.fraction, 0.5);
      expect(goalValueAt(g, s, 20261020), 75000);
      expect(goalHistory(g, s).first, (20261001, 100000.0));
    });

    test('отмеченная цель считается достигнутой', () {
      final st = goalStatus(goal(achievedDay: 20261101), GoalSources(checkins: [checkin(20261005, 3)]), today: today);
      expect(st.pace, GoalPace.reached);
    });

    test('id привычек цели', () {
      expect(parseIds('1, 5,x,7'), [1, 5, 7]);
      expect(joinIds([2, 3]), '2,3');
      expect(joinIds([]), isNull);
    });
  });

  group('дневник', () {
    test('теги: разбор и подсказки по частоте', () {
      expect(parseTags(' Спорт, код,,'), ['спорт', 'код']);
      expect(joinTags(['код', 'Код', ' ']), 'код');
      final s = tagSuggestions([dayEntry(1, tags: 'смена'), dayEntry(2, tags: 'смена, спорт')]);
      expect(s.take(2), ['смена', 'спорт']);
      expect(s, contains('работа'));
    });

    test('строки списка без номеров', () {
      expect(listLines('1. Код\n2.\n- Тренировка\n\n3) Сон'), ['Код', 'Тренировка', 'Сон']);
    });

    test('серия итогов дня', () {
      final e = [dayEntry(20261106), dayEntry(20261107), dayEntry(20261108), dayEntry(20261101), dayEntry(20261102)];
      expect(journalStreak(e, today: today), 3);
      expect(journalStreak([...e, dayEntry(today)], today: today), 4);
      expect(journalBestStreak(e), 3);
    });

    test('влияние тегов на настроение', () {
      final e = [
        dayEntry(1, mood: 8, tags: 'спорт'),
        dayEntry(2, mood: 9, tags: 'спорт'),
        dayEntry(3, mood: 4, tags: 'плохой сон'),
        dayEntry(4, mood: 5, tags: 'плохой сон'),
        dayEntry(5, mood: 6),
      ];
      final t = tagMoods(e);
      final sport = t.firstWhere((x) => x.tag == 'спорт');
      expect(sport.withTag, 8.5);
      expect(sport.without, 5);
      expect(t.firstWhere((x) => x.tag == 'плохой сон').delta, lessThan(0));
    });

    test('ключ обзора: понедельник и первое число', () {
      expect(journalAnchor(JournalKind.week, 20261112), 20261109);
      expect(journalAnchor(JournalKind.month, 20261112), 20261101);
      expect(journalAnchor(JournalKind.day, 20261112), 20261112);
    });
  });

  group('итоги', () {
    test('границы и сдвиг периодов', () {
      expect(periodRange(ReportPeriod.month, 20261115), (from: 20261101, to: 20261130));
      expect(periodRange(ReportPeriod.week, 20261115), (from: 20261109, to: 20261115));
      expect(shiftPeriod(ReportPeriod.month, 20261101, -1), 20261001);
      expect(shiftPeriod(ReportPeriod.month, 20260101, -1), 20251201);
    });

    test('итоги месяца: цели, победы, теги и сравнение', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final id = await db.saveGoal(
        GoalsCompanion.insert(name: 'Книги', kind: GoalKind.manual, startValue: 0, targetValue: 12, startDay: 20261001),
      );
      await db.addGoalCheckin(id, 2, day: 20261020);
      await db.addGoalCheckin(id, 4, day: 20261105);
      await db.saveJournal(
        JournalEntriesCompanion.insert(
          kind: JournalKind.day,
          day: 20261103,
          mood: const Value(8),
          tags: const Value('спорт, код'),
          wins: const Value('Час кода\nТренировка'),
        ),
      );
      await db.saveJournal(JournalEntriesCompanion.insert(kind: JournalKind.day, day: 20261020, mood: const Value(5)));
      await db.saveJournal(JournalEntriesCompanion.insert(kind: JournalKind.month, day: 20261101, focus: const Value('Резюме')));
      final r = await buildReport(db, ReportPeriod.month, 20261109, today: 20261109);
      expect(r.days, 9);
      expect(r.goals.single.text, contains('2 → 4'));
      expect(r.goals.single.forward, isTrue);
      expect(r.wins.map((w) => w.$2), ['Час кода', 'Тренировка']);
      expect(r.tags.first.$2, 1);
      expect(r.moodAvg, 8);
      expect(r.prev!.moodAvg, 5);
      expect(r.review!.focus, 'Резюме');
      final text = r.toText();
      expect(text, contains('Книги'));
      expect(text, contains('Фокус на следующий месяц'));
    });
  });

  test('этапы, отметки и записи к цели переживают экспорт и импорт', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.saveGoal(
      GoalsCompanion.insert(
        name: 'Резюме',
        kind: GoalKind.steps,
        startValue: 0,
        targetValue: 0,
        startDay: today,
        area: const Value(GoalArea.career),
        why: const Value('Новая работа'),
      ),
    );
    final step = await db.addGoalStep(id, 'Шаблон');
    await db.setGoalStepDone(step, true, day: today);
    await db.saveJournal(JournalEntriesCompanion.insert(kind: JournalKind.note, day: today, goalId: Value(id), body: const Value('мысль')));
    final json = await exportJson(db);

    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    await importJson(other, json);
    final g = (await other.select(other.goals).get()).single;
    expect(g.area, GoalArea.career);
    expect(g.why, 'Новая работа');
    expect((await other.select(other.goalSteps).get()).single.doneDay, today);
    expect((await other.select(other.journalEntries).get()).single.goalId, id);
  });

  test('переход с версии 4: новые колонки и таблицы целей и дневника', () async {
    final dir = await Directory.systemTemp.createTemp('planer_migration5');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final current = AppDatabase(NativeDatabase(file));
    await current.customStatement('DROP TABLE goal_steps');
    await current.customStatement('DROP TABLE goal_checkins');
    for (final c in ['area', 'unit', 'why', 'obstacle', 'plan', 'habit_ids', 'achieved_day']) {
      await current.customStatement('ALTER TABLE goals DROP COLUMN "$c"');
    }
    for (final c in ['title', 'energy', 'tags', 'wins', 'gratitude', 'lesson', 'focus']) {
      await current.customStatement('ALTER TABLE journal_entries DROP COLUMN "$c"');
    }
    await current.customStatement(
      "INSERT INTO goals (name, kind, start_value, target_value, start_day, archived, sort_order) VALUES ('Вес', 0, 67, 73, 20261001, 0, 1)",
    );
    await current.customStatement("INSERT INTO journal_entries (kind, day, at, mood, body) VALUES (0, 20261108, 0, 7, 'день')");
    await current.customStatement('PRAGMA user_version = 4');
    await current.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final g = (await db.select(db.goals).get()).single;
    expect(g.name, 'Вес');
    expect(g.area, isNull);
    final e = (await db.select(db.journalEntries).get()).single;
    expect(e.mood, 7);
    expect(e.wins, isNull);
    await db.addGoalStep(g.id, 'шаг');
    await db.addGoalCheckin(g.id, 68);
    expect((await db.select(db.goalSteps).get()).length, 1);
  });
}
