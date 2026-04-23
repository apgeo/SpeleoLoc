import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// Configuration for CSV cave place import.
class CSVCavePlacesImportConfig {
  /// If non-null, import is in single-cave mode for this cave id.
  final Uuid? caveUuid;

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

  bool get isMultipleCaveMode => caveUuid == null;

  CSVCavePlacesImportConfig({
    this.caveUuid,
    this.caveNameColumn,
    this.cavePlaceNameColumn,
    this.qrCodeColumn,
    this.caveAreaColumn,
    this.maxPreviewDuplicates = 5,
  });
}

/// Represents one row parsed from CSV to be imported.
class CSVCavePlaceImportRow {
  final String? caveName;
  final String? cavePlaceName;
  final int? qrCode;
  final String? caveArea;

  CSVCavePlaceImportRow({this.caveName, this.cavePlaceName, this.qrCode, this.caveArea});

  @override
  String toString() =>
      'CSVImportRow(cave: $caveName, place: $cavePlaceName, qr: $qrCode, area: $caveArea)';
}

/// Represents an existing combination found in the database that matches a CSV row.
class CavePlaceExistingMatch {
  final String caveName;
  final String cavePlaceName;
  final String? caveArea;
  final int? existingQrCode;

  CavePlaceExistingMatch({
    required this.caveName,
    required this.cavePlaceName,
    this.caveArea,
    this.existingQrCode,
  });
}

/// Result of an import operation.
class CSVCavePlaceImportResult {
  final int cavesCreated;
  final int cavePlacesCreated;
  final int caveAreasCreated;
  final int qrCodesUpdated;

  CSVCavePlaceImportResult({
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
  List<CSVCavePlaceImportRow> parseRows(List<List<dynamic>> csvData, CSVCavePlacesImportConfig config) {
    if (csvData.length < 2) return [];

    final rows = <CSVCavePlaceImportRow>[];
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

      rows.add(CSVCavePlaceImportRow(
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
  Future<({List<CavePlaceExistingMatch> matches, int totalCount})> findExistingCombinations(
    List<CSVCavePlaceImportRow> rows,
    CSVCavePlacesImportConfig config,
  ) async {
    final List<CavePlaceExistingMatch> allMatches = [];

    if (config.isMultipleCaveMode) {
      // Multiple cave mode: match cave name + cave area + cave place
      final caves = await _database.select(_database.caves).get();
      final caveMap = {for (var c in caves) c.title.toLowerCase(): c};

      final areas = await _database.select(_database.caveAreas).get();
      // Map: caveUuid -> (areaTitle.lowercase -> CaveArea)
      final areaMap = <Uuid, Map<String, CaveArea>>{};
      for (var a in areas) {
        areaMap.putIfAbsent(a.caveUuid, () => {});
        areaMap[a.caveUuid]![a.title.toLowerCase()] = a;
      }

      final places = await _database.select(_database.cavePlaces).get();
      // Map: caveUuid -> (placeTitle.lowercase -> list of CavePlace)
      final placeMap = <Uuid, Map<String, List<CavePlace>>>{};
      for (var p in places) {
        placeMap.putIfAbsent(p.caveUuid, () => {});
        placeMap[p.caveUuid]!.putIfAbsent(p.title.toLowerCase(), () => []);
        placeMap[p.caveUuid]![p.title.toLowerCase()]!.add(p);
      }

      for (final row in rows) {
        if (row.caveName == null) continue;
        final cave = caveMap[row.caveName!.toLowerCase()];
        if (cave == null) continue;

        // Check area match if area column is mapped
        if (row.caveArea != null && config.caveAreaColumn != null) {
          final caveAreas = areaMap[cave.uuid];
          if (caveAreas != null && caveAreas.containsKey(row.caveArea!.toLowerCase())) {
            // area exists
          }
        }

        // Check place match
        final cavePlaces = placeMap[cave.uuid];
        if (cavePlaces != null && row.cavePlaceName != null) {
          final matchingPlaces = cavePlaces[row.cavePlaceName!.toLowerCase()];
          if (matchingPlaces != null && matchingPlaces.isNotEmpty) {
            for (final mp in matchingPlaces) {
              allMatches.add(CavePlaceExistingMatch(
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
            ..where((cp) => cp.caveUuid.equalsValue(config.caveUuid!)))
          .get();
      final placeMap = <String, List<CavePlace>>{};
      for (var p in cavePlaces) {
        placeMap.putIfAbsent(p.title.toLowerCase(), () => []);
        placeMap[p.title.toLowerCase()]!.add(p);
      }

      // Get cave name for display
      final cave = await (_database.select(_database.caves)
            ..where((c) => c.uuid.equalsValue(config.caveUuid!)))
          .getSingleOrNull();
      final caveName = cave?.title ?? '';

      for (final row in rows) {
        if (row.cavePlaceName == null) continue;
        final matchingPlaces = placeMap[row.cavePlaceName!.toLowerCase()];
        if (matchingPlaces != null && matchingPlaces.isNotEmpty) {
          for (final mp in matchingPlaces) {
            allMatches.add(CavePlaceExistingMatch(
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
  Future<List<CavePlaceExistingMatch>> findQrCodeConflicts(
    List<CSVCavePlaceImportRow> rows,
    CSVCavePlacesImportConfig config,
  ) async {
    final conflicts = <CavePlaceExistingMatch>[];
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
              ..where((c) => c.uuid.equalsValue(existing.caveUuid)))
            .getSingleOrNull();
        caveName = cave?.title ?? '';
        conflicts.add(CavePlaceExistingMatch(
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
  Future<CSVCavePlaceImportResult> importRows(
    List<CSVCavePlaceImportRow> rows,
    CSVCavePlacesImportConfig config, {
    bool overwriteQr = false,
  }) async {
    return _database.transaction(() async {
    int cavesCreated = 0;
    int cavePlacesCreated = 0;
    int caveAreasCreated = 0;
    int qrCodesUpdated = 0;

    // Caches to avoid duplicate DB lookups / inserts within one import
    final caveCache = <String, Uuid>{}; // title.lower -> uuid
    final areaCache = <String, Uuid>{}; // "caveUuid:areaTitle.lower" -> uuid

    // Pre-populate caches from DB
    final existingCaves = await _database.select(_database.caves).get();
    for (var c in existingCaves) {
      caveCache[c.title.toLowerCase()] = c.uuid;
    }
    final existingAreas = await _database.select(_database.caveAreas).get();
    for (var a in existingAreas) {
      areaCache['${a.caveUuid}:${a.title.toLowerCase()}'] = a.uuid;
    }

    for (final row in rows) {
      if (row.cavePlaceName == null || row.cavePlaceName!.isEmpty) continue;

      Uuid? targetCaveUuid = config.caveUuid;

      // In multiple cave mode, resolve or create the cave
      if (config.isMultipleCaveMode) {
        if (row.caveName == null || row.caveName!.isEmpty) continue;
        final caveKey = row.caveName!.toLowerCase();
        if (caveCache.containsKey(caveKey)) {
          targetCaveUuid = caveCache[caveKey]!;
        } else {
          // Create new cave
          final newUuid = Uuid.v7();
          await _database.into(_database.caves).insert(
                CavesCompanion.insert(
                  uuid: newUuid,
                  title: row.caveName!,
                ),
              );
          caveCache[caveKey] = newUuid;
          targetCaveUuid = newUuid;
          cavesCreated++;
        }
      }

      if (targetCaveUuid == null) continue;

      // Resolve or create cave area if mapped
      Uuid? targetAreaUuid;
      if (row.caveArea != null && row.caveArea!.isNotEmpty) {
        final areaKey = '$targetCaveUuid:${row.caveArea!.toLowerCase()}';
        if (areaCache.containsKey(areaKey)) {
          targetAreaUuid = areaCache[areaKey]!;
        } else {
          final newUuid = Uuid.v7();
          await _database.into(_database.caveAreas).insert(
                CaveAreasCompanion.insert(
                  uuid: newUuid,
                  title: row.caveArea!,
                  caveUuid: targetCaveUuid,
                ),
              );
          areaCache[areaKey] = newUuid;
          targetAreaUuid = newUuid;
          caveAreasCreated++;
        }
      }

      // Check if a cave place with same title already exists in this cave
      final existingPlace = await (_database.select(_database.cavePlaces)
            ..where((cp) =>
                cp.caveUuid.equalsValue(targetCaveUuid!) &
                cp.title.equals(row.cavePlaceName!)))
          .getSingleOrNull();

      if (existingPlace != null) {
        // Update QR code if configured and allowed
        if (row.qrCode != null && config.qrCodeColumn != null) {
          if (existingPlace.placeQrCodeIdentifier != row.qrCode && overwriteQr) {
            await (_database.update(_database.cavePlaces)
                  ..where((cp) => cp.uuid.equalsValue(existingPlace.uuid)))
                .write(CavePlacesCompanion(
              placeQrCodeIdentifier: Value(row.qrCode),
            ));
            qrCodesUpdated++;
          }
        }
        // Update area if mapped and not yet set
        if (targetAreaUuid != null &&
            existingPlace.caveAreaUuid != targetAreaUuid) {
          await (_database.update(_database.cavePlaces)
                ..where((cp) => cp.uuid.equalsValue(existingPlace.uuid)))
              .write(CavePlacesCompanion(
            caveAreaUuid: Value(targetAreaUuid),
          ));
        }
      } else {
        // Create new cave place
        await _database.into(_database.cavePlaces).insert(
              CavePlacesCompanion.insert(
                uuid: Uuid.v7(),
                title: row.cavePlaceName!,
                caveUuid: targetCaveUuid,
                caveAreaUuid: Value(targetAreaUuid),
                placeQrCodeIdentifier: Value(row.qrCode),
              ),
            );
        cavePlacesCreated++;
      }
    }

    return CSVCavePlaceImportResult(
      cavesCreated: cavesCreated,
      cavePlacesCreated: cavePlacesCreated,
      caveAreasCreated: caveAreasCreated,
      qrCodesUpdated: qrCodesUpdated,
    );
    }); // end transaction
  }
}
