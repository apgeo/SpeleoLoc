import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/csv_cave_place_import_snapshot.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/place_code/place_code_service.dart';
import 'package:speleoloc/utils/clock.dart';

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
  final String? qrCode;
  final String? caveArea;

  /// The row's position in the file, the header being row 1, so issues can
  /// point the user at it; null for rows not read from a file.
  final int? lineNumber;

  CSVCavePlaceImportRow({
    this.caveName,
    this.cavePlaceName,
    this.qrCode,
    this.caveArea,
    this.lineNumber,
  });

  @override
  String toString() =>
      'CSVImportRow(cave: $caveName, place: $cavePlaceName, qr: $qrCode, area: $caveArea)';
}

/// Represents an existing combination found in the database that matches a CSV row.
class CavePlaceExistingMatch {
  final String caveName;
  final String cavePlaceName;
  final String? caveArea;
  final String? existingQrCode;

  CavePlaceExistingMatch({
    required this.caveName,
    required this.cavePlaceName,
    this.caveArea,
    this.existingQrCode,
  });
}

/// Why a row was not imported as written.
enum CSVCavePlaceRowIssueKind {
  /// Several caves carry the row's cave name; the row was skipped.
  caveAmbiguous,

  /// Several places of the cave carry the row's place name and the row's
  /// area does not pick one; the row was skipped.
  placeAmbiguous,

  /// Another place of the cave holds the row's code and the user chose to
  /// leave it there; the row's place was written without the code.
  qrCodeTaken,

  /// An earlier row of the file gave the code to another place; the row's
  /// place was written without it.
  qrCodeRepeated,
}

/// One row the import could not apply as written.
class CSVCavePlaceRowIssue {
  final CSVCavePlaceRowIssueKind kind;
  final CSVCavePlaceImportRow row;

  /// The place that keeps the row's code, for the code issues.
  final String? holderTitle;

  CSVCavePlaceRowIssue(this.kind, this.row, {this.holderTitle});

  int? get lineNumber => row.lineNumber;
  String? get caveName => row.caveName;
  String? get placeName => row.cavePlaceName;
  String? get qrCode => row.qrCode;
}

/// Result of an import operation.
class CSVCavePlaceImportResult {
  final int cavesCreated;
  final int cavePlacesCreated;
  final int caveAreasCreated;

  /// Codes written onto places that already existed.
  final int qrCodesUpdated;

  /// Codes taken away from places because the user chose to overwrite.
  final int qrCodesCleared;

  final List<CSVCavePlaceRowIssue> issues;

  CSVCavePlaceImportResult({
    required this.cavesCreated,
    required this.cavePlacesCreated,
    required this.caveAreasCreated,
    required this.qrCodesUpdated,
    this.qrCodesCleared = 0,
    this.issues = const [],
  });
}

/// Helper class for importing cave place data from CSV files.
///
/// The duplicate preview ([findExistingCombinations]), the code-conflict
/// check ([findQrCodeConflicts]) and the import ([importRows]) resolve
/// caves, places and code holders through one [CavePlaceImportSnapshot],
/// so the questions asked before the import describe what it will do. A
/// row that names more than one cave or place is reported rather than
/// guessed at.
///
/// Every row written is logged in the change log like a repository write:
/// the log is what the FTP upload gate and the change history read, so an
/// unlogged import would never be uploaded to other devices.
class CSVCavePlaceImporter {
  final AppDatabase _database;
  final CurrentUserService _currentUser;
  final PlaceCodeService _placeCodeService;
  final ChangeLogger _logger;
  final Clock _clock;

  CSVCavePlaceImporter(
    this._database,
    this._currentUser,
    this._placeCodeService,
    this._logger, {
    Clock clock = const SystemClock(),
  }) : _clock = clock;

  /// Parse a CSV string into a list of lists (rows x columns).
  /// Expects the first row to be headers.
  List<List<dynamic>> parseCSV(String csvContent) {
    final converter = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    );
    // Normalize line endings
    final normalized = csvContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    return converter.convert(normalized);
  }

  /// Extract header names from the first row of parsed CSV data.
  List<String> getHeaders(List<List<dynamic>> csvData) {
    if (csvData.isEmpty) return [];
    return csvData.first.map((e) => e.toString().trim()).toList();
  }

  /// Parse CSV rows according to the given config, skipping the header row.
  List<CSVCavePlaceImportRow> parseRows(
    List<List<dynamic>> csvData,
    CSVCavePlacesImportConfig config,
  ) {
    if (csvData.length < 2) return [];

    final rows = <CSVCavePlaceImportRow>[];
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty) continue;

      String? caveName;
      String? cavePlaceName;
      String? qrCode;
      String? caveArea;

      if (config.caveNameColumn != null &&
          config.caveNameColumn! < row.length) {
        final val = row[config.caveNameColumn!].toString().trim();
        if (val.isNotEmpty) caveName = val;
      }

      if (config.cavePlaceNameColumn != null &&
          config.cavePlaceNameColumn! < row.length) {
        final val = row[config.cavePlaceNameColumn!].toString().trim();
        if (val.isNotEmpty) cavePlaceName = val;
      }

      if (config.qrCodeColumn != null && config.qrCodeColumn! < row.length) {
        final val = row[config.qrCodeColumn!].toString().trim();
        if (val.isNotEmpty) qrCode = val;
      }

      if (config.caveAreaColumn != null &&
          config.caveAreaColumn! < row.length) {
        final val = row[config.caveAreaColumn!].toString().trim();
        if (val.isNotEmpty) caveArea = val;
      }

      // Skip rows with no place name
      if (cavePlaceName == null || cavePlaceName.isEmpty) continue;

      rows.add(
        CSVCavePlaceImportRow(
          caveName: caveName,
          cavePlaceName: cavePlaceName,
          qrCode: qrCode,
          caveArea: caveArea,
          lineNumber: i + 1,
        ),
      );
    }
    return rows;
  }

  /// Find the places already in the database that the CSV rows will update.
  /// Rows naming several caves or places match nothing here; the import
  /// reports them instead.
  Future<({List<CavePlaceExistingMatch> matches, int totalCount})>
  findExistingCombinations(
    List<CSVCavePlaceImportRow> rows,
    CSVCavePlacesImportConfig config,
  ) async {
    final snapshot = await CavePlaceImportSnapshot.load(
      _database,
      caveUuid: config.caveUuid,
    );
    final matches = <CavePlaceExistingMatch>[];
    for (final row in rows) {
      final caveUuid = _existingCave(row, config, snapshot).match;
      if (caveUuid == null || row.cavePlaceName == null) continue;
      final place = _placeFor(snapshot, caveUuid, row).match;
      if (place == null) continue;
      matches.add(
        CavePlaceExistingMatch(
          caveName: snapshot.caveTitleOf(caveUuid) ?? '',
          cavePlaceName: place.title,
          caveArea: row.caveArea,
          existingQrCode: place.placeCode,
        ),
      );
    }
    return (matches: matches, totalCount: matches.length);
  }

  /// Find the places whose code the import would replace if the user
  /// chooses to overwrite: other places of a row's cave holding the row's
  /// code, and places the row matches that already hold a different code.
  /// Codes repeat legitimately across caves, so only the row's own cave
  /// counts.
  Future<List<CavePlaceExistingMatch>> findQrCodeConflicts(
    List<CSVCavePlaceImportRow> rows,
    CSVCavePlacesImportConfig config,
  ) async {
    final conflicts = <CavePlaceExistingMatch>[];
    if (config.qrCodeColumn == null) return conflicts;

    final snapshot = await CavePlaceImportSnapshot.load(
      _database,
      caveUuid: config.caveUuid,
    );
    final listed = <Uuid>{};
    void add(Uuid caveUuid, PlaceSnapshotEntry place) {
      if (!listed.add(place.uuid)) return;
      conflicts.add(
        CavePlaceExistingMatch(
          caveName: snapshot.caveTitleOf(caveUuid) ?? '',
          cavePlaceName: place.title,
          existingQrCode: place.placeCode,
        ),
      );
    }

    for (final row in rows) {
      final code = row.qrCode;
      if (code == null || row.cavePlaceName == null) continue;
      final caveUuid = _existingCave(row, config, snapshot).match;
      if (caveUuid == null) continue;
      final resolved = _placeFor(snapshot, caveUuid, row);
      if (resolved.ambiguous) continue;
      final place = resolved.match;
      for (final holder in snapshot.holdersOf(caveUuid, code, except: place)) {
        add(caveUuid, holder);
      }
      if (place != null && place.placeCode != null && place.placeCode != code) {
        add(caveUuid, place);
      }
    }
    return conflicts;
  }

  /// Perform the actual import.
  ///
  /// [overwriteQr] answers the code-conflict question: true gives each row's
  /// place the file's code and takes it away from any other place of the
  /// cave holding it; false leaves every code where it is, so a place whose
  /// code is held elsewhere is written without one. A code no place of the
  /// cave holds is written either way, as is a code onto a place that has
  /// none. The first row of the file to name a code keeps it.
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
      int qrCodesCleared = 0;
      final issues = <CSVCavePlaceRowIssue>[];

      // Kept in step with every write below, so later rows see this run's
      // own caves, areas, places and codes.
      final snapshot = await CavePlaceImportSnapshot.load(
        _database,
        caveUuid: config.caveUuid,
      );
      // Place given each "cave|code" by an earlier row of this file.
      final claimedBy = <String, PlaceSnapshotEntry>{};
      final author = await _currentUser.currentOrSystem();

      for (final row in rows) {
        final title = row.cavePlaceName;
        if (title == null || title.isEmpty) continue;
        final now = _clock.nowMs();

        final cave = _existingCave(row, config, snapshot);
        if (cave.ambiguous) {
          issues.add(
            CSVCavePlaceRowIssue(CSVCavePlaceRowIssueKind.caveAmbiguous, row),
          );
          continue;
        }
        var caveUuid = cave.match;
        if (caveUuid == null) {
          final caveName = row.caveName;
          if (!config.isMultipleCaveMode ||
              caveName == null ||
              caveName.isEmpty) {
            continue;
          }
          caveUuid = await _createCave(caveName, now, author, snapshot);
          cavesCreated++;
        }

        final resolved = _placeFor(snapshot, caveUuid, row);
        if (resolved.ambiguous) {
          issues.add(
            CSVCavePlaceRowIssue(CSVCavePlaceRowIssueKind.placeAmbiguous, row),
          );
          continue;
        }

        final areaTitle = _areaTitle(row);
        Uuid? areaUuid;
        if (areaTitle != null) {
          areaUuid = snapshot.areaOf(caveUuid, areaTitle);
          if (areaUuid == null) {
            areaUuid = await _createArea(
              caveUuid,
              areaTitle,
              now,
              author,
              snapshot,
            );
            caveAreasCreated++;
          }
        }

        final place = resolved.match;
        final code = config.qrCodeColumn != null ? row.qrCode : null;
        final claimKey = '$caveUuid|$code';
        String? codeToWrite;
        if (code != null && place?.placeCode != code) {
          final earlier = claimedBy[claimKey];
          final holders = snapshot.holdersOf(caveUuid, code, except: place);
          if (earlier != null) {
            issues.add(
              CSVCavePlaceRowIssue(
                CSVCavePlaceRowIssueKind.qrCodeRepeated,
                row,
                holderTitle: earlier.title,
              ),
            );
          } else if (overwriteQr ||
              (holders.isEmpty && place?.placeCode == null)) {
            for (final holder in holders) {
              await _writeCode(holder, null, now, author, snapshot);
              qrCodesCleared++;
            }
            codeToWrite = code;
          } else if (holders.isNotEmpty) {
            issues.add(
              CSVCavePlaceRowIssue(
                CSVCavePlaceRowIssueKind.qrCodeTaken,
                row,
                holderTitle: holders.first.title,
              ),
            );
          }
        }

        final PlaceSnapshotEntry target;
        if (place != null) {
          if (codeToWrite != null) {
            await _writeCode(place, codeToWrite, now, author, snapshot);
            qrCodesUpdated++;
          }
          // An area already set is never overwritten: a place filed in
          // another area is a different place, which the lookup keeps apart.
          if (areaUuid != null && place.caveAreaUuid == null) {
            await (_database.update(
              _database.cavePlaces,
            )..where((cp) => cp.uuid.equalsValue(place.uuid))).write(
              CavePlacesCompanion(
                caveAreaUuid: Value(areaUuid),
                updatedAt: Value(now),
                lastModifiedByUserUuid: Value(author),
              ),
            );
            await _logger.logUpdate(
              'cave_places',
              place.uuid,
              oldValues: const {'cave_area_uuid': null},
              newValues: {'cave_area_uuid': areaUuid},
            );
            place.caveAreaUuid = areaUuid;
          }
          target = place;
        } else {
          final newUuid = Uuid.v7();
          final companion = await _placeCodeService.applyPciToCompanion(
            CavePlacesCompanion.insert(
              uuid: newUuid,
              title: title,
              caveUuid: caveUuid,
              caveAreaUuid: Value(areaUuid),
              placeCodeIdentifier: Value(codeToWrite),
              createdAt: Value(now),
              updatedAt: Value(now),
              createdByUserUuid: Value(author),
              lastModifiedByUserUuid: Value(author),
            ),
            cavePlaceUuid: newUuid,
          );
          await _database.into(_database.cavePlaces).insert(companion);
          await _logger.logInsert('cave_places', newUuid);
          target = PlaceSnapshotEntry(
            uuid: newUuid,
            caveUuid: caveUuid,
            title: title,
            caveAreaUuid: areaUuid,
            placeCode: codeToWrite,
          );
          snapshot.registerPlace(target);
          cavePlacesCreated++;
        }
        if (code != null && target.placeCode == code) {
          claimedBy.putIfAbsent(claimKey, () => target);
        }
      }

      return CSVCavePlaceImportResult(
        cavesCreated: cavesCreated,
        cavePlacesCreated: cavePlacesCreated,
        caveAreasCreated: caveAreasCreated,
        qrCodesUpdated: qrCodesUpdated,
        qrCodesCleared: qrCodesCleared,
        issues: issues,
      );
    }); // end transaction
  }

  static String? _areaTitle(CSVCavePlaceImportRow row) {
    final area = row.caveArea;
    return (area == null || area.isEmpty) ? null : area;
  }

  /// The existing cave a row belongs to. In multi-cave mode a match of
  /// null that is not ambiguous means the import would create the cave.
  SnapshotMatch<Uuid> _existingCave(
    CSVCavePlaceImportRow row,
    CSVCavePlacesImportConfig config,
    CavePlaceImportSnapshot snapshot,
  ) {
    if (!config.isMultipleCaveMode) {
      return (match: config.caveUuid, ambiguous: false);
    }
    final name = row.caveName;
    if (name == null || name.isEmpty) return (match: null, ambiguous: false);
    final caves = snapshot.cavesTitled(name);
    return (match: caves.match?.uuid, ambiguous: caves.ambiguous);
  }

  SnapshotMatch<PlaceSnapshotEntry> _placeFor(
    CavePlaceImportSnapshot snapshot,
    Uuid caveUuid,
    CSVCavePlaceImportRow row,
  ) {
    final areaTitle = _areaTitle(row);
    return snapshot.placeIn(
      caveUuid,
      row.cavePlaceName!,
      rowNamesArea: areaTitle != null,
      areaUuid: areaTitle == null ? null : snapshot.areaOf(caveUuid, areaTitle),
    );
  }

  Future<Uuid> _createCave(
    String title,
    int now,
    Uuid author,
    CavePlaceImportSnapshot snapshot,
  ) async {
    final uuid = Uuid.v7();
    await _database
        .into(_database.caves)
        .insert(
          CavesCompanion.insert(
            uuid: uuid,
            title: title,
            createdAt: Value(now),
            updatedAt: Value(now),
            createdByUserUuid: Value(author),
            lastModifiedByUserUuid: Value(author),
          ),
        );
    await _logger.logInsert('caves', uuid);
    snapshot.registerCave(uuid, title);
    return uuid;
  }

  Future<Uuid> _createArea(
    Uuid caveUuid,
    String title,
    int now,
    Uuid author,
    CavePlaceImportSnapshot snapshot,
  ) async {
    final uuid = Uuid.v7();
    await _database
        .into(_database.caveAreas)
        .insert(
          CaveAreasCompanion.insert(
            uuid: uuid,
            title: title,
            caveUuid: caveUuid,
            createdAt: Value(now),
            updatedAt: Value(now),
            createdByUserUuid: Value(author),
            lastModifiedByUserUuid: Value(author),
          ),
        );
    await _logger.logInsert('cave_areas', uuid);
    snapshot.registerArea(caveUuid, title, uuid);
    return uuid;
  }

  /// Writes [code] onto [place], or clears it when null, recomputing the
  /// QR payload that is derived from it.
  Future<void> _writeCode(
    PlaceSnapshotEntry place,
    String? code,
    int now,
    Uuid author,
    CavePlaceImportSnapshot snapshot,
  ) async {
    final old = await (_database.select(
      _database.cavePlaces,
    )..where((cp) => cp.uuid.equalsValue(place.uuid))).getSingle();
    final patch = await _placeCodeService.applyPciToCompanion(
      CavePlacesCompanion(
        placeCodeIdentifier: Value(code),
        updatedAt: Value(now),
        lastModifiedByUserUuid: Value(author),
      ),
      cavePlaceUuid: place.uuid,
    );
    await (_database.update(
      _database.cavePlaces,
    )..where((cp) => cp.uuid.equalsValue(place.uuid))).write(patch);
    await _logger.logUpdate(
      'cave_places',
      place.uuid,
      oldValues: {
        'place_code_identifier': old.placeCodeIdentifier,
        'qr_code_resource_identifier': old.qrCodeResourceIdentifier,
      },
      newValues: {
        'place_code_identifier': code,
        'qr_code_resource_identifier': patch.qrCodeResourceIdentifier.present
            ? patch.qrCodeResourceIdentifier.value
            : old.qrCodeResourceIdentifier,
      },
    );
    snapshot.setPlaceCode(place, code);
  }
}
