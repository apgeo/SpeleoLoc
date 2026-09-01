import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/model/sync_set.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_feature_mapper.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// End to end against a real SilexGIS installation.
///
/// The recorded traffic under `test_data/silexgis_contract/` is what pins the
/// wire; this proves the whole chain actually holds together against a running
/// server — the sign-in dance, the bearer header, the paging, and the
/// protection rule that is the cheapest thing to point a first client test at.
///
/// It talks to a network and creates rows, so it is off by default. To run it:
///
/// 1. From a SilexGIS checkout: `node deploy/speleoloc-dev.mjs up`.
/// 2. `SPELEO_LOC_SILEXGIS_LIVE=1 flutter test test/services/silexgis/silexgis_live_test.dart`
///
/// `SPELEO_LOC_SILEXGIS_URL` overrides the base address if the script had to
/// serve on another port.
void main() {
  final env = Platform.environment;
  if (env['SPELEO_LOC_SILEXGIS_LIVE'] != '1') {
    test('SilexGIS live test skipped (set SPELEO_LOC_SILEXGIS_LIVE=1)', () {});
    return;
  }

  final baseUri = Uri.parse(
    env['SPELEO_LOC_SILEXGIS_URL'] ?? 'http://127.0.0.1:5205',
  );
  // The development server's own accounts, printed by the script that starts
  // it. The member owns nothing, so what it sees is decided by the permission
  // and protection rules rather than by ownership.
  const email = 'member@dev.local';
  const password = 'dev-member-pass-1';

  late SilexgisAuthService auth;
  late SilexgisSyncApi api;
  final created = <String>[];

  setUpAll(() async {
    auth = SilexgisAuthService(
      baseUri: baseUri,
      profileUuid: 'live-test',
      store: InMemoryRefreshTokenStore(),
    );
    await auth.signIn(email: email, password: password);
    api = SilexgisSyncApi(SilexgisHttp(baseUri: baseUri, tokens: auth));
  });

  tearDownAll(() async {
    for (final setId in created) {
      await api.deleteSet(setId);
    }
    auth.close();
  });

  test('the sign-in dance yields a usable bearer credential', () async {
    expect(auth.isSignedIn, isTrue);
    expect(await auth.accessToken(), isNotNull);
  });

  test('capabilities answers the version this build is pinned to', () async {
    final capabilities = await api.capabilities();
    expect(
      capabilities.contractVersion,
      SilexgisContract.version,
      reason:
          'the server has moved on; read the changelog beside the '
          'recordings before changing anything',
    );
    expect(capabilities.speaksOurContract, isTrue);
    expect(capabilities.servesDownload, isTrue);
    expect(capabilities.servesUpload, isTrue);
    expect(capabilities.pageSizeMax, greaterThan(0));
    expect(capabilities.uploadRowsMax, greaterThan(0));
  });

  test(
    'a refresh yields a new credential and does not revoke the chain',
    () async {
      expect(await auth.refresh(), isTrue);
      // The successor works: a chain revoked by a replayed token would answer
      // 401 here instead.
      await api.capabilities();
    },
  );

  group('a set over every demo cave', () {
    late SyncSet set;

    setUpAll(() async {
      final roots = await _demoCaveFeatureIds(
        baseUri,
        await auth.accessToken(),
      );
      expect(
        roots,
        hasLength(_demoCaveNames.length),
        reason:
            'the demonstration dataset is not seeded — run '
            '`node deploy/speleoloc-dev.mjs reset` then `up`',
      );
      set = await api.createSet(
        SyncSetWrite(
          name: 'live test ${DateTime.now().millisecondsSinceEpoch}',
          rootFeatureIds: roots,
          settings: const <String, Object?>{'pciStrategy': 'ro-default'},
        ),
      );
      created.add(set.id);
    });

    test(
      'withholds the protected cave entirely rather than blurring it',
      () async {
        final page = await api.download(set.id, pageSize: 500);
        final names = page.features.map((f) => f.name).toList();

        // Eleven rows as this account, and the guarded cave and its entrance are
        // simply not among them — no row, no geometry, no placeholder, and
        // nothing anywhere saying one was kept back.
        expect(page.features, hasLength(11));
        expect(names, isNot(contains('Avenul Demo Protejat')));
        expect(names, isNot(contains('Shaft')));
        expect(page.tombstones, isEmpty);
        expect(page.hasMore, isFalse);
        expect(page.nextCursor, isNotNull);

        // The group-only cave *is* here: visibility and location protection are
        // two different rules and the download applies both.
        expect(names, contains('Peștera Demo Izvorului'));
      },
    );

    test(
      'a child can arrive before its parent, so containment is a second pass',
      () async {
        final page = await api.download(set.id, pageSize: 500);
        final seen = <String>{};
        var childBeforeParent = false;
        for (final row in page.features) {
          final parent = row.primaryParent;
          if (parent != null && !seen.contains(parent.parentId)) {
            childBeforeParent = true;
          }
          seen.add(row.id);
        }
        expect(
          childBeforeParent,
          isTrue,
          reason:
              'the order is the change order and has nothing to do with '
              'containment; if this ever stops being true the buffering is '
              'still required and this assertion is the thing to relax',
        );
      },
    );

    test('paging resumes exactly where the cursor said', () async {
      final first = await api.download(set.id, pageSize: 4);
      expect(first.features, hasLength(4));
      expect(first.hasMore, isTrue);

      final seen = <String>{...first.features.map((f) => f.id)};
      var cursor = first.nextCursor;
      var page = first;
      while (page.hasMore) {
        page = await api.download(set.id, cursor: cursor, pageSize: 4);
        for (final row in page.features) {
          expect(seen.add(row.id), isTrue, reason: 'row ${row.id} repeated');
        }
        cursor = page.nextCursor;
      }
      expect(seen, hasLength(11));
    });

    test(
      'a cursor this server never issued is refused, never restarted',
      () async {
        // A silent restart is indistinguishable from an incremental page and
        // would cost a device a full re-download it never asked for.
        await expectLater(
          api.download(set.id, cursor: 'not-a-cursor'),
          throwsA(
            isA<SilexgisProblemException>()
                .having((e) => e.status, 'status', 400)
                .having((e) => e.code, 'code', SilexgisCodes.cursorInvalid)
                .having(
                  (e) => e.action,
                  'action',
                  SilexgisAction.applyAndResubmit,
                ),
          ),
        );
      },
    );

    test(
      'editing the selection retires every cursor issued before it',
      () async {
        final page = await api.download(set.id, pageSize: 500);
        final replaced = await api.replaceSet(
          set.id,
          set.toWrite().copyWith(name: '${set.name} (edited)'),
        );
        expect(replaced.revision, greaterThan(set.revision));
        set = replaced;

        // Told rather than answered short: adding a cave to a set writes
        // nothing to any feature row, so a server that accepted the old cursor
        // would answer "nothing new" and the cave would never arrive.
        await expectLater(
          api.download(set.id, cursor: page.nextCursor),
          throwsA(
            isA<SilexgisProblemException>()
                .having((e) => e.status, 'status', 409)
                .having((e) => e.code, 'code', SilexgisCodes.cursorStale),
          ),
        );
      },
    );
  });

  group('rows this application composes', () {
    // A set bound to the caving group, because a set with none refuses every
    // create with `access.create_forbidden` — see found-defects.md.
    const mapper = SilexgisFeatureMapper();
    late SyncSet set;
    late Uuid areaUuid;
    late Uuid caveUuid;
    late Uuid entranceUuid;
    late Uuid placeUuid;

    setUpAll(() async {
      final group = await _demoCavingGroupId(baseUri, await auth.accessToken());
      set = await api.createSet(
        SyncSetWrite(
          name: 'live upload ${DateTime.now().millisecondsSinceEpoch}',
          cavingGroupId: group,
          uploadVisibility: SyncVisibility.cavingGroup,
          rootFeatureIds: const <String>[],
          settings: const <String, Object?>{'pciStrategy': 'ro-default'},
        ),
      );
      created.add(set.id);

      areaUuid = Uuid.v7();
      caveUuid = Uuid.v7();
      entranceUuid = Uuid.v7();
      placeUuid = Uuid.v7();
    });

    test('a whole cave, as this application shapes it, is accepted', () async {
      final area = SurfaceArea(
        uuid: areaUuid,
        title: 'Live area ${areaUuid.toString().substring(0, 8)}',
        generalAreaIdentifier: 'LV',
      );
      final cave = Cave(
        uuid: caveUuid,
        title: 'Live cave ${caveUuid.toString().substring(0, 8)}',
        description: 'Written by the mapper.',
        surfaceAreaUuid: areaUuid,
        caveLocalIndex: 'C7',
      );
      CavePlace place({
        required Uuid uuid,
        required String title,
        required bool entrance,
      }) => CavePlace(
        uuid: uuid,
        title: title,
        description: entrance ? 'The way in.' : 'A chamber.',
        caveUuid: caveUuid,
        placeCodeIdentifier: entrance ? 'LV-0001' : 'LV-0002',
        qrCodeResourceIdentifier: entrance ? 'aaaa1111' : 'bbbb2222',
        latitude: entrance ? 45.601 : 45.602,
        longitude: entrance ? 25.501 : 25.502,
        altitude: entrance ? 1240 : 1180,
        depthInCave: entrance ? null : 60,
        isEntrance: entrance ? 1 : 0,
        isMainEntrance: entrance ? 1 : 0,
      );

      // Rows are applied in the order given, so a container is created earlier
      // in the same batch than the row that hangs under it.
      final batch = SyncUploadBatch(
        batchId: Uuid.v7().toString(),
        rows: <SyncUploadRow>[
          mapper.surfaceAreaRow(area, baseRevision: null),
          mapper.caveRow(
            cave,
            baseRevision: null,
            parentSurfaceAreaId: areaUuid.toString(),
          ),
          mapper.cavePlaceRow(
            CavePlaceUpload(
              place: place(
                uuid: entranceUuid,
                title: 'Main entrance',
                entrance: true,
              ),
              caveLocalIndex: 'C7',
              generalAreaIdentifier: 'LV',
            ),
            baseRevision: null,
            parentId: caveUuid.toString(),
          ),
          mapper.cavePlaceRow(
            CavePlaceUpload(
              place: place(
                uuid: placeUuid,
                title: 'Sala Mare',
                entrance: false,
              ),
              caveLocalIndex: 'C7',
              generalAreaIdentifier: 'LV',
            ),
            baseRevision: null,
            parentId: caveUuid.toString(),
          ),
        ],
      );

      final result = await api.upload(set.id, batch);
      for (final row in result.rows) {
        expect(
          row.status,
          SyncRowStatus.created,
          reason: '${row.id}: ${row.code} ${row.detail}',
        );
        // The identifier the device minted is the identifier that came back.
        expect(row.revision, isNotNull);
      }
      expect(result.rows.map((r) => r.id), <String>[
        areaUuid.toString(),
        caveUuid.toString(),
        entranceUuid.toString(),
        placeUuid.toString(),
      ]);
      expect(result.replayed, isFalse);
      expect(result.written, 4);

      // Replaying the same batch identifier returns the first answer and
      // writes nothing a second time.
      final replay = await api.upload(set.id, batch);
      expect(replay.replayed, isTrue);
      expect(replay.importBatchId, result.importBatchId);
      expect(
        replay.rows.map((r) => r.status),
        result.rows.map((r) => r.status),
      );
    });

    test('and reads back as the same rows', () async {
      // Put the area in the selection so the download reaches everything under
      // it, and re-read from the beginning.
      final current = await api.getSet(set.id);
      await api.replaceSet(
        set.id,
        current.toWrite().copyWith(
          rootFeatureIds: <String>[areaUuid.toString()],
        ),
      );

      final page = await api.download(set.id, pageSize: 500);
      final byId = <String, MappedFeature>{
        for (final row in page.features) row.id: mapper.read(row),
      };

      final area = byId[areaUuid.toString()]! as MappedSurfaceArea;
      expect(area.generalAreaIdentifier, 'LV');

      final cave = byId[caveUuid.toString()]! as MappedCave;
      expect(cave.caveLocalIndex, 'C7');
      expect(cave.description, 'Written by the mapper.');
      expect(cave.parentUuid, areaUuid);

      final entrance = byId[entranceUuid.toString()]! as MappedCavePlace;
      expect(entrance.isEntrance, isTrue);
      expect(entrance.latitude, 45.601);
      expect(entrance.longitude, 25.501);
      // The only place an altitude comes back, and only on an entrance.
      expect(entrance.altitude, 1240);
      expect(entrance.placeCodeIdentifier, 'LV-0001');
      expect(entrance.qrCodeResourceIdentifier, 'aaaa1111');
      expect(entrance.parentUuid, caveUuid);

      final place = byId[placeUuid.toString()]! as MappedCavePlace;
      expect(place.isEntrance, isFalse);
      expect(place.latitude, 45.602);
      expect(place.depthInCave, 60);
      expect(place.placeCodeIdentifier, 'LV-0002');
      // Accepted on the way up and discarded there — see found-defects.md.
      expect(place.altitude, isNull);

      // The cave's own map point is its main entrance's, kept in step by the
      // server rather than written by the device.
      final caveRow = page.features.firstWhere(
        (f) => f.id == caveUuid.toString(),
      );
      expect(caveRow.geometry?.longitude, 25.501);
      expect(caveRow.kind, SilexgisKinds.cave);
    });

    test(
      'a stale base revision is refused with the server\'s row attached',
      () async {
        final page = await api.download(set.id, pageSize: 500);
        final stored = page.features.firstWhere(
          (f) => f.id == placeUuid.toString(),
        );

        final result = await api.upload(
          set.id,
          SyncUploadBatch(
            batchId: Uuid.v7().toString(),
            rows: <SyncUploadRow>[
              SyncUploadRow(
                id: placeUuid.toString(),
                kind: SyncUploadKind.generic,
                baseRevision: '2020-01-01T00:00:00.000Z',
                name: 'Renamed against a stale revision',
              ),
            ],
          ),
        );

        final row = result.rows.single;
        expect(row.status, SyncRowStatus.conflict);
        expect(row.code, SilexgisCodes.conflict);
        expect(row.action, SilexgisAction.applyAndResubmit);
        // The server's own version rides back so the device can merge without a
        // second round trip.
        final echo = result.conflictFor(placeUuid.toString())!;
        expect(echo.name, stored.name);
        expect(echo.updatedAt, stored.updatedAt);
      },
    );

    test('a removal is arbitrated exactly as an edit is', () async {
      final page = await api.download(set.id, pageSize: 500);
      final stored = page.features.firstWhere(
        (f) => f.id == placeUuid.toString(),
      );

      final result = await api.upload(
        set.id,
        SyncUploadBatch(
          batchId: Uuid.v7().toString(),
          rows: <SyncUploadRow>[
            mapper.deleteRow(
              entityUuid: placeUuid,
              kind: SyncUploadKind.generic,
              baseRevision: stored.updatedAt,
            ),
          ],
        ),
      );
      expect(result.rows.single.status, SyncRowStatus.deleted);

      // And it comes back as a tombstone, not as a row that stopped appearing.
      final after = await api.download(set.id, pageSize: 500);
      expect(after.tombstones.map((t) => t.id), contains(placeUuid.toString()));
      expect(
        after.features.map((f) => f.id),
        isNot(contains(placeUuid.toString())),
      );
    });
  });
}

/// The six demonstration caves' feature ids, read from the ordinary cave list.
///
/// That route is not part of this contract and the client has no reason to
/// call it; the test does, because a sync set names roots by identifier and
/// the seeded identifiers differ per installation.
///
/// It is also the route that shows the withhold rule bounds this channel and
/// not the server: `Avenul Demo Protejat` comes back from here with a
/// grid-snapped point and `approximateLocation: true`, and is absent from the
/// sync download altogether.
Future<List<String>> _demoCaveFeatureIds(Uri baseUri, String? token) async {
  final http = HttpClient();
  try {
    final request = await http.getUrl(
      baseUri.replace(
        path: '/api/v1/caves',
        queryParameters: {'pageSize': '50'},
      ),
    );
    request.headers.set('Authorization', 'Bearer $token');
    final response = await request.close();
    final body = await response.transform(const Utf8Decoder()).join();
    final decoded = jsonDecode(body);
    final items = decoded is Map ? decoded['items'] as List : decoded as List;
    return items
        .cast<Map<String, Object?>>()
        // Only the seeded demonstration caves. A development database that has
        // been written into by hand holds other caves as well, and the row
        // counts below are statements about the demo dataset.
        .where((c) => _demoCaveNames.contains(c['name']))
        .map((c) => c['id'] as String?)
        .whereType<String>()
        .toList(growable: false);
  } finally {
    http.close();
  }
}

/// The caving group both development accounts belong to.
///
/// A sync set has to name one before an account that owns nothing may create
/// any row through it — which no document says, and which
/// `docs/integrations/silexgis/found-defects.md` records.
Future<String> _demoCavingGroupId(Uri baseUri, String? token) async {
  final http = HttpClient();
  try {
    final request = await http.getUrl(
      baseUri.replace(path: '/api/v1/caving-groups'),
    );
    request.headers.set('Authorization', 'Bearer $token');
    final response = await request.close();
    final body = await response.transform(const Utf8Decoder()).join();
    final decoded = jsonDecode(body);
    final items = decoded is Map ? decoded['items'] as List : decoded as List;
    return (items.first as Map<String, Object?>)['id']! as String;
  } finally {
    http.close();
  }
}

/// The demonstration dataset, by name. Six caves, of which one is protected
/// and one is visible only through the caving group.
const Set<String> _demoCaveNames = <String>{
  'Peștera Demo Mare',
  'Avenul Demo Protejat',
  'Peștera Demo Mică',
  'Peștera Demo Ursului',
  'Avenul Demo Vântului',
  'Peștera Demo Izvorului',
};
