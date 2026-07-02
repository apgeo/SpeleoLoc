import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/beacon/bp1003_advertisement_parser.dart';

/// Test vectors taken verbatim from the vendor document
/// `resource_docs/ble_tags/Beacon Protocol BP1003v1.02 ...pdf`.
void main() {
  // Manufacturer payload after the 0x004C company ID:
  // type 0x02, len 0x15, UUID FDA50693..., major 0x2A40, minor 0x0001,
  // measured power 0xC3 (-61 dBm).
  const iBeaconPayload = [
    0x02, 0x15, //
    0xFD, 0xA5, 0x06, 0x93, 0xA4, 0xE2, 0x4F, 0xB1, //
    0xAF, 0xCF, 0xC6, 0xEB, 0x07, 0x64, 0x78, 0x25, //
    0x2A, 0x40, // major
    0x00, 0x01, // minor
    0xC3, // RSSI@1m
  ];

  // Service data value for UUID 0x4B4C with the UUID prefix stripped:
  // battery 0x0CD7 (3287 mV), interval 0x08 (800 ms), tx 0x00 (0 dBm),
  // MAC F0:C8:90:02:10:9B, status 0xA5, temp/hum 0x00 0x1C 0x5D 0x26
  // (28.93 °C, 38 %).
  const serviceDataPayload = [
    0x0C, 0xD7, //
    0x08, //
    0x00, //
    0xF0, 0xC8, 0x90, 0x02, 0x10, 0x9B, //
    0xA5, //
    0x00, 0x1C, 0x5D, 0x26, //
  ];

  group('IBeaconFrame.parse', () {
    test('decodes the PDF advertising example', () {
      final frame = IBeaconFrame.parse(iBeaconPayload);
      expect(frame, isNotNull);
      expect(frame!.proximityUuid, honeyCommDefaultProximityUuid);
      expect(frame.major, 0x2A40); // 10816
      expect(frame.minor, 1);
      expect(frame.measuredPower, -61);
      expect(frame.identity,
          'FDA50693-A4E2-4FB1-AFCF-C6EB07647825/10816/1');
    });

    test('rejects non-iBeacon manufacturer payloads', () {
      expect(IBeaconFrame.parse(null), isNull);
      expect(IBeaconFrame.parse([]), isNull);
      expect(IBeaconFrame.parse([0x01, 0x15, ...List.filled(21, 0)]), isNull);
      expect(IBeaconFrame.parse(iBeaconPayload.sublist(0, 22)), isNull);
    });

    test('reads from a manufacturer-data map keyed by company ID', () {
      final frame = IBeaconFrame.fromManufacturerData({
        0x0059: [1, 2, 3], // Nordic, ignored
        iBeaconCompanyId: iBeaconPayload,
      });
      expect(frame?.major, 0x2A40);
      expect(IBeaconFrame.fromManufacturerData({0x0059: iBeaconPayload}),
          isNull);
    });
  });

  group('Bp1003ServiceData.parse', () {
    test('decodes the PDF scan-response example', () {
      final sd = Bp1003ServiceData.parse(serviceDataPayload);
      expect(sd, isNotNull);
      expect(sd!.batteryMv, 3287);
      expect(sd.broadcastIntervalMs, 800);
      expect(sd.txPowerDbm, 0);
      expect(sd.macAddress, 'F0:C8:90:02:10:9B');
      expect(sd.statusFlags, 0xA5);
      expect(sd.rawTempHumidity, [0x00, 0x1C, 0x5D, 0x26]);
      expect(sd.expectedLocalName, 'K02109b');
    });

    test('status flag getters follow the documented bit layout', () {
      final sd = Bp1003ServiceData.parse(serviceDataPayload)!;
      // 0xA5 = 1010 0101
      expect(sd.isConnectable, isTrue); // bit4 == 0
      expect(sd.hasAccelerometer, isFalse); // bit3
      expect(sd.hasAdaptiveInterval, isTrue); // bit2
      expect(sd.hasTempHumiditySensor, isFalse); // bit1
      expect(sd.tempHumidityEnabled, isTrue); // bit0
    });

    test('temperature/humidity gated on sensor flags', () {
      // 0xA5 has bit1 (sensor present) clear → no temperature exposed.
      final noSensor = Bp1003ServiceData.parse(serviceDataPayload)!;
      expect(noSensor.temperatureC, isNull);
      expect(noSensor.humidityPct, isNull);

      // Same payload with bits 1+0 set → 28.93 °C / 38 %.
      final withSensor = Bp1003ServiceData.parse(
          [...serviceDataPayload]..[10] = 0xA7)!;
      expect(withSensor.temperatureC, closeTo(28.93, 0.001));
      expect(withSensor.humidityPct, 38);
    });

    test('negative temperatures extend away from zero', () {
      final payload = [...serviceDataPayload]
        ..[10] = 0x03 // sensor present + enabled
        ..[12] = 0xFB // -5
        ..[13] = 50;
      final sd = Bp1003ServiceData.parse(payload)!;
      expect(sd.temperatureC, closeTo(-5.50, 0.001));
    });

    test('accepts a value with the 4C4B UUID prefix still present', () {
      final sd =
          Bp1003ServiceData.parse([0x4C, 0x4B, ...serviceDataPayload]);
      expect(sd?.batteryMv, 3287);
      expect(sd?.macAddress, 'F0:C8:90:02:10:9B');
    });

    test('rejects other lengths', () {
      expect(Bp1003ServiceData.parse(null), isNull);
      expect(Bp1003ServiceData.parse([]), isNull);
      expect(
          Bp1003ServiceData.parse(serviceDataPayload.sublist(0, 14)), isNull);
      expect(Bp1003ServiceData.parse([...serviceDataPayload, 0x00]), isNull);
    });

    test('fromServiceData matches short and 128-bit expanded keys', () {
      expect(
          Bp1003ServiceData.fromServiceData({'4b4c': serviceDataPayload})
              ?.batteryMv,
          3287);
      expect(
          Bp1003ServiceData.fromServiceData({
            '00004b4c-0000-1000-8000-00805f9b34fb': serviceDataPayload
          })?.batteryMv,
          3287);
      expect(
          Bp1003ServiceData.fromServiceData({'180f': [42]}), isNull);
    });
  });

  group('bp1003LocalNamePattern', () {
    test('matches vendor default names and nothing else', () {
      expect(bp1003LocalNamePattern.hasMatch('K02109b'), isTrue);
      expect(bp1003LocalNamePattern.hasMatch('KABCDEF'), isTrue);
      expect(bp1003LocalNamePattern.hasMatch('K02109'), isFalse);
      expect(bp1003LocalNamePattern.hasMatch('K02109bb'), isFalse);
      expect(bp1003LocalNamePattern.hasMatch('X02109b'), isFalse);
      expect(bp1003LocalNamePattern.hasMatch('K02109g'), isFalse);
    });
  });
}
