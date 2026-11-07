import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

import '../../support/schema_snapshots.dart';

/// The v12 to v13 step rebuilds raster_maps to add `order_index`, numbering
/// each cave's maps in the order they were added. The rebuild must keep what
/// the maps already had, the picture's hash and size above all, which the
/// duplicate-picture check relies on. Every value here is invented.
void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('v12_to_v13_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('numbers each cave\'s maps by age and keeps their pictures', () async {
    final caveA = Uuid.v7();
    final caveB = Uuid.v7();
    final older = Uuid.v7();
    final newer = Uuid.v7();
    final other = Uuid.v7();
    final f = createDatabaseAtVersion(
      p.join(tmp.path, 'v12.sqlite'),
      12,
      seed: (d) {
        for (final (cave, title) in [
          (caveA, 'Invented Cave A'),
          (caveB, 'Invented Cave B'),
        ]) {
          d.execute('INSERT INTO caves (uuid, title) VALUES (?, ?)', [
            cave.bytes,
            title,
          ]);
        }
        // Inserted newest first, so the numbering cannot follow insertion.
        for (final (uuid, cave, title, hash, createdAt) in [
          (newer, caveA, 'Invented Profile', 'bb' * 32, 1700000002000),
          (older, caveA, 'Invented Plan', 'aa' * 32, 1700000001000),
          (other, caveB, 'Invented Other Plan', 'cc' * 32, 1700000003000),
        ]) {
          d.execute(
            'INSERT INTO raster_maps (uuid, title, map_type, file_name, '
            'file_hash, file_size, cave_uuid, created_at, updated_at, '
            "deleted_at) VALUES (?, ?, 'plane view', ?, ?, 4096, ?, ?, ?, ?)",
            [
              uuid.bytes,
              title,
              '$title.png',
              hash,
              cave.bytes,
              createdAt,
              createdAt + 1,
              uuid == other ? createdAt + 2 : null,
            ],
          );
        }
      },
    );

    await openThroughApp(f);

    final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
    try {
      final rows = {
        for (final r in d.select(
          'SELECT uuid, order_index, file_hash, file_size, updated_at, '
          'deleted_at FROM raster_maps',
        ))
          Uuid.fromBytes(r['uuid'] as List<int>): r,
      };
      expect(rows[older]!['order_index'], 0);
      expect(rows[newer]!['order_index'], 1);
      expect(rows[other]!['order_index'], 0);
      expect(rows[older]!['file_hash'], 'aa' * 32);
      expect(rows[newer]!['file_hash'], 'bb' * 32);
      expect(rows[newer]!['file_size'], 4096);
      expect(rows[newer]!['updated_at'], 1700000002001);
      expect(rows[other]!['deleted_at'], 1700000003002);
      expect(rows[older]!['deleted_at'], isNull);
    } finally {
      d.close();
    }
  });
}
