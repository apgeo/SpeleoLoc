import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/utils/clock.dart';

/// Configuration for CSV cave import.
class CSVCavesImportConfig {
  /// Column index for the cave name field, or null to skip.
  final int? caveNameColumn;

  /// Column index for the description field, or null to skip.
  final int? descriptionColumn;

  /// Column index for the cave local index field, or null to skip.
  final int? caveLocalIndexColumn;

  /// Column index for the surface area field, or null to skip.
  final int? surfaceAreaColumn;

  /// Column index for the general area identifier field, or null to skip.
  /// Resolves the cave's surface area by `general_area_identifier`.
  final int? generalAreaIdentifierColumn;

  /// Maximum number of existing duplicate entries to preview before import.
  final int maxPreviewDuplicates;

  CSVCavesImportConfig({
    this.caveNameColumn,
    this.descriptionColumn,
    this.caveLocalIndexColumn,
    this.surfaceAreaColumn,
    this.generalAreaIdentifierColumn,
    this.maxPreviewDuplicates = 5,
  });
}

/// Represents one row parsed from CSV to be imported.
class CSVCaveImportRow {
  final String? caveName;
  final String? description;
  final String? caveLocalIndex;
  final String? surfaceArea;
  final String? generalAreaIdentifier;

  CSVCaveImportRow({
    this.caveName,
    this.description,
    this.caveLocalIndex,
    this.surfaceArea,
    this.generalAreaIdentifier,
  });

  @override
  String toString() =>
      'CSVCaveImportRow(cave: $caveName, desc: $description, '
      'localIndex: $caveLocalIndex, area: $surfaceArea, '
      'areaIdentifier: $generalAreaIdentifier)';
}

/// Represents an existing cave found in the database that matches a CSV row.
class CaveExistingMatch {
  final String caveName;
  final String? surfaceArea;

  CaveExistingMatch({required this.caveName, this.surfaceArea});
}

/// Result of a cave import operation.
class CSVCaveImportResult {
  final int cavesCreated;
  final int surfaceAreasCreated;
  final int skippedDuplicates;

  CSVCaveImportResult({
    required this.cavesCreated,
    required this.surfaceAreasCreated,
    required this.skippedDuplicates,
  });
}

/// Helper class for importing cave data from CSV files.
class CSVCaveImporter {
  final AppDatabase _database;
  final CurrentUserService _currentUser;
  final Clock _clock;

  CSVCaveImporter(
    this._database,
    this._currentUser, {
    Clock clock = const SystemClock(),
  }) : _clock = clock;

  /// Parse CSV rows according to the given config, skipping the header row.
  List<CSVCaveImportRow> parseRows(
    List<List<dynamic>> csvData,
    CSVCavesImportConfig config,
  ) {
    if (csvData.length < 2) return [];

    final rows = <CSVCaveImportRow>[];
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty) continue;

      String? cell(int? column) {
        if (column == null || column >= row.length) return null;
        final val = row[column].toString().trim();
        return val.isEmpty ? null : val;
      }

      final caveName = cell(config.caveNameColumn);

      // Skip rows with no cave name
      if (caveName == null) continue;

      rows.add(
        CSVCaveImportRow(
          caveName: caveName,
          description: cell(config.descriptionColumn),
          caveLocalIndex: cell(config.caveLocalIndexColumn),
          surfaceArea: cell(config.surfaceAreaColumn),
          generalAreaIdentifier: cell(config.generalAreaIdentifierColumn),
        ),
      );
    }
    return rows;
  }

  /// Find existing caves that match the CSV rows by title and surface area.
  /// The caves table has UNIQUE(title, surface_area_id).
  Future<({List<CaveExistingMatch> matches, int totalCount})> findExistingCaves(
    List<CSVCaveImportRow> rows,
    CSVCavesImportConfig config,
  ) async {
    final allMatches = <CaveExistingMatch>[];

    final caves = await _database.select(_database.caves).get();
    final surfaceAreas = await _database.select(_database.surfaceAreas).get();
    final surfaceAreaMap = {for (var s in surfaceAreas) s.uuid: s.title};
    final titleByIdentifier = <String, String>{};
    for (var s in surfaceAreas) {
      final identifier = s.generalAreaIdentifier;
      if (identifier != null && identifier.isNotEmpty) {
        titleByIdentifier[identifier] = s.title;
      }
    }

    // Build lookup: "title.lower|surfaceAreaTitle.lower" -> exists
    final caveSet = <String>{};
    for (var c in caves) {
      final saTitle = c.surfaceAreaUuid != null
          ? surfaceAreaMap[c.surfaceAreaUuid]?.toLowerCase()
          : null;
      final key = '${c.title.toLowerCase()}|${saTitle ?? ''}';
      caveSet.add(key);
    }

    for (final row in rows) {
      if (row.caveName == null) continue;
      // Mirror the import-time resolution: general area identifier match
      // first, then the title (the identifier doubles as title when no
      // title is given).
      final identifiedTitle = row.generalAreaIdentifier != null
          ? titleByIdentifier[row.generalAreaIdentifier!]
          : null;
      final saTitle =
          identifiedTitle ?? row.surfaceArea ?? row.generalAreaIdentifier;
      final key = '${row.caveName!.toLowerCase()}|${saTitle?.toLowerCase() ?? ''}';
      if (caveSet.contains(key)) {
        allMatches.add(
          CaveExistingMatch(caveName: row.caveName!, surfaceArea: saTitle),
        );
      }
    }

    return (matches: allMatches, totalCount: allMatches.length);
  }

  /// Perform the actual import.
  Future<CSVCaveImportResult> importRows(
    List<CSVCaveImportRow> rows,
    CSVCavesImportConfig config,
  ) async {
    return _database.transaction(() async {
      int cavesCreated = 0;
      int surfaceAreasCreated = 0;
      int skippedDuplicates = 0;

      // Cache existing data
      final surfaceAreaCache = <String, Uuid>{}; // title.lower -> uuid
      final identifierCache = <String, Uuid>{}; // general_area_identifier -> uuid
      final identifierByUuid = <Uuid, String>{}; // uuid -> non-empty identifier
      final existingSAs = await _database.select(_database.surfaceAreas).get();
      for (var s in existingSAs) {
        surfaceAreaCache[s.title.toLowerCase()] = s.uuid;
        final identifier = s.generalAreaIdentifier;
        if (identifier != null && identifier.isNotEmpty) {
          identifierCache[identifier] = s.uuid;
          identifierByUuid[s.uuid] = identifier;
        }
      }

      final caveCache = <String, Uuid>{}; // "title.lower|saUuid" -> uuid
      final existingCaves = await _database.select(_database.caves).get();
      for (var c in existingCaves) {
        final key = '${c.title.toLowerCase()}|${c.surfaceAreaUuid ?? ''}';
        caveCache[key] = c.uuid;
      }

      // Resolve the row's surface area to a uuid, creating the area when
      // needed: an existing area matched by general_area_identifier wins,
      // then one matched by title (backfilling its identifier when it has
      // none), otherwise a new area is created. The identifier doubles as
      // the title when no title is given.
      Future<Uuid?> resolveSurfaceArea(
        CSVCaveImportRow row,
        int now,
        Uuid author,
      ) async {
        final identifier = row.generalAreaIdentifier;
        final title = row.surfaceArea;
        if (identifier == null && title == null) return null;

        if (identifier != null) {
          final byIdentifier = identifierCache[identifier];
          if (byIdentifier != null) return byIdentifier;
        }

        final effectiveTitle = title ?? identifier!;
        final titleKey = effectiveTitle.toLowerCase();
        final byTitle = surfaceAreaCache[titleKey];
        if (byTitle != null) {
          // Never overwrite a differing identifier on an existing area.
          if (identifier != null && !identifierByUuid.containsKey(byTitle)) {
            await (_database.update(
              _database.surfaceAreas,
            )..where((s) => s.uuid.equalsValue(byTitle))).write(
              SurfaceAreasCompanion(
                generalAreaIdentifier: Value(identifier),
                updatedAt: Value(now),
                lastModifiedByUserUuid: Value(author),
              ),
            );
            identifierCache[identifier] = byTitle;
            identifierByUuid[byTitle] = identifier;
          }
          return byTitle;
        }

        final newUuid = Uuid.v7();
        await _database
            .into(_database.surfaceAreas)
            .insert(
              SurfaceAreasCompanion.insert(
                uuid: newUuid,
                title: effectiveTitle,
                generalAreaIdentifier: Value(identifier),
                createdAt: Value(now),
                updatedAt: Value(now),
                createdByUserUuid: Value(author),
                lastModifiedByUserUuid: Value(author),
              ),
            );
        surfaceAreaCache[titleKey] = newUuid;
        if (identifier != null) {
          identifierCache[identifier] = newUuid;
          identifierByUuid[newUuid] = identifier;
        }
        surfaceAreasCreated++;
        return newUuid;
      }

      for (final row in rows) {
        if (row.caveName == null || row.caveName!.isEmpty) continue;

        final now = _clock.nowMs();
        final author = await _currentUser.currentOrSystem();

        final surfaceAreaUuid = await resolveSurfaceArea(row, now, author);

        // Check if cave already exists (title + surface_area_uuid is unique)
        final caveKey =
            '${row.caveName!.toLowerCase()}|${surfaceAreaUuid ?? ''}';
        if (caveCache.containsKey(caveKey)) {
          // Update description / local index if provided and cave exists
          if (row.description != null || row.caveLocalIndex != null) {
            await (_database.update(
              _database.caves,
            )..where((c) => c.uuid.equalsValue(caveCache[caveKey]!))).write(
              CavesCompanion(
                description: row.description != null
                    ? Value(row.description)
                    : const Value.absent(),
                caveLocalIndex: row.caveLocalIndex != null
                    ? Value(row.caveLocalIndex)
                    : const Value.absent(),
                updatedAt: Value(now),
                lastModifiedByUserUuid: Value(author),
              ),
            );
          }
          skippedDuplicates++;
          continue;
        }

        // Create new cave
        final newUuid = Uuid.v7();
        await _database
            .into(_database.caves)
            .insert(
              CavesCompanion.insert(
                uuid: newUuid,
                title: row.caveName!,
                description: Value(row.description),
                caveLocalIndex: Value(row.caveLocalIndex),
                surfaceAreaUuid: Value(surfaceAreaUuid),
                createdAt: Value(now),
                updatedAt: Value(now),
                createdByUserUuid: Value(author),
                lastModifiedByUserUuid: Value(author),
              ),
            );
        caveCache[caveKey] = newUuid;
        cavesCreated++;
      }

      return CSVCaveImportResult(
        cavesCreated: cavesCreated,
        surfaceAreasCreated: surfaceAreasCreated,
        skippedDuplicates: skippedDuplicates,
      );
    }); // end transaction
  }
}
