import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/legacy_v6_migration.dart';
import 'package:speleoloc/data/source/database/test_data_helper.dart';
import 'package:speleoloc/utils/uuid.dart';

export 'package:speleoloc/utils/uuid.dart' show Uuid, UuidConverter;

part 'app_database.g.dart';

AppDatabase appDatabase = AppDatabase();

class DatabaseMigrationEvent {
  const DatabaseMigrationEvent({
    required this.fromVersion,
    required this.toVersion,
    required this.timestamp,
  });

  final int fromVersion;
  final int toVersion;
  final DateTime timestamp;
}

class DatabaseMigrationMonitor {
  DatabaseMigrationMonitor._();

  static DatabaseMigrationEvent? _lastEvent;

  static void record({required int fromVersion, required int toVersion}) {
    _lastEvent = DatabaseMigrationEvent(
      fromVersion: fromVersion,
      toVersion: toVersion,
      timestamp: DateTime.now(),
    );
    debugPrint(
      '[DatabaseMigration] Upgrade performed: v$fromVersion -> v$toVersion',
    );
  }

  static DatabaseMigrationEvent? consumeLatest() {
    final event = _lastEvent;
    _lastEvent = null;
    return event;
  }
}

enum GeofeatureType {
  cave('cave'),
  cavePlace('cave_place'),
  caveArea('cave_area');

  const GeofeatureType(this.dbValue);
  final String dbValue;

  static GeofeatureType? fromDbValue(String? value) {
    if (value == null) return null;
    for (final type in GeofeatureType.values) {
      if (type.dbValue == value) return type;
    }
    return null;
  }
}

class DocumentationGeofeatureLink {
  final GeofeatureType type;
  final Uuid geofeatureUuid;

  const DocumentationGeofeatureLink({
    required this.type,
    required this.geofeatureUuid,
  });
}

class CavePlaceWithDefinition {
  final CavePlace cavePlace;
  final CavePlaceToRasterMapDefinition? definition;

  CavePlaceWithDefinition(this.cavePlace, this.definition);
}

@DriftDatabase(include: {'./tables.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          if (details.hadUpgrade) {
            DatabaseMigrationMonitor.record(
              fromVersion: details.versionBefore ?? 0,
              toVersion: details.versionNow,
            );
          }
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 7) {
            // Pre-v7 schemas used INTEGER PKs. Convert to UUID PKs while
            // preserving all rows and FK relationships.
            final snap = await snapshotLegacyV6(this);
            await dropLegacyV6Tables(this);
            await migrator.createAll();
            if (snap.totalRows > 0) {
              await reinsertLegacyData(this, snap);
            }
          }
          if (from == 7) {
            // v7 → v8 migrations:
            //
            // 1. Add created_at to documentation_files_to_geofeatures.
            await migrator.addColumn(
              documentationFilesToGeofeatures,
              documentationFilesToGeofeatures.createdAt,
            );

            // 2. Backfill cave_places.is_entrance / is_main_entrance NULL → 0.
            //    The columns are now NOT NULL DEFAULT 0; existing rows that
            //    pre-date the constraint must be updated before Drift enforces
            //    the non-nullable Dart type on read.
            await customStatement(
              'UPDATE cave_places SET is_entrance = 0 WHERE is_entrance IS NULL',
            );
            await customStatement(
              'UPDATE cave_places SET is_main_entrance = 0 WHERE is_main_entrance IS NULL',
            );

            // 3. Recreate cave_trips to apply the new UNIQUE(title, cave_uuid)
            //    constraint and the CHECK on raster_maps.map_type.
            //    cave_trips has 0 rows in all known v7 databases, so
            //    drop+create is safe. If rows exist they would be lost, but
            //    that is acceptable because active trips must have been ended
            //    before a migration is possible.
            await migrator.drop(caveTrips);
            await migrator.create(caveTrips);

            // 4. Recreate raster_maps to apply the new
            //    CHECK(map_type IN ('plane view', 'projected profile',
            //    'extended profile')) constraint. All existing rows have
            //    map_type = 'plane view' which is within the allowed set.
            //    cave_place_to_raster_map_definitions references raster_maps;
            //    FK checks are off during onUpgrade (PRAGMA foreign_keys is
            //    enabled in beforeOpen, which runs after this callback), so
            //    the drop is safe.
            final rasterMapRows = await customSelect(
              'SELECT * FROM raster_maps',
            ).get();
            await migrator.drop(rasterMaps);
            await migrator.create(rasterMaps);
            for (final row in rasterMapRows) {
              final d = row.data;
              await customStatement(
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
            }
          }
          if (from < 9) {
            // v8 → v9 migrations: sync-v2 schema
            //
            // 1. Create `users` table. Audit columns on the users table itself
            //    self-reference users(uuid), which is fine because they are
            //    nullable and SQLite does not enforce self-FK checks.
            await migrator.createTable(users);

            // 2. Add audit columns (created_by_user_uuid,
            //    last_modified_by_user_uuid) to every existing syncable
            //    table. They are nullable so existing rows are backfilled
            //    with NULL and the app treats NULL as "unknown author".
            final auditableTables = <TableInfo<Table, dynamic>>[
              caveAreas,
              caveEntrances,
              cavePlaceToRasterMapDefinitions,
              cavePlaces,
              caves,
              documentationFiles,
              documentationFilesToGeofeatures,
              rasterMaps,
              surfacePlaces,
              surfaceAreas,
              caveTrips,
              caveTripPoints,
              documentationFilesToCaveTrips,
              tripReportTemplates,
            ];
            for (final table in auditableTables) {
              final info = await customSelect(
                'PRAGMA table_info(${table.actualTableName})',
              ).get();
              final cols =
                  info.map((r) => r.data['name'] as String).toSet();
              if (!cols.contains('created_by_user_uuid')) {
                await customStatement(
                  'ALTER TABLE ${table.actualTableName} '
                  'ADD COLUMN created_by_user_uuid BLOB '
                  'REFERENCES users(uuid)',
                );
              }
              if (!cols.contains('last_modified_by_user_uuid')) {
                await customStatement(
                  'ALTER TABLE ${table.actualTableName} '
                  'ADD COLUMN last_modified_by_user_uuid BLOB '
                  'REFERENCES users(uuid)',
                );
              }
            }

            // 3. Create change_log + change_log_field + indexes.
            await migrator.createTable(changeLog);
            await migrator.createTable(changeLogField);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_change_log_entity '
              'ON change_log(entity_table, entity_uuid)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_change_log_changed_at '
              'ON change_log(changed_at)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_change_log_changed_by '
              'ON change_log(changed_by_user_uuid)',
            );

            // 4. Seed local-only configuration keys required for sync. They
            //    are created with ON CONFLICT IGNORE semantics via UNIQUE
            //    on configurations.title.
            final nowMs = DateTime.now().millisecondsSinceEpoch;
            await _seedConfiguration(
              'device_uuid',
              Uuid.v7().toString(),
              nowMs,
            );
            await _seedConfiguration(
              'change_log_retention_days',
              '365',
              nowMs,
            );
            await _seedConfiguration(
              'tombstone_retention_days',
              '365',
              nowMs,
            );
          }
          if (from < 10) {
            // v9 → v10 migration: add `altitude` column to cave_places.
            // Holds the surface altitude (WGS84 ellipsoidal, meters) captured
            // by the GPS recorder. Nullable; existing rows stay NULL.
            final info = await customSelect(
              'PRAGMA table_info(cave_places)',
            ).get();
            final cols = info.map((r) => r.data['name'] as String).toSet();
            if (!cols.contains('altitude')) {
              await customStatement(
                'ALTER TABLE cave_places ADD COLUMN altitude REAL',
              );
            }
          }
        },
      );

  Future<void> _seedConfiguration(
      String title, String value, int nowMs) async {
    await customStatement(
      'INSERT OR IGNORE INTO configurations '
      '(title, value, created_at, updated_at) VALUES (?, ?, ?, ?)',
      [title, value, nowMs, nowMs],
    );
  }

  Future<Uuid> insertCaveTrip({
    required Uuid caveUuid,
    required String title,
    String? description,
    required int startedAt,
    required Uuid authorUuid,
  }) async {
    final uuid = Uuid.v7();
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(caveTrips).insert(
      CaveTripsCompanion.insert(
        uuid: uuid,
        caveUuid: caveUuid,
        title: title,
        description: Value(description),
        tripStartedAt: startedAt,
        createdAt: Value(now),
        updatedAt: Value(now),
        createdByUserUuid: Value(authorUuid),
        lastModifiedByUserUuid: Value(authorUuid),
      ),
    );
    return uuid;
  }

  Future<void> endCaveTrip(Uuid tripUuid, {required Uuid authorUuid}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(caveTrips)..where((t) => t.uuid.equalsValue(tripUuid))).write(
      CaveTripsCompanion(
        tripEndedAt: Value(now),
        updatedAt: Value(now),
        lastModifiedByUserUuid: Value(authorUuid),
      ),
    );
  }

  Future<CaveTrip?> getActiveTripForCave(Uuid caveUuid) async {
    return (select(caveTrips)
          ..where((t) => t.caveUuid.equalsValue(caveUuid) & t.tripEndedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.tripStartedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<CaveTrip?> getActiveTrip() async {
    return (select(caveTrips)
          ..where((t) => t.tripEndedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.tripStartedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<Uuid> insertTripPoint({
    required Uuid tripUuid,
    required Uuid cavePlaceUuid,
    String? notes,
    required Uuid authorUuid,
  }) async {
    final uuid = Uuid.v7();
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(caveTripPoints).insert(
      CaveTripPointsCompanion.insert(
        uuid: uuid,
        caveTripUuid: tripUuid,
        cavePlaceUuid: Value(cavePlaceUuid),
        scannedAt: now,
        notes: Value(notes),
        createdAt: Value(now),
        updatedAt: Value(now),
        createdByUserUuid: Value(authorUuid),
        lastModifiedByUserUuid: Value(authorUuid),
      ),
    );
    return uuid;
  }

  Future<List<CaveTripPoint>> getTripPoints(Uuid tripUuid) async {
    return (select(caveTripPoints)
          ..where((t) => t.caveTripUuid.equalsValue(tripUuid))
          ..orderBy([(t) => OrderingTerm.asc(t.scannedAt)]))
        .get();
  }

  Future<List<CaveTrip>> getCaveTrips(Uuid caveUuid) async {
    return (select(caveTrips)
          ..where((t) => t.caveUuid.equalsValue(caveUuid))
          ..orderBy([(t) => OrderingTerm.desc(t.tripStartedAt)]))
        .get();
  }

  Future<List<String>> getCaveTripTitles(Uuid caveUuid) async {
    final trips = await (select(caveTrips)
          ..where((t) => t.caveUuid.equalsValue(caveUuid)))
        .get();
    return trips.map((t) => t.title).toList();
  }

  Future<void> linkDocumentToTrip(Uuid docUuid, Uuid tripUuid,
      {required Uuid authorUuid}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(documentationFilesToCaveTrips).insertOnConflictUpdate(
      DocumentationFilesToCaveTripsCompanion.insert(
        uuid: Uuid.v7(),
        documentationFileUuid: docUuid,
        caveTripUuid: tripUuid,
        createdAt: Value(now),
        createdByUserUuid: Value(authorUuid),
        lastModifiedByUserUuid: Value(authorUuid),
      ),
    );
  }

  Future<void> deleteCaveTrip(Uuid tripUuid) async {
    await transaction(() async {
      await (delete(documentationFilesToCaveTrips)
            ..where((t) => t.caveTripUuid.equalsValue(tripUuid)))
          .go();
      await (delete(caveTripPoints)
            ..where((t) => t.caveTripUuid.equalsValue(tripUuid)))
          .go();
      await (delete(caveTrips)..where((t) => t.uuid.equalsValue(tripUuid))).go();
    });
  }

  /// Reactivates a previously ended trip: clears [tripEndedAt], resets
  /// [tripStartedAt] to now, and records the author.
  Future<void> restartCaveTrip(Uuid tripUuid,
      {required Uuid authorUuid}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(caveTrips)..where((t) => t.uuid.equalsValue(tripUuid)))
        .write(
      CaveTripsCompanion(
        tripEndedAt: const Value(null),
        tripStartedAt: Value(now),
        updatedAt: Value(now),
        lastModifiedByUserUuid: Value(authorUuid),
      ),
    );
  }

  Future<void> renameCaveTrip(Uuid tripUuid, String newTitle) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(caveTrips)..where((t) => t.uuid.equalsValue(tripUuid)))
        .write(
      CaveTripsCompanion(
        title: Value(newTitle),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> appendToTripLog(Uuid tripUuid, String formattedLine) async {
    await transaction(() async {
      final trip = await (select(caveTrips)
            ..where((t) => t.uuid.equalsValue(tripUuid)))
          .getSingleOrNull();
      if (trip == null) return;
      final current = trip.log ?? '';
      final newLog =
          current.isEmpty ? formattedLine : '$current\n$formattedLine';
      await (update(caveTrips)..where((t) => t.uuid.equalsValue(tripUuid))).write(
        CaveTripsCompanion(
          log: Value(newLog),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    });
  }

  Future<void> updateTripLog(Uuid tripUuid, String log) async {
    await (update(caveTrips)..where((t) => t.uuid.equalsValue(tripUuid))).write(
      CaveTripsCompanion(
        log: Value(log),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<List<TripReportTemplate>> getTripReportTemplates() async {
    return (select(tripReportTemplates)
          ..orderBy([(t) => OrderingTerm.asc(t.title)]))
        .get();
  }

  Future<TripReportTemplate?> getTripReportTemplate(Uuid uuid) async {
    return (select(tripReportTemplates)..where((t) => t.uuid.equalsValue(uuid)))
        .getSingleOrNull();
  }

  Future<Uuid> insertTripReportTemplate({
    required String title,
    required String fileName,
    required int fileSize,
    required String format,
  }) async {
    final uuid = Uuid.v7();
    await into(tripReportTemplates).insert(
      TripReportTemplatesCompanion.insert(
        uuid: uuid,
        title: title,
        fileName: fileName,
        fileSize: fileSize,
        format: format,
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    return uuid;
  }

  Future<void> deleteTripReportTemplate(Uuid uuid) async {
    await (delete(tripReportTemplates)..where((t) => t.uuid.equalsValue(uuid))).go();
  }

  Future<bool> _geofeatureExists(
      GeofeatureType type, Uuid geofeatureUuid) async {
    switch (type) {
      case GeofeatureType.cave:
        final cave =
            await (select(caves)..where((t) => t.uuid.equalsValue(geofeatureUuid)))
                .getSingleOrNull();
        return cave != null;
      case GeofeatureType.cavePlace:
        final cavePlace = await (select(cavePlaces)
              ..where((t) => t.uuid.equalsValue(geofeatureUuid)))
            .getSingleOrNull();
        return cavePlace != null;
      case GeofeatureType.caveArea:
        final caveArea = await (select(caveAreas)
              ..where((t) => t.uuid.equalsValue(geofeatureUuid)))
            .getSingleOrNull();
        return caveArea != null;
    }
  }

  Future<void> _assertValidGeofeatureLink(
      DocumentationGeofeatureLink link) async {
    final exists = await _geofeatureExists(link.type, link.geofeatureUuid);
    if (!exists) {
      throw StateError(
          'Invalid geofeature link: ${link.type.dbValue}(${link.geofeatureUuid}) does not exist.');
    }
  }

  Future<DocumentationGeofeatureLink?> getDocumentationParentLink({
    Uuid? caveUuid,
    Uuid? cavePlaceUuid,
    Uuid? caveAreaUuid,
  }) async {
    final provided =
        [caveUuid, cavePlaceUuid, caveAreaUuid].where((v) => v != null).length;
    if (provided == 0) return null;
    if (provided > 1) {
      throw ArgumentError(
          'Only one of caveUuid, cavePlaceUuid, caveAreaUuid can be provided.');
    }

    if (caveUuid != null) {
      return DocumentationGeofeatureLink(
          type: GeofeatureType.cave, geofeatureUuid: caveUuid);
    }
    if (cavePlaceUuid != null) {
      return DocumentationGeofeatureLink(
          type: GeofeatureType.cavePlace, geofeatureUuid: cavePlaceUuid);
    }
    return DocumentationGeofeatureLink(
        type: GeofeatureType.caveArea, geofeatureUuid: caveAreaUuid!);
  }

  Future<void> insertDocumentationLink({
    required Uuid documentationFileUuid,
    required DocumentationGeofeatureLink link,
  }) async {
    await _assertValidGeofeatureLink(link);

    await into(documentationFilesToGeofeatures).insert(
      DocumentationFilesToGeofeaturesCompanion.insert(
        uuid: Uuid.v7(),
        geofeatureType: link.type.dbValue,
        documentationFileUuid: documentationFileUuid,
        geofeatureUuid: Value(link.geofeatureUuid),
      ),
    );
  }

  Future<Uuid> insertDocumentationFile({
    required DocumentationFilesCompanion companion,
    DocumentationGeofeatureLink? parentLink,
  }) async {
    return transaction(() async {
      final uuidValue =
          companion.uuid.present ? companion.uuid.value : Uuid.v7();
      final effective = companion.copyWith(uuid: Value(uuidValue));
      await into(documentationFiles).insert(effective);
      if (parentLink != null) {
        await insertDocumentationLink(
          documentationFileUuid: uuidValue,
          link: parentLink,
        );
      }
      return uuidValue;
    });
  }

  Future<List<DocumentationFile>> getDocumentationFiles({
    DocumentationGeofeatureLink? parentLink,
  }) async {
    if (parentLink == null) {
      return select(documentationFiles).get();
    }

    await _assertValidGeofeatureLink(parentLink);

    final rows = await (select(documentationFilesToGeofeatures)
          ..where(
            (t) =>
                t.geofeatureType.equals(parentLink.type.dbValue) &
                t.geofeatureUuid.equalsValue(parentLink.geofeatureUuid),
          ))
        .get();

    final documentUuids =
        rows.map((r) => r.documentationFileUuid).toSet().toList();
    if (documentUuids.isEmpty) return const <DocumentationFile>[];

    return (select(documentationFiles)
          ..where((t) => t.uuid.isInValues(documentUuids)))
        .get();
  }

  Future<void> deleteDocumentationFileByUuid(Uuid uuid) async {
    await transaction(() async {
      await (delete(documentationFilesToGeofeatures)
            ..where((t) => t.documentationFileUuid.equalsValue(uuid)))
          .go();
      await (delete(documentationFilesToCaveTrips)
            ..where((t) => t.documentationFileUuid.equalsValue(uuid)))
          .go();
      await (delete(documentationFiles)..where((t) => t.uuid.equalsValue(uuid)))
          .go();
    });
  }

  Future<void> updateDocumentationFile({
    required Uuid uuid,
    required DocumentationFilesCompanion companion,
  }) async {
    await (update(documentationFiles)..where((t) => t.uuid.equalsValue(uuid)))
        .write(companion);
  }

  Future<List<CavePlaceWithDefinition>>
      getCavePlacesWithDefinitionsForRasterMap(
          Uuid caveUuid, Uuid rasterMapUuid) async {
    final query = select(cavePlaces).join([
      leftOuterJoin(
        cavePlaceToRasterMapDefinitions,
        cavePlaceToRasterMapDefinitions.cavePlaceUuid
                .equalsExp(cavePlaces.uuid) &
            cavePlaceToRasterMapDefinitions.rasterMapUuid.equalsValue(rasterMapUuid),
      ),
    ])
      ..where(cavePlaces.caveUuid.equalsValue(caveUuid));

    return query.map((row) {
      final cavePlace = row.readTable(cavePlaces);
      final definition = row.readTableOrNull(cavePlaceToRasterMapDefinitions);
      return CavePlaceWithDefinition(cavePlace, definition);
    }).get();
  }

  Future<CavePlaceToRasterMapDefinition?> getDefinition(
      Uuid cavePlaceUuid, Uuid rasterMapUuid) async {
    return (select(cavePlaceToRasterMapDefinitions)
          ..where((d) =>
              d.cavePlaceUuid.equalsValue(cavePlaceUuid) &
              d.rasterMapUuid.equalsValue(rasterMapUuid)))
        .getSingleOrNull();
  }

  Future<void> populateTestData() async {
    await TestDataHelper.populateTestData(this);
  }

  Future<void> populateTestDataIfEmpty() async {
    final existing = await select(caves).get();
    if (existing.isEmpty) {
      await TestDataHelper.populateTestData(this);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final filePath = File(p.join(dbFolder.path, 'speleo_loc.sqlite'));
    return NativeDatabase.createInBackground(filePath, enableMigrations: true);
  });
}
