// Проходит по всем экранам с шаблоном «Мой план» и проверяет, что ничего не падает
// и не вылезает за границы. С флагом --dart-define=SCREENSHOTS=true ещё и
// сохраняет картинки экранов в test/screens/ (для ручной проверки, в git не идут).
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/app.dart';
import 'package:planer/data/database.dart';
import 'package:planer/data/dates.dart';
import 'package:planer/data/goal_queries.dart';
import 'package:planer/data/money_queries.dart';
import 'package:planer/data/queries.dart';
import 'package:planer/data/templates.dart';
import 'package:planer/data/time_queries.dart';
import 'package:planer/logic/sleep.dart';
import 'package:planer/services/notifications.dart';
import 'package:planer/ui/habits_screen.dart';
import 'package:planer/ui/icons.dart';
import 'package:planer/ui/money/overview_tab.dart';
import 'package:planer/ui/money/plans_tab.dart';
import 'package:planer/ui/more_screen.dart';
import 'package:planer/ui/theme.dart';

const screenshots = bool.fromEnvironment('SCREENSHOTS');

const theme = String.fromEnvironment('THEME', defaultValue: 'light');

Future<void> loadFonts() async {
  final root = '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/sdk/flutter'}/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }

  await load('Inter', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) 'assets/fonts/Inter-$w.ttf',
  ]);
  await load('MaterialIcons', ['$root/MaterialIcons-Regular.otf']);
  // Цветные эмодзи: путь к NotoColorEmoji.ttf, если он есть на машине.
  final emoji = Platform.environment['EMOJI_FONT'];
  if (emoji != null) await load('Noto Color Emoji', [emoji]);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    if (screenshots) await loadFonts();
  });

  Future<void> shot(WidgetTester tester, String name) async {
    debugPrint('screen: $name');
    if (!screenshots) return;
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/$theme/$name.png'));
  }

  testWidgets('все экраны открываются', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory());
    final today = todayKey();
    await tester.runAsync(() async {
      await applyTemplate(db, 'my_plan', today: addDays(today, -14));
      await db.setSetting('setup_done', '1');
      if (theme == 'dark') await db.setSetting('theme', 'dark');
      // Немного истории, чтобы графики и серии были не пустыми.
      final trackers = await db.select(db.trackers).get();
      final weight = trackers.firstWhere((t) => t.name == 'Вес');
      for (var i = 1; i <= 14; i++) {
        await db.addEntry(weight.id, 67 + i * 0.08, day: addDays(today, -14 + i));
      }
      final code = trackers.firstWhere((t) => t.name == 'Время кода');
      for (var i = 1; i <= 10; i++) {
        await db.addEntry(code.id, 60.0 + i * 5, day: addDays(today, -i));
      }
      final habits = await db.select(db.habits).get();
      for (var i = 1; i <= 9; i++) {
        await db.setHabitDone(habits.first.id, addDays(today, -i), done: true, minimum: i == 4);
      }
      final funds = await db.select(db.funds).get();
      await db.addFundMove(funds.first.id, 12000, day: addDays(today, -3));
      await db.addFundMove(funds.last.id, 20000, day: addDays(today, -2));
      final cats = await db.select(db.categories).get();
      await db.saveTransaction(TransactionsCompanionX.expense(350, cats.first.id, today));
      await db.saveTransaction(TransactionsCompanionX.expense(2500, cats[1].id, addDays(today, -1)));
      await db.saveJournal(
        JournalEntriesCompanion.insert(
          kind: JournalKind.day,
          day: addDays(today, -1),
          mood: const Value(7),
          body: const Value('Что сделал сегодня:\n1. Час кода\n2. Тренировка A\n3. Лёг до 23:00'),
        ),
      );
      // Дневник за две недели с тегами и победами, цель из этапов и цель с ручными отметками.
      for (var i = 2; i <= 13; i++) {
        await db.saveJournal(
          JournalEntriesCompanion.insert(
            kind: JournalKind.day,
            day: addDays(today, -i),
            mood: Value(i % 3 == 0 ? 5 : 8),
            energy: Value(2 + i % 3),
            tags: Value(i % 3 == 0 ? 'работа, плохой сон' : 'спорт, код'),
            wins: Value('Час кода\nТренировка ${i.isEven ? 'A' : 'B'}'),
            focus: Value(i == 2 ? 'Доделать резюме' : null),
          ),
        );
      }
      final steps = await db.saveGoal(
        GoalsCompanion.insert(
          name: 'Найти работу backend',
          kind: GoalKind.steps,
          startValue: 0,
          targetValue: 0,
          startDay: addDays(today, -20),
          deadline: Value(addDays(today, 120)),
          area: const Value(GoalArea.career),
          why: const Value('Работать программистом и жить отдельно'),
          obstacle: const Value('Устаю после смены'),
          plan: const Value('Делаю хотя бы 20 минут кода сразу после ужина'),
          habitIds: Value('${habits.first.id}'),
        ),
      );
      for (final (i, t) in ['Повторить Python', 'Проект на FastAPI', 'Docker и деплой', 'Резюме и GitHub', 'Отклики'].indexed) {
        final id = await db.addGoalStep(steps, t, dueDay: addDays(today, 10 + i * 20));
        if (i < 2) await db.setGoalStepDone(id, true, day: addDays(today, -10 + i * 5));
      }
      final books = await db.saveGoal(
        GoalsCompanion.insert(
          name: 'Прочитать 12 книг',
          kind: GoalKind.manual,
          startValue: 0,
          targetValue: 12,
          unit: const Value('книг'),
          startDay: addDays(today, -60),
          deadline: Value(addDays(today, 300)),
          area: const Value(GoalArea.study),
        ),
      );
      await db.addGoalCheckin(books, 1, day: addDays(today, -40));
      await db.addGoalCheckin(books, 3, day: addDays(today, -5));
      // Сон за две недели, кроме сегодняшней ночи, и еда с водой за неделю.
      for (var i = 1; i <= 13; i++) {
        final bed = [23 * 60, 23 * 60 + 40, 22 * 60 + 50, 23 * 60 + 10, 15][i % 5];
        final wake = [7 * 60, 7 * 60 + 15, 6 * 60 + 40][i % 3];
        final t = sleepTimes(wakeDay: addDays(today, -i), bedMinutes: bed, wakeMinutes: wake);
        await db.saveSleep(
          SleepLogsCompanion.insert(
            day: addDays(today, -i),
            bedAt: t.bedAt,
            wakeAt: t.wakeAt,
            quality: Value(3 + i % 3),
            latency: Value([10, 20, 35][i % 3]),
            awakenings: Value(i % 4 == 0 ? 1 : 0),
            awakeMinutes: Value(i % 4 == 0 ? 15 : null),
            tags: Value(i % 2 == 0 ? 'screen,coffee' : 'walk'),
          ),
        );
      }
      final foods = await db.watchFoods().first;
      for (var i = 0; i <= 6; i++) {
        final day = addDays(today, -i);
        final count = i == 0 ? 3 : 4 + i % 3;
        for (var j = 0; j < count; j++) {
          await db.eatFood(foods[(j * 2 + i) % foods.length], day: day);
        }
        for (var j = 0; j < (i == 0 ? 3 : 6 + i % 3); j++) {
          await db.addWater(250, day: day);
        }
      }
      final salary = cats.firstWhere((c) => c.name == 'Зарплата');
      await db.saveTransaction(
        TransactionsCompanion.insert(amount: 65000, isIncome: const Value(true), categoryId: Value(salary.id), day: today),
      );
      // Деньги: два счёта, перевод, прошлые месяцы для аналитики, регулярные платежи.
      final card = await db.saveAccount(AccountsCompanion.insert(name: 'Карта', initialBalance: const Value(14000)));
      final cash = await db.saveAccount(
        AccountsCompanion.insert(name: 'Наличные', icon: const Value('wallet'), initialBalance: const Value(3000)),
      );
      await db.customStatement('UPDATE transactions SET account_id = ?', [card]);
      await db.saveTransfer(TransfersCompanion.insert(fromAccountId: card, toAccountId: cash, amount: 2000, day: addDays(today, -1)));
      final now = DateTime.now();
      for (var m = 1; m <= 5; m++) {
        final day = dayKey(DateTime(now.year, now.month - m, 10));
        await db.saveTransaction(
          TransactionsCompanion.insert(
            amount: 65000,
            isIncome: const Value(true),
            categoryId: Value(salary.id),
            day: day,
            accountId: Value(card),
          ),
        );
        for (var i = 0; i < 5; i++) {
          await db.saveTransaction(
            TransactionsCompanion.insert(
              amount: 4000.0 + 2500 * i + 900 * m,
              categoryId: Value(cats[i].id),
              day: day,
              accountId: Value(card),
            ),
          );
        }
      }
      await db.saveRecurring(
        RecurringsCompanion.insert(
          name: 'Зарплата',
          icon: const Value('salary'),
          kind: RecurringKind.income,
          amount: 65000,
          repeat: RepeatKind.monthly,
          nextDay: addDays(today, 12),
          accountId: Value(card),
        ),
      );
      await db.saveRecurring(
        RecurringsCompanion.insert(
          name: 'Связь и интернет',
          icon: const Value('phone'),
          kind: RecurringKind.expense,
          amount: 650,
          repeat: RepeatKind.monthly,
          nextDay: addDays(today, 3),
          categoryId: Value(cats[4].id),
        ),
      );
      await db.saveRecurring(
        RecurringsCompanion.insert(
          name: 'Платёж: Кредит',
          icon: const Value('bank'),
          kind: RecurringKind.fund,
          amount: 12000,
          repeat: RepeatKind.monthly,
          nextDay: addDays(today, 6),
          fundId: Value(funds.first.id),
        ),
      );
      // Задачи и фокус для модуля «Время».
      final docker = await db.saveTask(
        TasksCompanion.insert(
          title: 'Урок Docker: volumes',
          day: Value(today),
          priority: const Value(1),
          estimate: const Value(60),
          kind: const Value(BlockKind.study),
        ),
      );
      for (final step in ['Посмотреть видео', 'Повторить команды', 'Записать конспект']) {
        await db.saveTask(TasksCompanion.insert(title: step, parentId: Value(docker)));
      }
      await db.saveTask(
        TasksCompanion.insert(
          title: 'Оплатить кредит',
          day: Value(today),
          time: const Value(19 * 60),
          remind: const Value(true),
          priority: const Value(2),
        ),
      );
      await db.saveTask(TasksCompanion.insert(title: 'Резюме: черновик', day: Value(addDays(today, -2)), estimate: const Value(30)));
      await db.saveTask(TasksCompanion.insert(title: 'Купить протеин', kind: const Value(BlockKind.home)));
      await db.saveTask(
        TasksCompanion.insert(
          title: 'FastAPI: роуты',
          day: Value(addDays(today, 2)),
          kind: const Value(BlockKind.study),
          estimate: const Value(90),
        ),
      );
      final done = await db.saveTask(TasksCompanion.insert(title: 'Разобрать почту', day: Value(today)));
      await db.setTaskDone((await db.taskById(done))!, true);
      for (var i = 0; i < 6; i++) {
        final at = dayFromKey(addDays(today, -i)).add(const Duration(hours: 19));
        await db.addFocus(at: at, minutes: 25 + i * 5, taskId: i.isEven ? docker : null, kind: BlockKind.study);
      }
      final programs = await db.select(db.programs).get();
      await db.saveSession(
        program: programs.first,
        day: addDays(today, -2),
        sets: [SessionSetsCompanion.insert(sessionId: 0, exerciseName: 'Отжимания', setIndex: 0, reps: 15)],
      );
    });

    await tester.pumpWidget(PlanerApp(db: db, notifications: NotificationService(db)));
    await pumpData(tester);
    expect(find.text('Сегодня'), findsWidgets);
    await shot(tester, '01_today');

    // Быстрая запись с «Сегодня».
    await tester.tap(find.byType(FloatingActionButton).hitTestable());
    await pumpData(tester);
    expect(find.text('Записать за сегодня'), findsOneWidget);
    expect(find.text('Стакан воды'), findsOneWidget);
    await shot(tester, '01c_quick_add');
    await back(tester);
    await pumpData(tester);

    Future<void> tab(String label, String name) async {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
      await pumpData(tester);
      await shot(tester, name);
    }

    Future<void> openFromMore(String title, String name) async {
      await tab('Ещё', '05_more');
      if (find.text(title).hitTestable().evaluate().isEmpty) {
        final list = find.descendant(of: find.byType(MoreScreen), matching: find.byType(Scrollable)).first;
        await tester.scrollUntilVisible(find.text(title).hitTestable(), 200, scrollable: list);
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.tap(find.text(title).hitTestable().first);
      await pumpData(tester);
      await shot(tester, name);
      await back(tester);
      await pumpData(tester);
    }

    await tab('Привычки', '02_habits');
    await tester.tap(find.text('Программирование').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '02b_habit_detail');
    await tester.scrollUntilVisible(find.text('Календарь').hitTestable(), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '02b2_habit_calendar');
    await back(tester);
    await pumpData(tester);
    await tester.tap(find.text('Неделя').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '02c_habits_week');
    await tester.tap(find.text('Итоги').hitTestable().first);
    await pumpData(tester);
    expect(find.text('идеальных дней'), findsOneWidget);
    await shot(tester, '02d_habits_stats');
    await tester.tap(find.text('Сегодня').hitTestable().first);
    await pumpData(tester);
    // Новая привычка из идей: вода по стаканам.
    await tester.tap(find.byType(FloatingActionButton).hitTestable());
    await pumpData(tester);
    await shot(tester, '02e_habit_ideas');
    await tester.tap(find.text('Вода').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '02f_habit_edit');
    await tester.scrollUntilVisible(
      find.text('Сохранить').hitTestable(),
      300,
      scrollable: find.descendant(of: find.byType(HabitEditScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Сохранить'));
    await pumpData(tester);
    final water = (await tester.runAsync(() => db.select(db.habits).get()))!.firstWhere((h) => h.name == 'Вода');
    expect(water.target, 8);
    await tester.tap(find.byTooltip('+1').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '02g_habits_today');

    await tab('Деньги', '03_money');
    expect(find.text('Можно потратить сегодня'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Копилки и долги').hitTestable(),
      300,
      scrollable: find.descendant(of: find.byType(MoneyOverviewTab), matching: find.byType(Scrollable)).first,
    );
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '03a_money_overview_more');
    Future<void> moneyTab(String label, String name) async {
      await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.text(label)));
      await pumpData(tester);
      await tester.pump(const Duration(milliseconds: 400));
      await shot(tester, name);
    }

    await moneyTab('Операции', '03b_money_ops');
    await tester.tap(find.byType(FloatingActionButton).hitTestable());
    await pumpData(tester);
    await shot(tester, '03e_money_add');
    await back(tester);
    await pumpData(tester);
    await moneyTab('Аналитика', '03c_money_analytics');
    expect(find.text('Куда уходят деньги'), findsOneWidget);
    await moneyTab('Планы', '03d_money_plans');
    expect(find.text('Регулярные платежи'), findsOneWidget);
    final plans = find.descendant(of: find.byType(MoneyPlansTab), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('На долги и копилки в месяц').hitTestable(), 300, scrollable: plans);
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '03g_money_plans_monthly');
    await tester.scrollUntilVisible(find.text('Кредит: как закрыть быстрее').hitTestable(), 300, scrollable: plans);
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '03h_money_plan_debt');
    await tester.tap(find.byTooltip('Счета'));
    await pumpData(tester);
    await shot(tester, '03i_money_accounts');
    await tester.tap(find.text('Наличные').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '03f_money_account');
    await back(tester);
    await pumpData(tester);
    await back(tester);
    await pumpData(tester);
    await tab('Спорт', '04_workouts');
    await tester.tap(find.text('Тренировка A').hitTestable().first);
    await pumpData(tester);
    await tester.tap(find.text('Начать').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '04b_session');
    await back(tester);
    await pumpData(tester);
    await back(tester);
    await pumpData(tester);

    await openFromMore('Трекеры', '06_trackers');
    await tab('Ещё', '05_more');
    await tester.tap(find.text('Трекеры').hitTestable().first);
    await pumpData(tester);
    await tester.tap(find.text('Вес').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '06b_tracker_detail');
    await back(tester);
    await pumpData(tester);
    await back(tester);
    await pumpData(tester);

    // Модуль «Время»: свои вкладки внизу.
    await tab('Ещё', '05_more');
    await tester.tap(find.text('Время и задачи').hitTestable().first);
    await pumpData(tester);
    expect(find.text('Урок Docker: volumes'), findsWidgets);
    expect(find.text('Просрочено'), findsOneWidget);
    await shot(tester, '15_time_tasks');
    Future<void> timeTab(String label, String name) async {
      await tester.tap(find.text(label).hitTestable().last);
      await pumpData(tester);
      await shot(tester, name);
    }

    await timeTab('Скоро', '15b_time_upcoming');
    await timeTab('Входящие 1', '15c_time_inbox');
    await timeTab('Сегодня', '15_time_tasks');
    // Быстрый ввод: дата, время, приоритет и оценка из текста.
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Задача').hitTestable());
    await pumpData(tester);
    await shot(tester, '15d_task_sheet');
    await tester.enterText(find.widgetWithText(TextField, 'Что сделать'), 'Повторить SQL завтра в 18:30 !2 ~45м #учёба');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpData(tester);
    final added = (await tester.runAsync(() => db.allTasks()))!.firstWhere((t) => t.title == 'Повторить SQL');
    expect(added.day, addDays(today, 1));
    expect(added.time, 18 * 60 + 30);
    expect(added.priority, 2);
    expect(added.estimate, 45);
    expect(added.kind, BlockKind.study);
    await timeTab('День', '15e_time_day');
    await timeTab('Фокус', '15f_time_focus');
    await tester.tap(find.text('Начать').hitTestable().first);
    await pumpData(tester);
    expect(await tester.runAsync(() => db.focusState()), isNotNull);
    await shot(tester, '15g_time_focus_running');
    await tester.tap(find.text('Стоп').hitTestable().first);
    await pumpData(tester);
    await timeTab('Итоги', '15h_time_stats');
    await back(tester);
    await pumpData(tester);
    await openFromMore('Сон', '12_sleep');
    // Разбор сна и инструменты.
    await tab('Ещё', '05_more');
    await tester.tap(find.text('Сон').hitTestable().first);
    await pumpData(tester);
    await tester.scrollUntilVisible(find.text('Окно сна, 14 ночей').hitTestable(), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '12c_sleep_window');
    await tester.scrollUntilVisible(find.text('Что влияет на мой сон').hitTestable(), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '12d_sleep_rhythm');
    await tester.scrollUntilVisible(find.text('Когда лечь, когда встать').hitTestable(), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Когда лечь, когда встать').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '12f_sleep_cycles');
    await back(tester);
    await pumpData(tester);
    await tester.tap(find.text('Вечерний план').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '12e_sleep_evening');
    await back(tester);
    await pumpData(tester);
    await back(tester);
    await pumpData(tester);
    // Окно записи сна.
    await tab('Ещё', '05_more');
    await tester.tap(find.text('Сон').hitTestable().first);
    await pumpData(tester);
    await tester.tap(find.text('Записать').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '12b_sleep_sheet');
    await back(tester);
    await pumpData(tester);
    await back(tester);
    await pumpData(tester);
    await openFromMore('Питание', '13_food');
    // Расчёт нормы по формуле.
    await tab('Ещё', '05_more');
    await tester.tap(find.text('Питание').hitTestable().first);
    await pumpData(tester);
    await tester.tap(find.text('Рассчитать норму').hitTestable().first);
    await pumpData(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Год рожд.'), '2006');
    await tester.enterText(find.widgetWithText(TextField, 'Рост'), '175');
    await pumpData(tester);
    expect(find.text('Обмен в покое'), findsOneWidget);
    await shot(tester, '13b_food_calc');
    await tester.ensureVisible(find.text('Применить'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Применить'));
    await pumpData(tester);
    final applied = await tester.runAsync(() => db.watchAllSettings().first);
    expect(applied!['body_height'], '175');
    await tester.scrollUntilVisible(find.text('Съедено').hitTestable(), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '13c_food_meals');
    // Статистика за 30 дней.
    await tester.scrollUntilVisible(find.text('30 дней').hitTestable(), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('30 дней').hitTestable());
    await pumpData(tester);
    await shot(tester, '13d_food_stats');
    await back(tester);
    await pumpData(tester);

    // Поиск по справочнику и запись в граммах.
    await tab('Ещё', '05_more');
    await tester.tap(find.text('Питание').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '13i_food_insight');
    await tester.tap(find.text('Добавить').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '13e_food_search');
    await tester.enterText(find.byType(TextField).first, 'банан');
    await pumpData(tester);
    expect(find.text('Банан'), findsWidgets);
    await tester.tap(find.text('Банан').hitTestable().last);
    await pumpData(tester);
    await shot(tester, '13f_food_amount');
    await tester.tap(find.text('Записать').hitTestable());
    await pumpData(tester);
    final eaten = await tester.runAsync(() => db.mealsBetween(today, today));
    expect(eaten!.any((m) => m.name == 'Банан' && m.grams == 120 && (m.kcal - 115.2).abs() < 0.01), isTrue);
    // Подсказка «Записано» не должна закрывать пункты меню дальше.
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first).removeCurrentSnackBar();
    await pumpData(tester);

    // Мои блюда и рецепт.
    await tester.tap(find.byTooltip('Мои блюда и рецепты'));
    await pumpData(tester);
    await shot(tester, '13g_food_library');
    await tester.tap(find.text('Рецепт').hitTestable().first);
    await pumpData(tester);
    expect(find.text('Новый рецепт'), findsOneWidget);
    await shot(tester, '13h_food_recipe');
    await back(tester);
    await pumpData(tester);
    await back(tester);
    await pumpData(tester);
    await back(tester);
    await pumpData(tester);
    await openFromMore('Цели', '07_goals');
    await tab('Ещё', '05_more');
    await tester.tap(find.text('Цели').hitTestable().first);
    await pumpData(tester);
    await tester.tap(find.text('Найти работу backend').hitTestable().first);
    await pumpData(tester);
    expect(find.text('Проект на FastAPI'), findsOneWidget);
    await shot(tester, '07b_goal_detail');
    await tester.scrollUntilVisible(find.text('Заметки').hitTestable(), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '07c_goal_detail_plan');
    await back(tester);
    await pumpData(tester);
    await tester.tap(find.byType(FloatingActionButton).hitTestable());
    await pumpData(tester);
    await shot(tester, '07d_goal_edit');
    await back(tester);
    await pumpData(tester);
    await back(tester);
    await pumpData(tester);

    await openFromMore('Дневник', '08_journal');
    await tab('Ещё', '05_more');
    await tester.tap(find.text('Дневник').hitTestable().first);
    await pumpData(tester);
    await tester.tap(find.text('Календарь'));
    await pumpData(tester);
    await shot(tester, '08b_journal_calendar');
    await tester.tap(find.text('Выводы'));
    await pumpData(tester);
    expect(find.text('#спорт'), findsOneWidget);
    await shot(tester, '08c_journal_insights');
    await tester.tap(find.text('Лента'));
    await pumpData(tester);
    await tester.tap(find.byType(FloatingActionButton).hitTestable());
    await pumpData(tester);
    await tester.tap(find.text('Итог дня').hitTestable().last);
    await pumpData(tester);
    expect(find.text('Победы дня'), findsOneWidget);
    await shot(tester, '08d_journal_day');
    await back(tester);
    await pumpData(tester);
    await back(tester);
    await pumpData(tester);

    await openFromMore('Итоги', '09_report');
    await tab('Ещё', '05_more');
    await tester.tap(find.text('Итоги').hitTestable().first);
    await pumpData(tester);
    await tester.tap(find.text('Месяц'));
    await pumpData(tester);
    await shot(tester, '09b_report_month');
    await tester.tap(find.text('День'));
    await pumpData(tester);
    await shot(tester, '09c_report_day');
    await back(tester);
    await pumpData(tester);
    await openFromMore('Напоминания', '10_reminders');
    await openFromMore('Настройки и данные', '11_settings');

    // Отметка привычки на «Сегодня».
    await tab('Сегодня', '01_today');
    await tester.scrollUntilVisible(find.text('Спина и осанка').hitTestable(), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '01b_today_scrolled');
    await tester.tap(find.text('Спина и осанка').hitTestable().first);
    await pumpData(tester);
    final logs = await tester.runAsync(() => db.select(db.habitLogs).get());
    expect(logs!.any((l) => l.day == today), isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });

  testWidgets('выбор иконки', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(theme == 'dark' ? Brightness.dark : Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async => picked = await pickIcon(context, current: 'code'),
                child: const Text('Иконка'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Иконка'));
    await tester.pumpAndSettle();
    if (screenshots) await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/$theme/14_icon_picker.png'));
    await tester.tap(find.byIcon(Icons.bedtime_rounded).hitTestable().first);
    await tester.pumpAndSettle();
    expect(picked, 'bedtime');
  });

  testWidgets('первый запуск показывает выбор шаблона', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(PlanerApp(db: db, notifications: NotificationService(db)));
    await pumpData(tester);
    expect(find.text('С чего начнём?'), findsOneWidget);
    await shot(tester, '00_setup');
    await tester.scrollUntilVisible(find.text('Чистый лист').hitTestable(), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Чистый лист').hitTestable());
    await pumpData(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
}

Future<void> back(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
}

/// Даёт базе ответить и интерфейсу перерисоваться.
Future<void> pumpData(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 400));
}

extension TransactionsCompanionX on TransactionsCompanion {
  static TransactionsCompanion expense(double amount, int categoryId, int day) =>
      TransactionsCompanion.insert(amount: amount, day: day, categoryId: Value(categoryId));
}
