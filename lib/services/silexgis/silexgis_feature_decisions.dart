import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_row_lookup.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_row_placer.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_version_reread.dart';

/// Decisions about feature rows: caves, areas and places.
class SilexgisFeatureDecisions implements SilexgisDecisionResolver {
  SilexgisFeatureDecisions({
    required AppDatabase db,
    required SilexgisServerVersionReread reread,
    required SilexgisServerRowPlacer placer,
    required ICaveRepository caves,
    required ICavePlaceRepository places,
  }) : _db = db,
       _reread = reread,
       _placer = placer,
       _caves = caves,
       _places = places,
       _rows = SilexgisLocalRowLookup(db, tables: tables);

  final AppDatabase _db;
  final SilexgisServerVersionReread _reread;
  final SilexgisServerRowPlacer _placer;
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
    await _reread.giveUp(
      profile.profileUuid,
      held,
      localUpdatedAt: (await _rows.read(
        held.entityTable,
        held.entityUuid,
      ))?.updatedAt,
    );
    return _placer.place(
      profile.profileUuid,
      profile.syncSetId,
      held,
      held.current,
    );
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
