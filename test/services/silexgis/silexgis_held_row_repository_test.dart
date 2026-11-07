import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_review.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// What is held is held per installation and per section, and a decision
/// that arrives after the caver settled an earlier one is put to them again.
void main() {
  final clock = FakeClock(DateTime.utc(2026, 11, 3, 8));

  late AppDatabase db;
  late SilexgisHeldRowRepository heldRows;
  final place = Uuid.v7();

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    heldRows = SilexgisHeldRowRepository(db, clock: clock);
  });
  tearDown(() => db.close());

  Future<void> hold(
    String profile, {
    SyncUploadSection section = SyncUploadSection.rows,
    String reviewId = 'review-1',
  }) => heldRows.recordHeld(profile, <SilexgisHeldEntry>[
    SilexgisHeldEntry(
      section: section,
      entityUuid: place,
      entityTable: 'cave_places',
      reviewId: reviewId,
    ),
  ]);

  Future<SilexgisHeldItem> heldOn(
    String profile, [
    SyncUploadSection section = SyncUploadSection.rows,
  ]) async => (await heldRows.readSection(profile, section))[place]!;

  test(
    'a decision on one installation leaves another\'s review alone',
    () async {
      // Two installations number their reviews each on its own, so the same
      // review identifier can name a proposal on both.
      await hold('p-a');
      await hold('p-b');

      await heldRows.recordDecision(
        'p-a',
        reviewId: 'review-1',
        outcome: SyncReviewOutcome.rejected,
      );

      expect((await heldOn('p-a')).outcome, SyncReviewOutcome.rejected);
      final other = await heldOn('p-b');
      expect(other.outcome, isNull);
      expect(other.isWaiting, isTrue);
    },
  );

  test('clearing a row in one section leaves it held in another', () async {
    await hold('p-a');
    await hold(
      'p-a',
      section: SyncUploadSection.placeStations,
      reviewId: 'review-2',
    );

    await heldRows.clear('p-a', SyncUploadSection.rows, <Uuid>[place]);

    expect(await heldRows.readSection('p-a', SyncUploadSection.rows), isEmpty);
    expect(
      (await heldOn('p-a', SyncUploadSection.placeStations)).reviewId,
      'review-2',
    );
  });

  test('a decision after the caver kept their version is put to them '
      'again', () async {
    await hold('p-a');
    await heldRows.recordDecision(
      'p-a',
      reviewId: 'review-1',
      outcome: SyncReviewOutcome.rejected,
    );
    await heldRows.markKept('p-a', SyncUploadSection.rows, place);
    expect((await heldOn('p-a')).awaitsCaver, isFalse);

    // A reviewer may accept what they turned down, under the same review.
    await heldRows.recordDecision(
      'p-a',
      reviewId: 'review-1',
      outcome: SyncReviewOutcome.accepted,
    );

    final held = await heldOn('p-a');
    expect(held.keptAt, isNull);
    expect(held.awaitsCaver, isTrue);
    expect((await heldRows.counts('p-a')).toDecide, 1);
  });
}
