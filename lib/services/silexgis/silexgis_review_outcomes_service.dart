import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';

/// A row a reviewer turned down, or that failed when it was written, as the
/// caver is shown it.
class SilexgisReviewOutcome {
  const SilexgisReviewOutcome({
    required this.held,
    required this.isNew,
    this.title,
  });

  final SilexgisHeldItem held;

  /// The row's name here, or the server's when the row is gone locally.
  final String? title;

  /// The row is not on the server at all: there is no version of it there to
  /// go back to.
  final bool isNew;

  /// Whether the server's version comes with the decision, so going back to it
  /// needs no further read.
  bool get hasServerRow => held.current != null;

  bool get canUseServerVersion => !isNew;

  /// Only a row the server never had can be thrown away here without that
  /// being a removal to send.
  bool get canDelete => isNew && !held.isDelete;
}

/// What the caver can do about a turned-down row.
///
/// Nothing here happens on its own. A turned-down new row stays on the device
/// as a draft, unsent until the caver edits it; a turned-down edit stays as the
/// caver left it. The caver chooses: go back to the server's version, keep
/// their own without sending it, or throw a draft away.
class SilexgisReviewOutcomesService {
  SilexgisReviewOutcomesService({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required ICaveRepository caves,
    required ICavePlaceRepository places,
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _heldRows = heldRows,
       _caves = caves,
       _places = places;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final ICaveRepository _caves;
  final ICavePlaceRepository _places;

  /// The local tables a held feature row can live in. Names are only ever
  /// taken from this set, never from stored text, when they go into SQL.
  static const Set<String> _featureTables = <String>{
    'surface_areas',
    'caves',
    'cave_areas',
    'cave_places',
  };

  /// The rows waiting for the caver's choice on [profileUuid].
  Future<List<SilexgisReviewOutcome>> outcomes(String profileUuid) async {
    final revisions = await _localState.readRevisions(profileUuid);
    final outcomes = <SilexgisReviewOutcome>[];
    final orphans = <Uuid>[];
    for (final held in await _heldRows.readAll(profileUuid)) {
      if (!held.awaitsCaver) continue;
      final title = await _localTitle(held);
      if (title == null && !held.isDelete) {
        // The row went with something the caver threw away — a place inside a
        // draft cave — so there is nothing left to choose about.
        if (held.section == SyncUploadSection.rows)
          orphans.add(held.entityUuid);
        continue;
      }
      outcomes.add(
        SilexgisReviewOutcome(
          held: held,
          isNew: !revisions.containsKey(held.entityUuid),
          title: title ?? held.current?['name'] as String?,
        ),
      );
    }
    await _heldRows.clear(profileUuid, SyncUploadSection.rows, orphans);
    return outcomes;
  }

  /// Puts the server's version back in place of the caver's.
  ///
  /// With the server's row at hand it is written now, through the same
  /// applier a download uses, with change logging suspended. Without it — the
  /// account may not be handed that row's position — the feature download is
  /// read from the beginning on the next run, and this row is no longer held
  /// back from it. Returns true when the server's version is already in place.
  Future<bool> useServerVersion(
    SilexgisProfile profile,
    SilexgisReviewOutcome outcome,
  ) async {
    final held = outcome.held;
    if (!outcome.canUseServerVersion ||
        held.section != SyncUploadSection.rows) {
      return false;
    }
    final profileUuid = profile.profileUuid;
    final server = held.current == null
        ? null
        : SyncFeatureRow.fromJson(held.current!);
    final stored = (await _localState.readRevisions(
      profileUuid,
    ))[held.entityUuid];

    if (held.isDelete) {
      // The row is gone here and still there. With no revision the device
      // sends no removal, and the next read brings the row back.
      await _localState.forgetRevisions(profileUuid, <Uuid>[held.entityUuid]);
    } else {
      // The caver's edit is given up: the row now agrees with the server as
      // far as the device can tell, so it is neither sent nor held back.
      await _localState.writeRevision(
        profileUuid,
        held.entityUuid,
        entityTable: held.entityTable,
        wireKind: held.wireKind ?? stored?.wireKind,
        revision: server?.updatedAt ?? stored?.revision ?? '',
        localUpdatedAt: await _localUpdatedAt(held),
      );
    }
    await _heldRows.clear(profileUuid, held.section, <Uuid>[held.entityUuid]);

    if (server != null) {
      final report = await _applier(
        profileUuid,
      ).applyRows(<SyncFeatureRow>[server]);
      if (report.inserted + report.updated > 0) return true;
    }
    final setId = profile.syncSetId;
    if (setId != null) await _localState.dropCursor(profileUuid, setId);
    return false;
  }

  /// Keeps the caver's version on the device, unsent until they edit it.
  Future<void> keepMine(String profileUuid, SilexgisReviewOutcome outcome) =>
      _heldRows.markKept(
        profileUuid,
        outcome.held.section,
        outcome.held.entityUuid,
      );

  /// Throws away a row the server never had. A caver's own deletion, so it is
  /// logged like any other.
  Future<void> deleteDraft(
    String profileUuid,
    SilexgisReviewOutcome outcome,
  ) async {
    if (!outcome.canDelete) return;
    final held = outcome.held;
    final uuid = held.entityUuid;
    switch (held.entityTable) {
      case 'cave_places':
        await _places.deleteCavePlace(uuid);
      case 'caves':
        await _caves.deleteCave(uuid);
      case 'cave_areas':
        final area = await (_db.select(
          _db.caveAreas,
        )..where((t) => t.uuid.equalsValue(uuid))).getSingleOrNull();
        if (area != null) await _caves.deleteCaveArea(area);
      case 'surface_areas':
        final area = await (_db.select(
          _db.surfaceAreas,
        )..where((t) => t.uuid.equalsValue(uuid))).getSingleOrNull();
        if (area != null) await _caves.deleteSurfaceArea(area);
    }
    await _heldRows.clear(profileUuid, held.section, <Uuid>[uuid]);
  }

  SilexgisDownloadApplier _applier(String profileUuid) =>
      SilexgisDownloadApplier(
        db: _db,
        logger: _logger,
        localState: _localState,
        heldRows: _heldRows,
        caves: _caves,
        places: _places,
        profileUuid: profileUuid,
      );

  Future<String?> _localTitle(SilexgisHeldItem held) async {
    final row = await _localRow(held, 'title');
    return row?.read<String?>('title');
  }

  Future<int?> _localUpdatedAt(SilexgisHeldItem held) async {
    final row = await _localRow(held, 'updated_at');
    return row?.read<int?>('updated_at');
  }

  Future<QueryRow?> _localRow(SilexgisHeldItem held, String column) async {
    final table = held.entityTable;
    if (!_featureTables.contains(table)) return null;
    final rows = await _db
        .customSelect(
          'SELECT $column FROM $table WHERE uuid = ? LIMIT 1',
          variables: <Variable<Object>>[
            Variable<Uint8List>(held.entityUuid.bytes),
          ],
        )
        .get();
    return rows.isEmpty ? null : rows.single;
  }
}
