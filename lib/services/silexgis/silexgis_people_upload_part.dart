import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_people.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// The `people` section: the phone users this run has something to say about.
///
/// A user goes up when the caver chose a caver for them here and has not sent
/// it yet, or when the names sent before have changed since. A user nothing
/// was ever said about stays on the phone: being on this device is not a
/// reason for an installation to keep a record of somebody.
///
/// Only the user's own identifier and names travel, and a caver only when one
/// was chosen here — absent means "nothing to say about the link", so a link
/// made in the browser is never overwritten by silence.
class SilexgisPeopleUploadPart implements SilexgisUploadPart {
  SilexgisPeopleUploadPart({
    required AppDatabase db,
    required SilexgisPeopleRepository people,
    required String profileUuid,
  }) : _db = db,
       _people = people,
       _profileUuid = profileUuid;

  final AppDatabase _db;
  final SilexgisPeopleRepository _people;
  final String _profileUuid;
  final _log = AppLogger.of('SilexgisPeopleUploadPart');

  /// The names digest of each user built this run, by device user id.
  final Map<String, String> _hashes = <String, String>{};

  @override
  SyncUploadSection get section => SyncUploadSection.people;

  /// A digest of what the server keeps about a user's names. Stored after a
  /// send, so an unchanged user is not sent again.
  static String namesHash(User user) => sha256
      .convert(
        utf8.encode(
          jsonEncode(<String?>[user.username, user.firstName, user.lastName]),
        ),
      )
      .toString();

  @override
  Future<List<SyncUploadItem>> build(SilexgisUploadContext context) async {
    final links = await _people.readLinks(_profileUuid);
    final users = await (_db.select(
      _db.users,
    )..where((t) => t.deletedAt.isNull())).get();

    final items = <SyncUploadItem>[];
    for (final user in users) {
      final link = links[user.uuid];
      if (link == null) continue;
      final hash = namesHash(user);
      final choice = link.choicePending ? link.caverId : null;
      final renamed = link.sentNamesHash != null && link.sentNamesHash != hash;
      if (choice == null && !renamed) continue;

      final id = user.uuid.toString();
      _hashes[id] = hash;
      items.add(
        SyncUploadPerson(
          deviceUserId: id,
          username: user.username,
          firstName: user.firstName,
          lastName: user.lastName,
          caverId: choice,
        ),
      );
    }
    return items;
  }

  @override
  Future<SilexgisPartAnswers> apply(
    List<SyncUploadItem> sent,
    List<SyncRowResult> answers, {
    required bool resent,
  }) async {
    final byId = <String, SyncUploadPerson>{
      for (final item in sent.whereType<SyncUploadPerson>())
        item.deviceUserId: item,
    };
    final refusals = <SilexgisRefusal>[];
    final resend = <SyncUploadItem>[];
    var held = 0;

    for (final answer in answers) {
      final item = byId[answer.id];
      final userUuid = Uuid.tryParse(answer.id);
      final hash = _hashes[answer.id];
      if (item == null || userUuid == null || hash == null) {
        _log.warning('the answer names a person this batch did not send');
        continue;
      }

      switch (answer.status) {
        case SyncRowStatus.created:
        case SyncRowStatus.updated:
        case SyncRowStatus.unchanged:
        case SyncRowStatus.held:
          // People are not arbitrated, and what stands is what the next read
          // of the directory says — a link made in the browser is kept over
          // the phone's, and answered `updated` all the same.
          if (answer.status == SyncRowStatus.held) held++;
          await _people.recordSent(
            _profileUuid,
            userUuid,
            namesHash: hash,
            linkSent: item.caverId != null,
          );
        case SyncRowStatus.rejected
            when answer.code == SilexgisCodes.personNotListed:
          // The caver chosen is not one this account may name. The directory
          // is read again later in this run, and the caver chooses from it.
          await _people.clearChoice(_profileUuid, userUuid);
        case SyncRowStatus.rejected
            when answer.code == SilexgisCodes.featureDisabled &&
                item.caverId != null &&
                !resent:
          // The directory was switched off: the names still go, and the
          // choice waits for the directory to come back.
          resend.add(item.withoutCaver());
        case SyncRowStatus.rejected:
        case SyncRowStatus.conflict:
        case SyncRowStatus.deleted:
        case null:
          refusals.add(
            SilexgisRefusal(
              entityUuid: userUuid,
              entityTable: 'users',
              result: answer,
            ),
          );
      }
    }
    return SilexgisPartAnswers(refusals: refusals, resend: resend, held: held);
  }
}
