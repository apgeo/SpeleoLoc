import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/localization.dart';

/// Configuration that controls sizing and layout of the [RasterMapNavBar].
class RasterMapNavBarStyle {
  const RasterMapNavBarStyle({
    this.rasterMapItemWidth = 96,
    this.rasterMapImageSize = 56,
    this.rasterMapPlaceholderSize = 64,
    this.rasterMapIconSize = 32,
    this.rasterMapBrokenIconSize = 28,
    this.rasterMapTitleFontSize = 11.0,
    this.rasterMapTitleWidth = 84,
    this.rasterMapListHeight,
    this.rasterMapListHeightFraction = 0.14,
    this.rasterMapListMaxHeight = 96,
    this.rasterMapListMaxHeightNoTitle = 72,
    this.rasterMapItemMarginH = 6.0,
    this.rasterMapItemMarginV = 8.0,
    this.showRasterMapTitles = true,
    this.placesAvatarRadius = 12.0,
    this.placesAvatarRadiusSelected = 14.0,
    this.placesTitleFontSize = 12.0,
    this.placesTitleWidth = 80,
    this.placesListHeight,
    this.placesListHeightFraction = 0.09,
    this.placesListMaxHeight = 72,
  });

  /// Compact style for embedding inside RasterMapPlacePointEditor.
  const RasterMapNavBarStyle.compact()
      : rasterMapItemWidth = 64,
        rasterMapImageSize = 36,
        rasterMapPlaceholderSize = 42,
        rasterMapIconSize = 22,
        rasterMapBrokenIconSize = 18,
        rasterMapTitleFontSize = 9.0,
        rasterMapTitleWidth = 56,
        rasterMapListHeight = null,
        rasterMapListHeightFraction = 0.10,
        rasterMapListMaxHeight = 64,
        rasterMapListMaxHeightNoTitle = 48,
        rasterMapItemMarginH = 4.0,
        rasterMapItemMarginV = 4.0,
        showRasterMapTitles = true,
        placesAvatarRadius = 9.0,
        placesAvatarRadiusSelected = 11.0,
        placesTitleFontSize = 10.0,
        placesTitleWidth = 60,
        placesListHeight = null,
        placesListHeightFraction = 0.08,
        placesListMaxHeight = 56;

  final double rasterMapItemWidth;
  final double rasterMapImageSize;
  final double rasterMapPlaceholderSize;
  final double rasterMapIconSize;
  final double rasterMapBrokenIconSize;
  final double rasterMapTitleFontSize;
  final double rasterMapTitleWidth;
  final double? rasterMapListHeight;
  final double rasterMapListHeightFraction;
  final double rasterMapListMaxHeight;
  /// Max height to use for the raster-maps list when [showRasterMapTitles] is
  /// false (tighter, since no title row is rendered).
  final double rasterMapListMaxHeightNoTitle;
  final double rasterMapItemMarginH;
  final double rasterMapItemMarginV;
  /// When false the horizontal raster-maps list renders only the thumbnails
  /// (no title under each item) and the row collapses to a smaller height.
  final bool showRasterMapTitles;
  final double placesAvatarRadius;
  final double placesAvatarRadiusSelected;
  final double placesTitleFontSize;
  final double placesTitleWidth;
  final double? placesListHeight;
  final double placesListHeightFraction;
  final double placesListMaxHeight;

  /// Returns a copy of this style with selected fields overridden.
  RasterMapNavBarStyle copyWith({
    bool? showRasterMapTitles,
  }) {
    return RasterMapNavBarStyle(
      rasterMapItemWidth: rasterMapItemWidth,
      rasterMapImageSize: rasterMapImageSize,
      rasterMapPlaceholderSize: rasterMapPlaceholderSize,
      rasterMapIconSize: rasterMapIconSize,
      rasterMapBrokenIconSize: rasterMapBrokenIconSize,
      rasterMapTitleFontSize: rasterMapTitleFontSize,
      rasterMapTitleWidth: rasterMapTitleWidth,
      rasterMapListHeight: rasterMapListHeight,
      rasterMapListHeightFraction: rasterMapListHeightFraction,
      rasterMapListMaxHeight: rasterMapListMaxHeight,
      rasterMapListMaxHeightNoTitle: rasterMapListMaxHeightNoTitle,
      rasterMapItemMarginH: rasterMapItemMarginH,
      rasterMapItemMarginV: rasterMapItemMarginV,
      showRasterMapTitles: showRasterMapTitles ?? this.showRasterMapTitles,
      placesAvatarRadius: placesAvatarRadius,
      placesAvatarRadiusSelected: placesAvatarRadiusSelected,
      placesTitleFontSize: placesTitleFontSize,
      placesTitleWidth: placesTitleWidth,
      placesListHeight: placesListHeight,
      placesListHeightFraction: placesListHeightFraction,
      placesListMaxHeight: placesListMaxHeight,
    );
  }
}

/// A reusable widget containing:
///  - Horizontal list of raster maps for selection.
///  - Horizontal list of cave places for quick navigation.
///
/// Both lists respond to item taps via callbacks. The widget does NOT own
/// any database or editor state — the parent provides data and handles
/// actions through callbacks.
class RasterMapNavBar extends StatefulWidget {
  const RasterMapNavBar({
    super.key,
    required this.rasterMaps,
    required this.cavePlacesWithDefinitions,
    required this.selectedRasterMapUuid,
    required this.selectedPlaceId,
    required this.onRasterMapSelected,
    required this.onCavePlaceSelected,
    this.style = const RasterMapNavBarStyle(),
    this.imageProviderCache,
    this.placesListAlignment = 0.5,
    this.showRasterMapsList = true,
    this.showCavePlacesList = true,
    this.caveAreaTitles = const {},
    this.groupByCaveArea = false,
    this.onVisiblePlaceUuidsChanged,
  });

  final List<RasterMap> rasterMaps;
  final List<CavePlaceWithDefinition> cavePlacesWithDefinitions;
  final Uuid? selectedRasterMapUuid;
  final Uuid? selectedPlaceId;
  final void Function(RasterMap rm) onRasterMapSelected;
  final void Function(CavePlaceWithDefinition cpwd) onCavePlaceSelected;
  final RasterMapNavBarStyle style;

  /// Shared image-provider cache so thumbnails are not re-decoded.
  final Map<String, ImageProvider>? imageProviderCache;

  /// Alignment used when auto-scrolling to the selected cave place item.
  final double placesListAlignment;

  final bool showRasterMapsList;
  final bool showCavePlacesList;

  /// When provided and [groupByCaveArea] is true, the places list displays
  /// items grouped visually by cave area using these titles for headers.
  final Map<Uuid, String> caveAreaTitles;

  /// When true, the cave-places horizontal list renders items in grouped
  /// "area boxes" (requires [caveAreaTitles] to be populated).
  final bool groupByCaveArea;

  /// Called whenever the active filter changes.  The argument is a
  /// [Set<Uuid>] of the place UUIDs that pass the filter, or `null` when
  /// the filter is cleared (meaning all places are visible).  The parent
  /// widget uses this to hide/show map markers accordingly.
  final void Function(Set<Uuid>?)? onVisiblePlaceUuidsChanged;

  @override
  State<RasterMapNavBar> createState() => RasterMapNavBarState();
}

class RasterMapNavBarState extends State<RasterMapNavBar> {
  // scroll controller + keys for the horizontal cave-places list
  final ScrollController _placesScrollController = ScrollController();
  final Map<Uuid, GlobalKey> _placeItemKeys = {};

  // Notifier so the places list updates efficiently without full rebuild.
  final ValueNotifier<Uuid?> _selectedPlaceNotifier = ValueNotifier<Uuid?>(null);

  // Cache for image path futures so they're not re-awaited on rebuild
  final Map<String, Future<String>> _imagePathFutures = {};

  // ── Cave-places text filter ───────────────────────────────────────────────
  /// Whether the filter text field is currently shown.
  bool _filterVisible = false;

  /// Controller for the filter text field.
  final TextEditingController _filterController = TextEditingController();

  /// The currently-active filter set.  `null` = no filter (all visible).
  /// Non-null = only the UUIDs in this set should be shown.
  Set<Uuid>? _filteredIds;

  @override
  void initState() {
    super.initState();
    _selectedPlaceNotifier.value = widget.selectedPlaceId;
  }

  @override
  void didUpdateWidget(covariant RasterMapNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPlaceId != oldWidget.selectedPlaceId) {
      _selectedPlaceNotifier.value = widget.selectedPlaceId;
    }
    // When the places list is replaced (e.g. after sorting), re-apply any
    // active filter so the map markers and horizontal list stay in sync.
    if (!identical(widget.cavePlacesWithDefinitions, oldWidget.cavePlacesWithDefinitions) &&
        _filterController.text.isNotEmpty) {
      _applyFilter(_filterController.text);
    }
  }

  @override
  void dispose() {
    _placesScrollController.dispose();
    _selectedPlaceNotifier.dispose();
    _filterController.dispose();
    super.dispose();
  }

  /// Programmatically update the selected place id and scroll to it.
  void setSelectedPlaceId(Uuid? id) {
    _selectedPlaceNotifier.value = id;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ensurePlaceItemVisible(id);
      });
    }
  }

  void ensurePlaceItemVisible(Uuid cavePlaceUuid) {
    final key = _placeItemKeys[cavePlaceUuid];
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      alignment: widget.placesListAlignment,
      curve: Curves.easeInOut,
    );
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  /// Toggles the filter text field visibility.  Clears the filter when hiding.
  void toggleFilter() {
    setState(() {
      _filterVisible = !_filterVisible;
      if (!_filterVisible && _filterController.text.isNotEmpty) {
        _filterController.clear();
        _applyFilter('');
      }
    });
  }

  /// Recomputes [_filteredIds] from [query] and notifies the parent.
  void _applyFilter(String query) {
    final q = query.toLowerCase().trim();
    Set<Uuid>? result;
    if (q.isEmpty) {
      result = null;
    } else {
      result = {};
      for (final cpwd in widget.cavePlacesWithDefinitions) {
        final cp = cpwd.cavePlace;
        bool match = cp.title.toLowerCase().contains(q);
        if (!match) match = cp.description?.toLowerCase().contains(q) ?? false;
        if (!match) {
          match = cp.placeCodeIdentifier?.toLowerCase().contains(q) ?? false;
        }
        if (!match) {
          final areaTitle = cp.caveAreaUuid != null
              ? (widget.caveAreaTitles[cp.caveAreaUuid] ?? '')
              : '';
          match = areaTitle.toLowerCase().contains(q);
        }
        if (match) result.add(cp.uuid);
      }
    }
    setState(() => _filteredIds = result);
    widget.onVisiblePlaceUuidsChanged?.call(result);
  }

  /// Builds the compact filter input row shown above the places list.
  Widget _buildFilterRow(BuildContext context, RasterMapNavBarStyle s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
      child: SizedBox(
        height: 34,
        child: TextField(
          controller: _filterController,
          autofocus: true,
          style: TextStyle(fontSize: s.placesTitleFontSize + 1),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            hintText: LocServ.inst.t('filter_cave_places'),
            hintStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17)),
            suffixIcon: ListenableBuilder(
              listenable: _filterController,
              builder: (_, __) => _filterController.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        _filterController.clear();
                        _applyFilter('');
                      },
                    ),
            ),
          ),
          onChanged: _applyFilter,
        ),
      ),
    );
  }

  Future<String> _getImagePath(String fileName) {
    return _imagePathFutures[fileName] ??= (() async {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/$fileName';
    })();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showRasterMapsList) _buildRasterMapsList(context, s),
        if (widget.showCavePlacesList && _filterVisible)
          _buildFilterRow(context, s),
        if (widget.showCavePlacesList) _buildCavePlacesList(context, s),
      ],
    );
  }

  // ---- Raster maps horizontal list ----

  Widget _buildRasterMapsList(BuildContext context, RasterMapNavBarStyle s) {
    final screenH = MediaQuery.of(context).size.height;
    final double listHeight;
    if (s.showRasterMapTitles) {
      listHeight =
          s.rasterMapListHeight ?? math.min(s.rasterMapListMaxHeight, screenH * s.rasterMapListHeightFraction);
    } else {
      // Titles hidden: collapse to the thumbnail height plus a small breathing
      // room so the row occupies minimal vertical space.
      listHeight = math.min(
        s.rasterMapListMaxHeightNoTitle,
        s.rasterMapPlaceholderSize + (s.rasterMapItemMarginV * 2) + 4,
      );
    }
    // Tighter vertical padding when titles are off so the band stays compact.
    final vPad = s.showRasterMapTitles ? 10.0 : 2.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: vPad),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: listHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.rasterMaps.length,
                itemBuilder: (context, i) {
                  final rm = widget.rasterMaps[i];
                  final isSelected = widget.selectedRasterMapUuid == rm.uuid;
                  return GestureDetector(
                    onTap: () => widget.onRasterMapSelected(rm),
                    child: Container(
                      width: s.rasterMapItemWidth,
                      margin: EdgeInsets.symmetric(
                          horizontal: s.rasterMapItemMarginH, vertical: s.rasterMapItemMarginV),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                            width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FutureBuilder<String>(
                            future: _getImagePath(rm.fileName),
                            builder: (ctx, snap) {
                              if (!snap.hasData) {
                                return Container(
                                  width: s.rasterMapPlaceholderSize,
                                  height: s.rasterMapPlaceholderSize,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                                  child: Icon(Icons.map, size: s.rasterMapIconSize, color: Colors.grey),
                                );
                              }
                              final f = File(snap.data!);
                              if (!f.existsSync()) {
                                return Container(
                                  width: s.rasterMapPlaceholderSize,
                                  height: s.rasterMapPlaceholderSize,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                                  child: Icon(Icons.broken_image,
                                      size: s.rasterMapBrokenIconSize, color: Colors.grey),
                                );
                              }
                              final cache = widget.imageProviderCache;
                              final provider =
                                  cache != null ? (cache[snap.data!] ??= FileImage(File(snap.data!))) : FileImage(f);
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image(
                                    image: provider,
                                    width: s.rasterMapImageSize,
                                    height: s.rasterMapImageSize,
                                    fit: BoxFit.cover),
                              );
                            },
                          ),
                          if (s.showRasterMapTitles) ...[
                            const SizedBox(height: 4),
                            Flexible(
                              child: SizedBox(
                                width: s.rasterMapTitleWidth,
                                child: Text(
                                  rm.title,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(fontSize: s.rasterMapTitleFontSize),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Cave places horizontal list ----

  Widget _buildCavePlacesList(BuildContext context, RasterMapNavBarStyle s) {
    final screenH = MediaQuery.of(context).size.height;
    final listHeight =
        s.placesListHeight ?? math.min(s.placesListMaxHeight, screenH * s.placesListHeightFraction);
    final titleGap = listHeight <= 44 ? 1.0 : 2.0;

    // Group-header strip height (only in cave-area grouping mode)
    const double groupHeaderHeight = 14.0;
    const double groupHeaderFontSize = 9.0;

    // Apply active filter (null means show all).
    final displayList = _filteredIds == null
        ? widget.cavePlacesWithDefinitions
        : widget.cavePlacesWithDefinitions
            .where((c) => _filteredIds!.contains(c.cavePlace.uuid))
            .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ValueListenableBuilder<Uuid?>(
        valueListenable: _selectedPlaceNotifier,
        builder: (context, selectedId, _) {
          if (widget.groupByCaveArea && displayList.isNotEmpty) {
            // ── Grouped mode: SingleChildScrollView + Row of area boxes ───────
            final groups = _groupByCaveArea(displayList);
            return SizedBox(
              height: listHeight + groupHeaderHeight + 8,
              child: SingleChildScrollView(
                controller: _placesScrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groups.map((g) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        borderRadius: BorderRadius.circular(6),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Cave area title strip
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 2, 4, 1),
                            child: SizedBox(
                              height: groupHeaderHeight,
                              child: Text(
                                g.areaTitle,
                                style: TextStyle(
                                  fontSize: groupHeaderFontSize,
                                  color: Theme.of(context).hintColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Items in the group
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: g.items.map((cpwd) {
                              final hasDef = cpwd.definition != null &&
                                  cpwd.definition!.xCoordinate != null &&
                                  cpwd.definition!.yCoordinate != null;
                              final isSelected = selectedId != null &&
                                  selectedId == cpwd.cavePlace.uuid;
                              final key = _placeItemKeys.putIfAbsent(
                                  cpwd.cavePlace.uuid, () => GlobalKey());
                              return GestureDetector(
                                onTap: () {
                                  _selectedPlaceNotifier.value = cpwd.cavePlace.uuid;
                                  widget.onCavePlaceSelected(cpwd);
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    ensurePlaceItemVisible(cpwd.cavePlace.uuid);
                                  });
                                },
                                child: _buildPlaceItem(
                                  context, s, cpwd, isSelected, hasDef,
                                  key, titleGap,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }

          // ── Default mode: ListView.builder ────────────────────────────────
          return SizedBox(
            height: listHeight,
            child: ListView.builder(
              controller: _placesScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: displayList.length,
              itemBuilder: (context, idx) {
                final cpwd = displayList[idx];
                final hasDef = cpwd.definition != null &&
                    cpwd.definition!.xCoordinate != null &&
                    cpwd.definition!.yCoordinate != null;
                final isSelected = selectedId != null && selectedId == cpwd.cavePlace.uuid;
                final key = _placeItemKeys.putIfAbsent(
                    cpwd.cavePlace.uuid, () => GlobalKey());

                return GestureDetector(
                  onTap: () {
                    _selectedPlaceNotifier.value = cpwd.cavePlace.uuid;
                    widget.onCavePlaceSelected(cpwd);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ensurePlaceItemVisible(cpwd.cavePlace.uuid);
                    });
                  },
                  child: _buildPlaceItem(
                    context, s, cpwd, isSelected, hasDef, key, titleGap,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Builds a single place item widget (shared by flat and grouped modes).
  Widget _buildPlaceItem(
    BuildContext context,
    RasterMapNavBarStyle s,
    CavePlaceWithDefinition cpwd,
    bool isSelected,
    bool hasDef,
    Key key,
    double titleGap,
  ) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: isSelected
          ? BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                width: 1,
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: isSelected ? s.placesAvatarRadiusSelected : s.placesAvatarRadius,
            backgroundColor: hasDef
                ? (isSelected ? Colors.blue : const Color.fromARGB(255, 252, 136, 127))
                : Colors.grey[400],
            child: Text(
                cpwd.cavePlace.title.isNotEmpty ? cpwd.cavePlace.title[0].toUpperCase() : '?'),
          ),
          SizedBox(height: titleGap),
          SizedBox(
            width: s.placesTitleWidth,
            child: Text(
              cpwd.cavePlace.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                  fontSize: s.placesTitleFontSize,
                  color: isSelected ? Theme.of(context).primaryColor : null),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Groups [places] by cave area, preserving the existing order within each group.
  List<_PlaceGroup> _groupByCaveArea(List<CavePlaceWithDefinition> places) {
    final ordered = <String>[];   // ordered list of group keys (area title)
    final map = <String, List<CavePlaceWithDefinition>>{};

    for (final cpwd in places) {
      final areaTitle = cpwd.cavePlace.caveAreaUuid != null
          ? (widget.caveAreaTitles[cpwd.cavePlace.caveAreaUuid] ?? '')
          : '';
      if (!map.containsKey(areaTitle)) {
        ordered.add(areaTitle);
        map[areaTitle] = [];
      }
      map[areaTitle]!.add(cpwd);
    }

    return ordered
        .map((key) => _PlaceGroup(areaTitle: key.isEmpty ? '—' : key, items: map[key]!))
        .toList();
  }
}

/// Internal data class for a group of places sharing a cave area.
class _PlaceGroup {
  const _PlaceGroup({required this.areaTitle, required this.items});
  final String areaTitle;
  final List<CavePlaceWithDefinition> items;
}
