import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/legacy_v6_migration.dart';
import 'package:speleoloc/data/source/database/migrations/schema_migration.dart';

/// Pre-v7 → v7. Converts legacy INTEGER-PK schema to UUID-PK schema,
/// preserving rows and FK relationships via [snapshotLegacyV6] →
/// [dropLegacyV6Tables] → `migrator.createAll()` → [reinsertLegacyData].
class LegacyV6ToV7Migration extends SchemaMigration {
  const LegacyV6ToV7Migration();

  @override
  int get toVersion => 7;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    final snap = await snapshotLegacyV6(db);
    await dropLegacyV6Tables(db);
    await migrator.createAll();
    if (snap.totalRows > 0) {
      await reinsertLegacyData(db, snap);
    }
  }
}

/// v7 → v8.
/// 1. Add created_at column to documentation_files_to_geofeatures.
/// 2. Backfill cave_places.is_entrance / is_main_entrance NULL → 0.
/// 3. Recreate cave_trips for the new UNIQUE(title, cave_uuid) constraint.
/// 4. Recreate raster_maps for the new map_type CHECK constraint.
///
/// Only runs when `from == 7`: the v6→v7 path calls `createAll()` at the
/// current schema, so this step must not double-apply.
class V7ToV8Migration extends SchemaMigration {
  const V7ToV8Migration();

  @override
  int get toVersion => 8;

  @override
  bool shouldApply(int from) => from == 7;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await migrator.addColumn(
      db.documentationFilesToGeofeatures,
      db.documentationFilesToGeofeatures.createdAt,
    );
    await db.customStatement(
      'UPDATE cave_places SET is_entrance = 0 WHERE is_entrance IS NULL',
    );
    await db.customStatement(
      'UPDATE cave_places SET is_main_entrance = 0 WHERE is_main_entrance IS NULL',
    );
    await migrator.drop(db.caveTrips);
    await migrator.create(db.caveTrips);
    await TableRecreator.recreate(
      db: db,
      migrator: migrator,
      table: db.rasterMaps,
      reinsert: (d) async {
        await db.customStatement(
          'INSERT INTO raster_maps '
          '(uuid, title, map_type, file_name, cave_uuid, cave_area_uuid, '
          'created_at, updated_at, deleted_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            d['uuid'],
            d['title'],
            d['map_type'],
            d['file_name'],
            d['cave_uuid'],
            d['cave_area_uuid'],
            d['created_at'],
            d['updated_at'],
            d['deleted_at'],
          ],
        );
      },
    );
  }
}

/// v8 → v9: sync-v2 schema.
/// 1. Create `users` table.
/// 2. Add audit columns (created_by_user_uuid, last_modified_by_user_uuid)
///    to every existing syncable table.
/// 3. Create change_log + change_log_field + indexes.
/// 4. Seed local-only configuration keys required for sync.
///
/// All operations are idempotent (`CREATE TABLE IF NOT EXISTS`, column
/// existence checks via PRAGMA, `INSERT OR IGNORE`), so this migration
/// is safe to run after a `from < 7` legacy migration that already
/// produced the current schema via `createAll()`.
class V8ToV9Migration extends SchemaMigration {
  const V8ToV9Migration();

  @override
  int get toVersion => 9;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await migrator.createTable(db.users);

    final auditableTables = <TableInfo<Table, dynamic>>[
      db.caveAreas,
      db.caveEntrances,
      db.cavePlaceToRasterMapDefinitions,
      db.cavePlaces,
      db.caves,
      db.documentationFiles,
      db.documentationFilesToGeofeatures,
      db.rasterMaps,
      db.surfacePlaces,
      db.surfaceAreas,
      db.caveTrips,
      db.caveTripPoints,
      db.documentationFilesToCaveTrips,
      db.tripReportTemplates,
    ];
    for (final table in auditableTables) {
      final info = await db
          .customSelect('PRAGMA table_info(${table.actualTableName})')
          .get();
      final cols = info.map((r) => r.data['name'] as String).toSet();
      if (!cols.contains('created_by_user_uuid')) {
        await db.customStatement(
          'ALTER TABLE ${table.actualTableName} '
          'ADD COLUMN created_by_user_uuid BLOB '
          'REFERENCES users(uuid)',
        );
      }
      if (!cols.contains('last_modified_by_user_uuid')) {
        await db.customStatement(
          'ALTER TABLE ${table.actualTableName} '
          'ADD COLUMN last_modified_by_user_uuid BLOB '
          'REFERENCES users(uuid)',
        );
      }
    }

    await migrator.createTable(db.changeLog);
    await migrator.createTable(db.changeLogField);
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_change_log_entity '
      'ON change_log(entity_table, entity_uuid)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_change_log_changed_at '
      'ON change_log(changed_at)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_change_log_changed_by '
      'ON change_log(changed_by_user_uuid)',
    );

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _seedConfiguration(db, 'device_uuid', Uuid.v7().toString(), nowMs);
    await _seedConfiguration(db, 'change_log_retention_days', '365', nowMs);
    await _seedConfiguration(db, 'tombstone_retention_days', '365', nowMs);
  }
}

/// v9 → v10: add `altitude REAL` column to cave_places (WGS84
/// ellipsoidal meters captured by GPS).
class V9ToV10Migration extends SchemaMigration {
  const V9ToV10Migration();

  @override
  int get toVersion => 10;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    final info = await db.customSelect('PRAGMA table_info(cave_places)').get();
    final cols = info.map((r) => r.data['name'] as String).toSet();
    if (!cols.contains('altitude')) {
      await db.customStatement('ALTER TABLE cave_places ADD COLUMN altitude REAL');
    }
  }
}

/// v10 → v11: introduce the pluggable place-code identifier system.
/// See docs/features/place-code-identifiers.md.
class V10ToV11Migration extends SchemaMigration {
  const V10ToV11Migration();

  @override
  int get toVersion => 11;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    final cpInfo =
        await db.customSelect('PRAGMA table_info(cave_places)').get();
    final cpCols = cpInfo.map((r) => r.data['name'] as String).toSet();
    if (cpCols.contains('place_qr_code_identifier')) {
      await db.customStatement(
        'ALTER TABLE cave_places DROP COLUMN place_qr_code_identifier',
      );
    }
    if (!cpCols.contains('place_code_identifier')) {
      await db.customStatement(
        'ALTER TABLE cave_places ADD COLUMN place_code_identifier TEXT',
      );
    }
    if (!cpCols.contains('qr_code_resource_identifier')) {
      await db.customStatement(
        'ALTER TABLE cave_places ADD COLUMN qr_code_resource_identifier TEXT',
      );
    }

    final cavesInfo = await db.customSelect('PRAGMA table_info(caves)').get();
    final cavesCols = cavesInfo.map((r) => r.data['name'] as String).toSet();
    if (!cavesCols.contains('cave_local_index')) {
      await db.customStatement(
        'ALTER TABLE caves ADD COLUMN cave_local_index TEXT',
      );
    }

    final saInfo =
        await db.customSelect('PRAGMA table_info(surface_areas)').get();
    final saCols = saInfo.map((r) => r.data['name'] as String).toSet();
    if (!saCols.contains('general_area_identifier')) {
      await db.customStatement(
        'ALTER TABLE surface_areas ADD COLUMN general_area_identifier TEXT',
      );
    }

    final cfgInfo =
        await db.customSelect('PRAGMA table_info(configurations)').get();
    final cfgCols = cfgInfo.map((r) => r.data['name'] as String).toSet();
    if (!cfgCols.contains('is_synced')) {
      await db.customStatement(
        'ALTER TABLE configurations '
        'ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0',
      );
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _seedConfiguration(db, 'place_code_strategy',
        'global_hierarchical', nowMs,
        isSynced: true);
    await _seedConfiguration(
        db, 'place_code_strategy_config', '{}', nowMs,
        isSynced: true);
    await _seedConfiguration(db, 'qcri_mode', 'plain', nowMs, isSynced: true);
    await _seedConfiguration(db, 'qcri_hash_config', '{}', nowMs,
        isSynced: true);
  }
}

/// v11 → v12: add file_hash + file_size columns and expand map_type
/// CHECK constraint on raster_maps.
class V11ToV12Migration extends SchemaMigration {
  const V11ToV12Migration();

  @override
  int get toVersion => 12;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await TableRecreator.recreate(
      db: db,
      migrator: migrator,
      table: db.rasterMaps,
      reinsert: (d) async {
        await db.customStatement(
          'INSERT INTO raster_maps '
          '(uuid, title, map_type, file_name, '
          'file_hash, file_size, '
          'cave_uuid, cave_area_uuid, '
          'created_at, updated_at, deleted_at, '
          'created_by_user_uuid, last_modified_by_user_uuid) '
          'VALUES (?, ?, ?, ?, NULL, NULL, ?, ?, ?, ?, ?, ?, ?)',
          [
            d['uuid'],
            d['title'],
            d['map_type'],
            d['file_name'],
            d['cave_uuid'],
            d['cave_area_uuid'],
            d['created_at'],
            d['updated_at'],
            d['deleted_at'],
            d['created_by_user_uuid'],
            d['last_modified_by_user_uuid'],
          ],
        );
      },
    );
  }
}

/// v12 → v13: add `order_index INTEGER NOT NULL DEFAULT 0` to raster_maps,
/// backfilled per-cave sequentially.
class V12ToV13Migration extends SchemaMigration {
  const V12ToV13Migration();

  @override
  int get toVersion => 13;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    final caveCounter = <Object?, int>{};
    await TableRecreator.recreate(
      db: db,
      migrator: migrator,
      table: db.rasterMaps,
      selectSql:
          'SELECT * FROM raster_maps ORDER BY cave_uuid, created_at, uuid',
      reinsert: (d) async {
        final caveKey = d['cave_uuid'];
        final idx = caveCounter[caveKey] ?? 0;
        caveCounter[caveKey] = idx + 1;
        await db.customStatement(
          'INSERT INTO raster_maps '
          '(uuid, title, map_type, file_name, '
          'file_hash, file_size, order_index, '
          'cave_uuid, cave_area_uuid, '
          'created_at, updated_at, deleted_at, '
          'created_by_user_uuid, last_modified_by_user_uuid) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            d['uuid'],
            d['title'],
            d['map_type'],
            d['file_name'],
            d['file_hash'],
            d['file_size'],
            idx,
            d['cave_uuid'],
            d['cave_area_uuid'],
            d['created_at'],
            d['updated_at'],
            d['deleted_at'],
            d['created_by_user_uuid'],
            d['last_modified_by_user_uuid'],
          ],
        );
      },
    );
  }
}

/// v13 → v14: add device_uuid to cave_trips and widen UNIQUE constraint
/// from (title, cave_uuid) to
/// (title, cave_uuid, created_by_user_uuid, device_uuid). Existing rows
/// receive device_uuid = NULL; SQLite treats each NULL as distinct in
/// UNIQUE indexes, so no conflicts.
class V13ToV14Migration extends SchemaMigration {
  const V13ToV14Migration();

  @override
  int get toVersion => 14;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await TableRecreator.recreate(
      db: db,
      migrator: migrator,
      table: db.caveTrips,
      reinsert: (d) async {
        await db.customStatement(
          'INSERT INTO cave_trips '
          '(uuid, cave_uuid, title, description, '
          'trip_started_at, trip_ended_at, log, '
          'created_at, updated_at, deleted_at, '
          'created_by_user_uuid, last_modified_by_user_uuid) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            d['uuid'],
            d['cave_uuid'],
            d['title'],
            d['description'],
            d['trip_started_at'],
            d['trip_ended_at'],
            d['log'],
            d['created_at'],
            d['updated_at'],
            d['deleted_at'],
            d['created_by_user_uuid'],
            d['last_modified_by_user_uuid'],
          ],
        );
      },
    );
  }
}

/// Ordered list of all schema migrations. The engine iterates this list
/// in order during `onUpgrade`, applying each migration for which
/// [SchemaMigration.shouldApply] returns true. The original `from`
/// value is passed to every step (matching the pre-refactor chained
/// `if (from < N)` ladder).
const List<SchemaMigration> schemaMigrations = <SchemaMigration>[
  LegacyV6ToV7Migration(),
  V7ToV8Migration(),
  V8ToV9Migration(),
  V9ToV10Migration(),
  V10ToV11Migration(),
  V11ToV12Migration(),
  V12ToV13Migration(),
  V13ToV14Migration(),
];

/// Seeds a row into `configurations` with ON CONFLICT IGNORE on the
/// UNIQUE(title) constraint. Mirrors the original private
/// `AppDatabase._seedConfiguration` helper. Kept as a module-private
/// top-level function so each migration class is self-contained.
Future<void> _seedConfiguration(
  AppDatabase db,
  String title,
  String value,
  int nowMs, {
  bool isSynced = false,
}) async {
  await db.customStatement(
    'INSERT OR IGNORE INTO configurations '
    '(title, value, is_synced, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?)',
    [title, value, isSynced ? 1 : 0, nowMs, nowMs],
  );
}
