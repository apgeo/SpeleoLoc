import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';

/// One upload section's way of writing the server's own row of an item — the
/// `current` a decision hands over — through the applier that section's
/// stream is written with, so it lands exactly as a read would land it.
///
/// A section is covered by writing a handler and passing it to
/// `SilexgisServerRowPlacer`; nothing else branches on the section.
abstract interface class SilexgisServerRowHandler {
  Set<SyncUploadSection> get sections;

  /// The stream these rows arrive on; null for the feature download, whose
  /// position is kept apart from the other streams'.
  SyncStream? get stream;

  /// Writes [current], shaped as [stream] delivers it, in place of the local
  /// row of [held]. Returns true when the server's row is now in place; false
  /// when it could not be written here — its parent is not on this device,
  /// say — and only a fresh read of [stream] can bring it.
  Future<bool> write(
    String profileUuid,
    SilexgisHeldItem held,
    Map<String, Object?> current,
  );
}
