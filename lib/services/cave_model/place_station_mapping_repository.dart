import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/model_splay_offset.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/clock.dart';

class PlaceStationMappingRepository implements IPlaceStationMappingRepository {
  PlaceStationMappingRepository(
    this._db,
    this._currentUser,
    this._logger, {
    Clock clock = const SystemClock(),
  }) : _clock = clock;

  final AppDatabase _db;
  final CurrentUserService _currentUser;
  final ChangeLogger _logger;
  final Clock _clock;

  static const _table = 'cave_place_model_stations';

  SimpleSelectStatement<CavePlaceModelStations, CavePlaceModelStation>
  _forModel(Uuid documentationFileUuid) => _db.select(
    _db.cavePlaceModelStations,
  )..where((m) => m.documentationFileUuid.equalsValue(documentationFileUuid));

  @override
  Future<List<CavePlaceModelStation>> mappingsForModel(
    Uuid documentationFileUuid,
  ) => _forModel(documentationFileUuid).get();

  @override
  Stream<List<CavePlaceModelStation>> watchMappingsForModel(
    Uuid documentationFileUuid,
  ) => _forModel(documentationFileUuid).watch();

  @override
  Future<List<CavePlaceModelStation>> mappingsForPlace(Uuid cavePlaceUuid) =>
      (_db.select(
        _db.cavePlaceModelStations,
      )..where((m) => m.cavePlaceUuid.equalsValue(cavePlaceUuid))).get();

  Future<CavePlaceModelStation?> _find(Uuid place, Uuid model) =>
      (_db.select(_db.cavePlaceModelStations)..where(
            (m) =>
                m.cavePlaceUuid.equalsValue(place) &
                m.documentationFileUuid.equalsValue(model),
          ))
          .getSingleOrNull();

  @override
  Future<CavePlaceModelStation> saveMapping({
    required Uuid cavePlaceUuid,
    required Uuid caveUuid,
    required Uuid documentationFileUuid,
    required String station,
    ModelSplayOffset? splay,
  }) => _db.transaction(() async {
    final now = _clock.nowMs();
    final author = await _currentUser.currentOrSystem();
    final existing = await _find(cavePlaceUuid, documentationFileUuid);
    final needsReview = splay != null;
    if (existing != null) {
      await (_db.update(
        _db.cavePlaceModelStations,
      )..where((m) => m.uuid.equalsValue(existing.uuid))).write(
        CavePlaceModelStationsCompanion(
          station: Value(station),
          splayEast: Value(splay?.east),
          splayNorth: Value(splay?.north),
          splayUp: Value(splay?.up),
          needsReview: Value(needsReview ? 1 : 0),
          updatedAt: Value(now),
          lastModifiedByUserUuid: Value(author),
        ),
      );
      await _logger.logUpdate(
        _table,
        existing.uuid,
        oldValues: {
          'station': existing.station,
          'splay_east': existing.splayEast,
          'splay_north': existing.splayNorth,
          'splay_up': existing.splayUp,
          'needs_review': existing.needsReview,
        },
        newValues: {
          'station': station,
          'splay_east': splay?.east,
          'splay_north': splay?.north,
          'splay_up': splay?.up,
          'needs_review': needsReview ? 1 : 0,
        },
      );
    } else {
      final uuid = Uuid.v7();
      await _db
          .into(_db.cavePlaceModelStations)
          .insert(
            CavePlaceModelStationsCompanion.insert(
              uuid: uuid,
              cavePlaceUuid: cavePlaceUuid,
              caveUuid: caveUuid,
              documentationFileUuid: documentationFileUuid,
              station: station,
              splayEast: Value(splay?.east),
              splayNorth: Value(splay?.north),
              splayUp: Value(splay?.up),
              needsReview: Value(needsReview ? 1 : 0),
              createdAt: Value(now),
              updatedAt: Value(now),
              createdByUserUuid: Value(author),
              lastModifiedByUserUuid: Value(author),
            ),
          );
      await _logger.logInsert(_table, uuid);
    }
    return (await _find(cavePlaceUuid, documentationFileUuid))!;
  });

  @override
  Future<bool> deleteMapping(Uuid cavePlaceUuid, Uuid documentationFileUuid) =>
      _db.transaction(() async {
        final old = await _find(cavePlaceUuid, documentationFileUuid);
        if (old == null) return false;
        await (_db.delete(
          _db.cavePlaceModelStations,
        )..where((m) => m.uuid.equalsValue(old.uuid))).go();
        await _logger.logDelete(
          _table,
          old.uuid,
          oldValues: {
            'cave_place_uuid': old.cavePlaceUuid,
            'documentation_file_uuid': old.documentationFileUuid,
            'station': old.station,
          },
        );
        return true;
      });
}
