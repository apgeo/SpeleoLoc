import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/map/tile_failure_monitor.dart';

void main() {
  late DateTime now;
  late TileFailureMonitor monitor;

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    monitor = TileFailureMonitor(
      threshold: 3,
      window: const Duration(seconds: 10),
      now: () => now,
    );
  });

  test('stays quiet below the threshold', () {
    expect(monitor.record(), isFalse);
    expect(monitor.record(), isFalse);
  });

  test('trips once the threshold is reached inside the window', () {
    monitor.record();
    now = now.add(const Duration(seconds: 4));
    monitor.record();
    now = now.add(const Duration(seconds: 4));
    expect(monitor.record(), isTrue);
  });

  test('scattered failures never add up to an outage', () {
    for (var i = 0; i < 10; i++) {
      expect(monitor.record(), isFalse);
      now = now.add(const Duration(seconds: 6));
    }
  });

  test('reset forgets earlier failures', () {
    monitor.record();
    monitor.record();
    monitor.reset();
    expect(monitor.record(), isFalse);
  });

  test('is quiet until a failure, and again once the window has passed', () {
    expect(monitor.quiet, isTrue);
    monitor.record();
    expect(monitor.quiet, isFalse);
    now = now.add(const Duration(seconds: 9));
    expect(monitor.quiet, isFalse);
    now = now.add(const Duration(seconds: 2));
    expect(monitor.quiet, isTrue);
  });
}
