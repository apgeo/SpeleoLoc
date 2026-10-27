import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_people.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';

import 'contract_fixtures.dart';

/// Replays the recorded read of the people directory, and composes the
/// `people` section of an upload.
void main() {
  group('23-people', () {
    final exchange = ContractExchange('23-people');

    test('is a plain read of the account\'s directory', () {
      expect(exchange.requestLine, 'GET ${SilexgisContract.peoplePath}');
    });

    test('lists cavers by name only, and the account\'s own', () {
      final directory = SyncPeopleDirectory.fromJson(exchange.responseBody);
      expect(directory.people, hasLength(3));
      expect(directory.links, isEmpty);

      final mate = directory.people.first;
      expect(mate.id, '<clubmate>');
      expect(mate.shortName, 'Mate');
      expect(mate.hasAccount, isFalse);
      expect(mate.isMe, isFalse);

      final me = directory.people.singleWhere((p) => p.isMe);
      expect(me.id, '<me>');
      expect(me.hasAccount, isTrue);
      expect(me.shortName, isNull);

      // Names only: nothing that reaches a person travels here.
      for (final person
          in (exchange.responseBody['people']! as List).cast<Map>()) {
        expect(person.keys.toSet(), <String>{
          'id',
          'fullName',
          'shortName',
          'hasAccount',
          'isMe',
        });
      }
    });

    test('a link names a phone user and a caver, or none', () {
      final directory = SyncPeopleDirectory.fromJson(const <String, Object?>{
        'people': <Object?>[],
        'links': <Object?>[
          <String, Object?>{'deviceUserId': 'u-1', 'caverId': 'c-1'},
          <String, Object?>{'deviceUserId': 'u-2', 'caverId': null},
        ],
      });
      expect(directory.links.first.caverId, 'c-1');
      expect(directory.links.last.caverId, isNull);
    });
  });

  group('16-errors/feature-disabled', () {
    test('the directory switched off is a stop, not an empty directory', () {
      final exchange = ContractExchange('16-errors/feature-disabled');
      expect(exchange.requestTarget, SilexgisContract.peoplePath);
      final problem = SilexgisProblem.tryParse(
        exchange.status,
        exchange.responseBody,
      )!;
      expect(problem.code, SilexgisCodes.featureDisabled);
      expect(problem.action, SilexgisAction.stop);
    });
  });

  group('the people section', () {
    test('states a caver only when there is one to state', () {
      const chosen = SyncUploadPerson(
        deviceUserId: 'u-1',
        username: 'ana',
        firstName: 'Ana',
        lastName: 'Pop',
        caverId: 'c-1',
      );
      expect(chosen.toJson(), <String, Object?>{
        'deviceUserId': 'u-1',
        'username': 'ana',
        'firstName': 'Ana',
        'lastName': 'Pop',
        'caverId': 'c-1',
      });
      // Absent is "nothing to say about the link", which leaves a link made
      // in the browser as it stands.
      expect(chosen.withoutCaver().toJson().containsKey('caverId'), isFalse);
    });

    test('goes beside rows, and alone when there are none', () {
      const batch = SyncUploadBatch(
        batchId: '<batch>',
        clientFeatures: SilexgisContract.clientFeatures,
        sections: <SyncUploadSection, List<SyncUploadItem>>{
          SyncUploadSection.people: <SyncUploadItem>[
            SyncUploadPerson(deviceUserId: 'u-1', username: 'ana'),
          ],
        },
      );
      final json = batch.toJson();
      expect(json.containsKey('rows'), isFalse);
      expect((json['people']! as List).single, containsPair('username', 'ana'));
      // Which device, and who is signed in on it, never travel.
      final encoded = json.toString();
      expect(encoded, isNot(contains('device_uuid')));
      expect(encoded, isNot(contains('current_user')));
    });

    test('an item is answered in the shape a row is', () {
      final answer = SyncRowResult.fromJson(const <String, Object?>{
        'id': 'u-1',
        'status': 'rejected',
        'revision': null,
        'code': 'sync.person_not_listed',
        'detail': 'Not in the directory.',
      });
      expect(answer.action, SilexgisAction.applyAndResubmit);
      final off = SyncRowResult.fromJson(const <String, Object?>{
        'id': 'u-1',
        'status': 'rejected',
        'code': 'sync.feature_disabled',
      });
      expect(off.action, SilexgisAction.applyAndResubmit);
    });
  });
}
