import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_row_placer.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_version_reread.dart';

/// Decisions about places at stations of a survey.
///
/// A mapping is named after its survey and its place. One refused because
/// another already puts the place at a station of that survey can be
/// removed, and the next read then brings the one the installation holds.
class SilexgisPlaceStationDecisions implements SilexgisDecisionResolver {
  SilexgisPlaceStationDecisions({
    required AppDatabase db,
    required SilexgisServerVersionReread reread,
    required SilexgisServerRowPlacer placer,
    required IPlaceStationMappingRepository mappings,
  }) : _db = db,
       _reread = reread,
       _placer = placer,
       _mappings = mappings;

  final AppDatabase _db;
  final SilexgisServerVersionReread _reread;
  final SilexgisServerRowPlacer _placer;
  final IPlaceStationMappingRepository _mappings;

  @override
  Set<SyncUploadSection> get sections => const <SyncUploadSection>{
    SyncUploadSection.placeStations,
  };

  @override
  Future<String?> title(SilexgisHeldItem held) async {
    final row = await _row(held.entityUuid);
    if (row == null) return null;
    return '${row.read<String>('model')} · ${row.read<String>('place')}';
  }

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
      localUpdatedAt: (await _row(held.entityUuid))?.read<int?>('updated_at'),
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
    final row = await _row(held.entityUuid);
    if (row == null) return;
    await _mappings.deleteMapping(
      Uuid.fromBytes(row.read<Uint8List>('place_uuid')),
      Uuid.fromBytes(row.read<Uint8List>('model_uuid')),
    );
    if (held.code == SilexgisCodes.placeStationExists) {
      // The mapping already on the server for that place arrives with the
      // next read of the whole stream.
      await _reread.rereadFromBeginning(
        profile.profileUuid,
        profile.syncSetId,
        SyncStream.surveyModels,
      );
    }
  }

  Future<QueryRow?> _row(Uuid uuid) async {
    final rows = await _db
        .customSelect(
          'SELECT d.title AS model, c.title AS place, '
          'm.updated_at AS updated_at, m.cave_place_uuid AS place_uuid, '
          'm.documentation_file_uuid AS model_uuid '
          'FROM cave_place_model_stations m '
          'JOIN documentation_files d ON d.uuid = m.documentation_file_uuid '
          'JOIN cave_places c ON c.uuid = m.cave_place_uuid '
          'WHERE m.uuid = ? LIMIT 1',
          variables: <Variable<Object>>[Variable<Uint8List>(uuid.bytes)],
        )
        .get();
    return rows.isEmpty ? null : rows.single;
  }
}
