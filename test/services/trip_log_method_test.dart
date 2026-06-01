import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/trip_log_method.dart';

void main() {
  group('TripLogMethod.fromId', () {
    test('returns the matching enum for every valid id', () {
      for (final m in TripLogMethod.values) {
        expect(TripLogMethod.fromId(m.id), same(m));
      }
    });

    test('null id falls back to classic (default fallback)', () {
      expect(TripLogMethod.fromId(null), TripLogMethod.classic);
    });

    test('unknown id falls back to classic (default fallback)', () {
      expect(TripLogMethod.fromId('not-a-method'), TripLogMethod.classic);
      expect(TripLogMethod.fromId(''), TripLogMethod.classic);
    });

    test('explicit fallback is honoured for null and unknown', () {
      expect(
        TripLogMethod.fromId(null, fallback: TripLogMethod.raw),
        TripLogMethod.raw,
      );
      expect(
        TripLogMethod.fromId('bogus', fallback: TripLogMethod.narrative),
        TripLogMethod.narrative,
      );
    });

    test('stable ids are NOT changed (persisted in DB)', () {
      // These ids are written to `configurations.value`. Changing any of
      // them silently invalidates every existing install. If this test
      // fails, you almost certainly want a migration, not a rename.
      expect(TripLogMethod.raw.id, 'raw');
      expect(TripLogMethod.classic.id, 'classic');
      expect(TripLogMethod.journal.id, 'journal');
      expect(TripLogMethod.narrative.id, 'narrative');
    });
  });
}
