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
import 'package:planer/data/queries.dart';
import 'package:planer/data/templates.dart';
import 'package:planer/services/notifications.dart';

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

    Future<void> tab(String label, String name) async {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
      await pumpData(tester);
      await shot(tester, name);
    }

    Future<void> openFromMore(String title, String name) async {
      await tab('Ещё', '05_more');
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
    await back(tester);
    await pumpData(tester);

    await tab('Деньги', '03_money');
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

    await openFromMore('Цели', '07_goals');
    await openFromMore('Записи', '08_journal');
    await openFromMore('Отчёт недели', '09_report');
    await openFromMore('Напоминания', '10_reminders');
    await openFromMore('Настройки и данные', '11_settings');

    // Отметка привычки на «Сегодня».
    await tab('Сегодня', '01_today');
    await tester.tap(find.text('Спина и осанка').hitTestable().first);
    await pumpData(tester);
    final logs = await tester.runAsync(() => db.select(db.habitLogs).get());
    expect(logs!.any((l) => l.day == today), isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
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
