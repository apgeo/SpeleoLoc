import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// Configuration for CSV cave import.
class CSVCavesImportConfig {
  /// Column index for the cave name field, or null to skip.
  final int? caveNameColumn;

  /// Column index for the description field, or null to skip.
  final int? descriptionColumn;

  /// Column index for the surface area field, or null to skip.
  final int? surfaceAreaColumn;

  /// Maximum number of existing duplicate entries to preview before import.
  final int maxPreviewDuplicates;

  CSVCavesImportConfig({
    this.caveNameColumn,
    this.descriptionColumn,
    this.surfaceAreaColumn,
    this.maxPreviewDuplicates = 5,
  });
}

/// Represents one row parsed from CSV to be imported.
class CSVCaveImportRow {
  final String? caveName;
  final String? description;
  final String? surfaceArea;

  CSVCaveImportRow({this.caveName, this.description, this.surfaceArea});

  @override
  String toString() =>
      'CSVCaveImportRow(cave: $caveName, desc: $description, area: $surfaceArea)';
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

  CSVCaveImporter(this._database);

  /// Parse CSV rows according to the given config, skipping the header row.
  List<CSVCaveImportRow> parseRows(List<List<dynamic>> csvData, CSVCavesImportConfig config) {
    if (csvData.length < 2) return [];

    final rows = <CSVCaveImportRow>[];
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty) continue;

      String? caveName;
      String? description;
      String? surfaceArea;

      if (config.caveNameColumn != null && config.caveNameColumn! < row.length) {
        final val = row[config.caveNameColumn!].toString().trim();
        if (val.isNotEmpty) caveName = val;
      }

      if (config.descriptionColumn != null && config.descriptionColumn! < row.length) {
        final val = row[config.descriptionColumn!].toString().trim();
        if (val.isNotEmpty) description = val;
      }

      if (config.surfaceAreaColumn != null && config.surfaceAreaColumn! < row.length) {
        final val = row[config.surfaceAreaColumn!].toString().trim();
        if (val.isNotEmpty) surfaceArea = val;
      }

      // Skip rows with no cave name
      if (caveName == null || caveName.isEmpty) continue;

      rows.add(CSVCaveImportRow(
        caveName: caveName,
        description: description,
        surfaceArea: surfaceArea,
      ));
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
    final surfaceAreaMap = {for (var s in surfaceAreas) s.id: s.title};

    // Build lookup: "title.lower|surfaceAreaTitle.lower" -> exists
    final caveSet = <String>{};
    for (var c in caves) {
      final saTitle = c.surfaceAreaId != null
          ? surfaceAreaMap[c.surfaceAreaId]?.toLowerCase()
          : null;
      final key = '${c.title.toLowerCase()}|${saTitle ?? ''}';
      caveSet.add(key);
    }

    for (final row in rows) {
      if (row.caveName == null) continue;
      final saKey = row.surfaceArea?.toLowerCase() ?? '';
      final key = '${row.caveName!.toLowerCase()}|$saKey';
      if (caveSet.contains(key)) {
        allMatches.add(CaveExistingMatch(
          caveName: row.caveName!,
          surfaceArea: row.surfaceArea,
        ));
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
      final surfaceAreaCache = <String, int>{}; // title.lower -> id
      final existingSAs = await _database.select(_database.surfaceAreas).get();
      for (var s in existingSAs) {
        surfaceAreaCache[s.title.toLowerCase()] = s.id;
      }

      final caveCache = <String, int>{}; // "title.lower|saId" -> id
      final existingCaves = await _database.select(_database.caves).get();
      for (var c in existingCaves) {
        final key = '${c.title.toLowerCase()}|${c.surfaceAreaId ?? ''}';
        caveCache[key] = c.id;
      }

      for (final row in rows) {
        if (row.caveName == null || row.caveName!.isEmpty) continue;

        // Resolve surface area
        int? surfaceAreaId;
        if (row.surfaceArea != null && row.surfaceArea!.isNotEmpty) {
          final saKey = row.surfaceArea!.toLowerCase();
          if (surfaceAreaCache.containsKey(saKey)) {
            surfaceAreaId = surfaceAreaCache[saKey]!;
          } else {
            final newId = await _database.into(_database.surfaceAreas).insert(
              SurfaceAreasCompanion(title: Value(row.surfaceArea!)),
            );
            surfaceAreaCache[saKey] = newId;
            surfaceAreaId = newId;
            surfaceAreasCreated++;
          }
        }

        // Check if cave already exists (title + surface_area_id is unique)
        final caveKey = '${row.caveName!.toLowerCase()}|${surfaceAreaId ?? ''}';
        if (caveCache.containsKey(caveKey)) {
          // Update description if provided and cave exists
          if (row.description != null && row.description!.isNotEmpty) {
            await (_database.update(_database.caves)
                  ..where((c) => c.id.equals(caveCache[caveKey]!)))
                .write(CavesCompanion(description: Value(row.description)));
          }
          skippedDuplicates++;
          continue;
        }

        // Create new cave
        final newId = await _database.into(_database.caves).insert(
          CavesCompanion(
            title: Value(row.caveName!),
            description: Value(row.description),
            surfaceAreaId: Value(surfaceAreaId),
          ),
        );
        caveCache[caveKey] = newId;
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
