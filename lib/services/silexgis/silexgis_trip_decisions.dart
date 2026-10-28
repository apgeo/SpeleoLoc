import 'package:drift/drift.dart';
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
import 'package:speleoloc/services/silexgis/silexgis_trip_upload_answers.dart';

/// Removes one scan as the caver would, its photos' links and the trip's log
/// included.
typedef SilexgisScanRemover = Future<void> Function(Uuid scanUuid);

/// Decisions about trip recordings and their scans.
///
/// A scan is named after its recording and the place it marks.
class SilexgisTripDecisions implements SilexgisDecisionResolver {
  SilexgisTripDecisions({
    required AppDatabase db,
    required SilexgisServerVersionReread reread,
    required SilexgisServerRowPlacer placer,
    required ICaveTripRepository trips,
    required SilexgisScanRemover removeScan,
  }) : _db = db,
       _reread = reread,
       _placer = placer,
       _trips = trips,
       _removeScan = removeScan,
       _recordings = SilexgisLocalRowLookup(
         db,
         tables: const <String>{SilexgisTripTables.recordings},
       );

  final AppDatabase _db;
  final SilexgisServerVersionReread _reread;
  final SilexgisServerRowPlacer _placer;
  final ICaveTripRepository _trips;
  final SilexgisScanRemover _removeScan;
  final SilexgisLocalRowLookup _recordings;

  @override
  Set<SyncUploadSection> get sections => const <SyncUploadSection>{
    SyncUploadSection.tripRecordings,
    SyncUploadSection.tripPoints,
  };

  @override
  Future<String?> title(SilexgisHeldItem held) async {
    if (held.entityTable == SilexgisTripTables.recordings) {
      return (await _recordings.read(held.entityTable, held.entityUuid))?.title;
    }
    final scan = await _scan(held.entityUuid);
    if (scan == null) return null;
    return <String>[
      scan.read<String>('trip'),
      ?scan.read<String?>('place'),
    ].join(' · ');
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
      localUpdatedAt: await _updatedAt(held),
    );
    return _placer.place(
      profile.profileUuid,
      profile.syncSetId,
      held,
      held.current,
    );
  }

  @override
  Future<void> delete(SilexgisProfile profile, SilexgisHeldItem held) =>
      held.entityTable == SilexgisTripTables.recordings
      ? _trips.deleteCaveTrip(held.entityUuid)
      : _removeScan(held.entityUuid);

  Future<int?> _updatedAt(SilexgisHeldItem held) async =>
      held.entityTable == SilexgisTripTables.recordings
      ? (await _recordings.read(held.entityTable, held.entityUuid))?.updatedAt
      : (await _scan(held.entityUuid))?.read<int?>('updated_at');

  Future<QueryRow?> _scan(Uuid uuid) async {
    final rows = await _db
        .customSelect(
          'SELECT t.title AS trip, c.title AS place, p.updated_at AS updated_at '
          'FROM cave_trip_points p JOIN cave_trips t ON t.uuid = p.cave_trip_uuid '
          'LEFT JOIN cave_places c ON c.uuid = p.cave_place_uuid '
          'WHERE p.uuid = ? LIMIT 1',
          variables: <Variable<Object>>[Variable<Uint8List>(uuid.bytes)],
        )
        .get();
    return rows.isEmpty ? null : rows.single;
  }
}
