import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
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

    // Build lookup: "title.lower|surfaceAreaTitle.lower" -> exists, plus
    // the same title+local-index axis importRows dedups on, so the preview
    // count matches what the import will actually skip.
    final caveSet = <String>{};
    final caveIdxSet = <String>{};
    for (var c in caves) {
      final saTitle = c.surfaceAreaUuid != null
          ? surfaceAreaMap[c.surfaceAreaUuid]?.toLowerCase()
          : null;
      final key = '${c.title.toLowerCase()}|${saTitle ?? ''}';
      caveSet.add(key);
      final idx = c.caveLocalIndex;
      if (idx != null && idx.isNotEmpty) {
        caveIdxSet.add('${c.title.toLowerCase()}|$idx');
      }
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
      final key =
          '${row.caveName!.toLowerCase()}|${saTitle?.toLowerCase() ?? ''}';
      final byIndex =
          row.caveLocalIndex != null &&
          caveIdxSet.contains(
            '${row.caveName!.toLowerCase()}|${row.caveLocalIndex}',
          );
      if (caveSet.contains(key) || byIndex) {
        allMatches.add(
          CaveExistingMatch(caveName: row.caveName!, surfaceArea: saTitle),
        );
      }
    }

    return (matches: allMatches, totalCount: allMatches.length);
  }

  /// Find rows matching an existing cave — same title and cave local index,
  /// or the (title, surface area) identity — whose provided CSV values
  /// differ from the stored ones. Read-only: run before [importRows] so the
  /// user can be asked which caves to update.
  Future<List<CSVCaveUpdateCandidate>> planCaveUpdates(
    List<CSVCaveImportRow> rows,
    CSVCavesImportConfig config,
  ) async {
    final caves = await _database.select(_database.caves).get();
    final areas = await _database.select(_database.surfaceAreas).get();

    final saTitleByUuid = {for (var a in areas) a.uuid: a.title};
    final saByIdentifier = <String, SurfaceArea>{};
    final saByTitle = <String, SurfaceArea>{};
    for (var a in areas) {
      saByTitle[a.title.toLowerCase()] = a;
      final identifier = a.generalAreaIdentifier;
      if (identifier != null && identifier.isNotEmpty) {
        saByIdentifier[identifier] = a;
      }
    }

    final caveByTitleIdx = <String, Cave>{};
    final caveByTitleSa = <String, Cave>{};
    for (var c in caves) {
      final titleKey = c.title.toLowerCase();
      final idx = c.caveLocalIndex;
      if (idx != null && idx.isNotEmpty) {
        caveByTitleIdx.putIfAbsent('$titleKey|$idx', () => c);
      }
      caveByTitleSa['$titleKey|${c.surfaceAreaUuid ?? ''}'] = c;
    }

    final candidates = <CSVCaveUpdateCandidate>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.caveName == null) continue;
      final titleKey = row.caveName!.toLowerCase();

      // Resolve the row's target surface area without creating anything.
      // Null when the row carries no area information; `existing` is null
      // when the import would create a new area.
      ({String title, SurfaceArea? existing})? resolvedSa;
      if (row.generalAreaIdentifier != null || row.surfaceArea != null) {
        final byIdentifier = row.generalAreaIdentifier != null
            ? saByIdentifier[row.generalAreaIdentifier!]
            : null;
        if (byIdentifier != null) {
          resolvedSa = (title: byIdentifier.title, existing: byIdentifier);
        } else {
          final effectiveTitle = row.surfaceArea ?? row.generalAreaIdentifier!;
          final byTitle = saByTitle[effectiveTitle.toLowerCase()];
          resolvedSa = (
            title: byTitle?.title ?? effectiveTitle,
            existing: byTitle,
          );
        }
      }

      // Same cave: matched by title + cave local index first, then by the
      // (title, surface area) unique identity.
      Cave? target;
      if (row.caveLocalIndex != null) {
        target = caveByTitleIdx['$titleKey|${row.caveLocalIndex}'];
      }
      if (target == null &&
          (resolvedSa == null || resolvedSa.existing != null)) {
        target = caveByTitleSa['$titleKey|${resolvedSa?.existing?.uuid ?? ''}'];
      }
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
      if (resolvedSa != null) {
        final sameArea =
            resolvedSa.existing != null &&
            resolvedSa.existing!.uuid == target.surfaceAreaUuid;
        // Moving the cave into an area where a same-titled cave already
        // lives would break UNIQUE(title, surface_area_uuid) — leave the
        // area untouched in that case.
        final occupied =
            resolvedSa.existing != null &&
            caveByTitleSa.containsKey('$titleKey|${resolvedSa.existing!.uuid}');
        if (!sameArea && !occupied) {
          changes.add(
            CSVCaveFieldChange(
              field: CSVCaveField.surfaceArea,
              oldValue: target.surfaceAreaUuid != null
                  ? saTitleByUuid[target.surfaceAreaUuid]
                  : null,
              newValue: resolvedSa.title,
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

      // Cache existing data
      final surfaceAreaCache = <String, Uuid>{}; // title.lower -> uuid
      final identifierCache =
          <String, Uuid>{}; // general_area_identifier -> uuid
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
      final caveByTitleIdx = <String, Uuid>{}; // "title.lower|localIdx" -> uuid
      final existingCaves = await _database.select(_database.caves).get();
      for (var c in existingCaves) {
        final key = '${c.title.toLowerCase()}|${c.surfaceAreaUuid ?? ''}';
        caveCache[key] = c.uuid;
        final idx = c.caveLocalIndex;
        if (idx != null && idx.isNotEmpty) {
          caveByTitleIdx.putIfAbsent(
            '${c.title.toLowerCase()}|$idx',
            () => c.uuid,
          );
        }
      }

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

      // Read-only side of the surface-area resolution: an existing area
      // matched by general_area_identifier wins, then one matched by
      // title. Null when the row names an area that does not exist yet —
      // creation (and identifier backfill) is deferred to
      // [resolveSurfaceArea] so rows that end up skipped leave the
      // database untouched.
      Uuid? lookupSurfaceArea(CSVCaveImportRow row) {
        final identifier = row.generalAreaIdentifier;
        final title = row.surfaceArea;
        if (identifier == null && title == null) return null;
        if (identifier != null) {
          final byIdentifier = identifierCache[identifier];
          if (byIdentifier != null) return byIdentifier;
        }
        final effectiveTitle = title ?? identifier!;
        return surfaceAreaCache[effectiveTitle.toLowerCase()];
      }

      bool rowNamesArea(CSVCaveImportRow row) =>
          row.generalAreaIdentifier != null || row.surfaceArea != null;

      // Write side of the resolution, run only for rows that actually
      // import: an existing area matched by general_area_identifier wins,
      // then one matched by title (backfilling its identifier when it has
      // none), otherwise a new area is created. The identifier doubles as
      // the title when no title is given.
      Future<Uuid?> resolveSurfaceArea(CSVCaveImportRow row, int now) async {
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

      // Caves created during this run, with the field values they were
      // created/last enriched with. Duplicate rows for these caves may
      // still carry fields an earlier row lacked; those are applied
      // silently — pre-existing caves go through the update-approval flow
      // instead.
      final createdFieldsByUuid =
          <Uuid, ({String? description, String? caveLocalIndex})>{};

      Future<bool> enrichSameRunCave(
        Uuid caveUuid,
        CSVCaveImportRow row,
        int now,
      ) async {
        final current = createdFieldsByUuid[caveUuid];
        if (current == null) return false;
        final newDescription =
            row.description != null && row.description != current.description
            ? row.description
            : null;
        final newIndex =
            row.caveLocalIndex != null &&
                row.caveLocalIndex != current.caveLocalIndex
            ? row.caveLocalIndex
            : null;
        if (newDescription == null && newIndex == null) return false;
        await (_database.update(
          _database.caves,
        )..where((c) => c.uuid.equalsValue(caveUuid))).write(
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
        createdFieldsByUuid[caveUuid] = (
          description: newDescription ?? current.description,
          caveLocalIndex: newIndex ?? current.caveLocalIndex,
        );
        return true;
      }

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.caveName == null || row.caveName!.isEmpty) continue;

        final now = _clock.nowMs();
        final titleKey = row.caveName!.toLowerCase();

        // Row matches an existing cave with differing fields: apply the
        // update only when the user approved it, otherwise leave the fields
        // untouched. Either way the matched cave still gets a default
        // entrance when it has none.
        final candidate = candidateByRow[i];
        if (candidate != null) {
          if (approvedUpdates.contains(i)) {
            final surfaceAreaUuid = await resolveSurfaceArea(row, now);
            final caveKey = '$titleKey|${surfaceAreaUuid ?? ''}';
            // Re-check the unique (title, surface area) slot: it may have
            // been taken by a cave created earlier in this import.
            final occupant = caveCache[caveKey];
            final moveArea =
                rowNamesArea(row) &&
                (occupant == null || occupant == candidate.caveUuid);
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
            if (moveArea) {
              // Vacate the cave's previous (title, area) slot so later
              // rows can move into or create a cave there.
              caveCache.removeWhere((_, uuid) => uuid == candidate.caveUuid);
              caveCache[caveKey] = candidate.caveUuid;
            }
            cavesUpdated++;
          } else {
            skippedDuplicates++;
          }
          await ensureEntrance(candidate.caveUuid);
          continue;
        }

        // Same cave already present (title + local index).
        final byIndex = row.caveLocalIndex != null
            ? caveByTitleIdx['$titleKey|${row.caveLocalIndex}']
            : null;
        if (byIndex != null) {
          if (await enrichSameRunCave(byIndex, row, now)) {
            cavesUpdated++;
          } else {
            skippedDuplicates++;
          }
          await ensureEntrance(byIndex);
          continue;
        }

        // Check if cave already exists (title + surface_area_uuid is
        // unique). An area the import has not created yet cannot hold a
        // cave, so the lookup only applies when the area resolves.
        final lookedUpSaUuid = lookupSurfaceArea(row);
        final wouldCreateArea = rowNamesArea(row) && lookedUpSaUuid == null;
        if (!wouldCreateArea) {
          final existingUuid = caveCache['$titleKey|${lookedUpSaUuid ?? ''}'];
          if (existingUuid != null) {
            if (await enrichSameRunCave(existingUuid, row, now)) {
              cavesUpdated++;
            } else {
              skippedDuplicates++;
            }
            await ensureEntrance(existingUuid);
            continue;
          }
        }

        // Create new cave (materializing its surface area first).
        final surfaceAreaUuid = await resolveSurfaceArea(row, now);
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
        caveCache['$titleKey|${surfaceAreaUuid ?? ''}'] = newUuid;
        final idx = row.caveLocalIndex;
        if (idx != null && idx.isNotEmpty) {
          caveByTitleIdx.putIfAbsent('$titleKey|$idx', () => newUuid);
        }
        createdFieldsByUuid[newUuid] = (
          description: row.description,
          caveLocalIndex: row.caveLocalIndex,
        );
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
