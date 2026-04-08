import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/test_data_helper.dart';

part 'app_database.g.dart';

//?
// final appDatabase = AppDatabase();
AppDatabase appDatabase = AppDatabase();

/// Captures migration events performed while opening the database.
///
/// Restore flows can consume the latest event and write a dedicated log line.
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

  /// Returns and clears the latest migration event.
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
  final int geofeatureId;

  const DocumentationGeofeatureLink({
    required this.type,
    required this.geofeatureId,
  });
}

class CavePlaceWithDefinition {
  final CavePlace cavePlace;
  final CavePlaceToRasterMapDefinition? definition;

  CavePlaceWithDefinition(this.cavePlace, this.definition);
}

@DriftDatabase(
  // relative import for the drift file. Drift also supports `package:`
  // imports
  include: {'./tables.drift'},
)
class AppDatabase extends _$AppDatabase {
  // static final AppDatabase _instance = AppDatabase();
  // static AppDatabase instance() => _instance;

  AppDatabase() : super(_openConnection()) {
    // Populate test data asynchronously after the database is opened.
    // Schedule without awaiting so constructor remains synchronous.
    
    // Future(() async => await populateTestData());
  }

  @override
  int get schemaVersion => 4; // Schema version

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');

      // Use dynamic access so this remains robust across Drift versions.
      final dynamic d = details;
      int fromVersion = 0;
      int toVersion = schemaVersion;
      bool hadUpgrade = false;

      try {
        final dynamic v = d.versionBefore;
        if (v is int) fromVersion = v;
      } catch (_) {}

      try {
        final dynamic v = d.versionNow;
        if (v is int) toVersion = v;
      } catch (_) {}

      try {
        final dynamic v = d.hadUpgrade;
        if (v is bool) hadUpgrade = v;
      } catch (_) {}

      if (hadUpgrade || toVersion > fromVersion) {
        DatabaseMigrationMonitor.record(
          fromVersion: fromVersion,
          toVersion: toVersion,
        );
      }
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // Add depth_in_cave column to cave_places (introduced in schema v2).
        // The column is NUMERIC(7,2) and nullable, matching the drift definition.
        await customStatement(
          'ALTER TABLE cave_places ADD COLUMN depth_in_cave NUMERIC(7, 2)',
        );
      }

      if (from < 3) {
        await transaction(() async {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS documentation_files__new (
              id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
              title TEXT(50) NOT NULL,
              description TEXT,
              file_name TEXT(255) NOT NULL,
              file_size INTEGER NOT NULL,
              file_hash TEXT(64),
              file_type TEXT(25) NOT NULL,
              created_at INTEGER,
              updated_at INTEGER,
              deleted_at INTEGER,
              UNIQUE(title, file_name, file_size, file_hash) ON CONFLICT ROLLBACK
            )
          ''');

          await customStatement('''
            INSERT INTO documentation_files__new
              (id, title, description, file_name, file_size, file_hash, file_type, created_at, updated_at, deleted_at)
            SELECT
              id, title, description, file_name, COALESCE(file_size, 0), file_hash, 'unknown', created_at, updated_at, deleted_at
            FROM documentation_files
          ''');

          await customStatement('''
            CREATE TABLE IF NOT EXISTS documentation_files_to_geofeatures (
              id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
              geofeature_id INTEGER,
              geofeature_type TEXT(10) NOT NULL,
              documentation_file_id INTEGER NOT NULL REFERENCES documentation_files(id),
              updated_at INTEGER,
              deleted_at INTEGER,
              UNIQUE(geofeature_id, geofeature_type, documentation_file_id) ON CONFLICT ROLLBACK
            )
          ''');

          await customStatement('''
            INSERT INTO documentation_files_to_geofeatures
              (geofeature_id, geofeature_type, documentation_file_id, updated_at, deleted_at)
            SELECT cave_id, 'cave', id, updated_at, deleted_at
            FROM documentation_files
            WHERE cave_id IS NOT NULL
          ''');

          await customStatement('''
            INSERT INTO documentation_files_to_geofeatures
              (geofeature_id, geofeature_type, documentation_file_id, updated_at, deleted_at)
            SELECT cave_place_id, 'cave_place', id, updated_at, deleted_at
            FROM documentation_files
            WHERE cave_place_id IS NOT NULL
          ''');

          await customStatement('''
            INSERT INTO documentation_files_to_geofeatures
              (geofeature_id, geofeature_type, documentation_file_id, updated_at, deleted_at)
            SELECT cave_area_id, 'cave_area', id, updated_at, deleted_at
            FROM documentation_files
            WHERE cave_area_id IS NOT NULL
          ''');

          await customStatement('DROP TABLE documentation_files');
          await customStatement('ALTER TABLE documentation_files__new RENAME TO documentation_files');
        });
      }

      if (from < 4) {
        await customStatement('''
          CREATE TABLE IF NOT EXISTS cave_trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
            cave_id INTEGER NOT NULL REFERENCES caves (id),
            title TEXT(255) NOT NULL,
            description TEXT,
            trip_started_at INTEGER NOT NULL,
            trip_ended_at INTEGER,
            created_at INTEGER,
            updated_at INTEGER,
            deleted_at INTEGER
          )
        ''');

        await customStatement('''
          CREATE TABLE IF NOT EXISTS cave_trip_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
            cave_trip_id INTEGER NOT NULL REFERENCES cave_trips (id),
            cave_place_id INTEGER NOT NULL REFERENCES cave_places (id),
            scanned_at INTEGER NOT NULL,
            notes TEXT,
            created_at INTEGER,
            updated_at INTEGER,
            deleted_at INTEGER,
            UNIQUE(cave_trip_id, cave_place_id, scanned_at) ON CONFLICT ROLLBACK
          )
        ''');

        await customStatement('''
          CREATE TABLE IF NOT EXISTS documentation_files_to_cave_trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
            documentation_file_id INTEGER NOT NULL REFERENCES documentation_files (id),
            cave_trip_id INTEGER NOT NULL REFERENCES cave_trips (id),
            created_at INTEGER,
            deleted_at INTEGER,
            UNIQUE(documentation_file_id, cave_trip_id) ON CONFLICT ROLLBACK
          )
        ''');
      }
    },
  );

  // Cave trips
  Future<int> insertCaveTrip({
    required int caveId,
    required String title,
    String? description,
    required int startedAt,
  }) async {
    return into(caveTrips).insert(
      CaveTripsCompanion.insert(
        caveId: caveId,
        title: title,
        description: Value(description),
        tripStartedAt: startedAt,
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> endCaveTrip(int tripId) async {
    await (update(caveTrips)..where((t) => t.id.equals(tripId))).write(
      CaveTripsCompanion(
        tripEndedAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<CaveTrip?> getActiveTripForCave(int caveId) async {
    return (select(caveTrips)
      ..where((t) => t.caveId.equals(caveId) & t.tripEndedAt.isNull())
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

  Future<int> insertTripPoint({
    required int tripId,
    required int cavePlaceId,
    String? notes,
  }) async {
    return into(caveTripPoints).insert(
      CaveTripPointsCompanion.insert(
        caveTripId: tripId,
        cavePlaceId: cavePlaceId,
        scannedAt: DateTime.now().millisecondsSinceEpoch,
        notes: Value(notes),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<List<CaveTripPoint>> getTripPoints(int tripId) async {
    return (select(caveTripPoints)
      ..where((t) => t.caveTripId.equals(tripId))
      ..orderBy([(t) => OrderingTerm.asc(t.scannedAt)]))
        .get();
  }

  Future<List<CaveTrip>> getCaveTrips(int caveId) async {
    return (select(caveTrips)
      ..where((t) => t.caveId.equals(caveId))
      ..orderBy([(t) => OrderingTerm.desc(t.tripStartedAt)]))
        .get();
  }

  Future<void> linkDocumentToTrip(int docId, int tripId) async {
    await into(documentationFilesToCaveTrips).insertOnConflictUpdate(
      DocumentationFilesToCaveTripsCompanion.insert(
        documentationFileId: docId,
        caveTripId: tripId,
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> deleteCaveTrip(int tripId) async {
    await transaction(() async {
      await (delete(documentationFilesToCaveTrips)
        ..where((t) => t.caveTripId.equals(tripId))).go();
      await (delete(caveTripPoints)
        ..where((t) => t.caveTripId.equals(tripId))).go();
      await (delete(caveTrips)..where((t) => t.id.equals(tripId))).go();
    });
  }

  Future<bool> _geofeatureExists(GeofeatureType type, int geofeatureId) async {
    switch (type) {
      case GeofeatureType.cave:
        final cave = await (select(caves)..where((t) => t.id.equals(geofeatureId))).getSingleOrNull();
        return cave != null;
      case GeofeatureType.cavePlace:
        final cavePlace = await (select(cavePlaces)..where((t) => t.id.equals(geofeatureId))).getSingleOrNull();
        return cavePlace != null;
      case GeofeatureType.caveArea:
        final caveArea = await (select(caveAreas)..where((t) => t.id.equals(geofeatureId))).getSingleOrNull();
        return caveArea != null;
    }
  }

  Future<void> _assertValidGeofeatureLink(DocumentationGeofeatureLink link) async {
    final exists = await _geofeatureExists(link.type, link.geofeatureId);
    if (!exists) {
      throw StateError('Invalid geofeature link: ${link.type.dbValue}(${link.geofeatureId}) does not exist.');
    }
  }

  Future<DocumentationGeofeatureLink?> getDocumentationParentLink({
    int? caveId,
    int? cavePlaceId,
    int? caveAreaId,
  }) async {
    final provided = [caveId, cavePlaceId, caveAreaId].where((v) => v != null).length;
    if (provided == 0) return null;
    if (provided > 1) {
      throw ArgumentError('Only one of caveId, cavePlaceId, caveAreaId can be provided.');
    }

    if (caveId != null) {
      return DocumentationGeofeatureLink(type: GeofeatureType.cave, geofeatureId: caveId);
    }
    if (cavePlaceId != null) {
      return DocumentationGeofeatureLink(type: GeofeatureType.cavePlace, geofeatureId: cavePlaceId);
    }
    return DocumentationGeofeatureLink(type: GeofeatureType.caveArea, geofeatureId: caveAreaId!);
  }

  Future<void> insertDocumentationLink({
    required int documentationFileId,
    required DocumentationGeofeatureLink link,
  }) async {
    await _assertValidGeofeatureLink(link);

    // UNIQUE(geofeature_id, geofeature_type, documentation_file_id) ON CONFLICT ROLLBACK
    // prevents duplicates at the DB level.
    await into(documentationFilesToGeofeatures).insert(
      DocumentationFilesToGeofeaturesCompanion.insert(
        geofeatureType: link.type.dbValue,
        documentationFileId: documentationFileId,
        geofeatureId: Value(link.geofeatureId),
      ),
    );
  }

  Future<int> insertDocumentationFile({
    required DocumentationFilesCompanion companion,
    DocumentationGeofeatureLink? parentLink,
  }) async {
    return transaction(() async {
      final docId = await into(documentationFiles).insert(companion);
      if (parentLink != null) {
        await insertDocumentationLink(
          documentationFileId: docId,
          link: parentLink,
        );
      }
      return docId;
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
            t.geofeatureId.equals(parentLink.geofeatureId),
      )).get();

    final documentIds = rows.map((r) => r.documentationFileId).toSet().toList();
    if (documentIds.isEmpty) return const <DocumentationFile>[];

    return (select(documentationFiles)..where((t) => t.id.isIn(documentIds))).get();
  }

  Future<void> deleteDocumentationFileById(int id) async {
    await transaction(() async {
      await (delete(documentationFilesToGeofeatures)
        ..where((t) => t.documentationFileId.equals(id))).go();
      await (delete(documentationFiles)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Updates an existing documentation file record (title, file metadata, etc.).
  Future<void> updateDocumentationFile({
    required int id,
    required DocumentationFilesCompanion companion,
  }) async {
    await (update(documentationFiles)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<List<CavePlaceWithDefinition>> getCavePlacesWithDefinitionsForRasterMap(int caveId, int rasterMapId) async {
    final query = select(cavePlaces).join([
      leftOuterJoin(cavePlaceToRasterMapDefinitions, cavePlaceToRasterMapDefinitions.cavePlaceId.equalsExp(cavePlaces.id) & cavePlaceToRasterMapDefinitions.rasterMapId.equals(rasterMapId)),
    ])..where(cavePlaces.caveId.equals(caveId));

    return query.map((row) {
      final cavePlace = row.readTable(cavePlaces);
      final definition = row.readTableOrNull(cavePlaceToRasterMapDefinitions);
      return CavePlaceWithDefinition(cavePlace, definition);
    }).get();
  }

  Future<CavePlaceToRasterMapDefinition?> getDefinition(int cavePlaceId, int rasterMapId) async {
    return (select(cavePlaceToRasterMapDefinitions)..where((d) => d.cavePlaceId.equals(cavePlaceId) & d.rasterMapId.equals(rasterMapId))).getSingleOrNull();
  }

  Future<void> populateTestData() async {
    await TestDataHelper.populateTestData(this);
  }

  Future<void> populateTestDataIfEmpty() async {
    final caves = await select(this.caves).get();
    if (caves.isEmpty) {
      await TestDataHelper.populateTestData(this);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final filePath = File(p.join(dbFolder.path, 'speleo_loc.sqlite'));
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    
    // // Also work around limitations on old Android versions
    // if (Platform.isAndroid) {
    //   await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    // }

    // // Make sqlite3 pick a more suitable location for temporary files - the
    // // one from the system may be inaccessible due to sandboxing.
    // final cachebase = (await getTemporaryDirectory()).path;
    // // We can't access /tmp on Android, which sqlite3 would try by default.
    // // Explicitly tell it about the correct temporary directory.
    // sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(filePath, enableMigrations: true);
  });
}