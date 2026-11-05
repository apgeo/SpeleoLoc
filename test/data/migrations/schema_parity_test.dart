import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// A database brought up through the migration ladder must end with the same
/// schema a fresh install gets from `createAll()`: the same columns with the
/// same types, nullability and defaults, the same indexes and the same
/// foreign keys. Code is written and tested against the fresh shape, so any
/// drift shows up on upgraded devices only.
///
/// The starting points are the shipped fixtures at user_version 5 (the pre-v7
/// re-keying path), 7 (the oldest uuid-keyed schema) and 9. Only their
/// schema is compared; no row is read.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('schema_parity_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<void> openThroughApp(File f) async {
    final db = AppDatabase.forTesting(NativeDatabase(f));
    try {
      await db.customSelect('SELECT 1').get();
    } finally {
      await db.close();
    }
  }

  Future<Map<String, Set<String>>> freshSchema() async {
    final f = File(p.join(tmp.path, 'fresh.sqlite'));
    await openThroughApp(f);
    return _describe(f);
  }

  const fixtures = <int, String>{
    5: 'test_data/db/binaries/speleo_loc_export_20260414.sqlite',
    7: 'test_data/db/binaries/speleo_loc_export_20260423.sqlite',
    9: 'test_data/db/binaries/speleo_loc_export_20260425.sqlite',
  };

  for (final MapEntry(key: version, value: path) in fixtures.entries) {
    test('a v$version database upgrades to the fresh schema', () async {
      final source = File(path);
      expect(source.existsSync(), isTrue, reason: 'fixture missing: $path');
      final copy = File(p.join(tmp.path, 'v$version.sqlite'));
      await source.copy(copy.path);
      expect(_userVersion(copy), version);

      await openThroughApp(copy);

      final upgraded = _describe(copy);
      final fresh = await freshSchema();
      // The describer must see the constraints it compares, or an empty
      // difference proves nothing.
      expect(
        fresh['raster_maps'],
        containsAll(<Matcher>[
          startsWith('check (map_type in'),
          startsWith('unique (title, map_type, cave_uuid) on conflict'),
          startsWith('fk cave_uuid -> caves(uuid)'),
          startsWith('index UNIQUE (u)'),
        ]),
      );

      final differences = <String>[
        for (final table in {...fresh.keys, ...upgraded.keys}) ...[
          for (final d in (fresh[table] ?? const <String>{}).difference(
            upgraded[table] ?? const <String>{},
          ))
            'only on a fresh install: $table: $d',
          for (final d in (upgraded[table] ?? const <String>{}).difference(
            fresh[table] ?? const <String>{},
          ))
            'only after the upgrade: $table: $d',
        ],
      ]..sort();
      expect(differences, isEmpty);
    });
  }
}

int _userVersion(File f) {
  final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
  try {
    return d.userVersion;
  } finally {
    d.close();
  }
}

/// Describes the schema of [f], per table, as a set of comparable lines.
/// Column order is left out on purpose: `ALTER TABLE ADD COLUMN` appends, and
/// nothing reads columns by position.
Map<String, Set<String>> _describe(File f) {
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
