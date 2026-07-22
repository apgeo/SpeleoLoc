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
  PlaceTransferService(this._caves, this._places);

  final ICaveRepository _caves;
  final ICavePlaceRepository _places;

  /// Every place with coordinates, optionally restricted to [caveUuids]
  /// (null or empty = all caves). Waypoint names use the list label
  /// (`<place> - <cave>`) so they stay unambiguous in external tools.
  Future<List<GeoWaypoint>> collectWaypoints({Set<Uuid>? caveUuids}) async {
    final (places, caves) = await (
      _places.getCavePlacesWithCoordinates(),
      _caves.getCaves(),
    ).wait;
    final caveTitles = {for (final cave in caves) cave.uuid: cave.title};

    return [
      for (final place in places)
        if (caveUuids == null ||
            caveUuids.isEmpty ||
            caveUuids.contains(place.caveUuid))
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

  /// Creates one place per waypoint in [caveUuid]. Waypoints whose name
  /// matches an existing place title in the cave (case-insensitive) are
  /// skipped rather than twinned; unnamed waypoints get a numbered
  /// fallback title.
  Future<PlaceImportResult> importWaypoints(
    Uuid caveUuid,
    List<GeoWaypoint> waypoints, {
    String fallbackTitle = 'Waypoint',
  }) async {
    final existing = await _places.getCavePlaces(caveUuid);
    final taken = {for (final place in existing) place.title.toLowerCase()};

    var created = 0, skipped = 0, unnamed = 0;
    for (final waypoint in waypoints) {
      var title = waypoint.name.trim();
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
  }
}
