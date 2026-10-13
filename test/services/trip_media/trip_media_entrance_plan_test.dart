import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/trip_media/trip_media_entrance_plan.dart';

/// A photo taken at a cave entrance is the record of going in or coming
/// out, so it contradicts two things the trip already holds: its entrance
/// points and its own start/end. These tests pin which of those the plan
/// offers to change, and — just as importantly — when it offers nothing.
void main() {
  final tripStart = DateTime(2026, 10, 13, 9, 0);
  final tripEnd = DateTime(2026, 10, 13, 17, 0);

  final entranceA = Uuid.v7();
  final entranceB = Uuid.v7();
  final innerPlace = Uuid.v7();
  final entrances = {entranceA, entranceB};

  CaveTripPoint point(Uuid placeUuid, DateTime at) => CaveTripPoint(
    uuid: Uuid.v7(),
    caveTripUuid: Uuid.v7(),
    cavePlaceUuid: placeUuid,
    scannedAt: at.millisecondsSinceEpoch,
  );

  test('no entrance markers means nothing to reconcile', () {
    final plan = planEntranceReconciliation(
      tripStart: tripStart,
      tripEnd: tripEnd,
      newEntranceTimes: const [],
      existingPoints: [point(entranceA, tripStart)],
      entrancePlaceUuids: entrances,
    );
    expect(plan.isEmpty, isTrue);
  });

  test('two markers read as went-in-first, came-out-last', () {
    final wentIn = DateTime(2026, 10, 13, 8, 40);
    final cameOut = DateTime(2026, 10, 13, 17, 25);
    final plan = planEntranceReconciliation(
      tripStart: tripStart,
      tripEnd: tripEnd,
      newEntranceTimes: [cameOut, wentIn],
      existingPoints: const [],
      entrancePlaceUuids: entrances,
    );
    expect(plan.proposedTripStart, wentIn);
    expect(plan.proposedTripEnd, cameOut);
  });

  test('a middle marker does not become a boundary', () {
    final wentIn = DateTime(2026, 10, 13, 8, 40);
    final middle = DateTime(2026, 10, 13, 12, 0);
    final cameOut = DateTime(2026, 10, 13, 17, 25);
    final plan = planEntranceReconciliation(
      tripStart: tripStart,
      tripEnd: tripEnd,
      newEntranceTimes: [middle, cameOut, wentIn],
      existingPoints: const [],
      entrancePlaceUuids: entrances,
    );
    expect(plan.proposedTripStart, wentIn);
    expect(plan.proposedTripEnd, cameOut);
  });

  group('a single marker moves the nearer end', () {
    test('near the start it moves the start', () {
      final marker = DateTime(2026, 10, 13, 8, 45);
      final plan = planEntranceReconciliation(
        tripStart: tripStart,
        tripEnd: tripEnd,
        newEntranceTimes: [marker],
        existingPoints: const [],
        entrancePlaceUuids: entrances,
      );
      expect(plan.proposedTripStart, marker);
      expect(plan.proposedTripEnd, isNull);
    });

    test('near the end it moves the end', () {
      final marker = DateTime(2026, 10, 13, 16, 50);
      final plan = planEntranceReconciliation(
        tripStart: tripStart,
        tripEnd: tripEnd,
        newEntranceTimes: [marker],
        existingPoints: const [],
        entrancePlaceUuids: entrances,
      );
      expect(plan.proposedTripStart, isNull);
      expect(plan.proposedTripEnd, marker);
    });

    test('never both, which would collapse the trip to an instant', () {
      final marker = DateTime(2026, 10, 13, 13, 0);
      final plan = planEntranceReconciliation(
        tripStart: tripStart,
        tripEnd: tripEnd,
        newEntranceTimes: [marker],
        existingPoints: const [],
        entrancePlaceUuids: entrances,
      );
      expect(
        plan.proposedTripStart == null || plan.proposedTripEnd == null,
        isTrue,
      );
    });
  });

  test('an unended trip only ever gets a start proposal', () {
    final marker = DateTime(2026, 10, 13, 8, 30);
    final plan = planEntranceReconciliation(
      tripStart: tripStart,
      tripEnd: null,
      newEntranceTimes: [marker, DateTime(2026, 10, 13, 16, 0)],
      existingPoints: const [],
      entrancePlaceUuids: entrances,
    );
    expect(plan.proposedTripStart, marker);
    expect(
      plan.proposedTripEnd,
      isNull,
      reason: 'there is no recorded end to move on a live trip',
    );
  });

  test('a marker that matches the recorded boundary proposes nothing', () {
    final plan = planEntranceReconciliation(
      tripStart: tripStart,
      tripEnd: tripEnd,
      newEntranceTimes: [tripStart, tripEnd],
      existingPoints: const [],
      entrancePlaceUuids: entrances,
    );
    expect(plan.proposedTripStart, isNull);
    expect(plan.proposedTripEnd, isNull);
  });

  test('a pair outside the recorded window moves the whole window', () {
    // Both markers land after the recorded end: the pictures say the trip
    // happened later than it was logged, and taking both ends keeps the
    // window ordered rather than inverting it.
    final wentIn = DateTime(2026, 10, 13, 18, 0);
    final cameOut = DateTime(2026, 10, 13, 19, 0);
    final plan = planEntranceReconciliation(
      tripStart: tripStart,
      tripEnd: DateTime(2026, 10, 13, 10, 0),
      newEntranceTimes: [wentIn, cameOut],
      existingPoints: const [],
      entrancePlaceUuids: entrances,
    );
    expect(plan.proposedTripStart, wentIn);
    expect(plan.proposedTripEnd, cameOut);
    expect(plan.proposedTripStart!.isAfter(plan.proposedTripEnd!), isFalse);
  });

  test('a lone marker past the recorded end moves the end, not the start', () {
    final marker = DateTime(2026, 10, 13, 18, 0);
    final plan = planEntranceReconciliation(
      tripStart: tripStart,
      tripEnd: DateTime(2026, 10, 13, 10, 0),
      newEntranceTimes: [marker],
      existingPoints: const [],
      entrancePlaceUuids: entrances,
    );
    expect(plan.proposedTripStart, isNull);
    expect(plan.proposedTripEnd, marker);
  });

  test('a lone marker before the recorded start moves the start', () {
    final marker = DateTime(2026, 10, 13, 6, 0);
    final plan = planEntranceReconciliation(
      tripStart: tripStart,
      tripEnd: tripEnd,
      newEntranceTimes: [marker],
      existingPoints: const [],
      entrancePlaceUuids: entrances,
    );
    expect(plan.proposedTripStart, marker);
    expect(plan.proposedTripEnd, isNull);
  });

  group('superseded points', () {
    test('only entrance-place points are offered for removal', () {
      final oldEntrance = point(entranceA, tripStart);
      final oldInner = point(innerPlace, DateTime(2026, 10, 13, 11, 0));
      final plan = planEntranceReconciliation(
        tripStart: tripStart,
        tripEnd: tripEnd,
        newEntranceTimes: [DateTime(2026, 10, 13, 8, 30)],
        existingPoints: [oldInner, oldEntrance],
        entrancePlaceUuids: entrances,
      );
      expect(plan.supersededPoints.map((p) => p.uuid), [oldEntrance.uuid]);
    });

    test('they come back in chronological order', () {
      final late = point(entranceA, DateTime(2026, 10, 13, 17, 5));
      final early = point(entranceB, DateTime(2026, 10, 13, 8, 55));
      final plan = planEntranceReconciliation(
        tripStart: tripStart,
        tripEnd: tripEnd,
        newEntranceTimes: [DateTime(2026, 10, 13, 8, 30)],
        existingPoints: [late, early],
        entrancePlaceUuids: entrances,
      );
      expect(plan.supersededPoints.map((p) => p.uuid), [early.uuid, late.uuid]);
    });

    test('a point with no place at all is not an entrance point', () {
      final orphan = CaveTripPoint(
        uuid: Uuid.v7(),
        caveTripUuid: Uuid.v7(),
        scannedAt: tripStart.millisecondsSinceEpoch,
      );
      final plan = planEntranceReconciliation(
        tripStart: tripStart,
        tripEnd: tripEnd,
        newEntranceTimes: [DateTime(2026, 10, 13, 8, 30)],
        existingPoints: [orphan],
        entrancePlaceUuids: entrances,
      );
      expect(plan.supersededPoints, isEmpty);
    });
  });
}
