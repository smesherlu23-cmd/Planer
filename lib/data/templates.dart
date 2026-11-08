/// Шаблоны для быстрого старта.
///
/// Шаблон просто добавляет обычные записи: потом их можно менять и удалять
/// как угодно, приложение ни к чему из этого не привязано.
library;

import 'package:drift/drift.dart';

import 'database.dart';
import 'dates.dart';
import '../logic/calc.dart';
import 'queries.dart';

const _mon = 1, _wed = 3, _fri = 5, _sun = 7;

class TemplateInfo {
  const TemplateInfo(this.id, this.title, this.description);
  final String id;
  final String title;
  final String description;
}

const templates = [
  TemplateInfo(
    'my_plan',
    'Мой план',
    'Режим сна, код, спина, тренировки A и B, вес и силовые цели, кредит, копилки на права и Civic, итог дня и обзор недели.',
  ),
  TemplateInfo('basic', 'Чистый лист', 'Только категории расходов и доходов. Всё остальное добавишь сам.'),
];

Future<void> applyTemplate(AppDatabase db, String id, {int? today}) async {
  final day = today ?? todayKey();
  await db.transaction(() async {
    switch (id) {
      case 'my_plan':
        await _basicCategories(db);
        await _myPlan(db, day);
      case 'basic':
        await _basicCategories(db);
      default:
        throw ArgumentError('Нет шаблона $id');
    }
  });
}

Future<void> _basicCategories(AppDatabase db) async {
  final existing = await db.select(db.categories).get();
  if (existing.isNotEmpty) return;
  const expenses = [
    ('Еда и перекусы', '🍌'),
    ('Одежда', '👕'),
    ('Уход и здоровье', '🧴'),
    ('Транспорт', '🚌'),
    ('Связь и подписки', '📱'),
    ('Игры и развлечения', '🎮'),
    ('Учёба', '📚'),
    ('Подарки', '🎁'),
    ('Другое', '💸'),
  ];
  const incomes = [('Зарплата', '💰'), ('Другой доход', '💵')];
  for (final (name, icon) in expenses) {
    await db.saveCategory(CategoriesCompanion.insert(name: name, icon: Value(icon)));
  }
  for (final (name, icon) in incomes) {
    await db.saveCategory(CategoriesCompanion.insert(name: name, icon: Value(icon), isIncome: const Value(true)));
  }
}

Future<void> _myPlan(AppDatabase db, int today) async {
  final in6Months = addMonths(today, 6);

  // ----- Трекеры -----
  final weight = await db.saveTracker(
    TrackersCompanion.insert(
      name: 'Вес',
      icon: const Value('⚖️'),
      unit: const Value('кг'),
      kind: TrackerKind.number,
      daysMask: Value(maskFromWeekdays([_sun])),
      reminderMinutes: const Value(9 * 60),
    ),
  );
  final code = await db.saveTracker(
    TrackersCompanion.insert(
      name: 'Время кода',
      icon: const Value('⏱️'),
      unit: const Value('мин'),
      kind: TrackerKind.duration,
      daysMask: Value(maskFromWeekdays([1, 2, 3, 4, 5, 6])),
    ),
  );
  final pullups = await db.saveTracker(
    TrackersCompanion.insert(name: 'Подтягивания подряд', icon: const Value('💪'), unit: const Value('раз'), kind: TrackerKind.number),
  );
  final pushups = await db.saveTracker(
    TrackersCompanion.insert(name: 'Отжимания подряд', icon: const Value('🙌'), unit: const Value('раз'), kind: TrackerKind.number),
  );
  await db.saveTracker(
    TrackersCompanion.insert(name: 'Faceit', icon: const Value('🎯'), unit: const Value('ELO'), kind: TrackerKind.number),
  );

  // Стартовые значения, которые уже известны.
  await db.addEntry(weight, 67, day: today, note: 'старт');
  await db.addEntry(pullups, 10, day: today, note: 'старт');
  await db.addEntry(pushups, 15, day: today, note: 'старт');

  // ----- Привычки: первый месяц только три опорные -----
  await db.saveHabit(HabitsCompanion.insert(name: 'Отбой до 23:00', icon: const Value('😴'), minimumText: const Value('Лечь до полуночи')));
  await db.saveHabit(
    HabitsCompanion.insert(
      name: 'Программирование',
      icon: const Value('💻'),
      daysMask: Value(maskFromWeekdays([1, 2, 3, 4, 5, 6])),
      reminderMinutes: const Value(18 * 60 + 45),
      minimumText: const Value('20 минут кода'),
      trackerId: Value(code),
    ),
  );
  await db.saveHabit(
    HabitsCompanion.insert(
      name: 'Спина и осанка',
      icon: const Value('🧘'),
      minimumText: const Value('Вис на турнике и разгибание на валике'),
    ),
  );

  // ----- Деньги -----
  final loan = await db.saveFund(
    FundsCompanion.insert(
      name: 'Кредит',
      icon: const Value('🏦'),
      kind: FundKind.debt,
      initialAmount: const Value(120000),
      monthlyAmount: const Value(12000),
    ),
  );
  await db.saveFund(FundsCompanion.insert(name: 'Права', icon: const Value('🪪'), kind: FundKind.savings, target: const Value(60000)));
  final civic = await db.saveFund(
    FundsCompanion.insert(name: 'Honda Civic', icon: const Value('🚗'), kind: FundKind.savings, target: const Value(300000)),
  );

  // ----- Цели -----
  await db.saveGoal(
    GoalsCompanion.insert(
      name: 'Вес 73 кг',
      kind: GoalKind.tracker,
      trackerId: Value(weight),
      startValue: 67,
      targetValue: 73,
      deadline: Value(in6Months),
      startDay: today,
    ),
  );
  await db.saveGoal(
    GoalsCompanion.insert(
      name: '15 подтягиваний подряд',
      kind: GoalKind.tracker,
      trackerId: Value(pullups),
      startValue: 10,
      targetValue: 15,
      deadline: Value(in6Months),
      startDay: today,
    ),
  );
  await db.saveGoal(
    GoalsCompanion.insert(
      name: '30 отжиманий подряд',
      kind: GoalKind.tracker,
      trackerId: Value(pushups),
      startValue: 15,
      targetValue: 30,
      deadline: Value(in6Months),
      startDay: today,
    ),
  );
  await db.saveGoal(
    GoalsCompanion.insert(
      name: 'Закрыть кредит',
      kind: GoalKind.fund,
      fundId: Value(loan),
      startValue: 120000,
      targetValue: 0,
      startDay: today,
    ),
  );
  await db.saveGoal(
    GoalsCompanion.insert(
      name: 'Накопить на Civic',
      kind: GoalKind.fund,
      fundId: Value(civic),
      startValue: 0,
      targetValue: 300000,
      startDay: today,
    ),
  );

  // ----- Тренировки -----
  final workoutDays = maskFromWeekdays([_mon, _wed, _fri]);
  const workoutNote =
      'Разминка 5 минут, в конце 15 минут на спину. Чередуй A и B: на одной неделе A–B–A, на следующей B–A–B. '
      'До врача никакого веса на позвоночник.';
  final a = await db.saveProgram(
    ProgramsCompanion.insert(
      name: 'Тренировка A',
      daysMask: Value(workoutDays),
      reminderMinutes: const Value(18 * 60),
      note: const Value(workoutNote),
    ),
  );
  await _exercises(db, a, const [
    ('Подтягивания', 4, 6, 8, 'повт', 'Оставляй 2 повтора в запасе. Усложнить: вниз за 3 секунды, пауза наверху'),
    ('Отжимания от пола', 3, 10, 12, 'повт', 'Когда получается 3 × 15: ноги на стул'),
    ('Приседания без веса', 3, 15, 20, 'повт', 'Усложнить: вниз за 3 секунды и пауза внизу'),
    ('Ягодичный мост', 3, 15, 15, 'повт', 'Усложнить: на одной ноге'),
    ('Боковая планка', 3, 20, 30, 'сек', 'На каждую сторону. +5 секунд в неделю'),
  ]);
  final b = await db.saveProgram(
    ProgramsCompanion.insert(
      name: 'Тренировка B',
      daysMask: Value(workoutDays),
      reminderMinutes: const Value(18 * 60),
      note: const Value(workoutNote),
    ),
  );
  await _exercises(db, b, const [
    ('Австралийские подтягивания', 3, 12, 15, 'повт', 'К низкой перекладине или краю крепкого стола. Усложнить: ноги на стул'),
    ('Узкие отжимания', 3, 8, 12, 'повт', 'Локти вдоль тела. Усложнить: ноги на стул'),
    ('Выпады назад без веса', 3, 10, 10, 'повт', 'На каждую ногу. Усложнить: болгарские выпады'),
    ('Отжимания домиком', 3, 8, 10, 'повт', 'Таз вверх, для плеч. Усложнить: ноги на стул'),
    ('Мёртвый жук', 3, 10, 10, 'повт', 'На каждую сторону, поясница прижата'),
  ]);
  final back = await db.saveProgram(
    ProgramsCompanion.insert(
      name: 'Спина и осанка',
      note: const Value('15 минут после тренировки и 10 минут в дни без неё. После врача ЛФК заменим его комплексом.'),
    ),
  );
  await _exercises(db, back, const [
    ('Вис на турнике', 3, 20, 40, 'сек', 'Плечи расслаблены'),
    ('Тяга резинки к лицу', 3, 15, 15, 'повт', 'Резинка на уровне глаз, сводишь лопатки'),
    ('Разгибание на валике', 1, 10, 10, 'повт', 'Полотенце под лопатками, медленно назад'),
    ('Ангел у стены', 2, 10, 10, 'повт', 'Спина и затылок прижаты к стене'),
    ('Растяжка груди в дверном проёме', 2, 30, 30, 'сек', 'Мягко подаёшься вперёд'),
    ('Птица-собака', 2, 8, 8, 'повт', 'На каждую сторону, спина ровная'),
  ]);

  // ----- Напоминания -----
  await db.saveReminder(
    RemindersCompanion.insert(
      title: 'Итог дня',
      body: const Value('3 дела за сегодня и настроение. Потом телефон в сторону.'),
      minutes: 22 * 60 + 30,
    ),
  );
  await db.saveReminder(
    RemindersCompanion.insert(
      title: 'Обзор недели',
      body: const Value('15 минут: что получилось, что нет, что меняем.'),
      minutes: 20 * 60,
      daysMask: Value(maskFromWeekdays([_sun])),
    ),
  );
}

Future<void> _exercises(AppDatabase db, int programId, List<(String, int, int, int, String, String)> list) async {
  for (final (name, sets, min, max, unit, note) in list) {
    await db.saveExercise(
      ProgramExercisesCompanion.insert(
        programId: programId,
        name: name,
        sets: Value(sets),
        repsMin: Value(min),
        repsMax: Value(max),
        unit: Value(unit),
        note: Value(note),
      ),
    );
  }
}
