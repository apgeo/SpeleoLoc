import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';

/// Something an installation did not write that only the caver can settle: a
/// row a reviewer turned down or that failed when written, a row that met a
/// later version on the server, or a pin whose place another pin already
/// marks.
class SilexgisDecision {
  const SilexgisDecision({required this.held, required this.isNew, this.title});

  final SilexgisHeldItem held;

  /// The item's name here, or the server's when it is gone locally.
  final String? title;

  /// The item is not on the server at all: there is no version of it there to
  /// go back to.
  final bool isNew;

  SyncUploadSection get section => held.section;
  bool get isConflict => held.isConflict;
  bool get isPinExists => held.code == SilexgisCodes.pinExists;

  /// Whether the server's version comes with it, so going back to it needs no
  /// further read.
  bool get hasServerRow => held.current != null;

  /// A conflict means the server holds a later version, even of an item this
  /// device has no revision of. Another pin on the same place is not a version
  /// of this pin.
  bool get canUseServerVersion => !isPinExists && (!isNew || isConflict);

  /// Only an item the server never had can be thrown away here without that
  /// being a removal to send.
  bool get canDelete => isNew && !held.isDelete && !isPinExists;

  /// The pin goes, so the one already on the server can take its place.
  bool get canRemovePin => isPinExists && !held.isDelete;
}

/// One upload section's part in settling decisions: how its items are named,
/// whether the installation has them, and how each choice is carried out.
///
/// A section is added to the decisions page by writing a resolver and passing
/// it to [SilexgisDecisionsService]; nothing else branches on the section.
abstract interface class SilexgisDecisionResolver {
  Set<SyncUploadSection> get sections;

  /// The item's name on this device, or null when its local row is gone.
  Future<String?> title(SilexgisHeldItem held);

  /// Whether the installation never had the item.
  Future<bool> isNew(
    SilexgisHeldItem held,
    Map<Uuid, StoredRevision> revisions,
  );

  /// Gives up the caver's version for the installation's, and forgets the
  /// decision. Returns true when the server's version is already in place;
  /// false when the next run brings it.
  Future<bool> useServerVersion(SilexgisProfile profile, SilexgisHeldItem held);

  /// Throws the local item away — the caver's own deletion, logged like any
  /// other.
  Future<void> delete(SilexgisProfile profile, SilexgisHeldItem held);
}
