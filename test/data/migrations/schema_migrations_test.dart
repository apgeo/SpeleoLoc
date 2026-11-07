import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/migrations/migrations.dart';

/// Pure-logic tests for the migration registry: ordering, version
/// coverage, and the per-class `shouldApply` rules. These complement
/// the end-to-end tests that run the whole ladder from each historical
/// schema.
void main() {
  group('schemaMigrations registry', () {
    test('is ordered strictly by toVersion ascending', () {
      final versions = schemaMigrations.map((m) => m.toVersion).toList();
      final sorted = [...versions]..sort();
      expect(versions, sorted, reason: 'registry must be in ascending order');
      expect(
        versions.toSet().length,
        versions.length,
        reason: 'no duplicate toVersion values',
      );
    });

    test('covers every version from 7 to the latest contiguously', () {
      // 35 and 36 were stamped only by development builds; their changes
      // are part of the single step to 37.
      const foldedSteps = {37: 34};
      final versions = schemaMigrations.map((m) => m.toVersion).toList();
      expect(versions.first, 7);
      for (var i = 1; i < versions.length; i++) {
        expect(
          versions[i - 1],
          foldedSteps[versions[i]] ?? versions[i] - 1,
          reason: 'gap between v${versions[i - 1]} and v${versions[i]}',
        );
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
      // The two first steps choose their own starting versions; every later
      // one applies from any version below its own.
      final defaults = schemaMigrations.skipWhile((m) => m.toVersion <= 8);
      expect(defaults, isNotEmpty);
      for (final m in defaults) {
        for (var from = 0; from < m.toVersion; from++) {
          expect(
            m.shouldApply(from),
            isTrue,
            reason: '${m.runtimeType} should apply from v$from',
          );
        }
        expect(
          m.shouldApply(m.toVersion),
          isFalse,
          reason: '${m.runtimeType} must not re-apply at its target version',
        );
        expect(
          m.shouldApply(m.toVersion + 1),
          isFalse,
          reason: '${m.runtimeType} must not run when already past target',
        );
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
      // V7->V8 is gated off (from != 7), and V8..V21 run as no-op-ish
      // idempotent backfills against the already-current schema.
      expect(appliedFor(5), [
        7,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        37,
      ]);
      expect(appliedFor(6), [
        7,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        37,
      ]);

      // From v7: every migration from v8 onward fires.
      expect(appliedFor(7), [
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        37,
      ]);

      // Mid-ladder upgrade: only the remaining steps fire.
      expect(appliedFor(10), [
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        37,
      ]);
      expect(appliedFor(16), [
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        37,
      ]);
      expect(appliedFor(17), [
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        37,
      ]);
      expect(appliedFor(18), [
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        37,
      ]);

      expect(appliedFor(19), [
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        37,
      ]);
      expect(appliedFor(20), [
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        37,
      ]);
      expect(appliedFor(21), [
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        37,
      ]);
      expect(appliedFor(22), [
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        37,
      ]);
      expect(appliedFor(23), [24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 37]);
      expect(appliedFor(24), [25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 37]);
      expect(appliedFor(25), [26, 27, 28, 29, 30, 31, 32, 33, 34, 37]);
      expect(appliedFor(26), [27, 28, 29, 30, 31, 32, 33, 34, 37]);
      expect(appliedFor(27), [28, 29, 30, 31, 32, 33, 34, 37]);
      expect(appliedFor(28), [29, 30, 31, 32, 33, 34, 37]);

      expect(appliedFor(29), [30, 31, 32, 33, 34, 37]);
      expect(appliedFor(30), [31, 32, 33, 34, 37]);
      expect(appliedFor(31), [32, 33, 34, 37]);
      expect(appliedFor(32), [33, 34, 37]);

      expect(appliedFor(33), [34, 37]);
      // Databases development builds stamped 35 or 36 take the same step.
      expect(appliedFor(34), [37]);
      expect(appliedFor(35), [37]);
      expect(appliedFor(36), [37]);

      // Already current: nothing fires.
      expect(appliedFor(37), isEmpty);
    });
  });
}
