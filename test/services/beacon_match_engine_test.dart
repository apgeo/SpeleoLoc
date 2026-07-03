import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/beacon/beacon_match_engine.dart';

void main() {
  const idA = 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825/10828/518';
  const idB = 'FFFE2D12-1E4B-0FA4-994E-CEB531F40545/57362/45060';
  final t0 = DateTime(2026, 7, 2, 12, 0, 0);

  BeaconMatchEngine engine({
    int threshold = -75,
    int debounce = 2,
    int windowSec = 5,
    int cooldownSec = 300,
  }) {
    final e = BeaconMatchEngine(
      BeaconDetectionConfig(
        enabled: true,
        rssiThresholdDbm: threshold,
        debounceCount: debounce,
        debounceWindowSec: windowSec,
        cooldownSec: cooldownSec,
      ),
    );
    e.updateRegistrations({idA, idB});
    return e;
  }

  group('BeaconMatchEngine', () {
    test('unregistered identities never trigger', () {
      final e = engine();
      e.updateRegistrations({idB});
      expect(e.observe(idA, -30, t0), isFalse);
      expect(e.observe(idA, -30, t0.add(const Duration(seconds: 1))), isFalse);
      expect(e.observe(idA, -30, t0.add(const Duration(seconds: 2))), isFalse);
    });

    test('sightings below the RSSI threshold are ignored', () {
      final e = engine(threshold: -60);
      expect(e.observe(idA, -70, t0), isFalse);
      expect(e.observe(idA, -61, t0.add(const Duration(seconds: 1))), isFalse);
      // Below-threshold sightings must not count toward the debounce.
      expect(e.observe(idA, -50, t0.add(const Duration(seconds: 2))), isFalse);
      expect(e.observe(idA, -50, t0.add(const Duration(seconds: 3))), isTrue);
    });

    test('rssi 0 (unknown) is ignored', () {
      final e = engine();
      expect(e.observe(idA, 0, t0), isFalse);
      expect(e.observe(idA, 0, t0.add(const Duration(seconds: 1))), isFalse);
    });

    test('triggers on the Nth strong sighting within the window', () {
      final e = engine(debounce: 3, windowSec: 5);
      expect(e.observe(idA, -40, t0), isFalse);
      expect(e.observe(idA, -40, t0.add(const Duration(seconds: 1))), isFalse);
      expect(e.observe(idA, -40, t0.add(const Duration(seconds: 2))), isTrue);
    });

    test('sightings outside the window do not accumulate', () {
      final e = engine(debounce: 2, windowSec: 5);
      expect(e.observe(idA, -40, t0), isFalse);
      // 6 s later — first sighting expired, this restarts the count.
      expect(e.observe(idA, -40, t0.add(const Duration(seconds: 6))), isFalse);
      expect(e.observe(idA, -40, t0.add(const Duration(seconds: 7))), isTrue);
    });

    test('cooldown suppresses re-triggering, then allows again', () {
      final e = engine(debounce: 1, cooldownSec: 300);
      expect(e.observe(idA, -40, t0), isTrue);
      // Storm of sightings during cooldown — all silent.
      for (var s = 1; s < 300; s += 30) {
        expect(e.observe(idA, -20, t0.add(Duration(seconds: s))), isFalse);
      }
      // After cooldown a fresh debounce cycle triggers again.
      expect(e.observe(idA, -40, t0.add(const Duration(seconds: 301))), isTrue);
    });

    test('identities are tracked independently', () {
      final e = engine(debounce: 2, cooldownSec: 300);
      expect(e.observe(idA, -40, t0), isFalse);
      expect(e.observe(idB, -40, t0), isFalse);
      expect(e.observe(idA, -40, t0.add(const Duration(seconds: 1))), isTrue);
      // idA in cooldown; idB still completes its own debounce.
      expect(e.observe(idB, -40, t0.add(const Duration(seconds: 1))), isTrue);
      expect(e.observe(idA, -40, t0.add(const Duration(seconds: 2))), isFalse);
    });

    test('removing a registration clears its state', () {
      final e = engine(debounce: 2);
      expect(e.observe(idA, -40, t0), isFalse);
      e.updateRegistrations({idB});
      e.updateRegistrations({idA, idB});
      // State was dropped on unregister — needs a full debounce again.
      expect(e.observe(idA, -40, t0.add(const Duration(seconds: 1))), isFalse);
      expect(e.observe(idA, -40, t0.add(const Duration(seconds: 2))), isTrue);
    });

    test('reset clears cooldowns', () {
      final e = engine(debounce: 1, cooldownSec: 300);
      expect(e.observe(idA, -40, t0), isTrue);
      e.reset();
      expect(e.observe(idA, -40, t0.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('BeaconDetectionConfig', () {
    test('json round-trip preserves all fields', () {
      const cfg = BeaconDetectionConfig(
        enabled: true,
        rssiThresholdDbm: -62,
        debounceCount: 3,
        debounceWindowSec: 7,
        cooldownSec: 120,
        autoOpenPlace: true,
        backgroundEnabled: true,
        backgroundScanIntervalSec: 45,
      );
      final back = BeaconDetectionConfig.fromJson(cfg.toJson());
      expect(back.enabled, cfg.enabled);
      expect(back.rssiThresholdDbm, cfg.rssiThresholdDbm);
      expect(back.debounceCount, cfg.debounceCount);
      expect(back.debounceWindowSec, cfg.debounceWindowSec);
      expect(back.cooldownSec, cfg.cooldownSec);
      expect(back.autoOpenPlace, cfg.autoOpenPlace);
      expect(back.backgroundEnabled, cfg.backgroundEnabled);
      expect(back.backgroundScanIntervalSec, cfg.backgroundScanIntervalSec);
    });

    test('fromJson falls back to defaults for missing keys', () {
      final cfg = BeaconDetectionConfig.fromJson(const {});
      expect(cfg.enabled, isFalse);
      expect(cfg.rssiThresholdDbm, -75);
      expect(cfg.debounceCount, 2);
      expect(cfg.cooldownSec, 300);
      expect(cfg.autoOpenPlace, isFalse);
      expect(cfg.backgroundEnabled, isFalse);
      expect(cfg.backgroundScanIntervalSec, 30);
    });
  });
}
