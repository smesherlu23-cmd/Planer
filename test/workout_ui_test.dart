// Модуль «Спорт»: вкладки, карточка упражнения и тренировка от начала до итогов.
// С --dart-define=SCREENSHOTS=true сохраняет картинки в test/screens/.
import 'package:drift/drift.dart' show driftRuntimeOptions, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/app.dart';
import 'package:planer/data/database.dart';
import 'package:planer/data/dates.dart';
import 'package:planer/data/queries.dart';
import 'package:planer/data/templates.dart';
import 'package:planer/data/workout_queries.dart';
import 'package:planer/services/notifications.dart';
import 'package:planer/ui/workout_progress.dart';

import 'ui_test.dart' show back, loadFonts, pumpData, screenshots, theme;

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

  testWidgets('спорт: вкладки и тренировка до итогов', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory());
    final today = todayKey();
    await tester.runAsync(() async {
      await applyTemplate(db, 'my_plan', today: addDays(today, -40));
      await db.setSetting('setup_done', '1');
      if (theme == 'dark') await db.setSetting('theme', 'dark');
      final programs = await db.select(db.programs).get();
      final a = programs.firstWhere((p) => p.name == 'Тренировка A');
      final b = programs.firstWhere((p) => p.name == 'Тренировка B');
      // Пять недель истории: понедельник, среда, пятница, повторы растут.
      var n = 0;
      for (var w = 5; w >= 1; w--) {
        for (final d in [0, 2, 4]) {
          final day = addDays(weekStart(today), -7 * w + d);
          final p = n.isEven ? a : b;
          final exercises = await db.exercisesOf(p.id);
          await db.saveWorkout(
            programId: p.id,
            programName: p.name,
            day: day,
            durationSec: 2400 + n * 30,
            minimum: n == 7,
            sets: [
              for (final e in exercises)
                for (var i = 0; i < (n == 7 ? 1 : e.sets); i++)
                  SessionSetsCompanion.insert(
                    sessionId: 0,
                    exerciseId: Value(e.id),
                    exerciseName: e.name,
                    setIndex: i,
                    reps: (e.repsMin + n ~/ 2 - i).clamp(1, e.repsMax),
                  ),
            ],
          );
          final last = (await db.select(db.workoutSessions).get()).last;
          await db.updateSessionInfo(last.id, feel: 3 + n % 3);
          n++;
        }
      }
      await db.setSportGoal('Подтягивания', 15);
    });

    await tester.pumpWidget(PlanerApp(db: db, notifications: NotificationService(db)));
    await pumpData(tester);
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Спорт')));
    await pumpData(tester);
    expect(find.textContaining('Начать:'), findsOneWidget);
    await shot(tester, '20_sport_overview');

    await tester.tap(find.text('История'));
    await pumpData(tester);
    await shot(tester, '21_sport_history');

    await tester.tap(find.text('Прогресс'));
    await pumpData(tester);
    await shot(tester, '22_sport_progress');
    final list = find.descendant(of: find.byType(ProgressTab), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Нагрузка на мышцы за 7 дней'), 300, scrollable: list);
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '22b_sport_progress_muscles');
    await tester.scrollUntilVisible(find.text('Упражнения').hitTestable(), 300, scrollable: list);
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, '22c_sport_progress_exercises');

    // Карточка упражнения.
    await tester.scrollUntilVisible(find.text('Подтягивания').hitTestable(), 200, scrollable: list);
    await tester.tap(find.text('Подтягивания').hitTestable().last);
    await pumpData(tester);
    expect(find.text('Лестница усложнения'), findsOneWidget);
    await shot(tester, '23_sport_exercise');
    await back(tester);
    await pumpData(tester);

    // Тренировка: отметить подход, увидеть отдых, завершить.
    await tester.tap(find.text('Обзор'));
    await pumpData(tester);
    // Кнопка «Начать» внизу спряталась после прокрутки: идём через карточку следующей тренировки.
    await tester.tap(find.text('Тренировка B').hitTestable().first);
    await pumpData(tester);
    await shot(tester, '26_sport_program');
    await tester.tap(find.text('Начать').hitTestable().first);
    await pumpData(tester);
    expect(find.text('Завершить'), findsOneWidget);
    await shot(tester, '24_sport_session');
    await tester.tap(find.byTooltip('Подход сделан').first);
    await pumpData(tester);
    expect(find.textContaining('Отдых'), findsWidgets);
    await shot(tester, '24b_sport_session_rest');
    final draft = await tester.runAsync(() => db.workoutDraft());
    expect(draft!.exercises.first.sets.first.$3, isTrue);

    await tester.tap(find.text('Завершить'));
    await pumpData(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Завершить').last);
    await pumpData(tester);
    expect(find.text('Как ощущения?'), findsOneWidget);
    await shot(tester, '25_sport_summary');
    await tester.tap(find.text('Готово'));
    await pumpData(tester);
    final sessions = await tester.runAsync(() => db.select(db.workoutSessions).get());
    expect(sessions!.where((s) => s.day == today).length, 1);
    expect(await tester.runAsync(() => db.workoutDraft()), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close());
  });
}
