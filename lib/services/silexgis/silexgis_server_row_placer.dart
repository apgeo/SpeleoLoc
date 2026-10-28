import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_row_handler.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_version_reread.dart';

/// Puts the server's row of an item in place of the device's, whatever
/// section it belongs to.
///
/// The row is written now when the decision handed it over. When it did not —
/// that stream would not hand this account the row now — or it cannot be
/// written here, that section's stream alone is read again from the
/// beginning: the server's row did not change after the device's position, so
/// an incremental read would never bring it. The other streams keep their
/// positions.
class SilexgisServerRowPlacer {
  SilexgisServerRowPlacer({
    required SilexgisServerVersionReread reread,
    required List<SilexgisServerRowHandler> handlers,
  }) : _reread = reread,
       _handlers = <SyncUploadSection, SilexgisServerRowHandler>{
         for (final handler in handlers)
           for (final section in handler.sections) section: handler,
       };

  final SilexgisServerVersionReread _reread;
  final Map<SyncUploadSection, SilexgisServerRowHandler> _handlers;

  /// Returns true when the server's row is in place now; false when the next
  /// run of [setId] brings it.
  ///
  /// The local row must no longer be held back from what the server says —
  /// neither waiting for a reviewer nor edited since the two sides last
  /// agreed — or the write leaves it as the caver has it.
  Future<bool> place(
    String profileUuid,
    String? setId,
    SilexgisHeldItem held,
    Map<String, Object?>? current,
  ) async {
    final handler = _handlers[held.section];
    if (handler == null) return false;
    if (current != null && await handler.write(profileUuid, held, current)) {
      return true;
    }
    await _reread.rereadFromBeginning(profileUuid, setId, handler.stream);
    return false;
  }
}
