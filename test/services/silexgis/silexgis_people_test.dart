import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_people.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_reader.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/clock.dart';

import 'contract_fixtures.dart';
import 'scripted_client.dart';
import 'token_source.dart';

/// The phone's side of the people directory: which caver each phone user is,
/// what is said about them, and what the installation says back.
void main() {
  const profile = 'p-1';
  const setId = 'set-1';
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'upload', 'people'],
  );

  late AppDatabase db;
  late SilexgisPeopleRepository people;
  final clock = FakeClock(DateTime.utc(2026, 10, 27, 8));

  final ana = Uuid.v7();
  final dan = Uuid.v7();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    people = SilexgisPeopleRepository(db, clock: clock);
    for (final (uuid, username, first) in <(Uuid, String, String)>[
      (ana, 'ana', 'Ana'),
      (dan, 'dan', 'Dan'),
    ]) {
      await db
          .into(db.users)
          .insert(User(uuid: uuid, username: username, firstName: first));
    }
  });
  tearDown(() => db.close());

  SilexgisSyncApi apiFor(ScriptedClient client) => SilexgisSyncApi(
    SilexgisHttp(
      baseUri: Uri.parse('https://club.example.org'),
      tokens: FixedTokenSource(),
      client: client,
    ),
  );

  Future<User> userRow(Uuid uuid) =>
      (db.select(db.users)..where((t) => t.uuid.equalsValue(uuid))).getSingle();

  group('links', () {
    test('the directory\'s link replaces the phone\'s choice', () async {
      // That is how a mapping made in the browser arrives.
      await people.choose(profile, ana, 'caver-phone');
      await people.recordSent(profile, ana, namesHash: 'h', linkSent: true);

      await people.applyServerLinks(profile, <SyncPersonLink>[
        SyncPersonLink(deviceUserId: ana.toString(), caverId: 'caver-browser'),
      ]);

      final link = (await people.readLink(profile, ana))!;
      expect(link.caverId, 'caver-browser');
      expect(link.source, SilexgisLinkSource.server);
    });

    test('the phone\'s own choice, confirmed, stays the phone\'s', () async {
      await people.choose(profile, ana, 'caver-1');
      await people.recordSent(profile, ana, namesHash: 'h', linkSent: true);

      await people.applyServerLinks(profile, <SyncPersonLink>[
        SyncPersonLink(deviceUserId: ana.toString(), caverId: 'caver-1'),
      ]);

      expect(
        (await people.readLink(profile, ana))!.source,
        SilexgisLinkSource.phone,
      );
    });

    test('a choice not sent yet is not overwritten before it goes', () async {
      await people.choose(profile, ana, 'caver-new');

      await people.applyServerLinks(profile, <SyncPersonLink>[
        SyncPersonLink(deviceUserId: ana.toString(), caverId: 'caver-old'),
      ]);

      final link = (await people.readLink(profile, ana))!;
      expect(link.caverId, 'caver-new');
      expect(link.choicePending, isTrue);
    });
  });

  group('the people section', () {
    late SilexgisPeopleUploadPart part;

    setUp(() {
      part = SilexgisPeopleUploadPart(
        db: db,
        people: people,
        profileUuid: profile,
      );
    });

    Future<SilexgisUploadReport> send(List<ScriptedResponse> script) =>
        SilexgisUploadRunner(
          api: apiFor(ScriptedClient(script)),
          builder: SilexgisUploadBuilder(
            db: db,
            localState: SilexgisLocalStateRepository(db),
            heldRows: SilexgisHeldRowRepository(db),
            profileUuid: profile,
          ),
          localState: SilexgisLocalStateRepository(db),
          heldRows: SilexgisHeldRowRepository(db),
          profileUuid: profile,
          parts: <SilexgisPeopleUploadPart>[part],
        ).run(setId, capabilities: capabilities);

    ScriptedResponse answer(List<Map<String, Object?>> people) =>
        ScriptedResponse.json(
          path: SilexgisContract.uploadPath(setId),
          json: <String, Object?>{
            'batchId': '<batch>',
            'importBatchId': '<import>',
            'replayed': false,
            'written': people.length,
            'refused': 0,
            'rows': const <Object?>[],
            'people': people,
            'conflicts': const <Object?>[],
            'duplicates': const <Object?>[],
          },
        );

    Map<String, Object?> verdict(Uuid id, String status, {String? code}) =>
        <String, Object?>{
          'id': id.toString(),
          'status': status,
          'revision': null,
          'code': code,
          'detail': null,
        };

    test('says nothing about a user nothing was chosen or sent for', () async {
      expect(await part.build(SilexgisUploadContext()), isEmpty);
    });

    test('sends a chosen caver, once', () async {
      await people.choose(profile, ana, 'caver-1');

      final items = (await part.build(
        SilexgisUploadContext(),
      )).cast<SyncUploadPerson>();
      expect(items.single.deviceUserId, ana.toString());
      expect(items.single.caverId, 'caver-1');

      final report = await send(<ScriptedResponse>[
        answer(<Map<String, Object?>>[verdict(ana, 'created')]),
      ]);
      expect(report.batches, 1);

      final link = (await people.readLink(profile, ana))!;
      expect(link.choicePending, isFalse);
      expect(link.sentNamesHash, isNotNull);
      // Nothing changed since, so nothing goes next time.
      expect(await part.build(SilexgisUploadContext()), isEmpty);
    });

    test(
      'a renamed user goes again, with nothing to say about the link',
      () async {
        await people.choose(profile, ana, 'caver-1');
        await send(<ScriptedResponse>[
          answer(<Map<String, Object?>>[verdict(ana, 'created')]),
        ]);
        await (db.update(db.users)..where((t) => t.uuid.equalsValue(ana)))
            .write(const UsersCompanion(lastName: Value('Pop')));

        final items = (await part.build(
          SilexgisUploadContext(),
        )).cast<SyncUploadPerson>();
        expect(items.single.lastName, 'Pop');
        expect(items.single.caverId, isNull);
        expect(items.single.toJson().containsKey('caverId'), isFalse);
      },
    );

    test('a caver the directory does not list clears the choice', () async {
      await people.choose(profile, ana, 'caver-gone');

      final report = await send(<ScriptedResponse>[
        answer(<Map<String, Object?>>[
          verdict(ana, 'rejected', code: SilexgisCodes.personNotListed),
        ]),
      ]);

      expect(report.refusals, isEmpty);
      final link = (await people.readLink(profile, ana))!;
      expect(link.caverId, isNull);
      expect(link.choicePending, isFalse);
    });

    test(
      'a directory switched off takes the names without the caver',
      () async {
        await people.choose(profile, ana, 'caver-1');
        final client = ScriptedClient(<ScriptedResponse>[
          answer(<Map<String, Object?>>[
            verdict(ana, 'rejected', code: SilexgisCodes.featureDisabled),
          ]),
          answer(<Map<String, Object?>>[verdict(ana, 'created')]),
        ]);

        await SilexgisUploadRunner(
          api: apiFor(client),
          builder: SilexgisUploadBuilder(
            db: db,
            localState: SilexgisLocalStateRepository(db),
            heldRows: SilexgisHeldRowRepository(db),
            profileUuid: profile,
          ),
          localState: SilexgisLocalStateRepository(db),
          heldRows: SilexgisHeldRowRepository(db),
          profileUuid: profile,
          parts: <SilexgisPeopleUploadPart>[part],
        ).run(setId, capabilities: capabilities);

        expect(client.sent, hasLength(2));
        final first = (client.sent.first.jsonBody['people']! as List).single;
        final second = (client.sent.last.jsonBody['people']! as List).single;
        expect(first, containsPair('caverId', 'caver-1'));
        expect((second as Map).containsKey('caverId'), isFalse);
        expect(
          client.sent.first.jsonBody['batchId'],
          isNot(client.sent.last.jsonBody['batchId']),
        );
        // The choice waits for the directory to come back.
        final link = (await people.readLink(profile, ana))!;
        expect(link.caverId, 'caver-1');
        expect(link.choicePending, isTrue);
        expect(
          link.sentNamesHash,
          SilexgisPeopleUploadPart.namesHash(await userRow(ana)),
        );
      },
    );

    test('describes an author of what the run sends, once', () async {
      final context = SilexgisUploadContext()..authors.add(ana);
      final items = (await part.build(context)).cast<SyncUploadPerson>();
      expect(items.single.deviceUserId, ana.toString());
      // Nothing was chosen, so nothing is said about the link.
      expect(items.single.toJson().containsKey('caverId'), isFalse);

      await part.apply(items, <SyncRowResult>[
        SyncRowResult(id: ana.toString(), status: SyncRowStatus.created),
      ], resent: false);
      expect(
        await part.build(SilexgisUploadContext()..authors.add(ana)),
        isEmpty,
      );
    });

    test('never names the device or the user signed in on it', () async {
      await people.choose(profile, ana, 'caver-1');
      final items = await part.build(SilexgisUploadContext());
      expect(items.single.toJson().keys.toSet(), <String>{
        'deviceUserId',
        'username',
        'firstName',
        'lastName',
        'caverId',
      });
    });
  });

  group('reading the directory', () {
    test('23: replaces the directory whole and takes the links', () async {
      await db
          .into(db.silexgisPerson)
          .insert(
            SilexgisPersonCompanion.insert(
              profileUuid: profile,
              caverId: 'no-longer-listed',
              fullName: 'Gone',
            ),
          );
      final recorded = fillPlaceholders(
        ContractExchange('23-people').responseBody,
        <String, String>{'<clubmate>': 'caver-mate', '<me>': 'caver-me'},
      )!;
      final body = <String, Object?>{
        ...recorded as Map<String, Object?>,
        'links': <Object?>[
          <String, Object?>{
            'deviceUserId': dan.toString(),
            'caverId': 'caver-mate',
          },
        ],
      };

      final count = await SilexgisPeopleReader(
        db: db,
        api: apiFor(
          ScriptedClient(<ScriptedResponse>[
            ScriptedResponse.json(
              path: SilexgisContract.peoplePath,
              json: body,
            ),
          ]),
        ),
        people: people,
        profileUuid: profile,
      ).run();

      expect(count, 3);
      final directory = await people.readDirectory(profile);
      expect(
        directory.map((c) => c.caverId),
        isNot(contains('no-longer-listed')),
      );
      expect(directory.singleWhere((c) => c.isMe).caverId, 'caver-me');
      final link = (await people.readLink(profile, dan))!;
      expect(link.caverId, 'caver-mate');
      expect(link.source, SilexgisLinkSource.server);
    });

    for (final (status, code) in <(int, String)>[
      (409, SilexgisCodes.featureDisabled),
      (403, SilexgisCodes.accessForbidden),
    ]) {
      test('$code drops the directory and stops', () async {
        await people.replaceDirectory(profile, const <SyncPerson>[
          SyncPerson(id: 'caver-1', fullName: 'Invented Caver'),
        ]);
        final reader = SilexgisPeopleReader(
          db: db,
          api: apiFor(
            ScriptedClient(<ScriptedResponse>[
              ScriptedResponse.problem(
                path: SilexgisContract.peoplePath,
                status: status,
                code: code,
              ),
            ]),
          ),
          people: people,
          profileUuid: profile,
        );

        await expectLater(
          reader.run(),
          throwsA(isA<SilexgisProblemException>()),
        );
        expect(await people.readDirectory(profile), isEmpty);
      });
    }
  });

  group('the choice on the user screen', () {
    late SilexgisProfileRepository profiles;
    late SilexgisPeopleService service;

    setUp(() {
      profiles = SilexgisProfileRepository(
        ConfigurationRepository(db),
        InMemoryRefreshTokenStore(),
        SilexgisLocalStateRepository(db),
      );
      service = SilexgisPeopleService(profiles: profiles, people: people);
    });

    test('is not offered without a server', () async {
      expect(await service.choiceFor(ana), isNull);
    });

    test('is not offered without a directory', () async {
      await profiles.save(
        const SilexgisProfile(
          profileUuid: profile,
          displayName: 'Clubul Speo Example',
          baseUrl: 'https://club.example.org',
          accountEmail: 'caver@example.org',
        ),
      );
      expect(await service.choiceFor(ana), isNull);
    });

    test('offers the directory and records the choice', () async {
      await profiles.save(
        const SilexgisProfile(
          profileUuid: profile,
          displayName: 'Clubul Speo Example',
          baseUrl: 'https://club.example.org',
          accountEmail: 'caver@example.org',
        ),
      );
      await people.replaceDirectory(profile, const <SyncPerson>[
        SyncPerson(id: 'caver-1', fullName: 'Invented Caver'),
      ]);

      final before = (await service.choiceFor(ana))!;
      expect(before.installation, 'Clubul Speo Example');
      expect(before.cavers.single.fullName, 'Invented Caver');
      expect(before.caverId, isNull);

      await service.choose(ana, 'caver-1');
      final after = (await service.choiceFor(ana))!;
      expect(after.caverId, 'caver-1');
      expect(after.pending, isTrue);
      expect(after.chosenOnServer, isFalse);
    });
  });
}
