import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_rasters.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_picture_frame.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_picture_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_rasters_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

import 'contract_fixtures.dart';
import 'scripted_client.dart';
import 'token_source.dart';

/// Raster maps down: read under the installation's identifiers, held back
/// where the caver has an edit not yet sent, pins of places this device does
/// not hold skipped, collisions kept local and reported — and each map's
/// picture fetched afterwards, named by its type, and never mistaken for the
/// caver's own.
void main() {
  const profile = 'p-1';
  const setId = 'set-1';
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'documents', 'rasters'],
  );
  final baseUri = Uri.parse('https://club.example.org');
  final clock = FakeClock(DateTime.utc(2026, 10, 28, 8));

  late Directory base;
  late AppDatabase db;
  late ChangeLogger logger;
  late SilexgisLocalStateRepository localState;
  late SilexgisHeldRowRepository heldRows;
  late SilexgisRasterStateRepository rasters;
  late SilexgisDocumentCatalogueRepository catalogue;
  late SilexgisFileCopyRepository copies;
  late SilexgisRasterApplier applier;

  final caveId = Uuid.v7();
  final placeId = Uuid.v7();
  final hiddenPlace = Uuid.v7();
  const revision = '2026-10-27T12:00:00Z';

  setUp(() async {
    base = await Directory.systemTemp.createTemp('silexgis_rasters_down_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final currentUser = CurrentUserService(
      db,
      UserRepository(db, () => loggerRef),
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    logger = loggerRef = ChangeLogger(db, currentUser, clock: clock);
    localState = SilexgisLocalStateRepository(db, clock: clock);
    heldRows = SilexgisHeldRowRepository(db, clock: clock);
    rasters = SilexgisRasterStateRepository(db);
    catalogue = SilexgisDocumentCatalogueRepository(db);
    copies = SilexgisFileCopyRepository(db, clock: clock);
    applier = SilexgisRasterApplier(
      db: db,
      logger: logger,
      localState: localState,
      heldRows: heldRows,
      rasters: rasters,
      catalogue: catalogue,
      profileUuid: profile,
      clock: clock,
    );
    await db.into(db.caves).insert(Cave(uuid: caveId, title: 'Invented'));
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlace(
            uuid: placeId,
            title: 'Sump',
            caveUuid: caveId,
            isEntrance: 0,
            isMainEntrance: 0,
          ),
        );
  });
  tearDown(() async {
    await db.close();
    await base.delete(recursive: true);
  });

  /// Recording 25, its placeholders filled with identifiers this device can
  /// hold.
  SyncRastersPage recorded25({
    required Uuid map,
    required Uuid pin,
    required Uuid document,
  }) => SyncRastersPage.fromJson(
    fillPlaceholders(
          ContractExchange('25-rasters-first-page').responseBody,
          <String, String>{
            '<map>': map.toString(),
            '<cave>': caveId.toString(),
            '<place>': placeId.toString(),
            '<pin>': pin.toString(),
            '<uuid-1>': document.toString(),
            '<timestamp>': revision,
            '<cursor>': 'rasters-c1',
          },
        )!
        as Map<String, Object?>,
  );

  SyncRastersPage page(
    List<Map<String, Object?>> maps, {
    List<Map<String, Object?>> tombstones = const <Map<String, Object?>>[],
    List<Map<String, Object?>>? pinTombstones,
  }) => SyncRastersPage.fromJson(<String, Object?>{
    'setRevision': 1,
    'settings': const <String, Object?>{},
    'maps': maps,
    'tombstones': tombstones,
    // Left out unless given: a server that does not name removed pins.
    'pinTombstones': ?pinTombstones,
    'nextCursor': 'rasters-c2',
    'hasMore': false,
  });

  Map<String, Object?> mapJson(
    Uuid id, {
    String title = 'Plan',
    String mapType = 'planView',
    Uuid? document,
    String? area,
    List<Map<String, Object?>> pins = const <Map<String, Object?>>[],
  }) => <String, Object?>{
    'id': id.toString(),
    'caveId': caveId.toString(),
    'caveAreaId': area,
    'title': title,
    'mapType': mapType,
    'sortOrder': 1,
    'documentId': (document ?? Uuid.v7()).toString(),
    'revision': revision,
    'pins': pins,
  };

  Map<String, Object?> pinJson(
    Uuid id, {
    Uuid? place,
    int x = 10,
    int y = 20,
  }) => <String, Object?>{
    'id': id.toString(),
    'placeId': (place ?? placeId).toString(),
    'x': x,
    'y': y,
    'revision': revision,
  };

  /// [document] in the catalogue as the map's picture on the cave.
  Future<void> catalogued(
    Uuid document, {
    String mimeType = 'image/png',
    String reach = 'original',
    String? sha,
    int? size,
    String version = 'version-1',
  }) => catalogue.applyPage(
    profile,
    SyncDocumentsPage.fromJson(<String, Object?>{
      'setRevision': 1,
      'links': <Object?>[
        <String, Object?>{
          'id': 'link-$document-$version',
          'documentId': document.toString(),
          'target': <String, Object?>{
            'kind': 'feature',
            'id': caveId.toString(),
          },
          'role': 'map2d',
          'caption': 'Plan',
          'sortOrder': 0,
          'isPrimary': false,
          'inDefaultSet': false,
          'revision': revision,
          'document': <String, Object?>{
            'id': document.toString(),
            'title': 'plan',
            'description': null,
            'fileKind': 'photo',
            'mimeType': mimeType,
            'sizeBytes': size,
            'sha256': sha,
            'versionId': version,
            'reach': reach,
            'renditions': const <int>[2400, 1200],
            'capturedAt': null,
            'createdAt': revision,
            'updatedAt': revision,
          },
        },
      ],
      'tombstones': const <Object?>[],
      'nextCursor': 'd1',
      'hasMore': false,
    }),
  );

  Future<RasterMap?> mapRow(Uuid id) => (db.select(
    db.rasterMaps,
  )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();

  Future<List<CavePlaceToRasterMapDefinition>> pinsOf(Uuid map) => (db.select(
    db.cavePlaceToRasterMapDefinitions,
  )..where((t) => t.rasterMapUuid.equalsValue(map))).get();

  group('25-rasters-first-page', () {
    test('the map lands under the server\'s ids, with its one pin', () async {
      final map = Uuid.v7();
      final pin = Uuid.v7();
      final document = Uuid.v7();
      await catalogued(document);

      final applied = await applier.applyPage(
        recorded25(map: map, pin: pin, document: document),
      );

      expect(applied.mapsInserted, 1);
      expect(applied.pinsInserted, 1);
      final row = (await mapRow(map))!;
      expect(row.caveUuid, caveId);
      expect(row.title, 'Plan');
      expect(row.mapType, 'plane view');
      expect(row.orderIndex, 0);
      expect(row.caveAreaUuid, isNull);
      // Where the picture will be, named by its document and its type.
      expect(row.fileName, 'cave_$caveId/raster_$document.png');
      expect(row.fileHash, isNull);
      final pins = await pinsOf(map);
      expect(pins.single.uuid, pin);
      expect(pins.single.cavePlaceUuid, placeId);
      expect(pins.single.xCoordinate, 120);
      expect(pins.single.yCoordinate, 80);

      final revisions = await localState.readRevisions(profile);
      expect(revisions[map]!.revision, revision);
      expect(revisions[map]!.entityTable, 'raster_maps');
      expect(
        revisions[pin]!.entityTable,
        'cave_place_to_raster_map_definitions',
      );
      final states = await rasters.readAll(profile);
      expect(states[map]!.received, isTrue);
      expect(states[map]!.documentId, document);
      expect(states[map]!.pictureSha256, isNull);
      // The frame the pins are in; the recording does not say how the
      // renditions are turned.
      expect(
        states[map]!.pictureFrame,
        const SilexgisPictureFrame(width: 64, height: 48),
      );
      expect(states[pin]!.mapUuid, map);
      expect(states[pin]!.pictureFrame, const SilexgisPictureFrame());
      // An import, not a caver's edit: nothing to carry to other devices.
      expect(await db.select(db.changeLog).get(), isEmpty);
      // The picture's catalogue entry is no documentation file.
      expect(await db.select(db.documentationFiles).get(), isEmpty);
    });

    test('a map read again keeps what the server now says of its '
        'picture', () async {
      final map = Uuid.v7();
      final document = Uuid.v7();
      await applier.applyPage(
        recorded25(map: map, pin: Uuid.v7(), document: document),
      );
      await applier.applyPage(
        page(<Map<String, Object?>>[
          <String, Object?>{
            ...mapJson(map, document: document),
            'pictureWidth': 300,
            'pictureHeight': 200,
            'pictureMirrored': true,
            'pictureTurn': 90,
          },
        ]),
      );
      expect(
        (await rasters.readAll(profile))[map]!.pictureFrame,
        const SilexgisPictureFrame(
          width: 300,
          height: 200,
          mirrored: true,
          turn: 90,
        ),
      );
    });

    test('a picture the catalogue does not describe is named jpg', () async {
      final map = Uuid.v7();
      final document = Uuid.v7();
      await applier.applyPage(
        recorded25(map: map, pin: Uuid.v7(), document: document),
      );
      expect(
        (await mapRow(map))!.fileName,
        'cave_$caveId/raster_$document.jpg',
      );
    });
  });

  test('a map of a cave this device does not hold is skipped', () async {
    final applied = await applier.applyPage(
      page(<Map<String, Object?>>[
        <String, Object?>{
          ...mapJson(Uuid.v7()),
          'caveId': Uuid.v7().toString(),
        },
      ]),
    );
    expect(applied.withoutCave, 1);
    expect(await db.select(db.rasterMaps).get(), isEmpty);
  });

  test('an area this device does not hold is kept aside', () async {
    final map = Uuid.v7();
    final area = Uuid.v7().toString();
    await applier.applyPage(
      page(<Map<String, Object?>>[mapJson(map, area: area)]),
    );
    expect((await mapRow(map))!.caveAreaUuid, isNull);
    expect((await rasters.readAll(profile))[map]!.areaId.toString(), area);
  });

  test('a pin of a place this device does not hold is skipped', () async {
    final map = Uuid.v7();
    final applied = await applier.applyPage(
      page(<Map<String, Object?>>[
        mapJson(
          map,
          pins: <Map<String, Object?>>[pinJson(Uuid.v7(), place: hiddenPlace)],
        ),
      ]),
    );
    expect(applied.pinsWithoutPlace, 1);
    expect(await pinsOf(map), isEmpty);
  });

  group('held back', () {
    test('a map with an edit not yet sent stays as the caver has it', () async {
      final map = Uuid.v7();
      await applier.applyPage(page(<Map<String, Object?>>[mapJson(map)]));
      await (db.update(
        db.rasterMaps,
      )..where((t) => t.uuid.equalsValue(map))).write(
        RasterMapsCompanion(
          title: const Value('Mine'),
          updatedAt: Value(clock.nowMs() + 1000),
        ),
      );

      final applied = await applier.applyPage(
        page(<Map<String, Object?>>[mapJson(map, title: 'Theirs')]),
      );
      expect(applied.heldBack, 1);
      expect((await mapRow(map))!.title, 'Mine');
    });

    test('a pin waiting for a reviewer stays as the caver has it', () async {
      final map = Uuid.v7();
      final pin = Uuid.v7();
      await applier.applyPage(
        page(<Map<String, Object?>>[
          mapJson(map, pins: <Map<String, Object?>>[pinJson(pin)]),
        ]),
      );
      await heldRows.recordHeld(profile, <SilexgisHeldEntry>[
        SilexgisHeldEntry(
          section: SyncUploadSection.rasterPins,
          entityUuid: pin,
          entityTable: 'cave_place_to_raster_map_definitions',
          reviewId: 'review-1',
          sentLocalUpdatedAt: (await pinsOf(map)).single.updatedAt,
        ),
      ]);
      final applied = await applier.applyPage(
        page(<Map<String, Object?>>[
          mapJson(map, pins: <Map<String, Object?>>[pinJson(pin, x: 99)]),
        ]),
      );
      expect(applied.heldBack, 1);
      expect((await pinsOf(map)).single.xCoordinate, 10);
    });
  });

  group('a pin missing from a server that names no removed pins', () {
    Future<(Uuid, Uuid)> mapWithPin() async {
      final map = Uuid.v7();
      final pin = Uuid.v7();
      await applier.applyPage(
        page(<Map<String, Object?>>[
          mapJson(map, pins: <Map<String, Object?>>[pinJson(pin)]),
        ]),
      );
      return (map, pin);
    }

    test('is removed when it came from the installation alone', () async {
      final (map, pin) = await mapWithPin();
      final applied = await applier.applyPage(
        page(<Map<String, Object?>>[mapJson(map)]),
      );
      expect(applied.pinsRemoved, 1);
      expect(await pinsOf(map), isEmpty);
      expect((await localState.readRevisions(profile))[pin], isNull);
      expect((await rasters.readAll(profile))[pin], isNull);
    });

    test('is kept once this device has sent it — it may be withheld', () async {
      final (map, pin) = await mapWithPin();
      await rasters.recordSent(profile, <SilexgisRasterState>[
        SilexgisRasterState(entityUuid: pin, mapUuid: map, isPin: true),
      ]);
      await applier.applyPage(page(<Map<String, Object?>>[mapJson(map)]));
      expect((await pinsOf(map)).single.uuid, pin);
    });

    test('is kept when it is the caver\'s own and never sent', () async {
      final (map, _) = await mapWithPin();
      final mine = Uuid.v7();
      final other = Uuid.v7();
      await db
          .into(db.cavePlaces)
          .insert(
            CavePlace(
              uuid: other,
              title: 'Chamber',
              caveUuid: caveId,
              isEntrance: 0,
              isMainEntrance: 0,
            ),
          );
      await db
          .into(db.cavePlaceToRasterMapDefinitions)
          .insert(
            CavePlaceToRasterMapDefinitionsCompanion.insert(
              uuid: mine,
              cavePlaceUuid: other,
              rasterMapUuid: map,
            ),
          );
      await applier.applyPage(page(<Map<String, Object?>>[mapJson(map)]));
      expect((await pinsOf(map)).map((p) => p.uuid), <Uuid>[mine]);
    });
  });

  group('with the pin tombstones named', () {
    Future<(Uuid, Uuid)> mapWithPin() async {
      final map = Uuid.v7();
      final pin = Uuid.v7();
      await applier.applyPage(
        page(<Map<String, Object?>>[
          mapJson(map, pins: <Map<String, Object?>>[pinJson(pin)]),
        ]),
      );
      return (map, pin);
    }

    Map<String, Object?> pinTombstone(Uuid map, Uuid pin) => <String, Object?>{
      'id': pin.toString(),
      'mapId': map.toString(),
      'deletedAt': revision,
    };

    test('a tombstone removes the pin and what is kept of it', () async {
      final (map, pin) = await mapWithPin();
      final applied = await applier.applyPage(
        page(
          <Map<String, Object?>>[mapJson(map)],
          pinTombstones: <Map<String, Object?>>[pinTombstone(map, pin)],
        ),
      );
      expect(applied.pinsRemoved, 1);
      expect(await pinsOf(map), isEmpty);
      expect((await mapRow(map)), isNotNull);
      expect((await localState.readRevisions(profile))[pin], isNull);
      expect((await rasters.readAll(profile))[pin], isNull);
      expect(await db.select(db.changeLog).get(), isEmpty);
    });

    test('a tombstone removes a pin this device sent as well', () async {
      final (map, pin) = await mapWithPin();
      await rasters.recordSent(profile, <SilexgisRasterState>[
        SilexgisRasterState(entityUuid: pin, mapUuid: map, isPin: true),
      ]);
      final applied = await applier.applyPage(
        page(
          const <Map<String, Object?>>[],
          pinTombstones: <Map<String, Object?>>[pinTombstone(map, pin)],
        ),
      );
      expect(applied.pinsRemoved, 1);
      expect(await pinsOf(map), isEmpty);
    });

    test(
      'a tombstone of a pin this device never held changes nothing',
      () async {
        final (map, pin) = await mapWithPin();
        final applied = await applier.applyPage(
          page(
            <Map<String, Object?>>[
              mapJson(map, pins: <Map<String, Object?>>[pinJson(pin)]),
            ],
            pinTombstones: <Map<String, Object?>>[pinTombstone(map, Uuid.v7())],
          ),
        );
        expect(applied.pinsRemoved, 0);
        expect((await pinsOf(map)).single.uuid, pin);
      },
    );

    test('a tombstone leaves a pin with an unsent edit to the caver', () async {
      final (map, pin) = await mapWithPin();
      await (db.update(
        db.cavePlaceToRasterMapDefinitions,
      )..where((t) => t.uuid.equalsValue(pin))).write(
        CavePlaceToRasterMapDefinitionsCompanion(
          xCoordinate: const Value(77),
          updatedAt: Value(clock.nowMs() + 1000),
        ),
      );
      final applied = await applier.applyPage(
        page(
          const <Map<String, Object?>>[],
          pinTombstones: <Map<String, Object?>>[pinTombstone(map, pin)],
        ),
      );
      expect(applied.pinsRemoved, 0);
      expect(applied.heldBack, 1);
      expect((await pinsOf(map)).single.xCoordinate, 77);
    });

    test('a pin merely missing is kept, whatever its history', () async {
      final (map, pin) = await mapWithPin();
      // Received here and never sent: the interim rule would remove it.
      final applied = await applier.applyPage(
        page(<Map<String, Object?>>[mapJson(map)], pinTombstones: const []),
      );
      expect(applied.pinsRemoved, 0);
      expect((await pinsOf(map)).single.uuid, pin);
      expect((await localState.readRevisions(profile))[pin], isNotNull);
    });

    test('a pin missing is kept beside a tombstone naming another', () async {
      final (map, pin) = await mapWithPin();
      final applied = await applier.applyPage(
        page(
          <Map<String, Object?>>[mapJson(map)],
          pinTombstones: <Map<String, Object?>>[pinTombstone(map, Uuid.v7())],
        ),
      );
      expect(applied.pinsRemoved, 0);
      expect((await pinsOf(map)).single.uuid, pin);
    });
  });

  group('collisions', () {
    test(
      'a map of the same name keeps the local one and the page goes on',
      () async {
        final local = Uuid.v7();
        await db
            .into(db.rasterMaps)
            .insert(
              RasterMapsCompanion.insert(
                uuid: local,
                title: 'Plan',
                mapType: 'plane view',
                fileName: 'cave_$caveId/raster_1.jpg',
                caveUuid: caveId,
              ),
            );
        final theirs = Uuid.v7();
        final next = Uuid.v7();
        final applied = await applier.applyPage(
          page(<Map<String, Object?>>[
            mapJson(theirs),
            mapJson(next, title: 'Profile', mapType: 'extendedProfile'),
          ]),
        );
        expect(applied.collisions, <Uuid>[theirs]);
        expect(applied.mapsInserted, 1);
        expect(await mapRow(theirs), isNull);
        expect((await mapRow(next))!.mapType, 'extended profile');
        expect((await mapRow(local))!.title, 'Plan');
      },
    );

    test('a pin of a place another pin marks keeps the local one', () async {
      final map = Uuid.v7();
      await applier.applyPage(page(<Map<String, Object?>>[mapJson(map)]));
      final mine = Uuid.v7();
      await db
          .into(db.cavePlaceToRasterMapDefinitions)
          .insert(
            CavePlaceToRasterMapDefinitionsCompanion.insert(
              uuid: mine,
              cavePlaceUuid: placeId,
              rasterMapUuid: map,
            ),
          );
      final theirs = Uuid.v7();
      final applied = await applier.applyPage(
        page(<Map<String, Object?>>[
          mapJson(map, pins: <Map<String, Object?>>[pinJson(theirs)]),
        ]),
      );
      expect(applied.collisions, <Uuid>[theirs]);
      expect((await pinsOf(map)).map((p) => p.uuid), <Uuid>[mine]);
    });
  });

  test('a tombstone takes the map and its pins', () async {
    final map = Uuid.v7();
    final pin = Uuid.v7();
    await applier.applyPage(
      page(<Map<String, Object?>>[
        mapJson(map, pins: <Map<String, Object?>>[pinJson(pin)]),
      ]),
    );
    final applied = await applier.applyPage(
      page(
        const <Map<String, Object?>>[],
        tombstones: <Map<String, Object?>>[
          <String, Object?>{'id': map.toString(), 'deletedAt': revision},
        ],
      ),
    );
    expect(applied.mapsRemoved, 1);
    expect(await mapRow(map), isNull);
    expect(await pinsOf(map), isEmpty);
    final revisions = await localState.readRevisions(profile);
    expect(revisions[map], isNull);
    expect(revisions[pin], isNull);
  });

  group('the picture', () {
    late _Files files;
    late ScriptedClient api;

    SilexgisRasterPictureFetcher fetcher(List<ScriptedResponse> script) {
      files = _Files();
      api = ScriptedClient(script);
      return SilexgisRasterPictureFetcher(
        db: db,
        logger: logger,
        api: SilexgisSyncApi(
          SilexgisHttp(
            baseUri: baseUri,
            tokens: FixedTokenSource(),
            client: api,
          ),
        ),
        fetcher: SilexgisFileFetcher(baseUri: baseUri, client: files),
        localState: localState,
        catalogue: catalogue,
        copies: copies,
        rasters: rasters,
        baseDir: () async => base,
        profileUuid: profile,
      );
    }

    ScriptedResponse address(Uuid document, {Object rendition = 'original'}) =>
        ScriptedResponse.json(
          path: SilexgisContract.fileLinksPath,
          json: <String, Object?>{
            'links': <Object?>[
              <String, Object?>{
                'documentId': document.toString(),
                'rendition': rendition,
                'url': '/api/v1/files/f-$document/content?token=t1',
                'expiresAt': '2026-10-28T13:00:00Z',
                'sizeBytes': null,
                'sha256': null,
              },
            ],
            'refused': const <Object?>[],
          },
        );

    /// Invented bytes; never a real picture.
    final picture = <int>[
      0x52,
      0x49,
      0x46,
      0x46,
      1,
      2,
      3,
      4,
      ...'WEBP'.codeUnits,
      9,
      9,
    ];

    test('arrives without location, named by its type, and stands for the '
        'installation\'s', () async {
      final map = Uuid.v7();
      final document = Uuid.v7();
      await catalogued(document, mimeType: 'image/webp', reach: 'locationFree');
      await applier.applyPage(
        page(<Map<String, Object?>>[mapJson(map, document: document)]),
      );
      final before = (await mapRow(map))!;
      final pictures = fetcher(<ScriptedResponse>[address(document)]);
      files.serve('/api/v1/files/f-$document/content', picture, 'image/webp');

      final report = await pictures.fetchPending();

      expect(report.fetched, 1);
      final row = (await mapRow(map))!;
      expect(row.fileName, 'cave_$caveId/raster_$document.webp');
      expect(await File('${base.path}/${row.fileName}').readAsBytes(), picture);
      expect(row.fileHash, sha256.convert(picture).toString());
      expect(row.fileSize, picture.length);
      // Still agreed with the installation: nothing to send.
      expect(row.updatedAt, before.updatedAt);
      expect(
        (await localState.readRevisions(
          profile,
        ))[map]!.agreesWith(row.updatedAt),
        isTrue,
      );
      final copy = (await copies.read(document))!;
      expect(copy.heldAs, SilexgisHeldAs.locationFree);
      expect(copy.origin, SilexgisCopyOrigin.server);
      expect(copy.versionId, 'version-1');
      final state = (await rasters.readAll(profile))[map]!;
      expect(state.pictureSha256, sha256.convert(picture).toString());
      expect(state.pictureVersion, 'version-1');
      // Never a documentation file, and nothing to carry to other devices.
      expect(await db.select(db.documentationFiles).get(), isEmpty);
      expect(await db.select(db.changeLog).get(), isEmpty);

      // Fetched once: the next run has nothing to do.
      final again = fetcher(const <ScriptedResponse>[]);
      expect((await again.fetchPending()).fetched, 0);
    });

    test(
      'with no catalogue entry, its extension comes from what arrived',
      () async {
        final map = Uuid.v7();
        final document = Uuid.v7();
        await applier.applyPage(
          page(<Map<String, Object?>>[mapJson(map, document: document)]),
        );
        final pictures = fetcher(<ScriptedResponse>[address(document)]);
        files.serve('/api/v1/files/f-$document/content', picture, 'image/png');

        await pictures.fetchPending();

        final row = (await mapRow(map))!;
        expect(row.fileName, 'cave_$caveId/raster_$document.png');
        // The name given before the picture said what it is is gone.
        expect(
          await File('${base.path}/cave_$caveId/raster_$document.jpg').exists(),
          isFalse,
        );
        expect(await File('${base.path}/${row.fileName}').exists(), isTrue);
      },
    );

    test(
      'one this device sent takes the catalogue\'s revision unfetched',
      () async {
        final map = Uuid.v7();
        final document = Uuid.v7();
        await applier.applyPage(
          page(<Map<String, Object?>>[mapJson(map, document: document)]),
        );
        await rasters.recordSent(profile, <SilexgisRasterState>[
          SilexgisRasterState(
            entityUuid: map,
            mapUuid: map,
            pictureSha256: 'ab12',
          ),
        ]);
        await catalogued(document, version: 'version-7');

        final report = await fetcher(const <ScriptedResponse>[]).fetchPending();

        expect(report.fetched, 0);
        expect(api.sent, isEmpty);
        expect(
          (await rasters.readAll(profile))[map]!.pictureVersion,
          'version-7',
        );
      },
    );

    test('a server error on one picture is that picture\'s alone', () async {
      final map = Uuid.v7();
      final document = Uuid.v7();
      await catalogued(document);
      await applier.applyPage(
        page(<Map<String, Object?>>[mapJson(map, document: document)]),
      );
      final pictures = fetcher(<ScriptedResponse>[
        ScriptedResponse.problem(
          path: SilexgisContract.fileLinksPath,
          status: 503,
          title: 'Unavailable',
        ),
      ]);

      final report = await pictures.fetchPending();

      expect(report.notFetched, 1);
      expect(await mapRow(map), isNotNull);
    });

    test('a refused picture is counted and asked for again next run', () async {
      final map = Uuid.v7();
      final document = Uuid.v7();
      await catalogued(document);
      await applier.applyPage(
        page(<Map<String, Object?>>[mapJson(map, document: document)]),
      );
      final pictures = fetcher(<ScriptedResponse>[
        ScriptedResponse.json(
          path: SilexgisContract.fileLinksPath,
          json: <String, Object?>{
            'links': const <Object?>[],
            'refused': <Object?>[
              <String, Object?>{
                'documentId': document.toString(),
                'rendition': 'original',
                'code': 'sync.document_unavailable',
              },
            ],
          },
        ),
      ]);

      final report = await pictures.fetchPending();

      expect(report.notFetched, 1);
      expect((await rasters.readAll(profile))[map]!.pictureSha256, isNull);
    });
  });

  test('the stream reads on its own cursor, then fetches pictures', () async {
    final map = Uuid.v7();
    final document = Uuid.v7();
    final api = ScriptedClient(<ScriptedResponse>[
      ScriptedResponse.json(
        path: SilexgisContract.rastersPath(setId),
        json: <String, Object?>{
          'setRevision': 3,
          'settings': const <String, Object?>{},
          'maps': <Object?>[mapJson(map, document: document)],
          'tombstones': const <Object?>[],
          'nextCursor': 'rasters-c3',
          'hasMore': false,
        },
      ),
    ]);
    final syncApi = SilexgisSyncApi(
      SilexgisHttp(baseUri: baseUri, tokens: FixedTokenSource(), client: api),
    );
    final report = await SilexgisRastersRunner(
      api: syncApi,
      localState: localState,
      applier: applier,
      profileUuid: profile,
    ).run(setId, capabilities: capabilities);

    expect(report.pages, 1);
    expect(report.applied.mapsInserted, 1);
    expect(
      (await localState.readStreamCursor(
        profile,
        setId,
        SyncStream.rasters,
      )).cursor,
      'rasters-c3',
    );
    // The features' own position is untouched.
    expect((await localState.readSetState(profile, setId)).cursor, isNull);
  });
}

/// Serves invented file bytes at fixed paths.
class _Files extends http.BaseClient {
  final Map<String, (List<int>, String)> _served =
      <String, (List<int>, String)>{};

  void serve(String path, List<int> bytes, String contentType) =>
      _served[path] = (bytes, contentType);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final served = _served[request.url.path];
    if (served == null) {
      return http.StreamedResponse(const Stream<List<int>>.empty(), 404);
    }
    final (bytes, type) = served;
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      contentLength: bytes.length,
      headers: <String, String>{'content-type': type},
      request: request,
    );
  }
}
