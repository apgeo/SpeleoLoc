import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/clock.dart';

void main() {
  group('SystemClock', () {
    test('now() and nowMs() are close to the real DateTime.now()', () {
      const clock = SystemClock();
      final before = DateTime.now().millisecondsSinceEpoch;
      final ms = clock.nowMs();
      final after = DateTime.now().millisecondsSinceEpoch;
      expect(ms, inInclusiveRange(before, after));
      expect(clock.now().millisecondsSinceEpoch, closeTo(ms, 1000));
    });
  });

  group('FakeClock', () {
    test('reports the initial time', () {
      final t0 = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final clock = FakeClock(t0);
      expect(clock.now(), t0);
      expect(clock.nowMs(), t0.millisecondsSinceEpoch);
    });

    test('advance shifts time forward by the given duration', () {
      final t0 = DateTime.utc(2026, 1, 1);
      final clock = FakeClock(t0);
      clock.advance(const Duration(seconds: 90));
      expect(clock.now(), t0.add(const Duration(seconds: 90)));
      clock.advance(const Duration(milliseconds: 500));
      expect(clock.nowMs(), t0.millisecondsSinceEpoch + 90_500);
    });

    test('set replaces the current time absolutely', () {
      final clock = FakeClock(DateTime.utc(2020));
      final t = DateTime.utc(2030, 6, 15, 9, 0, 0);
      clock.set(t);
      expect(clock.now(), t);
    });

    test('multiple advances accumulate', () {
      final t0 = DateTime.utc(2026, 1, 1);
      final clock = FakeClock(t0);
      for (var i = 0; i < 10; i++) {
        clock.advance(const Duration(minutes: 1));
      }
      expect(clock.now(), t0.add(const Duration(minutes: 10)));
    });
  });
}
