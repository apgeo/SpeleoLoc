/// Decoder for the HoneyComm BP1003 beacon advertising protocol.
///
/// Covers the beacon families HCBB01 / HCBB07 / HCBB16 / HCBB22 / HCBB62 / H8
/// (see `resource_docs/ble_tags/Beacon Protocol BP1003v1.02 ...pdf`).
///
/// The tags broadcast two frames:
///  * an **advertising frame** — a standard Apple iBeacon (company ID 0x004C,
///    type 0x02, length 0x15) carrying proximity UUID / major / minor and the
///    calibrated RSSI@1m byte;
///  * a **scan response** — Tx power AD + proprietary Service Data (16-bit
///    service UUID 0x4B4C) with battery voltage, broadcast interval, MAC,
///    a status bit-field and optional temperature/humidity, plus a Complete
///    Local Name of the form `K` + last 6 hex digits of the MAC.
///
/// Pure Dart — no Flutter or plugin imports — so it is unit-testable and
/// reusable by both the raw-scan diagnostics and the future detection service.
library;

/// Apple's Bluetooth company identifier, used by every iBeacon frame.
const int iBeaconCompanyId = 0x004C;

/// 16-bit service UUID of the BP1003 proprietary scan-response service data.
const int bp1003ServiceUuid = 0x4B4C;

/// Factory-default proximity UUID of the HoneyComm beacon family.
const String honeyCommDefaultProximityUuid =
    'FDA50693-A4E2-4FB1-AFCF-C6EB07647825';

/// Matches the BP1003 default local name: `K` + last 6 hex digits of MAC.
final RegExp bp1003LocalNamePattern = RegExp(r'^K[0-9a-fA-F]{6}$');

/// Decoded iBeacon advertising frame.
class IBeaconFrame {
  /// Proximity UUID in canonical uppercase 8-4-4-4-12 form.
  final String proximityUuid;
  final int major;
  final int minor;

  /// Calibrated RSSI at 1 m, in dBm (signed; e.g. -61).
  final int measuredPower;

  const IBeaconFrame({
    required this.proximityUuid,
    required this.major,
    required this.minor,
    required this.measuredPower,
  });

  /// Stable identity string `UUID/major/minor` used for registration lookups.
  String get identity => '$proximityUuid/$major/$minor';

  /// Parses the manufacturer-specific payload that follows the company ID —
  /// the byte list found under key [iBeaconCompanyId] in a scan result's
  /// manufacturer data map. Returns null when the payload is not an iBeacon.
  static IBeaconFrame? parse(List<int>? data) {
    if (data == null || data.length < 23) return null;
    if (data[0] != 0x02 || data[1] != 0x15) return null;
    return IBeaconFrame(
      proximityUuid: _formatUuid(data.sublist(2, 18)),
      major: (data[18] << 8) | data[19],
      minor: (data[20] << 8) | data[21],
      measuredPower: _toInt8(data[22]),
    );
  }

  /// Convenience over a whole manufacturer-data map (company ID → payload).
  static IBeaconFrame? fromManufacturerData(Map<int, List<int>> data) =>
      parse(data[iBeaconCompanyId]);

  @override
  String toString() =>
      'IBeaconFrame($identity, measuredPower: $measuredPower dBm)';
}

/// Decoded BP1003 scan-response service data (service UUID 0x4B4C).
class Bp1003ServiceData {
  /// Battery voltage in millivolts (refreshed by the tag every ~12 h).
  final int batteryMv;

  /// Advertising interval in milliseconds (wire value × 100 ms).
  final int broadcastIntervalMs;

  /// Transmit power in dBm (signed).
  final int txPowerDbm;

  /// MAC address as `AA:BB:CC:DD:EE:FF` (uppercase).
  final String macAddress;

  /// Raw status bit-field — see the individual getters.
  final int statusFlags;

  /// Temperature in °C, only when the tag has an enabled temp/humidity
  /// sensor per [statusFlags]; null otherwise.
  final double? temperatureC;

  /// Relative humidity in %, gated like [temperatureC].
  final int? humidityPct;

  /// Raw temperature/humidity bytes (reserved, integer °C, decimal °C,
  /// humidity %) — kept for diagnostics because vendor flag semantics have
  /// not been hardware-verified yet.
  final List<int> rawTempHumidity;

  const Bp1003ServiceData({
    required this.batteryMv,
    required this.broadcastIntervalMs,
    required this.txPowerDbm,
    required this.macAddress,
    required this.statusFlags,
    required this.temperatureC,
    required this.humidityPct,
    required this.rawTempHumidity,
  });

  /// Bit 4: 0 = connectable (configurable via HC Connect), 1 = not.
  bool get isConnectable => (statusFlags & 0x10) == 0;

  /// Bit 3: tag has an accelerometer.
  bool get hasAccelerometer => (statusFlags & 0x08) != 0;

  /// Bit 2: tag adapts broadcast interval to movement.
  bool get hasAdaptiveInterval => (statusFlags & 0x04) != 0;

  /// Bit 1: tag has a temperature/humidity sensor.
  bool get hasTempHumiditySensor => (statusFlags & 0x02) != 0;

  /// Bit 0: temperature/humidity measurement is enabled.
  bool get tempHumidityEnabled => (statusFlags & 0x01) != 0;

  /// Expected BP1003 local name for this tag's MAC (`K` + last 6 hex digits).
  String get expectedLocalName =>
      'K${macAddress.replaceAll(':', '').substring(6).toLowerCase()}';

  /// Parses the service-data payload for UUID 0x4B4C.
  ///
  /// Platforms normally strip the leading 16-bit service UUID from the value
  /// (15 payload bytes); a 17-byte value with the `4C 4B` little-endian
  /// prefix still present is also accepted. Returns null on any other shape.
  static Bp1003ServiceData? parse(List<int>? data) {
    if (data == null) return null;
    var d = data;
    if (d.length == 17 && d[0] == 0x4C && d[1] == 0x4B) {
      d = d.sublist(2);
    }
    if (d.length != 15) return null;

    final flags = d[10];
    final hasTemp = (flags & 0x02) != 0 && (flags & 0x01) != 0;
    // Integer °C is signed; the decimal byte extends away from zero.
    final tempInt = _toInt8(d[12]);
    final temp = tempInt < 0 ? tempInt - d[13] / 100 : tempInt + d[13] / 100;
    return Bp1003ServiceData(
      batteryMv: (d[0] << 8) | d[1],
      broadcastIntervalMs: d[2] * 100,
      txPowerDbm: _toInt8(d[3]),
      macAddress: d
          .sublist(4, 10)
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(':'),
      statusFlags: flags,
      temperatureC: hasTemp ? temp : null,
      humidityPct: hasTemp ? d[14] : null,
      rawTempHumidity: List.unmodifiable(d.sublist(11, 15)),
    );
  }

  /// Convenience over a whole service-data map. Keys may be 16-bit short
  /// UUIDs (`4b4c`) or the expanded 128-bit base-UUID form.
  static Bp1003ServiceData? fromServiceData(Map<String, List<int>> data) {
    for (final entry in data.entries) {
      final k = entry.key.toLowerCase().replaceAll('-', '');
      if (k == '4b4c' || k.startsWith('00004b4c')) {
        return parse(entry.value);
      }
    }
    return null;
  }

  @override
  String toString() => 'Bp1003ServiceData(mac: $macAddress, '
      'battery: $batteryMv mV, interval: $broadcastIntervalMs ms, '
      'tx: $txPowerDbm dBm, flags: 0x${statusFlags.toRadixString(16)}, '
      'temp: $temperatureC °C, humidity: $humidityPct %)';
}

String _formatUuid(List<int> bytes) {
  final hex = bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

int _toInt8(int byte) => byte > 127 ? byte - 256 : byte;
