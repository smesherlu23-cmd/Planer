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
    Accounts,
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
    Transfers,
    Recurrings,
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
        // Версия 5: счета, переводы, регулярные платежи. Шаг можно повторить без вреда.
        await addMoneyAccounts(m);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

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
