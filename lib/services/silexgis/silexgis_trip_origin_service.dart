import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';

/// The recordings on this device that came from an installation and that this
/// device did not make.
class SilexgisReceivedTrips {
  const SilexgisReceivedTrips({
    required this.installation,
    required this.recordings,
    this.recordedBy = const <Uuid, String>{},
  });

  /// The installation's name, as the caver configured it.
  final String installation;
  final Set<Uuid> recordings;

  /// The name of the caver who made a recording, for those the installation
  /// named one its people directory still lists.
  final Map<Uuid, String> recordedBy;

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
    required SilexgisPeopleRepository people,
  }) : _profiles = profiles,
       _trips = trips,
       _people = people;

  final SilexgisProfileRepository _profiles;
  final SilexgisTripStateRepository _trips;
  final SilexgisPeopleRepository _people;

  /// Null when there is no active installation, or nothing came from it.
  Future<SilexgisReceivedTrips?> received() async {
    final profile = await _profiles.getDefaultProfile();
    if (profile == null) return null;
    final recordings = await _trips.receivedRecordings(profile.profileUuid);
    if (recordings.isEmpty) return null;
    // Named only through the directory as last read: a caver it no longer
    // lists, or a directory no longer offered, names nobody.
    final names = <String, String>{
      for (final caver in await _people.readDirectory(profile.profileUuid))
        caver.caverId: caver.fullName,
    };
    return SilexgisReceivedTrips(
      installation: profile.displayName,
      recordings: recordings.keys.toSet(),
      recordedBy: <Uuid, String>{
        for (final MapEntry(key: recording, value: caver) in recordings.entries)
          recording: ?names[caver],
      },
    );
  }
}
