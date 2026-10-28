import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_trips.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_row_handler.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// The server's row of a recording — with its scans — or of one scan, written
/// by the trips stream's applier.
///
/// A scan comes without its recording, so it is written under the one this
/// device holds it in, or held it in before the caver removed it.
class SilexgisTripServerRow implements SilexgisServerRowHandler {
  SilexgisTripServerRow({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisTripStateRepository trips,
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _heldRows = heldRows,
       _trips = trips,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisTripStateRepository _trips;
  final Clock _clock;

  @override
  Set<SyncUploadSection> get sections => const <SyncUploadSection>{
    SyncUploadSection.tripRecordings,
    SyncUploadSection.tripPoints,
  };

  @override
  SyncStream get stream => SyncStream.trips;

  @override
  Future<bool> write(
    String profileUuid,
    SilexgisHeldItem held,
    Map<String, Object?> current,
  ) async {
    final applier = SilexgisTripApplier(
      db: _db,
      logger: _logger,
      localState: _localState,
      heldRows: _heldRows,
      trips: _trips,
      profileUuid: profileUuid,
      clock: _clock,
    );
    if (held.section == SyncUploadSection.tripRecordings) {
      final applied = await applier.applyPage(
        SyncTripsPage(
          setRevision: 0,
          recordings: <SyncTripRecording>[SyncTripRecording.fromJson(current)],
          tombstones: const <SyncTombstone>[],
          nextCursor: null,
          hasMore: false,
        ),
      );
      return applied.recordingsInserted + applied.recordingsUpdated > 0;
    }
    final recording = await _recordingOf(profileUuid, held.entityUuid);
    if (recording == null) return false;
    final applied = await applier.applyScan(
      recording,
      SyncTripPoint.fromJson(current),
    );
    return applied.scansInserted + applied.scansUpdated > 0;
  }

  Future<Uuid?> _recordingOf(String profileUuid, Uuid scan) async =>
      (await (_db.select(
            _db.caveTripPoints,
          )..where((t) => t.uuid.equalsValue(scan))).getSingleOrNull())
          ?.caveTripUuid ??
      (await _trips.readAll(profileUuid))[scan]?.recordingUuid;
}
