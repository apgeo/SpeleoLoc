import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/sync/sync_table_registry.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:sqlite3/sqlite3.dart' show Database;

import '../support/schema_snapshots.dart';

/// A database brought up from an older version must survive an export and
/// import through the current sync format without losing a row.
///
/// The source is built at v9, the first version with users and audit
/// columns, from its schema snapshot and an invented data set with a row in
/// every table that version syncs, every reference set. Opening it runs the
/// ladder to the current schema; it is then exported, imported into a fresh
/// database, and the per-table row counts are compared.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_fixture_rt_');
  });
  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<(AppDatabase, SyncArchiveService)> buildStack(
    QueryExecutor executor,
    Directory assets,
  ) async {
    final db = AppDatabase.forTesting(executor);
    late ChangeLogger loggerRef;
    final userRepo = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      userRepo,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    loggerRef = ChangeLogger(db, currentUser);
    final sync = SyncArchiveService(
      db,
      loggerRef,
      assetsBaseDirResolver: () async => assets,
    );
    return (db, sync);
  }

  test(
    'a database upgraded from v9 round-trips through sync without row loss',
    () async {
      // The on-open migration runs the ladder from v9 to the current schema.
      final source = createDatabaseAtVersion(
        p.join(tempDir.path, 'source.sqlite'),
        9,
        seed: _seedInventedV9Data,
      );

      final srcAssets = await Directory.systemTemp.createTemp('rt_src_');
      final (srcDb, srcSync) = await buildStack(
        NativeDatabase(source),
        srcAssets,
      );
      final tgtAssets = await Directory.systemTemp.createTemp('rt_tgt_');
      final (tgtDb, tgtSync) = await buildStack(
        NativeDatabase.memory(),
        tgtAssets,
      );

      try {
        // Opening migrated the fixture to the current schema.
        final stamp = await srcDb
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(stamp.data.values.single, srcDb.schemaVersion);

        // Per-table dump counts on the migrated source.
        final srcRegistry = SyncTableRegistry(srcDb);
        final srcCounts = <String, int>{};
        for (final t in srcRegistry.tables()) {
          srcCounts[t.name] = (await t.dump()).length;
        }
        // Every table the fixture fills is still filled after the upgrade,
        // so the comparison below covers each of them.
        for (final table in _filledTables) {
          expect(srcCounts[table], greaterThan(0), reason: table);
        }

        final zip = await srcSync.exportToZip(
          tempDir.path,
          filenameHint: 'rt.zip',
          includeDocumentationFiles: false,
          includeRasterMaps: false,
        );

        final report = await tgtSync.importFromZip(zip.path);
        expect(report.rowsInserted, greaterThan(0));

        // Every synced table has the same dump count on the fresh target.
        // `users` is compared by username instead of raw count because sync
        // merges the auto-created 'system' user across devices by username.
        final tgtRegistry = SyncTableRegistry(tgtDb);
        for (final t in tgtRegistry.tables()) {
          if (t.name == 'users') continue;
          final tgtCount = (await t.dump()).length;
          expect(
            tgtCount,
            srcCounts[t.name],
            reason:
                'row-count mismatch for ${t.name}: '
                'src=${srcCounts[t.name]} tgt=$tgtCount '
                '(warnings: ${report.warnings.join("; ")})',
          );
        }

        final srcUsernames = (await srcDb.select(srcDb.users).get())
            .map((u) => u.username)
            .toSet();
        final tgtUsernames = (await tgtDb.select(tgtDb.users).get())
            .map((u) => u.username)
            .toSet();
        expect(
          tgtUsernames.containsAll(srcUsernames),
          isTrue,
          reason: 'every source user should survive the round-trip',
        );
      } finally {
        await srcDb.close();
        await tgtDb.close();
      }
    },
  );
}

/// The synced tables [_seedInventedV9Data] writes to.
const _filledTables = [
  'users',
  'surface_areas',
  'caves',
  'cave_areas',
  'cave_places',
  'raster_maps',
  'cave_place_to_raster_map_definitions',
  'cave_trips',
  'cave_trip_points',
  'documentation_files',
  'documentation_files_to_geofeatures',
  'documentation_files_to_cave_trips',
  'trip_report_templates',
];

/// Invented rows in every table of the v9 schema that holds caving data,
/// each one made by an invented caver and every reference pointing at a row
/// that is there.
void _seedInventedV9Data(Database d) {
  const t = 1700000000000;
  final caver = Uuid.v7().bytes;
  final plateau = Uuid.v7().bytes;
  final alpha = Uuid.v7().bytes;
  final beta = Uuid.v7().bytes;
  final gallery = Uuid.v7().bytes;
  final sinkhole = Uuid.v7().bytes;
  final entrance = Uuid.v7().bytes;
  final sump = Uuid.v7().bytes;
  final chamber = Uuid.v7().bytes;
  final plan = Uuid.v7().bytes;
  final section = Uuid.v7().bytes;
  final sketch = Uuid.v7().bytes;
  final survey = Uuid.v7().bytes;
  final photo = Uuid.v7().bytes;

  void insert(String table, Map<String, Object?> row) {
    final values = {
      ...row,
      'created_at': t,
      'updated_at': t + 1,
      if (table != 'users' || row['uuid'] != caver) ...{
        'created_by_user_uuid': caver,
        'last_modified_by_user_uuid': caver,
      },
    };
    if (table == 'documentation_files_to_cave_trips') {
      values.remove('updated_at');
    }
    d.execute(
      'INSERT INTO $table (${values.keys.join(', ')}) '
      'VALUES (${List.filled(values.length, '?').join(', ')})',
      values.values.toList(),
    );
  }

  insert('users', {
    'uuid': caver,
    'username': 'invented_caver',
    'first_name': 'Invented',
    'last_name': 'Caver',
  });
  insert('surface_areas', {'uuid': plateau, 'title': 'Invented Plateau'});
  insert('caves', {
    'uuid': alpha,
    'title': 'Invented Cave Alpha',
    'surface_area_uuid': plateau,
  });
  insert('caves', {'uuid': beta, 'title': 'Invented Cave Beta'});
  insert('cave_areas', {
    'uuid': gallery,
    'title': 'Invented Upper Gallery',
    'cave_uuid': alpha,
  });
  insert('surface_places', {'uuid': sinkhole, 'title': 'Invented Sinkhole'});
  insert('cave_entrances', {
    'uuid': Uuid.v7().bytes,
    'cave_uuid': alpha,
    'surface_place_uuid': sinkhole,
    'title': 'Invented Main Entrance',
  });
  for (final (uuid, title, cave, area, qr, isEntrance) in [
    (entrance, 'Invented Entrance', alpha, null, 101, 1),
    (sump, 'Invented Sump', alpha, gallery, null, 0),
    (chamber, 'Invented Chamber', beta, null, 202, 0),
  ]) {
    insert('cave_places', {
      'uuid': uuid,
      'title': title,
      'cave_uuid': cave,
      'cave_area_uuid': area,
      'place_qr_code_identifier': qr,
      'latitude': 45.5,
      'longitude': 25.25,
      'depth_in_cave': 12.5,
      'is_entrance': isEntrance,
    });
  }
  for (final (uuid, title, type, area) in [
    (plan, 'Invented Plan', 'plane view', null),
    (section, 'Invented Section', 'projected profile', gallery),
  ]) {
    insert('raster_maps', {
      'uuid': uuid,
      'title': title,
      'map_type': type,
      'file_name': '${title.toLowerCase().replaceAll(' ', '_')}.png',
      'cave_uuid': alpha,
      'cave_area_uuid': area,
    });
  }
  insert('cave_place_to_raster_map_definitions', {
    'uuid': Uuid.v7().bytes,
    'x_coordinate': 10,
    'y_coordinate': 20,
    'cave_place_uuid': entrance,
    'raster_map_uuid': plan,
  });
  insert('documentation_files', {
    'uuid': sketch,
    'title': 'Invented Sketch',
    'file_name': 'invented_sketch.jpg',
    'file_size': 2048,
    'file_hash': 'ab' * 32,
    'file_type': 'image',
  });
  for (final (target, type) in [(alpha, 'cave'), (sump, 'cave_place')]) {
    insert('documentation_files_to_geofeatures', {
      'uuid': Uuid.v7().bytes,
      'geofeature_uuid': target,
      'geofeature_type': type,
      'documentation_file_uuid': sketch,
    });
  }
  for (final (uuid, cave, title, ended) in [
    (survey, alpha, 'Invented Survey Trip', t + 3600000),
    (photo, beta, 'Invented Photo Trip', null),
  ]) {
    insert('cave_trips', {
      'uuid': uuid,
      'cave_uuid': cave,
      'title': title,
      'trip_started_at': t,
      'trip_ended_at': ended,
      'log': 'invented log of $title',
    });
  }
  for (final (place, offset) in [(entrance, 60000), (null, 120000)]) {
    insert('cave_trip_points', {
      'uuid': Uuid.v7().bytes,
      'cave_trip_uuid': survey,
      'cave_place_uuid': place,
      'scanned_at': t + offset,
      'notes': 'invented note',
    });
  }
  insert('documentation_files_to_cave_trips', {
    'uuid': Uuid.v7().bytes,
    'documentation_file_uuid': sketch,
    'cave_trip_uuid': survey,
  });
  insert('trip_report_templates', {
    'uuid': Uuid.v7().bytes,
    'title': 'Invented Template',
    'file_name': 'invented_template.docx',
    'file_size': 1234,
    'format': 'docx',
  });
}
