/// Decoder for Ruuvi tag BLE advertisements, data format 5 ("RAWv2").
///
/// Covers RuuviTag (temp/humidity/pressure/motion) and RuuviTag Pro
/// (rugged; the 3-in-1 variant has no pressure sensor). Both broadcast
/// manufacturer-specific data under Ruuvi's company ID with the same
/// format-5 layout; sensors a model lacks report a per-field "invalid"
/// marker, which this decoder maps to null. The tag's MAC address is part
/// of the payload, so identity works on iOS where the OS hides real
/// peripheral MACs.
///
/// Pure Dart — no Flutter or plugin imports — so it is unit-testable and
/// reusable by the raw-scan diagnostics, the picker and the detection
/// service.
library;

/// Ruuvi Innovations' Bluetooth company identifier.
const int ruuviCompanyId = 0x0499;

/// Format byte of the RAWv2 payload.
const int ruuviDataFormat5 = 0x05;

/// Prefix of the registration identity string, ahead of the MAC. Distinct
/// from iBeacon `UUID/major/minor` identities by construction.
const String ruuviIdentityPrefix = 'RUUVI/';

/// Advertised battery voltage below which a tag counts as low-battery.
const int ruuviLowBatteryMv = 2500;

/// Ruuvi tag model, inferred from which sensor fields are valid.
enum RuuviModel {
  ruuviTag('RuuviTag'),
  ruuviTagPro3in1('RuuviTag Pro 3in1'),
  ruuviTagPro2in1('RuuviTag Pro 2in1');

  const RuuviModel(this.label);

  /// Product name as stored in the beacon registration's `model` column.
  final String label;
}

/// Decoded format-5 manufacturer payload. Sensor fields are null when the
/// tag reported the field's "not available" marker.
class RuuviAdvertisement {
  final double? temperatureC;
  final double? humidityPct;

  /// Air pressure in hPa (wire value is Pa with a -50000 offset).
  final double? pressureHpa;

  /// Acceleration per axis in mG.
  final int? accelerationXMg;
  final int? accelerationYMg;
  final int? accelerationZMg;

  /// Battery voltage in millivolts (1600–3646).
  final int? batteryMv;

  /// Transmit power in dBm.
  final int? txPowerDbm;

  /// Incremented on motion, wraps at 254.
  final int? movementCounter;

  /// Advertisement counter, wraps at 65534 — sequence gaps estimate
  /// packet loss.
  final int? measurementSequence;

  /// MAC address as `AA:BB:CC:DD:EE:FF` (uppercase); null when the tag
  /// masks it.
  final String? macAddress;

  const RuuviAdvertisement({
    required this.temperatureC,
    required this.humidityPct,
    required this.pressureHpa,
    required this.accelerationXMg,
    required this.accelerationYMg,
    required this.accelerationZMg,
    required this.batteryMv,
    required this.txPowerDbm,
    required this.movementCounter,
    required this.measurementSequence,
    required this.macAddress,
  });

  /// Stable identity string `RUUVI/<MAC>` used for registration lookups;
  /// null without a MAC.
  String? get identity =>
      macAddress == null ? null : '$ruuviIdentityPrefix$macAddress';

  /// Model inferred from sensor availability: pressure present ⇒ RuuviTag,
  /// humidity only ⇒ Pro 3-in-1, neither ⇒ Pro 2-in-1.
  RuuviModel get inferredModel {
    if (pressureHpa != null) return RuuviModel.ruuviTag;
    if (humidityPct != null) return RuuviModel.ruuviTagPro3in1;
    return RuuviModel.ruuviTagPro2in1;
  }

  bool get isLowBattery =>
      batteryMv != null && batteryMv! < ruuviLowBatteryMv;

  /// Parses the manufacturer-specific payload that follows the company ID —
  /// the byte list found under key [ruuviCompanyId] in a scan result's
  /// manufacturer data map. Returns null for non-format-5 payloads.
  static RuuviAdvertisement? parse(List<int>? data) {
    if (data == null || data.length < 24) return null;
    if (data[0] != ruuviDataFormat5) return null;

    final tempRaw = (data[1] << 8) | data[2];
    final humidityRaw = (data[3] << 8) | data[4];
    final pressureRaw = (data[5] << 8) | data[6];
    final accXRaw = (data[7] << 8) | data[8];
    final accYRaw = (data[9] << 8) | data[10];
    final accZRaw = (data[11] << 8) | data[12];
    final powerRaw = (data[13] << 8) | data[14];
    final batteryRaw = powerRaw >> 5;
    final txRaw = powerRaw & 0x1F;
    final movementRaw = data[15];
    final sequenceRaw = (data[16] << 8) | data[17];
    final macBytes = data.sublist(18, 24);

    return RuuviAdvertisement(
      temperatureC: tempRaw == 0x8000 ? null : _toInt16(tempRaw) * 0.005,
      humidityPct: humidityRaw == 0xFFFF ? null : humidityRaw * 0.0025,
      pressureHpa: pressureRaw == 0xFFFF ? null : (pressureRaw + 50000) / 100,
      accelerationXMg: accXRaw == 0x8000 ? null : _toInt16(accXRaw),
      accelerationYMg: accYRaw == 0x8000 ? null : _toInt16(accYRaw),
      accelerationZMg: accZRaw == 0x8000 ? null : _toInt16(accZRaw),
      batteryMv: batteryRaw == 2047 ? null : batteryRaw + 1600,
      txPowerDbm: txRaw == 31 ? null : txRaw * 2 - 40,
      movementCounter: movementRaw == 0xFF ? null : movementRaw,
      measurementSequence: sequenceRaw == 0xFFFF ? null : sequenceRaw,
      macAddress: macBytes.every((b) => b == 0xFF)
          ? null
          : macBytes
                .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                .join(':'),
    );
  }

  /// Convenience over a whole manufacturer-data map (company ID → payload).
  static RuuviAdvertisement? fromManufacturerData(Map<int, List<int>> data) =>
      parse(data[ruuviCompanyId]);

  @override
  String toString() =>
      'RuuviAdvertisement(mac: $macAddress, model: ${inferredModel.label}, '
      'temp: $temperatureC °C, humidity: $humidityPct %, '
      'pressure: $pressureHpa hPa, battery: $batteryMv mV, '
      'movement: $movementCounter, seq: $measurementSequence)';
}

int _toInt16(int value) => value > 0x7FFF ? value - 0x10000 : value;
