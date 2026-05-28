import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Thin read/mutation wrapper around the `cave_trips`, `cave_trip_points`
/// and `trip_report_templates` tables.
///
/// Trip *runtime state* (active trip notifier, paused flag, log appending,
/// playback) is owned by [CaveTripService]. This repository only exposes
/// the table-level operations that screens currently invoke directly on
/// [AppDatabase]. Full DI of the trip service is the subject of PR 3.
class CaveTripRepository implements ICaveTripRepository {
  final AppDatabase _database;
  final _log = AppLogger.of('CaveTripRepository');

  CaveTripRepository(this._database);

  @override
  Future<CaveTrip?> findById(Uuid uuid) async {
    try {
      return await (_database.select(_database.caveTrips)
            ..where((t) => t.uuid.equalsValue(uuid)))
          .getSingleOrNull();
    } catch (e, st) {
      _log.severe('Failed to find cave trip by id', e, st);
      throw DbException('Failed to find cave trip', cause: e, stackTrace: st);
    }
  }

  @override
  Future<List<CaveTrip>> getCaveTrips(Uuid caveUuid) async {
    try {
      return await _database.getCaveTrips(caveUuid);
    } catch (e, st) {
      _log.severe('Failed to load cave trips', e, st);
      throw DbException('Failed to load cave trips',
          cause: e, stackTrace: st);
    }
  }

  @override
  Future<List<String>> getCaveTripTitles(Uuid caveUuid) async {
    try {
      return await _database.getCaveTripTitles(caveUuid);
    } catch (e, st) {
      _log.severe('Failed to load cave trip titles', e, st);
      throw DbException('Failed to load cave trip titles',
          cause: e, stackTrace: st);
    }
  }

  @override
  Future<List<CaveTripPoint>> getTripPoints(Uuid tripUuid) async {
    try {
      return await _database.getTripPoints(tripUuid);
    } catch (e, st) {
      _log.severe('Failed to load trip points', e, st);
      throw DbException('Failed to load trip points',
          cause: e, stackTrace: st);
    }
  }

  @override
  Future<List<TripReportTemplate>> getTripReportTemplates() async {
    try {
      return await _database.getTripReportTemplates();
    } catch (e, st) {
      _log.severe('Failed to load trip report templates', e, st);
      throw DbException('Failed to load trip report templates',
          cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> renameCaveTrip(Uuid tripUuid, String newTitle) async {
    try {
      await _database.renameCaveTrip(tripUuid, newTitle);
    } catch (e, st) {
      _log.severe('Failed to rename cave trip', e, st);
      throw DbException('Failed to rename cave trip',
          cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteCaveTrip(Uuid tripUuid) async {
    try {
      await _database.deleteCaveTrip(tripUuid);
    } catch (e, st) {
      _log.severe('Failed to delete cave trip', e, st);
      throw DbException('Failed to delete cave trip',
          cause: e, stackTrace: st);
    }
  }
}
