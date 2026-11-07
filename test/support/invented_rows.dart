import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

/// One invented row per table, every column filled, for tests that check a
/// schema change keeps what was in a row.
///
/// Every value is derived from the table and column name alone, so a foreign
/// key holds exactly the value its parent row has in the referenced column
/// and no insert order is needed. Values are chosen to survive the rewrites
/// every open does: integers look like millisecond timestamps, so the
/// seconds-to-milliseconds normalisation leaves them alone, and `is_` flags
/// are 1. A column restricted to a list by a CHECK gets the first allowed
/// value.
///
/// [onlyColumns], when given, limits the seeding to its tables and, within
/// them, fills only its columns, leaving the others to their default as a
/// later `ADD COLUMN` would have left them. Columns that must be filled are
/// filled anyway. [overrides] replaces chosen values, per table and column.
void seedOneRowPerTable(
  Database d, {
  Map<String, Set<String>>? onlyColumns,
  Map<String, Map<String, Object?>> overrides = const {},
}) {
  final schema = _Schema.of(d);
  for (final table in schema.tables) {
    final allowed = onlyColumns == null ? null : onlyColumns[table];
    if (onlyColumns != null && allowed == null) continue;
    final values = <String, Object?>{};
    for (final c in schema.columns[table]!) {
      final required = c.notNull && c.defaultValue == null;
      if (allowed != null && !allowed.contains(c.name) && !required) continue;
      values[c.name] =
          overrides[table]?[c.name] ?? schema.valueFor(table, c.name);
    }
    final names = values.keys.map((n) => '"$n"').join(', ');
    final marks = List.filled(values.length, '?').join(', ');
    d.execute(
      'INSERT INTO "$table" ($names) VALUES ($marks)',
      values.values.toList(),
    );
  }
}

/// The columns of every table of [d], by table.
Map<String, Set<String>> columnsByTable(Database d) {
  final schema = _Schema.of(d);
  return {
    for (final t in schema.tables)
      t: {for (final c in schema.columns[t]!) c.name},
  };
}

/// Every row of every table of [d], keyed by table and then by primary key,
/// with blobs as hex so rows compare by value.
Map<String, Map<String, Map<String, Object?>>> rowsByKey(Database d) {
  final schema = _Schema.of(d);
  final result = <String, Map<String, Map<String, Object?>>>{};
  for (final table in schema.tables) {
    final key = [
      for (final c in schema.columns[table]!)
        if (c.pk > 0) c,
    ]..sort((a, b) => a.pk.compareTo(b.pk));
    final keyNames = key.isEmpty ? ['rowid'] : key.map((c) => c.name).toList();
    final rows = d.select(
      'SELECT ${key.isEmpty ? 'rowid, ' : ''}* FROM "$table"',
    );
    result[table] = {
      for (final r in rows)
        keyNames.map((k) => _plain(r[k])).join('|'): {
          for (final c in schema.columns[table]!) c.name: _plain(r[c.name]),
        },
    };
  }
  return result;
}

/// The differences between [before] and [after], read with [rowsByKey]:
/// rows that went missing, and values that changed in a column both sides
/// have. Tables only [before] has are reported whole, unless [dropped]
/// names them. Rows only [after] has are allowed in [mayGainRows] only.
List<String> rowDifferences(
  Map<String, Map<String, Map<String, Object?>>> before,
  Map<String, Map<String, Map<String, Object?>>> after, {
  Set<String> mayGainRows = const {},
  Set<String> dropped = const {},
}) {
  final out = <String>[];
  for (final MapEntry(key: table, value: rows) in before.entries) {
    final now = after[table];
    if (now == null) {
      if (!dropped.contains(table) && rows.isNotEmpty) {
        out.add('$table: the table and its ${rows.length} rows are gone');
      }
      continue;
    }
    if (!mayGainRows.contains(table) && now.length != rows.length) {
      out.add('$table: ${rows.length} rows before, ${now.length} after');
    }
    for (final MapEntry(key: key, value: row) in rows.entries) {
      final match = now[key];
      if (match == null) {
        out.add('$table: row $key is gone');
        continue;
      }
      for (final MapEntry(key: column, value: value) in row.entries) {
        if (!match.containsKey(column)) continue;
        if (match[column] != value) {
          out.add('$table.$column: $value became ${match[column]}');
        }
      }
    }
  }
  return out..sort();
}

Object? _plain(Object? v) => v is Uint8List ? _hex(v) : v;

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

class _Column {
  _Column(this.name, this.type, this.notNull, this.defaultValue, this.pk);

  final String name;
  final String type;
  final bool notNull;
  final Object? defaultValue;
  final int pk;
}

class _Schema {
  _Schema._(this.tables, this.columns, this._references, this._allowed);

  factory _Schema.of(Database d) {
    final tables = [
      for (final r in d.select(
        "SELECT name, sql FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      ))
        (r['name'] as String, r['sql'] as String),
    ];
    final columns = <String, List<_Column>>{};
    final references = <String, (String, String?)>{};
    final allowed = <String, Object?>{};
    for (final (table, sql) in tables) {
      columns[table] = [
        for (final c in d.select('PRAGMA table_info("$table")'))
          _Column(
            c['name'] as String,
            (c['type'] as String).toUpperCase(),
            c['notnull'] == 1,
            c['dflt_value'],
            c['pk'] as int,
          ),
      ];
      for (final k in d.select('PRAGMA foreign_key_list("$table")')) {
        references['$table.${k['from']}'] = (
          k['table'] as String,
          k['to'] as String?,
        );
      }
      for (final m in RegExp(
        r'CHECK\s*\(\s*"?(\w+)"?\s+IN\s*\(([^)]*)\)',
        caseSensitive: false,
      ).allMatches(sql)) {
        final first = m.group(2)!.split(',').first.trim();
        allowed['$table.${m.group(1)}'] = first.startsWith("'")
            ? first.substring(1, first.length - 1)
            : int.parse(first);
      }
    }
    return _Schema._(
      [for (final (t, _) in tables) t],
      columns,
      references,
      allowed,
    );
  }

  final List<String> tables;
  final Map<String, List<_Column>> columns;
  final Map<String, (String, String?)> _references;
  final Map<String, Object?> _allowed;

  Object? valueFor(String table, String column) {
    final reference = _references['$table.$column'];
    if (reference != null) {
      final (parent, to) = reference;
      final parentColumn =
          to ??
          columns[parent]!
              .firstWhere(
                (c) => c.pk == 1,
                orElse: () {
                  throw StateError(
                    '$parent has no primary key for $table.$column',
                  );
                },
              )
              .name;
      return valueFor(parent, parentColumn);
    }
    final key = '$table.$column';
    if (_allowed.containsKey(key)) return _allowed[key];
    final type = columns[table]!.firstWhere((c) => c.name == column).type;
    final seed = key.codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0xFFFFF);
    if (type.contains('INT')) {
      return column.startsWith('is_') ? 1 : 1700000000000 + seed;
    }
    if (type.contains('CHAR') ||
        type.contains('TEXT') ||
        type.contains('CLOB')) {
      return 'invented $key';
    }
    if (type.contains('REAL') ||
        type.contains('FLOA') ||
        type.contains('DOUB') ||
        type.contains('NUM')) {
      return 12.5 + seed % 100;
    }
    return Uint8List.fromList(
      List<int>.generate(16, (i) => (seed >> (i % 3) * 7) + i & 0xFF),
    );
  }
}
