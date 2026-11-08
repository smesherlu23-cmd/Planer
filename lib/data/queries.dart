import 'package:drift/drift.dart';

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

  /// Записать значение трекера. Привычки, привязанные к трекеру, отмечаются сами.
  Future<int> addEntry(int trackerId, double value, {int? day, String? note}) {
    final d = day ?? todayKey();
    return transaction(() async {
      final id = await into(trackerEntries)
          .insert(TrackerEntriesCompanion.insert(trackerId: trackerId, day: d, value: value, note: Value(note)));
      final tracker = await (select(trackers)..where((t) => t.id.equals(trackerId))).getSingleOrNull();
      // У трекера «да или нет» значение 0 значит «не сделал».
      final counts = tracker != null && (tracker.kind != TrackerKind.yesNo || value > 0);
      if (counts) {
        final linked = await (select(habits)..where((t) => t.trackerId.equals(trackerId))).get();
        for (final h in linked) {
          await into(habitLogs).insert(
            HabitLogsCompanion.insert(habitId: h.id, day: d),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
      return id;
    });
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
  Future<int> saveSession({required Program program, required int day, required List<SessionSetsCompanion> sets, String? note}) {
    return transaction(() async {
      final id = await into(workoutSessions)
          .insert(WorkoutSessionsCompanion.insert(programId: Value(program.id), programName: program.name, day: day, note: Value(note)));
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
