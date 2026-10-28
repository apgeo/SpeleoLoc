import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// A recording or scan one run sends.
class SilexgisPlannedTripItem {
  const SilexgisPlannedTripItem({
    required this.id,
    required this.recordingId,
    required this.isScan,
    this.isDelete = false,
    this.localUpdatedAt,
  });

  final Uuid id;

  /// The recording itself, or the scan's.
  final Uuid recordingId;
  final bool isScan;
  final bool isDelete;

  /// The local row's stamp as sent; null for a removal.
  final int? localUpdatedAt;

  String get entityTable =>
      isScan ? SilexgisTripTables.scans : SilexgisTripTables.recordings;
}

/// The local tables the trip sections come from.
abstract final class SilexgisTripTables {
  static const String recordings = 'cave_trips';
  static const String scans = 'cave_trip_points';
}

/// Stores what the installation answered about the recordings or scans of one
/// section — the same for both, since a scan is arbitrated exactly as its
/// recording is.
class SilexgisTripUploadAnswers {
  SilexgisTripUploadAnswers({
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisTripStateRepository trips,
    required String profileUuid,
  }) : _localState = localState,
       _heldRows = heldRows,
       _trips = trips,
       _profileUuid = profileUuid;

  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisTripStateRepository _trips;
  final String _profileUuid;
  final _log = AppLogger.of('SilexgisTripUploadAnswers');

  Future<SilexgisPartAnswers> apply(
    SyncUploadSection section,
    Map<String, SilexgisPlannedTripItem> planned,
    List<SyncRowResult> answers,
  ) async {
    final revisions = <SilexgisRevisionEntry>[];
    final sent = <SilexgisTripState>[];
    final forgotten = <Uuid>[];
    final heldNow = <SilexgisHeldEntry>[];
    final conflicts = <SilexgisConflictEntry>[];
    final answeredOtherwise = <Uuid>[];
    final refusals = <SilexgisRefusal>[];
    var held = 0;

    for (final answer in answers) {
      final item = planned[answer.id];
      if (item == null) {
        _log.warning('the answer names an item this batch did not send');
        continue;
      }
      if (answer.status != SyncRowStatus.held) answeredOtherwise.add(item.id);

      switch (answer.status) {
        case SyncRowStatus.created:
        case SyncRowStatus.updated:
        case SyncRowStatus.unchanged:
          if (item.isDelete) {
            // A removal of something never received is `unchanged`.
            forgotten.addAll(await _withScans(item));
            break;
          }
          if (answer.revision case final revision?) {
            revisions.add(
              SilexgisRevisionEntry(
                entityUuid: item.id,
                entityTable: item.entityTable,
                revision: revision,
                localUpdatedAt: item.localUpdatedAt,
              ),
            );
          }
          sent.add(
            SilexgisTripState(
              entityUuid: item.id,
              recordingUuid: item.recordingId,
              isScan: item.isScan,
            ),
          );
        case SyncRowStatus.deleted:
          forgotten.addAll(await _withScans(item));
        case SyncRowStatus.held:
          held++;
          final reviewId = answer.reviewId;
          if (reviewId == null) {
            _log.warning('a held answer named no review: ${answer.id}');
            break;
          }
          heldNow.add(
            SilexgisHeldEntry(
              section: section,
              entityUuid: item.id,
              entityTable: item.entityTable,
              reviewId: reviewId,
              isDelete: item.isDelete,
              sentLocalUpdatedAt: item.localUpdatedAt,
            ),
          );
        case SyncRowStatus.rejected
            when answer.code == SilexgisCodes.rowNotFound:
          // Not there after all: forgotten, it goes as new next time.
          forgotten.add(item.id);
          refusals.add(_refusal(item, answer));
        case SyncRowStatus.conflict:
          // A conflict comes with no echo to merge with, so the local edit
          // stays as it is, unsent, until the caver chooses what to do.
          conflicts.add(
            SilexgisConflictEntry(
              section: section,
              entityUuid: item.id,
              entityTable: item.entityTable,
              code: answer.code ?? SilexgisCodes.conflict,
              isDelete: item.isDelete,
              sentLocalUpdatedAt: item.localUpdatedAt,
            ),
          );
          refusals.add(_refusal(item, answer));
        case SyncRowStatus.rejected:
        case null:
          refusals.add(_refusal(item, answer));
      }
    }

    await _localState.writeRevisions(_profileUuid, revisions);
    await _trips.recordSent(_profileUuid, sent);
    await _localState.forgetRevisions(_profileUuid, forgotten);
    await _trips.forget(_profileUuid, forgotten);
    await _heldRows.clear(_profileUuid, section, answeredOtherwise);
    await _heldRows.recordHeld(_profileUuid, heldNow);
    await _heldRows.recordConflicts(_profileUuid, conflicts);
    return SilexgisPartAnswers(refusals: refusals, held: held);
  }

  /// [item], and for a recording the scans it took with it.
  Future<List<Uuid>> _withScans(SilexgisPlannedTripItem item) async => <Uuid>[
    item.id,
    if (!item.isScan) ...await _trips.scansOf(_profileUuid, item.id),
  ];

  static SilexgisRefusal _refusal(
    SilexgisPlannedTripItem item,
    SyncRowResult answer,
  ) => SilexgisRefusal(
    entityUuid: item.id,
    entityTable: item.entityTable,
    result: answer,
  );
}
