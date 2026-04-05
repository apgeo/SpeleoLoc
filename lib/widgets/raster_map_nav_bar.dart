import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

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
    this.rasterMapItemMarginH = 6.0,
    this.rasterMapItemMarginV = 8.0,
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
        rasterMapItemMarginH = 4.0,
        rasterMapItemMarginV = 4.0,
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
  final double rasterMapItemMarginH;
  final double rasterMapItemMarginV;
  final double placesAvatarRadius;
  final double placesAvatarRadiusSelected;
  final double placesTitleFontSize;
  final double placesTitleWidth;
  final double? placesListHeight;
  final double placesListHeightFraction;
  final double placesListMaxHeight;
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
    required this.selectedRasterMapId,
    required this.selectedPlaceId,
    required this.onRasterMapSelected,
    required this.onCavePlaceSelected,
    this.style = const RasterMapNavBarStyle(),
    this.imageProviderCache,
    this.placesListAlignment = 0.5,
    this.showRasterMapsList = true,
    this.showCavePlacesList = true,
  });

  final List<RasterMap> rasterMaps;
  final List<CavePlaceWithDefinition> cavePlacesWithDefinitions;
  final int? selectedRasterMapId;
  final int? selectedPlaceId;
  final void Function(RasterMap rm) onRasterMapSelected;
  final void Function(CavePlaceWithDefinition cpwd) onCavePlaceSelected;
  final RasterMapNavBarStyle style;

  /// Shared image-provider cache so thumbnails are not re-decoded.
  final Map<String, ImageProvider>? imageProviderCache;

  /// Alignment used when auto-scrolling to the selected cave place item.
  final double placesListAlignment;

  final bool showRasterMapsList;
  final bool showCavePlacesList;

  @override
  State<RasterMapNavBar> createState() => RasterMapNavBarState();
}

class RasterMapNavBarState extends State<RasterMapNavBar> {
  // scroll controller + keys for the horizontal cave-places list
  final ScrollController _placesScrollController = ScrollController();
  final Map<int, GlobalKey> _placeItemKeys = {};

  // Notifier so the places list updates efficiently without full rebuild.
  final ValueNotifier<int?> _selectedPlaceNotifier = ValueNotifier<int?>(null);

  // Cache for image path futures so they're not re-awaited on rebuild
  final Map<String, Future<String>> _imagePathFutures = {};

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
  }

  @override
  void dispose() {
    _placesScrollController.dispose();
    _selectedPlaceNotifier.dispose();
    super.dispose();
  }

  /// Programmatically update the selected place id and scroll to it.
  void setSelectedPlaceId(int? id) {
    _selectedPlaceNotifier.value = id;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ensurePlaceItemVisible(id);
      });
    }
  }

  void ensurePlaceItemVisible(int cavePlaceId) {
    final key = _placeItemKeys[cavePlaceId];
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
        if (widget.showCavePlacesList) _buildCavePlacesList(context, s),
      ],
    );
  }

  // ---- Raster maps horizontal list ----

  Widget _buildRasterMapsList(BuildContext context, RasterMapNavBarStyle s) {
    final screenH = MediaQuery.of(context).size.height;
    final listHeight =
        s.rasterMapListHeight ?? math.min(s.rasterMapListMaxHeight, screenH * s.rasterMapListHeightFraction);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 10.0),
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
                  final isSelected = widget.selectedRasterMapId == rm.id;
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: listHeight,
        child: ValueListenableBuilder<int?>(
          valueListenable: _selectedPlaceNotifier,
          builder: (context, selectedId, _) {
            return ListView.builder(
              controller: _placesScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.cavePlacesWithDefinitions.length,
              itemBuilder: (context, idx) {
                final cpwd = widget.cavePlacesWithDefinitions[idx];
                final hasDef = cpwd.definition != null &&
                    cpwd.definition!.xCoordinate != null &&
                    cpwd.definition!.yCoordinate != null;
                final isSelected = selectedId != null && selectedId == cpwd.cavePlace.id;

                final key = _placeItemKeys.putIfAbsent(cpwd.cavePlace.id, () => GlobalKey());

                return GestureDetector(
                  onTap: () {
                    _selectedPlaceNotifier.value = cpwd.cavePlace.id;
                    widget.onCavePlaceSelected(cpwd);

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ensurePlaceItemVisible(cpwd.cavePlace.id);
                    });
                  },
                  child: Container(
                    key: key,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.12), //withOpacity
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.35), //withOpacity
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
                          child:
                              Text(cpwd.cavePlace.title.isNotEmpty ? cpwd.cavePlace.title[0].toUpperCase() : '?'),
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
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
