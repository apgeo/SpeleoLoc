import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speleo_loc/data/source/database/test_data_helper.dart';

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
  int get schemaVersion => 3; // Schema version

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
    },
  );

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