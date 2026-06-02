import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/file_utils.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_editor_constants.dart';
import 'package:speleoloc/widgets/raster_map_nav_bar.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';
import 'package:speleoloc/screens/general_data/raster_maps_page.dart';

class RasterMapPlaceSelectorPage extends StatefulWidget {
  const RasterMapPlaceSelectorPage({
    super.key,
    required this.rasterMap,
    required this.cavePlaceUuid,
    required this.cavePlacesWithDefinitions,
    this.existingDefinition,
    this.isReadonly = false,
    this.initialTapDefinesNewPoint = true,
  });

  final RasterMap rasterMap;
  final Uuid cavePlaceUuid;
  final List<CavePlaceWithDefinition> cavePlacesWithDefinitions;
  final CavePlaceToRasterMapDefinition? existingDefinition;
  final bool isReadonly;
  final bool initialTapDefinesNewPoint;

  @override
  State<RasterMapPlaceSelectorPage> createState() => _RasterMapPlaceSelectorPageState();
}

class _RasterMapPlaceSelectorPageState extends State<RasterMapPlaceSelectorPage>
    with AppBarMenuMixin<RasterMapPlaceSelectorPage>, ProductTourMixin<RasterMapPlaceSelectorPage> {
  @override
  String get tourId => 'raster_map_place_selector';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'map', titleLocKey: 'tour_raster_map_selector_map_title', bodyLocKey: 'tour_raster_map_selector_map_body'),
    TourStepDef(keyId: 'navbar', titleLocKey: 'tour_raster_map_selector_navbar_title', bodyLocKey: 'tour_raster_map_selector_navbar_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_raster_map_selector_menu_title', bodyLocKey: 'tour_raster_map_selector_menu_body'),
  ];

  // Selected image-space coordinates received from the editor widget
  double? _imageSelectedX;
  double? _imageSelectedY;

  // Controller for programmatic editor actions (widget-internal legend/controls hidden — placed at bottom)
  final RasterMapPlacePointEditorController _editorController =
      RasterMapPlacePointEditorController(
        showLegend: false,
        showZoomControls: !false,
        showNavBar: true,
        showTapModeCheckbox: true,
        initialTapDefinesNewPoint: true,
        
        autoZoomToPoints: true,
        keepZoomOnNavigation: true,

        //todo: check/fix - label color not working in most cases, maybe something to do with the source of calculation and moment
        useImageTextColor: true,
        //todo: check - seems like when enabled, the zoom is constrained to a max level, jumping back if zoomed too far on point switch
        animatePointTransitions: true,
        // gestureZoomEnabled: !true,
        
      );

  static const bool DEBUG_UI = false;

  // Compact nav bar mode toggle
  bool _compactNavBar = false;

  /// When true the AppBar is hidden (full-screen map mode).
  bool _isFullScreen = false;

  List<RasterMap> _rasterMaps = [];
  late RasterMap _selectedRasterMap;
  late Uuid _selectedCavePlaceId;
  List<CavePlaceWithDefinition> _placesWithDefinitions = [];
  CavePlaceToRasterMapDefinition? _selectedDefinition;

  // Resolved image file for selected raster map; null while loading or not found.
  File? _imageFile;
  bool _imageLoaded = false;

  Map<Uuid, String> _caveAreaTitles = {};

  // Cave-places nav bar sort
  CavePlaceSortOption _cavePlaceSortOption = const CavePlaceSortOption();

  // Definitions count across all raster maps (for sort by definitions_count)
  Map<Uuid, int> _definitionCountByPlace = {};

  @override
  void initState() {
    super.initState();
    _selectedRasterMap = widget.rasterMap;
    _selectedCavePlaceId = widget.cavePlaceUuid;
    _placesWithDefinitions = widget.cavePlacesWithDefinitions;
    _selectedDefinition = widget.existingDefinition;
    _loadRasterMaps();
    _loadDefinitionsForSelected();
    _loadCaveAreas();
    _loadCompactNavState();
    _loadCavePlaceSortOption();

    // Seed selected image coordinates from existing definition (so save uses them if unchanged)
    if (_selectedDefinition != null) {
      _imageSelectedX = _selectedDefinition!.xCoordinate?.toDouble();
      _imageSelectedY = _selectedDefinition!.yCoordinate?.toDouble();
    }

    // inform the editor controller which cavePlace should be highlighted by default
    _editorController.setCavePlaceId(_selectedCavePlaceId);

    // propagate widget-level tap-mode preference to the controller
    _editorController.initialTapDefinesNewPoint = widget.initialTapDefinesNewPoint;

    // In view-only mode, don't auto-zoom to points when not already zoomed
    if (widget.isReadonly) {
      _editorController.autoZoomToPoints = false;
    }
  }

  Future<void> _loadCompactNavState() async {
    final val = await SettingsHelper.loadStringConfig(compactNavBarKey, 'false');
    if (mounted) setState(() => _compactNavBar = val == 'true');
  }

  Future<void> _loadCavePlaceSortOption() async {
    final option = await CavePlaceSortOption.load();
    if (mounted) {
      setState(() {
        _cavePlaceSortOption = option;
        _placesWithDefinitions = _sortPlaces(_placesWithDefinitions);
      });
    }
  }

  /// Applies the current [_cavePlaceSortOption] to [places] and returns the
  /// sorted copy.
  List<CavePlaceWithDefinition> _sortPlaces(List<CavePlaceWithDefinition> places) =>
      _cavePlaceSortOption.apply(places, _caveAreaTitles, _definitionCountByPlace);

  Future<void> _loadCaveAreas() async {
    final areas = await caveRepository.getCaveAreas(widget.rasterMap.caveUuid);
    if (mounted) {
      setState(() {
        _caveAreaTitles = {for (final a in areas) a.uuid: a.title};
        // Re-sort with updated area titles (needed for cave_area sort field)
        _placesWithDefinitions = _sortPlaces(_placesWithDefinitions);
      });
    }
  }

  Future<void> _loadRasterMaps() async {
    final maps = await rasterMapRepository.getRasterMaps(widget.rasterMap.caveUuid);

    // Collect definition counts across all raster maps for the definitions_count sort.
    if (maps.isNotEmpty) {
      final rasterMapIds = maps.map((r) => r.uuid).toList();
      try {
        final allDefs = await definitionRepository.getDefinitionsForRasterMaps(rasterMapIds);
        final placeToRasters = <Uuid, Set<Uuid>>{};
        for (final d in allDefs) {
          placeToRasters.putIfAbsent(d.cavePlaceUuid, () => <Uuid>{}).add(d.rasterMapUuid);
        }
        _definitionCountByPlace = {
          for (final e in placeToRasters.entries) e.key: e.value.length,
        };
      } catch (e, st) {
        AppLogger.of('RasterMapPlaceSelector').warning('_loadRasterMaps: failed to load all defs', e, st);
        _definitionCountByPlace = {};
      }
    }

    if (mounted) {
      setState(() {
        _rasterMaps = _editorController.sortOption.apply(maps, _placesWithDefinitions);
        _placesWithDefinitions = _sortPlaces(_placesWithDefinitions);
      });
    }
  }

  Future<void> _loadDefinitionsForSelected() async {
    final defs = await definitionRepository.getCavePlacesWithDefinitionsForRasterMap(
      _selectedRasterMap.caveUuid,
      _selectedRasterMap.uuid,
    );
    final file = await getDocumentsFile(_selectedRasterMap.fileName);
    if (!mounted) return;
    setState(() {
      _placesWithDefinitions = _sortPlaces(defs);
      _selectedDefinition = _findDefinition(
        _selectedCavePlaceId,
        _placesWithDefinitions,
      );
      _imageSelectedX = _selectedDefinition?.xCoordinate?.toDouble();
      _imageSelectedY = _selectedDefinition?.yCoordinate?.toDouble();
      _imageFile = file;
      _imageLoaded = true;
    });
    try {
      _editorController.setCavePlaceId(_selectedCavePlaceId);
    } catch (e, st) {
      AppLogger.of('RasterMapPlaceSelector').fine('setCavePlaceId after load failed', e, st);
    }
  }

  CavePlaceToRasterMapDefinition? _findDefinition(
    Uuid cavePlaceUuid,
    List<CavePlaceWithDefinition> list,
  ) {
    return list.where((c) => c.cavePlace.uuid == cavePlaceUuid).firstOrNull?.definition;
  }

  Future<bool> _confirmAutoSaveIfNeeded() async {
    if (SessionPrefs.instance.autoSaveConfirmed) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(LocServ.inst.t('auto_save_on_switch')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocServ.inst.t('yes')),
          ),
        ],
      ),
    );
    if (result == true) {
      SessionPrefs.instance.autoSaveConfirmed = true;
      return true;
    }
    return false;
  }

  Future<void> _saveDefinition(
    Uuid cavePlaceUuid,
    Uuid rasterMapUuid,
    double imageX,
    double imageY,
  ) async {
    final saved = await definitionRepository.saveDefinition(cavePlaceUuid, rasterMapUuid, imageX, imageY);
    // keep local list in sync so subsequent navigation reflects the persisted state
    final idx = _placesWithDefinitions.indexWhere((c) => c.cavePlace.uuid == cavePlaceUuid);
    if (idx >= 0) {
      _placesWithDefinitions[idx] = CavePlaceWithDefinition(_placesWithDefinitions[idx].cavePlace, saved);
    }
  }

  Future<bool> _handleAutoSaveRequested(
    Uuid cavePlaceUuid,
    Uuid rasterMapUuid,
    double imageX,
    double imageY,
  ) async {
    final shouldSave = await _confirmAutoSaveIfNeeded();
    if (!shouldSave) return false;
    await _saveDefinition(cavePlaceUuid, rasterMapUuid, imageX, imageY);
    return true;
  }

  Future<bool> _handleRemoveDefinition(Uuid cavePlaceUuid, Uuid rasterMapUuid) async {
    final removed = await definitionRepository.deleteDefinition(cavePlaceUuid, rasterMapUuid);
    if (removed) {
      // Update local list so the UI reflects the deletion immediately.
      final idx = _placesWithDefinitions.indexWhere((c) => c.cavePlace.uuid == cavePlaceUuid);
      if (idx >= 0) {
        _placesWithDefinitions[idx] = CavePlaceWithDefinition(
          _placesWithDefinitions[idx].cavePlace,
          null,
        );
      }
      if (mounted) {
        setState(() {
          _selectedDefinition = null;
          _imageSelectedX = null;
          _imageSelectedY = null;
        });
      }
    }
    return removed;
  }

  Future<void> _onRasterMapSelected(RasterMap rm) async {
    if (rm.uuid == _selectedRasterMap.uuid) return;
    setState(() {
      _selectedRasterMap = rm;
      _imageFile = null;
      _imageLoaded = false;
    });
    await _loadDefinitionsForSelected();
  }

  void _onCavePlaceSelected(CavePlaceWithDefinition cpwd) {
    if (_selectedCavePlaceId == cpwd.cavePlace.uuid) return;
    setState(() {
      _selectedCavePlaceId = cpwd.cavePlace.uuid;
      _selectedDefinition = cpwd.definition;
      _imageSelectedX = _selectedDefinition?.xCoordinate?.toDouble();
      _imageSelectedY = _selectedDefinition?.yCoordinate?.toDouble();
    });
  }

  @override
  void dispose() {
    _editorController.detach();
    super.dispose();
  }

  // ── Sort menu ────────────────────────────────────────────────────────────

  @override
  List<AppMenuItem> get screenMenuItems => [
    AppMenuItem(
      value: 'filter_cave_places',
      icon: Icons.search,
      label: LocServ.inst.t('filter_cave_places'),
    ),
    AppMenuItem(
      value: 'sort_cave_places',
      icon: Icons.sort_by_alpha,
      label: LocServ.inst.t('sort_cave_places_navbar'),
    ),
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
    if (value == 'filter_cave_places') {
      // toggleCavePlaceFilter already calls ensurePlacesListVisible internally
      _editorController.toggleCavePlaceFilter();
    } else if (value == 'sort_cave_places') {
      _editorController.ensurePlacesListVisible();
      _showCavePlacesSortDialog();
    } else if (value == 'sort_raster_maps') {
      _editorController.ensureMapsListVisible();
      _showSortDialog();
    } else if (value == 'manage_raster_maps') {
      _editorController.ensureMapsListVisible();
      _openRasterMapsPage();
    }
  }

  Future<void> _showCavePlacesSortDialog() async {
    final option = await showCavePlacesSortDialog(context, _cavePlaceSortOption);
    if (option == null || !mounted) return;
    await option.save();
    setState(() {
      _cavePlaceSortOption = option;
      _placesWithDefinitions = _sortPlaces(_placesWithDefinitions);
    });
  }

  Future<void> _showSortDialog() async {
    final option = await showRasterMapSortDialog(
      context,
      _editorController.sortOption,
    );
    if (option == null || !mounted) return;
    setState(() {
      _editorController.sortOption = option;
      _rasterMaps = option.apply(_rasterMaps, _placesWithDefinitions);
    });
  }

  Future<void> _openRasterMapsPage() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RasterMapsPage(caveUuid: widget.rasterMap.caveUuid),
      ),
    );
    if ((changed == true) && mounted) {
      await _loadRasterMaps();
      await _loadDefinitionsForSelected();
    }
  }

  /// Public function to zoom and pan to a specific cave place point
  void zoomToPoint(
    double imageX,
    double imageY, {
    double zoomLevel = RasterMapEditorConstants.defaultZoomToPointLevel,
  }) {
    // Use the typed controller to programmatically pan/zoom the editor.
    try {
      _editorController.zoomToPoint(imageX, imageY, zoomLevel: zoomLevel);
    } catch (e, st) {
      AppLogger.of('RasterMapPlaceSelector').fine('zoomToPoint failed', e, st);
    }
  }

  void _definePlace() async {
    if (_imageSelectedX == null || _imageSelectedY == null) {
      SnackBarService.showWarning(LocServ.inst.t('no_point_defined'));
      return;
    }

    // Use image-space coordinates (calculated from tap + controller).
    final saveX = _imageSelectedX!;
    final saveY = _imageSelectedY!;

    await _saveDefinition(
      _selectedCavePlaceId,
      _selectedRasterMap.uuid,
      saveX,
      saveY,
    );

    if (mounted) {
      SnackBarService.showSuccess(
        LocServ.inst.t('define_place_on_map'),
        duration: RasterMapEditorConstants.shortSnackbarDuration,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? cavePlaceTitle = _placesWithDefinitions
        .where((c) => c.cavePlace.uuid == _selectedCavePlaceId)
        .map((c) => c.cavePlace.title)
        .firstOrNull;

    final selectedCp = _placesWithDefinitions
        .where((c) => c.cavePlace.uuid == _selectedCavePlaceId)
        .map((c) => c.cavePlace)
        .firstOrNull;
    final caveAreaSuffix = (selectedCp?.caveAreaUuid != null &&
            _caveAreaTitles.containsKey(selectedCp!.caveAreaUuid))
        ? ' (${_caveAreaTitles[selectedCp.caveAreaUuid!]})'
        : '';

    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: _isFullScreen ? null : AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedRasterMap.title,
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (cavePlaceTitle != null)
              Text(
                '$cavePlaceTitle$caveAreaSuffix',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: LocServ.inst.t('compact_nav'),
            icon: Icon(_compactNavBar ? Icons.view_compact : Icons.view_comfortable),
            onPressed: () {
              setState(() {
                _compactNavBar = !_compactNavBar;
              });
              // Switching format — make both lists visible so neither is
              // unexpectedly hidden after the format change.
              _editorController.ensureBothListsVisible();
              SettingsHelper.saveStringConfig(compactNavBarKey, _compactNavBar.toString());
            },
          ),
          KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
        ],
      ),
      // bottom controls: legend + zoom controls + save button — responsive layout
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(8.0),
        child: LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;

          if (isNarrow) {
            return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(children: [
                  // const Expanded(child: RasterMapPointsLegend()),
                  // const SizedBox(width: 12),
                ]),
              ),
            ]);
          }

          return Row(children: [
            // const Padding(padding: EdgeInsets.only(left: 4.0), child: RasterMapPointsLegend()),
            // const SizedBox(width: 12),
          ]);
        }),
      ),

      body: !_imageLoaded
          ? const Center(child: CircularProgressIndicator())
          : _imageFile == null
              ? Center(child: Text(LocServ.inst.t('image_not_found')))
              : Column(
                  children: [
                    // Editor handles image display, taps, overlays and zoom controls.
                    Expanded(
                      key: tourKeys['map'],
                      child: ClipRect(
                        child: RasterMapPlacePointEditor(
                          controller: _editorController,
                          imageFile: _imageFile!,
                          cavePlacesWithDefinitions: _placesWithDefinitions,
                          initialImageX: _selectedDefinition?.xCoordinate?.toDouble(),
                          initialImageY: _selectedDefinition?.yCoordinate?.toDouble(),
                          isReadonly: widget.isReadonly,
                          debugUi: DEBUG_UI,
                          rasterMaps: _rasterMaps,
                          selectedRasterMapUuid: _selectedRasterMap.uuid,
                          navBarStyle: _compactNavBar ? const RasterMapNavBarStyle.compact() : const RasterMapNavBarStyle(),
                          onRasterMapSelected: _onRasterMapSelected,
                          onCavePlaceSelected: _onCavePlaceSelected,
                          onAutoSaveRequested: _handleAutoSaveRequested,
                          onRemoveDefinitionRequested: _handleRemoveDefinition,
                          onSaveDefinitionRequested: widget.isReadonly ? null : _definePlace,
                          caveUuid: widget.rasterMap.caveUuid,
                          caveAreaTitles: _caveAreaTitles,
                          groupPlacesByCaveArea: _cavePlaceSortOption.groupByCaveArea,
                          onCavePlaceAdded: () {
                            _loadDefinitionsForSelected();
                          },
                          onSortCavePlacesRequested: _showCavePlacesSortDialog,
                          onSortRasterMapsRequested: _showSortDialog,
                          onManageRasterMapsRequested: _openRasterMapsPage,
                          onFullScreenChanged: (isFullScreen) {
                            setState(() => _isFullScreen = isFullScreen);
                          },
                          onImagePointChanged: (x, y) {
                            setState(() {
                              _imageSelectedX = x;
                              _imageSelectedY = y;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
