import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';

/// Whether an item the caver is about to delete is also held by the active
/// SilexGIS installation.
///
/// A deletion travels: an item the installation holds is removed there on the
/// next sync, for everyone who reads it, and from there on the phone that
/// made it. A screen asks this before it confirms a deletion, so the caver is
/// told before rather than after.
class SilexgisServerPresence {
  SilexgisServerPresence({
    required SilexgisProfileRepository profiles,
    required SilexgisLocalStateRepository localState,
  }) : _profiles = profiles,
       _localState = localState;

  final SilexgisProfileRepository _profiles;
  final SilexgisLocalStateRepository _localState;

  /// The installation's name when it holds [uuid]; null when no installation
  /// is configured or it does not.
  Future<String?> holdingInstallation(Uuid uuid) async {
    final profile = await _profiles.getDefaultProfile();
    if (profile == null) return null;
    final revision = await _localState.readRevision(profile.profileUuid, uuid);
    return revision == null ? null : profile.displayName;
  }

  /// The installation's name and how many of [uuids] it holds, for a
  /// deletion of several items at once; null when it holds none of them.
  Future<({String installation, int count})?> holdingInstallationOfAny(
    Iterable<Uuid> uuids,
  ) async {
    final profile = await _profiles.getDefaultProfile();
    if (profile == null) return null;
    var count = 0;
    for (final uuid in uuids) {
      final revision = await _localState.readRevision(
        profile.profileUuid,
        uuid,
      );
      if (revision != null) count++;
    }
    return count == 0
        ? null
        : (installation: profile.displayName, count: count);
  }
}
