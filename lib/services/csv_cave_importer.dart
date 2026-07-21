import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/csv_cave_import_snapshot.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
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

  /// When non-null, every newly created cave gets a main entrance place
  /// with this title — the same default as adding a cave in the UI.
  final String? entrancePlaceTitle;

  /// Maximum number of existing duplicate entries to preview before import.
  final int maxPreviewDuplicates;

  CSVCavesImportConfig({
    this.caveNameColumn,
    this.descriptionColumn,
    this.caveLocalIndexColumn,
    this.surfaceAreaColumn,
    this.generalAreaIdentifierColumn,
    this.entrancePlaceTitle,
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

/// Cave fields the import can update on an existing cave.
enum CSVCaveField { description, caveLocalIndex, surfaceArea }

/// One field whose CSV value differs from the existing cave's value.
class CSVCaveFieldChange {
  final CSVCaveField field;
  final String? oldValue;
  final String? newValue;

  CSVCaveFieldChange({required this.field, this.oldValue, this.newValue});
}

/// A CSV row matching an existing cave whose fields would change; the user
/// decides per cave (or for all) whether to apply the changes.
class CSVCaveUpdateCandidate {
  /// Index into the parsed rows list passed to [CSVCaveImporter.importRows].
  final int rowIndex;
  final Uuid caveUuid;
  final String caveTitle;
  final String? caveLocalIndex;
  final List<CSVCaveFieldChange> changes;

  CSVCaveUpdateCandidate({
    required this.rowIndex,
    required this.caveUuid,
    required this.caveTitle,
    this.caveLocalIndex,
    required this.changes,
  });
}

/// Result of a cave import operation.
class CSVCaveImportResult {
  final int cavesCreated;
  final int cavesUpdated;
  final int surfaceAreasCreated;
  final int skippedDuplicates;

  CSVCaveImportResult({
    required this.cavesCreated,
    required this.cavesUpdated,
    required this.surfaceAreasCreated,
    required this.skippedDuplicates,
  });
}

/// Helper class for importing cave data from CSV files.
///
/// All three phases — duplicate preview ([findExistingCaves]), update
/// planning ([planCaveUpdates]) and the import itself ([importRows]) —
/// resolve areas and match caves through one [CaveImportSnapshot], so
/// what the preview reports is exactly what the import will do.
class CSVCaveImporter {
  final AppDatabase _database;
  final CurrentUserService _currentUser;
  final ICavePlaceRepository _cavePlaces;
  final Clock _clock;

  CSVCaveImporter(
    this._database,
    this._currentUser,
    this._cavePlaces, {
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

  /// Find existing caves that match the CSV rows on the shared identity
  /// axes: title + local index, or the (title, surface area) identity.
  Future<({List<CaveExistingMatch> matches, int totalCount})> findExistingCaves(
    List<CSVCaveImportRow> rows,
    CSVCavesImportConfig config,
  ) async {
    final snapshot = await CaveImportSnapshot.load(_database);

    final allMatches = <CaveExistingMatch>[];
    for (final row in rows) {
      final title = row.caveName;
      if (title == null) continue;
      final area = snapshot.resolveArea(
        identifier: row.generalAreaIdentifier,
        title: row.surfaceArea,
      );
      final match = snapshot.matchCave(
        title: title,
        localIndex: row.caveLocalIndex,
        area: area,
      );
      if (match != null) {
        allMatches.add(
          CaveExistingMatch(
            caveName: match.title,
            surfaceArea: match.surfaceAreaUuid != null
                ? snapshot.areaTitleOf(match.surfaceAreaUuid!)
                : null,
          ),
        );
      }
    }

    return (matches: allMatches, totalCount: allMatches.length);
  }

  /// Find rows matching an existing cave whose provided CSV values differ
  /// from the stored ones. Read-only: run before [importRows] so the user
  /// can be asked which caves to update.
  Future<List<CSVCaveUpdateCandidate>> planCaveUpdates(
    List<CSVCaveImportRow> rows,
    CSVCavesImportConfig config,
  ) async {
    final snapshot = await CaveImportSnapshot.load(_database);

    final candidates = <CSVCaveUpdateCandidate>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final title = row.caveName;
      if (title == null) continue;

      final area = snapshot.resolveArea(
        identifier: row.generalAreaIdentifier,
        title: row.surfaceArea,
      );
      final target = snapshot.matchCave(
        title: title,
        localIndex: row.caveLocalIndex,
        area: area,
      );
      if (target == null) continue;

      final changes = <CSVCaveFieldChange>[];
      if (row.description != null && row.description != target.description) {
        changes.add(
          CSVCaveFieldChange(
            field: CSVCaveField.description,
            oldValue: target.description,
            newValue: row.description,
          ),
        );
      }
      if (row.caveLocalIndex != null &&
          row.caveLocalIndex != target.caveLocalIndex) {
        changes.add(
          CSVCaveFieldChange(
            field: CSVCaveField.caveLocalIndex,
            oldValue: target.caveLocalIndex,
            newValue: row.caveLocalIndex,
          ),
        );
      }
      if (area != null) {
        final sameArea =
            area.existing != null &&
            area.existing!.uuid == target.surfaceAreaUuid;
        // Moving the cave into an area where a same-titled cave already
        // lives would break UNIQUE(title, surface_area_uuid) — leave the
        // area untouched in that case.
        final occupied =
            area.existing != null &&
            snapshot.caveByTitleAndArea(title, area.existing!.uuid) != null;
        if (!sameArea && !occupied) {
          changes.add(
            CSVCaveFieldChange(
              field: CSVCaveField.surfaceArea,
              oldValue: target.surfaceAreaUuid != null
                  ? snapshot.areaTitleOf(target.surfaceAreaUuid!)
                  : null,
              newValue: area.title,
            ),
          );
        }
      }

      if (changes.isNotEmpty) {
        candidates.add(
          CSVCaveUpdateCandidate(
            rowIndex: i,
            caveUuid: target.uuid,
            caveTitle: target.title,
            caveLocalIndex: target.caveLocalIndex,
            changes: changes,
          ),
        );
      }
    }
    return candidates;
  }

  /// Perform the actual import.
  ///
  /// [updateCandidates] is the output of [planCaveUpdates];
  /// [approvedUpdates] holds the row indexes the user approved. Candidate
  /// rows not approved are skipped untouched.
  Future<CSVCaveImportResult> importRows(
    List<CSVCaveImportRow> rows,
    CSVCavesImportConfig config, {
    List<CSVCaveUpdateCandidate> updateCandidates = const [],
    Set<int> approvedUpdates = const {},
  }) async {
    return _database.transaction(() async {
      int cavesCreated = 0;
      int cavesUpdated = 0;
      int surfaceAreasCreated = 0;
      int skippedDuplicates = 0;
      final candidateByRow = {for (final c in updateCandidates) c.rowIndex: c};

      // The same identity view the preview and planning phases used, kept
      // in sync as rows are written so later rows see this run's own
      // creations and moves.
      final snapshot = await CaveImportSnapshot.load(_database);

      // Preload which caves already have an entrance place so an imported
      // cave — newly created or matched to an existing one — can be given a
      // default main entrance when it has none. Maintained as entrances are
      // added below.
      final cavesWithEntrance = <Uuid>{};
      if (config.entrancePlaceTitle != null) {
        cavesWithEntrance.addAll(
          (await _cavePlaces.getEntranceCountsByCave()).keys,
        );
      }

      // The import author is invariant for the whole run.
      final author = await _currentUser.currentOrSystem();

      bool rowNamesArea(CSVCaveImportRow row) =>
          row.generalAreaIdentifier != null || row.surfaceArea != null;

      // Write side of the area resolution, run only for rows that actually
      // import: backfills a missing identifier on a title-matched area and
      // creates the area when nothing matches. Rows that end up skipped
      // never reach this, leaving the database untouched.
      Future<Uuid?> resolveSurfaceArea(CSVCaveImportRow row, int now) async {
        final area = snapshot.resolveArea(
          identifier: row.generalAreaIdentifier,
          title: row.surfaceArea,
        );
        if (area == null) return null;

        final identifier = row.generalAreaIdentifier;
        final existing = area.existing;
        if (existing != null) {
          // Never overwrite a differing identifier on an existing area.
          if (identifier != null && existing.generalAreaIdentifier == null) {
            await (_database.update(
              _database.surfaceAreas,
            )..where((s) => s.uuid.equalsValue(existing.uuid))).write(
              SurfaceAreasCompanion(
                generalAreaIdentifier: Value(identifier),
                updatedAt: Value(now),
                lastModifiedByUserUuid: Value(author),
              ),
            );
            snapshot.backfillAreaIdentifier(existing, identifier);
          }
          return existing.uuid;
        }

        final newUuid = Uuid.v7();
        await _database
            .into(_database.surfaceAreas)
            .insert(
              SurfaceAreasCompanion.insert(
                uuid: newUuid,
                title: area.title,
                generalAreaIdentifier: Value(identifier),
                createdAt: Value(now),
                updatedAt: Value(now),
                createdByUserUuid: Value(author),
                lastModifiedByUserUuid: Value(author),
              ),
            );
        snapshot.registerArea(
          AreaSnapshotEntry(
            uuid: newUuid,
            title: area.title,
            generalAreaIdentifier: identifier,
          ),
        );
        surfaceAreasCreated++;
        return newUuid;
      }

      // Give [caveUuid] a default main entrance when it has none — the same
      // place adding a cave in the UI creates. No-op when the entrance
      // default is disabled or the cave already has an entrance.
      Future<void> ensureEntrance(Uuid caveUuid) async {
        if (config.entrancePlaceTitle == null) return;
        if (cavesWithEntrance.contains(caveUuid)) return;
        await _cavePlaces.addCavePlace(
          caveUuid,
          config.entrancePlaceTitle!,
          isEntrance: true,
          isMainEntrance: true,
        );
        cavesWithEntrance.add(caveUuid);
      }

      // Caves created during this run: duplicate rows for them may still
      // carry fields an earlier row lacked; those are applied silently —
      // pre-existing caves go through the update-approval flow instead.
      final createdThisRun = <Uuid>{};

      Future<bool> enrichSameRunCave(
        CaveSnapshotEntry cave,
        CSVCaveImportRow row,
        int now,
      ) async {
        if (!createdThisRun.contains(cave.uuid)) return false;
        final newDescription =
            row.description != null && row.description != cave.description
            ? row.description
            : null;
        final newIndex =
            row.caveLocalIndex != null &&
                row.caveLocalIndex != cave.caveLocalIndex
            ? row.caveLocalIndex
            : null;
        if (newDescription == null && newIndex == null) return false;
        await (_database.update(
          _database.caves,
        )..where((c) => c.uuid.equalsValue(cave.uuid))).write(
          CavesCompanion(
            description: newDescription != null
                ? Value(newDescription)
                : const Value.absent(),
            caveLocalIndex: newIndex != null
                ? Value(newIndex)
                : const Value.absent(),
            updatedAt: Value(now),
            lastModifiedByUserUuid: Value(author),
          ),
        );
        if (newDescription != null) cave.description = newDescription;
        if (newIndex != null) snapshot.setCaveLocalIndex(cave, newIndex);
        return true;
      }

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final title = row.caveName;
        if (title == null || title.isEmpty) continue;

        final now = _clock.nowMs();

        // Row matches an existing cave with differing fields: apply the
        // update only when the user approved it, otherwise leave the fields
        // untouched. Either way the matched cave still gets a default
        // entrance when it has none.
        final candidate = candidateByRow[i];
        if (candidate != null) {
          if (approvedUpdates.contains(i)) {
            final surfaceAreaUuid = await resolveSurfaceArea(row, now);
            // Re-check the unique (title, surface area) slot: it may have
            // been taken by a cave created earlier in this import.
            final occupant = snapshot.caveByTitleAndArea(
              title,
              surfaceAreaUuid,
            );
            final moveArea =
                rowNamesArea(row) &&
                (occupant == null || occupant.uuid == candidate.caveUuid);
            await (_database.update(
              _database.caves,
            )..where((c) => c.uuid.equalsValue(candidate.caveUuid))).write(
              CavesCompanion(
                description: row.description != null
                    ? Value(row.description)
                    : const Value.absent(),
                caveLocalIndex: row.caveLocalIndex != null
                    ? Value(row.caveLocalIndex)
                    : const Value.absent(),
                surfaceAreaUuid: moveArea
                    ? Value(surfaceAreaUuid)
                    : const Value.absent(),
                updatedAt: Value(now),
                lastModifiedByUserUuid: Value(author),
              ),
            );
            final entry = snapshot.caveByUuid(candidate.caveUuid);
            if (entry != null) {
              if (row.description != null) {
                entry.description = row.description;
              }
              if (row.caveLocalIndex != null) {
                snapshot.setCaveLocalIndex(entry, row.caveLocalIndex!);
              }
              if (moveArea) {
                snapshot.moveCaveToArea(entry, surfaceAreaUuid);
              }
            }
            cavesUpdated++;
          } else {
            skippedDuplicates++;
          }
          await ensureEntrance(candidate.caveUuid);
          continue;
        }

        // Same cave already present on either identity axis.
        final area = snapshot.resolveArea(
          identifier: row.generalAreaIdentifier,
          title: row.surfaceArea,
        );
        final match = snapshot.matchCave(
          title: title,
          localIndex: row.caveLocalIndex,
          area: area,
        );
        if (match != null) {
          if (await enrichSameRunCave(match, row, now)) {
            cavesUpdated++;
          } else {
            skippedDuplicates++;
          }
          await ensureEntrance(match.uuid);
          continue;
        }

        // Create new cave (materializing its surface area first).
        final surfaceAreaUuid = await resolveSurfaceArea(row, now);
        final newUuid = Uuid.v7();
        await _database
            .into(_database.caves)
            .insert(
              CavesCompanion.insert(
                uuid: newUuid,
                title: title,
                description: Value(row.description),
                caveLocalIndex: Value(row.caveLocalIndex),
                surfaceAreaUuid: Value(surfaceAreaUuid),
                createdAt: Value(now),
                updatedAt: Value(now),
                createdByUserUuid: Value(author),
                lastModifiedByUserUuid: Value(author),
              ),
            );
        snapshot.registerCave(
          CaveSnapshotEntry(
            uuid: newUuid,
            title: title,
            description: row.description,
            caveLocalIndex: row.caveLocalIndex,
            surfaceAreaUuid: surfaceAreaUuid,
          ),
        );
        createdThisRun.add(newUuid);
        cavesCreated++;

        // Same default as adding a cave in the UI: a main entrance place.
        await ensureEntrance(newUuid);
      }

      return CSVCaveImportResult(
        cavesCreated: cavesCreated,
        cavesUpdated: cavesUpdated,
        surfaceAreasCreated: surfaceAreasCreated,
        skippedDuplicates: skippedDuplicates,
      );
    }); // end transaction
  }
}
