import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_trips.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_missing_item_rule.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trips_runner.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

import 'contract_fixtures.dart';
import 'scripted_client.dart';
import 'token_source.dart';

/// Trip recordings down: read under the installation's identifiers, held back
/// where the caver has an edit not yet sent, scans of places this device does
/// not hold skipped, and another phone's author kept out of the foreign key.
void main() {
  const profile = 'p-1';
  const setId = 'set-1';
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'trips'],
  );
  final clock = FakeClock(DateTime.utc(2026, 10, 28, 8));

  late AppDatabase db;
  late ChangeLogger logger;
  late SilexgisLocalStateRepository localState;
  late SilexgisHeldRowRepository heldRows;
  late SilexgisTripStateRepository trips;
  late SilexgisTripApplier applier;

  final caveId = Uuid.v7();
  final placeId = Uuid.v7();
  final localUser = Uuid.v7();
  const revision = '2026-10-27T12:00:00Z';

  setUp(() async {
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
    trips = SilexgisTripStateRepository(db);
    applier = SilexgisTripApplier(
      db: db,
      logger: logger,
      localState: localState,
      heldRows: heldRows,
      trips: trips,
      profileUuid: profile,
      clock: clock,
    );
    await db
        .into(db.users)
        .insert(UsersCompanion.insert(uuid: localUser, username: 'invented'));
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
  tearDown(() => db.close());

  /// Recording 24, its placeholders filled with identifiers this device can
  /// hold.
  SyncTripsPage recorded24({
    required Uuid recording,
    required Uuid scanAtPlace,
    required Uuid scanAtNoPlace,
    String author = '',
  }) => SyncTripsPage.fromJson(
    fillPlaceholders(
          ContractExchange('24-trips-first-page').responseBody,
          <String, String>{
            '<recording>': recording.toString(),
            '<cave>': caveId.toString(),
            '<place>': placeId.toString(),
            '<scan-at-place>': scanAtPlace.toString(),
            '<scan-at-no-place>': scanAtNoPlace.toString(),
            '<uuid-1>': author.isEmpty ? Uuid.v7().toString() : author,
            '<timestamp>': revision,
            '<cursor>': 'trips-c1',
          },
        )!
        as Map<String, Object?>,
  );

  SyncTripsPage page(
    List<Map<String, Object?>> recordings, {
    List<Map<String, Object?>> tombstones = const <Map<String, Object?>>[],
    List<Map<String, Object?>>? pointTombstones,
  }) => SyncTripsPage.fromJson(<String, Object?>{
    'setRevision': 1,
    'settings': const <String, Object?>{},
    'recordings': recordings,
    'tombstones': tombstones,
    // Left out unless given: a server that does not name removed scans.
    'pointTombstones': ?pointTombstones,
    'nextCursor': 'trips-c2',
    'hasMore': false,
  });

  Map<String, Object?> recordingJson(
    Uuid id, {
    String title = 'Trip',
    String? author,
    String rev = revision,
    List<Map<String, Object?>> points = const <Map<String, Object?>>[],
  }) => <String, Object?>{
    'id': id.toString(),
    'caveId': caveId.toString(),
    'title': title,
    'description': null,
    'log': 'from the server',
    'startedAt': '2026-10-27T08:00:00Z',
    'endedAt': '2026-10-27T12:00:00Z',
    'createdByDeviceUserId': author,
    'revision': rev,
    'points': points,
  };

  Map<String, Object?> pointJson(
    Uuid id, {
    Uuid? place,
    String scannedAt = '2026-10-27T09:00:00Z',
    String notes = 'from the server',
  }) => <String, Object?>{
    'id': id.toString(),
    'placeId': (place ?? placeId).toString(),
    'scannedAt': scannedAt,
    'notes': notes,
    'createdByDeviceUserId': null,
    'revision': revision,
  };

  Future<CaveTrip?> tripRow(Uuid id) => (db.select(
    db.caveTrips,
  )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();

  Future<List<CaveTripPoint>> scansOf(Uuid id) => db.getTripPoints(id);

  group('24-trips-first-page', () {
    test('another phone\'s recording lands under the server\'s ids', () async {
      final recording = Uuid.v7();
      final atPlace = Uuid.v7();
      final atNoPlace = Uuid.v7();
      final foreign = Uuid.v7().toString();

      final applied = await applier.applyPage(
        recorded24(
          recording: recording,
          scanAtPlace: atPlace,
          scanAtNoPlace: atNoPlace,
          author: foreign,
        ),
      );

      expect(applied.recordingsInserted, 1);
      expect(applied.scansInserted, 2);
      final trip = (await tripRow(recording))!;
      expect(trip.caveUuid, caveId);
      expect(trip.title, 'Trip');
      expect(trip.log, 'entered; turned back at the sump');
      expect(trip.tripEndedAt, isNotNull);
      // Never in the stream, so nothing is made up for them.
      expect(trip.participants, isNull);
      expect(trip.deviceUuid, isNull);
      // An author no user here is: the key stays null, the id is kept aside.
      expect(trip.createdByUserUuid, isNull);
      final state = (await trips.readAll(profile))[recording]!;
      expect(state.received, isTrue);
      expect(state.sent, isFalse);
      expect(state.authorDeviceUserId, foreign);

      final scans = await scansOf(recording);
      expect(scans.map((s) => s.uuid).toSet(), <Uuid>{atPlace, atNoPlace});
      expect(
        scans.singleWhere((s) => s.uuid == atPlace).cavePlaceUuid,
        placeId,
      );
      expect(
        scans.singleWhere((s) => s.uuid == atNoPlace).cavePlaceUuid,
        isNull,
      );

      final revisions = await localState.readRevisions(profile);
      expect(revisions[recording]!.entityTable, 'cave_trips');
      expect(revisions[atPlace]!.entityTable, 'cave_trip_points');
      // An import, not a caver's edit: nothing to carry to other devices.
      expect(await db.select(db.changeLog).get(), isEmpty);
    });

    test('a revision is kept verbatim and never read as a moment', () async {
      final asMoment = Uuid.v7();
      final opaque = Uuid.v7();
      final scan = Uuid.v7();
      await applier.applyPage(
        page(<Map<String, Object?>>[
          recordingJson(asMoment, title: 'A', rev: '2020-01-01T00:00:00Z'),
          recordingJson(
            opaque,
            title: 'B',
            rev: 'r7',
            points: <Map<String, Object?>>[pointJson(scan)],
          ),
        ]),
      );

      for (final id in <Uuid>[asMoment, opaque]) {
        final row = (await tripRow(id))!;
        expect(row.updatedAt, clock.nowMs());
        expect(row.createdAt, clock.nowMs());
      }
      expect((await scansOf(opaque)).single.updatedAt, clock.nowMs());
      final revisions = await localState.readRevisions(profile);
      expect(revisions[asMoment]!.revision, '2020-01-01T00:00:00Z');
      expect(revisions[opaque]!.revision, 'r7');
      expect(revisions[opaque]!.agreesWith(clock.nowMs()), isTrue);
    });

    test('an author this device has is the row\'s own', () async {
      final recording = Uuid.v7();
      await applier.applyPage(
        recorded24(
          recording: recording,
          scanAtPlace: Uuid.v7(),
          scanAtNoPlace: Uuid.v7(),
          author: localUser.toString(),
        ),
      );
      expect((await tripRow(recording))!.createdByUserUuid, localUser);
      expect(
        (await trips.readAll(profile))[recording]!.authorDeviceUserId,
        isNull,
      );
    });
  });

  test('a scan of a place this device does not hold is skipped', () async {
    final recording = Uuid.v7();
    final applied = await applier.applyPage(
      page(<Map<String, Object?>>[
        recordingJson(
          recording,
          points: <Map<String, Object?>>[
            pointJson(Uuid.v7()),
            pointJson(Uuid.v7(), place: Uuid.v7()),
          ],
        ),
      ]),
    );
    expect(applied.scansInserted, 1);
    expect(applied.scansWithoutPlace, 1);
    expect(await scansOf(recording), hasLength(1));
  });

  test('a recording in a cave this device does not hold is skipped', () async {
    final applied = await applier.applyPage(
      page(<Map<String, Object?>>[
        <String, Object?>{
          ...recordingJson(Uuid.v7()),
          'caveId': Uuid.v7().toString(),
        },
      ]),
    );
    expect(applied.withoutCave, 1);
    expect(await db.select(db.caveTrips).get(), isEmpty);
  });

  group('held back', () {
    test(
      'a recording with an edit not yet sent stays as the caver has it',
      () async {
        final recording = Uuid.v7();
        await applier.applyPage(
          page(<Map<String, Object?>>[recordingJson(recording)]),
        );
        await (db.update(
          db.caveTrips,
        )..where((t) => t.uuid.equalsValue(recording))).write(
          CaveTripsCompanion(
            log: const Value('mine'),
            // The caver's edit comes after the read.
            updatedAt: Value(clock.nowMs() + 1000),
          ),
        );

        final applied = await applier.applyPage(
          page(<Map<String, Object?>>[
            recordingJson(recording, rev: '2026-10-27T13:00:00Z'),
          ]),
        );
        expect(applied.heldBack, 1);
        expect((await tripRow(recording))!.log, 'mine');
      },
    );

    test(
      'a recording waiting for a reviewer stays as the caver has it',
      () async {
        final recording = Uuid.v7();
        await applier.applyPage(
          page(<Map<String, Object?>>[recordingJson(recording)]),
        );
        await heldRows.recordHeld(profile, <SilexgisHeldEntry>[
          SilexgisHeldEntry(
            section: SyncUploadSection.tripRecordings,
            entityUuid: recording,
            entityTable: 'cave_trips',
            reviewId: 'review-1',
            sentLocalUpdatedAt: (await tripRow(recording))!.updatedAt,
          ),
        ]);
        final applied = await applier.applyPage(
          page(<Map<String, Object?>>[
            recordingJson(recording, title: 'Renamed there'),
          ]),
        );
        expect(applied.heldBack, 1);
        expect((await tripRow(recording))!.title, 'Trip');
      },
    );

    test(
      'an edit read later keeps a known author and changes nothing else of it',
      () async {
        final recording = Uuid.v7();
        final foreign = Uuid.v7().toString();
        await applier.applyPage(
          page(<Map<String, Object?>>[
            recordingJson(recording, author: foreign),
          ]),
        );
        await applier.applyPage(
          page(<Map<String, Object?>>[
            recordingJson(
              recording,
              author: foreign,
              title: 'Renamed there',
              rev: '2026-10-27T14:00:00Z',
            ),
          ]),
        );
        final trip = (await tripRow(recording))!;
        expect(trip.title, 'Renamed there');
        expect(trip.createdByUserUuid, isNull);
        final state = (await trips.readAll(profile))[recording]!;
        expect(state.received, isTrue);
        expect(state.authorDeviceUserId, foreign);
      },
    );
  });

  group('a scan missing from a server that names no removed scans', () {
    Future<(Uuid, Uuid, Uuid)> twoScans() async {
      final recording = Uuid.v7();
      final kept = Uuid.v7();
      final other = Uuid.v7();
      await applier.applyPage(
        page(<Map<String, Object?>>[
          recordingJson(
            recording,
            points: <Map<String, Object?>>[
              pointJson(kept),
              pointJson(other, scannedAt: '2026-10-27T10:00:00Z'),
            ],
          ),
        ]),
      );
      return (recording, kept, other);
    }

    test(
      'is removed when it came from the installation and was never sent',
      () async {
        final (recording, kept, other) = await twoScans();
        final applied = await applier.applyPage(
          page(<Map<String, Object?>>[
            recordingJson(
              recording,
              points: <Map<String, Object?>>[pointJson(kept)],
            ),
          ]),
        );
        expect(applied.scansRemoved, 1);
        expect((await scansOf(recording)).map((s) => s.uuid), <Uuid>[kept]);
        expect((await localState.readRevisions(profile))[other], isNull);
        expect((await trips.readAll(profile))[other], isNull);
      },
    );

    test(
      'is kept when this device sent it — it may only be withheld',
      () async {
        final (recording, kept, other) = await twoScans();
        await trips.recordSent(profile, <SilexgisTripState>[
          SilexgisTripState(
            entityUuid: other,
            recordingUuid: recording,
            isScan: true,
          ),
        ]);
        final applied = await applier.applyPage(
          page(<Map<String, Object?>>[
            recordingJson(
              recording,
              points: <Map<String, Object?>>[pointJson(kept)],
            ),
          ]),
        );
        expect(applied.scansRemoved, 0);
        expect(await scansOf(recording), hasLength(2));
      },
    );

    test('is kept when this device made it and has not sent it yet', () async {
      final (recording, kept, _) = await twoScans();
      final mine = await db.insertTripPoint(
        tripUuid: recording,
        cavePlaceUuid: placeId,
        authorUuid: localUser,
        scannedAt: DateTime.utc(2026, 10, 27, 11).millisecondsSinceEpoch,
      );
      await applier.applyPage(
        page(<Map<String, Object?>>[
          recordingJson(
            recording,
            points: <Map<String, Object?>>[pointJson(kept)],
          ),
        ]),
      );
      expect((await scansOf(recording)).map((s) => s.uuid), contains(mine));
    });

    test('the rule answers by what this device knows of the scan', () {
      const rule = SilexgisMissingItemRule();
      final id = Uuid.v7();
      SilexgisTripState state({bool received = false, bool sent = false}) =>
          SilexgisTripState(
            entityUuid: id,
            recordingUuid: id,
            isScan: true,
            received: received,
            sent: sent,
          );
      expect(rule.removesMissing(null, editedHere: false), isFalse);
      expect(
        rule.removesMissing(state(received: true), editedHere: false),
        isTrue,
      );
      expect(
        rule.removesMissing(state(received: true), editedHere: true),
        isFalse,
      );
      expect(
        rule.removesMissing(
          state(received: true, sent: true),
          editedHere: false,
        ),
        isFalse,
      );
      expect(rule.removesMissing(state(), editedHere: false), isFalse);
    });
  });

  group('with the scan tombstones named', () {
    Future<(Uuid, Uuid)> recordingWithScan() async {
      final recording = Uuid.v7();
      final scan = Uuid.v7();
      await applier.applyPage(
        page(<Map<String, Object?>>[
          recordingJson(
            recording,
            points: <Map<String, Object?>>[pointJson(scan)],
          ),
        ]),
      );
      return (recording, scan);
    }

    Map<String, Object?> pointTombstone(Uuid recording, Uuid scan) =>
        <String, Object?>{
          'id': scan.toString(),
          'recordingId': recording.toString(),
          'deletedAt': revision,
        };

    test('a tombstone removes the scan and what is kept of it', () async {
      final (recording, scan) = await recordingWithScan();
      final applied = await applier.applyPage(
        page(
          <Map<String, Object?>>[recordingJson(recording)],
          pointTombstones: <Map<String, Object?>>[
            pointTombstone(recording, scan),
          ],
        ),
      );
      expect(applied.scansRemoved, 1);
      expect(await scansOf(recording), isEmpty);
      expect(await tripRow(recording), isNotNull);
      expect((await localState.readRevisions(profile))[scan], isNull);
      expect((await trips.readAll(profile))[scan], isNull);
      expect(await db.select(db.changeLog).get(), isEmpty);
    });

    test('a tombstone removes a scan this device sent as well', () async {
      final (recording, scan) = await recordingWithScan();
      await trips.recordSent(profile, <SilexgisTripState>[
        SilexgisTripState(
          entityUuid: scan,
          recordingUuid: recording,
          isScan: true,
        ),
      ]);
      final applied = await applier.applyPage(
        page(
          const <Map<String, Object?>>[],
          pointTombstones: <Map<String, Object?>>[
            pointTombstone(recording, scan),
          ],
        ),
      );
      expect(applied.scansRemoved, 1);
      expect(await scansOf(recording), isEmpty);
    });

    test(
      'a tombstone of a scan this device never held changes nothing',
      () async {
        final (recording, scan) = await recordingWithScan();
        final applied = await applier.applyPage(
          page(
            <Map<String, Object?>>[
              recordingJson(
                recording,
                points: <Map<String, Object?>>[pointJson(scan)],
              ),
            ],
            pointTombstones: <Map<String, Object?>>[
              pointTombstone(recording, Uuid.v7()),
            ],
          ),
        );
        expect(applied.scansRemoved, 0);
        expect((await scansOf(recording)).single.uuid, scan);
      },
    );

    test(
      'a tombstone leaves a scan with an unsent edit to the caver',
      () async {
        final (recording, scan) = await recordingWithScan();
        await (db.update(
          db.caveTripPoints,
        )..where((t) => t.uuid.equalsValue(scan))).write(
          CaveTripPointsCompanion(
            notes: const Value('mine'),
            updatedAt: Value(clock.nowMs() + 1000),
          ),
        );
        final applied = await applier.applyPage(
          page(
            const <Map<String, Object?>>[],
            pointTombstones: <Map<String, Object?>>[
              pointTombstone(recording, scan),
            ],
          ),
        );
        expect(applied.scansRemoved, 0);
        expect(applied.heldBack, 1);
        expect((await scansOf(recording)).single.notes, 'mine');
      },
    );

    test('a scan merely missing is kept, whatever its history', () async {
      final (recording, scan) = await recordingWithScan();
      // Received here and never sent: the interim rule would remove it.
      final applied = await applier.applyPage(
        page(<Map<String, Object?>>[
          recordingJson(recording),
        ], pointTombstones: const []),
      );
      expect(applied.scansRemoved, 0);
      expect((await scansOf(recording)).single.uuid, scan);
      expect((await localState.readRevisions(profile))[scan], isNotNull);
    });

    test('a scan missing is kept beside a tombstone naming another', () async {
      final (recording, scan) = await recordingWithScan();
      final applied = await applier.applyPage(
        page(
          <Map<String, Object?>>[recordingJson(recording)],
          pointTombstones: <Map<String, Object?>>[
            pointTombstone(recording, Uuid.v7()),
          ],
        ),
      );
      expect(applied.scansRemoved, 0);
      expect((await scansOf(recording)).single.uuid, scan);
    });
  });

  test(
    'a scan colliding with a local one keeps the local one and is reported',
    () async {
      final recording = Uuid.v7();
      await applier.applyPage(
        page(<Map<String, Object?>>[recordingJson(recording)]),
      );
      final mine = await db.insertTripPoint(
        tripUuid: recording,
        cavePlaceUuid: placeId,
        authorUuid: localUser,
        scannedAt: DateTime.utc(2026, 10, 27, 9).millisecondsSinceEpoch,
        notes: 'mine',
      );
      final twin = Uuid.v7();
      final applied = await applier.applyPage(
        page(<Map<String, Object?>>[
          recordingJson(
            recording,
            rev: '2026-10-27T15:00:00Z',
            points: <Map<String, Object?>>[
              pointJson(twin),
              pointJson(Uuid.v7(), scannedAt: '2026-10-27T10:30:00Z'),
            ],
          ),
        ]),
      );
      expect(applied.collisions, <Uuid>[twin]);
      // The rest of the page still landed.
      expect(applied.scansInserted, 1);
      final scans = await scansOf(recording);
      expect(scans.singleWhere((s) => s.uuid == mine).notes, 'mine');
    },
  );

  test('a tombstone removes the recording with its scans', () async {
    final recording = Uuid.v7();
    final scan = Uuid.v7();
    await applier.applyPage(
      page(<Map<String, Object?>>[
        recordingJson(
          recording,
          points: <Map<String, Object?>>[pointJson(scan)],
        ),
      ]),
    );
    final applied = await applier.applyPage(
      page(
        const <Map<String, Object?>>[],
        tombstones: <Map<String, Object?>>[
          <String, Object?>{'id': recording.toString(), 'deletedAt': revision},
        ],
      ),
    );
    expect(applied.recordingsRemoved, 1);
    expect(await tripRow(recording), isNull);
    expect(await scansOf(recording), isEmpty);
    expect(await trips.readAll(profile), isEmpty);
    expect(await db.select(db.changeLog).get(), isEmpty);
  });

  group('the stream', () {
    test(
      'reads on its own cursor, and from the beginning when refused',
      () async {
        final recording = Uuid.v7();
        await localState.writeStreamCursor(
          profile,
          setId,
          SyncStream.trips,
          cursor: 'stale',
          setRevision: 0,
        );
        final path = SilexgisContract.tripsPath(setId);
        final client = ScriptedClient(<ScriptedResponse>[
          ScriptedResponse.json(
            path: path,
            status: 409,
            json: const <String, Object?>{
              'status': 409,
              'code': SilexgisCodes.cursorStale,
            },
          ),
          ScriptedResponse.json(
            path: path,
            json: <String, Object?>{
              'setRevision': 2,
              'settings': const <String, Object?>{},
              'recordings': <Object?>[recordingJson(recording)],
              'tombstones': const <Object?>[],
              'nextCursor': 'trips-c9',
              'hasMore': false,
            },
          ),
        ]);
        final report = await SilexgisTripsRunner(
          api: SilexgisSyncApi(
            SilexgisHttp(
              baseUri: Uri.parse('https://club.example.org'),
              tokens: FixedTokenSource(),
              client: client,
            ),
          ),
          localState: localState,
          applier: applier,
          profileUuid: profile,
        ).run(setId, capabilities: capabilities);

        expect(report.restarted, isTrue);
        expect(report.applied.recordingsInserted, 1);
        expect(client.sent.first.url.queryParameters['cursor'], 'stale');
        expect(
          client.sent.last.url.queryParameters.containsKey('cursor'),
          isFalse,
        );
        expect(
          (await localState.readStreamCursor(
            profile,
            setId,
            SyncStream.trips,
          )).cursor,
          'trips-c9',
        );
        // The feature download's position is not this stream's.
        expect((await localState.readSetState(profile, setId)).cursor, isNull);
      },
    );
  });
}
