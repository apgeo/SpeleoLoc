import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_review.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_decisions_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_upload_answers.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

import 'decisions_fixture.dart';

/// One upload section, as far as putting the server's row of an item back in
/// place of the caver's goes.
class _Section {
  const _Section({
    required this.name,
    required this.section,
    required this.table,
    required this.stream,
    required this.make,
    required this.current,
    required this.read,
    required this.localValue,
    required this.serverValue,
    this.hasRevision = true,
  });

  final String name;
  final SyncUploadSection section;
  final String table;

  /// Null for the feature download.
  final SyncStream? stream;

  /// Makes the item as the caver edited it here; returns its id and stamp.
  final Future<(Uuid, int)> Function() make;

  /// The server's row of the item, shaped as [stream] delivers it.
  final Map<String, Object?> Function(Uuid id) current;

  /// What the item says here, in the one field the two versions differ in.
  final Future<Object?> Function(Uuid id) read;
  final Object? localValue;
  final Object? serverValue;

  /// A link has no revision of its own on this device.
  final bool hasRevision;
}

/// The server's row handed over with a decision, for every section that has
/// one: written in place of the caver's through the applier its stream uses,
/// and when it is not handed over, that stream alone read again.
void main() {
  const setId = 'set-1';
  const profile = SilexgisProfile(
    profileUuid: 'p-1',
    displayName: 'Clubul Speo Example',
    baseUrl: 'https://club.example.org',
    syncSetId: setId,
  );
  const agreedRevision = '2026-10-27T10:00:00.000Z';
  const serverRevision = '2026-10-28T09:00:00.000Z';
  final clock = FakeClock(DateTime.utc(2026, 10, 28, 8));

  late AppDatabase db;
  late ChangeLogger logger;
  late SilexgisLocalStateRepository localState;
  late SilexgisHeldRowRepository heldRows;
  late SilexgisDocumentCatalogueRepository catalogue;
  late SilexgisTripStateRepository trips;
  late SilexgisDecisionsService decisions;

  final caveId = Uuid.v7();
  final placeId = Uuid.v7();
  late Uuid documentId;

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
    logger = loggerRef = ChangeLogger(db, currentUser, clock: clock);
    localState = SilexgisLocalStateRepository(db, clock: clock);
    heldRows = SilexgisHeldRowRepository(db, clock: clock);
    catalogue = SilexgisDocumentCatalogueRepository(db);
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
        revision: agreedRevision,
        localUpdatedAt: t0,
      );
    }
    // Every stream has read part of the set.
    await localState.writeSetState(
      profile.profileUuid,
      setId,
      cursor: 'features-c9',
      setRevision: 1,
    );
    for (final stream in <SyncStream>[
      SyncStream.documents,
      SyncStream.trips,
      SyncStream.rasters,
    ]) {
      await localState.writeStreamCursor(
        profile.profileUuid,
        setId,
        stream,
        cursor: '${stream.routeName}-c9',
        setRevision: 1,
      );
    }
  });
  tearDown(() => db.close());

  // ---------------------------------------------------------------- fixtures

  /// Agrees on [id] at [agreedAt], then has the caver edit it: returns the
  /// stamp of the edit.
  Future<int> agreeThenEdit(Uuid id, String table, int agreedAt) async {
    await localState.writeRevision(
      profile.profileUuid,
      id,
      entityTable: table,
      revision: agreedRevision,
      localUpdatedAt: agreedAt,
    );
    clock.advance(const Duration(minutes: 5));
    return clock.nowMs();
  }

  Map<String, Object?> catalogueDocument(String title) => <String, Object?>{
    'id': documentId.toString(),
    'title': title,
    'fileKind': 'photo',
    'reach': 'original',
    'updatedAt': serverRevision,
  };

  Future<void> insertDocument() async {
    documentId = Uuid.v7();
    await db
        .into(db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: documentId,
            title: 'Edited here',
            fileName: 'documentation_files/invented.jpg',
            fileSize: 1,
            fileType: 'photo',
          ).copyWith(updatedAt: Value(clock.nowMs())),
        );
  }

  Future<Uuid> insertRecording({String title = 'Invented trip'}) async {
    final id = Uuid.v7();
    final t0 = clock.nowMs();
    await db
        .into(db.caveTrips)
        .insert(
          CaveTripsCompanion.insert(
            uuid: id,
            caveUuid: caveId,
            title: title,
            tripStartedAt: t0,
          ).copyWith(updatedAt: Value(t0)),
        );
    await localState.writeRevision(
      profile.profileUuid,
      id,
      entityTable: SilexgisTripTables.recordings,
      revision: agreedRevision,
      localUpdatedAt: t0,
    );
    return id;
  }

  Future<Uuid> insertMap({String title = 'Invented plan'}) async {
    final id = Uuid.v7();
    final t0 = clock.nowMs();
    await db
        .into(db.rasterMaps)
        .insert(
          RasterMapsCompanion.insert(
            uuid: id,
            title: title,
            mapType: 'plane view',
            fileName: 'cave_$caveId/raster_$id.jpg',
            caveUuid: caveId,
          ).copyWith(updatedAt: Value(t0)),
        );
    await localState.writeRevision(
      profile.profileUuid,
      id,
      entityTable: SilexgisRasterTables.maps,
      revision: agreedRevision,
      localUpdatedAt: t0,
    );
    return id;
  }

  late Uuid pinMap;

  final sections = <_Section>[
    _Section(
      name: 'an entrance',
      section: SyncUploadSection.rows,
      table: 'cave_places',
      stream: null,
      make: () async {
        final id = Uuid.v7();
        final edited = await agreeThenEdit(id, 'cave_places', clock.nowMs());
        await db
            .into(db.cavePlaces)
            .insert(
              CavePlace(
                uuid: id,
                title: 'Edited here',
                caveUuid: caveId,
                isEntrance: 1,
                isMainEntrance: 0,
                updatedAt: edited,
              ),
            );
        return (id, edited);
      },
      current: (id) => <String, Object?>{
        'id': id.toString(),
        'kind': 'caveEntrance',
        'name': 'Server place',
        'updatedAt': serverRevision,
        'properties': const <String, Object?>{},
        'parents': <Object?>[
          <String, Object?>{'parentId': caveId.toString(), 'isPrimary': true},
        ],
      },
      read: (id) async => (await (db.select(
        db.cavePlaces,
      )..where((t) => t.uuid.equalsValue(id))).getSingle()).title,
      localValue: 'Edited here',
      serverValue: 'Server place',
    ),
    _Section(
      name: 'a document',
      section: SyncUploadSection.documents,
      table: 'documentation_files',
      stream: SyncStream.documents,
      make: () async {
        final t0 = clock.nowMs();
        await insertDocument();
        final edited = await agreeThenEdit(
          documentId,
          'documentation_files',
          t0,
        );
        await (db.update(db.documentationFiles)
              ..where((t) => t.uuid.equalsValue(documentId)))
            .write(DocumentationFilesCompanion(updatedAt: Value(edited)));
        return (documentId, edited);
      },
      current: (id) => catalogueDocument('Server title'),
      read: (id) async => (await (db.select(
        db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(id))).getSingle()).title,
      localValue: 'Edited here',
      serverValue: 'Server title',
    ),
    _Section(
      name: 'a document link',
      section: SyncUploadSection.documentLinks,
      table: 'documentation_files_to_geofeatures',
      stream: SyncStream.documents,
      hasRevision: false,
      make: () async {
        await insertDocument();
        final id = Uuid.v7();
        final now = clock.nowMs();
        await db
            .into(db.documentationFilesToGeofeatures)
            .insert(
              DocumentationFilesToGeofeaturesCompanion.insert(
                uuid: id,
                geofeatureType: 'cave',
                documentationFileUuid: documentId,
                geofeatureUuid: Value(caveId),
                updatedAt: Value(now),
              ),
            );
        return (id, now);
      },
      current: (id) => <String, Object?>{
        'id': 'server-link-1',
        'documentId': documentId.toString(),
        'target': <String, Object?>{'kind': 'feature', 'id': caveId.toString()},
        'sortOrder': 0,
        'isPrimary': true,
        'inDefaultSet': false,
        'revision': serverRevision,
        'document': catalogueDocument('Invented photo'),
      },
      read: (id) async => (await catalogue.linksOf(
        profile.profileUuid,
        documentId,
      )).map((l) => l.linkId).firstOrNull,
      localValue: null,
      serverValue: 'server-link-1',
    ),
    _Section(
      name: 'a recording',
      section: SyncUploadSection.tripRecordings,
      table: SilexgisTripTables.recordings,
      stream: SyncStream.trips,
      make: () async {
        final id = await insertRecording(title: 'Edited here');
        clock.advance(const Duration(minutes: 5));
        final edited = clock.nowMs();
        await (db.update(db.caveTrips)..where((t) => t.uuid.equalsValue(id)))
            .write(CaveTripsCompanion(updatedAt: Value(edited)));
        return (id, edited);
      },
      current: (id) => <String, Object?>{
        'id': id.toString(),
        'caveId': caveId.toString(),
        'title': 'Server trip',
        'startedAt': '2026-10-27T08:00:00.000Z',
        'revision': serverRevision,
        'points': const <Object?>[],
      },
      read: (id) async => (await (db.select(
        db.caveTrips,
      )..where((t) => t.uuid.equalsValue(id))).getSingle()).title,
      localValue: 'Edited here',
      serverValue: 'Server trip',
    ),
    _Section(
      name: 'a scan',
      section: SyncUploadSection.tripPoints,
      table: SilexgisTripTables.scans,
      stream: SyncStream.trips,
      make: () async {
        final recording = await insertRecording();
        final id = Uuid.v7();
        final edited = await agreeThenEdit(
          id,
          SilexgisTripTables.scans,
          clock.nowMs(),
        );
        await db
            .into(db.caveTripPoints)
            .insert(
              CaveTripPointsCompanion.insert(
                uuid: id,
                caveTripUuid: recording,
                scannedAt: edited,
              ).copyWith(
                cavePlaceUuid: Value(placeId),
                notes: const Value('Edited here'),
                updatedAt: Value(edited),
              ),
            );
        return (id, edited);
      },
      current: (id) => <String, Object?>{
        'id': id.toString(),
        'placeId': placeId.toString(),
        'scannedAt': '2026-10-27T08:30:00.000Z',
        'notes': 'Server notes',
        'revision': serverRevision,
      },
      read: (id) async => (await (db.select(
        db.caveTripPoints,
      )..where((t) => t.uuid.equalsValue(id))).getSingle()).notes,
      localValue: 'Edited here',
      serverValue: 'Server notes',
    ),
    _Section(
      name: 'a raster map',
      section: SyncUploadSection.rasterMaps,
      table: SilexgisRasterTables.maps,
      stream: SyncStream.rasters,
      make: () async {
        final id = await insertMap(title: 'Edited here');
        clock.advance(const Duration(minutes: 5));
        final edited = clock.nowMs();
        await (db.update(db.rasterMaps)..where((t) => t.uuid.equalsValue(id)))
            .write(RasterMapsCompanion(updatedAt: Value(edited)));
        return (id, edited);
      },
      current: (id) => <String, Object?>{
        'id': id.toString(),
        'caveId': caveId.toString(),
        'title': 'Server plan',
        'mapType': 'planView',
        'sortOrder': 0,
        'revision': serverRevision,
        'pins': const <Object?>[],
      },
      read: (id) async => (await (db.select(
        db.rasterMaps,
      )..where((t) => t.uuid.equalsValue(id))).getSingle()).title,
      localValue: 'Edited here',
      serverValue: 'Server plan',
    ),
    _Section(
      name: 'a pin',
      section: SyncUploadSection.rasterPins,
      table: SilexgisRasterTables.pins,
      stream: SyncStream.rasters,
      make: () async {
        pinMap = await insertMap();
        final id = Uuid.v7();
        final edited = await agreeThenEdit(
          id,
          SilexgisRasterTables.pins,
          clock.nowMs(),
        );
        await db
            .into(db.cavePlaceToRasterMapDefinitions)
            .insert(
              CavePlaceToRasterMapDefinitionsCompanion.insert(
                uuid: id,
                cavePlaceUuid: placeId,
                rasterMapUuid: pinMap,
              ).copyWith(
                xCoordinate: const Value(10),
                yCoordinate: const Value(80),
                updatedAt: Value(edited),
              ),
            );
        return (id, edited);
      },
      current: (id) => <String, Object?>{
        'id': id.toString(),
        'placeId': placeId.toString(),
        'x': 99,
        'y': 80,
        'revision': serverRevision,
      },
      read: (id) async => (await (db.select(
        db.cavePlaceToRasterMapDefinitions,
      )..where((t) => t.uuid.equalsValue(id))).getSingle()).xCoordinate,
      localValue: 10,
      serverValue: 99,
    ),
  ];

  /// Every stream's position, the feature download's under null.
  Future<Map<SyncStream?, String?>> positions() async => <SyncStream?, String?>{
    null: (await localState.readSetState(profile.profileUuid, setId)).cursor,
    for (final stream in <SyncStream>[
      SyncStream.documents,
      SyncStream.trips,
      SyncStream.rasters,
    ])
      stream: (await localState.readStreamCursor(
        profile.profileUuid,
        setId,
        stream,
      )).cursor,
  };

  /// Every stream's position as placed, but [stream]'s dropped.
  Map<SyncStream?, String?> allBut(SyncStream? stream, {bool drop = true}) =>
      <SyncStream?, String?>{
        null: drop && stream == null ? null : 'features-c9',
        for (final s in <SyncStream>[
          SyncStream.documents,
          SyncStream.trips,
          SyncStream.rasters,
        ])
          s: drop && s == stream ? null : '${s.routeName}-c9',
      };

  /// Holds [id] for a reviewer under a review named after it.
  Future<String> hold(_Section s, Uuid id, int sentAt) async {
    final reviewId = 'review-${id.toString().substring(0, 8)}';
    await heldRows.recordHeld(profile.profileUuid, <SilexgisHeldEntry>[
      SilexgisHeldEntry(
        section: s.section,
        entityUuid: id,
        entityTable: s.table,
        reviewId: reviewId,
        sentLocalUpdatedAt: sentAt,
      ),
    ]);
    return reviewId;
  }

  // ------------------------------------------------------------------- tests

  for (final s in sections) {
    group('${s.name} turned down, the server\'s version', () {
      test('is written now when the decision hands it over', () async {
        final (id, sentAt) = await s.make();
        final reviewId = await hold(s, id, sentAt);
        await heldRows.recordDecision(
          profile.profileUuid,
          reviewId: reviewId,
          outcome: SyncReviewOutcome.rejected,
          current: s.current(id),
        );
        await db.delete(db.changeLog).go();

        final decision = (await decisions.decisions(
          profile.profileUuid,
        )).single;
        expect(decision.hasServerRow, isTrue);
        expect(decision.canUseServerVersion, isTrue);
        expect(await decisions.useServerVersion(profile, decision), isTrue);

        expect(await s.read(id), s.serverValue);
        expect(await heldRows.readAll(profile.profileUuid), isEmpty);
        if (s.hasRevision) {
          expect(
            await localState.readRevision(profile.profileUuid, id),
            serverRevision,
          );
        }
        // An import, not the caver's edit.
        expect(await db.select(db.changeLog).get(), isEmpty);
        // Nothing needs reading again.
        expect(await positions(), allBut(s.stream, drop: false));
      });

      test(
        'without it, that stream alone is read from the beginning',
        () async {
          final (id, sentAt) = await s.make();
          if (s.hasRevision) {
            final reviewId = await hold(s, id, sentAt);
            await heldRows.recordDecision(
              profile.profileUuid,
              reviewId: reviewId,
              outcome: SyncReviewOutcome.rejected,
            );
          } else {
            // A link with no server version to name is new to the
            // installation; one that met a later version is not.
            await heldRows
                .recordConflicts(profile.profileUuid, <SilexgisConflictEntry>[
                  SilexgisConflictEntry(
                    section: s.section,
                    entityUuid: id,
                    entityTable: s.table,
                    code: 'sync.conflict',
                    sentLocalUpdatedAt: sentAt,
                  ),
                ]);
          }

          final decision = (await decisions.decisions(
            profile.profileUuid,
          )).single;
          expect(decision.hasServerRow, isFalse);
          expect(await decisions.useServerVersion(profile, decision), isFalse);

          expect(await s.read(id), s.localValue);
          expect(await heldRows.readAll(profile.profileUuid), isEmpty);
          expect(await positions(), allBut(s.stream));
        },
      );
    });
  }

  test('a document\'s catalogue copy follows the server\'s too', () async {
    final s = sections.firstWhere(
      (s) => s.section == SyncUploadSection.documents,
    );
    final (id, sentAt) = await s.make();
    await catalogue.applyPage(
      profile.profileUuid,
      SyncDocumentsPage.fromJson(<String, Object?>{
        'links': <Object?>[
          <String, Object?>{
            'id': 'server-link-1',
            'documentId': documentId.toString(),
            'target': <String, Object?>{
              'kind': 'feature',
              'id': caveId.toString(),
            },
            'document': catalogueDocument('Before'),
          },
        ],
      }),
    );
    final reviewId = await hold(s, id, sentAt);
    await heldRows.recordDecision(
      profile.profileUuid,
      reviewId: reviewId,
      outcome: SyncReviewOutcome.rejected,
      current: s.current(id),
    );

    final decision = (await decisions.decisions(profile.profileUuid)).single;
    expect(await decisions.useServerVersion(profile, decision), isTrue);

    expect(
      (await catalogue.document(profile.profileUuid, documentId))?.title,
      'Server title',
    );
  });

  test('a scan the caver removed comes back under its recording', () async {
    final recording = await insertRecording();
    final id = Uuid.v7();
    await localState.writeRevision(
      profile.profileUuid,
      id,
      entityTable: SilexgisTripTables.scans,
      revision: agreedRevision,
    );
    await trips.recordDownloaded(
      profile.profileUuid,
      SilexgisTripState(
        entityUuid: id,
        recordingUuid: recording,
        isScan: true,
        received: true,
      ),
    );
    await heldRows.recordHeld(profile.profileUuid, <SilexgisHeldEntry>[
      SilexgisHeldEntry(
        section: SyncUploadSection.tripPoints,
        entityUuid: id,
        entityTable: SilexgisTripTables.scans,
        reviewId: 'review-1',
        isDelete: true,
      ),
    ]);
    await heldRows.recordDecision(
      profile.profileUuid,
      reviewId: 'review-1',
      outcome: SyncReviewOutcome.rejected,
      current: <String, Object?>{
        'id': id.toString(),
        'placeId': placeId.toString(),
        'scannedAt': '2026-10-27T08:30:00.000Z',
        'notes': 'Server notes',
        'revision': serverRevision,
      },
    );

    final decision = (await decisions.decisions(profile.profileUuid)).single;
    expect(await decisions.useServerVersion(profile, decision), isTrue);

    final scan = await (db.select(
      db.caveTripPoints,
    )..where((t) => t.uuid.equalsValue(id))).getSingle();
    expect(scan.caveTripUuid, recording);
    expect(scan.notes, 'Server notes');
  });

  test('a pin whose map is not here is read again with the rasters', () async {
    final id = Uuid.v7();
    await localState.writeRevision(
      profile.profileUuid,
      id,
      entityTable: SilexgisRasterTables.pins,
      revision: agreedRevision,
    );
    await heldRows.recordHeld(profile.profileUuid, <SilexgisHeldEntry>[
      SilexgisHeldEntry(
        section: SyncUploadSection.rasterPins,
        entityUuid: id,
        entityTable: SilexgisRasterTables.pins,
        reviewId: 'review-1',
        isDelete: true,
      ),
    ]);
    await heldRows.recordDecision(
      profile.profileUuid,
      reviewId: 'review-1',
      outcome: SyncReviewOutcome.rejected,
      current: <String, Object?>{
        'id': id.toString(),
        'placeId': placeId.toString(),
        'x': 1,
        'y': 2,
      },
    );

    final decision = (await decisions.decisions(profile.profileUuid)).single;
    expect(await decisions.useServerVersion(profile, decision), isFalse);

    expect(await positions(), allBut(SyncStream.rasters));
  });
}
