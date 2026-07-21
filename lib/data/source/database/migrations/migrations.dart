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
    // createAll builds the partial title index for NULL-area cave places,
    // but legacy data may still contain title twins that would abort the
    // reinsert below. Drop it here; V16ToV17Migration (which also runs on
    // this path) renames the twins and recreates the index afterwards.
    await db.customStatement(
      'DROP INDEX IF EXISTS idx_cave_places_title_no_area',
    );
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
    // Recreate cave_trips for its new UNIQUE constraint, PRESERVING existing
    // rows. The previous code did drop + create, which silently discarded
    // every trip in any v7 database that had them (the v7 cave_trips table
    // already existed). Reinsert the v7 column set; audit columns
    // (created_by/last_modified) and device_uuid are added by later
    // migrations and stay NULL here.
    await TableRecreator.recreate(
      db: db,
      migrator: migrator,
      table: db.caveTrips,
      reinsert: (d) async {
        await db.customStatement(
          'INSERT INTO cave_trips '
          '(uuid, cave_uuid, title, description, trip_started_at, '
          'trip_ended_at, log, created_at, updated_at, deleted_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
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
          ],
        );
      },
    );
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

    // The shared [_seedConfiguration] helper writes the `is_synced` column,
    // but that column is only formally added in v10→v11. For a real v7/v8
    // database (where v6→v7's createAll did not run) the column does not yet
    // exist here, so seeding below would crash with "no column named
    // is_synced" and the whole upgrade would fail. Add it now, idempotently;
    // v10→v11's own guarded add-column then skips it.
    final cfgInfo = await db
        .customSelect('PRAGMA table_info(configurations)')
        .get();
    final cfgCols = cfgInfo.map((r) => r.data['name'] as String).toSet();
    if (!cfgCols.contains('is_synced')) {
      await db.customStatement(
        'ALTER TABLE configurations '
        'ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0',
      );
    }

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
      await db.customStatement(
        'ALTER TABLE cave_places ADD COLUMN altitude REAL',
      );
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
    final cpInfo = await db
        .customSelect('PRAGMA table_info(cave_places)')
        .get();
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

    final saInfo = await db
        .customSelect('PRAGMA table_info(surface_areas)')
        .get();
    final saCols = saInfo.map((r) => r.data['name'] as String).toSet();
    if (!saCols.contains('general_area_identifier')) {
      await db.customStatement(
        'ALTER TABLE surface_areas ADD COLUMN general_area_identifier TEXT',
      );
    }

    final cfgInfo = await db
        .customSelect('PRAGMA table_info(configurations)')
        .get();
    final cfgCols = cfgInfo.map((r) => r.data['name'] as String).toSet();
    if (!cfgCols.contains('is_synced')) {
      await db.customStatement(
        'ALTER TABLE configurations '
        'ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0',
      );
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _seedConfiguration(
      db,
      'place_code_strategy',
      'global_hierarchical',
      nowMs,
      isSynced: true,
    );
    await _seedConfiguration(
      db,
      'place_code_strategy_config',
      '{}',
      nowMs,
      isSynced: true,
    );
    await _seedConfiguration(db, 'qcri_mode', 'plain', nowMs, isSynced: true);
    await _seedConfiguration(
      db,
      'qcri_hash_config',
      '{}',
      nowMs,
      isSynced: true,
    );
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

/// v14 → v15: create `cave_place_beacons` (BLE beacon registrations —
/// beacon identity → cave place, plus health telemetry). New table only;
/// idempotent thanks to CREATE TABLE IF NOT EXISTS in tables.drift.
class V14ToV15Migration extends SchemaMigration {
  const V14ToV15Migration();

  @override
  int get toVersion => 15;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await migrator.createTable(db.cavePlaceBeacons);
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cave_place_beacons_identity '
      'ON cave_place_beacons(proximity_uuid, major, minor)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cave_place_beacons_place '
      'ON cave_place_beacons(cave_place_uuid)',
    );
  }
}

/// v15 → v16: multi-kind tag support + Ruuvi history.
/// 1. Recreate cave_place_beacons: beacon_type discriminator (existing
///    rows become 'ibeacon'), iBeacon triple relaxed to nullable, new
///    firmware_version + last_pressure_hpa + last_movement_counter
///    columns. The triple UNIQUE constraint keeps guarding iBeacon rows
///    (NULL triples never collide), so Ruuvi identity gets its own
///    partial unique index on (mac_address, cave_uuid).
/// 2. Create the local-only ruuvi_sensor_history table.
class V15ToV16Migration extends SchemaMigration {
  const V15ToV16Migration();

  @override
  int get toVersion => 16;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await TableRecreator.recreate(
      db: db,
      migrator: migrator,
      table: db.cavePlaceBeacons,
      reinsert: (d) async {
        await db.customStatement(
          'INSERT INTO cave_place_beacons '
          '(uuid, cave_place_uuid, cave_uuid, beacon_type, '
          'proximity_uuid, major, minor, mac_address, local_name, model, '
          'measured_power, notes, '
          'last_seen_at, last_battery_mv, last_temperature_c, '
          'last_humidity_pct, '
          'created_at, updated_at, deleted_at, '
          'created_by_user_uuid, last_modified_by_user_uuid) '
          "VALUES (?, ?, ?, 'ibeacon', ?, ?, ?, ?, ?, ?, ?, ?, "
          '?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            d['uuid'],
            d['cave_place_uuid'],
            d['cave_uuid'],
            d['proximity_uuid'],
            d['major'],
            d['minor'],
            d['mac_address'],
            d['local_name'],
            d['model'],
            d['measured_power'],
            d['notes'],
            d['last_seen_at'],
            d['last_battery_mv'],
            d['last_temperature_c'],
            d['last_humidity_pct'],
            d['created_at'],
            d['updated_at'],
            d['deleted_at'],
            d['created_by_user_uuid'],
            d['last_modified_by_user_uuid'],
          ],
        );
      },
    );
    // The recreate drops the v15 indexes with the table — restore them.
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cave_place_beacons_identity '
      'ON cave_place_beacons(proximity_uuid, major, minor)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cave_place_beacons_place '
      'ON cave_place_beacons(cave_place_uuid)',
    );
    await db.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_cave_place_beacons_ruuvi '
      "ON cave_place_beacons(mac_address, cave_uuid) "
      "WHERE beacon_type = 'ruuvi'",
    );
    await migrator.createTable(db.ruuviSensorHistory);
  }
}

/// v16 → v17: enforce title uniqueness for cave places without a cave
/// area. UNIQUE(title, cave_uuid, cave_area_uuid) never fires when
/// cave_area_uuid is NULL (SQLite treats NULLs as distinct), so a partial
/// unique index on (title, cave_uuid) WHERE cave_area_uuid IS NULL closes
/// the gap — the same pattern as the Ruuvi identity index in v15→v16.
/// Existing twins are renamed with a numeric suffix (earliest row by
/// created_at keeps its title) before the index is created. The renames
/// bypass change_log: migrations run before the services that own audit
/// logging, and the rows sync by uuid afterwards either way.
class V16ToV17Migration extends SchemaMigration {
  const V16ToV17Migration();

  @override
  int get toVersion => 17;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    final rows = await db
        .customSelect(
          'SELECT uuid, title, hex(cave_uuid) AS cave_hex '
          'FROM cave_places WHERE cave_area_uuid IS NULL '
          'ORDER BY cave_uuid, title, COALESCE(created_at, 0), uuid',
        )
        .get();

    // Group NULL-area rows by (cave, title); every row after the first in
    // a group is a twin that needs a new title.
    final groups = <String, List<QueryRow>>{};
    for (final row in rows) {
      final key =
          '${row.read<String>('cave_hex')}|${row.read<String>('title')}';
      (groups[key] ??= []).add(row);
    }

    final takenByCave = <String, Set<String>>{};
    Future<Set<String>> takenTitles(String caveHex) async {
      final cached = takenByCave[caveHex];
      if (cached != null) return cached;
      final titleRows = await db
          .customSelect(
            'SELECT title FROM cave_places WHERE hex(cave_uuid) = ?',
            variables: [Variable.withString(caveHex)],
          )
          .get();
      return takenByCave[caveHex] = {
        for (final r in titleRows) r.read<String>('title'),
      };
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final group in groups.values) {
      if (group.length < 2) continue;
      final caveHex = group.first.read<String>('cave_hex');
      final title = group.first.read<String>('title');
      final taken = await takenTitles(caveHex);
      for (final twin in group.skip(1)) {
        var n = 2;
        while (taken.contains('$title $n')) {
          n++;
        }
        final newTitle = '$title $n';
        taken.add(newTitle);
        await db.customStatement(
          'UPDATE cave_places SET title = ?, updated_at = ? WHERE uuid = ?',
          [newTitle, nowMs, twin.read<Uint8List>('uuid')],
        );
      }
    }

    await db.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_cave_places_title_no_area '
      'ON cave_places(title, cave_uuid) WHERE cave_area_uuid IS NULL',
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
  V14ToV15Migration(),
  V15ToV16Migration(),
  V16ToV17Migration(),
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
