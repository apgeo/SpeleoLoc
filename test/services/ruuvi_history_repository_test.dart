import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_history_repository.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_log_protocol.dart';

void main() {
  late AppDatabase db;
  late RuuviHistoryRepository repo;

  const mac = 'CB:B8:33:4C:88:4F';

  DateTime epoch(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RuuviHistoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RuuviHistoryRepository', () {
    test('merges per-sensor samples sharing a timestamp into one row',
        () async {
      final written = await repo.upsertSamples(mac.toLowerCase(), [
        RuuviLogSample(measuredAt: epoch(1000), temperatureC: 4.2),
        RuuviLogSample(measuredAt: epoch(1000), humidityPct: 98.5),
        RuuviLogSample(measuredAt: epoch(1000), pressureHpa: 1000.44),
        RuuviLogSample(measuredAt: epoch(1300), temperatureC: 4.3),
      ]);
      expect(written, 2);

      final rows = await repo.getReadings(mac);
      expect(rows, hasLength(2));
      expect(rows.first.macAddress, mac); // normalised to uppercase
      expect(rows.first.measuredAt, 1000);
      expect(rows.first.temperatureC, 4.2);
      expect(rows.first.humidityPct, 98.5);
      expect(rows.first.pressureHpa, 1000.44);
      expect(rows.last.measuredAt, 1300);
      expect(rows.last.humidityPct, isNull);
    });

    test('re-download upserts without duplicating or erasing values',
        () async {
      await repo.upsertSamples(mac, [
        RuuviLogSample(measuredAt: epoch(1000), temperatureC: 4.2),
        RuuviLogSample(measuredAt: epoch(1000), humidityPct: 98.5),
      ]);
      // Overlapping second download: same timestamp, only temperature —
      // the stored humidity must survive, the temperature may refresh.
      await repo.upsertSamples(mac, [
        RuuviLogSample(measuredAt: epoch(1000), temperatureC: 4.25),
        RuuviLogSample(measuredAt: epoch(1300), temperatureC: 4.3),
      ]);
      final rows = await repo.getReadings(mac);
      expect(rows, hasLength(2));
      expect(rows.first.temperatureC, 4.25);
      expect(rows.first.humidityPct, 98.5);
    });

    test('getReadings respects time bounds and tag separation', () async {
      await repo.upsertSamples(mac, [
        RuuviLogSample(measuredAt: epoch(1000), temperatureC: 1),
        RuuviLogSample(measuredAt: epoch(2000), temperatureC: 2),
        RuuviLogSample(measuredAt: epoch(3000), temperatureC: 3),
      ]);
      await repo.upsertSamples('AA:AA:AA:AA:AA:AA', [
        RuuviLogSample(measuredAt: epoch(2000), temperatureC: 99),
      ]);

      final bounded = await repo.getReadings(
        mac,
        from: epoch(1500),
        to: epoch(2500),
      );
      expect(bounded.single.temperatureC, 2);
      expect(await repo.getReadings(mac), hasLength(3));
    });

    test('latestTimestamp tracks the newest stored reading', () async {
      expect(await repo.latestTimestamp(mac), isNull);
      await repo.upsertSamples(mac, [
        RuuviLogSample(measuredAt: epoch(1300), temperatureC: 4.3),
        RuuviLogSample(measuredAt: epoch(1000), temperatureC: 4.2),
      ]);
      expect(await repo.latestTimestamp(mac), epoch(1300));
    });

    test('clearHistory removes only the given tag', () async {
      await repo.upsertSamples(mac, [
        RuuviLogSample(measuredAt: epoch(1000), temperatureC: 4.2),
      ]);
      await repo.upsertSamples('AA:AA:AA:AA:AA:AA', [
        RuuviLogSample(measuredAt: epoch(1000), temperatureC: 99),
      ]);
      await repo.clearHistory(mac);
      expect(await repo.getReadings(mac), isEmpty);
      expect(await repo.getReadings('AA:AA:AA:AA:AA:AA'), hasLength(1));
    });

    test('empty batch is a no-op', () async {
      expect(await repo.upsertSamples(mac, const []), 0);
      expect(await repo.getReadings(mac), isEmpty);
    });

    test('watchReadings emits after an upsert (raw SQL must notify)', () async {
      final sawRow = expectLater(
        repo.watchReadings(mac),
        emitsThrough(
          predicate<List<RuuviSensorHistoryData>>(
            (rows) => rows.length == 1 && rows.single.temperatureC == 4.2,
          ),
        ),
      );
      await repo.upsertSamples(mac, [
        RuuviLogSample(measuredAt: epoch(1000), temperatureC: 4.2),
      ]);
      await sawRow;
    });
  });
}
