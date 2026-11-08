import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'dates.dart';

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
  TextColumn get icon => text().withDefault(const Constant('✅'))();
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
  TextColumn get icon => text().withDefault(const Constant('📈'))();
  TextColumn get unit => text().nullable()();
  IntColumn get kind => intEnum<TrackerKind>()();

  /// В какие дни трекер показывается на экране «Сегодня». 0 = не показывать.
  IntColumn get daysMask => integer().withDefault(const Constant(0))();
  IntColumn get reminderMinutes => integer().nullable()();
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

  /// Желаемый срок (ключ дня), необязательно.
  IntColumn get deadline => integer().nullable()();
  IntColumn get startDay => integer()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('💸'))();
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
  TextColumn get icon => text().withDefault(const Constant('🐷'))();
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'planer'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

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
