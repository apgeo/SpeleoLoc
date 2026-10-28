import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_trips.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_row_composer.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_upload_answers.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// The `tripPoints` section: the scans this run creates, edits or removes.
///
/// Built after the recordings part. A scan goes up when its recording is on
/// the installation, waits there for a reviewer, or goes in this run; and when
/// the place it names is on the installation or goes in this run — a scan sent
/// without its place would keep no place there once the place arrived.
///
/// A scan removed here is sent as a removal naming its recording. When the
/// whole recording was removed, its scans go with it and are not named.
class SilexgisTripPointsUploadPart implements SilexgisUploadPart {
  SilexgisTripPointsUploadPart({
    required AppDatabase db,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisTripStateRepository trips,
    required SilexgisTripUploadAnswers answers,
    required String profileUuid,
    SilexgisTripRowComposer composer = const SilexgisTripRowComposer(),
  }) : _db = db,
       _localState = localState,
       _heldRows = heldRows,
       _trips = trips,
       _answers = answers,
       _profileUuid = profileUuid,
       _composer = composer;

  final AppDatabase _db;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisTripStateRepository _trips;
  final SilexgisTripUploadAnswers _answers;
  final String _profileUuid;
  final SilexgisTripRowComposer _composer;
  final _log = AppLogger.of('SilexgisTripPointsUploadPart');

  final Map<String, SilexgisPlannedTripItem> _planned =
      <String, SilexgisPlannedTripItem>{};

  @override
  SyncUploadSection get section => SyncUploadSection.tripPoints;

  @override
  Future<List<SyncUploadItem>> build(SilexgisUploadContext context) async {
    final revisions = await _localState.readRevisions(_profileUuid);
    final held = await _heldRows.readSection(_profileUuid, section);
    final heldRecordings = await _heldRows.readSection(
      _profileUuid,
      SyncUploadSection.tripRecordings,
    );
    final recordings = <Uuid>{
      for (final e in revisions.entries)
        if (e.value.entityTable == SilexgisTripTables.recordings) e.key,
      ...context.tripsSent,
      ...heldRecordings.keys,
    };
    final places = <Uuid>{
      for (final e in revisions.entries)
        if (e.value.entityTable == 'cave_places') e.key,
      ...context.rowsSent,
    };

    final items = <SyncUploadItem>[];
    final present = <Uuid>{};
    for (final point in await _db.select(_db.caveTripPoints).get()) {
      present.add(point.uuid);
      if (!recordings.contains(point.caveTripUuid)) continue;
      final place = point.cavePlaceUuid;
      if (place != null && !places.contains(place)) continue;
      final stored = switch (revisions[point.uuid]) {
        final r? when r.entityTable == SilexgisTripTables.scans => r,
        _ => null,
      };
      if (stored != null && stored.agreesWith(point.updatedAt)) continue;
      if (held[point.uuid]?.stillAsSent(point.updatedAt) ?? false) continue;

      final item = _composer.scan(point, baseRevision: stored?.revision);
      _planned[item.id] = SilexgisPlannedTripItem(
        id: point.uuid,
        recordingId: point.caveTripUuid,
        isScan: true,
        localUpdatedAt: point.updatedAt,
      );
      context.tripsSent.add(point.uuid);
      if (point.createdByUserUuid case final author?) {
        context.authors.add(author);
      }
      items.add(item);
    }

    final states = await _trips.readAll(_profileUuid);
    final liveRecordings = <Uuid>{
      for (final trip in await _db.select(_db.caveTrips).get()) trip.uuid,
    };
    final orphans = <Uuid>[];
    for (final entry in revisions.entries) {
      if (entry.value.entityTable != SilexgisTripTables.scans) continue;
      if (present.contains(entry.key)) continue;
      if (held[entry.key]?.isDelete ?? false) continue;
      final recording = states[entry.key]?.recordingUuid;
      if (recording == null) {
        // Nothing here can name its recording any more, and a removal
        // without one is refused whole.
        _log.warning('a removed scan names no recording; forgetting it');
        orphans.add(entry.key);
        continue;
      }
      // The recording's own removal takes it.
      if (!liveRecordings.contains(recording)) continue;
      final item = SyncUploadTripPoint.delete(
        id: entry.key.toString(),
        recordingId: recording.toString(),
        baseRevision: entry.value.revision,
      );
      _planned[item.id] = SilexgisPlannedTripItem(
        id: entry.key,
        recordingId: recording,
        isScan: true,
        isDelete: true,
      );
      items.add(item);
    }
    await _localState.forgetRevisions(_profileUuid, orphans);
    return items;
  }

  @override
  Future<SilexgisPartAnswers> apply(
    List<SyncUploadItem> sent,
    List<SyncRowResult> answers, {
    required bool resent,
  }) => _answers.apply(section, _planned, answers);
}
