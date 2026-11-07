import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Describes the schema of [f], per table, as a set of comparable lines:
/// columns with their type, nullability, default and key position, indexes
/// with their columns and partial clause, foreign keys, CHECK constraints and
/// UNIQUE conflict clauses.
///
/// Column order is left out on purpose: `ALTER TABLE ADD COLUMN` appends, and
/// nothing reads columns by position.
Map<String, Set<String>> describeSchema(File f) {
  final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
  try {
    final tables = d
        .select(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .map((r) => r['name'] as String);
    return {
      for (final t in tables)
        t: {
          ..._columns(d, t),
          ..._indexes(d, t),
          ..._fks(d, t),
          ..._clauses(d, t),
        },
    };
  } finally {
    d.close();
  }
}

/// The lines in which [actual] differs from [expected], each saying on which
/// side it appears.
List<String> schemaDifferences(
  Map<String, Set<String>> expected,
  Map<String, Set<String>> actual, {
  String expectedLabel = 'only on a fresh install',
  String actualLabel = 'only after the upgrade',
}) => <String>[
  for (final table in {...expected.keys, ...actual.keys}) ...[
    for (final d in (expected[table] ?? const <String>{}).difference(
      actual[table] ?? const <String>{},
    ))
      '$expectedLabel: $table: $d',
    for (final d in (actual[table] ?? const <String>{}).difference(
      expected[table] ?? const <String>{},
    ))
      '$actualLabel: $table: $d',
  ],
]..sort();

Iterable<String> _columns(Database d, String table) => d
    .select('PRAGMA table_info("$table")')
    .map(
      (c) =>
          'column ${c['name']} ${(c['type'] as String).toUpperCase()}'
          '${c['notnull'] == 1 ? ' NOT NULL' : ''}'
          '${c['dflt_value'] == null ? '' : ' DEFAULT ${c['dflt_value']}'}'
          '${c['pk'] == 0 ? '' : ' PK${c['pk']}'}',
    );

Iterable<String> _indexes(Database d, String table) sync* {
  for (final i in d.select('PRAGMA index_list("$table")')) {
    final name = i['name'] as String;
    final cols = d
        .select('PRAGMA index_info("$name")')
        .map((c) => c['name'])
        .join(', ');
    // Automatic indexes are named by position, which differs between a
    // created and a recreated table; their origin and columns identify them.
    final label = name.startsWith('sqlite_autoindex_') ? '' : '$name ';
    final where = i['partial'] == 1 ? ' WHERE ${_partialClause(d, name)}' : '';
    yield 'index $label${i['unique'] == 1 ? 'UNIQUE ' : ''}'
        '(${i['origin']}) ($cols)$where';
  }
}

String _partialClause(Database d, String index) {
  final sql =
      d.select("SELECT sql FROM sqlite_master WHERE name = ?", [
            index,
          ]).first['sql']
          as String;
  final at = sql.toUpperCase().lastIndexOf(' WHERE ');
  return sql.substring(at + 7).replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// The CHECK constraints and UNIQUE conflict clauses of [table], which no
/// pragma reports; read from its CREATE statement.
Iterable<String> _clauses(Database d, String table) sync* {
  final sql =
      (d.select(
                "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
                [table],
              ).first['sql']
              as String)
          .replaceAll(RegExp(r'["`\[\]]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .toLowerCase();
  for (final m in RegExp(r'check ?\(').allMatches(sql)) {
    var depth = 1;
    var i = m.end;
    while (depth > 0 && i < sql.length) {
      if (sql[i] == '(') depth++;
      if (sql[i] == ')') depth--;
      i++;
    }
    yield 'check (${sql.substring(m.end, i - 1).trim()})';
  }
  for (final m in RegExp(
    r'unique ?\(([^)]*)\) ?on conflict (\w+)',
  ).allMatches(sql)) {
    final cols = m.group(1)!.split(',').map((c) => c.trim()).join(', ');
    yield 'unique ($cols) on conflict ${m.group(2)}';
  }
}

Iterable<String> _fks(Database d, String table) => d
    .select('PRAGMA foreign_key_list("$table")')
    .map(
      (k) =>
          'fk ${k['from']} -> ${k['table']}(${k['to']}) '
          'on delete ${k['on_delete']} on update ${k['on_update']}',
    );
