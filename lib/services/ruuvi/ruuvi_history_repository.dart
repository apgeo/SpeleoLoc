import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_log_protocol.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Storage for downloaded Ruuvi on-tag measurement history
/// (`ruuvi_sensor_history`).
///
/// Local-only telemetry: rows are keyed by the physical tag's MAC, never
/// change-logged and never synced — sharing happens via CSV export. The
/// per-sensor samples of one log download share timestamps, so ingest
/// merges them into wide rows; the (mac, measured_at) primary key makes
/// re-downloads idempotent.
class RuuviHistoryRepository {
  final AppDatabase _database;
  final _log = AppLogger.of('RuuviHistoryRepository');

  RuuviHistoryRepository(this._database);

  /// Upserts one download's samples, merging per-sensor values that share
  /// a timestamp and preserving already-stored values the new batch does
  /// not carry. Returns the number of distinct timestamps written.
  Future<int> upsertSamples(
    String macAddress,
    Iterable<RuuviLogSample> samples,
  ) async {
    final mac = macAddress.toUpperCase();
    // Merge the per-sensor streams into wide rows before touching the DB.
    final merged = <int, List<double?>>{};
    for (final s in samples) {
      final epochS = s.measuredAt.toUtc().millisecondsSinceEpoch ~/ 1000;
      final row = merged.putIfAbsent(epochS, () => [null, null, null]);
      if (s.temperatureC != null) row[0] = s.temperatureC;
      if (s.humidityPct != null) row[1] = s.humidityPct;
      if (s.pressureHpa != null) row[2] = s.pressureHpa;
    }
    if (merged.isEmpty) return 0;
    try {
      await _database.transaction(() async {
        for (final entry in merged.entries) {
          await _database.customStatement(
            'INSERT INTO ruuvi_sensor_history '
            '(mac_address, measured_at, temperature_c, humidity_pct, '
            'pressure_hpa) VALUES (?, ?, ?, ?, ?) '
            'ON CONFLICT(mac_address, measured_at) DO UPDATE SET '
            'temperature_c = COALESCE(excluded.temperature_c, temperature_c), '
            'humidity_pct = COALESCE(excluded.humidity_pct, humidity_pct), '
            'pressure_hpa = COALESCE(excluded.pressure_hpa, pressure_hpa)',
            [mac, entry.key, entry.value[0], entry.value[1], entry.value[2]],
          );
        }
      });
      return merged.length;
    } catch (e, st) {
      _log.severe('Failed to store Ruuvi history', e, st);
      throw DbException(
        'Failed to store Ruuvi history',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Stored readings for one tag, oldest first, optionally bounded.
  Future<List<RuuviSensorHistoryData>> getReadings(
    String macAddress, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      return await _readingsQuery(macAddress, from: from, to: to).get();
    } catch (e, st) {
      _log.severe('Failed to load Ruuvi history', e, st);
      throw DbException(
        'Failed to load Ruuvi history',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Reactive variant of [getReadings] for the history screen.
  Stream<List<RuuviSensorHistoryData>> watchReadings(
    String macAddress, {
    DateTime? from,
    DateTime? to,
  }) => _readingsQuery(macAddress, from: from, to: to).watch();

  /// Timestamp of the newest stored reading; the next download's lower
  /// bound. Null when nothing is stored yet.
  Future<DateTime?> latestTimestamp(String macAddress) async {
    try {
      final row =
          await (_database.select(_database.ruuviSensorHistory)
                ..where((r) => r.macAddress.equals(macAddress.toUpperCase()))
                ..orderBy([
                  (r) => OrderingTerm(
                    expression: r.measuredAt,
                    mode: OrderingMode.desc,
                  ),
                ])
                ..limit(1))
              .getSingleOrNull();
      if (row == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        row.measuredAt * 1000,
        isUtc: true,
      );
    } catch (e, st) {
      _log.severe('Failed to read latest Ruuvi timestamp', e, st);
      throw DbException(
        'Failed to read latest Ruuvi timestamp',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Deletes all stored history of one tag.
  Future<void> clearHistory(String macAddress) async {
    try {
      await (_database.delete(
        _database.ruuviSensorHistory,
      )..where((r) => r.macAddress.equals(macAddress.toUpperCase()))).go();
    } catch (e, st) {
      _log.severe('Failed to clear Ruuvi history', e, st);
      throw DbException(
        'Failed to clear Ruuvi history',
        cause: e,
        stackTrace: st,
      );
    }
  }

  SimpleSelectStatement<RuuviSensorHistory, RuuviSensorHistoryData>
  _readingsQuery(String macAddress, {DateTime? from, DateTime? to}) {
    final query = _database.select(_database.ruuviSensorHistory)
      ..where((r) => r.macAddress.equals(macAddress.toUpperCase()))
      ..orderBy([(r) => OrderingTerm(expression: r.measuredAt)]);
    if (from != null) {
      final fromS = from.toUtc().millisecondsSinceEpoch ~/ 1000;
      query.where((r) => r.measuredAt.isBiggerOrEqualValue(fromS));
    }
    if (to != null) {
      final toS = to.toUtc().millisecondsSinceEpoch ~/ 1000;
      query.where((r) => r.measuredAt.isSmallerOrEqualValue(toS));
    }
    return query;
  }
}
