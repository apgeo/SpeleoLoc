import 'dart:io';

import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_place_page.dart';
import 'package:speleoloc/screens/geofeature_documents_page.dart';
import 'package:speleoloc/services/documents_controller.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/file_utils.dart';
import 'package:speleoloc/utils/raw_image_data.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';
import 'package:speleoloc/widgets/raster_map_nav_bar.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/screens/general_data/raster_maps_page.dart';

class MapViewerPage extends StatefulWidget {
  const MapViewerPage({
    super.key,
    required this.cavePlaceUuid,
    this.caveUuid,
    this.initialRasterMapUuid,
    this.placesListAlignment = 0.5,
    this.allowEditorOverflow = false,
  });

  final Uuid cavePlaceUuid;

  /// Optional cave context. When provided and [cavePlaceUuid] resolves to null
  /// (e.g. id == 0), raster maps for this cave are still loaded.
  final Uuid? caveUuid;

  /// When set (e.g. from a QR scan), the viewer pre-selects this raster map
  /// instead of defaulting to the first one in the sorted list.
  final Uuid? initialRasterMapUuid;

  /// Horizontal alignment used when bringing a cave-place item into view
  /// (0.0 = left, 0.5 = center, 1.0 = right).
  final double placesListAlignment;

  /// If true, the inner `RasterMapPlacePointEditor` is allowed to paint
  /// outside its initial bounds when panned/zoomed (original behavior).
  /// If false (default), the editor is clipped to its layout box so the
  /// map cannot visually overlap other controls.
  final bool allowEditorOverflow;

  @override
  State<MapViewerPage> createState() => _MapViewerPageState();
}

class _MapViewerPageState extends State<MapViewerPage> with SingleTickerProviderStateMixin, AppBarMenuMixin<MapViewerPage>, ProductTourMixin<MapViewerPage> {
  static final _log = AppLogger.of('MapViewerPage');
  @override
  String get tourId => 'map_viewer';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'map', titleLocKey: 'tour_map_viewer_map_title', bodyLocKey: 'tour_map_viewer_map_body'),
    TourStepDef(keyId: 'navbar', titleLocKey: 'tour_map_viewer_navbar_title', bodyLocKey: 'tour_map_viewer_navbar_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_map_viewer_menu_title', bodyLocKey: 'tour_map_viewer_menu_body'),
  ];

  CavePlace? _cavePlace;
  List<RasterMap> _rasterMaps = [];
  RasterMap? _selectedRasterMap;
  List<CavePlaceWithDefinition> _placesWithDefs = [];
  Uuid? _selectedPlaceId;

  static const bool SHOW_CAVE_PLACE_ACTIONS_IN_APP_BAR = false;

  final RasterMapPlacePointEditorController _editorController = RasterMapPlacePointEditorController(
    showLegend: false,
    showZoomControls: true,
    gestureZoomEnabled: true,
    keepZoomOnNavigation: true,
    autoZoomToPoints: false,
    initialZoomLevel: 1.0,
  );
  final GlobalKey _childKey = GlobalKey();

  RawImageData? _decodedImage;
  bool _isDecodingImage = false;
  final Map<String, ImageProvider> _imageProviderCache = {};
  File? _imageFile;

  // loading flag to show progress while raster maps are being loaded
  bool _isLoading = true;

  // Compact nav bar mode toggle
  bool _compactNavBar = false;

  /// When true the AppBar is hidden (full-screen map mode).
  bool _isFullScreen = false;

  // Key for the RasterMapNavBar so we can programmatically scroll items.
  final GlobalKey<RasterMapNavBarState> _navBarKey = GlobalKey<RasterMapNavBarState>();


  
  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _loadAll();
    _loadCompactNavState();
  }

  Future<void> _loadCompactNavState() async {
    final val = await SettingsHelper.loadStringConfig(compactNavBarKey, 'false');
    if (mounted) setState(() => _compactNavBar = val == 'true');
  }

  Future<void> _loadAll() async {
    // Load persisted sort option so the initial order matches the user's preference.
    final savedSort = await RasterMapSortOption.load();
    _editorController.sortOption = savedSort;

    // Load cave place and raster maps for its cave
    _cavePlace = await cavePlaceRepository.findById(widget.cavePlaceUuid);
    if (_cavePlace == null) {
      // If an explicit caveUuid was provided, still load raster maps for that cave.
      if (widget.caveUuid != null) {
        _rasterMaps = await rasterMapRepository.getRasterMaps(widget.caveUuid!);
        _rasterMaps = _editorController.sortOption.apply(_rasterMaps, []);
        if (_rasterMaps.isNotEmpty) {
          _selectedRasterMap = _rasterMaps.first;
          await _loadDefinitionsForSelected();
        }
      }
      _isLoading = false;
      if (mounted) setState(() {});
      return;
    }
    final Uuid caveUuid = _cavePlace!.caveUuid;
    _rasterMaps = await rasterMapRepository.getRasterMaps(caveUuid);
    _rasterMaps = _editorController.sortOption.apply(_rasterMaps, _placesWithDefs);

    // default selected place is the one passed in (must be set BEFORE
    // loading definitions so the editor controller is informed about which
    // cave place should be highlighted as selected).
    _selectedPlaceId = widget.cavePlaceUuid;

    if (_rasterMaps.isNotEmpty) {
      _selectedRasterMap = widget.initialRasterMapUuid != null
          ? _rasterMaps.firstWhere(
              (m) => m.uuid == widget.initialRasterMapUuid,
              orElse: () => _rasterMaps.first,
            )
          : _rasterMaps.first;
      await _loadDefinitionsForSelected();
    }

    _isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _loadDefinitionsForSelected() async {
    if (_selectedRasterMap == null || _cavePlace == null) return;
    // get cave places with definitions for this cave and raster map
    _placesWithDefs = await definitionRepository.getCavePlacesWithDefinitionsForRasterMap(_cavePlace!.caveUuid, _selectedRasterMap!.uuid);

    // inform persistent editor controller about the currently selected place
    // (so it can highlight the corresponding cave place marker without
    // requiring a user tap)
    try {
      _editorController.setCavePlaceId(_selectedPlaceId);
    } catch (e, st) {
      _log.fine('setCavePlaceId failed (initial)', e, st);
    }

    // load image (for color sampling if needed)
    try {
      final path = await getDocumentsFilePath(_selectedRasterMap!.fileName);
      final f = File(path);
      if (f.existsSync()) {
        _imageFile = f;
        _decodedImage = null;
        _isDecodingImage = true;
        final raw = await decodeImageToRawCached(path);
        _decodedImage = raw;
        _isDecodingImage = false;
      } else {
        _imageFile = null;
        _decodedImage = null;
      }
    } catch (e) {
      _log.warning('Error loading image', e);
      _imageFile = null;
      _decodedImage = null;
      _isDecodingImage = false;
    }

    // Reset zoom so a new raster map doesn't inherit the previous scale/position.
    try {
      _editorController.resetZoom();
    } catch (e, st) {
      _log.fine('resetZoom after load failed', e, st);
    }

    // Center on initially selected place if it has coordinates.
    // Use a short delay (instead of a bare postFrameCallback) so that PhotoView
    // has time to finish its first-paint setup before the scale is changed
    // programmatically.  Applying the scale too early can leave the map blank
    // until the next user interaction (pan / zoom / reset).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        final id = _selectedPlaceId;
        final cpwd = id == null
            ? null
            : _placesWithDefs.where((p) => p.cavePlace.uuid == id).firstOrNull;
        final x = cpwd?.definition?.xCoordinate?.toDouble();
        final y = cpwd?.definition?.yCoordinate?.toDouble();
        if (x != null && y != null) {
          _editorController.zoomToPoint(x, y, zoomLevel: 0.8);
        } else {
          // No point to zoom to; call resetZoom to guarantee the map repaints
          // correctly after its first render (works around the same blank-map
          // issue even when there is nothing to zoom to).
          try {
            _editorController.resetZoom();
          } catch (e, st) {
            _log.fine('resetZoom (post-frame fallback) failed', e, st);
          }
        }
      });
    });
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _editorController.detach();
    _imageProviderCache.clear();
    _decodedImage = null;
    super.dispose();
  }

  // ── Sort menu ────────────────────────────────────────────────────────────

  @override
  List<AppMenuItem> get screenMenuItems => [
    AppMenuItem(
      value: 'sort_raster_maps',
      icon: Icons.sort,
      label: LocServ.inst.t('sort_raster_maps'),
    ),
    AppMenuItem(
      value: 'manage_raster_maps',
      icon: Icons.map,
      label: LocServ.inst.t('manage_raster_maps'),
    ),
  ];

  @override
  void onScreenMenuItemSelected(String value) {
    if (value == 'sort_raster_maps') {
      _showSortDialog();
    } else if (value == 'manage_raster_maps') {
      _openRasterMapsPage();
    }
  }

  Future<void> _showSortDialog() async {
    final option = await showRasterMapSortDialog(
      context,
      _editorController.sortOption,
    );
    if (option == null || !mounted) return;
    setState(() {
      _editorController.sortOption = option;
      _rasterMaps = option.apply(_rasterMaps, _placesWithDefs);
    });
    await option.save();
  }

  Future<void> _openRasterMapsPage() async {
    final caveUuid = _cavePlace?.caveUuid ?? widget.caveUuid;
    if (caveUuid == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RasterMapsPage(caveUuid: caveUuid),
      ),
    );
    if ((changed == true) && mounted) {
      _loadAll();
    }
  }

  void _ensurePlaceItemVisible(Uuid cavePlaceUuid) {
    _navBarKey.currentState?.ensurePlaceItemVisible(cavePlaceUuid);
  }

  /// Builds the readonly [RasterMapPlacePointEditor] for the given image.
  /// Callers should wrap in [ClipRect] when `allowEditorOverflow` is false.
  Widget _buildEditorWidget(File file, String imagePath) {
    return RepaintBoundary(
      child: RasterMapPlacePointEditor(
        controller: _editorController,
        imageFile: file,
        imageProvider: _imageProviderCache[imagePath] ??= FileImage(file),
        cavePlacesWithDefinitions: _placesWithDefs,
        isReadonly: true,
        debugUi: false,
        onFullScreenChanged: (isFullScreen) {
          setState(() => _isFullScreen = isFullScreen);
        },
        onMarkerTap: (cpwd) {
          if (cpwd.definition == null) return;
          // update selection UI only — editor handles controller selection
          // and centering itself (mirrors behavior of the nav bar list).
          _selectedPlaceId = cpwd.cavePlace.uuid;
          _navBarKey.currentState?.setSelectedPlaceId(cpwd.cavePlace.uuid);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensurePlaceItemVisible(cpwd.cavePlace.uuid);
          });
        },
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return RasterMapNavBar(
      key: _navBarKey,
      rasterMaps: _rasterMaps,
      cavePlacesWithDefinitions: _placesWithDefs,
      selectedRasterMapUuid: _selectedRasterMap?.uuid,
      selectedPlaceId: _selectedPlaceId,
      imageProviderCache: _imageProviderCache,
      placesListAlignment: widget.placesListAlignment,
      style: _compactNavBar ? const RasterMapNavBarStyle.compact() : const RasterMapNavBarStyle(),
      onRasterMapSelected: (rm) async {
        setState(() {
          _selectedRasterMap = rm;
        });
        try {
          _editorController.resetZoom();
        } catch (e, st) {
          _log.fine('resetZoom on raster select failed', e, st);
        }
        await _loadDefinitionsForSelected();
      },
      onCavePlaceSelected: (cpwd) {
        final hasDef = cpwd.definition != null &&
            cpwd.definition!.xCoordinate != null &&
            cpwd.definition!.yCoordinate != null;

        _selectedPlaceId = cpwd.cavePlace.uuid;

        try {
          _editorController.setCavePlaceId(_selectedPlaceId);
        } catch (e, st) {
          _log.fine('setCavePlaceId on cave place select failed', e, st);
        }

        if (hasDef) {
          final x = cpwd.definition!.xCoordinate!.toDouble();
          final y = cpwd.definition!.yCoordinate!.toDouble();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _editorController.panToPoint(x, y);
          });
        } else {
            SnackBarService.showWarning(LocServ.inst.t('no_point_defined'));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ensurePlaceItemVisible(cpwd.cavePlace.uuid);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      extendBody: true,
      appBar: _isFullScreen ? null : AppBar(
        titleSpacing: 0,
        title: Text(
          _cavePlace?.title ?? LocServ.inst.t('view_raster_maps'),
          style: const TextStyle(fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // compact nav bar toggle
          IconButton(
            tooltip: LocServ.inst.t('compact_nav'),
            icon: Icon(_compactNavBar ? Icons.view_compact : Icons.view_comfortable),
            onPressed: () {
              setState(() {
                _compactNavBar = !_compactNavBar;
              });
              SettingsHelper.saveStringConfig(compactNavBarKey, _compactNavBar.toString());
            },
          ),
          if (SHOW_CAVE_PLACE_ACTIONS_IN_APP_BAR) ...[
            // open cave place documents
            IconButton(
              tooltip: LocServ.inst.t('open_documents'),
              icon: const Icon(Icons.folder_open),
              onPressed: () {
                if (_cavePlace == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GeofeatureDocumentsPage(
                      source: DocumentsSource.cavePlace(
                        cavePlaceUuid: _selectedPlaceId ?? _cavePlace!.uuid,
                        cavePlaceTitle: _cavePlace!.title,
                      ),
                    ),
                  ),
                );
              },
            ),
            // open cave place button
            IconButton(
              tooltip: LocServ.inst.t('open_cave_place'),
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                if (_cavePlace == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CavePlacePage(caveUuid: _cavePlace!.caveUuid, cavePlaceUuid: _selectedPlaceId ?? _cavePlace!.uuid)),
                );
              },
            ),
          ],
          KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedRasterMap == null
              ? Center(child: Text(LocServ.inst.t('no_raster_maps_for_cave')))
              : Builder(builder: (context) {
                if (_imageFile == null) {
                  return Column(
                    children: [
                      _buildNavBar(context),
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  );
                }

                final file = _imageFile!;
                final imagePath = file.path;

                // Ensure _decodedImage is loaded; if not, trigger background decode
                if (_decodedImage == null && !_isDecodingImage) {
                  _isDecodingImage = true;
                  decodeImageToRawCached(imagePath).then((raw) {
                    if (mounted) {
                      setState(() {
                        _decodedImage = raw;
                        _isDecodingImage = false;
                      });
                    }
                  }).catchError((_) {
                    if (mounted) {
                      setState(() {
                        _decodedImage = null;
                        _isDecodingImage = false;
                      });
                    }
                  });
                }

                return Column(
                  children: [
                    KeyedSubtree(key: tourKeys['navbar'], child: _buildNavBar(context)),
                    Expanded(
                      key: tourKeys['map'],
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          Widget editor = _buildEditorWidget(file, imagePath);
                          // Clip the editor to its layout bounds unless the caller
                          // explicitly allows overflow via `widget.allowEditorOverflow`.
                          if (!widget.allowEditorOverflow) editor = ClipRect(child: editor);
                          return SizedBox.expand(
                            key: _childKey,
                            child: Stack(children: [editor]),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
    );
  }
}
