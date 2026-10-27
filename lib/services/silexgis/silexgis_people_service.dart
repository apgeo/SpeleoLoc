import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';

/// Which caver a phone user is on the active installation, and whom they may
/// be said to be.
class SilexgisCaverChoice {
  const SilexgisCaverChoice({
    required this.installation,
    required this.cavers,
    this.caverId,
    this.chosenOnServer = false,
    this.pending = false,
  });

  /// The installation's name, as the caver configured it.
  final String installation;
  final List<SilexgisCaver> cavers;

  /// The link as it stands here, or null when there is none.
  final String? caverId;

  /// The link came from the installation and is not this phone's choice — it
  /// was made in the browser, or while an archive was imported.
  final bool chosenOnServer;

  /// Chosen here and not sent yet.
  final bool pending;
}

/// The phone's side of the people directory, for the user screens.
///
/// Offered only with an active server profile whose last run was handed the
/// directory: an installation that stopped offering it, or an account that
/// may not be told who people are, leaves nothing to choose from.
class SilexgisPeopleService {
  SilexgisPeopleService({
    required SilexgisProfileRepository profiles,
    required SilexgisPeopleRepository people,
  }) : _profiles = profiles,
       _people = people;

  final SilexgisProfileRepository _profiles;
  final SilexgisPeopleRepository _people;

  /// The choice for [userUuid], or null when there is nothing to offer.
  Future<SilexgisCaverChoice?> choiceFor(Uuid userUuid) async {
    final profile = await _profiles.getDefaultProfile();
    if (profile == null) return null;
    final cavers = await _people.readDirectory(profile.profileUuid);
    if (cavers.isEmpty) return null;
    final link = await _people.readLink(profile.profileUuid, userUuid);
    return SilexgisCaverChoice(
      installation: profile.displayName,
      cavers: cavers,
      caverId: link?.caverId,
      chosenOnServer: link?.source == SilexgisLinkSource.server,
      pending: link?.choicePending ?? false,
    );
  }

  /// Says that [userUuid] is [caverId] on the active installation. Sent with
  /// the next sync.
  Future<void> choose(Uuid userUuid, String caverId) async {
    final profile = await _profiles.getDefaultProfile();
    if (profile == null) return;
    await _people.choose(profile.profileUuid, userUuid, caverId);
  }
}
