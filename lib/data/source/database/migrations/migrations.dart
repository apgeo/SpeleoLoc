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

/// v17 → v18: tag titles + re-registration after unassign.
/// Recreates cave_place_beacons (a) without the inline identity UNIQUE
/// constraint — it also covered soft-deleted rows, so an unassigned tag
/// could never be registered again in the same cave — and (b) with the
/// new user-facing `title` column. The identity guards return as partial
/// unique indexes scoped to active rows, one per beacon_type (the iBeacon
/// one replaces the inline constraint, the Ruuvi one gains the
/// deleted_at filter).
class V17ToV18Migration extends SchemaMigration {
  const V17ToV18Migration();

  @override
  int get toVersion => 18;

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
          'measured_power, firmware_version, notes, '
          'last_seen_at, last_battery_mv, last_temperature_c, '
          'last_humidity_pct, last_pressure_hpa, last_movement_counter, '
          'created_at, updated_at, deleted_at, '
          'created_by_user_uuid, last_modified_by_user_uuid) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '
          '?, ?, ?, ?, ?, ?)',
          [
            d['uuid'],
            d['cave_place_uuid'],
            d['cave_uuid'],
            d['beacon_type'],
            d['proximity_uuid'],
            d['major'],
            d['minor'],
            d['mac_address'],
            d['local_name'],
            d['model'],
            d['measured_power'],
            d['firmware_version'],
            d['notes'],
            d['last_seen_at'],
            d['last_battery_mv'],
            d['last_temperature_c'],
            d['last_humidity_pct'],
            d['last_pressure_hpa'],
            d['last_movement_counter'],
            d['created_at'],
            d['updated_at'],
            d['deleted_at'],
            d['created_by_user_uuid'],
            d['last_modified_by_user_uuid'],
          ],
        );
      },
    );
    // The recreate drops every index with the table — restore all four
    // (same statements as tables.drift runs for fresh installs).
    await db.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_cave_place_beacons_ibeacon '
      'ON cave_place_beacons(proximity_uuid, major, minor, cave_uuid) '
      "WHERE beacon_type = 'ibeacon' AND deleted_at IS NULL",
    );
    await db.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_cave_place_beacons_ruuvi '
      'ON cave_place_beacons(mac_address, cave_uuid) '
      "WHERE beacon_type = 'ruuvi' AND deleted_at IS NULL",
    );
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

/// v18 → v19.
///
/// Adds the two local-only tables the SilexGIS sync feature keeps its position
/// in: the download cursor per (profile, set), and the server revision of each
/// row this device has seen on that installation.
///
/// Both are local-only in the same sense `configurations` and
/// `ruuvi_sensor_history` are — absent from the sync-archive registry and from
/// the archive table configs, so nothing has to remember to skip them. That is
/// the point rather than an implementation detail: a cursor or a base revision
/// that travelled to a second device costs that device rows it never learns it
/// is missing, or loses every upload to a conflict it cannot explain.
///
/// Additive, so upgraders get the same statements a fresh install runs from
/// tables.drift.
class V18ToV19Migration extends SchemaMigration {
  const V18ToV19Migration();

  @override
  int get toVersion => 19;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await migrator.createTable(db.silexgisSyncState);
    await migrator.createTable(db.silexgisRowRevision);
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_silexgis_row_revision_table '
      'ON silexgis_row_revision(profile_uuid, entity_table)',
    );
  }
}

/// v19 → v20.
///
/// Records the wire `kind` and the local stamp beside each SilexGIS row
/// revision.
///
/// A local delete is physical, so once a row is gone this device can no longer
/// tell whether it was an entrance or a place inside the cave — and the
/// tombstone it has to send still names a kind. Keeping it here is what lets a
/// removal be composed correctly from a revision alone, rather than from an
/// assumption about what the server does with the field.
///
/// `local_updated_at` is the row's own stamp at the moment the two sides last
/// agreed about it, which is what decides whether it is due to be sent again.
/// Comparing stamps exactly, rather than a row's stamp against a clock reading,
/// leaves no window in which an edit is missed and none in which an untouched
/// row is re-sent for ever.
///
/// Additive and nullable: rows written before this migration have neither, and
/// a tombstone for one falls back to what the local table implies while a row
/// with no recorded stamp is treated as due.
class V19ToV20Migration extends SchemaMigration {
  const V19ToV20Migration();

  @override
  int get toVersion => 20;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    // Guarded because the pre-v7 path runs `createAll()` at the *current*
    // schema and then walks the whole ladder: by the time this step is reached
    // the table already has both columns, and a bare ADD COLUMN would fail the
    // upgrade for every legacy dataset. Every step after v7 is an idempotent
    // backfill for that reason.
    await _addColumnIfMissing(
      db,
      migrator,
      db.silexgisRowRevision,
      db.silexgisRowRevision.wireKind,
    );
    await _addColumnIfMissing(
      db,
      migrator,
      db.silexgisRowRevision,
      db.silexgisRowRevision.localUpdatedAt,
    );
  }
}

/// v20 → v21.
///
/// Adds the document-to-track-point link table behind the "trip points from
/// pictures" import.
///
/// Additive, so upgraders run the same statement a fresh install takes from
/// tables.drift. `createTable` is `CREATE TABLE IF NOT EXISTS`, which also
/// makes it a no-op on the pre-v7 path that runs `createAll()` at the current
/// schema before walking the ladder.
class V20ToV21Migration extends SchemaMigration {
  const V20ToV21Migration();

  @override
  int get toVersion => 21;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await migrator.createTable(db.documentationFilesToCaveTripPoints);
    // The import reads every link of a point when it rebuilds a trip, and
    // the cascade on point delete looks rows up the same way.
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_doc_files_to_trip_points_point '
      'ON documentation_files_to_cave_trip_points(cave_trip_point_uuid)',
    );
  }
}

/// v21 → v22.
///
/// Records when a trip's log fell behind its recorded points. Editing points
/// no longer rewrites the log unless the user asks for that, so a log can now
/// be out of date — and saying so later, on the log page or another device,
/// needs the fact stored with the trip rather than remembered by one screen.
///
/// Additive and nullable, guarded like the other post-v7 steps because the
/// pre-v7 path has already created the column through `createAll()`.
class V21ToV22Migration extends SchemaMigration {
  const V21ToV22Migration();

  @override
  int get toVersion => 22;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await _addColumnIfMissing(
      db,
      migrator,
      db.caveTrips,
      db.caveTrips.logStaleSince,
    );
  }
}

/// v22 → v23.
///
/// Records who took part in a trip. Additive and nullable, guarded like the
/// other post-v7 steps.
class V22ToV23Migration extends SchemaMigration {
  const V22ToV23Migration();

  @override
  int get toVersion => 23;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await _addColumnIfMissing(
      db,
      migrator,
      db.caveTrips,
      db.caveTrips.participants,
    );
  }
}

/// v23 → v24.
///
/// Adds the local cache of what reading device pictures for QR labels found,
/// so the points-from-pictures screen does not decode the same pictures every
/// time it opens. Local-only, like the SilexGIS state tables.
class V23ToV24Migration extends SchemaMigration {
  const V23ToV24Migration();

  @override
  int get toVersion => 24;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await migrator.createTable(db.mediaQrScanCache);
  }
}

/// v24 → v25.
///
/// Adds the local-only table that keeps one SilexGIS resume position per
/// stream of a sync set. Each stream's cursor is refused by every other
/// stream, so they cannot share the feature download's single position. Local
/// only, like the other SilexGIS state tables; nothing is moved into it.
class V24ToV25Migration extends SchemaMigration {
  const V24ToV25Migration();

  @override
  int get toVersion => 25;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await migrator.createTable(db.silexgisStreamCursor);
  }
}

/// v25 → v26.
///
/// Adds the local-only SilexGIS tables for rows an installation holds for a
/// reviewer, and for its people directory with this device's choice of caver
/// per phone user. Local only, like the other SilexGIS state tables; nothing is
/// moved into them.
class V25ToV26Migration extends SchemaMigration {
  const V25ToV26Migration();

  @override
  int get toVersion => 26;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await migrator.createTable(db.silexgisHeldRow);
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_silexgis_held_row_review '
      'ON silexgis_held_row(profile_uuid, review_id)',
    );
    await migrator.createTable(db.silexgisPerson);
    await migrator.createTable(db.silexgisPersonLink);
  }
}

/// v26 → v27.
///
/// Adds the local-only SilexGIS photo and document catalogue, and the register
/// of which documentation files are copies the server handed down. Local only,
/// like the other SilexGIS state tables; nothing is moved into them.
class V26ToV27Migration extends SchemaMigration {
  const V26ToV27Migration();

  @override
  int get toVersion => 27;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await migrator.createTable(db.silexgisDocument);
    await migrator.createTable(db.silexgisDocumentLink);
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_silexgis_document_link_target '
      'ON silexgis_document_link(profile_uuid, target_id)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_silexgis_document_link_document '
      'ON silexgis_document_link(profile_uuid, document_id)',
    );
    await migrator.createTable(db.silexgisFileCopy);
  }
}

/// v27 → v28.
///
/// Adds the local-only SilexGIS record of file bytes staged for an upload, and
/// of the document links an installation holds. Local only, like the other
/// SilexGIS state tables; nothing is moved into them.
class V27ToV28Migration extends SchemaMigration {
  const V27ToV28Migration();

  @override
  int get toVersion => 28;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await migrator.createTable(db.silexgisStagedUpload);
    await migrator.createTable(db.silexgisServerLink);
  }
}

/// v28 → v29.
///
/// Adds the local-only SilexGIS record of the trip recordings and scans an
/// installation holds: which recording a scan belongs to, whether a row came
/// from the installation or was sent from here, and an author no user on this
/// device is. Local only, like the other SilexGIS state tables; nothing is
/// moved into it.
class V28ToV29Migration extends SchemaMigration {
  const V28ToV29Migration();

  @override
  int get toVersion => 29;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await migrator.createTable(db.silexgisTripEntry);
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_silexgis_trip_entry_recording '
      'ON silexgis_trip_entry(profile_uuid, recording_uuid)',
    );
  }
}

/// v29 → v30.
///
/// Adds the local-only SilexGIS record of the raster maps and pins an
/// installation holds: which map a pin is on, whether a row came from the
/// installation or was sent from here, and which local picture stands for the
/// installation's. Local only, like the other SilexGIS state tables; nothing
/// is moved into it.
class V29ToV30Migration extends SchemaMigration {
  const V29ToV30Migration();

  @override
  int get toVersion => 30;

  @override
  Future<void> apply(AppDatabase db, Migrator migrator) async {
    await migrator.createTable(db.silexgisRasterEntry);
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_silexgis_raster_entry_map '
      'ON silexgis_raster_entry(profile_uuid, map_uuid)',
    );
  }
}

/// Adds [column] to [table] unless it is already there — or unless the
/// table is not there at all.
///
/// Every real database has had every table since v7, so an absent one only
/// occurs in a deliberately partial one, such as a migration test that builds
/// just the tables its own step touches. Adding a column there would fail the
/// whole ladder over a step the test is not about. The table name comes from
/// generated code, so this cannot hide a misspelling.
Future<void> _addColumnIfMissing(
  AppDatabase db,
  Migrator migrator,
  TableInfo<Table, dynamic> table,
  GeneratedColumn<Object> column,
) async {
  final existing = await db
      .customSelect('PRAGMA table_info(${table.actualTableName})')
      .get();
  if (existing.isEmpty) return;
  final names = existing.map((r) => r.read<String>('name')).toSet();
  if (names.contains(column.name)) return;
  await migrator.addColumn(table, column);
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
  V17ToV18Migration(),
  V18ToV19Migration(),
  V19ToV20Migration(),
  V20ToV21Migration(),
  V21ToV22Migration(),
  V22ToV23Migration(),
  V23ToV24Migration(),
  V24ToV25Migration(),
  V25ToV26Migration(),
  V26ToV27Migration(),
  V27ToV28Migration(),
  V28ToV29Migration(),
  V29ToV30Migration(),
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
