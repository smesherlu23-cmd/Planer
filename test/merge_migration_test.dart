import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/database.dart';

/// Модули делались параллельно, и каждая предварительная сборка поднимала базу до версии 5 только со своими
/// изменениями. Версия 6 должна догнать такую базу целиком.
void main() {
  test('база версии 5 из сборки одного модуля получает таблицы и колонки остальных', () async {
    final dir = await Directory.systemTemp.createTemp('planer_migration6');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final current = AppDatabase(NativeDatabase(file));
    // Как после сборки модуля питания: его колонки есть, а таблиц и колонок других модулей нет.
    for (final t in ['recurrings', 'transfers', 'tasks', 'focus_sessions', 'goal_checkins', 'goal_steps', 'habit_days']) {
      await current.customStatement('DROP TABLE "$t"');
    }
    for (final (table, column) in [
      ('transactions', 'account_id'),
      ('fund_moves', 'account_id'),
      ('habits', 'per_week'),
      ('sleep_logs', 'latency'),
      ('program_exercises', 'rest_sec'),
      ('goals', 'area'),
      ('journal_entries', 'wins'),
    ]) {
      await current.customStatement('ALTER TABLE "$table" DROP COLUMN "$column"');
    }
    await current.customStatement('DROP TABLE "accounts"');
    await current.customStatement('PRAGMA user_version = 5');
    await current.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    Future<Set<String>> columns(String table) async => {
      for (final r in await db.customSelect('PRAGMA table_info("$table")').get()) r.read<String>('name'),
    };
    for (final t in ['accounts', 'recurrings', 'transfers', 'tasks', 'focus_sessions', 'goal_checkins', 'goal_steps', 'habit_days']) {
      expect(await db.customSelect('SELECT * FROM "$t"').get(), isEmpty, reason: t);
    }
    expect(await columns('transactions'), contains('account_id'));
    expect(await columns('habits'), contains('per_week'));
    expect(await columns('sleep_logs'), contains('latency'));
    expect(await columns('program_exercises'), contains('rest_sec'));
    expect(await columns('goals'), contains('area'));
    expect(await columns('journal_entries'), contains('wins'));
    expect(await columns('foods'), contains('grams'));
  });
}
