import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';

/// Gives up the caver's version of one item so that the installation's can
/// take its place.
///
/// The item is no longer held back from what the server says, whether that
/// comes with the answer or from reading its stream again. An incremental read
/// never brings an unchanged item again, so that read starts from the
/// beginning.
class SilexgisServerVersionReread {
  SilexgisServerVersionReread({
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
  }) : _localState = localState,
       _heldRows = heldRows;

  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;

  /// Marks [held] as agreeing with the installation as far as the device can
  /// tell — neither sent nor held back — and forgets the decision.
  ///
  /// [localUpdatedAt] is the local row's stamp now. A removal forgets the
  /// revision instead: with none, the device sends no removal, and the
  /// server's row is written back as one never held.
  Future<void> giveUp(
    String profileUuid,
    SilexgisHeldItem held, {
    int? localUpdatedAt,
  }) async {
    final uuid = held.entityUuid;
    if (held.isDelete) {
      await _localState.forgetRevisions(profileUuid, <Uuid>[uuid]);
    } else {
      final stored = (await _localState.readRevisions(profileUuid))[uuid];
      final agreed = stored?.revision;
      if (agreed != null) {
        await _localState.writeRevision(
          profileUuid,
          uuid,
          entityTable: held.entityTable,
          wireKind: held.wireKind ?? stored?.wireKind,
          revision: agreed,
          localUpdatedAt: localUpdatedAt,
        );
      }
    }
    await _heldRows.clear(profileUuid, held.section, <Uuid>[uuid]);
  }

  /// Has the next run of [setId] read [stream] from the beginning; null
  /// stands for the feature download, whose position is kept apart from the
  /// other streams'.
  Future<void> rereadFromBeginning(
    String profileUuid,
    String? setId,
    SyncStream? stream,
  ) async {
    if (setId == null) return;
    if (stream == null) {
      await _localState.dropCursor(profileUuid, setId);
    } else {
      await _localState.dropStreamCursor(profileUuid, setId, stream);
    }
  }
}
