import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_trips.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_row_composer.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_upload_answers.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';

/// The `tripRecordings` section: the recordings this run creates, edits or
/// removes.
///
/// A recording goes up by the rule the feature rows follow: when its cave is
/// on the installation or goes in the same run. A recording made in a cave the
/// installation does not carry stays on the phone. One the installation holds
/// goes again only once it changed here, and one held for a reviewer only once
/// the caver edits it again.
///
/// The app makes no trip report on the installation: the server makes its own
/// from the recording, and the phone's report export stays a local export.
class SilexgisTripRecordingsUploadPart implements SilexgisUploadPart {
  SilexgisTripRecordingsUploadPart({
    required AppDatabase db,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisTripUploadAnswers answers,
    required String profileUuid,
    SilexgisTripRowComposer composer = const SilexgisTripRowComposer(),
  }) : _db = db,
       _localState = localState,
       _heldRows = heldRows,
       _answers = answers,
       _profileUuid = profileUuid,
       _composer = composer;

  final AppDatabase _db;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisTripUploadAnswers _answers;
  final String _profileUuid;
  final SilexgisTripRowComposer _composer;

  final Map<String, SilexgisPlannedTripItem> _planned =
      <String, SilexgisPlannedTripItem>{};

  @override
  SyncUploadSection get section => SyncUploadSection.tripRecordings;

  @override
  Future<List<SyncUploadItem>> build(SilexgisUploadContext context) async {
    final revisions = await _localState.readRevisions(_profileUuid);
    final held = await _heldRows.readSection(_profileUuid, section);
    final caves = <Uuid>{
      for (final e in revisions.entries)
        if (e.value.entityTable == 'caves') e.key,
      ...context.rowsSent,
    };

    final items = <SyncUploadItem>[];
    final present = <Uuid>{};
    for (final trip in await _db.select(_db.caveTrips).get()) {
      present.add(trip.uuid);
      final stored = _recordingRevision(revisions[trip.uuid]);
      if (stored == null && !caves.contains(trip.caveUuid)) continue;
      if (stored != null && stored.agreesWith(trip.updatedAt)) continue;
      if (held[trip.uuid]?.stillAsSent(trip.updatedAt) ?? false) continue;

      final item = _composer.recording(trip, baseRevision: stored?.revision);
      _planned[item.id] = SilexgisPlannedTripItem(
        id: trip.uuid,
        recordingId: trip.uuid,
        isScan: false,
        localUpdatedAt: trip.updatedAt,
      );
      context.tripsSent.add(trip.uuid);
      if (trip.createdByUserUuid case final author?) {
        context.authors.add(author);
      }
      items.add(item);
    }

    for (final entry in revisions.entries) {
      final stored = _recordingRevision(entry.value);
      if (stored == null || present.contains(entry.key)) continue;
      // A removal is never edited again, so a held one waits for its decision.
      if (held[entry.key]?.isDelete ?? false) continue;
      final item = SyncUploadTripRecording.delete(
        id: entry.key.toString(),
        baseRevision: stored.revision,
      );
      _planned[item.id] = SilexgisPlannedTripItem(
        id: entry.key,
        recordingId: entry.key,
        isScan: false,
        isDelete: true,
      );
      items.add(item);
    }
    return items;
  }

  @override
  Future<SilexgisPartAnswers> apply(
    List<SyncUploadItem> sent,
    List<SyncRowResult> answers, {
    required bool resent,
  }) => _answers.apply(section, _planned, answers);

  static StoredRevision? _recordingRevision(StoredRevision? stored) =>
      stored?.entityTable == SilexgisTripTables.recordings ? stored : null;
}
