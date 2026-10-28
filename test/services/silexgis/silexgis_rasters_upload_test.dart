import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_sending_gate.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_stager.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_paged_stream_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_maps_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_pins_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_upload_answers.dart';
import 'package:speleoloc/services/silexgis/silexgis_staged_upload_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_transfer_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/clock.dart';

import 'scripted_client.dart';
import 'token_source.dart';

/// Raster maps up: which go, what each says, when a picture's bytes go with
/// it — and never a copy handed down without its location — and what is kept
/// of each answer.
void main() {
  const profile = 'p-1';
  const setId = 'set-1';
  const transferId = 'transfer-1';
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'upload', 'documentUpload', 'rasters'],
  );
  final clock = FakeClock(DateTime.utc(2026, 10, 28, 8));
  final uploadPath = SilexgisContract.uploadPath(setId);

  late Directory base;
  late AppDatabase db;
  late SilexgisLocalStateRepository localState;
  late SilexgisHeldRowRepository heldRows;
  late SilexgisRasterStateRepository rasters;
  late SilexgisStagedUploadRepository staged;

  final caveId = Uuid.v7();
  final placeId = Uuid.v7();

  setUp(() async {
    base = await Directory.systemTemp.createTemp('silexgis_rasters_up_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localState = SilexgisLocalStateRepository(db, clock: clock);
    heldRows = SilexgisHeldRowRepository(db, clock: clock);
    rasters = SilexgisRasterStateRepository(db);
    staged = SilexgisStagedUploadRepository(db, clock: clock);

    final t0 = clock.nowMs();
    await db
        .into(db.caves)
        .insert(Cave(uuid: caveId, title: 'Invented', updatedAt: t0));
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlace(
            uuid: placeId,
            title: 'Sump',
            caveUuid: caveId,
            isEntrance: 0,
            isMainEntrance: 0,
            updatedAt: t0,
          ),
        );
    for (final (id, table) in <(Uuid, String)>[
      (caveId, 'caves'),
      (placeId, 'cave_places'),
    ]) {
      await localState.writeRevision(
        profile,
        id,
        entityTable: table,
        revision: '2026-10-27T10:00:00Z',
        localUpdatedAt: t0,
      );
    }
  });
  tearDown(() async {
    await db.close();
    await base.delete(recursive: true);
  });

  /// A map of [cave] with an invented picture written under the documents
  /// folder.
  Future<(Uuid, List<int>)> map({
    Uuid? cave,
    String title = 'Invented plan',
    List<int>? bytes,
  }) async {
    final id = Uuid.v7();
    final picture =
        bytes ?? <int>[0xFF, 0xD8, 0xFF, ...List<int>.filled(64, id.bytes[15])];
    final relPath = 'cave_${cave ?? caveId}/raster_${id.toString()}.jpg';
    final file = File('${base.path}/$relPath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(picture);
    final now = clock.nowMs();
    await db
        .into(db.rasterMaps)
        .insert(
          RasterMapsCompanion.insert(
            uuid: id,
            title: title,
            mapType: 'projected profile',
            fileName: relPath,
            caveUuid: cave ?? caveId,
          ).copyWith(
            orderIndex: const Value(2),
            fileHash: Value(sha256.convert(picture).toString()),
            fileSize: Value(picture.length),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return (id, picture);
  }

  Future<Uuid> pin(Uuid map, {int x = 120, int y = 80}) async {
    final id = Uuid.v7();
    final now = clock.nowMs();
    await db
        .into(db.cavePlaceToRasterMapDefinitions)
        .insert(
          CavePlaceToRasterMapDefinitionsCompanion.insert(
            uuid: id,
            cavePlaceUuid: placeId,
            rasterMapUuid: map,
          ).copyWith(
            xCoordinate: Value(x),
            yCoordinate: Value(y),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  /// [id] as the installation holds it, agreed with the local row, its
  /// picture standing for the installation's when [picture] is given.
  Future<void> agreed(
    Uuid id, {
    required String table,
    required Uuid mapId,
    List<int>? picture,
    bool received = false,
  }) async {
    final row = table == SilexgisRasterTables.maps
        ? (await (db.select(
            db.rasterMaps,
          )..where((t) => t.uuid.equalsValue(id))).getSingle()).updatedAt
        : (await (db.select(
            db.cavePlaceToRasterMapDefinitions,
          )..where((t) => t.uuid.equalsValue(id))).getSingle()).updatedAt;
    await localState.writeRevision(
      profile,
      id,
      entityTable: table,
      revision: 'rev-$id',
      localUpdatedAt: row,
    );
    await rasters.recordDownloaded(
      profile,
      SilexgisRasterState(
        entityUuid: id,
        mapUuid: mapId,
        isPin: table == SilexgisRasterTables.pins,
        received: received,
        documentId: table == SilexgisRasterTables.maps ? Uuid.v7() : null,
      ),
    );
    if (picture != null) {
      await rasters.recordPicture(
        profile,
        id,
        sha256: sha256.convert(picture).toString(),
        version: 'v-1',
      );
    }
  }

  Future<void> rename(Uuid id, String title) async {
    clock.advance(const Duration(minutes: 1));
    await (db.update(
      db.rasterMaps,
    )..where((t) => t.uuid.equalsValue(id))).write(
      RasterMapsCompanion(title: Value(title), updatedAt: Value(clock.nowMs())),
    );
  }

  Map<String, Object?> verdict(
    Uuid id,
    String status, {
    String? code,
    String? reviewId,
  }) => <String, Object?>{
    'id': id.toString(),
    'status': status,
    'revision': code == null ? '2026-10-28T08:00:00Z' : null,
    'code': code,
    'detail': null,
    'reviewId': ?reviewId,
  };

  ScriptedResponse answer({
    List<Map<String, Object?>>? maps,
    List<Map<String, Object?>>? pins,
  }) => ScriptedResponse.json(
    path: uploadPath,
    json: <String, Object?>{
      'batchId': 'b',
      'importBatchId': 'i',
      'replayed': false,
      'written': 0,
      'refused': 0,
      'rows': const <Object?>[],
      'conflicts': const <Object?>[],
      'duplicates': const <Object?>[],
      'rasterMaps': ?maps,
      'rasterPins': ?pins,
    },
  );

  /// The transfer routes for one file of [bytes], sent whole.
  List<ScriptedResponse> staging(List<int> bytes) {
    final path = SilexgisContract.fileUploadPath(transferId);
    return <ScriptedResponse>[
      ScriptedResponse.json(
        path: SilexgisContract.filesConfigPath,
        json: <String, Object?>{
          'maxUploadBytes': 1 << 30,
          'remainingBytes': null,
          'chunkBytes': 8 * 1024 * 1024,
        },
      ),
      ScriptedResponse.json(
        path: SilexgisContract.fileUploadsPath,
        status: 201,
        json: <String, Object?>{
          'id': transferId,
          'receivedBytes': 0,
          'chunkBytes': 8 * 1024 * 1024,
          'expiresAt': '2026-10-29T08:00:00Z',
        },
      ),
      ScriptedResponse.json(
        path: path,
        method: 'PUT',
        json: <String, Object?>{
          'id': transferId,
          'receivedBytes': bytes.length,
          'chunkBytes': 8 * 1024 * 1024,
        },
      ),
      ScriptedResponse.json(
        path: SilexgisContract.fileUploadCompletePath(transferId),
        json: <String, Object?>{
          'id': transferId,
          'sizeBytes': bytes.length,
          'sha256': sha256.convert(bytes).toString(),
          'mimeType': 'image/jpeg',
          'expiresAt': '2026-11-04T08:00:00Z',
        },
      ),
    ];
  }

  Future<(SilexgisUploadReport, SilexgisRasterMapsUploadPart)> run(
    ScriptedClient client, {
    SilexgisFileSendingGate gate = const SilexgisFilesAlwaysGo(),
    bool filesAllowed = true,
  }) async {
    final http = SilexgisHttp(
      baseUri: Uri.parse('https://club.example.org'),
      tokens: FixedTokenSource(),
      client: client,
    );
    final answers = SilexgisRasterUploadAnswers(
      localState: localState,
      heldRows: heldRows,
      rasters: rasters,
      staged: staged,
      rastersCursor: SilexgisStreamCursorStore(
        localState: localState,
        profileUuid: profile,
        setId: setId,
        stream: SyncStream.rasters,
      ),
      profileUuid: profile,
    );
    final maps = SilexgisRasterMapsUploadPart(
      db: db,
      localState: localState,
      heldRows: heldRows,
      rasters: rasters,
      answers: answers,
      stager: SilexgisFileStager(
        api: SilexgisTransferApi(http),
        staged: staged,
        profileUuid: profile,
        clock: clock,
      ),
      gate: gate,
      baseDir: () async => base,
      profileUuid: profile,
      filesAllowed: filesAllowed,
    );
    final report = await SilexgisUploadRunner(
      api: SilexgisSyncApi(http),
      builder: SilexgisUploadBuilder(
        db: db,
        localState: localState,
        heldRows: heldRows,
        profileUuid: profile,
      ),
      localState: localState,
      heldRows: heldRows,
      profileUuid: profile,
      parts: [
        maps,
        SilexgisRasterPinsUploadPart(
          db: db,
          localState: localState,
          heldRows: heldRows,
          rasters: rasters,
          answers: answers,
          profileUuid: profile,
        ),
      ],
    ).run(setId, capabilities: capabilities);
    return (report, maps);
  }

  List<Map<String, Object?>> sentSection(
    ScriptedClient client,
    SyncUploadSection section,
  ) => <Map<String, Object?>>[
    for (final r in client.sent.where((r) => r.url.path == uploadPath))
      for (final item in (r.jsonBody[section.wireName] as List? ?? const []))
        item as Map<String, Object?>,
  ];

  bool touchedTransfers(ScriptedClient client) =>
      client.sent.any((r) => r.url.path.startsWith('/api/v1/files/'));

  group('a map of the caver\'s own', () {
    test('goes up with its picture and its pin, and is kept as sent', () async {
      final (id, bytes) = await map();
      final pinId = await pin(id);
      final client = ScriptedClient(<ScriptedResponse>[
        ...staging(bytes),
        answer(
          maps: <Map<String, Object?>>[verdict(id, 'created')],
          pins: <Map<String, Object?>>[verdict(pinId, 'created')],
        ),
      ]);

      final (report, maps) = await run(client);

      expect(report.refusals, isEmpty);
      expect(client.isExhausted, isTrue);
      final sent = sentSection(client, SyncUploadSection.rasterMaps).single;
      expect(sent['id'], id.toString());
      expect(sent['baseRevision'], isNull);
      expect(sent['caveId'], caveId.toString());
      expect(sent.containsKey('caveAreaId'), isFalse);
      expect(sent['title'], 'Invented plan');
      expect(sent['mapType'], 'projectedProfile');
      expect(sent['sortOrder'], 2);
      expect(sent['fileName'], 'raster_$id.jpg');
      expect(sent['sha256'], sha256.convert(bytes).toString());
      expect(sent['sizeBytes'], bytes.length);
      expect(sent['stagedUploadId'], transferId);
      final pinSent = sentSection(client, SyncUploadSection.rasterPins).single;
      expect(pinSent, <String, Object?>{
        'id': pinId.toString(),
        'rasterMapId': id.toString(),
        'baseRevision': null,
        'deleted': false,
        'placeId': placeId.toString(),
        'x': 120,
        'y': 80,
      });
      expect(maps.files.staged, 1);

      final revisions = await localState.readRevisions(profile);
      expect(revisions[id]!.entityTable, 'raster_maps');
      expect(
        revisions[pinId]!.entityTable,
        'cave_place_to_raster_map_definitions',
      );
      final states = await rasters.readAll(profile);
      expect(states[id]!.sent, isTrue);
      expect(states[id]!.pictureSha256, sha256.convert(bytes).toString());
      expect(states[pinId]!.mapUuid, id);
      expect(
        (await staged.read(profile, id))!.state,
        SilexgisStagedState.adopted,
      );
    });

    test('in a cave the installation does not hold stays here', () async {
      final elsewhere = Uuid.v7();
      await db.into(db.caves).insert(Cave(uuid: elsewhere, title: 'Local'));
      final (id, _) = await map(cave: elsewhere);
      await pin(id);
      final client = ScriptedClient(<ScriptedResponse>[]);

      final (report, _) = await run(client);
      expect(report.batches, 0);
      expect(client.sent, isEmpty);
    });

    test('an edit keeping its picture sends no bytes', () async {
      final (id, bytes) = await map();
      await agreed(
        id,
        table: SilexgisRasterTables.maps,
        mapId: id,
        picture: bytes,
      );
      await rename(id, 'Renamed');
      final client = ScriptedClient(<ScriptedResponse>[
        answer(maps: <Map<String, Object?>>[verdict(id, 'updated')]),
      ]);

      await run(client);

      expect(touchedTransfers(client), isFalse);
      final sent = sentSection(client, SyncUploadSection.rasterMaps).single;
      expect(sent['baseRevision'], 'rev-$id');
      expect(sent['title'], 'Renamed');
      expect(sent.containsKey('stagedUploadId'), isFalse);
    });

    test('a new picture goes as staged bytes of the edit', () async {
      final (id, old) = await map();
      await agreed(
        id,
        table: SilexgisRasterTables.maps,
        mapId: id,
        picture: old,
      );
      final redrawn = <int>[0xFF, 0xD8, 0xFF, 1, 2, 3, 4];
      final row = await (db.select(
        db.rasterMaps,
      )..where((t) => t.uuid.equalsValue(id))).getSingle();
      await File('${base.path}/${row.fileName}').writeAsBytes(redrawn);
      await rename(id, 'Redrawn');
      final client = ScriptedClient(<ScriptedResponse>[
        ...staging(redrawn),
        answer(maps: <Map<String, Object?>>[verdict(id, 'updated')]),
      ]);

      await run(client);

      final sent = sentSection(client, SyncUploadSection.rasterMaps).single;
      expect(sent['stagedUploadId'], transferId);
      expect(sent['sha256'], sha256.convert(redrawn).toString());
      final state = (await rasters.readAll(profile))[id]!;
      expect(state.pictureSha256, sha256.convert(redrawn).toString());
      // The catalogue's revision of the new bytes is not known until read.
      expect(state.pictureVersion, isNull);
    });
  });

  group('rule 13', () {
    test('a picture fetched without its location never goes back up', () async {
      final (id, fetched) = await map();
      await agreed(
        id,
        table: SilexgisRasterTables.maps,
        mapId: id,
        picture: fetched,
        received: true,
      );
      final document = (await rasters.readAll(profile))[id]!.documentId!;
      await SilexgisFileCopyRepository(db).register(
        SilexgisFileCopyEntry(
          documentUuid: document,
          heldAs: SilexgisHeldAs.locationFree,
          origin: SilexgisCopyOrigin.server,
          versionId: 'v-1',
        ),
      );
      await rename(id, 'Renamed here');
      final client = ScriptedClient(<ScriptedResponse>[
        answer(maps: <Map<String, Object?>>[verdict(id, 'updated')]),
      ]);

      await run(client);

      expect(touchedTransfers(client), isFalse);
      final sent = sentSection(client, SyncUploadSection.rasterMaps).single;
      expect(sent['title'], 'Renamed here');
      expect(sent.containsKey('stagedUploadId'), isFalse);
    });
  });

  group('files', () {
    test(
      'switched off, a new map waits with its pins and an edit goes',
      () async {
        final (fresh, _) = await map(title: 'New');
        await pin(fresh);
        final (held, bytes) = await map(title: 'Held');
        await agreed(
          held,
          table: SilexgisRasterTables.maps,
          mapId: held,
          picture: bytes,
        );
        await rename(held, 'Held, renamed');
        final client = ScriptedClient(<ScriptedResponse>[
          answer(maps: <Map<String, Object?>>[verdict(held, 'updated')]),
        ]);

        final (report, maps) = await run(client, filesAllowed: false);

        expect(report.refusals, isEmpty);
        expect(touchedTransfers(client), isFalse);
        expect(
          sentSection(client, SyncUploadSection.rasterMaps).map((m) => m['id']),
          <String>[held.toString()],
        );
        expect(sentSection(client, SyncUploadSection.rasterPins), isEmpty);
        expect(maps.files.isEmpty, isTrue);
      },
    );

    test('kept for Wi-Fi, a new map waits and is counted', () async {
      final (_, _) = await map();
      final client = ScriptedClient(<ScriptedResponse>[]);

      final (report, maps) = await run(client, gate: const _NotNow());

      expect(report.batches, 0);
      expect(maps.files.waitingForNetwork, 1);
    });
  });

  group('answers', () {
    test('map_cave_fixed stops the map and keeps it as it is', () async {
      final (id, bytes) = await map();
      await agreed(
        id,
        table: SilexgisRasterTables.maps,
        mapId: id,
        picture: bytes,
      );
      await rename(id, 'Moved');
      final client = ScriptedClient(<ScriptedResponse>[
        answer(
          maps: <Map<String, Object?>>[
            verdict(id, 'rejected', code: SilexgisCodes.mapCaveFixed),
          ],
        ),
      ]);

      final (report, _) = await run(client);

      final refusal = report.refusals.single;
      expect(refusal.entityTable, 'raster_maps');
      expect(refusal.action, SilexgisAction.stop);
      // Sent once, not again in this run.
      expect(sentSection(client, SyncUploadSection.rasterMaps), hasLength(1));
      expect(
        (await localState.readRevisions(profile))[id]!.revision,
        'rev-$id',
      );
    });

    test('pin_exists has the map read again from the beginning', () async {
      final (id, bytes) = await map();
      await agreed(
        id,
        table: SilexgisRasterTables.maps,
        mapId: id,
        picture: bytes,
      );
      final pinId = await pin(id);
      await localState.writeStreamCursor(
        profile,
        setId,
        SyncStream.rasters,
        cursor: 'rasters-c9',
        setRevision: 1,
      );
      final client = ScriptedClient(<ScriptedResponse>[
        answer(
          pins: <Map<String, Object?>>[
            verdict(pinId, 'rejected', code: SilexgisCodes.pinExists),
          ],
        ),
      ]);

      final (report, _) = await run(client);

      expect(report.refusals.single.result.code, SilexgisCodes.pinExists);
      expect(
        (await localState.readStreamCursor(
          profile,
          setId,
          SyncStream.rasters,
        )).cursor,
        isNull,
      );
      expect((await localState.readRevisions(profile))[pinId], isNull);
    });

    test('a pin whose pixel the installation does not take stays', () async {
      final (id, bytes) = await map();
      await agreed(
        id,
        table: SilexgisRasterTables.maps,
        mapId: id,
        picture: bytes,
      );
      await pin(id, x: -3);
      final client = ScriptedClient(<ScriptedResponse>[]);

      final (report, _) = await run(client);
      expect(report.batches, 0);
    });
  });

  group('removals', () {
    test('a removed map goes alone, taking its pins with it', () async {
      final (id, bytes) = await map();
      await agreed(
        id,
        table: SilexgisRasterTables.maps,
        mapId: id,
        picture: bytes,
      );
      final pinId = await pin(id);
      await agreed(pinId, table: SilexgisRasterTables.pins, mapId: id);
      await (db.delete(
        db.cavePlaceToRasterMapDefinitions,
      )..where((t) => t.uuid.equalsValue(pinId))).go();
      await (db.delete(
        db.rasterMaps,
      )..where((t) => t.uuid.equalsValue(id))).go();
      final client = ScriptedClient(<ScriptedResponse>[
        answer(maps: <Map<String, Object?>>[verdict(id, 'deleted')]),
      ]);

      await run(client);

      expect(
        sentSection(client, SyncUploadSection.rasterMaps).single,
        <String, Object?>{
          'id': id.toString(),
          'baseRevision': 'rev-$id',
          'deleted': true,
        },
      );
      expect(sentSection(client, SyncUploadSection.rasterPins), isEmpty);
      final revisions = await localState.readRevisions(profile);
      expect(revisions[id], isNull);
      expect(revisions[pinId], isNull);
      expect(await rasters.readAll(profile), isEmpty);
    });

    test('a removed pin names its map', () async {
      final (id, bytes) = await map();
      await agreed(
        id,
        table: SilexgisRasterTables.maps,
        mapId: id,
        picture: bytes,
      );
      final pinId = await pin(id);
      await agreed(pinId, table: SilexgisRasterTables.pins, mapId: id);
      await (db.delete(
        db.cavePlaceToRasterMapDefinitions,
      )..where((t) => t.uuid.equalsValue(pinId))).go();
      final client = ScriptedClient(<ScriptedResponse>[
        answer(pins: <Map<String, Object?>>[verdict(pinId, 'deleted')]),
      ]);

      await run(client);

      expect(
        sentSection(client, SyncUploadSection.rasterPins).single,
        <String, Object?>{
          'id': pinId.toString(),
          'rasterMapId': id.toString(),
          'baseRevision': 'rev-$pinId',
          'deleted': true,
        },
      );
      expect((await localState.readRevisions(profile))[pinId], isNull);
    });
  });
}

class _NotNow implements SilexgisFileSendingGate {
  const _NotNow();

  @override
  Future<bool> mayFilesGo({required int files, required int bytes}) async =>
      false;
}
