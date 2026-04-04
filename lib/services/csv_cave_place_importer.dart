import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:speleo_loc/data/source/database/app_database.dart';

/// Configuration for CSV cave place import.
class CSVImportConfig {
  /// If non-null, import is in single-cave mode for this cave id.
  final int? caveId;

  /// Column index for the cave name field, or null to skip.
  final int? caveNameColumn;

  /// Column index for the cave place name field, or null to skip.
  final int? cavePlaceNameColumn;

  /// Column index for the QR code identifier field, or null to skip.
  final int? qrCodeColumn;

  /// Column index for the cave area field, or null to skip.
  final int? caveAreaColumn;

  /// Maximum number of existing duplicate entries to preview before import.
  final int maxPreviewDuplicates;

  bool get isMultipleCaveMode => caveId == null;

  CSVImportConfig({
    this.caveId,
    this.caveNameColumn,
    this.cavePlaceNameColumn,
    this.qrCodeColumn,
    this.caveAreaColumn,
    this.maxPreviewDuplicates = 5,
  });
}

/// Represents one row parsed from CSV to be imported.
class CSVImportRow {
  final String? caveName;
  final String? cavePlaceName;
  final int? qrCode;
  final String? caveArea;

  CSVImportRow({this.caveName, this.cavePlaceName, this.qrCode, this.caveArea});

  @override
  String toString() =>
      'CSVImportRow(cave: $caveName, place: $cavePlaceName, qr: $qrCode, area: $caveArea)';
}

/// Represents an existing combination found in the database that matches a CSV row.
class ExistingMatch {
  final String caveName;
  final String cavePlaceName;
  final String? caveArea;
  final int? existingQrCode;

  ExistingMatch({
    required this.caveName,
    required this.cavePlaceName,
    this.caveArea,
    this.existingQrCode,
  });
}

/// Result of an import operation.
class CSVImportResult {
  final int cavesCreated;
  final int cavePlacesCreated;
  final int caveAreasCreated;
  final int qrCodesUpdated;

  CSVImportResult({
    required this.cavesCreated,
    required this.cavePlacesCreated,
    required this.caveAreasCreated,
    required this.qrCodesUpdated,
  });
}

/// Helper class for importing cave place data from CSV files.
class CSVCavePlaceImporter {
  final AppDatabase _database;

  CSVCavePlaceImporter(this._database);

  /// Parse a CSV string into a list of lists (rows x columns).
  /// Expects the first row to be headers.
  List<List<dynamic>> parseCSV(String csvContent) {
    final converter = const CsvToListConverter(eol: '\n', shouldParseNumbers: false);
    // Normalize line endings
    final normalized = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return converter.convert(normalized);
  }

  /// Extract header names from the first row of parsed CSV data.
  List<String> getHeaders(List<List<dynamic>> csvData) {
    if (csvData.isEmpty) return [];
    return csvData.first.map((e) => e.toString().trim()).toList();
  }

  /// Parse CSV rows according to the given config, skipping the header row.
  List<CSVImportRow> parseRows(List<List<dynamic>> csvData, CSVImportConfig config) {
    if (csvData.length < 2) return [];

    final rows = <CSVImportRow>[];
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty) continue;

      String? caveName;
      String? cavePlaceName;
      int? qrCode;
      String? caveArea;

      if (config.caveNameColumn != null && config.caveNameColumn! < row.length) {
        final val = row[config.caveNameColumn!].toString().trim();
        if (val.isNotEmpty) caveName = val;
      }

      if (config.cavePlaceNameColumn != null && config.cavePlaceNameColumn! < row.length) {
        final val = row[config.cavePlaceNameColumn!].toString().trim();
        if (val.isNotEmpty) cavePlaceName = val;
      }

      if (config.qrCodeColumn != null && config.qrCodeColumn! < row.length) {
        final val = row[config.qrCodeColumn!].toString().trim();
        if (val.isNotEmpty) qrCode = int.tryParse(val);
      }

      if (config.caveAreaColumn != null && config.caveAreaColumn! < row.length) {
        final val = row[config.caveAreaColumn!].toString().trim();
        if (val.isNotEmpty) caveArea = val;
      }

      // Skip rows with no place name
      if (cavePlaceName == null || cavePlaceName.isEmpty) continue;

      rows.add(CSVImportRow(
        caveName: caveName,
        cavePlaceName: cavePlaceName,
        qrCode: qrCode,
        caveArea: caveArea,
      ));
    }
    return rows;
  }

  /// Find existing combinations of (cave name, cave area, cave place) that already
  /// exist in the database, matching the CSV rows.
  /// In single-cave mode, only cave place name is matched within the specified cave.
  /// Returns the list of matches and the total count.
  Future<({List<ExistingMatch> matches, int totalCount})> findExistingCombinations(
    List<CSVImportRow> rows,
    CSVImportConfig config,
  ) async {
    final List<ExistingMatch> allMatches = [];

    if (config.isMultipleCaveMode) {
      // Multiple cave mode: match cave name + cave area + cave place
      final caves = await _database.select(_database.caves).get();
      final caveMap = {for (var c in caves) c.title.toLowerCase(): c};

      final areas = await _database.select(_database.caveAreas).get();
      // Map: caveId -> (areaTitle.lowercase -> CaveArea)
      final areaMap = <int, Map<String, CaveArea>>{};
      for (var a in areas) {
        areaMap.putIfAbsent(a.caveId, () => {});
        areaMap[a.caveId]![a.title.toLowerCase()] = a;
      }

      final places = await _database.select(_database.cavePlaces).get();
      // Map: caveId -> (placeTitle.lowercase -> list of CavePlace)
      final placeMap = <int, Map<String, List<CavePlace>>>{};
      for (var p in places) {
        placeMap.putIfAbsent(p.caveId, () => {});
        placeMap[p.caveId]!.putIfAbsent(p.title.toLowerCase(), () => []);
        placeMap[p.caveId]![p.title.toLowerCase()]!.add(p);
      }

      for (final row in rows) {
        if (row.caveName == null) continue;
        final cave = caveMap[row.caveName!.toLowerCase()];
        if (cave == null) continue;

        // Check area match if area column is mapped
        if (row.caveArea != null && config.caveAreaColumn != null) {
          final caveAreas = areaMap[cave.id];
          if (caveAreas != null && caveAreas.containsKey(row.caveArea!.toLowerCase())) {
            // area exists
          }
        }

        // Check place match
        final cavePlaces = placeMap[cave.id];
        if (cavePlaces != null && row.cavePlaceName != null) {
          final matchingPlaces = cavePlaces[row.cavePlaceName!.toLowerCase()];
          if (matchingPlaces != null && matchingPlaces.isNotEmpty) {
            for (final mp in matchingPlaces) {
              allMatches.add(ExistingMatch(
                caveName: cave.title,
                cavePlaceName: mp.title,
                caveArea: row.caveArea,
                existingQrCode: mp.placeQrCodeIdentifier,
              ));
            }
          }
        }
      }
    } else {
      // Single cave mode: match cave place within the specified cave
      final cavePlaces = await (_database.select(_database.cavePlaces)
            ..where((cp) => cp.caveId.equals(config.caveId!)))
          .get();
      final placeMap = <String, List<CavePlace>>{};
      for (var p in cavePlaces) {
        placeMap.putIfAbsent(p.title.toLowerCase(), () => []);
        placeMap[p.title.toLowerCase()]!.add(p);
      }

      // Get cave name for display
      final cave = await (_database.select(_database.caves)
            ..where((c) => c.id.equals(config.caveId!)))
          .getSingleOrNull();
      final caveName = cave?.title ?? '';

      for (final row in rows) {
        if (row.cavePlaceName == null) continue;
        final matchingPlaces = placeMap[row.cavePlaceName!.toLowerCase()];
        if (matchingPlaces != null && matchingPlaces.isNotEmpty) {
          for (final mp in matchingPlaces) {
            allMatches.add(ExistingMatch(
              caveName: caveName,
              cavePlaceName: mp.title,
              caveArea: row.caveArea,
              existingQrCode: mp.placeQrCodeIdentifier,
            ));
          }
        }
      }
    }

    return (matches: allMatches, totalCount: allMatches.length);
  }

  /// Find rows where the CSV has a QR code that already exists in the database
  /// on a *different* cave place or a matching place that already has a different QR.
  Future<List<ExistingMatch>> findQrCodeConflicts(
    List<CSVImportRow> rows,
    CSVImportConfig config,
  ) async {
    final conflicts = <ExistingMatch>[];
    if (config.qrCodeColumn == null) return conflicts;

    for (final row in rows) {
      if (row.qrCode == null) continue;
      final existing = await (_database.select(_database.cavePlaces)
            ..where((cp) => cp.placeQrCodeIdentifier.equals(row.qrCode!)))
          .getSingleOrNull();
      if (existing != null) {
        // Determine the cave name for display
        String caveName = '';
        final cave = await (_database.select(_database.caves)
              ..where((c) => c.id.equals(existing.caveId)))
            .getSingleOrNull();
        caveName = cave?.title ?? '';
        conflicts.add(ExistingMatch(
          caveName: caveName,
          cavePlaceName: existing.title,
          caveArea: null,
          existingQrCode: existing.placeQrCodeIdentifier,
        ));
      }
    }
    return conflicts;
  }

  /// Perform the actual import.
  /// [overwriteQr] — if true, existing QR codes will be overwritten.
  Future<CSVImportResult> importRows(
    List<CSVImportRow> rows,
    CSVImportConfig config, {
    bool overwriteQr = false,
  }) async {
    return _database.transaction(() async {
    int cavesCreated = 0;
    int cavePlacesCreated = 0;
    int caveAreasCreated = 0;
    int qrCodesUpdated = 0;

    // Caches to avoid duplicate DB lookups / inserts within one import
    final caveCache = <String, int>{}; // title.lower -> id
    final areaCache = <String, int>{}; // "caveId:areaTitle.lower" -> id

    // Pre-populate caches from DB
    final existingCaves = await _database.select(_database.caves).get();
    for (var c in existingCaves) {
      caveCache[c.title.toLowerCase()] = c.id;
    }
    final existingAreas = await _database.select(_database.caveAreas).get();
    for (var a in existingAreas) {
      areaCache['${a.caveId}:${a.title.toLowerCase()}'] = a.id;
    }

    for (final row in rows) {
      if (row.cavePlaceName == null || row.cavePlaceName!.isEmpty) continue;

      int? targetCaveId = config.caveId;

      // In multiple cave mode, resolve or create the cave
      if (config.isMultipleCaveMode) {
        if (row.caveName == null || row.caveName!.isEmpty) continue;
        final caveKey = row.caveName!.toLowerCase();
        if (caveCache.containsKey(caveKey)) {
          targetCaveId = caveCache[caveKey]!;
        } else {
          // Create new cave
          final newId = await _database.into(_database.caves).insert(
            CavesCompanion(
              title: Value(row.caveName!),
            ),
          );
          caveCache[caveKey] = newId;
          targetCaveId = newId;
          cavesCreated++;
        }
      }

      if (targetCaveId == null) continue;

      // Resolve or create cave area if mapped
      int? targetAreaId;
      if (row.caveArea != null && row.caveArea!.isNotEmpty) {
        final areaKey = '$targetCaveId:${row.caveArea!.toLowerCase()}';
        if (areaCache.containsKey(areaKey)) {
          targetAreaId = areaCache[areaKey]!;
        } else {
          final newId = await _database.into(_database.caveAreas).insert(
            CaveAreasCompanion(
              title: Value(row.caveArea!),
              caveId: Value(targetCaveId),
            ),
          );
          areaCache[areaKey] = newId;
          targetAreaId = newId;
          caveAreasCreated++;
        }
      }

      // Check if a cave place with same title already exists in this cave
      final existingPlace = await (_database.select(_database.cavePlaces)
            ..where((cp) =>
                cp.caveId.equals(targetCaveId!) &
                cp.title.equals(row.cavePlaceName!)))
          .getSingleOrNull();

      if (existingPlace != null) {
        // Update QR code if configured and allowed
        if (row.qrCode != null && config.qrCodeColumn != null) {
          if (existingPlace.placeQrCodeIdentifier != row.qrCode && overwriteQr) {
            await (_database.update(_database.cavePlaces)
                  ..where((cp) => cp.id.equals(existingPlace.id)))
                .write(CavePlacesCompanion(
              placeQrCodeIdentifier: Value(row.qrCode),
            ));
            qrCodesUpdated++;
          }
        }
        // Update area if mapped and not yet set
        if (targetAreaId != null && existingPlace.caveAreaId != targetAreaId) {
          await (_database.update(_database.cavePlaces)
                ..where((cp) => cp.id.equals(existingPlace.id)))
              .write(CavePlacesCompanion(
            caveAreaId: Value(targetAreaId),
          ));
        }
      } else {
        // Create new cave place
        await _database.into(_database.cavePlaces).insert(
          CavePlacesCompanion(
            title: Value(row.cavePlaceName!),
            caveId: Value(targetCaveId),
            caveAreaId: Value(targetAreaId),
            placeQrCodeIdentifier: Value(row.qrCode),
          ),
        );
        cavePlacesCreated++;
      }
    }

    return CSVImportResult(
      cavesCreated: cavesCreated,
      cavePlacesCreated: cavePlacesCreated,
      caveAreasCreated: caveAreasCreated,
      qrCodesUpdated: qrCodesUpdated,
    );
    }); // end transaction
  }
}
