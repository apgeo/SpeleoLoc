import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_review.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/services/silexgis/silexgis_decisions_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_paged_stream_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_upload_answers.dart';
import 'package:speleoloc/services/silexgis/silexgis_staged_upload_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_recordings_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_upload_answers.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

import 'decisions_fixture.dart';
import 'scripted_client.dart';
import 'token_source.dart';

/// One page for everything an installation did not write and only the caver
/// can settle, whatever section it went in: what each item is called, which
/// choices apply to it, and that nothing is sent again into the same answer
/// while the caver has not chosen.
void main() {
  const setId = 'set-1';
  const profile = SilexgisProfile(
    profileUuid: 'p-1',
    displayName: 'Clubul Speo Example',
    baseUrl: 'https://club.example.org',
    syncSetId: setId,
  );
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['upload', 'trips'],
  );
  const revision = '2026-10-27T10:00:00Z';
  final uploadPath = SilexgisContract.uploadPath(setId);
  final clock = FakeClock(DateTime.utc(2026, 10, 28, 8));

  late AppDatabase db;
  late SilexgisLocalStateRepository localState;
  late SilexgisHeldRowRepository heldRows;
  late SilexgisTripStateRepository trips;
  late SilexgisDecisionsService decisions;

  final caveId = Uuid.v7();
  final placeId = Uuid.v7();

  setUp(() async {
    clock.set(DateTime.utc(2026, 10, 28, 8));
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final users = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      users,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    final logger = loggerRef = ChangeLogger(db, currentUser, clock: clock);
    localState = SilexgisLocalStateRepository(db, clock: clock);
    heldRows = SilexgisHeldRowRepository(db, clock: clock);
    trips = SilexgisTripStateRepository(db);
    decisions = buildDecisionsService(
      db: db,
      logger: logger,
      currentUser: currentUser,
      localState: localState,
      heldRows: heldRows,
      clock: clock,
    );

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
        profile.profileUuid,
        id,
        entityTable: table,
        revision: revision,
        localUpdatedAt: t0,
      );
    }
    // Nothing above is the caver's: the log starts with what they do here.
    await db.delete(db.changeLog).go();
  });
  tearDown(() => db.close());

  // ---------------------------------------------------------------- fixtures

  Future<void> editRecording(Uuid id) async {
    clock.advance(const Duration(minutes: 5));
    await (db.update(db.caveTrips)..where((t) => t.uuid.equalsValue(id))).write(
      CaveTripsCompanion(updatedAt: Value(clock.nowMs())),
    );
  }

  /// A recording the installation holds, edited here since.
  Future<Uuid> editedRecording() async {
    final id = Uuid.v7();
    final t0 = clock.nowMs();
    await db
        .into(db.caveTrips)
        .insert(
          CaveTripsCompanion.insert(
            uuid: id,
            caveUuid: caveId,
            title: 'Invented trip',
            tripStartedAt: t0,
          ).copyWith(updatedAt: Value(t0)),
        );
    await localState.writeRevision(
      profile.profileUuid,
      id,
      entityTable: SilexgisTripTables.recordings,
      revision: revision,
      localUpdatedAt: t0,
    );
    await editRecording(id);
    return id;
  }

  Future<int?> recordingStamp(Uuid id) async => (await (db.select(
    db.caveTrips,
  )..where((t) => t.uuid.equalsValue(id))).getSingle()).updatedAt;

  ScriptedResponse recordingAnswer(Uuid id, String status, {String? code}) =>
      ScriptedResponse.json(
        path: uploadPath,
        json: <String, Object?>{
          'batchId': 'b',
          'importBatchId': 'i',
          'replayed': false,
          'written': 0,
          'refused': 1,
          'rows': const <Object?>[],
          'conflicts': const <Object?>[],
          'duplicates': const <Object?>[],
          'tripRecordings': <Object?>[
            <String, Object?>{
              'id': id.toString(),
              'status': status,
              'revision': status == 'conflict' ? null : revision,
              'code': code,
              'detail': null,
            },
          ],
        },
      );

  Future<ScriptedClient> upload(List<ScriptedResponse> script) async {
    final client = ScriptedClient(script);
    await SilexgisUploadRunner(
      api: SilexgisSyncApi(
        SilexgisHttp(
          baseUri: profile.baseUri,
          tokens: FixedTokenSource(),
          client: client,
        ),
      ),
      builder: SilexgisUploadBuilder(
        db: db,
        localState: localState,
        heldRows: heldRows,
        profileUuid: profile.profileUuid,
      ),
      localState: localState,
      heldRows: heldRows,
      profileUuid: profile.profileUuid,
      parts: [
        SilexgisTripRecordingsUploadPart(
          db: db,
          localState: localState,
          heldRows: heldRows,
          answers: SilexgisTripUploadAnswers(
            localState: localState,
            heldRows: heldRows,
            trips: trips,
            profileUuid: profile.profileUuid,
          ),
          profileUuid: profile.profileUuid,
        ),
      ],
    ).run(setId, capabilities: capabilities);
    return client;
  }

  Future<String?> streamCursor(SyncStream stream) async =>
      (await localState.readStreamCursor(
        profile.profileUuid,
        setId,
        stream,
      )).cursor;

  Future<void> placeCursor(SyncStream stream) => localState.writeStreamCursor(
    profile.profileUuid,
    setId,
    stream,
    cursor: '${stream.routeName}-c9',
    setRevision: 1,
  );

  /// Records [entityUuid] as held under [reviewId] and turned down.
  Future<void> turnedDown(
    SyncUploadSection section,
    Uuid entityUuid,
    String table, {
    int? sentAt,
  }) async {
    final reviewId = 'review-${entityUuid.toString().substring(0, 8)}';
    await heldRows.recordHeld(profile.profileUuid, <SilexgisHeldEntry>[
      SilexgisHeldEntry(
        section: section,
        entityUuid: entityUuid,
        entityTable: table,
        reviewId: reviewId,
        sentLocalUpdatedAt: sentAt,
      ),
    ]);
    await heldRows.recordDecision(
      profile.profileUuid,
      reviewId: reviewId,
      outcome: SyncReviewOutcome.rejected,
    );
  }

  Future<SilexgisDecision> single() async =>
      (await decisions.decisions(profile.profileUuid)).single;

  // ------------------------------------------------------------------- tests

  group('a recording that met a later version', () {
    test('is not sent into the same conflict again, run after run', () async {
      final trip = await editedRecording();
      final first = await upload(<ScriptedResponse>[
        recordingAnswer(trip, 'conflict', code: 'sync.conflict'),
      ]);
      expect(first.sent, hasLength(1));

      // Before the change, every run sent it and met the same conflict.
      final second = await upload(const <ScriptedResponse>[]);
      expect(second.sent, isEmpty);

      final decision = await single();
      expect(decision.section, SyncUploadSection.tripRecordings);
      expect(decision.title, 'Invented trip');
      expect(decision.isConflict, isTrue);
      expect(decision.isNew, isFalse);
      expect(decision.hasServerRow, isFalse);
      expect(decision.canUseServerVersion, isTrue);
      expect(decision.canDelete, isFalse);
      expect(decision.canRemovePin, isFalse);
      // Counted for the run report, and not as waiting for a reviewer.
      final counts = await heldRows.counts(profile.profileUuid);
      expect(counts.toDecide, 1);
      expect(counts.waiting, 0);
    });

    test('kept, it stays unsent until the caver edits it again', () async {
      final trip = await editedRecording();
      await upload(<ScriptedResponse>[
        recordingAnswer(trip, 'conflict', code: 'sync.conflict'),
      ]);

      await decisions.keepMine(profile.profileUuid, await single());

      expect(await decisions.decisions(profile.profileUuid), isEmpty);
      expect((await upload(const <ScriptedResponse>[])).sent, isEmpty);

      await editRecording(trip);
      final again = await upload(<ScriptedResponse>[
        recordingAnswer(trip, 'updated'),
      ]);
      expect(again.sent, hasLength(1));
      expect(
        (await heldRows.readAll(
          profile.profileUuid,
        )).where((h) => h.entityUuid == trip),
        isEmpty,
      );
    });

    test('re-read from the server, the trips stream starts over and the '
        'recording is no longer held back', () async {
      final trip = await editedRecording();
      await upload(<ScriptedResponse>[
        recordingAnswer(trip, 'conflict', code: 'sync.conflict'),
      ]);
      await placeCursor(SyncStream.trips);

      expect(
        await decisions.useServerVersion(profile, await single()),
        isFalse,
      );

      expect(await streamCursor(SyncStream.trips), isNull);
      expect(await heldRows.readAll(profile.profileUuid), isEmpty);
      final stored = (await localState.readRevisions(
        profile.profileUuid,
      ))[trip]!;
      expect(stored.revision, revision);
      expect(stored.agreesWith(await recordingStamp(trip)), isTrue);
      // The caver's version is given up, so nothing goes.
      expect((await upload(const <ScriptedResponse>[])).sent, isEmpty);
    });
  });

  group('a pin whose place another pin marks', () {
    late Uuid mapId;
    late Uuid pinId;

    setUp(() async {
      mapId = Uuid.v7();
      pinId = Uuid.v7();
      final now = clock.nowMs();
      await db
          .into(db.rasterMaps)
          .insert(
            RasterMapsCompanion.insert(
              uuid: mapId,
              title: 'Invented plan',
              mapType: 'plane view',
              fileName: 'cave_$caveId/raster_$mapId.jpg',
              caveUuid: caveId,
            ).copyWith(updatedAt: Value(now)),
          );
      await localState.writeRevision(
        profile.profileUuid,
        mapId,
        entityTable: SilexgisRasterTables.maps,
        revision: revision,
        localUpdatedAt: now,
      );
      await db
          .into(db.cavePlaceToRasterMapDefinitions)
          .insert(
            CavePlaceToRasterMapDefinitionsCompanion.insert(
              uuid: pinId,
              cavePlaceUuid: placeId,
              rasterMapUuid: mapId,
            ).copyWith(
              xCoordinate: const Value(120),
              yCoordinate: const Value(80),
              updatedAt: Value(now),
            ),
          );
      await placeCursor(SyncStream.rasters);
      await SilexgisRasterUploadAnswers(
        localState: localState,
        heldRows: heldRows,
        rasters: SilexgisRasterStateRepository(db),
        staged: SilexgisStagedUploadRepository(db),
        rastersCursor: SilexgisStreamCursorStore(
          localState: localState,
          profileUuid: profile.profileUuid,
          setId: setId,
          stream: SyncStream.rasters,
        ),
        profileUuid: profile.profileUuid,
      ).apply(
        SyncUploadSection.rasterPins,
        <String, SilexgisPlannedRasterItem>{
          pinId.toString(): SilexgisPlannedRasterItem(
            id: pinId,
            mapId: mapId,
            isPin: true,
            localUpdatedAt: now,
          ),
        },
        <SyncRowResult>[
          SyncRowResult.fromJson(<String, Object?>{
            'id': pinId.toString(),
            'status': 'rejected',
            'code': 'sync.pin_exists',
          }),
        ],
      );
      await placeCursor(SyncStream.rasters);
    });

    test(
      'offers to remove the caver\'s pin, not the server\'s version',
      () async {
        final decision = await single();
        expect(decision.title, 'Invented plan · Sump');
        expect(decision.isPinExists, isTrue);
        expect(decision.canRemovePin, isTrue);
        expect(decision.canDelete, isFalse);
        expect(decision.canUseServerVersion, isFalse);
      },
    );

    test('removing it is the caver\'s own deletion, and the map is read '
        'again so the server\'s pin can arrive', () async {
      await decisions.delete(profile, await single());

      expect(
        await db.select(db.cavePlaceToRasterMapDefinitions).get(),
        isEmpty,
      );
      final log = await db.select(db.changeLog).get();
      expect(log.single.entityTable, SilexgisRasterTables.pins);
      expect(log.single.entityUuid, pinId);
      expect(await streamCursor(SyncStream.rasters), isNull);
      expect(await heldRows.readAll(profile.profileUuid), isEmpty);
    });
  });

  group('a turned-down new item', () {
    test('a document link names its document and can be taken down', () async {
      final documentId = Uuid.v7();
      final linkId = Uuid.v7();
      final now = clock.nowMs();
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: documentId,
              title: 'Invented photo',
              fileName: 'documentation_files/invented.jpg',
              fileSize: 1,
              fileType: 'photo',
            ),
          );
      await db
          .into(db.documentationFilesToGeofeatures)
          .insert(
            DocumentationFilesToGeofeaturesCompanion.insert(
              uuid: linkId,
              geofeatureType: 'cave',
              documentationFileUuid: documentId,
              geofeatureUuid: Value(caveId),
              updatedAt: Value(now),
            ),
          );
      await turnedDown(
        SyncUploadSection.documentLinks,
        linkId,
        'documentation_files_to_geofeatures',
        sentAt: now,
      );

      final decision = await single();
      expect(decision.title, 'Invented photo');
      expect(decision.isNew, isTrue);
      expect(decision.canDelete, isTrue);
      expect(decision.canUseServerVersion, isFalse);

      await decisions.delete(profile, decision);

      expect(
        await db.select(db.documentationFilesToGeofeatures).get(),
        isEmpty,
      );
      expect(await db.select(db.documentationFiles).get(), hasLength(1));
      final log = await db.select(db.changeLog).get();
      expect(log.single.entityTable, 'documentation_files_to_geofeatures');
      expect(log.single.entityUuid, linkId);
    });

    test('a map goes with its pins, and their decisions with it', () async {
      final mapId = Uuid.v7();
      final pinId = Uuid.v7();
      await db
          .into(db.rasterMaps)
          .insert(
            RasterMapsCompanion.insert(
              uuid: mapId,
              title: 'Draft plan',
              mapType: 'plane view',
              fileName: 'cave_$caveId/raster_$mapId.jpg',
              caveUuid: caveId,
            ),
          );
      await db
          .into(db.cavePlaceToRasterMapDefinitions)
          .insert(
            CavePlaceToRasterMapDefinitionsCompanion.insert(
              uuid: pinId,
              cavePlaceUuid: placeId,
              rasterMapUuid: mapId,
            ),
          );
      await turnedDown(
        SyncUploadSection.rasterMaps,
        mapId,
        SilexgisRasterTables.maps,
      );
      await turnedDown(
        SyncUploadSection.rasterPins,
        pinId,
        SilexgisRasterTables.pins,
      );

      final listed = await decisions.decisions(profile.profileUuid);
      expect(listed.map((d) => d.title), <String>[
        'Draft plan',
        'Draft plan · Sump',
      ]);
      await decisions.delete(
        profile,
        listed.firstWhere((d) => d.section == SyncUploadSection.rasterMaps),
      );

      expect(await db.select(db.rasterMaps).get(), isEmpty);
      expect(
        await db.select(db.cavePlaceToRasterMapDefinitions).get(),
        isEmpty,
      );
      expect(await decisions.decisions(profile.profileUuid), isEmpty);
      expect(await heldRows.readAll(profile.profileUuid), isEmpty);
    });

    test('a scan is named after its recording and its place, and goes as '
        'the caver would remove it', () async {
      final trip = Uuid.v7();
      final point = Uuid.v7();
      final now = clock.nowMs();
      await db
          .into(db.caveTrips)
          .insert(
            CaveTripsCompanion.insert(
              uuid: trip,
              caveUuid: caveId,
              title: 'Invented trip',
              tripStartedAt: now,
            ),
          );
      await db
          .into(db.caveTripPoints)
          .insert(
            CaveTripPointsCompanion.insert(
              uuid: point,
              caveTripUuid: trip,
              scannedAt: now,
            ).copyWith(cavePlaceUuid: Value(placeId)),
          );
      await turnedDown(
        SyncUploadSection.tripPoints,
        point,
        SilexgisTripTables.scans,
      );

      final decision = await single();
      expect(decision.title, 'Invented trip · Sump');
      expect(decision.canDelete, isTrue);

      await decisions.delete(profile, decision);

      expect(await db.select(db.caveTripPoints).get(), isEmpty);
      expect(await db.select(db.caveTrips).get(), hasLength(1));
      expect(
        (await db.select(db.changeLog).get()).map((l) => l.entityTable),
        contains(SilexgisTripTables.scans),
      );
    });
  });

  test('a document that met a later version is read again from the '
      'catalogue, and is no longer held back', () async {
    final documentId = Uuid.v7();
    final t0 = clock.nowMs();
    await db
        .into(db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: documentId,
            title: 'Edited here',
            fileName: 'documentation_files/invented.jpg',
            fileSize: 1,
            fileType: 'photo',
          ).copyWith(updatedAt: Value(t0 + 1)),
        );
    await localState.writeRevision(
      profile.profileUuid,
      documentId,
      entityTable: 'documentation_files',
      wireKind: 'document',
      revision: revision,
      localUpdatedAt: t0,
    );
    await heldRows.recordConflicts(profile.profileUuid, <SilexgisConflictEntry>[
      SilexgisConflictEntry(
        section: SyncUploadSection.documents,
        entityUuid: documentId,
        entityTable: 'documentation_files',
        wireKind: 'document',
        code: 'sync.conflict',
        sentLocalUpdatedAt: t0 + 1,
      ),
    ]);
    await placeCursor(SyncStream.documents);

    final decision = await single();
    expect(decision.title, 'Edited here');
    expect(decision.canUseServerVersion, isTrue);
    expect(await decisions.useServerVersion(profile, decision), isFalse);

    expect(await streamCursor(SyncStream.documents), isNull);
    final stored = (await localState.readRevisions(
      profile.profileUuid,
    ))[documentId]!;
    expect(stored.agreesWith(t0 + 1), isTrue);
    expect(await heldRows.readAll(profile.profileUuid), isEmpty);
  });
}
