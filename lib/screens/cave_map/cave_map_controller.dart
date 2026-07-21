import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_item.dart';
import 'package:speleoloc/services/map/place_label_resolver.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/cave_place_flags.dart';

/// View state for the surface map: the place items loaded from the
/// database, the focus filter, the visibility toggles and the selection.
///
/// The visible and paint-ordered lists are derived once per state change
/// here instead of being refiltered and re-sorted on every build frame.
class CaveMapController extends ChangeNotifier {
  CaveMapController({
    required ICavePlaceRepository placeRepository,
    required ICaveRepository caveRepository,
    Set<Uuid>? focusCaveUuids,
    Set<Uuid>? focusPlaceUuids,
  }) : _placeRepository = placeRepository,
       _caveRepository = caveRepository,
       // Empty sets from the callers (nothing checked, or a filter
       // matching nothing) degrade to null — "no filter" instead of an
       // all-grey map that the other-caves toggle can blank entirely.
       _focusCaveUuids = (focusCaveUuids != null && focusCaveUuids.isNotEmpty)
           ? {...focusCaveUuids}
           : null,
       _focusPlaceUuids =
           (focusPlaceUuids != null && focusPlaceUuids.isNotEmpty)
           ? {...focusPlaceUuids}
           : null;

  final ICavePlaceRepository _placeRepository;
  final ICaveRepository _caveRepository;

  /// Mutable focus filter; points created on the map join it so they
  /// render focused. Null = no focus filter.
  Set<Uuid>? _focusCaveUuids;
  Set<Uuid>? _focusPlaceUuids;

  List<CaveMapPlaceItem> _items = const [];
  List<CaveMapPlaceItem> _visibleItems = const [];
  List<CaveMapPlaceItem> _paintOrder = const [];
  bool _showOtherCaves = true;
  bool _showNonEntrances = true;
  Uuid? _selectedUuid;

  List<CaveMapPlaceItem> get items => _items;
  List<CaveMapPlaceItem> get visibleItems => _visibleItems;
  bool get showOtherCaves => _showOtherCaves;
  bool get showNonEntrances => _showNonEntrances;
  Uuid? get selectedUuid => _selectedUuid;

  CaveMapPlaceItem? get selectedItem {
    for (final item in _visibleItems) {
      if (item.uuid == _selectedUuid) return item;
    }
    return null;
  }

  /// Visible items in marker paint order: focused above non-focused,
  /// entrances above plain places, and the selected item on top. The
  /// base order is cached; selection only moves one item to the end.
  List<CaveMapPlaceItem> get paintOrder {
    final selected = selectedItem;
    if (selected == null) return _paintOrder;
    return [
      for (final item in _paintOrder)
        if (item.uuid != selected.uuid) item,
      selected,
    ];
  }

  /// (Re)builds the render items from the database. Does not touch the
  /// camera, so it is also safe after a create/edit.
  Future<void> loadItems() async {
    final (places, entranceCounts, caves) = await (
      _placeRepository.getCavePlacesWithCoordinates(),
      _placeRepository.getEntranceCountsByCave(),
      _caveRepository.getCaves(),
    ).wait;
    final caveTitles = {for (final c in caves) c.uuid: c.title};

    _items = [
      for (final place in places)
        CaveMapPlaceItem(
          place: place,
          caveTitle: caveTitles[place.caveUuid] ?? '',
          point: LatLng(place.latitude!, place.longitude!),
          label: resolvePlaceLabel(
            caveTitle: caveTitles[place.caveUuid] ?? '',
            placeTitle: place.title,
            isEntrance: place.isAnyEntrance,
            caveEntranceCount: entranceCounts[place.caveUuid] ?? 0,
          ),
          isEntrance: place.isAnyEntrance,
          isMainEntrance: place.isMainEntrance == 1,
          isFocus: _isFocusPlace(place),
        ),
    ];
    _rebuildDerived();
    notifyListeners();
  }

  void toggleOtherCaves() {
    _showOtherCaves = !_showOtherCaves;
    _afterVisibilityChange();
  }

  void toggleNonEntrances() {
    _showNonEntrances = !_showNonEntrances;
    _afterVisibilityChange();
  }

  void select(Uuid? uuid) {
    _selectedUuid = uuid;
    notifyListeners();
  }

  /// Ensures [item] is not filtered out of view (relaxing the toggles
  /// when needed) and selects it.
  void reveal(CaveMapPlaceItem item) {
    if (!item.isFocus) _showOtherCaves = true;
    if (!item.isEntrance) _showNonEntrances = true;
    _rebuildDerived();
    _selectedUuid = item.uuid;
    notifyListeners();
  }

  /// Adds a point created on the map to the focus filter (no-op when no
  /// filter is active — everything is already in focus then). Silent:
  /// callers reload the items right after, which notifies.
  void addToFocus({Uuid? caveUuid, Uuid? placeUuid}) {
    if (_focusCaveUuids == null && _focusPlaceUuids == null) return;
    if (caveUuid != null) (_focusCaveUuids ??= {}).add(caveUuid);
    if (placeUuid != null) (_focusPlaceUuids ??= {}).add(placeUuid);
  }

  bool _isFocusPlace(CavePlace place) {
    if (_focusCaveUuids == null && _focusPlaceUuids == null) return true;
    return (_focusPlaceUuids?.contains(place.uuid) ?? false) ||
        (_focusCaveUuids?.contains(place.caveUuid) ?? false);
  }

  void _afterVisibilityChange() {
    _rebuildDerived();
    if (selectedItem == null) _selectedUuid = null;
    notifyListeners();
  }

  void _rebuildDerived() {
    _visibleItems = [
      for (final item in _items)
        if ((item.isFocus || _showOtherCaves) &&
            (item.isEntrance || _showNonEntrances))
          item,
    ];
    int rank(CaveMapPlaceItem item) =>
        (item.isEntrance ? 1 : 0) + (item.isFocus ? 2 : 0);
    // Indexed sort: List.sort is not stable, and the paint order must not
    // shuffle equal-rank markers between frames.
    final indexed = List<(int, CaveMapPlaceItem)>.generate(
      _visibleItems.length,
      (i) => (i, _visibleItems[i]),
    );
    indexed.sort((a, b) {
      final byRank = rank(a.$2).compareTo(rank(b.$2));
      return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
    });
    _paintOrder = [for (final (_, item) in indexed) item];
  }
}
