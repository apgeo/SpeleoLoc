import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/beacon/shared_ble_scan.dart';

import '../support/fake_ble_scan_platform.dart';

const _ruuviId = 0x0499;
const _otherId = 0x004C;

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeBleScanPlatform platform;
  late SharedBleScan scan;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 3, 1, 10);
    platform = FakeBleScanPlatform();
    scan = SharedBleScan(platform: platform, clock: () => now);
  });

  DateTime later(int ms) => now = now.add(Duration(milliseconds: ms));

  group('fresh advertisements', () {
    test('passes each advertisement on once although the plugin re-sends '
        'the whole list', () async {
      final seen = <String>[];
      final sub = scan.advertisements().listen(
        (r) => seen.add(r.device.remoteId.str),
      );
      await _settle();

      final a = scanResult('AA', at: later(10));
      platform.emit([a]);
      final b = scanResult('BB', at: later(10));
      // An unrelated device advertises: the plugin sends AA again with it.
      platform.emit([a, b]);
      await _settle();

      expect(seen, ['AA', 'BB']);
      await sub.cancel();
    });

    test('a new advertisement from the same device counts again', () async {
      final seen = <DateTime>[];
      final sub = scan.advertisements().listen((r) => seen.add(r.timeStamp));
      await _settle();

      final first = later(10);
      platform.emit([scanResult('AA', at: first)]);
      final second = later(1300);
      platform.emit([scanResult('AA', at: second)]);
      await _settle();

      expect(seen, [first, second]);
      await sub.cancel();
    });

    test('ignores the list replayed from an earlier scan', () async {
      var sub = scan.advertisements().listen((_) {});
      await _settle();
      final lastBurst = [scanResult('AA', at: later(10))];
      platform.emit(lastBurst);
      await _settle();
      await sub.cancel();
      await _settle();

      // The next burst starts a minute later; the plugin replays the last
      // burst's list to the new listener first.
      later(60000);
      final seen = <DateTime>[];
      sub = scan.advertisements().listen((r) => seen.add(r.timeStamp));
      await _settle();
      // The replay can also land after the new scan has started.
      platform.emit(lastBurst);
      await _settle();
      expect(seen, isEmpty);

      final fresh = later(10);
      platform.emit([scanResult('AA', at: fresh)]);
      await _settle();
      expect(seen, [fresh]);
      await sub.cancel();
    });
  });

  group('scan ownership', () {
    test('scans only while someone listens', () async {
      final sub = scan.advertisements().listen((_) {});
      await _settle();
      expect(platform.isScanning, isTrue);

      await sub.cancel();
      await _settle();
      expect(platform.isScanning, isFalse);
      expect(platform.stopCount, 1);
    });

    test('filters the platform scan to the manufacturers asked for', () async {
      final seen = <String>[];
      final sub = scan
          .advertisements(manufacturerIds: {_ruuviId})
          .listen((r) => seen.add(r.device.remoteId.str));
      await _settle();
      expect(platform.currentFilter, [_ruuviId]);

      platform.emit([
        scanResult(
          'RU',
          at: later(10),
          manufacturerData: {
            _ruuviId: [5],
          },
        ),
        scanResult(
          'XX',
          at: later(10),
          manufacturerData: {
            _otherId: [1],
          },
        ),
      ]);
      await _settle();
      expect(seen, ['RU']);
      await sub.cancel();
    });

    test('an unfiltered listener widens the scan, and the filtered one keeps '
        'receiving after it leaves', () async {
      final ruuvi = <String>[];
      final ruuviSub = scan
          .advertisements(manufacturerIds: {_ruuviId})
          .listen((r) => ruuvi.add(r.device.remoteId.str));
      await _settle();

      final raw = <String>[];
      final rawSub = scan.advertisements().listen(
        (r) => raw.add(r.device.remoteId.str),
      );
      await _settle();
      expect(platform.currentFilter, isEmpty);

      platform.emit([
        scanResult(
          'XX',
          at: later(10),
          manufacturerData: {
            _otherId: [1],
          },
        ),
      ]);
      await _settle();
      expect(raw, ['XX']);
      expect(ruuvi, isEmpty);

      await rawSub.cancel();
      await _settle();
      expect(platform.isScanning, isTrue);
      expect(platform.currentFilter, [_ruuviId]);

      platform.emit([
        scanResult(
          'RU',
          at: later(10),
          manufacturerData: {
            _ruuviId: [5],
          },
        ),
      ]);
      await _settle();
      expect(ruuvi, ['RU']);
      await ruuviSub.cancel();
    });

    test('waits for Bluetooth and resumes when it comes back on', () async {
      platform.adapter = fbp.BluetoothAdapterState.unknown;
      final sub = scan.advertisements().listen((_) {});
      await _settle();
      expect(platform.startedFilters, isEmpty);

      platform.setAdapter(fbp.BluetoothAdapterState.on);
      await _settle();
      expect(platform.startedFilters, hasLength(1));

      platform.setAdapter(fbp.BluetoothAdapterState.off);
      await _settle();
      platform.setAdapter(fbp.BluetoothAdapterState.on);
      await _settle();
      expect(platform.startedFilters, hasLength(2));
      expect(platform.isScanning, isTrue);
      await sub.cancel();
    });
  });
}
