/// Sort models for the raster-map and cave-place nav-bar lists.
///
/// Pure Dart (no Flutter imports) so non-UI code — e.g. the beacon detection
/// service picking the best map to open — can apply the user's persisted sort
/// without depending on the widget layer. The picker dialogs live in
/// `widgets/raster_map/raster_map_sort_options.dart`, which re-exports this
/// file for UI callers.
library;

import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/utils/constants.dart';

// ---------------------------------------------------------------------------
// Cave-place nav bar sort options
// ---------------------------------------------------------------------------

/// Field by which the cave-places horizontal list (nav bar) is sorted.
enum CavePlaceSortField {
  lastModified,
  title,
  caveArea,
  depth,
  qrCodeIdentifier,
  isEntrance,
  hasQrCode,
  definitionsCount,
}

/// Bundles sort field + direction for the cave-places nav bar.
class CavePlaceSortOption {
  const CavePlaceSortOption({
    this.field = CavePlaceSortField.lastModified,
    this.ascending = false,
  });

  final CavePlaceSortField field;
  final bool ascending;

  /// Whether the current sort field produces visible grouping in the list.
  bool get groupByCaveArea => field == CavePlaceSortField.caveArea;

  CavePlaceSortOption copyWith({CavePlaceSortField? field, bool? ascending}) =>
      CavePlaceSortOption(
        field: field ?? this.field,
        ascending: ascending ?? this.ascending,
      );

  /// Loads the persisted cave-places nav bar sort. Returns `null` if nothing
  /// has been saved yet (so the caller can fall back to another source).
  static Future<CavePlaceSortOption?> _loadIfSaved() async {
    final fieldStr = await SettingsHelper.loadStringConfig(
      cavePlacesNavBarSortFieldKey,
    );
    if (fieldStr.isEmpty) return null;
    final ascStr = await SettingsHelper.loadStringConfig(
      cavePlacesNavBarSortAscKey,
      'false',
    );
    final field = CavePlaceSortField.values.firstWhere(
      (f) => f.name == fieldStr,
      orElse: () => CavePlaceSortField.lastModified,
    );
    return CavePlaceSortOption(field: field, ascending: ascStr == 'true');
  }

  /// Loads the persisted sort.  When no nav-bar-specific config exists, falls
  /// back to the sort currently set in [CavePlacesListPage] (read from the
  /// `filterable_sort_cave_places_list_sort` config key).
  static Future<CavePlaceSortOption> load() async {
    final saved = await _loadIfSaved();
    if (saved != null) return saved;

    // Fall back: read CavePlacesListPage sort
    final json = await SettingsHelper.loadJsonConfig(
      'filterable_sort_cave_places_list_sort',
      () => const {},
    );
    final primaryFieldId = json['primaryFieldId'] as String? ?? 'last_modified';
    final primaryAscending = json['primaryAscending'] as bool? ?? false;
    const idToField = {
      'last_modified': CavePlaceSortField.lastModified,
      'title': CavePlaceSortField.title,
      'cave_area': CavePlaceSortField.caveArea,
      'depth': CavePlaceSortField.depth,
      'qr_code_identifier': CavePlaceSortField.qrCodeIdentifier,
      'is_entrance': CavePlaceSortField.isEntrance,
      'has_qr_code': CavePlaceSortField.hasQrCode,
      'definitions_count': CavePlaceSortField.definitionsCount,
    };
    return CavePlaceSortOption(
      field: idToField[primaryFieldId] ?? CavePlaceSortField.lastModified,
      ascending: primaryAscending,
    );
  }

  /// Persists this sort option.
  Future<void> save() async {
    await SettingsHelper.saveStringConfig(
      cavePlacesNavBarSortFieldKey,
      field.name,
    );
    await SettingsHelper.saveStringConfig(
      cavePlacesNavBarSortAscKey,
      ascending.toString(),
    );
  }

  /// Returns a sorted copy of [places].
  List<CavePlaceWithDefinition> apply(
    List<CavePlaceWithDefinition> places,
    Map<Uuid, String> areaTitles,
    Map<Uuid, int> definitionCountByPlace,
  ) {
    final sorted = List<CavePlaceWithDefinition>.from(places);
    final dir = ascending ? 1 : -1;
    switch (field) {
      case CavePlaceSortField.lastModified:
        sorted.sort(
          (a, b) =>
              dir *
              (a.cavePlace.updatedAt ?? 0).compareTo(
                b.cavePlace.updatedAt ?? 0,
              ),
        );
      case CavePlaceSortField.title:
        sorted.sort(
          (a, b) =>
              dir *
              a.cavePlace.title.toLowerCase().compareTo(
                b.cavePlace.title.toLowerCase(),
              ),
        );
      case CavePlaceSortField.caveArea:
        sorted.sort((a, b) {
          final at = a.cavePlace.caveAreaUuid != null
              ? (areaTitles[a.cavePlace.caveAreaUuid] ?? '')
              : '';
          final bt = b.cavePlace.caveAreaUuid != null
              ? (areaTitles[b.cavePlace.caveAreaUuid] ?? '')
              : '';
          return dir * at.toLowerCase().compareTo(bt.toLowerCase());
        });
      case CavePlaceSortField.depth:
        sorted.sort(
          (a, b) =>
              dir *
              (a.cavePlace.depthInCave ?? double.infinity).compareTo(
                b.cavePlace.depthInCave ?? double.infinity,
              ),
        );
      case CavePlaceSortField.qrCodeIdentifier:
        sorted.sort((a, b) {
          final av = a.cavePlace.placeCodeIdentifier;
          final bv = b.cavePlace.placeCodeIdentifier;
          if (av == null && bv == null) return 0;
          if (av == null) return dir;
          if (bv == null) return -dir;
          return dir * av.compareTo(bv);
        });
      case CavePlaceSortField.isEntrance:
        int rank(CavePlace p) =>
            p.isMainEntrance == 1 ? 2 : (p.isEntrance == 1 ? 1 : 0);
        sorted.sort(
          (a, b) => dir * rank(a.cavePlace).compareTo(rank(b.cavePlace)),
        );
      case CavePlaceSortField.hasQrCode:
        sorted.sort(
          (a, b) =>
              dir *
              (a.cavePlace.placeCodeIdentifier != null ? 1 : 0).compareTo(
                b.cavePlace.placeCodeIdentifier != null ? 1 : 0,
              ),
        );
      case CavePlaceSortField.definitionsCount:
        sorted.sort(
          (a, b) =>
              dir *
              (definitionCountByPlace[a.cavePlace.uuid] ?? 0).compareTo(
                definitionCountByPlace[b.cavePlace.uuid] ?? 0,
              ),
        );
    }
    return sorted;
  }
}

// ---------------------------------------------------------------------------
// Raster-map sort options
// ---------------------------------------------------------------------------

/// Field by which the raster-map list (nav bar thumbnails) is sorted.
enum RasterMapSortField {
  /// Manual order set by the user in RasterMapsPage (default).
  orderIndex,

  /// Number of cave places currently defined on the map (descending by default).
  placeCount,

  /// Map title, alphabetical.
  title,

  /// File size in bytes (proxy for map area / resolution).
  fileSize,
}

/// Bundles sort field + direction into one value that can be stored in the
/// controller and compared cheaply.
class RasterMapSortOption {
  const RasterMapSortOption({
    this.field = RasterMapSortField.orderIndex,
    this.ascending = true,
  });

  final RasterMapSortField field;
  final bool ascending;

  RasterMapSortOption copyWith({RasterMapSortField? field, bool? ascending}) =>
      RasterMapSortOption(
        field: field ?? this.field,
        ascending: ascending ?? this.ascending,
      );

  /// Load the persisted sort option from settings.
  static Future<RasterMapSortOption> load() async {
    final fieldStr = await SettingsHelper.loadStringConfig(
      rasterMapSortFieldKey,
      RasterMapSortField.orderIndex.name,
    );
    final ascStr = await SettingsHelper.loadStringConfig(
      rasterMapSortAscKey,
      'true',
    );
    final field = RasterMapSortField.values.firstWhere(
      (f) => f.name == fieldStr,
      orElse: () => RasterMapSortField.orderIndex,
    );
    return RasterMapSortOption(field: field, ascending: ascStr == 'true');
  }

  /// Persist this sort option to settings.
  Future<void> save() async {
    await SettingsHelper.saveStringConfig(rasterMapSortFieldKey, field.name);
    await SettingsHelper.saveStringConfig(
      rasterMapSortAscKey,
      ascending.toString(),
    );
  }

  /// Returns a sorted copy of [maps] using place-count data from [defs].
  List<RasterMap> apply(
    List<RasterMap> maps,
    List<CavePlaceWithDefinition> defs,
  ) {
    final sorted = List<RasterMap>.from(maps);
    final dir = ascending ? 1 : -1;
    switch (field) {
      case RasterMapSortField.orderIndex:
        sorted.sort((a, b) => dir * a.orderIndex.compareTo(b.orderIndex));
      case RasterMapSortField.placeCount:
        // Count how many definitions belong to each raster map.
        final counts = <Uuid, int>{};
        for (final d in defs) {
          if (d.definition != null) {
            final rmUuid = d.definition!.rasterMapUuid;
            counts[rmUuid] = (counts[rmUuid] ?? 0) + 1;
          }
        }
        sorted.sort(
          (a, b) => dir * (counts[a.uuid] ?? 0).compareTo(counts[b.uuid] ?? 0),
        );
      case RasterMapSortField.title:
        sorted.sort((a, b) => dir * a.title.compareTo(b.title));
      case RasterMapSortField.fileSize:
        sorted.sort(
          (a, b) => dir * (a.fileSize ?? 0).compareTo(b.fileSize ?? 0),
        );
    }
    return sorted;
  }
}
