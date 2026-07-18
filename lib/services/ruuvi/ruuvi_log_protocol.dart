/// Codec for the Ruuvi Nordic UART Service (NUS) log-read protocol used to
/// download the tag's on-board measurement history (~10 days at 5-minute
/// intervals).
///
/// Messages are 11 bytes: a 3-byte header `[destination, source, type]`
/// followed by an 8-byte payload. The central writes a log-read request to
/// the RX characteristic and receives one log-write message per stored
/// sample as TX notifications, closed by an all-0xFF payload. Production
/// firmware drops the connection unless TX notifications are subscribed
/// within ~12 s — the transport must subscribe before writing.
///
/// Pure Dart — no Flutter or plugin imports — so the framing stays
/// unit-testable without hardware; the GATT transport is a thin shell
/// around this codec.
library;

/// NUS service and characteristic UUIDs (RX: central writes, TX: central
/// subscribes for notifications).
const String ruuviNusServiceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
const String ruuviNusRxCharacteristicUuid =
    '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';
const String ruuviNusTxCharacteristicUuid =
    '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';

/// Header endpoints (destination/source).
const int ruuviEndpointAllEnvironmental = 0x3A;
const int ruuviEndpointTemperature = 0x30;
const int ruuviEndpointHumidity = 0x31;
const int ruuviEndpointPressure = 0x32;

/// Header types.
const int ruuviTypeLogWrite = 0x10;
const int ruuviTypeLogRead = 0x11;
const int ruuviTypeError = 0xF0;

const int ruuviLogMessageLength = 11;

/// Builds the 11-byte log-read request: header
/// `[destination, source, 0x11]` + current time and lower-bound time as
/// big-endian uint32 Unix seconds. The tag replies with every stored
/// sample newer than [since].
List<int> encodeLogReadRequest({
  required DateTime now,
  required DateTime since,
  int destination = ruuviEndpointAllEnvironmental,
  int source = ruuviEndpointAllEnvironmental,
}) => [
  destination,
  source,
  ruuviTypeLogRead,
  ..._encodeUint32(now.toUtc().millisecondsSinceEpoch ~/ 1000),
  ..._encodeUint32(since.toUtc().millisecondsSinceEpoch ~/ 1000),
];

/// One decoded sample from the log stream. Exactly one sensor field is
/// non-null, matching the source endpoint of the message it came from.
class RuuviLogSample {
  final DateTime measuredAt;
  final double? temperatureC;
  final double? humidityPct;

  /// In hPa (wire unit is Pa).
  final double? pressureHpa;

  const RuuviLogSample({
    required this.measuredAt,
    this.temperatureC,
    this.humidityPct,
    this.pressureHpa,
  });

  @override
  String toString() =>
      'RuuviLogSample($measuredAt, temp: $temperatureC, '
      'humidity: $humidityPct, pressure: $pressureHpa)';
}

/// One decoded 11-byte NUS message received during a log download.
class RuuviLogMessage {
  final int destination;
  final int source;
  final int type;
  final List<int> payload;

  const RuuviLogMessage({
    required this.destination,
    required this.source,
    required this.type,
    required this.payload,
  });

  /// All-0xFF log-write payload: the tag has sent every requested sample.
  bool get isEndOfData =>
      type == ruuviTypeLogWrite && payload.every((b) => b == 0xFF);

  /// Tag-side failure (e.g. transfer exceeded the ~5-minute watchdog).
  /// Recover by re-requesting with the last received timestamp.
  bool get isError => type == ruuviTypeError;

  /// The decoded sample, when this is a regular log-write element from a
  /// known sensor endpoint; null for end/error/other messages.
  RuuviLogSample? get sample {
    if (type != ruuviTypeLogWrite || isEndOfData) return null;
    final measuredAt = DateTime.fromMillisecondsSinceEpoch(
      _decodeUint32(payload, 0) * 1000,
      isUtc: true,
    );
    final raw = _decodeUint32(payload, 4);
    switch (source) {
      case ruuviEndpointTemperature:
        // Signed: 0.01 °C per LSB.
        final signed = raw > 0x7FFFFFFF ? raw - 0x100000000 : raw;
        return RuuviLogSample(
          measuredAt: measuredAt,
          temperatureC: signed * 0.01,
        );
      case ruuviEndpointHumidity:
        return RuuviLogSample(measuredAt: measuredAt, humidityPct: raw * 0.01);
      case ruuviEndpointPressure:
        return RuuviLogSample(measuredAt: measuredAt, pressureHpa: raw / 100);
      default:
        return null;
    }
  }

  /// Parses a single 11-byte message; null on any other length.
  static RuuviLogMessage? parse(List<int> data) {
    if (data.length != ruuviLogMessageLength) return null;
    return RuuviLogMessage(
      destination: data[0],
      source: data[1],
      type: data[2],
      payload: List.unmodifiable(data.sublist(3)),
    );
  }

  /// Splits a notification buffer into consecutive 11-byte messages —
  /// some stacks coalesce notifications, so the transport feeds raw
  /// buffers through this. Trailing partial data is ignored.
  static List<RuuviLogMessage> parseAll(List<int> data) {
    final messages = <RuuviLogMessage>[];
    for (var i = 0;
        i + ruuviLogMessageLength <= data.length;
        i += ruuviLogMessageLength) {
      final message = parse(data.sublist(i, i + ruuviLogMessageLength));
      if (message != null) messages.add(message);
    }
    return messages;
  }

  @override
  String toString() =>
      'RuuviLogMessage(dest: 0x${destination.toRadixString(16)}, '
      'src: 0x${source.toRadixString(16)}, '
      'type: 0x${type.toRadixString(16)})';
}

List<int> _encodeUint32(int value) => [
  (value >> 24) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 8) & 0xFF,
  value & 0xFF,
];

int _decodeUint32(List<int> data, int offset) =>
    (data[offset] << 24) |
    (data[offset + 1] << 16) |
    (data[offset + 2] << 8) |
    data[offset + 3];
