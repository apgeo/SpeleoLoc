import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_feature_rekeyer.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';

/// Sends a feature row the installation removed up again as a new row, with
/// everything inside it.
///
/// Sending it again is the caver's decision, never the client's: either
/// asked for outright, or given in advance by keeping the row after being
/// told that editing it later sends it again. The row and its subtree get
/// new identifiers, and the row is marked so that the next run sends it even
/// when it is a new root, which the upload otherwise leaves to the caver's
/// setting.
class SilexgisResendAsNew {
  SilexgisResendAsNew({
    required SilexgisFeatureRekeyer rekeyer,
    required SilexgisHeldRowRepository heldRows,
  }) : _rekeyer = rekeyer,
       _heldRows = heldRows;

  final SilexgisFeatureRekeyer _rekeyer;
  final SilexgisHeldRowRepository _heldRows;

  /// Sends [held] again as new. Returns the row's new identifier, or null
  /// when [held] is not a row removed there that this device still holds.
  Future<Uuid?> resend(String profileUuid, SilexgisHeldItem held) async {
    if (!held.isDeletedOnServer || held.isDelete) return null;
    final renamed = await _rekeyer.rekey(
      profileUuid,
      held.entityTable,
      held.entityUuid,
    );
    final fresh = renamed[held.entityUuid];
    if (fresh == null) return null;
    await _heldRows.recordResentAsNew(
      profileUuid,
      fresh,
      entityTable: held.entityTable,
      wireKind: held.wireKind,
    );
    return fresh;
  }

  /// Sends again as new each kept row that the caver has edited since
  /// keeping it, itself or anything inside it. Returns how many went.
  Future<int> resendEdited(String profileUuid) async {
    var resent = 0;
    final held = await _heldRows.readSection(
      profileUuid,
      SyncUploadSection.rows,
    );
    for (final item in held.values) {
      if (!item.isKeptAfterRemoval || item.isDelete) continue;
      // A row inside one sent again a moment ago is already gone under its
      // old identifier, and this finds nothing.
      final rows = await _rekeyer.subtree(item.entityTable, item.entityUuid);
      if (rows.isEmpty || !_editedSinceKept(item, rows)) continue;
      if (await resend(profileUuid, item) != null) resent++;
    }
    return resent;
  }

  /// The row itself no longer carries the stamp it had when the server
  /// removed it, or something inside it was changed after the caver kept it.
  static bool _editedSinceKept(
    SilexgisHeldItem item,
    List<SilexgisSubtreeRow> rows,
  ) {
    if (!item.stillAsSent(rows.first.updatedAt)) return true;
    final keptAt = item.keptAt!;
    return rows.skip(1).any((row) => (row.updatedAt ?? 0) > keptAt);
  }
}
