import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_advertisement_parser.dart';

/// Test vectors taken verbatim from the Ruuvi data format 5 specification
/// (github.com/ruuvi/ruuvi-sensor-protocols, "Test vectors" section).
void main() {
  // "Valid data": 24.3 °C, 53.49 %, 100044 Pa, acc (4, -4, 1036) mG,
  // battery 2977 mV, tx +4 dBm, movement 66, sequence 205,
  // MAC CB:B8:33:4C:88:4F.
  const validPayload = [
    0x05, //
    0x12, 0xFC, // temperature
    0x53, 0x94, // humidity
    0xC3, 0x7C, // pressure
    0x00, 0x04, // acceleration X
    0xFF, 0xFC, // acceleration Y
    0x04, 0x0C, // acceleration Z
    0xAC, 0x36, // power info
    0x42, // movement counter
    0x00, 0xCD, // measurement sequence
    0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F, // MAC
  ];

  // "Maximum values" vector.
  const maxPayload = [
    0x05, //
    0x7F, 0xFF, //
    0xFF, 0xFE, //
    0xFF, 0xFE, //
    0x7F, 0xFF, //
    0x7F, 0xFF, //
    0x7F, 0xFF, //
    0xFF, 0xDE, //
    0xFE, //
    0xFF, 0xFE, //
    0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F, //
  ];

  // "Minimum values" vector.
  const minPayload = [
    0x05, //
    0x80, 0x01, //
    0x00, 0x00, //
    0x00, 0x00, //
    0x80, 0x01, //
    0x80, 0x01, //
    0x80, 0x01, //
    0x00, 0x00, //
    0x00, //
    0x00, 0x00, //
    0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F, //
  ];

  // "Invalid values" vector: every field reports its not-available marker.
  const invalidPayload = [
    0x05, //
    0x80, 0x00, //
    0xFF, 0xFF, //
    0xFF, 0xFF, //
    0x80, 0x00, //
    0x80, 0x00, //
    0x80, 0x00, //
    0xFF, 0xFF, //
    0xFF, //
    0xFF, 0xFF, //
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, //
  ];

  group('RuuviAdvertisement.parse', () {
    test('decodes the specification "valid data" vector', () {
      final adv = RuuviAdvertisement.parse(validPayload);
      expect(adv, isNotNull);
      expect(adv!.temperatureC, closeTo(24.3, 0.0001));
      expect(adv.humidityPct, closeTo(53.49, 0.0001));
      expect(adv.pressureHpa, closeTo(1000.44, 0.0001));
      expect(adv.accelerationXMg, 4);
      expect(adv.accelerationYMg, -4);
      expect(adv.accelerationZMg, 1036);
      expect(adv.batteryMv, 2977);
      expect(adv.txPowerDbm, 4);
      expect(adv.movementCounter, 66);
      expect(adv.measurementSequence, 205);
      expect(adv.macAddress, 'CB:B8:33:4C:88:4F');
      expect(adv.identity, 'RUUVI/CB:B8:33:4C:88:4F');
      expect(adv.inferredModel, RuuviModel.ruuviTag);
      expect(adv.isLowBattery, isFalse);
    });

    test('decodes the "maximum values" vector', () {
      final adv = RuuviAdvertisement.parse(maxPayload)!;
      expect(adv.temperatureC, closeTo(163.835, 0.0001));
      expect(adv.humidityPct, closeTo(163.835, 0.0001));
      expect(adv.pressureHpa, closeTo(1155.34, 0.0001));
      expect(adv.accelerationXMg, 32767);
      expect(adv.batteryMv, 3646);
      expect(adv.txPowerDbm, 20);
      expect(adv.movementCounter, 254);
      expect(adv.measurementSequence, 65534);
    });

    test('decodes the "minimum values" vector', () {
      final adv = RuuviAdvertisement.parse(minPayload)!;
      expect(adv.temperatureC, closeTo(-163.835, 0.0001));
      expect(adv.humidityPct, 0);
      expect(adv.pressureHpa, closeTo(500.0, 0.0001));
      expect(adv.accelerationXMg, -32767);
      expect(adv.batteryMv, 1600);
      expect(adv.txPowerDbm, -40);
      expect(adv.movementCounter, 0);
      expect(adv.measurementSequence, 0);
    });

    test('maps every not-available marker to null', () {
      final adv = RuuviAdvertisement.parse(invalidPayload)!;
      expect(adv.temperatureC, isNull);
      expect(adv.humidityPct, isNull);
      expect(adv.pressureHpa, isNull);
      expect(adv.accelerationXMg, isNull);
      expect(adv.accelerationYMg, isNull);
      expect(adv.accelerationZMg, isNull);
      expect(adv.batteryMv, isNull);
      expect(adv.txPowerDbm, isNull);
      expect(adv.movementCounter, isNull);
      expect(adv.measurementSequence, isNull);
      expect(adv.macAddress, isNull);
      expect(adv.identity, isNull);
      expect(adv.isLowBattery, isFalse);
    });

    test('rejects non-format-5 payloads', () {
      expect(RuuviAdvertisement.parse(null), isNull);
      expect(RuuviAdvertisement.parse([]), isNull);
      expect(RuuviAdvertisement.parse(validPayload.sublist(0, 23)), isNull);
      expect(
        RuuviAdvertisement.parse([0x03, ...validPayload.sublist(1)]),
        isNull,
      );
    });
  });

  group('RuuviAdvertisement model inference', () {
    test('pressure unavailable but humidity valid is a Pro 3-in-1', () {
      final payload = [...validPayload]
        ..[5] = 0xFF
        ..[6] = 0xFF;
      final adv = RuuviAdvertisement.parse(payload)!;
      expect(adv.pressureHpa, isNull);
      expect(adv.inferredModel, RuuviModel.ruuviTagPro3in1);
    });

    test('pressure and humidity unavailable is a Pro 2-in-1', () {
      final payload = [...validPayload]
        ..[3] = 0xFF
        ..[4] = 0xFF
        ..[5] = 0xFF
        ..[6] = 0xFF;
      expect(
        RuuviAdvertisement.parse(payload)!.inferredModel,
        RuuviModel.ruuviTagPro2in1,
      );
    });
  });

  group('RuuviAdvertisement.isLowBattery', () {
    test('flags advertised voltage below the threshold', () {
      // Battery bits 800 → 2400 mV, tx bits 22 → +4 dBm.
      const powerRaw = (800 << 5) | 22;
      final payload = [...validPayload]
        ..[13] = powerRaw >> 8
        ..[14] = powerRaw & 0xFF;
      final adv = RuuviAdvertisement.parse(payload)!;
      expect(adv.batteryMv, 2400);
      expect(adv.txPowerDbm, 4);
      expect(adv.isLowBattery, isTrue);
    });
  });

  group('RuuviAdvertisement.fromManufacturerData', () {
    test('reads from a manufacturer-data map keyed by company ID', () {
      final adv = RuuviAdvertisement.fromManufacturerData({
        0x004C: [0x02, 0x15], // Apple, ignored
        ruuviCompanyId: validPayload,
      });
      expect(adv?.macAddress, 'CB:B8:33:4C:88:4F');
      expect(
        RuuviAdvertisement.fromManufacturerData({0x004C: validPayload}),
        isNull,
      );
    });
  });
}
