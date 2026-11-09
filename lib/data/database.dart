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
}

enum FundKind {
  /// Копилка: баланс растёт от взносов.
  savings,

  /// Долг: остаток уменьшается от платежей.
  debt,
}

/// На что уходит время в плане дня.
enum BlockKind { sleep, work, study, sport, rest, home, road, food, other }

enum JournalKind {
  /// Итог дня.
  day,

  /// Обзор недели.
  week,

  /// Просто заметка.
  note,
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
    Funds,
    Goals,
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'planer'));

  @override
  int get schemaVersion => 5;

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
      if (from < 4) {
        // Версия 4: жиры и углеводы у блюд и записей, приём пищи у записи.
        // Таблицы питания, созданные шагом версии 2, уже с новыми колонками.
        Future<void> add(TableInfo<Table, Object?> table, GeneratedColumn<Object> column) async {
          final cols = await customSelect('PRAGMA table_info("${table.actualTableName}")').get();
          if (!cols.any((c) => c.read<String>('name') == column.name)) await m.addColumn(table, column);
        }

        await add(foods, foods.fat);
        await add(foods, foods.carbs);
        await add(meals, meals.fat);
        await add(meals, meals.carbs);
        await add(meals, meals.slot);
        await fillTemplateMacros();
      }
      if (from < 5) {
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
