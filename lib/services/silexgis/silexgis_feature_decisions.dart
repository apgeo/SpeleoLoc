import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_row_lookup.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_version_reread.dart';

/// Decisions about feature rows: caves, areas and places.
///
/// The one section whose answers can carry the server's row: with it at hand,
/// going back to the server's version is written now, through the same
/// applier a download uses, with change logging suspended.
class SilexgisFeatureDecisions implements SilexgisDecisionResolver {
  SilexgisFeatureDecisions({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisServerVersionReread reread,
    required ICaveRepository caves,
    required ICavePlaceRepository places,
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _heldRows = heldRows,
       _reread = reread,
       _caves = caves,
       _places = places,
       _rows = SilexgisLocalRowLookup(db, tables: tables);

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisServerVersionReread _reread;
  final ICaveRepository _caves;
  final ICavePlaceRepository _places;
  final SilexgisLocalRowLookup _rows;

  /// The local tables a feature row can live in.
  static const Set<String> tables = <String>{
    'surface_areas',
    'caves',
    'cave_areas',
    'cave_places',
  };

  @override
  Set<SyncUploadSection> get sections => const <SyncUploadSection>{
    SyncUploadSection.rows,
  };

  @override
  Future<String?> title(SilexgisHeldItem held) async =>
      (await _rows.read(held.entityTable, held.entityUuid))?.title ??
      (held.isDelete ? (held.current?['name'] as String?) : null);

  @override
  Future<bool> isNew(
    SilexgisHeldItem held,
    Map<Uuid, StoredRevision> revisions,
  ) async => !revisions.containsKey(held.entityUuid);

  @override
  Future<bool> useServerVersion(
    SilexgisProfile profile,
    SilexgisHeldItem held,
  ) async {
    final profileUuid = profile.profileUuid;
    final server = held.current == null
        ? null
        : SyncFeatureRow.fromJson(held.current!);
    await _reread.giveUp(
      profileUuid,
      held,
      localUpdatedAt: (await _rows.read(
        held.entityTable,
        held.entityUuid,
      ))?.updatedAt,
      revision: server?.updatedAt,
    );
    if (server != null) {
      final report = await SilexgisDownloadApplier(
        db: _db,
        logger: _logger,
        localState: _localState,
        heldRows: _heldRows,
        caves: _caves,
        places: _places,
        profileUuid: profileUuid,
      ).applyRows(<SyncFeatureRow>[server]);
      if (report.inserted + report.updated > 0) return true;
    }
    // The account may not be handed that row's position: the feature
    // download is read from the beginning on the next run instead.
    await _reread.rereadFromBeginning(profile, null);
    return false;
  }

  @override
  Future<void> delete(SilexgisProfile profile, SilexgisHeldItem held) async {
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
  }
}
