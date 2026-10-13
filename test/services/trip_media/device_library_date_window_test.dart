import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/trip_media/device_library_media_source.dart';

/// The platform's "create time" filter tests when a file ARRIVED on the
/// device, while the time reported per picture is when it was TAKEN. Cave
/// pictures usually reach a phone days after the trip — off a waterproof
/// camera, from a teammate — so the two differ exactly when it matters.
///
/// Found on an emulator: a picture taken two days before the trip was listed
/// under a range of the trip's own day, because it had been copied over that
/// day. These pin the two rules that fix it.
void main() {
  final tripDayStart = DateTime(2026, 10, 13);
  final tripDayEnd = DateTime(2026, 10, 13, 23, 59, 59, 999);
  final now = DateTime(2026, 10, 20, 12);

  group('the arrival window asked of the platform', () {
    test('has no upper bound short of the present', () {
      // A picture taken on the trip day may be copied over a week later.
      final window = DeviceLibraryMediaSource.arrivalWindowFor(
        tripDayStart,
        now: now,
      );
      final copiedAWeekLater = DateTime(2026, 10, 19, 21);
      expect(copiedAWeekLater.isBefore(window.max), isTrue);
      expect(window.max.isBefore(now), isFalse);
    });

    test('starts a little before the range, for a skewed camera clock', () {
      final window = DeviceLibraryMediaSource.arrivalWindowFor(
        tripDayStart,
        now: now,
      );
      expect(
        window.min,
        tripDayStart.subtract(DeviceLibraryMediaSource.arrivalSlack),
      );
    });

    test('is the whole of time when no range is asked for', () {
      final window = DeviceLibraryMediaSource.arrivalWindowFor(null, now: now);
      expect(window.min, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('never excludes a picture the capture range would keep', () {
      // Arrival is at or after capture, so anything captured in range
      // arrived at or after the range's start.
      final window = DeviceLibraryMediaSource.arrivalWindowFor(
        tripDayStart,
        now: now,
      );
      for (final arrival in [
        DateTime(2026, 10, 13, 10, 7), // taken and stored at once
        DateTime(2026, 10, 15, 8), // copied two days later
        now, // copied just now
      ]) {
        expect(
          !arrival.isBefore(window.min) && !arrival.isAfter(window.max),
          isTrue,
          reason: 'arrival $arrival must survive the platform pre-filter',
        );
      }
    });
  });

  group('the capture-time range', () {
    test('keeps a picture taken on the day', () {
      expect(
        DeviceLibraryMediaSource.isCapturedWithin(
          DateTime(2026, 10, 13, 10, 7),
          tripDayStart,
          tripDayEnd,
        ),
        isTrue,
      );
    });

    test('drops one taken earlier, whenever it arrived', () {
      expect(
        DeviceLibraryMediaSource.isCapturedWithin(
          DateTime(2026, 10, 11, 20),
          tripDayStart,
          tripDayEnd,
        ),
        isFalse,
      );
    });

    test('drops one taken later', () {
      expect(
        DeviceLibraryMediaSource.isCapturedWithin(
          DateTime(2026, 10, 14, 0, 0, 1),
          tripDayStart,
          tripDayEnd,
        ),
        isFalse,
      );
    });

    test('includes both bounds', () {
      expect(
        DeviceLibraryMediaSource.isCapturedWithin(
          tripDayStart,
          tripDayStart,
          tripDayEnd,
        ),
        isTrue,
      );
      expect(
        DeviceLibraryMediaSource.isCapturedWithin(
          tripDayEnd,
          tripDayStart,
          tripDayEnd,
        ),
        isTrue,
      );
    });

    test('is open on a side that was not given', () {
      final at = DateTime(2020, 1, 1);
      expect(DeviceLibraryMediaSource.isCapturedWithin(at, null, null), isTrue);
      expect(
        DeviceLibraryMediaSource.isCapturedWithin(at, null, tripDayEnd),
        isTrue,
      );
      expect(
        DeviceLibraryMediaSource.isCapturedWithin(at, tripDayStart, null),
        isFalse,
      );
    });
  });
}
