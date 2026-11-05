import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// A foreign key from one synced table to another.
class SyncForeignKey {
  const SyncForeignKey({
    required this.column,
    required this.parentTable,
    required this.nullable,
  });

  final String column;
  final String parentTable;

  /// A nullable reference is cleared when its parent goes; a required one
  /// goes with it.
  final bool nullable;
}

/// A uniqueness rule of a synced table other than its primary key: a UNIQUE
/// constraint or a unique index, which may be partial.
class SyncUniqueKey {
  const SyncUniqueKey({required this.columns, this.where});

  final List<String> columns;

  /// The partial index's condition as the schema states it; null when the
  /// rule covers every row.
  final String? where;
}

/// How the synced tables hang together and what they keep unique, read
/// from the database itself rather than restated here, so the merge follows
/// the schema an upgraded file actually has.
///
/// References to `users` are authorship: a user is matched by name across
/// devices and never removed by a merge, so they are left out of [parentsOf]
/// and [childrenOf].
///
/// A table outside the merge whose rows refer to a merged one is read too,
/// so that [childrenOf] lists it: a deletion or merge of the record its rows
/// need reaches them like any other, or the import would end on the foreign
/// key check. Its rows are only ever removed, detached or moved, never
/// merged. A database upgraded from an older app can still hold such rows
/// (`cave_entrances` naming a cave).
class SyncSchema {
  SyncSchema._(this._db, this._tables);

  final AppDatabase _db;
  final Map<String, _TableShape> _tables;

  static const _authorTable = 'users';

  static Future<SyncSchema> read(
    AppDatabase db,
    Iterable<String> tables,
  ) async {
    final merged = tables.toSet();
    final shapes = <String, _TableShape>{};
    for (final table in [...merged, ...await _referring(db, merged)]) {
      final columns = <String, bool>{
        for (final row
            in await db.customSelect('PRAGMA table_info($table)').get())
          row.read<String>('name'): row.read<int>('notnull') == 0,
      };
      final parents = <SyncForeignKey>[
        for (final row
            in await db.customSelect('PRAGMA foreign_key_list($table)').get())
          if (row.read<String>('table') != _authorTable)
            SyncForeignKey(
              column: row.read<String>('from'),
              parentTable: row.read<String>('table'),
              nullable: columns[row.read<String>('from')] ?? true,
            ),
      ];
      final keys = <SyncUniqueKey>[];
      for (final index
          in await db.customSelect('PRAGMA index_list($table)').get()) {
        if (index.read<int>('unique') != 1) continue;
        if (index.read<String>('origin') == 'pk') continue;
        final name = index.read<String>('name');
        final cols = <String>[
          for (final c
              in await db.customSelect("PRAGMA index_info('$name')").get())
            c.read<String>('name'),
        ];
        String? where;
        if (index.read<int>('partial') == 1) {
          final sql = await db
              .customSelect(
                "SELECT sql FROM sqlite_master WHERE type = 'index' "
                'AND name = ?',
                variables: [Variable<String>(name)],
              )
              .getSingleOrNull();
          where = _partialCondition(sql?.read<String?>('sql'));
        }
        keys.add(SyncUniqueKey(columns: cols, where: where));
      }
      shapes[table] = _TableShape(columns, parents, keys);
    }
    return SyncSchema._(db, shapes);
  }

  /// The tables outside [merged], keyed by uuid, with a foreign key into
  /// one of them other than authorship.
  static Future<List<String>> _referring(
    AppDatabase db,
    Set<String> merged,
  ) async => <String>[
    for (final info in db.allTables)
      if (!merged.contains(info.actualTableName) &&
          info.columnsByName.containsKey('uuid') &&
          (await db
                  .customSelect(
                    'PRAGMA foreign_key_list(${info.actualTableName})',
                  )
                  .get())
              .map((row) => row.read<String>('table'))
              .any(
                (parent) => parent != _authorTable && merged.contains(parent),
              ))
        info.actualTableName,
  ];

  static String? _partialCondition(String? sql) {
    if (sql == null) return null;
    final at = sql.toUpperCase().lastIndexOf(' WHERE ');
    return at < 0 ? null : sql.substring(at + 7).trim();
  }

  bool has(String table) => _tables.containsKey(table);

  Set<String> columnsOf(String table) => _tables[table]!.columns.keys.toSet();

  List<SyncForeignKey> parentsOf(String table) => _tables[table]!.parents;

  /// Every reference into [table], as (child table, foreign key).
  List<(String, SyncForeignKey)> childrenOf(String table) => [
    for (final entry in _tables.entries)
      for (final fk in entry.value.parents)
        if (fk.parentTable == table) (entry.key, fk),
  ];

  /// The SQL giving a row's own last-change time. Link tables carry no
  /// `updated_at`, and never change once written.
  String stampOf(String table) =>
      _tables[table]!.columns.containsKey('updated_at')
      ? 'COALESCE(updated_at, created_at, 0)'
      : 'COALESCE(created_at, 0)';

  /// The uuid of a local row, other than [own] and [ignore], that holds the
  /// unique key [values] would claim, with the uniqueness rule it collides
  /// on; null when the row could be written. [values] maps column names to
  /// SQL values.
  Future<(Uuid, SyncUniqueKey)?> findCollision(
    String table,
    Map<String, Object?> values,
    Uuid own, {
    Set<Uuid> ignore = const <Uuid>{},
  }) async {
    final others = <Uuid>[own, ...ignore];
    for (final key in _tables[table]!.keys) {
      // NULLs never collide in a unique rule.
      if (key.columns.any((c) => values[c] == null)) continue;
      final where = key.where;
      if (where != null && !await _matches(table, where, values)) continue;
      final row = await _db
          .customSelect(
            'SELECT uuid FROM $table WHERE '
            '${key.columns.map((c) => '$c = ?').join(' AND ')} '
            'AND uuid NOT IN (${List.filled(others.length, '?').join(', ')})'
            '${where == null ? '' : ' AND ($where)'} LIMIT 1',
            variables: [
              for (final c in key.columns) variable(values[c]),
              for (final o in others) Variable<Uint8List>(o.bytes),
            ],
          )
          .getSingleOrNull();
      if (row != null) {
        return (Uuid.fromBytes(row.read<Uint8List>('uuid')), key);
      }
    }
    return null;
  }

  /// Whether the row [values] falls under a partial index's condition,
  /// evaluated by SQLite itself on the row's own values.
  Future<bool> _matches(
    String table,
    String where,
    Map<String, Object?> values,
  ) async {
    final names = columnsOf(table).toList();
    final row = await _db
        .customSelect(
          'WITH $table(${names.join(', ')}) AS '
          '(VALUES (${List.filled(names.length, '?').join(', ')})) '
          'SELECT 1 FROM $table WHERE $where',
          variables: [for (final n in names) variable(values[n])],
        )
        .getSingleOrNull();
    return row != null;
  }

  /// [value] bound as SQLite stores it.
  static Variable<Object> variable(Object? value) => switch (value) {
    null => const Variable<Object>(null),
    final Uint8List v => Variable<Uint8List>(v),
    final int v => Variable<int>(v),
    final double v => Variable<double>(v),
    final bool v => Variable<int>(v ? 1 : 0),
    final String v => Variable<String>(v),
    final Object v => Variable<String>(v.toString()),
  };
}

class _TableShape {
  _TableShape(this.columns, this.parents, this.keys);

  /// Column name to whether it may be NULL.
  final Map<String, bool> columns;
  final List<SyncForeignKey> parents;
  final List<SyncUniqueKey> keys;
}
