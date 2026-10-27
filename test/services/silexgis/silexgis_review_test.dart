import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_review.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_review_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/utils/clock.dart';

import 'contract_fixtures.dart';
import 'scripted_client.dart';
import 'token_source.dart';

/// What happens after a row is held: the reviewers' decisions.
void main() {
  const setId = 'set-1';
  const profile = SilexgisProfile(
    profileUuid: 'p-1',
    displayName: 'Clubul Speo Example',
    baseUrl: 'https://club.example.org',
    accountEmail: 'caver@example.org',
    syncSetId: setId,
  );
  const decidedAt = '2026-10-26T09:12:44.512Z';
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'upload', 'reviews'],
  );

  late AppDatabase db;
  late SilexgisLocalStateRepository localState;
  late SilexgisHeldRowRepository heldRows;
  late SilexgisUploadBuilder builder;
  final clock = FakeClock(DateTime.utc(2026, 10, 26, 8));

  final caveId = Uuid.v7();
  final entranceId = Uuid.v7();

  setUp(() async {
    clock.set(DateTime.utc(2026, 10, 26, 8));
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localState = SilexgisLocalStateRepository(db, clock: clock);
    heldRows = SilexgisHeldRowRepository(db, clock: clock);
    builder = SilexgisUploadBuilder(
      db: db,
      localState: localState,
      heldRows: heldRows,
      profileUuid: profile.profileUuid,
    );
  });
  tearDown(() => db.close());

  // ---------------------------------------------------------------- fixtures

  /// A cave the server holds, with an entrance the caver edited here and sent
  /// for review under [reviewId].
  Future<int> heldEntranceEdit({String reviewId = 'review-1'}) async {
    final t0 = clock.nowMs();
    await db
        .into(db.caves)
        .insert(Cave(uuid: caveId, title: 'Peștera Mică', updatedAt: t0));
    await localState.writeRevision(
      profile.profileUuid,
      caveId,
      entityTable: 'caves',
      wireKind: 'cave',
      revision: '2026-10-20T17:00:00.000Z',
      localUpdatedAt: t0,
    );
    await localState.writeRevision(
      profile.profileUuid,
      entranceId,
      entityTable: 'cave_places',
      wireKind: 'caveEntrance',
      revision: '2026-10-20T17:03:10.118Z',
      localUpdatedAt: t0,
    );
    clock.advance(const Duration(minutes: 5));
    final edited = clock.nowMs();
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlace(
            uuid: entranceId,
            title: 'Edited here',
            caveUuid: caveId,
            latitude: 45.7,
            longitude: 22.6,
            isEntrance: 1,
            isMainEntrance: 1,
            updatedAt: edited,
          ),
        );
    await heldRows.recordHeld(profile.profileUuid, <SilexgisHeldEntry>[
      SilexgisHeldEntry(
        section: SyncUploadSection.rows,
        entityUuid: entranceId,
        entityTable: 'cave_places',
        wireKind: 'caveEntrance',
        reviewId: reviewId,
        sentLocalUpdatedAt: edited,
      ),
    ]);
    return edited;
  }

  Map<String, String> placeholders({String reviewId = 'review-1'}) =>
      <String, String>{
        '<review>': reviewId,
        '<entrance>': entranceId.toString(),
        '<cave>': caveId.toString(),
        '<timestamp>': decidedAt,
        '<cursor>': 'reviews-c1',
      };

  Map<String, Object?> recorded(String name, {String reviewId = 'review-1'}) =>
      fillPlaceholders(
            ContractExchange(name).responseBody,
            placeholders(reviewId: reviewId),
          )!
          as Map<String, Object?>;

  Map<String, Object?> reviewsPage(List<Map<String, Object?>> reviews) =>
      <String, Object?>{
        'setRevision': 1,
        'settings': const <String, Object?>{},
        'reviews': reviews,
        'nextCursor': 'reviews-c1',
        'hasMore': false,
      };

  Map<String, Object?> decision(
    String reviewId,
    String outcome, {
    Uuid? rowId,
    String? revision,
  }) => <String, Object?>{
    'reviewId': reviewId,
    'entity': 'rows',
    'rowId': (rowId ?? entranceId).toString(),
    'outcome': outcome,
    'decidedAt': decidedAt,
    'revision': ?revision,
  };

  Future<SilexgisReviewReport> readReviews(List<Map<String, Object?>> pages) {
    final client = ScriptedClient(<ScriptedResponse>[
      for (final page in pages)
        ScriptedResponse.json(
          path: SilexgisContract.reviewsPath(setId),
          json: page,
        ),
    ]);
    return SilexgisReviewRunner(
      db: db,
      api: SilexgisSyncApi(
        SilexgisHttp(
          baseUri: profile.baseUri,
          tokens: FixedTokenSource(),
          client: client,
        ),
      ),
      localState: localState,
      heldRows: heldRows,
      profileUuid: profile.profileUuid,
    ).run(setId, capabilities: capabilities);
  }

  Future<SilexgisHeldItem?> heldFor(Uuid uuid) async => (await heldRows
      .readSection(profile.profileUuid, SyncUploadSection.rows))[uuid];

  Future<CavePlace> entrance() => (db.select(
    db.cavePlaces,
  )..where((t) => t.uuid.equalsValue(entranceId))).getSingle();

  // ------------------------------------------------------------------- tests

  group('the reviews stream', () {
    test(
      '21: a turned-down edit is kept with the note and the server\'s row',
      () async {
        await heldEntranceEdit();

        final report = await readReviews(<Map<String, Object?>>[
          recorded('21-reviews-first-page'),
        ]);

        expect(report.decided, 1);
        final held = (await heldFor(entranceId))!;
        expect(held.outcome, SyncReviewOutcome.rejected);
        expect(held.note, 'Wrong shaft');
        expect(held.current?['name'], 'Intrare');
        expect(held.awaitsCaver, isTrue);
        // The caver's version stays until they choose.
        expect((await entrance()).title, 'Edited here');
        // And the stream's position is its own.
        final cursor = await localState.readStreamCursor(
          profile.profileUuid,
          setId,
          SyncStream.reviews,
        );
        expect(cursor.cursor, 'reviews-c1');
        expect(
          (await localState.readSetState(profile.profileUuid, setId)).cursor,
          isNull,
        );
      },
    );

    test('22: with the server\'s row withheld, nothing is made up', () async {
      await heldEntranceEdit();

      await readReviews(<Map<String, Object?>>[
        recorded('22-reviews-current-withheld'),
      ]);

      final held = (await heldFor(entranceId))!;
      expect(held.outcome, SyncReviewOutcome.rejected);
      expect(held.current, isNull);
    });

    test(
      'the last decision read for a review is the one that stands',
      () async {
        // A reviewer may change their mind about a row they turned down.
        final sentAt = await heldEntranceEdit();

        final report = await readReviews(<Map<String, Object?>>[
          reviewsPage(<Map<String, Object?>>[
            decision('review-1', 'rejected'),
            decision('review-1', 'accepted', revision: decidedAt),
          ]),
        ]);

        expect(report.accepted, 1);
        expect(await heldFor(entranceId), isNull);
        final stored = (await localState.readRevisions(
          profile.profileUuid,
        ))[entranceId]!;
        expect(stored.revision, decidedAt);
        // The row as written is the version sent, so it agrees now and is not
        // sent again.
        expect(stored.localUpdatedAt, sentAt);
        expect(await builder.build(), isEmpty);
      },
    );

    test('a decision about an earlier proposal is ignored', () async {
      // The row was sent again with other content and waits under review-2;
      // review-1 is superseded, and nothing said about it concerns the row.
      await heldEntranceEdit(reviewId: 'review-2');

      await readReviews(<Map<String, Object?>>[
        reviewsPage(<Map<String, Object?>>[
          decision('review-1', 'rejected'),
          decision('review-1', 'superseded'),
        ]),
      ]);

      final held = (await heldFor(entranceId))!;
      expect(held.reviewId, 'review-2');
      expect(held.isWaiting, isTrue);
    });

    test('a failure keeps the code the write would have answered', () async {
      await heldEntranceEdit();

      await readReviews(<Map<String, Object?>>[
        reviewsPage(<Map<String, Object?>>[
          <String, Object?>{
            ...decision('review-1', 'failed'),
            'code': 'sync.row_forbidden',
          },
        ]),
      ]);

      final held = (await heldFor(entranceId))!;
      expect(held.outcome, SyncReviewOutcome.failed);
      expect(held.code, 'sync.row_forbidden');
    });

    test('an accepted removal forgets the revision', () async {
      await localState.writeRevision(
        profile.profileUuid,
        entranceId,
        entityTable: 'cave_places',
        wireKind: 'caveEntrance',
        revision: '2026-10-20T17:03:10.118Z',
      );
      await heldRows.recordHeld(profile.profileUuid, <SilexgisHeldEntry>[
        SilexgisHeldEntry(
          section: SyncUploadSection.rows,
          entityUuid: entranceId,
          entityTable: 'cave_places',
          reviewId: 'review-1',
          isDelete: true,
        ),
      ]);

      await readReviews(<Map<String, Object?>>[
        reviewsPage(<Map<String, Object?>>[decision('review-1', 'accepted')]),
      ]);

      expect(
        await localState.readRevision(profile.profileUuid, entranceId),
        isNull,
      );
      expect(await builder.build(), isEmpty);
    });
  });
}
