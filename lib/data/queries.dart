import 'package:drift/drift.dart';

import '../logic/minimum.dart';
import '../logic/values.dart';
import 'database.dart';
import 'dates.dart';

/// Запросы к базе, сгруппированные по кирпичикам.
extension Queries on AppDatabase {
  // ---------------------------------------------------------------------------
  // Привычки
  // ---------------------------------------------------------------------------

  Stream<List<Habit>> watchHabits({bool archived = false}) =>
      (select(habits)
            ..where((t) => t.archived.equals(archived))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
          .watch();

  Stream<List<HabitLog>> watchHabitLogs({required int from, required int to}) =>
      (select(habitLogs)..where((t) => t.day.isBetweenValues(from, to))).watch();

  Stream<List<HabitLog>> watchLogsOfHabit(int habitId) => (select(habitLogs)..where((t) => t.habitId.equals(habitId))).watch();

  Future<List<HabitLog>> habitLogsBetween(int from, int to) => (select(habitLogs)..where((t) => t.day.isBetweenValues(from, to))).get();

  /// Отметить или снять отметку.
  Future<void> setHabitDone(int habitId, int day, {required bool done, bool minimum = false}) async {
    await (delete(habitLogs)..where((t) => t.habitId.equals(habitId) & t.day.equals(day))).go();
    if (done) {
      await into(habitLogs).insert(HabitLogsCompanion.insert(habitId: habitId, day: day, minimum: Value(minimum)));
    }
  }

  // ---------------------------------------------------------------------------
  // Тяжёлые дни
  // ---------------------------------------------------------------------------

  Stream<Set<int>> watchHardDays() => select(hardDays).watch().map((rows) => {for (final r in rows) r.day});

  Future<bool> isHardDay(int day) async => await (select(hardDays)..where((t) => t.day.equals(day))).getSingleOrNull() != null;

  Future<List<int>> hardDaysBetween(int from, int to) async => [
    for (final r in await (select(hardDays)..where((t) => t.day.isBetweenValues(from, to))).get()) r.day,
  ];

  Future<void> setHardDay(int day, bool hard) async {
    if (hard) {
      await into(hardDays).insert(HardDaysCompanion.insert(day: Value(day)), mode: InsertMode.insertOrIgnore);
    } else {
      await (delete(hardDays)..where((t) => t.day.equals(day))).go();
    }
  }

  Future<int> saveHabit(HabitsCompanion habit) async {
    if (habit.id.present) {
      await (update(habits)..where((t) => t.id.equals(habit.id.value))).write(habit);
      return habit.id.value;
    }
    final maxOrder = await _maxOrder(habits, habits.sortOrder);
    return into(habits).insert(habit.copyWith(sortOrder: Value(maxOrder + 1)));
  }

  // ---------------------------------------------------------------------------
  // Трекеры
  // ---------------------------------------------------------------------------

  Stream<List<Tracker>> watchTrackers({bool archived = false}) =>
      (select(trackers)
            ..where((t) => t.archived.equals(archived))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
          .watch();

  Stream<List<TrackerEntry>> watchEntries(int trackerId) =>
      (select(trackerEntries)
            ..where((t) => t.trackerId.equals(trackerId))
            ..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.at)]))
          .watch();

  Stream<List<TrackerEntry>> watchAllEntriesBetween(int from, int to) =>
      (select(trackerEntries)..where((t) => t.day.isBetweenValues(from, to))).watch();

  Future<List<TrackerEntry>> entriesBetween(int from, int to) =>
      (select(trackerEntries)..where((t) => t.day.isBetweenValues(from, to))).get();

  /// Последнее значение каждого трекера.
  Stream<Map<int, TrackerEntry>> watchLatestEntries() {
    return (select(trackerEntries)..orderBy([(t) => OrderingTerm(expression: t.day), (t) => OrderingTerm(expression: t.at)])).watch().map(
      (rows) => {for (final r in rows) r.trackerId: r},
    );
  }

  /// Записать значение трекера. Привычки, привязанные к трекеру, отмечаются сами:
  /// нормой, минимумом или никак, смотря по порогам трекера и по тому, тяжёлый ли день.
  Future<int> addEntry(int trackerId, double value, {int? day, String? note}) {
    final d = day ?? todayKey();
    return transaction(() async {
      final id = await into(trackerEntries)
          .insert(TrackerEntriesCompanion.insert(trackerId: trackerId, day: d, value: value, note: Value(note)));
      final tracker = await (select(trackers)..where((t) => t.id.equals(trackerId))).getSingleOrNull();
      if (tracker != null) await _markLinkedHabits(tracker, d);
      return id;
    });
  }

  Future<void> _markLinkedHabits(Tracker tracker, int day) async {
    final entries = await (select(trackerEntries)..where((t) => t.trackerId.equals(tracker.id) & t.day.equals(day))).get();
    final value = dayValue(tracker, entries);
    if (!trackerCounts(tracker, value)) return;
    final level = trackerLevel(tracker, value);
    final minimum = level == null ? await isHardDay(day) : level == Level.minimum;
    final linked = await (select(habits)..where((t) => t.trackerId.equals(tracker.id))).get();
    for (final h in linked) {
      final existing = await (select(habitLogs)..where((t) => t.habitId.equals(h.id) & t.day.equals(day))).getSingleOrNull();
      if (existing == null) {
        await into(habitLogs).insert(HabitLogsCompanion.insert(habitId: h.id, day: day, minimum: Value(minimum)));
      } else if (existing.minimum && !minimum) {
        // Добрал до нормы: отметка становится полной.
        await (update(habitLogs)..where((t) => t.id.equals(existing.id))).write(const HabitLogsCompanion(minimum: Value(false)));
      }
    }
  }

  Future<void> updateEntry(int id, {required double value, required int day, String? note}) => (update(
    trackerEntries,
  )..where((t) => t.id.equals(id))).write(TrackerEntriesCompanion(value: Value(value), day: Value(day), note: Value(note)));

  Future<int> saveTracker(TrackersCompanion tracker) async {
    if (tracker.id.present) {
      await (update(trackers)..where((t) => t.id.equals(tracker.id.value))).write(tracker);
      return tracker.id.value;
    }
    final maxOrder = await _maxOrder(trackers, trackers.sortOrder);
    return into(trackers).insert(tracker.copyWith(sortOrder: Value(maxOrder + 1)));
  }

  // ---------------------------------------------------------------------------
  // Цели
  // ---------------------------------------------------------------------------

  Stream<List<Goal>> watchGoals({bool archived = false}) =>
      (select(goals)
            ..where((t) => t.archived.equals(archived))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
          .watch();

  Future<int> saveGoal(GoalsCompanion goal) async {
    if (goal.id.present) {
      await (update(goals)..where((t) => t.id.equals(goal.id.value))).write(goal);
      return goal.id.value;
    }
    final maxOrder = await _maxOrder(goals, goals.sortOrder);
    return into(goals).insert(goal.copyWith(sortOrder: Value(maxOrder + 1)));
  }

  // ---------------------------------------------------------------------------
  // Деньги
  // ---------------------------------------------------------------------------

  Stream<List<Category>> watchCategories({bool archived = false}) =>
      (select(categories)
            ..where((t) => t.archived.equals(archived))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
          .watch();

  Stream<List<Transaction>> watchTransactions({required int from, required int to}) =>
      (select(transactions)
            ..where((t) => t.day.isBetweenValues(from, to))
            ..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.at)]))
          .watch();

  Future<List<Transaction>> transactionsBetween(int from, int to) =>
      (select(transactions)..where((t) => t.day.isBetweenValues(from, to))).get();

  Future<int> saveTransaction(TransactionsCompanion tx) async {
    if (tx.id.present) {
      await (update(transactions)..where((t) => t.id.equals(tx.id.value))).write(tx);
      return tx.id.value;
    }
    return into(transactions).insert(tx);
  }

  Future<int> saveCategory(CategoriesCompanion c) async {
    if (c.id.present) {
      await (update(categories)..where((t) => t.id.equals(c.id.value))).write(c);
      return c.id.value;
    }
    final maxOrder = await _maxOrder(categories, categories.sortOrder);
    return into(categories).insert(c.copyWith(sortOrder: Value(maxOrder + 1)));
  }

  Stream<List<Fund>> watchFunds({bool archived = false}) =>
      (select(funds)
            ..where((t) => t.archived.equals(archived))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
          .watch();

  Stream<List<FundMove>> watchFundMoves(int fundId) =>
      (select(fundMoves)
            ..where((t) => t.fundId.equals(fundId))
            ..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.id)]))
          .watch();

  Stream<List<FundMove>> watchAllFundMoves() => select(fundMoves).watch();

  Future<List<FundMove>> fundMovesBetween(int from, int to) => (select(fundMoves)..where((t) => t.day.isBetweenValues(from, to))).get();

  /// Текущее значение копилки (баланс) или долга (остаток).
  Stream<Map<int, double>> watchFundValues() {
    final q = select(funds).join([leftOuterJoin(fundMoves, fundMoves.fundId.equalsExp(funds.id))]);
    return q.watch().map((rows) {
      final fundsById = <int, Fund>{};
      final sums = <int, double>{};
      for (final row in rows) {
        final f = row.readTable(funds);
        fundsById[f.id] = f;
        final m = row.readTableOrNull(fundMoves);
        sums[f.id] = (sums[f.id] ?? 0) + (m?.amount ?? 0);
      }
      return {for (final f in fundsById.values) f.id: fundValue(f, sums[f.id] ?? 0)};
    });
  }

  Future<int> saveFund(FundsCompanion f) async {
    if (f.id.present) {
      await (update(funds)..where((t) => t.id.equals(f.id.value))).write(f);
      return f.id.value;
    }
    final maxOrder = await _maxOrder(funds, funds.sortOrder);
    return into(funds).insert(f.copyWith(sortOrder: Value(maxOrder + 1)));
  }

  Future<int> addFundMove(int fundId, double amount, {int? day, String? note}) =>
      into(fundMoves).insert(FundMovesCompanion.insert(fundId: fundId, amount: amount, day: day ?? todayKey(), note: Value(note)));

  // ---------------------------------------------------------------------------
  // Тренировки
  // ---------------------------------------------------------------------------

  Stream<List<Program>> watchPrograms({bool archived = false}) =>
      (select(programs)
            ..where((t) => t.archived.equals(archived))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
          .watch();

  Stream<List<ProgramExercise>> watchExercises(int programId) =>
      (select(programExercises)
            ..where((t) => t.programId.equals(programId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
          .watch();

  Future<List<ProgramExercise>> exercisesOf(int programId) =>
      (select(programExercises)
            ..where((t) => t.programId.equals(programId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
          .get();

  Stream<List<WorkoutSession>> watchSessions({int? from, int? to}) {
    final q = select(workoutSessions)..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.at)]);
    if (from != null && to != null) q.where((t) => t.day.isBetweenValues(from, to));
    return q.watch();
  }

  Future<List<WorkoutSession>> sessionsBetween(int from, int to) =>
      (select(workoutSessions)..where((t) => t.day.isBetweenValues(from, to))).get();

  Future<List<SessionSet>> setsOf(int sessionId) =>
      (select(sessionSets)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm(expression: t.id)]))
          .get();

  /// Подходы из последней тренировки по этой программе: exerciseId -> повторы.
  Future<Map<int, List<SessionSet>>> lastSetsForProgram(int programId) async {
    final last =
        await (select(workoutSessions)
              ..where((t) => t.programId.equals(programId))
              ..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.at)])
              ..limit(1))
            .getSingleOrNull();
    if (last == null) return {};
    final sets = await setsOf(last.id);
    final result = <int, List<SessionSet>>{};
    for (final s in sets) {
      if (s.exerciseId == null) continue;
      result.putIfAbsent(s.exerciseId!, () => []).add(s);
    }
    for (final list in result.values) {
      list.sort((a, b) => a.setIndex.compareTo(b.setIndex));
    }
    return result;
  }

  Future<int> saveProgram(ProgramsCompanion p) async {
    if (p.id.present) {
      await (update(programs)..where((t) => t.id.equals(p.id.value))).write(p);
      return p.id.value;
    }
    final maxOrder = await _maxOrder(programs, programs.sortOrder);
    return into(programs).insert(p.copyWith(sortOrder: Value(maxOrder + 1)));
  }

  Future<int> saveExercise(ProgramExercisesCompanion e) async {
    if (e.id.present) {
      await (update(programExercises)..where((t) => t.id.equals(e.id.value))).write(e);
      return e.id.value;
    }
    final maxOrder = await _maxOrder(programExercises, programExercises.sortOrder);
    return into(programExercises).insert(e.copyWith(sortOrder: Value(maxOrder + 1)));
  }

  /// Сохранить проведённую тренировку целиком.
  /// [minimum]: сделано меньше плана.
  Future<int> saveSession({
    required Program program,
    required int day,
    required List<SessionSetsCompanion> sets,
    String? note,
    bool minimum = false,
  }) {
    return transaction(() async {
      final id = await into(workoutSessions).insert(
        WorkoutSessionsCompanion.insert(
          programId: Value(program.id),
          programName: program.name,
          day: day,
          note: Value(note),
          minimum: Value(minimum),
        ),
      );
      for (final s in sets) {
        await into(sessionSets).insert(s.copyWith(sessionId: Value(id)));
      }
      return id;
    });
  }

  // ---------------------------------------------------------------------------
  // Записи
  // ---------------------------------------------------------------------------

  Stream<List<JournalEntry>> watchJournal({JournalKind? kind}) {
    final q = select(journalEntries)..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.at)]);
    if (kind != null) q.where((t) => t.kind.equalsValue(kind));
    return q.watch();
  }

  Stream<JournalEntry?> watchJournalFor(JournalKind kind, int day) =>
      (select(journalEntries)
            ..where((t) => t.kind.equalsValue(kind) & t.day.equals(day))
            ..limit(1))
          .watchSingleOrNull();

  Future<List<JournalEntry>> journalBetween(int from, int to) =>
      (select(journalEntries)..where((t) => t.day.isBetweenValues(from, to))).get();

  Future<int> saveJournal(JournalEntriesCompanion e) async {
    if (e.id.present) {
      await (update(journalEntries)..where((t) => t.id.equals(e.id.value))).write(e);
      return e.id.value;
    }
    return into(journalEntries).insert(e);
  }

  // ---------------------------------------------------------------------------
  // Напоминания
  // ---------------------------------------------------------------------------

  Stream<List<Reminder>> watchReminders() => (select(reminders)..orderBy([(t) => OrderingTerm(expression: t.minutes)])).watch();

  Future<int> saveReminder(RemindersCompanion r) async {
    if (r.id.present) {
      await (update(reminders)..where((t) => t.id.equals(r.id.value))).write(r);
      return r.id.value;
    }
    return into(reminders).insert(r);
  }

  // ---------------------------------------------------------------------------
  // Общее
  // ---------------------------------------------------------------------------

  /// Удалить строку по id. Связанные записи удаляются или отвязываются по правилам таблиц.
  Future<void> deleteById(TableInfo table, int id) => customUpdate(
    'DELETE FROM "${table.actualTableName}" WHERE id = ?',
    variables: [Variable<int>(id)],
    updates: {table},
    updateKind: UpdateKind.delete,
  );

  /// Убрать в архив или вернуть из архива.
  Future<void> setArchived(TableInfo table, int id, bool archived) => customUpdate(
    'UPDATE "${table.actualTableName}" SET archived = ? WHERE id = ?',
    variables: [Variable<bool>(archived), Variable<int>(id)],
    updates: {table},
    updateKind: UpdateKind.update,
  );

  Future<int> _maxOrder(TableInfo table, GeneratedColumn<int> column) async {
    final maxExp = column.max();
    final row = await (selectOnly(table)..addColumns([maxExp])).getSingle();
    return row.read(maxExp) ?? 0;
  }
}

/// Значение копилки или остаток долга с учётом всех движений.
double fundValue(Fund f, double movesSum) {
  switch (f.kind) {
    case FundKind.savings:
      return f.initialAmount + movesSum;
    case FundKind.debt:
      final left = f.initialAmount - movesSum;
      return left < 0 ? 0 : left;
  }
}

extension MoreQueries on AppDatabase {
  Stream<Map<String, String>> watchAllSettings() => select(settings).watch().map((rows) => {for (final r in rows) r.key: r.value});

  Stream<List<HabitLog>> watchAllHabitLogs() => select(habitLogs).watch();

  Stream<List<TrackerEntry>> watchAllEntries() => select(trackerEntries).watch();
}

/// Сон и питание.
extension HealthQueries on AppDatabase {
  // ----- Сон -----

  Stream<List<SleepLog>> watchSleep({int? from}) {
    final q = select(sleepLogs)..orderBy([(t) => OrderingTerm.desc(t.day), (t) => OrderingTerm.desc(t.wakeAt)]);
    if (from != null) q.where((t) => t.day.isBiggerOrEqualValue(from));
    return q.watch();
  }

  Future<List<SleepLog>> sleepBetween(int from, int to) => (select(sleepLogs)..where((t) => t.day.isBetweenValues(from, to))).get();

  /// Сохранить ночь. На один день пробуждения одна запись: новая заменяет старую.
  Future<int> saveSleep(SleepLogsCompanion log) {
    return transaction(() async {
      if (log.id.present) {
        await (update(sleepLogs)..where((t) => t.id.equals(log.id.value))).write(log);
        return log.id.value;
      }
      await (delete(sleepLogs)..where((t) => t.day.equals(log.day.value))).go();
      return into(sleepLogs).insert(log);
    });
  }

  // ----- Питание -----

  Stream<List<Food>> watchFoods({bool archived = false}) =>
      (select(foods)
            ..where((t) => t.archived.equals(archived))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
          .watch();

  Future<int> saveFood(FoodsCompanion f) async {
    if (f.id.present) {
      await (update(foods)..where((t) => t.id.equals(f.id.value))).write(f);
      return f.id.value;
    }
    final order = await customSelect('SELECT COALESCE(MAX(sort_order), 0) + 1 AS n FROM foods', readsFrom: {foods}).getSingle();
    return into(foods).insert(f.copyWith(sortOrder: Value(order.read<int>('n'))));
  }

  Stream<List<Meal>> watchMeals({required int from, required int to}) =>
      (select(meals)
            ..where((t) => t.day.isBetweenValues(from, to))
            ..orderBy([(t) => OrderingTerm(expression: t.at)]))
          .watch();

  Future<List<Meal>> mealsBetween(int from, int to) => (select(meals)..where((t) => t.day.isBetweenValues(from, to))).get();

  /// Записать блюдо как съеденное. [portions] — сколько порций (1,5 порции, полпорции).
  /// Если у блюда задан вес порции, вес записи считается из него.
  Future<int> eatFood(Food f, {int? day, int? slot, double portions = 1}) => into(meals).insert(
    MealsCompanion.insert(
      day: day ?? todayKey(),
      name: f.name,
      icon: Value(f.icon),
      kcal: f.kcal * portions,
      protein: Value(f.protein * portions),
      fat: Value(f.fat * portions),
      carbs: Value(f.carbs * portions),
      slot: Value(slot),
      grams: Value(f.grams == null ? null : f.grams! * portions),
      foodId: Value(f.id),
    ),
  );

  /// Повторить еду другого дня: весь день или один приём пищи. Возвращает, сколько записей добавлено.
  Future<int> copyMeals({required int from, required int to, bool Function(Meal m)? where}) async {
    final src =
        await (select(meals)
              ..where((t) => t.day.equals(from))
              ..orderBy([(t) => OrderingTerm(expression: t.at)]))
            .get();
    final now = DateTime.now();
    var n = 0;
    await transaction(() async {
      for (final m in src) {
        if (where != null && !where(m)) continue;
        await into(meals)
            .insert(m.toCompanion(false).copyWith(id: const Value.absent(), day: Value(to), at: Value(to == todayKey() ? now : m.at)));
        n++;
      }
    });
    return n;
  }

  Future<int> saveMeal(MealsCompanion m) async {
    if (m.id.present) {
      await (update(meals)..where((t) => t.id.equals(m.id.value))).write(m);
      return m.id.value;
    }
    return into(meals).insert(m);
  }

  Stream<List<WaterLog>> watchWater({required int from, required int to}) =>
      (select(waterLogs)..where((t) => t.day.isBetweenValues(from, to))).watch();

  Future<List<WaterLog>> waterBetween(int from, int to) => (select(waterLogs)..where((t) => t.day.isBetweenValues(from, to))).get();

  Future<int> addWater(int ml, {int? day}) => into(waterLogs).insert(WaterLogsCompanion.insert(day: day ?? todayKey(), ml: ml));

  /// Убрать последний записанный стакан за день.
  Future<void> undoWater(int day) async {
    final last =
        await (select(waterLogs)
              ..where((t) => t.day.equals(day))
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();
    if (last != null) await (delete(waterLogs)..where((t) => t.id.equals(last.id))).go();
  }
}

/// План дня и бюджет.
extension PlanQueries on AppDatabase {
  Stream<List<TimeBlock>> watchTimeBlocks() => (select(timeBlocks)..orderBy([(t) => OrderingTerm(expression: t.start)])).watch();

  Future<int> saveTimeBlock(TimeBlocksCompanion b) async {
    if (b.id.present) {
      await (update(timeBlocks)..where((t) => t.id.equals(b.id.value))).write(b);
      return b.id.value;
    }
    return into(timeBlocks).insert(b);
  }

  Stream<List<BudgetLine>> watchBudget(int month) => (select(budgetLines)..where((t) => t.month.equals(month))).watch();

  Future<List<BudgetLine>> budgetOf(int month) => (select(budgetLines)..where((t) => t.month.equals(month))).get();

  /// Последний месяц до [month], для которого составлен бюджет.
  Future<int?> previousBudgetMonth(int month) async {
    final row =
        await (select(budgetLines)
              ..where((t) => t.month.isSmallerThanValue(month))
              ..orderBy([(t) => OrderingTerm.desc(t.month)])
              ..limit(1))
            .getSingleOrNull();
    return row?.month;
  }

  /// Заменить бюджет месяца целиком. Строки с нулём не сохраняются.
  Future<void> saveBudget(int month, List<({int? categoryId, int? fundId, double amount})> lines) => transaction(() async {
    await (delete(budgetLines)..where((t) => t.month.equals(month))).go();
    for (final l in lines) {
      if (l.amount <= 0) continue;
      await into(budgetLines)
          .insert(BudgetLinesCompanion.insert(month: month, categoryId: Value(l.categoryId), fundId: Value(l.fundId), amount: l.amount));
    }
  });

  Stream<List<FundMove>> watchFundMovesBetween(int from, int to) =>
      (select(fundMoves)..where((t) => t.day.isBetweenValues(from, to))).watch();
}
