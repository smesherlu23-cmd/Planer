/// Перенос данных одним файлом.
///
/// Файл это обычный JSON со всеми таблицами базы. Его можно отправить
/// в чат, сохранить на компьютер и загрузить обратно на другом телефоне.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';
import 'dates.dart';

const exportFormat = 1;
const exportAppId = 'planer';

class ImportException implements Exception {
  ImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ImportSummary {
  ImportSummary(this.rowsByTable);
  final Map<String, int> rowsByTable;
  int get total => rowsByTable.values.fold(0, (a, b) => a + b);
}

/// Все данные базы в виде JSON-строки.
Future<String> exportJson(AppDatabase db, {DateTime? now}) async {
  final tables = <String, List<Map<String, Object?>>>{};
  for (final table in db.allTables) {
    final rows = await db.customSelect('SELECT * FROM "${table.actualTableName}"', readsFrom: {table}).get();
    tables[table.actualTableName] = [for (final r in rows) r.data];
  }
  final data = {
    'app': exportAppId,
    'format': exportFormat,
    'schema': db.schemaVersion,
    'exportedAt': (now ?? DateTime.now()).toIso8601String(),
    'tables': tables,
  };
  return const JsonEncoder.withIndent(' ').convert(data);
}

String exportFileName([DateTime? now]) {
  final key = todayKey(now);
  final d = dayFromKey(key);
  String two(int v) => v.toString().padLeft(2, '0');
  return 'planer-${d.year}-${two(d.month)}-${two(d.day)}.json';
}

/// Проверить файл, не трогая базу. Возвращает, сколько строк в каждой таблице.
ImportSummary inspectImport(AppDatabase db, String json) {
  final tables = _parse(db, json);
  return ImportSummary({for (final e in tables.entries) e.key: e.value.length});
}

/// Заменить все данные содержимым файла. Всё или ничего: при ошибке база не меняется.
Future<ImportSummary> importJson(AppDatabase db, String json) async {
  final tables = _parse(db, json);
  final counts = <String, int>{};
  await db.transaction(() async {
    // Сначала удаляем дочерние таблицы, потом родительские.
    for (final table in db.allTables.toList().reversed) {
      await db.customUpdate('DELETE FROM "${table.actualTableName}"', updates: {table}, updateKind: UpdateKind.delete);
    }
    // Вставляем в обратном порядке: родители раньше детей.
    for (final table in db.allTables) {
      final rows = tables[table.actualTableName] ?? const [];
      final known = {for (final c in table.$columns) c.name};
      var n = 0;
      for (final row in rows) {
        final cols = [
          for (final k in row.keys)
            if (known.contains(k)) k,
        ];
        if (cols.isEmpty) continue;
        final names = cols.map((c) => '"$c"').join(', ');
        final marks = List.filled(cols.length, '?').join(', ');
        await db.customInsert(
          'INSERT INTO "${table.actualTableName}" ($names) VALUES ($marks)',
          variables: [for (final c in cols) _variable(row[c])],
          updates: {table},
        );
        n++;
      }
      counts[table.actualTableName] = n;
    }
    // Файл из старой версии мог хранить эмодзи вместо иконок.
    await db.convertEmojiIcons();
  });
  return ImportSummary(counts);
}

Variable _variable(Object? v) {
  if (v == null) return const Variable<Object>(null);
  if (v is bool) return Variable<int>(v ? 1 : 0);
  if (v is int) return Variable<int>(v);
  if (v is double) return Variable<double>(v);
  if (v is String) return Variable<String>(v);
  throw ImportException('Непонятное значение в файле: $v');
}

Map<String, List<Map<String, Object?>>> _parse(AppDatabase db, String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    throw ImportException('Это не файл Planer: не получилось прочитать JSON.');
  }
  if (decoded is! Map || decoded['app'] != exportAppId) {
    throw ImportException('Это не файл Planer.');
  }
  final format = decoded['format'];
  if (format is! int || format > exportFormat) {
    throw ImportException('Файл сделан более новой версией приложения. Обнови Planer и попробуй снова.');
  }
  final schema = decoded['schema'];
  if (schema is int && schema > db.schemaVersion) {
    throw ImportException('Файл сделан более новой версией приложения. Обнови Planer и попробуй снова.');
  }
  final tables = decoded['tables'];
  if (tables is! Map) throw ImportException('В файле нет данных.');
  final result = <String, List<Map<String, Object?>>>{};
  for (final entry in tables.entries) {
    final rows = entry.value;
    if (entry.key is! String || rows is! List) throw ImportException('Файл повреждён.');
    result[entry.key as String] = [
      for (final r in rows)
        if (r is Map) {for (final e in r.entries) e.key.toString(): e.value} else throw ImportException('Файл повреждён.'),
    ];
  }
  return result;
}
