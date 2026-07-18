import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_log_protocol.dart';

/// Framing per the Ruuvi NUS log-read documentation
/// (docs.ruuvi.com, "Read logged history").
void main() {
  DateTime epoch(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

  group('encodeLogReadRequest', () {
    test('builds header + two big-endian uint32 timestamps', () {
      final request = encodeLogReadRequest(
        now: epoch(0x01020304),
        since: epoch(0x01020000),
      );
      expect(request, [
        0x3A, 0x3A, 0x11, //
        0x01, 0x02, 0x03, 0x04, //
        0x01, 0x02, 0x00, 0x00, //
      ]);
    });

    test('local times are converted to UTC seconds', () {
      final request = encodeLogReadRequest(
        now: epoch(1609459200).toLocal(), // 2021-01-01T00:00:00Z
        since: epoch(0),
      );
      expect(request.sublist(3, 7), [0x5F, 0xEE, 0x66, 0x00]);
    });
  });

  group('RuuviLogMessage.parse', () {
    test('decodes a temperature element (0.01 °C per LSB)', () {
      final message = RuuviLogMessage.parse([
        0x3A, 0x30, 0x10, //
        0x5F, 0xEE, 0x66, 0x00, // 2021-01-01T00:00:00Z
        0x00, 0x00, 0x09, 0x72, // 2418 → 24.18 °C
      ]);
      expect(message, isNotNull);
      expect(message!.isEndOfData, isFalse);
      expect(message.isError, isFalse);
      final sample = message.sample!;
      expect(sample.measuredAt, DateTime.utc(2021));
      expect(sample.temperatureC, closeTo(24.18, 0.0001));
      expect(sample.humidityPct, isNull);
      expect(sample.pressureHpa, isNull);
    });

    test('temperature is signed', () {
      final message = RuuviLogMessage.parse([
        0x3A, 0x30, 0x10, //
        0x5F, 0xEE, 0x66, 0x00, //
        0xFF, 0xFF, 0xFF, 0x38, // -200 → -2.00 °C
      ])!;
      expect(message.sample!.temperatureC, closeTo(-2.0, 0.0001));
    });

    test('decodes humidity and pressure elements', () {
      final humidity = RuuviLogMessage.parse([
        0x3A, 0x31, 0x10, //
        0x5F, 0xEE, 0x66, 0x00, //
        0x00, 0x00, 0x14, 0xE5, // 5349 → 53.49 %
      ])!;
      expect(humidity.sample!.humidityPct, closeTo(53.49, 0.0001));

      final pressure = RuuviLogMessage.parse([
        0x3A, 0x32, 0x10, //
        0x5F, 0xEE, 0x66, 0x00, //
        0x00, 0x01, 0x86, 0xCC, // 100044 Pa → 1000.44 hPa
      ])!;
      expect(pressure.sample!.pressureHpa, closeTo(1000.44, 0.0001));
    });

    test('recognises the all-0xFF end-of-data marker', () {
      final message = RuuviLogMessage.parse([
        0x3A, 0x30, 0x10, //
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, //
      ])!;
      expect(message.isEndOfData, isTrue);
      expect(message.sample, isNull);
    });

    test('recognises error messages', () {
      final message = RuuviLogMessage.parse([
        0x3A, 0x3A, 0xF0, //
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, //
      ])!;
      expect(message.isError, isTrue);
      expect(message.isEndOfData, isFalse);
      expect(message.sample, isNull);
    });

    test('unknown source endpoints yield no sample', () {
      final message = RuuviLogMessage.parse([
        0x3A, 0x40, 0x10, //
        0x5F, 0xEE, 0x66, 0x00, //
        0x00, 0x00, 0x00, 0x01, //
      ])!;
      expect(message.sample, isNull);
    });

    test('rejects other lengths', () {
      expect(RuuviLogMessage.parse([]), isNull);
      expect(RuuviLogMessage.parse(List.filled(10, 0)), isNull);
      expect(RuuviLogMessage.parse(List.filled(12, 0)), isNull);
    });
  });

  group('RuuviLogMessage.parseAll', () {
    test('splits coalesced notifications and drops partial tails', () {
      final buffer = [
        0x3A, 0x30, 0x10, //
        0x5F, 0xEE, 0x66, 0x00, //
        0x00, 0x00, 0x09, 0x72, //
        0x3A, 0x31, 0x10, //
        0x5F, 0xEE, 0x66, 0x00, //
        0x00, 0x00, 0x14, 0xE5, //
        0x3A, 0x32, // partial trailing data
      ];
      final messages = RuuviLogMessage.parseAll(buffer);
      expect(messages, hasLength(2));
      expect(messages[0].sample!.temperatureC, closeTo(24.18, 0.0001));
      expect(messages[1].sample!.humidityPct, closeTo(53.49, 0.0001));
    });

    test('returns an empty list for an empty buffer', () {
      expect(RuuviLogMessage.parseAll([]), isEmpty);
    });
  });
}
