import 'package:drift/drift.dart' show Value;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/geo_transfer/geo_waypoint.dart';
import 'package:speleoloc/services/map/place_label_resolver.dart';
import 'package:speleoloc/services/repository_interfaces.dart';

/// Result of importing waypoints into a cave.
typedef PlaceImportResult = ({int created, int skipped});

/// Exchanges cave places with other mapping tools: located places out as
/// [GeoWaypoint]s (for the GPX/KML writers), waypoints in as new places
/// of a chosen cave.
class PlaceTransferService {
  PlaceTransferService(this._database, this._caves, this._places);

  final AppDatabase _database;
  final ICaveRepository _caves;
  final ICavePlaceRepository _places;

  /// Every place with coordinates, restricted to [caveUuids] when given.
  /// Strict set semantics: null = all caves, empty = none — an emptied
  /// selection must not silently widen an export to the whole database.
  /// Waypoint names use the list label (`<place> - <cave>`) so they stay
  /// unambiguous in external tools.
  Future<List<GeoWaypoint>> collectWaypoints({Set<Uuid>? caveUuids}) async {
    if (caveUuids != null && caveUuids.isEmpty) return const [];
    final (places, caves) = await (
      _places.getCavePlacesWithCoordinates(),
      _caves.getCaves(),
    ).wait;
    final caveTitles = {for (final cave in caves) cave.uuid: cave.title};

    return [
      for (final place in places)
        if (caveUuids == null || caveUuids.contains(place.caveUuid))
          GeoWaypoint(
            name: resolveListLabel(
              caveTitle: caveTitles[place.caveUuid] ?? '',
              placeTitle: place.title,
            ),
            latitude: place.latitude!,
            longitude: place.longitude!,
            altitude: place.altitude,
            description: place.description,
          ),
    ];
  }

  /// Creates one place per waypoint in [caveUuid], atomically — a failure
  /// mid-list rolls the whole import back. A trailing ` - <cave title>`
  /// (this app's own export decoration) is stripped so re-importing an
  /// export dedupes against the original places instead of twinning them.
  /// Waypoints whose name matches an existing place title in the cave
  /// (case-insensitive) are skipped; unnamed ones get a numbered fallback
  /// title.
  Future<PlaceImportResult> importWaypoints(
    Uuid caveUuid,
    List<GeoWaypoint> waypoints, {
    String fallbackTitle = 'Waypoint',
  }) async {
    return _database.transaction(() async {
      final (existing, cave) = await (
        _places.getCavePlaces(caveUuid),
        _caves.findById(caveUuid),
      ).wait;
      final taken = {for (final place in existing) place.title.toLowerCase()};
      final exportSuffix = cave == null
          ? null
          : ' - ${cave.title}'.toLowerCase();

      var created = 0, skipped = 0, unnamed = 0;
      for (final waypoint in waypoints) {
        var title = waypoint.name.trim();
        if (exportSuffix != null &&
            title.toLowerCase().endsWith(exportSuffix) &&
            title.length > exportSuffix.length) {
          title = title.substring(0, title.length - exportSuffix.length).trim();
        }
        if (title.isEmpty) {
          unnamed++;
          title = '$fallbackTitle $unnamed';
        }
        if (!taken.add(title.toLowerCase())) {
          skipped++;
          continue;
        }
        await _places.addCavePlaceFromCompanion(
          CavePlacesCompanion.insert(
            uuid: Uuid.v7(),
            title: title,
            caveUuid: caveUuid,
            latitude: Value(waypoint.latitude),
            longitude: Value(waypoint.longitude),
            altitude: Value(waypoint.altitude),
            description: Value(waypoint.description),
          ),
        );
        created++;
      }
      return (created: created, skipped: skipped);
    });
  }
}
