import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_points_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_recordings_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_upload_answers.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/clock.dart';

import 'scripted_client.dart';
import 'token_source.dart';

/// Trip recordings up: which go, what each says — an open one states no end,
/// an author this device cannot name is left out — and what is kept of each
/// answer.
void main() {
  const profile = 'p-1';
  const setId = 'set-1';
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'upload', 'trips', 'people'],
  );
  final clock = FakeClock(DateTime.utc(2026, 10, 28, 8));
  final uploadPath = SilexgisContract.uploadPath(setId);

  late AppDatabase db;
  late SilexgisLocalStateRepository localState;
  late SilexgisHeldRowRepository heldRows;
  late SilexgisTripStateRepository trips;
  late SilexgisPeopleRepository people;

  final caveId = Uuid.v7();
  final placeId = Uuid.v7();
  final userId = Uuid.v7();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localState = SilexgisLocalStateRepository(db, clock: clock);
    heldRows = SilexgisHeldRowRepository(db, clock: clock);
    trips = SilexgisTripStateRepository(db);
    people = SilexgisPeopleRepository(db, clock: clock);

    final t0 = clock.nowMs();
    await db
        .into(db.users)
        .insert(UsersCompanion.insert(uuid: userId, username: 'invented'));
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
    // The cave and its place, as the installation holds them.
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
  tearDown(() => db.close());

  Future<Uuid> recording({
    Uuid? cave,
    int? endedAt,
    Uuid? author,
    bool noAuthor = false,
  }) async {
    final id = Uuid.v7();
    final now = clock.nowMs();
    await db
        .into(db.caveTrips)
        .insert(
          CaveTripsCompanion.insert(
            uuid: id,
            caveUuid: cave ?? caveId,
            title: 'Invented trip',
            tripStartedAt: now,
          ).copyWith(
            tripEndedAt: Value(endedAt),
            participants: const Value('Ana, Ion'),
            logStaleSince: Value(now),
            deviceUuid: Value(Uuid.v7()),
            createdByUserUuid: Value(noAuthor ? null : (author ?? userId)),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  Future<Uuid> scan(Uuid trip, {Uuid? place}) async {
    final id = Uuid.v7();
    final now = clock.nowMs();
    await db
        .into(db.caveTripPoints)
        .insert(
          CaveTripPointsCompanion.insert(
            uuid: id,
            caveTripUuid: trip,
            scannedAt: now,
          ).copyWith(
            cavePlaceUuid: Value(place ?? placeId),
            notes: const Value('turned back'),
            createdByUserUuid: Value(userId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  Map<String, Object?> verdict(
    Uuid id,
    String status, {
    String revision = '2026-10-28T08:00:00Z',
    String? reviewId,
  }) => <String, Object?>{
    'id': id.toString(),
    'status': status,
    'revision': revision,
    'code': null,
    'detail': null,
    'reviewId': ?reviewId,
  };

  ScriptedResponse answer({
    List<Map<String, Object?>>? recordings,
    List<Map<String, Object?>>? points,
    List<Map<String, Object?>>? people,
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
      'tripRecordings': ?recordings,
      'tripPoints': ?points,
      'people': ?people,
    },
  );

  Future<SilexgisUploadReport> run(ScriptedClient client) {
    final answers = SilexgisTripUploadAnswers(
      localState: localState,
      heldRows: heldRows,
      trips: trips,
      profileUuid: profile,
    );
    return SilexgisUploadRunner(
      api: SilexgisSyncApi(
        SilexgisHttp(
          baseUri: Uri.parse('https://club.example.org'),
          tokens: FixedTokenSource(),
          client: client,
        ),
      ),
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
        SilexgisTripRecordingsUploadPart(
          db: db,
          localState: localState,
          heldRows: heldRows,
          answers: answers,
          profileUuid: profile,
        ),
        SilexgisTripPointsUploadPart(
          db: db,
          localState: localState,
          heldRows: heldRows,
          trips: trips,
          answers: answers,
          profileUuid: profile,
        ),
        SilexgisPeopleUploadPart(db: db, people: people, profileUuid: profile),
      ],
    ).run(setId, capabilities: capabilities);
  }

  List<Map<String, Object?>> sentSection(
    ScriptedClient client,
    SyncUploadSection section,
  ) => <Map<String, Object?>>[
    for (final r in client.sent.where((r) => r.url.path == uploadPath))
      for (final item in (r.jsonBody[section.wireName] as List? ?? const []))
        item as Map<String, Object?>,
  ];

  group('a recording of the caver\'s own', () {
    test(
      'while open goes without an end, with its scan and its author',
      () async {
        final trip = await recording();
        final point = await scan(trip);
        final client = ScriptedClient(<ScriptedResponse>[
          answer(
            recordings: <Map<String, Object?>>[verdict(trip, 'created')],
            points: <Map<String, Object?>>[verdict(point, 'created')],
            people: <Map<String, Object?>>[verdict(userId, 'created')],
          ),
        ]);

        final report = await run(client);

        expect(report.refusals, isEmpty);
        final sent = sentSection(
          client,
          SyncUploadSection.tripRecordings,
        ).single;
        expect(sent['id'], trip.toString());
        expect(sent['caveId'], caveId.toString());
        expect(sent['baseRevision'], isNull);
        expect(sent.containsKey('endedAt'), isFalse);
        expect(sent['createdByDeviceUserId'], userId.toString());
        // Who went, the log's staleness and the device stay on the phone.
        for (final key in <String>[
          'participants',
          'logStaleSince',
          'deviceUuid',
        ]) {
          expect(sent.containsKey(key), isFalse, reason: key);
        }
        final point0 = sentSection(client, SyncUploadSection.tripPoints).single;
        expect(point0['recordingId'], trip.toString());
        expect(point0['placeId'], placeId.toString());
        // The author goes as a phone user the installation can resolve.
        final person = sentSection(client, SyncUploadSection.people).single;
        expect(person['deviceUserId'], userId.toString());

        final revisions = await localState.readRevisions(profile);
        expect(revisions[trip]!.entityTable, 'cave_trips');
        expect(revisions[point]!.entityTable, 'cave_trip_points');
        final states = await trips.readAll(profile);
        expect(states[trip]!.sent, isTrue);
        expect(states[point]!.recordingUuid, trip);
        expect(states[point]!.received, isFalse);
      },
    );

    test('closing it sends its end against the revision it holds', () async {
      final trip = await recording();
      await run(
        ScriptedClient(<ScriptedResponse>[
          answer(
            recordings: <Map<String, Object?>>[verdict(trip, 'created')],
            people: <Map<String, Object?>>[verdict(userId, 'created')],
          ),
        ]),
      );

      clock.advance(const Duration(hours: 3));
      final end = clock.nowMs();
      await (db.update(
        db.caveTrips,
      )..where((t) => t.uuid.equalsValue(trip))).write(
        CaveTripsCompanion(tripEndedAt: Value(end), updatedAt: Value(end)),
      );
      final client = ScriptedClient(<ScriptedResponse>[
        answer(
          recordings: <Map<String, Object?>>[
            verdict(trip, 'updated', revision: '2026-10-28T11:00:00Z'),
          ],
        ),
      ]);
      await run(client);

      final sent = sentSection(client, SyncUploadSection.tripRecordings).single;
      expect(sent['baseRevision'], '2026-10-28T08:00:00Z');
      expect(
        sent['endedAt'],
        DateTime.fromMillisecondsSinceEpoch(end, isUtc: true).toIso8601String(),
      );
      // The author was told about once, and is not sent again.
      expect(sentSection(client, SyncUploadSection.people), isEmpty);
    });

    test('nothing goes again while it is unchanged', () async {
      final trip = await recording();
      await run(
        ScriptedClient(<ScriptedResponse>[
          answer(
            recordings: <Map<String, Object?>>[verdict(trip, 'created')],
            people: <Map<String, Object?>>[verdict(userId, 'created')],
          ),
        ]),
      );
      final client = ScriptedClient(const <ScriptedResponse>[]);
      final report = await run(client);
      expect(report.isEmpty, isTrue);
      expect(client.sent, isEmpty);
    });

    test('in a cave the installation does not carry, stays here', () async {
      final elsewhere = Uuid.v7();
      await db.into(db.caves).insert(Cave(uuid: elsewhere, title: 'Elsewhere'));
      await recording(cave: elsewhere);
      final client = ScriptedClient(const <ScriptedResponse>[]);
      final report = await run(client);
      expect(report.isEmpty, isTrue);
    });
  });

  group('a recording read from another phone', () {
    test('an edit keeps the installation\'s author by naming none', () async {
      final trip = await recording(noAuthor: true);
      final stamp = (await (db.select(
        db.caveTrips,
      )..where((t) => t.uuid.equalsValue(trip))).getSingle()).updatedAt;
      await localState.writeRevision(
        profile,
        trip,
        entityTable: 'cave_trips',
        revision: 'r-1',
        localUpdatedAt: stamp,
      );
      await trips.recordDownloaded(
        profile,
        SilexgisTripState(
          entityUuid: trip,
          recordingUuid: trip,
          received: true,
          authorDeviceUserId: Uuid.v7().toString(),
        ),
      );

      clock.advance(const Duration(minutes: 5));
      await (db.update(
        db.caveTrips,
      )..where((t) => t.uuid.equalsValue(trip))).write(
        CaveTripsCompanion(
          log: const Value('edited here'),
          updatedAt: Value(clock.nowMs()),
        ),
      );
      final client = ScriptedClient(<ScriptedResponse>[
        answer(recordings: <Map<String, Object?>>[verdict(trip, 'updated')]),
      ]);
      await run(client);

      final sent = sentSection(client, SyncUploadSection.tripRecordings).single;
      expect(sent['log'], 'edited here');
      expect(sent['baseRevision'], 'r-1');
      expect(sent.containsKey('createdByDeviceUserId'), isFalse);
      expect(sentSection(client, SyncUploadSection.people), isEmpty);
      // Sent from here now, and still the installation's.
      final state = (await trips.readAll(profile))[trip]!;
      expect(state.received, isTrue);
      expect(state.sent, isTrue);
    });
  });

  group('removals', () {
    Future<(Uuid, Uuid)> agreed() async {
      final trip = await recording(endedAt: clock.nowMs());
      final point = await scan(trip);
      await run(
        ScriptedClient(<ScriptedResponse>[
          answer(
            recordings: <Map<String, Object?>>[verdict(trip, 'created')],
            points: <Map<String, Object?>>[verdict(point, 'created')],
            people: <Map<String, Object?>>[verdict(userId, 'created')],
          ),
        ]),
      );
      return (trip, point);
    }

    test('a scan removed here names its recording', () async {
      final (trip, point) = await agreed();
      await db.deleteTripPoint(point);
      final client = ScriptedClient(<ScriptedResponse>[
        answer(points: <Map<String, Object?>>[verdict(point, 'deleted')]),
      ]);
      await run(client);

      expect(sentSection(client, SyncUploadSection.tripPoints).single, {
        'id': point.toString(),
        'recordingId': trip.toString(),
        'baseRevision': '2026-10-28T08:00:00Z',
        'deleted': true,
      });
      expect((await localState.readRevisions(profile))[point], isNull);
      expect((await trips.readAll(profile))[point], isNull);
    });

    test('a recording removed here takes its scans along', () async {
      final (trip, point) = await agreed();
      await db.deleteCaveTrip(trip);
      final client = ScriptedClient(<ScriptedResponse>[
        answer(recordings: <Map<String, Object?>>[verdict(trip, 'deleted')]),
      ]);
      await run(client);

      expect(sentSection(client, SyncUploadSection.tripPoints), isEmpty);
      final sent = sentSection(client, SyncUploadSection.tripRecordings).single;
      expect(sent['deleted'], isTrue);
      final revisions = await localState.readRevisions(profile);
      expect(revisions[trip], isNull);
      expect(revisions[point], isNull);
      expect(await trips.readAll(profile), isEmpty);
    });
  });

  group('held for a reviewer', () {
    test('a held recording is not sent again unedited', () async {
      final trip = await recording();
      final first = await run(
        ScriptedClient(<ScriptedResponse>[
          answer(
            recordings: <Map<String, Object?>>[
              <String, Object?>{
                ...verdict(trip, 'held', reviewId: 'review-1'),
                'revision': null,
              },
            ],
            people: <Map<String, Object?>>[verdict(userId, 'created')],
          ),
        ]),
      );
      expect(first.held, 1);
      final waiting = await heldRows.readSection(
        profile,
        SyncUploadSection.tripRecordings,
      );
      expect(waiting[trip]!.reviewId, 'review-1');
      expect((await localState.readRevisions(profile))[trip], isNull);

      final client = ScriptedClient(const <ScriptedResponse>[]);
      expect((await run(client)).isEmpty, isTrue);
    });
  });
}
