import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/database.dart';
import 'package:planer/data/dates.dart';
import 'package:planer/data/queries.dart';
import 'package:planer/data/templates.dart';
import 'package:planer/logic/budget.dart';
import 'package:planer/logic/day_plan.dart';
import 'package:planer/logic/sleep.dart';
import 'package:planer/services/notifications.dart';

TimeBlock block(int id, String name, BlockKind kind, int start, int end, {int mask = everyDay, bool remind = false}) =>
    TimeBlock(id: id, name: name, icon: 'clock', kind: kind, start: start, end: end, daysMask: mask, remind: remind);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('план дня', () {
    const sleep = SleepGoals(bed: 23 * 60, wake: 7 * 60, duration: 8 * 60);
    final all = [
      block(1, 'Работа', BlockKind.work, 8 * 60, 17 * 60, mask: weekdaysOnly),
      block(2, 'Код', BlockKind.study, 18 * 60 + 45, 20 * 60 + 30, mask: weekdaysOnly),
      block(3, 'Тренировка', BlockKind.sport, 18 * 60, 18 * 60 + 40, mask: maskFromWeekdays([1, 3, 5])),
      block(4, 'Код', BlockKind.study, 10 * 60, 13 * 60, mask: maskFromWeekdays([6])),
    ];

    test('блоки дня по порядку, сон из раздела «Сон» в конце', () {
      final mon = blocksForWeekday(all, 1, sleep: sleep);
      expect(mon.map((b) => b.name), ['Работа', 'Тренировка', 'Код', 'Сон']);
      final tue = blocksForWeekday(all, 2, sleep: sleep);
      expect(tue.map((b) => b.name), ['Работа', 'Код', 'Сон']);
      expect(blocksForWeekday(all, 6).map((b) => b.name), ['Код']);
    });

    test('распределение суток без двойного счёта', () {
      final d = distribution(blocksForWeekday(all, 1, sleep: sleep));
      expect(d.byKind[BlockKind.sleep], 8 * 60);
      expect(d.byKind[BlockKind.work], 9 * 60);
      expect(d.byKind[BlockKind.study], 105);
      expect(d.byKind[BlockKind.sport], 40);
      expect(d.free, 24 * 60 - 8 * 60 - 9 * 60 - 105 - 40);
      // Пересечение: минута достаётся одному блоку.
      final overlap = distribution([
        PlanBlock.of(block(1, 'A', BlockKind.work, 60, 180)),
        PlanBlock.of(block(2, 'B', BlockKind.rest, 120, 240)),
      ]);
      expect(overlap.byKind[BlockKind.work]! + overlap.byKind[BlockKind.rest]!, 180);
    });

    test('что сейчас и что дальше, промежутки', () {
      final mon = blocksForWeekday(all, 1, sleep: sleep);
      final at10 = currentBlocks(mon, 10 * 60);
      expect(at10.now!.name, 'Работа');
      expect(at10.next!.name, 'Тренировка');
      final at1745 = currentBlocks(mon, 17 * 60 + 45);
      expect(at1745.now, isNull);
      expect(at1745.next!.name, 'Тренировка');
      expect(currentBlocks(mon, 2 * 60).now!.name, 'Сон');
      expect(gapAfter(mon, 0), 60); // после работы до тренировки
      expect(gapAfter(mon, 1), 5); // после тренировки до кода
      expect(gapAfter(mon, 3), 60); // после сна до работы
    });

    test('напоминание в начале блока', () {
      final plan = planNotifications(
        habits: const [],
        trackers: const [],
        programs: const [],
        reminders: const [],
        blocks: [block(7, 'Код', BlockKind.study, 18 * 60 + 45, 20 * 60 + 30, mask: weekdaysOnly, remind: true)],
      );
      expect(plan.single.baseId, 600007);
      expect(plan.single.minutes, 18 * 60 + 45);
      expect(plan.single.body, contains('20:30'));
    });
  });

  group('бюджет', () {
    test('план против факта, свободные деньги и сколько можно потратить', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await applyTemplate(db, 'my_plan', today: 20261109);
      final lines = await db.budgetOf(202611);
      expect(lines.length, 7);
      final cats = await db.select(db.categories).get();
      final funds = await db.select(db.funds).get();
      final salary = cats.firstWhere((c) => c.name == 'Зарплата');
      final clothes = cats.firstWhere((c) => c.name == 'Одежда');
      final games = cats.firstWhere((c) => c.name == 'Игры и развлечения');
      final loan = funds.firstWhere((f) => f.name == 'Кредит');
      Transaction tx(int id, Category c, double amount) =>
          Transaction(id: id, amount: amount, isIncome: c.isIncome, categoryId: c.id, day: 20261110, at: DateTime(2026, 11, 10));
      final b = buildBudget(
        lines: lines,
        categories: cats,
        funds: funds,
        transactions: [tx(1, salary, 65000), tx(2, clothes, 5000), tx(3, games, 700)],
        moves: [FundMove(id: 1, fundId: loan.id, amount: 12000, day: 20261110)],
      );
      expect(b.incomePlan, 65000);
      expect(b.unallocated, 0);
      expect(b.expensePlan, 10000);
      expect(b.expenseFact, 5700);
      expect(b.leftToSpend, 4300);
      final clothesRow = b.rows.firstWhere((r) => r.category?.id == clothes.id);
      expect(clothesRow.over, isTrue);
      final gamesRow = b.rows.firstWhere((r) => r.category?.id == games.id);
      expect(gamesRow.unplanned, isTrue);
      final loanRow = b.rows.firstWhere((r) => r.fund?.id == loan.id);
      expect(loanRow.group, BudgetGroup.debts);
      expect(loanRow.done, isTrue);
    });

    test('новый месяц берёт план прошлого, нули не сохраняются', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final c = await db.saveCategory(CategoriesCompanion.insert(name: 'Еда'));
      await db.saveBudget(202610, [(categoryId: c, fundId: null, amount: 5000), (categoryId: null, fundId: null, amount: 0)]);
      expect((await db.budgetOf(202610)).length, 1);
      expect(await db.previousBudgetMonth(202612), 202610);
      expect(await db.previousBudgetMonth(202610), isNull);
    });

    test('дней до конца месяца', () {
      expect(daysLeftInMonth(DateTime(2026, 11), DateTime(2026, 11, 9, 10)), 22);
      expect(daysLeftInMonth(DateTime(2026, 11), DateTime(2026, 11, 30, 23)), 1);
      expect(daysLeftInMonth(DateTime(2026, 10), DateTime(2026, 11, 9)), 0);
      expect(daysLeftInMonth(DateTime(2026, 12), DateTime(2026, 11, 9)), 31);
    });
  });
}
