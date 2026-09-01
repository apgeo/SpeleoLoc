import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/user_repository.dart';

import 'scripted_client.dart';
import 'token_source.dart';

/// Reading a set to the end, and what the device does when its position is
/// refused.
void main() {
  const profile = 'profile-a';
  const setId = 'set-1';
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'upload'],
  );

  late AppDatabase db;
  late SilexgisLocalStateRepository localState;
  late SilexgisDownloadApplier applier;

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
    final logger = loggerRef = ChangeLogger(db, currentUser);
    localState = SilexgisLocalStateRepository(db);
    applier = SilexgisDownloadApplier(
      db: db,
      logger: logger,
      localState: localState,
      caves: CaveRepository(db, currentUser, logger),
      places: CavePlaceRepository(db, currentUser, logger),
      profileUuid: profile,
    );
  });
  tearDown(() => db.close());

  SilexgisDownloadRunner runnerFor(ScriptedClient client) =>
      SilexgisDownloadRunner(
        api: SilexgisSyncApi(
          SilexgisHttp(
            baseUri: Uri.parse('https://club.example.org'),
            tokens: FixedTokenSource(),
            client: client,
          ),
        ),
        applier: applier,
        localState: localState,
        profileUuid: profile,
      );

  ScriptedResponse pageOf({
    required List<Map<String, Object?>> features,
    String? cursor,
    bool hasMore = false,
    int setRevision = 1,
  }) => ScriptedResponse.json(
    path: SilexgisContract.downloadPath(setId),
    json: <String, Object?>{
      'setRevision': setRevision,
      'settings': const <String, Object?>{},
      'features': features,
      'tombstones': const <Object?>[],
      'nextCursor': cursor,
      'hasMore': hasMore,
    },
  );

  Map<String, Object?> cave(Uuid id, String name) => <String, Object?>{
    'id': id.toString(),
    'kind': 'cave',
    'name': name,
    'updatedAt': '2026-08-28T09:00:00.000Z',
    'properties': const <String, Object?>{},
    'parents': const <Object?>[],
  };

  test('reads until the server says it is level, and no further', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      pageOf(
        features: <Map<String, Object?>>[cave(Uuid.v7(), 'One')],
        cursor: 'c1',
        hasMore: true,
      ),
      pageOf(
        features: <Map<String, Object?>>[cave(Uuid.v7(), 'Two')],
        cursor: 'c2',
      ),
    ]);

    final report = await runnerFor(
      client,
    ).run(setId, capabilities: capabilities);

    expect(report.pages, 2);
    expect(report.applied.inserted, 2);
    expect(client.sent, hasLength(2));
    // The first request carries no position; the second carries the one the
    // first handed back.
    expect(
      client.sent.first.url.queryParameters.containsKey('cursor'),
      isFalse,
    );
    expect(client.sent.last.url.queryParameters['cursor'], 'c1');
    // `hasMore` false means level with the server as of this read — the signal
    // to stop looping now, not to stop syncing.
    expect((await localState.readSetState(profile, setId)).cursor, 'c2');
  });

  test('resumes from the position the last run stored', () async {
    await localState.writeSetState(
      profile,
      setId,
      cursor: 'from-last-time',
      setRevision: 1,
    );
    final client = ScriptedClient(<ScriptedResponse>[
      pageOf(features: const <Map<String, Object?>>[], cursor: 'c9'),
    ]);

    await runnerFor(client).run(setId, capabilities: capabilities);
    expect(client.sent.single.url.queryParameters['cursor'], 'from-last-time');
  });

  test('sizes its pages below the announced ceiling', () async {
    // `pageSize` counts rows and not bytes: a centerline's geometry is a cave's
    // whole survey, and one row of it can be far bigger than the other
    // ninety-nine.
    final client = ScriptedClient(<ScriptedResponse>[
      pageOf(features: const <Map<String, Object?>>[]),
    ]);
    await runnerFor(client).run(setId, capabilities: capabilities);
    expect(
      int.parse(client.sent.single.url.queryParameters['pageSize']!),
      lessThanOrEqualTo(capabilities.pageSizeMax),
    );
  });

  test('clamps to a ceiling lower than it would otherwise ask for', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      pageOf(features: const <Map<String, Object?>>[]),
    ]);
    await runnerFor(client).run(
      setId,
      capabilities: const SilexgisCapabilities(
        contractVersion: 1,
        pageSizeMax: 10,
        uploadRowsMax: 500,
        features: <String>['download'],
      ),
    );
    expect(client.sent.single.url.queryParameters['pageSize'], '10');
  });

  group('a refused position', () {
    ScriptedResponse refusal(String code, int status) =>
        ScriptedResponse.problem(
          path: SilexgisContract.downloadPath(setId),
          status: status,
          code: code,
        );

    for (final (code, status) in <(String, int)>[
      (SilexgisCodes.cursorStale, 409),
      (SilexgisCodes.cursorInvalid, 400),
    ]) {
      test('$code drops the cursor and reads from the beginning', () async {
        // Two different statuses and codes for what is one decision on the
        // device. Retrying the same cursor never succeeds.
        await localState.writeSetState(
          profile,
          setId,
          cursor: 'stale',
          setRevision: 1,
        );
        final client = ScriptedClient(<ScriptedResponse>[
          refusal(code, status),
          pageOf(
            features: <Map<String, Object?>>[cave(Uuid.v7(), 'One')],
            cursor: 'fresh',
          ),
        ]);

        final report = await runnerFor(
          client,
        ).run(setId, capabilities: capabilities);

        expect(report.restarted, isTrue);
        expect(report.applied.inserted, 1);
        expect(client.sent, hasLength(2));
        expect(client.sent.first.url.queryParameters['cursor'], 'stale');
        expect(
          client.sent.last.url.queryParameters.containsKey('cursor'),
          isFalse,
        );
      });
    }

    test('is not retried for ever when the fresh read is refused too', () async {
      // The restart starts from no position at all, so a second refusal is not
      // about a cursor and has to reach the caller.
      await localState.writeSetState(
        profile,
        setId,
        cursor: 'stale',
        setRevision: 1,
      );
      final client = ScriptedClient(<ScriptedResponse>[
        refusal(SilexgisCodes.cursorStale, 409),
        refusal(SilexgisCodes.cursorStale, 409),
      ]);

      await expectLater(
        runnerFor(client).run(setId, capabilities: capabilities),
        throwsA(isA<SilexgisProblemException>()),
      );
      expect(client.sent, hasLength(2));
    });

    test('any other refusal is not swallowed as a restart', () async {
      final client = ScriptedClient(<ScriptedResponse>[
        refusal(SilexgisCodes.setNotFound, 404),
      ]);
      await expectLater(
        runnerFor(client).run(setId, capabilities: capabilities),
        throwsA(
          isA<SilexgisProblemException>()
              .having((e) => e.code, 'code', SilexgisCodes.setNotFound)
              .having((e) => e.action, 'action', SilexgisAction.surfaceToUser),
        ),
      );
    });
  });

  test('a full read is asked for by dropping the position first', () async {
    // The only way to pick up a row that became readable: being granted the
    // right to place a cave writes nothing to that cave's row, so its change
    // key does not move and no incremental read will ever carry it.
    await localState.writeSetState(
      profile,
      setId,
      cursor: 'somewhere',
      setRevision: 1,
    );
    final client = ScriptedClient(<ScriptedResponse>[
      pageOf(features: const <Map<String, Object?>>[], cursor: 'c1'),
    ]);

    await runnerFor(
      client,
    ).run(setId, capabilities: capabilities, fromBeginning: true);

    expect(
      client.sent.single.url.queryParameters.containsKey('cursor'),
      isFalse,
    );
  });

  test(
    'carries rows whose container never arrives out to the caller',
    () async {
      final orphanCave = Uuid.v7();
      final client = ScriptedClient(<ScriptedResponse>[
        pageOf(
          features: <Map<String, Object?>>[
            <String, Object?>{
              'id': Uuid.v7().toString(),
              'kind': 'generic',
              'featureTypeCode': 'cave_place',
              'name': 'A place in a cave this account cannot see',
              'updatedAt': '2026-08-28T09:00:00.000Z',
              'properties': const <String, Object?>{},
              'parents': <Object?>[
                <String, Object?>{
                  'parentId': orphanCave.toString(),
                  'isPrimary': true,
                },
              ],
            },
          ],
          cursor: 'c1',
        ),
      ]);

      final report = await runnerFor(
        client,
      ).run(setId, capabilities: capabilities);

      expect(report.applied.inserted, 0);
      expect(report.unresolved, hasLength(1));
    },
  );
}
