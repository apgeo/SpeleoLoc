import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/documentation_repository.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_documents_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_session.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_transfer_api.dart';
import 'package:speleoloc/services/user_repository.dart';

import 'scripted_client.dart';

/// What a documents list is offered from the server, and when it is offered
/// nothing at all.
void main() {
  const profile = SilexgisProfile(
    profileUuid: 'p-1',
    displayName: 'Clubul Speo Example',
    baseUrl: 'https://club.example.org',
    accountEmail: 'caver@example.org',
    syncSetId: 'set-1',
  );

  late AppDatabase db;
  late SilexgisProfileRepository profiles;
  late InMemoryRefreshTokenStore tokens;
  late SilexgisDocumentCatalogueRepository catalogue;
  late DocumentationRepository documents;

  final caveId = Uuid.v7();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final users = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      users,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    loggerRef = ChangeLogger(db, currentUser);
    tokens = InMemoryRefreshTokenStore();
    profiles = SilexgisProfileRepository(
      ConfigurationRepository(db),
      tokens,
      SilexgisLocalStateRepository(db),
    );
    catalogue = SilexgisDocumentCatalogueRepository(db);
    documents = DocumentationRepository(db, loggerRef, currentUser);
  });
  tearDown(() => db.close());

  SilexgisDocumentsService serviceFor([ScriptedClient? client]) =>
      SilexgisDocumentsService(
        profiles: profiles,
        catalogue: catalogue,
        documents: documents,
        sessionBuilder: (p) {
          final auth = SilexgisAuthService(
            baseUri: p.baseUri,
            profileUuid: p.profileUuid,
            store: tokens,
            client: client,
          );
          final http = SilexgisHttp(
            baseUri: p.baseUri,
            tokens: auth,
            client: client,
          );
          return SilexgisSession(
            auth: auth,
            api: SilexgisSyncApi(http),
            transfers: SilexgisTransferApi(http),
          );
        },
        downloaderBuilder: (_, _) =>
            throw StateError('nothing is fetched in these tests'),
      );

  Map<String, Object?> link(
    String id,
    Uuid documentId, {
    String role = 'photoInterior',
    String reach = 'original',
    int? size = 2048,
    String? sha,
    bool usual = false,
    List<int> renditions = const <int>[2400, 1200, 480, 160],
  }) => <String, Object?>{
    'id': id,
    'documentId': documentId.toString(),
    'target': <String, Object?>{'kind': 'feature', 'id': caveId.toString()},
    'role': role,
    'sortOrder': 0,
    'inDefaultSet': usual,
    'document': <String, Object?>{
      'id': documentId.toString(),
      'title': 'invented $id',
      'fileKind': 'photo',
      'mimeType': 'image/jpeg',
      'sizeBytes': size,
      'sha256': sha,
      'versionId': 'v1',
      'reach': reach,
      'renditions': renditions,
      'updatedAt': '2026-10-27T10:00:00Z',
    },
  };

  Future<void> catalogued(List<Map<String, Object?>> links) =>
      catalogue.applyPage(
        profile.profileUuid,
        SyncDocumentsPage.fromJson(<String, Object?>{
          'setRevision': 1,
          'links': links,
          'nextCursor': 'c1',
          'hasMore': false,
        }),
      );

  test('with no server profile, nothing is offered', () async {
    // A catalogue left behind by a forgotten profile shows nothing either.
    await catalogue.applyPage(
      profile.profileUuid,
      SyncDocumentsPage.fromJson(<String, Object?>{
        'links': <Object?>[link('l1', Uuid.v7())],
      }),
    );

    expect(await serviceFor().forFeature(caveId), isNull);
  });

  test(
    'lists what is not held here, and marks what cannot be fetched',
    () async {
      await profiles.save(profile);
      final held = Uuid.v7();
      final sameBytes = Uuid.v7();
      final withoutLocation = Uuid.v7();
      final none = Uuid.v7();
      final map = Uuid.v7();
      await catalogued(<Map<String, Object?>>[
        link('held', held),
        link('same', sameBytes, sha: 'ab' * 32, usual: true),
        link('free', withoutLocation, reach: 'locationFree', size: null),
        link('none', none, reach: 'none', renditions: const <int>[]),
        link('map', map, role: 'map2d'),
      ]);
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: held,
              title: 'Fetched before',
              fileName: 'documentation_files/srv_held.jpg',
              fileSize: 2048,
              fileType: 'photo',
            ),
          );
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: Uuid.v7(),
              title: 'My own',
              fileName: 'documentation_files/doc_own.jpg',
              fileSize: 2048,
              fileType: 'photo',
            ).copyWith(fileHash: Value('ab' * 32)),
          );

      final server = (await serviceFor().forFeature(caveId))!;

      expect(server.installation, 'Clubul Speo Example');
      final byId = <Uuid, SilexgisServerDocument>{
        for (final d in server.documents) d.documentId: d,
      };
      expect(
        byId.keys,
        unorderedEquals(<Uuid>[sameBytes, withoutLocation, none]),
      );
      expect(byId[sameBytes]!.sameBytesHeld, isTrue);
      expect(byId[sameBytes]!.canDownload, isFalse);
      expect(byId[withoutLocation]!.withoutLocation, isTrue);
      expect(byId[withoutLocation]!.sizeBytes, isNull);
      expect(byId[withoutLocation]!.canDownload, isTrue);
      // Listed, and not downloadable.
      expect(byId[none]!.canDownload, isFalse);
      // A curated file the device already holds is not among the usual ones.
      expect(server.usual, isEmpty);
    },
  );

  test('the usual files show what they would cost first', () async {
    await profiles.save(profile);
    final a = Uuid.v7();
    final b = Uuid.v7();
    await catalogued(<Map<String, Object?>>[
      link('a', a, size: 1000, usual: true),
      link('b', b, reach: 'locationFree', size: null, usual: true),
    ]);

    final usual = (await serviceFor().forFeature(caveId))!.usual;

    final original = SilexgisDownloadEstimate.of(usual, SyncRendition.original);
    expect(original.files, 2);
    expect(original.knownBytes, 1000);
    expect(original.unknown, 1);
    // A picture's size is not known until it is drawn.
    final small = SilexgisDownloadEstimate.of(
      usual,
      SyncRendition.picture(480),
    );
    expect(small.knownBytes, 0);
    expect(small.unknown, 2);
  });

  test('a size not offered falls back to the nearest one offered', () async {
    await profiles.save(profile);
    final a = Uuid.v7();
    await catalogued(<Map<String, Object?>>[
      link('a', a, reach: 'renditions', renditions: const <int>[1200, 160]),
    ]);
    final document = (await serviceFor().forFeature(caveId))!.documents.single;

    expect(
      document.formFor(SyncRendition.original),
      SyncRendition.picture(1200),
    );
    expect(
      document.formFor(SyncRendition.picture(480)),
      SyncRendition.picture(160),
    );
  });

  test(
    'a server that stopped offering documents takes its catalogue away',
    () async {
      await profiles.save(profile);
      await tokens.write('p-1', 'refresh-1');
      await catalogued(<Map<String, Object?>>[link('a', Uuid.v7())]);
      final client = ScriptedClient(<ScriptedResponse>[
        ScriptedResponse.json(
          path: SilexgisContract.tokenPath,
          json: <String, Object?>{
            'access_token': 'access-1',
            'token_type': 'Bearer',
            'expires_in': 900,
            'refresh_token': 'refresh-2',
          },
        ),
        ScriptedResponse.json(
          path: SilexgisContract.capabilitiesPath,
          json: <String, Object?>{
            'contractVersion': 1,
            'pageSizeMax': 500,
            'uploadRowsMax': 500,
            'features': <String>['download', 'upload'],
          },
        ),
      ]);

      await expectLater(
        serviceFor(client).download(const []),
        throwsA(
          isA<SilexgisDocumentsBlocked>().having(
            (e) => e.reason,
            'reason',
            SilexgisDocumentsBlock.notServed,
          ),
        ),
      );
      expect(await catalogue.isEmpty(profile.profileUuid), isTrue);
      expect(await serviceFor().forFeature(caveId), isNull);
    },
  );
}
