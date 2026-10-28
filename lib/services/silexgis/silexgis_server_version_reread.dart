import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';

/// Gives up the caver's version of one item so that the installation's can
/// take its place.
///
/// An incremental read never brings an unchanged item again, so when the
/// server's version did not come with the answer the stream it lives on is
/// read again from the beginning, and the item is no longer held back from
/// what that read brings.
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
  /// [localUpdatedAt] is the local row's stamp now. [revision] replaces the
  /// stored revision when the server's row is at hand. A removal forgets the
  /// revision instead: with none, the device sends no removal, and the next
  /// read brings the row back.
  Future<void> giveUp(
    String profileUuid,
    SilexgisHeldItem held, {
    int? localUpdatedAt,
    String? revision,
  }) async {
    final uuid = held.entityUuid;
    if (held.isDelete) {
      await _localState.forgetRevisions(profileUuid, <Uuid>[uuid]);
    } else {
      final stored = (await _localState.readRevisions(profileUuid))[uuid];
      final agreed = revision ?? stored?.revision;
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

  /// Has the next run read [stream] from the beginning; null stands for the
  /// feature download, whose position is kept apart from the other streams'.
  Future<void> rereadFromBeginning(
    SilexgisProfile profile,
    SyncStream? stream,
  ) async {
    final setId = profile.syncSetId;
    if (setId == null) return;
    if (stream == null) {
      await _localState.dropCursor(profile.profileUuid, setId);
    } else {
      await _localState.dropStreamCursor(profile.profileUuid, setId, stream);
    }
  }
}
