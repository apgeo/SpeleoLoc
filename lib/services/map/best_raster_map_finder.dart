import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/state/raster_map_sort_options.dart';

/// The raster map a place opens on: the first map, in the caver's saved map
/// order, that has the place pinned.
class BestRasterMapFinder {
  BestRasterMapFinder(this._maps, this._pins);

  final IRasterMapRepository _maps;
  final IDefinitionRepository _pins;

  /// Null when no map of the place's cave pins it.
  Future<Uuid?> bestMapFor(CavePlace place) async {
    final maps = await _maps.getRasterMaps(place.caveUuid);
    if (maps.isEmpty) return null;
    final sortOption = await RasterMapSortOption.load();
    for (final map in sortOption.apply(maps, [])) {
      if (await _pins.findDefinition(place.uuid, map.uuid) != null) {
        return map.uuid;
      }
    }
    return null;
  }
}
