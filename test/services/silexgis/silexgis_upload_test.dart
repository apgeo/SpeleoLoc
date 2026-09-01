import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/clock.dart';

import 'scripted_client.dart';
import 'token_source.dart';

/// Choosing what to send, sending it, and storing what comes back.
void main() {
  const profile = 'profile-a';
  const setId = 'set-1';

  late AppDatabase db;
  late SilexgisLocalStateRepository localState;
  late SilexgisUploadBuilder builder;
  final clock = FakeClock(DateTime.utc(2026, 9, 1, 12));

  final areaId = Uuid.v7();
  final caveId = Uuid.v7();
  final caveAreaId = Uuid.v7();
  final placeId = Uuid.v7();
  final entranceId = Uuid.v7();

  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'upload'],
  );

  setUp(() {
    clock.set(DateTime.utc(2026, 9, 1, 12));
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localState = SilexgisLocalStateRepository(db, clock: clock);
    builder = SilexgisUploadBuilder(
      db: db,
      localState: localState,
      profileUuid: profile,
    );
  });
  tearDown(() => db.close());

  /// A row the two sides have already agreed about: the revision the device
  /// last saw, and the row's own stamp at that moment.
  Future<void> known(
    Uuid uuid, {
    required String table,
    String? kind,
    String revision = '2026-08-28T09:00:00.000Z',
    int? localUpdatedAt,
  }) => localState.writeRevision(
    profile,
    uuid,
    entityTable: table,
    revision: revision,
    wireKind: kind,
    localUpdatedAt: localUpdatedAt,
  );

  Future<void> insertArea({int? updatedAt}) => db
      .into(db.surfaceAreas)
      .insert(
        SurfaceArea(
          uuid: areaId,
          title: 'Bucegi',
          generalAreaIdentifier: 'BV',
          updatedAt: updatedAt,
        ),
      );

  Future<void> insertCave({int? updatedAt, Uuid? area}) => db
      .into(db.caves)
      .insert(
        Cave(
          uuid: caveId,
          title: 'Peștera Mică',
          surfaceAreaUuid: area ?? areaId,
          caveLocalIndex: 'C7',
          updatedAt: updatedAt,
        ),
      );

  Future<void> insertPlace(
    Uuid uuid, {
    required String title,
    bool entrance = false,
    Uuid? caveArea,
    int? updatedAt,
  }) => db
      .into(db.cavePlaces)
      .insert(
        CavePlace(
          uuid: uuid,
          title: title,
          caveUuid: caveId,
          caveAreaUuid: caveArea,
          placeCodeIdentifier: 'AB-0007',
          latitude: 45.531,
          longitude: 25.441,
          isEntrance: entrance ? 1 : 0,
          isMainEntrance: entrance ? 1 : 0,
          updatedAt: updatedAt,
        ),
      );

  group('what travels', () {
    test('nothing, on a device that has never synced', () async {
      // Every local row is outside anything this installation holds. A profile
      // being configured is not a reason to push a caver's whole dataset to
      // the club's server.
      await insertArea();
      await insertCave();
      await insertPlace(placeId, title: 'Sala Mare');

      expect(await builder.build(), isEmpty);
    });

    test('a new place inside a cave the server already holds', () async {
      final t0 = clock.nowMs();
      await insertArea(updatedAt: t0);
      await insertCave(updatedAt: t0);
      await known(areaId, table: 'surface_areas', localUpdatedAt: t0);
      await known(caveId, table: 'caves', kind: 'cave', localUpdatedAt: t0);
      clock.advance(const Duration(minutes: 5));
      await insertPlace(placeId, title: 'Sala Mare', updatedAt: clock.nowMs());

      final pending = await builder.build();
      expect(pending.map((p) => p.entityUuid), <Uuid>[placeId]);
      final row = pending.single.row;
      expect(row.isNew, isTrue);
      expect(row.baseRevision, isNull);
      expect(row.toJson()['parentId'], caveId.toString());
      expect(row.kind, SyncUploadKind.generic);
    });

    test('a new cave under a known area, and the places inside it', () async {
      final t0 = clock.nowMs();
      await insertArea(updatedAt: t0);
      await known(areaId, table: 'surface_areas', localUpdatedAt: t0);
      clock.advance(const Duration(minutes: 5));
      await insertCave(updatedAt: clock.nowMs());
      await insertPlace(placeId, title: 'Sala Mare', updatedAt: clock.nowMs());

      final pending = await builder.build();
      // Containment order: the cave before the place that hangs under it,
      // because a batch is applied in the order it is given.
      expect(pending.map((p) => p.entityUuid), <Uuid>[caveId, placeId]);
    });

    test('not a cave whose area the server has never seen', () async {
      // Putting a new root on the server is a deliberate act, made by adding
      // it to the sync set — not a side effect of surveying somewhere new.
      await insertArea();
      await insertCave();
      await insertPlace(placeId, title: 'Sala Mare');
      expect(await builder.build(), isEmpty);
    });

    test('a new cave and its area, once the caver asks for them', () async {
      // Off by default; on, this is the only way a genuinely new cave ever
      // reaches a server, because a selection can only name a root that is
      // already there.
      await insertArea(updatedAt: clock.nowMs());
      await insertCave(updatedAt: clock.nowMs());
      await insertPlace(placeId, title: 'Sala Mare', updatedAt: clock.nowMs());

      final pending = await SilexgisUploadBuilder(
        db: db,
        localState: localState,
        profileUuid: profile,
        uploadsNewRoots: true,
      ).build();

      expect(pending.map((p) => p.entityUuid), <Uuid>[areaId, caveId, placeId]);
      expect(pending.every((p) => p.row.isNew), isTrue);
    });

    test('an unchanged row is not re-sent', () async {
      final t0 = clock.nowMs();
      await insertArea(updatedAt: t0);
      await insertCave(updatedAt: t0);
      clock.advance(const Duration(minutes: 5));
      await known(areaId, table: 'surface_areas', localUpdatedAt: t0);
      await known(caveId, table: 'caves', kind: 'cave', localUpdatedAt: t0);

      expect(await builder.build(), isEmpty);
    });

    test(
      'a row edited since it was last sent goes with its base revision',
      () async {
        final t0 = clock.nowMs();
        await insertArea(updatedAt: t0);
        await insertCave(updatedAt: t0);
        await known(areaId, table: 'surface_areas', localUpdatedAt: t0);
        await known(
          caveId,
          table: 'caves',
          kind: 'cave',
          revision: '2026-08-28T09:00:00.000Z',
          localUpdatedAt: t0,
        );
        clock.advance(const Duration(minutes: 5));
        await (db.update(
          db.caves,
        )..where((t) => t.uuid.equalsValue(caveId))).write(
          CavesCompanion(
            title: const Value('Peștera Mică (resurveyed)'),
            updatedAt: Value(clock.nowMs()),
          ),
        );

        final pending = await builder.build();
        expect(pending.map((p) => p.entityUuid), <Uuid>[caveId]);
        expect(pending.single.row.baseRevision, '2026-08-28T09:00:00.000Z');
        expect(pending.single.row.isNew, isFalse);
        expect(pending.single.row.name, 'Peștera Mică (resurveyed)');
      },
    );

    test('a place under a cave area hangs under the area', () async {
      final t0 = clock.nowMs();
      await insertArea(updatedAt: t0);
      await insertCave(updatedAt: t0);
      await known(areaId, table: 'surface_areas', localUpdatedAt: t0);
      await known(caveId, table: 'caves', kind: 'cave', localUpdatedAt: t0);
      clock.advance(const Duration(minutes: 5));
      await db
          .into(db.caveAreas)
          .insert(
            CaveArea(
              uuid: caveAreaId,
              title: 'Galeria',
              caveUuid: caveId,
              updatedAt: clock.nowMs(),
            ),
          );
      await insertPlace(
        placeId,
        title: 'Sala Mare',
        caveArea: caveAreaId,
        updatedAt: clock.nowMs(),
      );

      final pending = await builder.build();
      expect(pending.map((p) => p.entityUuid), <Uuid>[caveAreaId, placeId]);
      // That edge is what decides what guards the place: protection is
      // inherited along containment and along nothing else.
      expect(pending.last.row.toJson()['parentId'], caveAreaId.toString());
    });
  });

  group('a row removed here', () {
    test(
      'becomes a tombstone carrying the revision the device holds',
      () async {
        await known(
          placeId,
          table: 'cave_places',
          kind: 'generic',
          revision: '2026-08-28T09:00:00.000Z',
        );

        final pending = await builder.build();
        expect(pending, hasLength(1));
        expect(pending.single.isDelete, isTrue);
        expect(pending.single.row.baseRevision, '2026-08-28T09:00:00.000Z');
        // Nothing else: the row is being removed, so none of its content is a
        // statement worth making.
        expect(
          pending.single.row.toJson().keys,
          unorderedEquals(<String>[
            'id',
            'kind',
            'baseRevision',
            'deleted',
            'isMain',
          ]),
        );
      },
    );

    test(
      'names the kind it travelled as, which a deleted row cannot say',
      () async {
        // A local delete is physical: once the row is gone nothing here
        // remembers whether it was an entrance, so the kind is kept beside the
        // revision rather than guessed from the table.
        await known(entranceId, table: 'cave_places', kind: 'caveEntrance');
        await known(placeId, table: 'cave_places', kind: 'generic');

        final byId = <Uuid, SyncUploadRow>{
          for (final p in await builder.build()) p.entityUuid: p.row,
        };
        expect(byId[entranceId]!.kind, SyncUploadKind.caveEntrance);
        expect(byId[placeId]!.kind, SyncUploadKind.generic);
      },
    );

    test(
      'falls back to what the table implies when no kind was recorded',
      () async {
        await known(caveId, table: 'caves');
        final pending = await builder.build();
        expect(pending.single.row.kind, SyncUploadKind.cave);
      },
    );

    test(
      'goes child-first, because a removal takes the subtree with it',
      () async {
        await known(caveId, table: 'caves', kind: 'cave');
        await known(placeId, table: 'cave_places', kind: 'generic');

        final pending = await builder.build();
        expect(pending.map((p) => p.entityUuid), <Uuid>[placeId, caveId]);
      },
    );
  });

  group('sending, and what comes back', () {
    late ScriptedClient client;
    late SilexgisUploadRunner runner;

    void arm(List<ScriptedResponse> script) {
      client = ScriptedClient(script);
      runner = SilexgisUploadRunner(
        api: SilexgisSyncApi(
          SilexgisHttp(
            baseUri: Uri.parse('https://club.example.org'),
            tokens: FixedTokenSource(),
            client: client,
          ),
        ),
        builder: builder,
        localState: localState,
        profileUuid: profile,
      );
    }

    ScriptedResponse answer(
      List<Map<String, Object?>> rows, {
      List<Map<String, Object?>> conflicts = const <Map<String, Object?>>[],
      List<Map<String, Object?>> duplicates = const <Map<String, Object?>>[],
      bool replayed = false,
    }) => ScriptedResponse.json(
      path: SilexgisContract.uploadPath(setId),
      json: <String, Object?>{
        'batchId': '<batch>',
        'importBatchId': '<import>',
        'replayed': replayed,
        'written': rows.where((r) => r['status'] != 'conflict').length,
        'refused': rows.where((r) => r['status'] == 'conflict').length,
        'rows': rows,
        'conflicts': conflicts,
        'duplicates': duplicates,
      },
    );

    test('nothing is sent when there is nothing to send', () async {
      arm(<ScriptedResponse>[]);
      final report = await runner.run(setId, capabilities: capabilities);
      expect(report.isEmpty, isTrue);
      expect(client.sent, isEmpty);
    });

    test('a created row stores the revision to send back next time', () async {
      final t0 = clock.nowMs();
      await insertArea(updatedAt: t0);
      await insertCave(updatedAt: t0);
      await known(areaId, table: 'surface_areas', localUpdatedAt: t0);
      await known(caveId, table: 'caves', kind: 'cave', localUpdatedAt: t0);
      clock.advance(const Duration(minutes: 5));
      await insertPlace(placeId, title: 'Sala Mare', updatedAt: clock.nowMs());

      arm(<ScriptedResponse>[
        answer(<Map<String, Object?>>[
          <String, Object?>{
            'id': placeId.toString(),
            'status': 'created',
            'revision': '2026-09-01T12:05:00.000Z',
            'code': null,
            'detail': null,
          },
        ]),
      ]);

      final report = await runner.run(setId, capabilities: capabilities);
      expect(report.written, 1);
      expect(report.refusals, isEmpty);
      expect(
        await localState.readRevision(profile, placeId),
        '2026-09-01T12:05:00.000Z',
      );
      // And a second run has nothing left to say about it.
      expect(await builder.build(), isEmpty);
    });

    test(
      'a deleted row forgets its revision, so the tombstone stops',
      () async {
        await known(placeId, table: 'cave_places', kind: 'generic');
        arm(<ScriptedResponse>[
          answer(<Map<String, Object?>>[
            <String, Object?>{
              'id': placeId.toString(),
              'status': 'deleted',
              'revision': '2026-09-01T12:05:00.000Z',
              'code': null,
              'detail': null,
            },
          ]),
        ]);

        await runner.run(setId, capabilities: capabilities);
        expect(await localState.readRevision(profile, placeId), isNull);
        expect(await builder.build(), isEmpty);
      },
    );

    test('a conflict is kept with the server\'s own row beside it', () async {
      await known(placeId, table: 'cave_places', kind: 'generic');
      arm(<ScriptedResponse>[
        answer(
          <Map<String, Object?>>[
            <String, Object?>{
              'id': placeId.toString(),
              'status': 'conflict',
              'revision': '2026-08-30T09:00:00.000Z',
              'code': 'sync.conflict',
              'detail':
                  'This row changed on the server after you last read it.',
            },
          ],
          conflicts: <Map<String, Object?>>[
            <String, Object?>{
              'id': placeId.toString(),
              'kind': 'generic',
              'featureTypeCode': 'cave_place',
              'name': 'Sala Mare (club)',
              'updatedAt': '2026-08-30T09:00:00.000Z',
              'properties': const <String, Object?>{},
              'parents': const <Object?>[],
            },
          ],
        ),
      ]);

      final report = await runner.run(setId, capabilities: capabilities);
      final refusal = report.refusals.single;
      expect(refusal.isConflict, isTrue);
      expect(refusal.action, SilexgisAction.applyAndResubmit);
      expect(refusal.serverRow?.name, 'Sala Mare (club)');
      expect(refusal.needsReread, isFalse);
      // The revision is not advanced: the device's version was not applied.
      expect(
        await localState.readRevision(profile, placeId),
        '2026-08-28T09:00:00.000Z',
      );
    });

    test('a conflict with no echo is a row to re-read, not an error', () async {
      // A row that lost and is missing from `conflicts` is one whose position
      // this account may not have — absence, never a blurred stand-in.
      await known(placeId, table: 'cave_places', kind: 'generic');
      arm(<ScriptedResponse>[
        answer(<Map<String, Object?>>[
          <String, Object?>{
            'id': placeId.toString(),
            'status': 'conflict',
            'revision': '2026-08-30T09:00:00.000Z',
            'code': 'sync.conflict',
            'detail': null,
          },
        ]),
      ]);

      final refusal = (await runner.run(
        setId,
        capabilities: capabilities,
      )).refusals.single;
      expect(refusal.serverRow, isNull);
      expect(refusal.needsReread, isTrue);
    });

    test('a refusal names the one action that moves it forward', () async {
      await known(placeId, table: 'cave_places', kind: 'generic');
      arm(<ScriptedResponse>[
        answer(<Map<String, Object?>>[
          <String, Object?>{
            'id': placeId.toString(),
            'status': 'rejected',
            'revision': null,
            'code': 'sync.set_unbound',
            'detail': 'This selection names no caving group.',
          },
        ]),
      ]);

      final refusal = (await runner.run(
        setId,
        capabilities: capabilities,
      )).refusals.single;
      // The caver picks a club for the selection and the batch is resent.
      expect(refusal.action, SilexgisAction.surfaceToUser);
      expect(refusal.result.code, SilexgisCodes.setUnbound);
    });

    test(
      'a batch over the ceiling is split, each part its own attempt',
      () async {
        final t0 = clock.nowMs();
        await insertArea(updatedAt: t0);
        await insertCave(updatedAt: t0);
        await known(areaId, table: 'surface_areas', localUpdatedAt: t0);
        await known(caveId, table: 'caves', kind: 'cave', localUpdatedAt: t0);
        clock.advance(const Duration(minutes: 5));
        final ids = <Uuid>[];
        for (var i = 0; i < 5; i++) {
          final id = Uuid.v7();
          ids.add(id);
          await insertPlace(id, title: 'Place $i', updatedAt: clock.nowMs());
        }

        Map<String, Object?> created(Uuid id) => <String, Object?>{
          'id': id.toString(),
          'status': 'created',
          'revision': '2026-09-01T12:05:00.000Z',
          'code': null,
          'detail': null,
        };
        arm(<ScriptedResponse>[
          answer(ids.take(2).map(created).toList()),
          answer(ids.skip(2).take(2).map(created).toList()),
          answer(ids.skip(4).map(created).toList()),
        ]);

        final report = await runner.run(
          setId,
          capabilities: const SilexgisCapabilities(
            contractVersion: 1,
            pageSizeMax: 500,
            uploadRowsMax: 2,
            features: <String>['download', 'upload'],
          ),
        );

        expect(report.batches, 3);
        expect(client.sent, hasLength(3));
        // A batch identifier stands for one attempt: reusing one for different
        // rows would have the server answer with the wrong stored result.
        final batchIds = client.sent
            .map((r) => r.jsonBody['batchId'] as String)
            .toSet();
        expect(batchIds, hasLength(3));
        // And every part states the contract version this build is pinned to.
        for (final sent in client.sent) {
          expect(sent.jsonBody['contractVersion'], SilexgisContract.version);
        }
      },
    );

    test('a duplicate report is carried, and changes no verdict', () async {
      final t0 = clock.nowMs();
      await insertArea(updatedAt: t0);
      await insertCave(updatedAt: t0);
      await known(areaId, table: 'surface_areas', localUpdatedAt: t0);
      await known(caveId, table: 'caves', kind: 'cave', localUpdatedAt: t0);
      clock.advance(const Duration(minutes: 5));
      await insertPlace(placeId, title: 'Sala Mare', updatedAt: clock.nowMs());

      arm(<ScriptedResponse>[
        answer(
          <Map<String, Object?>>[
            <String, Object?>{
              'id': placeId.toString(),
              'status': 'created',
              'revision': '2026-09-01T12:05:00.000Z',
              'code': null,
              'detail': null,
            },
          ],
          duplicates: <Map<String, Object?>>[
            <String, Object?>{
              'id': placeId.toString(),
              'nearby': <Object?>[
                <String, Object?>{
                  'id': Uuid.v7().toString(),
                  'name': 'Avenul Mare',
                  'kind': 'caveEntrance',
                  'distanceMeters': 41.2,
                },
              ],
            },
          ],
        ),
      ]);

      final report = await runner.run(setId, capabilities: capabilities);
      // Every row listed was written and its entry in `rows` says so. Deciding
      // whether the two are the same cave is the caver's, not the server's.
      expect(report.written, 1);
      expect(report.refusals, isEmpty);
      expect(report.duplicates.single.nearby.single.distanceMeters, 41.2);
      expect(
        await localState.readRevision(profile, placeId),
        '2026-09-01T12:05:00.000Z',
      );
    });
  });
}
