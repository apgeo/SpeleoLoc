import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';

/// Reads an installation's people directory and takes its links.
///
/// The directory is replaced whole on every read. The links overwrite this
/// phone's choices — that is how a mapping made in the browser arrives — except
/// a choice made here and not yet sent.
class SilexgisPeopleReader {
  SilexgisPeopleReader({
    required AppDatabase db,
    required SilexgisSyncApi api,
    required SilexgisPeopleRepository people,
    required String profileUuid,
  }) : _db = db,
       _api = api,
       _people = people,
       _profileUuid = profileUuid;

  final AppDatabase _db;
  final SilexgisSyncApi _api;
  final SilexgisPeopleRepository _people;
  final String _profileUuid;

  /// The answers that mean the directory is not for this account now. Neither
  /// is a reason to retry; the next run asks the capabilities again.
  static const Set<String> offCodes = <String>{
    SilexgisCodes.featureDisabled,
    SilexgisCodes.accessForbidden,
  };

  /// Reads the directory. Returns how many cavers it lists.
  ///
  /// When the directory is off for this account, the cached copy is dropped —
  /// which is what stops the caver being offered a choice — and the refusal
  /// goes on to the caller.
  Future<int> run() async {
    try {
      final directory = await _api.people();
      await _db.transaction(() async {
        await _people.replaceDirectory(_profileUuid, directory.people);
        await _people.applyServerLinks(_profileUuid, directory.links);
      });
      return directory.people.length;
    } on SilexgisProblemException catch (e) {
      if (offCodes.contains(e.code)) {
        await _people.clearDirectory(_profileUuid);
      }
      rethrow;
    }
  }
}
