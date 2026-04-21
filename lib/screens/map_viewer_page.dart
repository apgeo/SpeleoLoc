import 'dart:io';

import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_place_page.dart';
import 'package:speleoloc/screens/geofeature_documents_page.dart';
import 'package:speleoloc/services/documents_controller.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/file_utils.dart';
import 'package:speleoloc/utils/raw_image_data.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';
import 'package:speleoloc/widgets/raster_map_nav_bar.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

class MapViewerPage extends StatefulWidget {
  const MapViewerPage({
    super.key,
    required this.cavePlaceId,
    this.caveId,
    this.placesListAlignment = 0.5,
    this.allowEditorOverflow = false,
  });

  final int cavePlaceId;

  /// Optional cave context. When provided and [cavePlaceId] resolves to null
  /// (e.g. id == 0), raster maps for this cave are still loaded.
  final int? caveId;

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
  int? _selectedPlaceId;

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
    // Load cave place and raster maps for its cave
    _cavePlace = await cavePlaceRepository.findById(widget.cavePlaceId);
    if (_cavePlace == null) {
      // If an explicit caveId was provided, still load raster maps for that cave.
      if (widget.caveId != null) {
        _rasterMaps = await rasterMapRepository.getRasterMaps(widget.caveId!);
        if (_rasterMaps.isNotEmpty) {
          _selectedRasterMap = _rasterMaps.first;
          await _loadDefinitionsForSelected();
        }
      }
      _isLoading = false;
      if (mounted) setState(() {});
      return;
    }
    final int caveId = _cavePlace!.caveId;
    _rasterMaps = await rasterMapRepository.getRasterMaps(caveId);

    // default selected place is the one passed in (must be set BEFORE
    // loading definitions so the editor controller is informed about which
    // cave place should be highlighted as selected).
    _selectedPlaceId = widget.cavePlaceId;

    if (_rasterMaps.isNotEmpty) {
      _selectedRasterMap = _rasterMaps.first;
      await _loadDefinitionsForSelected();
    }

    _isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _loadDefinitionsForSelected() async {
    if (_selectedRasterMap == null || _cavePlace == null) return;
    // get cave places with definitions for this cave and raster map
    _placesWithDefs = await definitionRepository.getCavePlacesWithDefinitionsForRasterMap(_cavePlace!.caveId, _selectedRasterMap!.id);

    // inform persistent editor controller about the currently selected place
    // (so it can highlight the corresponding cave place marker without
    // requiring a user tap)
    try {
      _editorController.setCavePlaceId(_selectedPlaceId);
    } catch (_) {}

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
      debugPrint('[MapViewerPage] Error loading image: $e');
      _imageFile = null;
      _decodedImage = null;
      _isDecodingImage = false;
    }

    // Reset zoom so a new raster map doesn't inherit the previous scale/position.
    try {
      _editorController.resetZoom();
    } catch (_) {}

    // center on initially selected place if it has coordinates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // delegate centering to inner editor's PhotoView controller
      if (_selectedPlaceId == null) return;
      final matches = _placesWithDefs.where((p) => p.cavePlace.id == _selectedPlaceId).toList();
      if (matches.isEmpty) return;
      final cpwd = matches.first;
      if (cpwd.definition == null) return;
      final x = cpwd.definition!.xCoordinate?.toDouble();
      final y = cpwd.definition!.yCoordinate?.toDouble();
      if (x != null && y != null) {
        _editorController.zoomToPoint(x, y, zoomLevel: 0.8);
      }
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

  void _ensurePlaceItemVisible(int cavePlaceId) {
    _navBarKey.currentState?.ensurePlaceItemVisible(cavePlaceId);
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
        onMarkerTap: (cpwd) {
          if (cpwd.definition == null) return;
          // update selection UI only — editor handles controller selection
          // and centering itself (mirrors behavior of the nav bar list).
          _selectedPlaceId = cpwd.cavePlace.id;
          _navBarKey.currentState?.setSelectedPlaceId(cpwd.cavePlace.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensurePlaceItemVisible(cpwd.cavePlace.id);
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
      selectedRasterMapId: _selectedRasterMap?.id,
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
        } catch (_) {}
        await _loadDefinitionsForSelected();
      },
      onCavePlaceSelected: (cpwd) {
        final hasDef = cpwd.definition != null &&
            cpwd.definition!.xCoordinate != null &&
            cpwd.definition!.yCoordinate != null;

        _selectedPlaceId = cpwd.cavePlace.id;

        try {
          _editorController.setCavePlaceId(_selectedPlaceId);
        } catch (_) {}

        if (hasDef) {
          final x = cpwd.definition!.xCoordinate!.toDouble();
          final y = cpwd.definition!.yCoordinate!.toDouble();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _editorController.panToPoint(x, y);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocServ.inst.t('no_point_defined'))),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ensurePlaceItemVisible(cpwd.cavePlace.id);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
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
                        cavePlaceId: _selectedPlaceId ?? _cavePlace!.id,
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
                  MaterialPageRoute(builder: (_) => CavePlacePage(caveId: _cavePlace!.caveId, cavePlaceId: _selectedPlaceId ?? _cavePlace!.id)),
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
