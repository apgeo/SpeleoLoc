import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/beacon/shared_ble_scan.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_advertisement_parser.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_scan_service.dart';

import '../support/fake_ble_scan_platform.dart';

/// The "valid data" vector of the Ruuvi data format 5 specification.
const _ruuviPayload = [
  0x05, 0x12, 0xFC, 0x53, 0x94, 0xC3, 0x7C, 0x00, 0x04, 0xFF, 0xFC, 0x04, //
  0x0C, 0xAC, 0x36, 0x42, 0x00, 0xCD, 0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F,
];

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeBleScanPlatform platform;
  late RuuviScanService ruuvi;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 3, 1, 10);
    platform = FakeBleScanPlatform();
    ruuvi = RuuviScanService(
      scan: SharedBleScan(platform: platform, clock: () => now),
    );
  });

  DateTime later(int ms) => now = now.add(Duration(milliseconds: ms));

  test('a tag that stopped advertising is not seen again when another '
      'device advertises', () async {
    final sightings = <RuuviSighting>[];
    final sub = ruuvi.sightings.listen(sightings.add);
    await _settle();

    final heardAt = later(10);
    final tag = scanResult(
      'CB:B8:33:4C:88:4F',
      at: heardAt,
      rssi: -70,
      manufacturerData: {ruuviCompanyId: _ruuviPayload},
    );
    platform.emit([tag]);
    // The tag is out of range; a companion's phone advertises within the
    // debounce window and the plugin re-sends the tag's old entry with it.
    platform.emit([tag, scanResult('11:22:33:44:55:66', at: later(2000))]);
    await _settle();

    expect(sightings, hasLength(1));
    expect(sightings.single.identity, 'RUUVI/CB:B8:33:4C:88:4F');
    expect(sightings.single.seenAt, heardAt);
    await sub.cancel();
  });
}
