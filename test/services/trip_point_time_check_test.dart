import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/trip_point_time_check.dart';

void main() {
  final start = DateTime(2026, 9, 22, 10, 0);
  final end = DateTime(2026, 9, 22, 14, 0);

  test('a time inside the window has no issue', () {
    expect(
      checkTripPointTime(
        at: DateTime(2026, 9, 22, 12, 0),
        tripStart: start,
        tripEnd: end,
      ),
      isNull,
    );
  });

  test('the boundaries themselves are inside the window', () {
    expect(
      checkTripPointTime(at: start, tripStart: start, tripEnd: end),
      isNull,
    );
    expect(checkTripPointTime(at: end, tripStart: start, tripEnd: end), isNull);
  });

  test('a time before the start is flagged', () {
    expect(
      checkTripPointTime(
        at: start.subtract(const Duration(minutes: 1)),
        tripStart: start,
        tripEnd: end,
      ),
      TripPointTimeIssue.beforeTripStart,
    );
  });

  test('a time after the end is flagged', () {
    expect(
      checkTripPointTime(
        at: end.add(const Duration(minutes: 1)),
        tripStart: start,
        tripEnd: end,
      ),
      TripPointTimeIssue.afterTripEnd,
    );
  });

  test('an unended trip cannot be overrun', () {
    expect(
      checkTripPointTime(
        at: start.add(const Duration(days: 3)),
        tripStart: start,
      ),
      isNull,
    );
  });

  test('an unended trip still flags times before its start', () {
    expect(
      checkTripPointTime(
        at: start.subtract(const Duration(hours: 1)),
        tripStart: start,
      ),
      TripPointTimeIssue.beforeTripStart,
    );
  });
}
