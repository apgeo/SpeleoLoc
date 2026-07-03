import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/clock.dart';

/// A registered beacon joined with its cave place (and cave title for
/// cross-cave listings).
class BeaconWithPlace {
  final CavePlaceBeacon beacon;
  final CavePlace cavePlace;
  final String caveTitle;

  const BeaconWithPlace({
    required this.beacon,
    required this.cavePlace,
    required this.caveTitle,
  });
}

/// CRUD + lookup for `cave_place_beacons` (BLE beacon registrations).
///
/// Identity is the opaque triple (proximity UUID, major, minor); the
/// proximity UUID is normalised to uppercase on write and lookup.
class BeaconRepository {
  final AppDatabase _database;
  final CurrentUserService _currentUser;
  final ChangeLogger _logger;
  final Clock _clock;
  final _log = AppLogger.of('BeaconRepository');

  BeaconRepository(
    this._database,
    this._currentUser,
    this._logger, {
    Clock clock = const SystemClock(),
  }) : _clock = clock;

  /// Active (non-deleted) registrations for one cave place.
  Future<List<CavePlaceBeacon>> getBeaconsForPlace(Uuid cavePlaceUuid) async {
    try {
      return await (_database.select(_database.cavePlaceBeacons)..where(
            (b) =>
                b.cavePlaceUuid.equalsValue(cavePlaceUuid) &
                b.deletedAt.isNull(),
          ))
          .get();
    } catch (e, st) {
      _log.severe('Failed to load beacons for place', e, st);
      throw DbException(
        'Failed to load beacons for place',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Active registrations for a whole cave, joined with their places —
  /// the maintenance list.
  Future<List<BeaconWithPlace>> getBeaconsForCave(Uuid caveUuid) async {
    try {
      final beacons =
          await (_database.select(_database.cavePlaceBeacons)..where(
                (b) => b.caveUuid.equalsValue(caveUuid) & b.deletedAt.isNull(),
              ))
              .get();
      return _joinPlaces(beacons);
    } catch (e, st) {
      _log.severe('Failed to load beacons for cave', e, st);
      throw DbException(
        'Failed to load beacons for cave',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Resolves a detected beacon identity to registrations (normally one;
  /// multiple only when the same tag identity was registered in several
  /// caves — mirrors the QR cross-cave ambiguity case).
  Future<List<BeaconWithPlace>> findByIdentity(
    String proximityUuid,
    int major,
    int minor, {
    Uuid? currentCaveId,
  }) async {
    try {
      final query = _database.select(_database.cavePlaceBeacons)
        ..where(
          (b) =>
              b.proximityUuid.equals(proximityUuid.toUpperCase()) &
              b.major.equals(major) &
              b.minor.equals(minor) &
              b.deletedAt.isNull(),
        );
      var beacons = await query.get();
      if (currentCaveId != null) {
        beacons = beacons.where((b) => b.caveUuid == currentCaveId).toList();
      }
      return _joinPlaces(beacons);
    } catch (e, st) {
      _log.severe('Failed to find beacon by identity', e, st);
      throw DbException(
        'Failed to find beacon by identity',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Registers a beacon at a cave place. Throws [DbException] when the
  /// identity is already registered in the same cave (UNIQUE constraint).
  Future<Uuid> registerBeacon({
    required Uuid cavePlaceUuid,
    required Uuid caveUuid,
    required String proximityUuid,
    required int major,
    required int minor,
    String? macAddress,
    String? localName,
    String? model,
    int? measuredPower,
    String? notes,
  }) async {
    try {
      final now = _clock.nowMs();
      final author = await _currentUser.currentOrSystem();
      final newUuid = Uuid.v7();
      await _database
          .into(_database.cavePlaceBeacons)
          .insert(
            CavePlaceBeaconsCompanion.insert(
              uuid: newUuid,
              cavePlaceUuid: cavePlaceUuid,
              caveUuid: caveUuid,
              proximityUuid: proximityUuid.toUpperCase(),
              major: major,
              minor: minor,
              macAddress: Value(macAddress),
              localName: Value(localName),
              model: Value(model),
              measuredPower: Value(measuredPower),
              notes: Value(notes),
              createdAt: Value(now),
              updatedAt: Value(now),
              createdByUserUuid: Value(author),
              lastModifiedByUserUuid: Value(author),
            ),
          );
      await _logger.logInsert('cave_place_beacons', newUuid);
      return newUuid;
    } catch (e, st) {
      _log.severe('Failed to register beacon', e, st);
      throw DbException('Failed to register beacon', cause: e, stackTrace: st);
    }
  }

  /// Soft-deletes a registration.
  Future<void> unregisterBeacon(Uuid beaconUuid) async {
    try {
      final now = _clock.nowMs();
      final author = await _currentUser.currentOrSystem();
      final old =
          await (_database.select(_database.cavePlaceBeacons)
                ..where((b) => b.uuid.equalsValue(beaconUuid))
                ..limit(1))
              .getSingleOrNull();
      if (old == null) {
        throw DbException('Beacon $beaconUuid not found');
      }
      await (_database.update(
        _database.cavePlaceBeacons,
      )..where((b) => b.uuid.equalsValue(beaconUuid))).write(
        CavePlaceBeaconsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          lastModifiedByUserUuid: Value(author),
        ),
      );
      await _logger.logDelete(
        'cave_place_beacons',
        beaconUuid,
        oldValues: {
          'cave_place_uuid': old.cavePlaceUuid.toString(),
          'proximity_uuid': old.proximityUuid,
          'major': old.major,
          'minor': old.minor,
        },
      );
    } catch (e, st) {
      _log.severe('Failed to unregister beacon', e, st);
      throw DbException(
        'Failed to unregister beacon',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Opportunistic health update on encounter. Intentionally NOT
  /// change-logged (local telemetry, excluded from sync conflict diffs).
  Future<void> updateHealth(
    Uuid beaconUuid, {
    int? batteryMv,
    double? temperatureC,
    double? humidityPct,
  }) async {
    try {
      await (_database.update(
        _database.cavePlaceBeacons,
      )..where((b) => b.uuid.equalsValue(beaconUuid))).write(
        CavePlaceBeaconsCompanion(
          lastSeenAt: Value(_clock.nowMs()),
          lastBatteryMv: batteryMv != null
              ? Value(batteryMv)
              : const Value.absent(),
          lastTemperatureC: temperatureC != null
              ? Value(temperatureC)
              : const Value.absent(),
          lastHumidityPct: humidityPct != null
              ? Value(humidityPct)
              : const Value.absent(),
        ),
      );
    } catch (e, st) {
      // Telemetry only — log and continue, never surface to the user.
      _log.warning('Failed to update beacon health', e, st);
    }
  }

  Future<List<BeaconWithPlace>> _joinPlaces(
    List<CavePlaceBeacon> beacons,
  ) async {
    if (beacons.isEmpty) return [];
    final placeIds = beacons.map((b) => b.cavePlaceUuid).toSet();
    final places = await (_database.select(
      _database.cavePlaces,
    )..where((cp) => cp.uuid.isInValues(placeIds))).get();
    final placeById = {for (final p in places) p.uuid: p};
    final caveIds = beacons.map((b) => b.caveUuid).toSet();
    final caves = await (_database.select(
      _database.caves,
    )..where((c) => c.uuid.isInValues(caveIds))).get();
    final caveTitles = {for (final c in caves) c.uuid: c.title};
    return [
      for (final b in beacons)
        if (placeById[b.cavePlaceUuid] != null)
          BeaconWithPlace(
            beacon: b,
            cavePlace: placeById[b.cavePlaceUuid]!,
            caveTitle: caveTitles[b.caveUuid] ?? '',
          ),
    ];
  }
}
