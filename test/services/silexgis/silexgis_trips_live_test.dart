import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/model/sync_set.dart';
import 'package:speleoloc/services/silexgis/model/sync_trips.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_controller.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';
import 'package:speleoloc/services/user_repository.dart';

import 'live_server.dart';

/// Trip recordings both ways, against a real installation.
///
/// Off by default, like every live test. To run it:
///
/// 1. From a SilexGIS checkout: `node deploy/speleoloc-dev.mjs up`.
/// 2. `SPELEO_LOC_SILEXGIS_LIVE=1 flutter test test/services/silexgis/silexgis_trips_live_test.dart`
///
/// `SPELEO_LOC_SILEXGIS_URL` overrides the base address. The member reads the
/// seeded `Demo trip recording` — another phone's, visible to the caving
/// group — and then sends an invented recording of its own with one scan of
/// `Demo marker A`, reads it back from the stream, and takes it down again.
void main() {
  final env = Platform.environment;
  if (env['SPELEO_LOC_SILEXGIS_LIVE'] != '1') {
    test(
      'SilexGIS trips live test skipped (set SPELEO_LOC_SILEXGIS_LIVE=1)',
      () {},
    );
    return;
  }

  final baseUri = Uri.parse(
    env['SPELEO_LOC_SILEXGIS_URL'] ?? 'http://127.0.0.1:5205',
  );
  const email = 'member@dev.local';
  const password = 'dev-member-pass-1';
  const profileUuid = 'trips-live';

  late SilexgisAuthService auth;
  late SilexgisSyncApi api;
  late SyncSet set;

  late Directory files;
  late AppDatabase db;
  late SilexgisSyncController controller;
  late SilexgisLocalStateRepository localState;
  late SilexgisTripStateRepository trips;

  final authorId = Uuid.v7();
  final recordingId = Uuid.v7();
  final scanId = Uuid.v7();
  late Uuid caveId;
  late Uuid markerId;

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
    caveId = Uuid.parse(roots.single);
    set = await api.createSet(
      SyncSetWrite(
        name: 'trips live ${DateTime.now().millisecondsSinceEpoch}',
        cavingGroupId: await demoCavingGroupId(baseUri, token),
        uploadVisibility: SyncVisibility.cavingGroup,
        rootFeatureIds: roots,
        settings: const <String, Object?>{'pciStrategy': 'ro-default'},
      ),
    );

    // Where the run stores what it fetches, such as the demo plan's picture.
    files = await Directory.systemTemp.createTemp('silexgis_trips_live_');
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
    trips = SilexgisTripStateRepository(db);

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
      trips: trips,
      documentsDir: () async => files,
    );
    // An invented phone user, the author of the recording sent below.
    await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            uuid: authorId,
            username: 'live-trips-${authorId.toString().substring(0, 8)}',
          ),
        );
  });

  tearDownAll(() async {
    await api.deleteSet(set.id);
    auth.close();
    await db.close();
    await files.delete(recursive: true);
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

  /// The recording [id] as the trips stream hands it now, read from the
  /// beginning.
  Future<SyncTripRecording?> readBack(Uuid id) async {
    String? cursor;
    var more = true;
    while (more) {
      final page = await api.trips(set.id, cursor: cursor);
      for (final recording in page.recordings) {
        if (recording.id == id.toString()) return recording;
      }
      cursor = page.nextCursor;
      more = page.hasMore;
    }
    return null;
  }

  test('the installation serves trips', () async {
    final capabilities = await api.capabilities();
    expect(capabilities.servesTrips, isTrue);
  });

  test('the member reads the demo recording with its one scan', () async {
    await sync();

    final marker = await (db.select(
      db.cavePlaces,
    )..where((t) => t.title.equals('Demo marker A'))).getSingle();
    markerId = marker.uuid;

    final recording = await (db.select(
      db.caveTrips,
    )..where((t) => t.title.equals('Demo trip recording'))).getSingle();
    expect(recording.caveUuid, caveId);
    final scans = await db.getTripPoints(recording.uuid);
    expect(scans, hasLength(1));
    expect(scans.single.cavePlaceUuid, markerId);

    // Another phone's: marked as the installation's, and kept out of the
    // trips list until the caver asks for it.
    final state = (await trips.readAll(profileUuid))[recording.uuid]!;
    expect(state.received, isTrue);
    expect(state.sent, isFalse);
    expect((await trips.receivedRecordings(profileUuid)).keys, <Uuid>[
      recording.uuid,
    ]);
    // Nobody on this device is its author.
    expect(recording.createdByUserUuid, isNull);
    expect(await db.select(db.changeLog).get(), isEmpty);
  });

  test('a recording of its own with one scan goes up and reads back', () async {
    final start = DateTime.now().toUtc().subtract(const Duration(hours: 3));
    final now = DateTime.now().millisecondsSinceEpoch;
    final tag = recordingId.toString().substring(0, 8);
    await db
        .into(db.caveTrips)
        .insert(
          CaveTripsCompanion.insert(
            uuid: recordingId,
            caveUuid: caveId,
            title: 'Live trip $tag',
            tripStartedAt: start.millisecondsSinceEpoch,
          ).copyWith(
            tripEndedAt: Value(now),
            log: const Value('Invented by the live test'),
            participants: const Value('Nobody real'),
            createdByUserUuid: Value(authorId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await db
        .into(db.caveTripPoints)
        .insert(
          CaveTripPointsCompanion.insert(
            uuid: scanId,
            caveTripUuid: recordingId,
            scannedAt: start
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch,
          ).copyWith(
            cavePlaceUuid: Value(markerId),
            notes: const Value('Invented scan'),
            createdByUserUuid: Value(authorId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    await sync();

    final revisions = await localState.readRevisions(profileUuid);
    expect(revisions[recordingId]?.entityTable, 'cave_trips');
    expect(revisions[scanId]?.entityTable, 'cave_trip_points');
    final states = await trips.readAll(profileUuid);
    expect(states[recordingId]!.sent, isTrue);
    expect(states[recordingId]!.received, isFalse);

    final server = await readBack(recordingId);
    expect(server, isNotNull);
    expect(server!.title, 'Live trip $tag');
    expect(server.caveId, caveId.toString());
    expect(server.endedAt, isNotNull);
    expect(server.createdByDeviceUserId, authorId.toString());
    expect(server.points.single.id, scanId.toString());
    expect(server.points.single.placeId, markerId.toString());
    expect(server.points.single.notes, 'Invented scan');

    // The run read it back too, and found nothing to change here.
    final local = await (db.select(
      db.caveTrips,
    )..where((t) => t.uuid.equalsValue(recordingId))).getSingle();
    expect(local.participants, 'Nobody real');
    expect(local.createdByUserUuid, authorId);
  });

  test('removing it here takes it down there', () async {
    await db.deleteCaveTrip(recordingId);
    await sync();

    expect(await readBack(recordingId), isNull);
    final revisions = await localState.readRevisions(profileUuid);
    expect(revisions[recordingId], isNull);
    expect(revisions[scanId], isNull);
  });
}
