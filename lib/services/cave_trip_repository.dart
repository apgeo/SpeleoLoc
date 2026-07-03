import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
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
  final ChangeLogger _logger;
  final _log = AppLogger.of('CaveTripRepository');

  CaveTripRepository(this._database, this._logger);

  @override
  Future<CaveTrip?> findById(Uuid uuid) async {
    try {
      return await (_database.select(
        _database.caveTrips,
      )..where((t) => t.uuid.equalsValue(uuid))).getSingleOrNull();
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
      throw DbException('Failed to load cave trips', cause: e, stackTrace: st);
    }
  }

  @override
  Future<List<String>> getCaveTripTitles(Uuid caveUuid) async {
    try {
      return await _database.getCaveTripTitles(caveUuid);
    } catch (e, st) {
      _log.severe('Failed to load cave trip titles', e, st);
      throw DbException(
        'Failed to load cave trip titles',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<CaveTripPoint>> getTripPoints(Uuid tripUuid) async {
    try {
      return await _database.getTripPoints(tripUuid);
    } catch (e, st) {
      _log.severe('Failed to load trip points', e, st);
      throw DbException('Failed to load trip points', cause: e, stackTrace: st);
    }
  }

  @override
  Future<List<TripReportTemplate>> getTripReportTemplates() async {
    try {
      return await _database.getTripReportTemplates();
    } catch (e, st) {
      _log.severe('Failed to load trip report templates', e, st);
      throw DbException(
        'Failed to load trip report templates',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> renameCaveTrip(Uuid tripUuid, String newTitle) async {
    try {
      final old = await findById(tripUuid);
      await _database.renameCaveTrip(tripUuid, newTitle);
      if (old != null) {
        await _logger.logUpdate(
          'cave_trips',
          tripUuid,
          oldValues: {'title': old.title},
          newValues: {'title': newTitle},
        );
      }
    } catch (e, st) {
      _log.severe('Failed to rename cave trip', e, st);
      throw DbException('Failed to rename cave trip', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteCaveTrip(Uuid tripUuid) async {
    try {
      await _database.transaction(() async {
        // Snapshot the rows the cascade will remove, then log a tombstone
        // for every one of them: sync propagates deletes per-uuid via
        // change_log, so a missing child tombstone leaves orphaned rows on
        // peers (and fails their deferred-FK check on import).
        final trip = await findById(tripUuid);
        final points = await _database.getTripPoints(tripUuid);
        final docLinks = await (_database.select(
          _database.documentationFilesToCaveTrips,
        )..where((t) => t.caveTripUuid.equalsValue(tripUuid))).get();

        await _database.deleteCaveTrip(tripUuid);

        if (trip != null) {
          await _logger.logDelete(
            'cave_trips',
            tripUuid,
            oldValues: {'title': trip.title, 'cave_uuid': trip.caveUuid},
          );
        }
        for (final p in points) {
          await _logger.logDelete(
            'cave_trip_points',
            p.uuid,
            oldValues: {
              'cave_trip_uuid': p.caveTripUuid,
              'cave_place_uuid': p.cavePlaceUuid,
            },
          );
        }
        for (final l in docLinks) {
          await _logger.logDelete(
            'documentation_files_to_cave_trips',
            l.uuid,
            oldValues: {
              'documentation_file_uuid': l.documentationFileUuid,
              'cave_trip_uuid': l.caveTripUuid,
            },
          );
        }
      });
    } catch (e, st) {
      _log.severe('Failed to delete cave trip', e, st);
      throw DbException('Failed to delete cave trip', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> updateTripLog(Uuid tripUuid, String log) async {
    try {
      final old = await findById(tripUuid);
      await _database.updateTripLog(tripUuid, log);
      if (old != null) {
        await _logger.logUpdate(
          'cave_trips',
          tripUuid,
          oldValues: {'log': old.log},
          newValues: {'log': log},
        );
      }
    } catch (e, st) {
      _log.severe('Failed to update trip log', e, st);
      throw DbException('Failed to update trip log', cause: e, stackTrace: st);
    }
  }

  @override
  Future<Uuid> insertTripReportTemplate({
    required String title,
    required String fileName,
    required int fileSize,
    required String format,
  }) async {
    try {
      final uuid = await _database.insertTripReportTemplate(
        title: title,
        fileName: fileName,
        fileSize: fileSize,
        format: format,
      );
      await _logger.logInsert('trip_report_templates', uuid);
      return uuid;
    } catch (e, st) {
      _log.severe('Failed to insert trip report template', e, st);
      throw DbException(
        'Failed to insert trip report template',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> deleteTripReportTemplate(Uuid uuid) async {
    try {
      await _database.transaction(() async {
        final template = await _database.getTripReportTemplate(uuid);
        await _database.deleteTripReportTemplate(uuid);
        if (template != null) {
          await _logger.logDelete(
            'trip_report_templates',
            uuid,
            oldValues: {
              'title': template.title,
              'file_name': template.fileName,
            },
          );
        }
      });
    } catch (e, st) {
      _log.severe('Failed to delete trip report template', e, st);
      throw DbException(
        'Failed to delete trip report template',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
