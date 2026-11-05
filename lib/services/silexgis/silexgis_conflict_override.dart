import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';

/// Sends the caver's version of an item over the installation's newer one.
///
/// A conflict that came back with the server's row says which revision is
/// current there. Stored as the item's base revision, with no local stamp to
/// agree with, it makes the item due to be sent, and the next run sends it
/// against that revision — which the server writes, unless somebody changed
/// the item there yet again, which is a new conflict.
class SilexgisConflictOverride {
  SilexgisConflictOverride({
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
  }) : _localState = localState,
       _heldRows = heldRows;

  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;

  /// The revision the server's row carries, when [held] is an edit whose
  /// conflict came back with that row.
  static String? serverRevisionOf(SilexgisHeldItem held) {
    if (!held.isConflict || held.isDelete) return null;
    final revision = held.current?['updatedAt'];
    return revision is String && revision.isNotEmpty ? revision : null;
  }

  /// Returns false, changing nothing, when [held] carries no server revision.
  Future<bool> sendMineAnyway(String profileUuid, SilexgisHeldItem held) async {
    final revision = serverRevisionOf(held);
    if (revision == null) return false;
    final stored = (await _localState.readRevisions(
      profileUuid,
    ))[held.entityUuid];
    await _localState.writeRevision(
      profileUuid,
      held.entityUuid,
      entityTable: held.entityTable,
      wireKind: held.wireKind ?? stored?.wireKind,
      revision: revision,
    );
    await _heldRows.clear(profileUuid, held.section, <Uuid>[held.entityUuid]);
    return true;
  }
}
