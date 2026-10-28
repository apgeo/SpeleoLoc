import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/model/sync_rasters.dart';
import 'package:speleoloc/services/silexgis/model/sync_set.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_staged_upload_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_controller.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/services/user_repository.dart';

import 'live_server.dart';

/// Raster maps both ways, against a real installation.
///
/// Off by default, like every live test. To run it:
///
/// 1. From a SilexGIS checkout: `node deploy/speleoloc-dev.mjs up`.
/// 2. `SPELEO_LOC_SILEXGIS_LIVE=1 flutter test test/services/silexgis/silexgis_rasters_live_test.dart`
///
/// `SPELEO_LOC_SILEXGIS_URL` overrides the base address. The member reads the
/// seeded `Demo plan` with the one pin it may see, and its picture. It may
/// not add maps to the administrator's caves, so it then surveys a cave of
/// its own, sent in the same upload, and sends a map of it with a picture the
/// test draws and one pin; reads it back from the stream; renames it, which
/// sends no bytes; and takes it down again.
void main() {
  final env = Platform.environment;
  if (env['SPELEO_LOC_SILEXGIS_LIVE'] != '1') {
    test(
      'SilexGIS rasters live test skipped (set SPELEO_LOC_SILEXGIS_LIVE=1)',
      () {},
    );
    return;
  }

  final baseUri = Uri.parse(
    env['SPELEO_LOC_SILEXGIS_URL'] ?? 'http://127.0.0.1:5205',
  );
  const email = 'member@dev.local';
  const password = 'dev-member-pass-1';
  const profileUuid = 'rasters-live';

  late SilexgisAuthService auth;
  late SilexgisSyncApi api;
  late SyncSet set;

  late Directory base;
  late AppDatabase db;
  late SilexgisSyncController controller;
  late SilexgisLocalStateRepository localState;
  late SilexgisRasterStateRepository rasters;
  late SilexgisStagedUploadRepository staged;

  final areaId = Uuid.v7();
  final caveId = Uuid.v7();
  final placeId = Uuid.v7();
  final mapId = Uuid.v7();
  final pinId = Uuid.v7();
  late String pictureHash;

  setUpAll(() async {
    final tokens = InMemoryRefreshTokenStore();
    auth = SilexgisAuthService(
      baseUri: baseUri,
      profileUuid: profileUuid,
      store: tokens,
    );
    await auth.signIn(email: email, password: password);
    api = SilexgisSyncApi(SilexgisHttp(baseUri: baseUri, tokens: auth));

    final token = await auth.accessToken();
    final roots = await demoCaveFeatureIds(
      baseUri,
      token,
      names: const <String>{'Peștera Demo Mare'},
    );
    expect(
      roots,
      hasLength(1),
      reason:
          'the demonstration dataset is not seeded — run '
          '`node deploy/speleoloc-dev.mjs reset` then `up`',
    );
    set = await api.createSet(
      SyncSetWrite(
        name: 'rasters live ${DateTime.now().millisecondsSinceEpoch}',
        cavingGroupId: await demoCavingGroupId(baseUri, token),
        uploadVisibility: SyncVisibility.cavingGroup,
        rootFeatureIds: roots,
        settings: const <String, Object?>{'pciStrategy': 'ro-default'},
      ),
    );

    base = await Directory.systemTemp.createTemp('silexgis_rasters_live_');
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
    rasters = SilexgisRasterStateRepository(db);
    staged = SilexgisStagedUploadRepository(db);

    final profiles = SilexgisProfileRepository(
      ConfigurationRepository(db),
      tokens,
      localState,
    );
    await profiles.save(
      SilexgisProfile(
        profileUuid: profileUuid,
        displayName: 'Development server',
        baseUrl: baseUri.toString(),
        accountEmail: email,
        syncSetId: set.id,
        // The demo caves are the administrator's; what this device surveys
        // goes somewhere of its own.
        uploadsNewRoots: true,
        // No network to ask about here; the rule has its own tests.
        filesOnlyOverWifi: false,
      ),
    );
    controller = SilexgisSyncController(
      db: db,
      profiles: profiles,
      localState: localState,
      heldRows: SilexgisHeldRowRepository(db),
      people: SilexgisPeopleRepository(db),
      catalogue: SilexgisDocumentCatalogueRepository(db),
      logger: logger,
      caves: CaveRepository(db, currentUser, logger),
      places: CavePlaceRepository(db, currentUser, logger),
      tokens: tokens,
      staged: staged,
      rasters: rasters,
      documentsDir: () async => base,
    );
  });

  tearDownAll(() async {
    await api.deleteSet(set.id);
    auth.close();
    await db.close();
    await base.delete(recursive: true);
  });

  Future<void> sync() async {
    await controller.syncDefault();
    final progress = controller.progress;
    expect(
      progress.phase,
      SilexgisSyncPhase.completed,
      reason: progress.message,
    );
    expect(
      progress.upload?.refusals ?? const [],
      isEmpty,
      reason: progress.upload?.refusals
          .map((r) => '${r.entityTable} ${r.result.code} ${r.result.detail}')
          .join('; '),
    );
  }

  /// The map [id] as the rasters stream hands it now, read from the
  /// beginning.
  Future<SyncRasterMap?> readBack(Uuid id) async {
    String? cursor;
    var more = true;
    while (more) {
      final page = await api.rasters(set.id, cursor: cursor);
      for (final map in page.maps) {
        if (map.id == id.toString()) return map;
      }
      cursor = page.nextCursor;
      more = page.hasMore;
    }
    return null;
  }

  test('the installation serves raster maps', () async {
    final capabilities = await api.capabilities();
    expect(capabilities.servesRasters, isTrue);
  });

  test('the member gets the demo plan with one pin, not two', () async {
    await sync();

    final plan = await (db.select(
      db.rasterMaps,
    )..where((t) => t.title.equals('Demo plan'))).getSingle();
    final pins = await (db.select(
      db.cavePlaceToRasterMapDefinitions,
    )..where((t) => t.rasterMapUuid.equalsValue(plan.uuid))).get();
    expect(pins, hasLength(1));
    final marker = await (db.select(
      db.cavePlaces,
    )..where((t) => t.uuid.equalsValue(pins.single.cavePlaceUuid))).getSingle();
    expect(marker.title, 'Demo marker A');
    expect(controller.progress.rasters?.applied.pinsWithoutPlace ?? 0, 0);

    // Its picture arrived, under its document, and stands for the
    // installation's.
    expect(controller.progress.rasters?.pictures.notFetched, 0);
    final state = (await rasters.readAll(profileUuid))[plan.uuid]!;
    expect(state.received, isTrue);
    final document = state.documentId!;
    expect(
      plan.fileName,
      startsWith('cave_${plan.caveUuid}/raster_$document.'),
    );
    final file = File('${base.path}/${plan.fileName}');
    expect(await file.exists(), isTrue);
    final hash = sha256.convert(await file.readAsBytes()).toString();
    expect(plan.fileHash, hash);
    expect(state.pictureSha256, hash);
    final copy = (await SilexgisFileCopyRepository(db).read(document))!;
    expect(copy.origin, SilexgisCopyOrigin.server);
    // Never a documentation file, and an import rather than an edit.
    expect(await db.select(db.documentationFiles).get(), isEmpty);
    expect(await db.select(db.changeLog).get(), isEmpty);

    // A second run has nothing to send and nothing to fetch.
    await sync();
    expect(controller.progress.upload?.batches ?? 0, 0);
    expect(controller.progress.rasters?.pictures.fetched, 0);
  });

  test('a map of its own with one pin goes up and reads back', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final tag = caveId.toString().substring(0, 8);
    await db
        .into(db.surfaceAreas)
        .insert(
          SurfaceArea(
            uuid: areaId,
            title: 'Massif $tag',
            generalAreaIdentifier: 'DU',
            updatedAt: now,
          ),
        );
    await db
        .into(db.caves)
        .insert(
          Cave(
            uuid: caveId,
            title: 'Peștera Hartă $tag',
            surfaceAreaUuid: areaId,
            caveLocalIndex: 'R1',
            updatedAt: now,
          ),
        );
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlace(
            uuid: placeId,
            title: 'Sala Hărții $tag',
            caveUuid: caveId,
            isEntrance: 0,
            isMainEntrance: 0,
            updatedAt: now,
          ),
        );

    // An invented picture, drawn here: a gradient, no camera, no position.
    final picture = img.Image(width: 320, height: 200);
    for (final pixel in picture) {
      pixel
        ..r = pixel.x % 256
        ..g = pixel.y
        ..b = 64;
    }
    final bytes = img.encodePng(picture);
    pictureHash = sha256.convert(bytes).toString();
    final relPath = 'cave_$caveId/raster_$now.png';
    final file = File('${base.path}/$relPath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    await db
        .into(db.rasterMaps)
        .insert(
          RasterMapsCompanion.insert(
            uuid: mapId,
            title: 'Live plan $tag',
            mapType: 'extended profile',
            fileName: relPath,
            caveUuid: caveId,
          ).copyWith(
            fileHash: Value(pictureHash),
            fileSize: Value(bytes.length),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await db
        .into(db.cavePlaceToRasterMapDefinitions)
        .insert(
          CavePlaceToRasterMapDefinitionsCompanion.insert(
            uuid: pinId,
            cavePlaceUuid: placeId,
            rasterMapUuid: mapId,
          ).copyWith(
            xCoordinate: const Value(150),
            yCoordinate: const Value(90),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    await sync();

    expect(controller.progress.files.staged, 1);
    expect(controller.progress.files.held, 0);
    final revisions = await localState.readRevisions(profileUuid);
    expect(revisions[mapId]?.entityTable, 'raster_maps');
    expect(
      revisions[pinId]?.entityTable,
      'cave_place_to_raster_map_definitions',
    );
    final states = await rasters.readAll(profileUuid);
    expect(states[mapId]!.sent, isTrue);
    expect(states[mapId]!.received, isFalse);
    expect(states[mapId]!.pictureSha256, pictureHash);
    expect(
      (await staged.read(profileUuid, mapId))!.state,
      SilexgisStagedState.adopted,
    );

    // A set names roots, and the new massif is not one yet: naming it is what
    // makes the stream hand its maps over.
    final current = await api.getSet(set.id);
    await api.replaceSet(
      set.id,
      current.toWrite().copyWith(
        rootFeatureIds: <String>[...current.rootFeatureIds, areaId.toString()],
      ),
    );

    final server = await readBack(mapId);
    expect(server, isNotNull);
    expect(server!.caveId, caveId.toString());
    expect(server.title, 'Live plan $tag');
    expect(server.mapType, SyncRasterMapType.extendedProfile);
    expect(server.documentId, isNotNull);
    final pin = server.pins.single;
    expect(pin.id, pinId.toString());
    expect(pin.placeId, placeId.toString());
    expect(pin.x, 150);
    expect(pin.y, 90);

    // Read back here too: the picture this device sent is not fetched again,
    // and the caver's own file stays as it was.
    await sync();
    expect(controller.progress.upload?.batches ?? 0, 0);
    expect(controller.progress.rasters?.pictures.fetched, 0);
    final local = await (db.select(
      db.rasterMaps,
    )..where((t) => t.uuid.equalsValue(mapId))).getSingle();
    expect(local.fileName, relPath);
    expect(sha256.convert(await file.readAsBytes()).toString(), pictureHash);
    final state = (await rasters.readAll(profileUuid))[mapId]!;
    expect(state.documentId.toString(), server.documentId);
    expect(state.pictureVersion, isNotNull);
  });

  test('renaming it sends no bytes', () async {
    await (db.update(
      db.rasterMaps,
    )..where((t) => t.uuid.equalsValue(mapId))).write(
      RasterMapsCompanion(
        title: const Value('Live plan, renamed'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    await sync();

    expect(controller.progress.upload?.written, 1);
    expect(controller.progress.files.staged, 0);
    final server = await readBack(mapId);
    expect(server!.title, 'Live plan, renamed');
  });

  test('removing it here takes it and its pin down there', () async {
    await (db.delete(
      db.cavePlaceToRasterMapDefinitions,
    )..where((t) => t.rasterMapUuid.equalsValue(mapId))).go();
    await (db.delete(
      db.rasterMaps,
    )..where((t) => t.uuid.equalsValue(mapId))).go();

    await sync();

    expect(await readBack(mapId), isNull);
    final revisions = await localState.readRevisions(profileUuid);
    expect(revisions[mapId], isNull);
    expect(revisions[pinId], isNull);
  });
}
