import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'dates.dart';
import 'food_data.dart';
import 'icon_keys.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// Типы
// ---------------------------------------------------------------------------

/// Какую величину хранит трекер.
enum TrackerKind {
  /// Любое число: вес, пробег, уровень Faceit.
  number,

  /// Оценка от 1 до 10: настроение, энергия.
  scale10,

  /// Время в минутах, можно с таймером: часы кода, чтение.
  duration,

  /// Да или нет.
  yesNo,
}

/// К чему привязана цель.
enum GoalKind {
  /// Последнее значение трекера.
  tracker,

  /// Баланс копилки или остаток долга.
  fund,

  /// Значение вносится вручную: «прочитать 12 книг», «уровень Faceit 8».
  manual,

  /// Проект из этапов: прогресс считается по сделанным шагам.
  steps,
}

/// Сфера жизни, к которой относится цель.
enum GoalArea { health, money, career, study, relations, hobby, other }

enum FundKind {
  /// Копилка: баланс растёт от взносов.
  savings,

  /// Долг: остаток уменьшается от платежей.
  debt,
}

/// Как часто повторяется регулярный платёж.
enum RepeatKind { weekly, monthly, yearly }

/// Что делает регулярный платёж: расход, доход или взнос в копилку и платёж по долгу.
enum RecurringKind { expense, income, fund }

/// На что уходит время в плане дня.
enum BlockKind { sleep, work, study, sport, rest, home, road, food, other }

enum JournalKind {
  /// Итог дня.
  day,

  /// Обзор недели.
  week,

  /// Просто заметка.
  note,

  /// Обзор месяца.
  month,
}

// ---------------------------------------------------------------------------
// Таблицы
// ---------------------------------------------------------------------------

/// Регулярное действие с расписанием и отметкой.
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('check'))();
  IntColumn get daysMask => integer().withDefault(const Constant(everyDay))();

  /// Время напоминания в минутах от полуночи.
  IntColumn get reminderMinutes => integer().nullable()();

  /// Что считается минимумом в плохой день.
  TextColumn get minimumText => text().nullable()();

  /// Если задан, привычка отмечается сама, когда в этот трекер вносят значение.
  IntColumn get trackerId => integer().nullable().references(Trackers, #id, onDelete: KeyAction.setNull)();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 0: сделать (полезная привычка), 1: бросить (отметка = день без срыва).
  IntColumn get kind => integer().withDefault(const Constant(0))();

  /// Цель в день для привычки-количества (8 стаканов, 20 страниц). null: просто отметка.
  RealColumn get target => real().nullable()();
  TextColumn get unit => text().nullable()();

  /// Сколько раз в неделю. null: по дням из [daysMask].
  IntColumn get perWeek => integer().nullable()();

  /// Время дня: 0 любое, 1 утро, 2 день, 3 вечер.
  IntColumn get partOfDay => integer().withDefault(const Constant(0))();

  /// Якорь: после чего делаю («после утреннего кофе»).
  TextColumn get cue => text().nullable()();

  /// Зачем это мне.
  TextColumn get why => text().nullable()();
}

/// Подробности дня привычки: сколько сделано, пропуск по уважительной причине, заметка.
/// Сама отметка «сделано» живёт в [HabitLogs].
class HabitDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get day => integer()();
  RealColumn get value => real().nullable()();
  BoolColumn get skipped => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {habitId, day},
  ];
}

class HabitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get day => integer()();
  BoolColumn get minimum => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {habitId, day},
  ];
}

/// Любая величина с историей.
class Trackers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('chart'))();
  TextColumn get unit => text().nullable()();
  IntColumn get kind => intEnum<TrackerKind>()();

  /// В какие дни трекер показывается на экране «Сегодня». 0 = не показывать.
  IntColumn get daysMask => integer().withDefault(const Constant(0))();
  IntColumn get reminderMinutes => integer().nullable()();

  /// Норма и минимум за день, для чисел и времени. Без них засчитывается любое значение.
  RealColumn get dailyGoal => real().nullable()();
  RealColumn get dailyMin => real().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TrackerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackerId => integer().references(Trackers, #id, onDelete: KeyAction.cascade)();
  IntColumn get day => integer()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
  RealColumn get value => real()();
  TextColumn get note => text().nullable()();
}

/// Измеримая цель.
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get kind => intEnum<GoalKind>()();
  IntColumn get trackerId => integer().nullable().references(Trackers, #id, onDelete: KeyAction.setNull)();
  IntColumn get fundId => integer().nullable().references(Funds, #id, onDelete: KeyAction.setNull)();
  RealColumn get startValue => real()();
  RealColumn get targetValue => real()();

  /// Минимальный результат, который уже можно считать успехом. Необязательно.
  RealColumn get minimumValue => real().nullable()();

  /// Желаемый срок (ключ дня), необязательно.
  IntColumn get deadline => integer().nullable()();
  IntColumn get startDay => integer()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Сфера жизни. null у целей до версии 5.
  IntColumn get area => intEnum<GoalArea>().nullable()();

  /// Единица для цели с ручными отметками: «книг», «кг».
  TextColumn get unit => text().nullable()();

  /// Зачем мне это: главный мотив.
  TextColumn get why => text().nullable()();

  /// Что может помешать (метод WOOP).
  TextColumn get obstacle => text().nullable()();

  /// План «если…, то…» на этот случай.
  TextColumn get plan => text().nullable()();

  /// Привычки, которые ведут к цели: id через запятую.
  TextColumn get habitIds => text().nullable()();

  /// День, когда цель отмечена достигнутой.
  IntColumn get achievedDay => integer().nullable()();
}

/// Этап цели: шаг проекта или промежуточная веха.
class GoalSteps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(Goals, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  IntColumn get dueDay => integer().nullable()();
  IntColumn get doneDay => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Ручная отметка прогресса цели: значение на день.
class GoalCheckins extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(Goals, #id, onDelete: KeyAction.cascade)();
  IntColumn get day => integer()();
  RealColumn get value => real()();
  TextColumn get note => text().nullable()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('payments'))();
  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();

  /// Лимит на месяц, необязательно.
  RealColumn get monthlyLimit => real().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Расход или доход.
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  IntColumn get day => integer()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();

  /// Счёт, с которого ушли или на который пришли деньги. null: счёт не указан.
  IntColumn get accountId => integer().nullable().references(Accounts, #id, onDelete: KeyAction.setNull)();
}

/// Где лежат деньги: карта, наличные, накопительный счёт.
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('card'))();

  /// Остаток до первой записанной операции. Корректировка баланса меняет именно его.
  RealColumn get initialBalance => real().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Перевод между своими счетами: не доход и не расход.
class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('transfersOut')
  IntColumn get fromAccountId => integer().references(Accounts, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('transfersIn')
  IntColumn get toAccountId => integer().references(Accounts, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  IntColumn get day => integer()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();
}

/// Регулярный платёж: зарплата, подписка, связь, платёж по кредиту.
class Recurrings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('payments'))();
  IntColumn get kind => intEnum<RecurringKind>()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  IntColumn get accountId => integer().nullable().references(Accounts, #id, onDelete: KeyAction.setNull)();
  IntColumn get fundId => integer().nullable().references(Funds, #id, onDelete: KeyAction.cascade)();
  IntColumn get repeat => intEnum<RepeatKind>()();

  /// Каждые сколько недель, месяцев или лет.
  IntColumn get every => integer().withDefault(const Constant(1))();

  /// Ближайшая дата платежа. После оплаты сдвигается на следующий период.
  IntColumn get nextDay => integer()();

  /// Число месяца для ежемесячных и ежегодных: чтобы 31-е после февраля снова стало 31-м.
  IntColumn get monthDay => integer().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Копилка или долг.
class Funds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('savings'))();
  IntColumn get kind => intEnum<FundKind>()();

  /// Для копилки: сколько уже было на старте. Для долга: сколько был должен на старте.
  RealColumn get initialAmount => real().withDefault(const Constant(0))();

  /// Для копилки: сколько нужно накопить.
  RealColumn get target => real().nullable()();

  /// Для долга: годовая ставка в процентах.
  RealColumn get interestRate => real().nullable()();

  /// Для долга: плановый платёж в месяц. Для копилки: плановый взнос в месяц.
  RealColumn get monthlyAmount => real().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Взнос в копилку (плюс), снятие (минус) или платёж по долгу (плюс).
class FundMoves extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fundId => integer().references(Funds, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  IntColumn get day => integer()();
  TextColumn get note => text().nullable()();

  /// Счёт, с которого внесли или на который сняли. null: счёт не указан.
  IntColumn get accountId => integer().nullable().references(Accounts, #id, onDelete: KeyAction.setNull)();
}

/// Программа тренировок, например «Тренировка A».
class Programs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get daysMask => integer().withDefault(const Constant(0))();
  IntColumn get reminderMinutes => integer().nullable()();
  TextColumn get note => text().nullable()();

  /// Минимум на тяжёлый день: сколько подходов на упражнение и что ещё сделать.
  IntColumn get minSets => integer().nullable()();
  TextColumn get minimumText => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class ProgramExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programId => integer().references(Programs, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get sets => integer().withDefault(const Constant(3))();
  IntColumn get repsMin => integer().withDefault(const Constant(8))();
  IntColumn get repsMax => integer().withDefault(const Constant(12))();

  /// «повт» или «сек».
  TextColumn get unit => text().withDefault(const Constant('повт'))();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Основная мышечная группа: ключ из exercise_catalog.dart. null: берётся из каталога по названию.
  TextColumn get muscle => text().nullable()();

  /// Отдых между подходами в секундах. null: из каталога или 90 секунд.
  IntColumn get restSec => integer().nullable()();
}

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programId => integer().nullable().references(Programs, #id, onDelete: KeyAction.setNull)();
  TextColumn get programName => text()();
  IntColumn get day => integer()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();

  /// Сделано меньше плана: облегчённая тренировка.
  BoolColumn get minimum => boolean().withDefault(const Constant(false))();

  /// Сколько длилась тренировка, в секундах.
  IntColumn get durationSec => integer().nullable()();

  /// Самочувствие после тренировки от 1 (тяжело) до 5 (отлично).
  IntColumn get feel => integer().nullable()();
}

class SessionSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().nullable().references(ProgramExercises, #id, onDelete: KeyAction.setNull)();
  TextColumn get exerciseName => text()();
  IntColumn get setIndex => integer()();
  IntColumn get reps => integer()();
  RealColumn get weight => real().nullable()();
}

class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kind => intEnum<JournalKind>()();
  IntColumn get day => integer()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
  IntColumn get mood => integer().nullable()();
  TextColumn get body => text().withDefault(const Constant(''))();

  /// Заголовок заметки.
  TextColumn get title => text().nullable()();

  /// Энергия от 1 до 5.
  IntColumn get energy => integer().nullable()();

  /// Теги через запятую: «работа», «спорт», «плохой сон».
  TextColumn get tags => text().nullable()();

  /// Победы: что получилось. По строке на пункт.
  TextColumn get wins => text().nullable()();

  /// За что благодарен.
  TextColumn get gratitude => text().nullable()();

  /// Урок: что не получилось и почему, что улучшить.
  TextColumn get lesson => text().nullable()();

  /// Главное на завтра, на следующую неделю или месяц.
  TextColumn get focus => text().nullable()();

  /// Заметка к цели.
  IntColumn get goalId => integer().nullable().references(Goals, #id, onDelete: KeyAction.setNull)();
}

/// Свои напоминания, не привязанные к привычке: «Итог дня», «Обзор недели».
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  IntColumn get minutes => integer()();
  IntColumn get daysMask => integer().withDefault(const Constant(everyDay))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}

/// Одна ночь сна. День записи это день, когда проснулся.
class SleepLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get day => integer()();
  DateTimeColumn get bedAt => dateTime()();
  DateTimeColumn get wakeAt => dateTime()();

  /// Как выспался, от 1 до 5.
  IntColumn get quality => integer().nullable()();
  TextColumn get note => text().nullable()();

  /// Дневник сна: сколько минут засыпал, сколько раз просыпался ночью и сколько минут не спал.
  IntColumn get latency => integer().nullable()();
  IntColumn get awakenings => integer().nullable()();
  IntColumn get awakeMinutes => integer().nullable()();

  /// Что было вечером: ключи через запятую (coffee, alcohol, screen...).
  TextColumn get tags => text().nullable()();
}

/// Своё блюдо или продукт для добавления в один тап.
class Foods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('restaurant'))();
  RealColumn get kcal => real()();
  RealColumn get protein => real().withDefault(const Constant(0))();
  RealColumn get fat => real().withDefault(const Constant(0))();
  RealColumn get carbs => real().withDefault(const Constant(0))();

  /// Вес порции, г. Если задан, порцию можно записать в граммах: цифры пересчитываются.
  RealColumn get grams => real().nullable()();

  /// Состав рецепта: JSON-список ингредиентов с весом и БЖУ на 100 г. null у обычного блюда.
  TextColumn get ingredients => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// Что съел. Название и цифры копируются из блюда, чтобы правка блюда не меняла историю.
class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get day => integer()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('restaurant'))();
  RealColumn get kcal => real()();
  RealColumn get protein => real().withDefault(const Constant(0))();
  RealColumn get fat => real().withDefault(const Constant(0))();
  RealColumn get carbs => real().withDefault(const Constant(0))();

  /// Приём пищи: 0 завтрак, 1 обед, 2 ужин, 3 перекус. null у записей до версии 4: определяется по времени.
  IntColumn get slot => integer().nullable()();

  /// Сколько граммов съел, если записано по весу.
  RealColumn get grams => real().nullable()();
  IntColumn get foodId => integer().nullable().references(Foods, #id, onDelete: KeyAction.setNull)();
}

/// Выпитая вода.
class WaterLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get day => integer()();
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
  IntColumn get ml => integer()();
}

/// День, отмеченный как тяжёлый: в этот день засчитывается минимум.
class HardDays extends Table {
  IntColumn get day => integer()();

  @override
  Set<Column> get primaryKey => {day};
}

/// Блок времени в плане дня, например «Работа 8:00–17:00 по будням».
class TimeBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('clock'))();
  IntColumn get kind => intEnum<BlockKind>()();

  /// Начало и конец в минутах от полуночи. Конец меньше начала: блок через полночь.
  IntColumn get start => integer()();
  IntColumn get end => integer()();
  IntColumn get daysMask => integer().withDefault(const Constant(everyDay))();

  /// Напомнить в начале блока.
  BoolColumn get remind => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
}

/// Строка бюджета на месяц: плановый доход по категории, лимит расходов по категории или взнос в копилку и платёж по долгу.
class BudgetLines extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Месяц как yyyymm, например 202611.
  IntColumn get month => integer()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get fundId => integer().nullable().references(Funds, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ---------------------------------------------------------------------------
// База
// ---------------------------------------------------------------------------

// Порядок важен для импорта: таблица идёт после тех, на которые ссылается.
@DriftDatabase(
  tables: [
    Trackers,
    TrackerEntries,
    Habits,
    HabitLogs,
    HabitDays,
    Accounts,
    Funds,
    Goals,
    GoalSteps,
    GoalCheckins,
    Categories,
    Transactions,
    FundMoves,
    Programs,
    ProgramExercises,
    WorkoutSessions,
    SessionSets,
    JournalEntries,
    Reminders,
    Settings,
    SleepLogs,
    Foods,
    Meals,
    WaterLogs,
    HardDays,
    TimeBlocks,
    BudgetLines,
    Transfers,
    Recurrings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'planer'));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Версия 2: сон, питание и иконки вместо эмодзи.
        await m.createTable(sleepLogs);
        await m.createTable(foods);
        await m.createTable(meals);
        await m.createTable(waterLogs);
        await convertEmojiIcons();
      }
      if (from < 3) {
        // Версия 3: тяжёлые дни по датам, пороги минимума, план дня, бюджет.
        await m.createTable(hardDays);
        await m.createTable(timeBlocks);
        await m.createTable(budgetLines);
        await m.addColumn(trackers, trackers.dailyGoal);
        await m.addColumn(trackers, trackers.dailyMin);
        await m.addColumn(goals, goals.minimumValue);
        await m.addColumn(programs, programs.minSets);
        await m.addColumn(programs, programs.minimumText);
        await m.addColumn(workoutSessions, workoutSessions.minimum);
        await moveLegacyHardDay();
      }
      // Таблицы питания, созданные шагом версии 2, уже с новыми колонками: добавляем только недостающие.
      Future<void> add(TableInfo<Table, Object?> table, GeneratedColumn<Object> column) async {
        final cols = await customSelect('PRAGMA table_info("${table.actualTableName}")').get();
        if (!cols.any((c) => c.read<String>('name') == column.name)) await m.addColumn(table, column);
      }

      if (from < 4) {
        // Версия 4: жиры и углеводы у блюд и записей, приём пищи у записи.
        await add(foods, foods.fat);
        await add(foods, foods.carbs);
        await add(meals, meals.fat);
        await add(meals, meals.carbs);
        await add(meals, meals.slot);
        await fillTemplateMacros();
      }
      if (from < 6) {
        // Версии 5–6: модули разрабатывались параллельно и каждый поднимал версию до 5. Все шаги ниже
        // добавляют только недостающее, поэтому база любого промежуточного выпуска с версией 5 догоняется целиком.
        // Версия 5: вес порции и рецепты у блюд, вес у записи.
        await add(foods, foods.grams);
        await add(foods, foods.ingredients);
        await add(meals, meals.grams);
        // Версия 5: привычки-количества, N раз в неделю, бросить; дневник сна.
        await addMissingColumns(m, habits, [
          habits.kind,
          habits.target,
          habits.unit,
          habits.perWeek,
          habits.partOfDay,
          habits.cue,
          habits.why,
        ]);
        await addMissingColumns(m, sleepLogs, [sleepLogs.latency, sleepLogs.awakenings, sleepLogs.awakeMinutes, sleepLogs.tags]);
        await customStatement(
          'CREATE TABLE IF NOT EXISTS "habit_days" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          '"habit_id" INTEGER NOT NULL REFERENCES habits (id) ON DELETE CASCADE, "day" INTEGER NOT NULL, "value" REAL NULL, '
          '"skipped" INTEGER NOT NULL DEFAULT 0 CHECK ("skipped" IN (0, 1)), "note" TEXT NULL, UNIQUE ("habit_id", "day"))',
        );
        // Версия 5: спорт. Мышцы и отдых у упражнений, длительность и самочувствие у тренировки.
        await _addColumnIfMissing(m, programExercises, programExercises.muscle);
        await _addColumnIfMissing(m, programExercises, programExercises.restSec);
        await _addColumnIfMissing(m, workoutSessions, workoutSessions.durationSec);
        await _addColumnIfMissing(m, workoutSessions, workoutSessions.feel);
        // Версия 5: цели с этапами и ручными отметками, сферы, мотив и план; дневник с победами, тегами и фокусом.
        await _createTableOnce(m, goalSteps);
        await _createTableOnce(m, goalCheckins);
        for (final c in <GeneratedColumn<Object>>[goals.area, goals.unit, goals.why, goals.obstacle, goals.plan, goals.habitIds, goals.achievedDay]) {
          await _addColumnOnce(m, goals, c);
        }
        for (final c in <GeneratedColumn<Object>>[
          journalEntries.title,
          journalEntries.energy,
          journalEntries.tags,
          journalEntries.wins,
          journalEntries.gratitude,
          journalEntries.lesson,
          journalEntries.focus,
          journalEntries.goalId,
        ]) {
          await _addColumnOnce(m, journalEntries, c);
        }
        // Версия 5: счета, переводы, регулярные платежи. Шаг можно повторить без вреда.
        await addMoneyAccounts(m);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Добавить колонки, которых ещё нет: миграция переживает повторный запуск и смену номеров версий.
  Future<void> addMissingColumns(Migrator m, TableInfo<Table, Object?> table, List<GeneratedColumn<Object>> columns) async {
    final cols = await customSelect('PRAGMA table_info("${table.actualTableName}")').get();
    final have = {for (final c in cols) c.read<String>('name')};
    for (final c in columns) {
      if (!have.contains(c.name)) await m.addColumn(table, c);
    }
  }

  /// Добавить столбец, только если его ещё нет: шаги миграций из параллельных веток можно применять в любом порядке.
  Future<void> _addColumnIfMissing(Migrator m, TableInfo<Table, Object?> table, GeneratedColumn<Object> column) async {
    final cols = await customSelect('PRAGMA table_info("${table.actualTableName}")').get();
    if (!cols.any((c) => c.read<String>('name') == column.name)) await m.addColumn(table, column);
  }

  Future<bool> _hasColumn(TableInfo<Table, Object?> table, GeneratedColumn<Object> column) async {
    final cols = await customSelect('PRAGMA table_info("${table.actualTableName}")').get();
    return cols.any((c) => c.read<String>('name') == column.name);
  }

  Future<bool> _hasTable(TableInfo<Table, Object?> table) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable(table.actualTableName)],
    ).get();
    return rows.isNotEmpty;
  }

  /// Счета появились в версии 5. Старые операции и взносы относим к счёту «Карта»,
  /// чтобы остаток сразу считался; его можно поправить, указав, сколько на карте сейчас.
  Future<void> addMoneyAccounts(Migrator m) async {
    for (final t in <TableInfo<Table, Object?>>[accounts, transfers, recurrings]) {
      if (!await _hasTable(t)) await m.createTable(t);
    }
    if (!await _hasColumn(transactions, transactions.accountId)) await m.addColumn(transactions, transactions.accountId);
    if (!await _hasColumn(fundMoves, fundMoves.accountId)) await m.addColumn(fundMoves, fundMoves.accountId);
    final hasAccounts = (await customSelect('SELECT id FROM accounts LIMIT 1').get()).isNotEmpty;
    final hasTxs = (await customSelect('SELECT id FROM transactions LIMIT 1').get()).isNotEmpty;
    if (!hasAccounts && hasTxs) {
      final id = await into(accounts).insert(AccountsCompanion.insert(name: 'Карта', sortOrder: const Value(1)));
      await customStatement('UPDATE transactions SET account_id = ? WHERE account_id IS NULL', [id]);
    }
  }

  /// Раньше тяжёлый день хранился одной настройкой и забывался на следующий день. Переносим его в таблицу.
  Future<void> moveLegacyHardDay() async {
    final row = await customSelect("SELECT value FROM settings WHERE key = 'bad_day'").getSingleOrNull();
    final day = int.tryParse(row?.read<String>('value') ?? '');
    if (day != null) await customStatement('INSERT OR IGNORE INTO hard_days (day) VALUES (?)', [day]);
    await customStatement("DELETE FROM settings WHERE key = 'bad_day'");
  }

  /// Блюда из шаблона «Мой план» были без жиров и углеводов: дописываем их и в блюда, и в уже записанную еду.
  Future<void> fillTemplateMacros() async {
    for (final (name, fat, carbs) in templateFoodMacros) {
      await customStatement('UPDATE foods SET fat = ?, carbs = ? WHERE name = ? AND fat = 0 AND carbs = 0', [fat, carbs, name]);
      await customStatement('UPDATE meals SET fat = ?, carbs = ? WHERE name = ? AND fat = 0 AND carbs = 0', [fat, carbs, name]);
    }
  }

  /// Заменить эмодзи из старых версий на ключи иконок. Неизвестные значения не трогает.
  Future<void> convertEmojiIcons() async {
    for (final table in ['habits', 'trackers', 'funds', 'categories']) {
      final rows = await customSelect('SELECT id, icon FROM "$table"').get();
      for (final r in rows) {
        final old = r.read<String>('icon');
        final key = iconKeyFor(old);
        if (key != null && key != old) {
          await customStatement('UPDATE "$table" SET icon = ? WHERE id = ?', [key, r.read<int>('id')]);
        }
      }
    }
  }

  // ----- Настройки -----

  Future<String?> getSetting(String key) async {
    final row = await (select(settings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watchSetting(String key) => (select(settings)..where((t) => t.key.equals(key))).watchSingleOrNull().map((r) => r?.value);

  Future<void> setSetting(String key, String? value) async {
    if (value == null) {
      await (delete(settings)..where((t) => t.key.equals(key))).go();
    } else {
      await into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
    }
  }
}
