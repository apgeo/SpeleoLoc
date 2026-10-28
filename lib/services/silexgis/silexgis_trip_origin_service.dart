import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';

/// The recordings on this device that came from an installation and that this
/// device did not make.
class SilexgisReceivedTrips {
  const SilexgisReceivedTrips({
    required this.installation,
    required this.recordings,
  });

  /// The installation's name, as the caver configured it.
  final String installation;
  final Set<Uuid> recordings;

  bool contains(Uuid recording) => recordings.contains(recording);
}

/// Which of the trips list's recordings are another phone's, read from the
/// active installation — so the list can keep them out of the way.
///
/// Answers only with an active server profile: without one, every recording
/// on the device is shown as it always was.
class SilexgisTripOriginService {
  SilexgisTripOriginService({
    required SilexgisProfileRepository profiles,
    required SilexgisTripStateRepository trips,
  }) : _profiles = profiles,
       _trips = trips;

  final SilexgisProfileRepository _profiles;
  final SilexgisTripStateRepository _trips;

  /// Null when there is no active installation, or nothing came from it.
  Future<SilexgisReceivedTrips?> received() async {
    final profile = await _profiles.getDefaultProfile();
    if (profile == null) return null;
    final recordings = await _trips.receivedRecordings(profile.profileUuid);
    if (recordings.isEmpty) return null;
    return SilexgisReceivedTrips(
      installation: profile.displayName,
      recordings: recordings.keys.toSet(),
    );
  }
}
