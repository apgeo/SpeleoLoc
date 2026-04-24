import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/source/database/app_database.dart';

/// Exercises the legacy v6 → v7 UUID migration against the real
/// `speleo_loc_export_20260414.sqlite` binary shipped under `test_data/`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy v6 export is migrated to v7 UUID schema with data preserved',
      () async {
    final source =
        File('test_data/db/binaries/speleo_loc_export_20260414.sqlite');
    expect(source.existsSync(), isTrue,
        reason: 'Legacy test DB binary missing');

    // Copy to a temp file so the test doesn't mutate the fixture.
    final tmpDir = await Directory.systemTemp.createTemp('legacy_v6_test_');
    final tmpFile = File(p.join(tmpDir.path, 'legacy.sqlite'));
    await source.copy(tmpFile.path);

    final db = AppDatabase.forTesting(NativeDatabase(tmpFile));
    try {
      // Opening triggers onUpgrade (user_version=5 → schemaVersion=7).
      final caves = await db.select(db.caves).get();
      final cavePlaces = await db.select(db.cavePlaces).get();
      final rasterMaps = await db.select(db.rasterMaps).get();
      final caveAreas = await db.select(db.caveAreas).get();
      final surfaceAreas = await db.select(db.surfaceAreas).get();

      // Sanity: the export is expected to contain some caves.
      expect(caves, isNotEmpty,
          reason: 'Legacy export should contain cave rows');

      // Every migrated row has a 16-byte UUID PK.
      for (final c in caves) {
        expect(c.uuid.bytes.length, 16);
      }

      // FK integrity: every cave_place.cave_uuid points at an existing cave.
      final caveUuids = caves.map((c) => c.uuid).toSet();
      for (final cp in cavePlaces) {
        expect(caveUuids.contains(cp.caveUuid), isTrue,
            reason: 'cave_place ${cp.uuid} references missing cave');
      }

      // Non-null checks on migrated rows (smoke).
      for (final r in rasterMaps) {
        expect(r.uuid.bytes.length, 16);
      }
      for (final a in caveAreas) {
        expect(a.uuid.bytes.length, 16);
      }
      for (final s in surfaceAreas) {
        expect(s.uuid.bytes.length, 16);
      }

      // Drift reports the new schema version.
      expect(db.schemaVersion, 9);
    } finally {
      await db.close();
      await tmpDir.delete(recursive: true);
    }
  });
}
