import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// Before v8 nothing constrained `raster_maps.map_type`, and the upgrade
/// copies old maps into a table whose CHECK accepts four types. A map with
/// any other type must not stop the database from opening; it becomes
/// `other`. Every database is made here; the values are invented.
void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('raster_map_type_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<void> open(File f) async {
    final db = AppDatabase.forTesting(NativeDatabase(f));
    try {
      await db.customSelect('SELECT 1').get();
    } finally {
      await db.close();
    }
  }

  test('a v7 map with an unknown type opens as other', () async {
    final f = File(p.join(tmp.path, 'v7.sqlite'));
    await open(f);
    final cave = Uuid.v7();
    _raw(f, (d) {
      // The current schema without the v7 to v8 column, stamped 7.
      d.execute(
        'ALTER TABLE documentation_files_to_geofeatures DROP COLUMN created_at',
      );
      d.execute('INSERT INTO caves (uuid, title) VALUES (?, ?)', [
        cave.bytes,
        'Invented Cave',
      ]);
      d.execute('PRAGMA ignore_check_constraints = ON');
      d.execute(
        'INSERT INTO raster_maps (uuid, title, map_type, file_name, '
        'cave_uuid) VALUES (?, ?, ?, ?, ?)',
        [Uuid.v7().bytes, 'Invented Map', 'plan', 'm.png', cave.bytes],
      );
      d.execute('PRAGMA user_version = 7');
    });

    await open(f);

    expect(_mapTypes(f), ['other']);
  });

  test('a pre-v7 map with an unknown type opens as other', () async {
    final f = File(p.join(tmp.path, 'v5.sqlite'));
    _raw(f, (d) {
      // Just the integer-keyed tables the maps need; the snapshot reads a
      // missing table as empty.
      d.execute(
        'CREATE TABLE caves (id INTEGER PRIMARY KEY, title TEXT NOT NULL, '
        'description TEXT, surface_area_id INTEGER, created_at INTEGER, '
        'updated_at INTEGER, deleted_at INTEGER)',
      );
      d.execute(
        'CREATE TABLE raster_maps (id INTEGER PRIMARY KEY, title TEXT NOT '
        'NULL, map_type TEXT NOT NULL, file_name TEXT NOT NULL, cave_id '
        'INTEGER NOT NULL, cave_area_id INTEGER, created_at INTEGER, '
        'updated_at INTEGER, deleted_at INTEGER)',
      );
      d.execute("INSERT INTO caves (id, title) VALUES (1, 'Invented Cave')");
      d.execute(
        'INSERT INTO raster_maps (id, title, map_type, file_name, cave_id) '
        "VALUES (1, 'Invented Map', 'plan', 'm.png', 1), "
        "(2, 'Invented Profile', 'projected profile', 'p.png', 1)",
      );
      d.execute('PRAGMA user_version = 5');
    });

    await open(f);

    expect(_mapTypes(f), ['other', 'projected profile']);
  });
}

void _raw(File f, void Function(Database d) body) {
  final d = sqlite3.open(f.path);
  try {
    body(d);
  } finally {
    d.close();
  }
}

List<String> _mapTypes(File f) {
  final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
  try {
    return [
      for (final r in d.select(
        'SELECT map_type FROM raster_maps ORDER BY map_type',
      ))
        r['map_type'] as String,
    ];
  } finally {
    d.close();
  }
}
