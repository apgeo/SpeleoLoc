import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/migrations/migrations.dart';
import 'package:speleoloc/data/source/database/migrations/schema_migration.dart';

/// Pure-logic tests for the migration registry: ordering, version
/// coverage, and the per-class `shouldApply` rules. These complement
/// the end-to-end `legacy_v6_migration_test.dart` (which runs the
/// whole ladder against a real v6 SQLite fixture).
void main() {
  group('schemaMigrations registry', () {
    test('is ordered strictly by toVersion ascending', () {
      final versions = schemaMigrations.map((m) => m.toVersion).toList();
      final sorted = [...versions]..sort();
      expect(versions, sorted, reason: 'registry must be in ascending order');
      expect(versions.toSet().length, versions.length,
          reason: 'no duplicate toVersion values');
    });

    test('covers every version from 7 to the latest contiguously', () {
      final versions = schemaMigrations.map((m) => m.toVersion).toList();
      expect(versions.first, 7);
      for (var i = 1; i < versions.length; i++) {
        expect(versions[i], versions[i - 1] + 1,
            reason: 'gap between v${versions[i - 1]} and v${versions[i]}');
      }
    });

    test('contains exactly one instance of each migration class', () {
      final types = schemaMigrations.map((m) => m.runtimeType).toSet();
      expect(types.length, schemaMigrations.length);
    });
  });

  group('SchemaMigration.shouldApply defaults', () {
    test('LegacyV6ToV7Migration applies for from < 7', () {
      const m = LegacyV6ToV7Migration();
      expect(m.shouldApply(0), isTrue);
      expect(m.shouldApply(5), isTrue);
      expect(m.shouldApply(6), isTrue);
      expect(m.shouldApply(7), isFalse);
      expect(m.shouldApply(14), isFalse);
    });

    test('V7ToV8Migration only fires when from == 7 (overrides default)', () {
      const m = V7ToV8Migration();
      // The v6 -> v7 path calls createAll() at the latest schema, so this
      // step must NOT re-apply for from < 7.
      expect(m.shouldApply(5), isFalse);
      expect(m.shouldApply(6), isFalse);
      expect(m.shouldApply(7), isTrue);
      expect(m.shouldApply(8), isFalse);
    });

    test('non-overriding migrations use default from < toVersion', () {
      const cases = <(SchemaMigration, int)>[
        (V8ToV9Migration(), 9),
        (V9ToV10Migration(), 10),
        (V10ToV11Migration(), 11),
        (V11ToV12Migration(), 12),
        (V12ToV13Migration(), 13),
        (V13ToV14Migration(), 14),
      ];
      for (final (m, v) in cases) {
        expect(m.toVersion, v);
        expect(m.shouldApply(v - 1), isTrue,
            reason: '${m.runtimeType} should apply when from == toVersion-1');
        expect(m.shouldApply(v), isFalse,
            reason: '${m.runtimeType} must not re-apply at its target version');
        expect(m.shouldApply(v + 1), isFalse,
            reason: '${m.runtimeType} must not run when already past target');
      }
    });

    test('end-to-end ladder semantics for typical from values', () {
      // Walking the same algorithm the engine uses, check which steps
      // fire for representative starting versions.
      List<int> appliedFor(int from) => [
            for (final m in schemaMigrations)
              if (m.shouldApply(from)) m.toVersion,
          ];

      // Pre-v7: legacy step runs (calls createAll at the latest schema),
      // V7->V8 is gated off (from != 7), and V8..V14 run as no-op-ish
      // idempotent backfills against the already-current schema.
      expect(appliedFor(5), [7, 9, 10, 11, 12, 13, 14]);
      expect(appliedFor(6), [7, 9, 10, 11, 12, 13, 14]);

      // From v7: every migration from v8 onward fires.
      expect(appliedFor(7), [8, 9, 10, 11, 12, 13, 14]);

      // Mid-ladder upgrade: only the remaining steps fire.
      expect(appliedFor(10), [11, 12, 13, 14]);
      expect(appliedFor(13), [14]);

      // Already current: nothing fires.
      expect(appliedFor(14), isEmpty);
    });
  });
}
