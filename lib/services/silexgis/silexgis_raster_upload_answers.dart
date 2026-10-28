import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_paged_stream_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_staged_upload_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// A map or pin one run sends.
class SilexgisPlannedRasterItem {
  const SilexgisPlannedRasterItem({
    required this.id,
    required this.mapId,
    required this.isPin,
    this.isDelete = false,
    this.localUpdatedAt,
    this.pictureSha256,
    this.transferId,
  });

  final Uuid id;

  /// The map itself, or the pin's.
  final Uuid mapId;
  final bool isPin;
  final bool isDelete;

  /// The local row's stamp as sent; null for a removal.
  final int? localUpdatedAt;

  /// The hash of the picture whose bytes went with a map, which becomes the
  /// installation's current picture once written.
  final String? pictureSha256;

  /// The staged upload those bytes wait under.
  final String? transferId;

  String get entityTable =>
      isPin ? SilexgisRasterTables.pins : SilexgisRasterTables.maps;

  SilexgisPlannedRasterItem withTransfer(String transferId) =>
      SilexgisPlannedRasterItem(
        id: id,
        mapId: mapId,
        isPin: isPin,
        isDelete: isDelete,
        localUpdatedAt: localUpdatedAt,
        pictureSha256: pictureSha256,
        transferId: transferId,
      );
}

/// Stores what the installation answered about the maps or pins of one
/// section — the same for both, since a pin is arbitrated exactly as its map
/// is.
///
/// A conflict carries no echo, and a pin refused because another marks its
/// place asks for the map to be read again: both drop the rasters stream's
/// position, so the next read hands the map over whole. The local row is left
/// as the caver has it, and the caver is told.
class SilexgisRasterUploadAnswers {
  SilexgisRasterUploadAnswers({
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisRasterStateRepository rasters,
    required SilexgisStagedUploadRepository staged,
    required SilexgisCursorStore rastersCursor,
    required String profileUuid,
  }) : _localState = localState,
       _heldRows = heldRows,
       _rasters = rasters,
       _staged = staged,
       _rastersCursor = rastersCursor,
       _profileUuid = profileUuid;

  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisRasterStateRepository _rasters;
  final SilexgisStagedUploadRepository _staged;
  final SilexgisCursorStore _rastersCursor;
  final String _profileUuid;
  final _log = AppLogger.of('SilexgisRasterUploadAnswers');

  Future<SilexgisPartAnswers> apply(
    SyncUploadSection section,
    Map<String, SilexgisPlannedRasterItem> planned,
    List<SyncRowResult> answers,
  ) async {
    final revisions = <SilexgisRevisionEntry>[];
    final sent = <SilexgisRasterState>[];
    final forgotten = <Uuid>[];
    final heldNow = <SilexgisHeldEntry>[];
    final answeredOtherwise = <Uuid>[];
    final refusals = <SilexgisRefusal>[];
    var reread = false;
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
            forgotten.addAll(await _withPins(item));
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
          // Bytes a resent create names are not adopted: the map was already
          // there, with the picture its first answer made.
          final adopted = answer.status != SyncRowStatus.unchanged;
          if (adopted && item.transferId != null) {
            await _staged.markAdopted(_profileUuid, item.id, item.transferId!);
          }
          sent.add(
            SilexgisRasterState(
              entityUuid: item.id,
              mapUuid: item.mapId,
              isPin: item.isPin,
              pictureSha256: adopted ? item.pictureSha256 : null,
            ),
          );
        case SyncRowStatus.deleted:
          forgotten.addAll(await _withPins(item));
        case SyncRowStatus.held:
          held++;
          final reviewId = answer.reviewId;
          if (reviewId == null) {
            _log.warning('a held answer named no review: ${answer.id}');
            break;
          }
          // A held new picture's staged bytes wait on the server with it.
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
        case SyncRowStatus.rejected when answer.code == SilexgisCodes.pinExists:
          reread = true;
          refusals.add(_refusal(item, answer));
        case SyncRowStatus.conflict:
          reread = true;
          refusals.add(_refusal(item, answer));
        case SyncRowStatus.rejected:
        case null:
          refusals.add(_refusal(item, answer));
      }
    }

    await _localState.writeRevisions(_profileUuid, revisions);
    await _rasters.recordSent(_profileUuid, sent);
    await _localState.forgetRevisions(_profileUuid, forgotten);
    await _rasters.forget(_profileUuid, forgotten);
    for (final id in forgotten) {
      await _staged.delete(_profileUuid, id);
    }
    await _heldRows.clear(_profileUuid, section, answeredOtherwise);
    await _heldRows.recordHeld(_profileUuid, heldNow);
    // With no `current` on a raster answer, the installation's version is had
    // by reading the stream from the beginning.
    if (reread) await _rastersCursor.drop();
    return SilexgisPartAnswers(refusals: refusals, held: held);
  }

  /// [item], and for a map the pins it took with it.
  Future<List<Uuid>> _withPins(SilexgisPlannedRasterItem item) async => <Uuid>[
    item.id,
    if (!item.isPin) ...await _rasters.pinsOf(_profileUuid, item.id),
  ];

  static SilexgisRefusal _refusal(
    SilexgisPlannedRasterItem item,
    SyncRowResult answer,
  ) => SilexgisRefusal(
    entityUuid: item.id,
    entityTable: item.entityTable,
    result: answer,
  );
}
