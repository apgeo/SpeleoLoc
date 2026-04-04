import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speleo_loc/data/source/database/app_database.dart';
import 'package:speleo_loc/screens/settings/settings_helper.dart';
import 'package:speleo_loc/services/service_locator.dart';
import 'package:speleo_loc/utils/constants.dart';
import 'package:speleo_loc/utils/file_utils.dart';
import 'package:speleo_loc/utils/localization.dart';
import 'package:speleo_loc/widgets/raster_map_nav_bar.dart';
import 'package:speleo_loc/widgets/raster_map_place_point_editor.dart';

class RasterMapPlaceSelectorPage extends StatefulWidget {
  const RasterMapPlaceSelectorPage({
    super.key,
    required this.rasterMap,
    required this.cavePlaceId,
    required this.cavePlacesWithDefinitions,
    this.existingDefinition,
    this.isReadonly = false,
  });

  final RasterMap rasterMap;
  final int cavePlaceId;
  final List<CavePlaceWithDefinition> cavePlacesWithDefinitions;
  final CavePlaceToRasterMapDefinition? existingDefinition;
  final bool isReadonly;

  @override
  State<RasterMapPlaceSelectorPage> createState() => _RasterMapPlaceSelectorPageState();
}

class _RasterMapPlaceSelectorPageState extends State<RasterMapPlaceSelectorPage> {
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
        
        autoZoomToPoints: true,

        //todo: check/fix - label color not working in most cases, maybe something to do with the source of calculation and moment
        useImageTextColor: true,
        //todo: check - seems like when enabled, the zoom is constrained to a max level, jumping back if zoomed too far on point switch
        animatePointTransitions: true,
        // gestureZoomEnabled: !true,
      );

  static const bool DEBUG_UI = false;

  // Compact nav bar mode toggle
  bool _compactNavBar = false;

  List<RasterMap> _rasterMaps = [];
  late RasterMap _selectedRasterMap;
  late int _selectedCavePlaceId;
  List<CavePlaceWithDefinition> _placesWithDefinitions = [];
  CavePlaceToRasterMapDefinition? _selectedDefinition;

  // Resolved image file for selected raster map; null while loading or not found.
  File? _imageFile;
  bool _imageLoaded = false;

  Map<int, String> _caveAreaTitles = {};

  @override
  void initState() {
    super.initState();
    _selectedRasterMap = widget.rasterMap;
    _selectedCavePlaceId = widget.cavePlaceId;
    _placesWithDefinitions = widget.cavePlacesWithDefinitions;
    _selectedDefinition = widget.existingDefinition;
    _loadRasterMaps();
    _loadDefinitionsForSelected();
    _loadCaveAreas();
    _loadCompactNavState();

    // Seed selected image coordinates from existing definition (so save uses them if unchanged)
    if (_selectedDefinition != null) {
      _imageSelectedX = _selectedDefinition!.xCoordinate?.toDouble();
      _imageSelectedY = _selectedDefinition!.yCoordinate?.toDouble();
    }

    // inform the editor controller which cavePlace should be highlighted by default
    _editorController.setCavePlaceId(_selectedCavePlaceId);

    // In view-only mode, don't auto-zoom to points when not already zoomed
    if (widget.isReadonly) {
      _editorController.autoZoomToPoints = false;
    }
  }

  Future<void> _loadCompactNavState() async {
    final val = await SettingsHelper.loadStringConfig(compactNavBarKey, 'false');
    if (mounted) setState(() => _compactNavBar = val == 'true');
  }

  Future<void> _loadCaveAreas() async {
    final areas = await caveRepository.getCaveAreas(widget.rasterMap.caveId);
    if (mounted) {
      setState(() {
        _caveAreaTitles = {for (final a in areas) a.id: a.title};
      });
    }
  }

  Future<void> _loadRasterMaps() async {
    final maps = await rasterMapRepository.getRasterMaps(widget.rasterMap.caveId);
    if (mounted) {
      setState(() {
        _rasterMaps = maps;
      });
    }
  }

  Future<void> _loadDefinitionsForSelected() async {
    final defs = await definitionRepository.getCavePlacesWithDefinitionsForRasterMap(
      _selectedRasterMap.caveId,
      _selectedRasterMap.id,
    );
    final file = await getDocumentsFile(_selectedRasterMap.fileName);
    if (!mounted) return;
    setState(() {
      _placesWithDefinitions = defs;
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
    } catch (_) {}
  }

  CavePlaceToRasterMapDefinition? _findDefinition(
    int cavePlaceId,
    List<CavePlaceWithDefinition> list,
  ) {
    return list.where((c) => c.cavePlace.id == cavePlaceId).firstOrNull?.definition;
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
    int cavePlaceId,
    int rasterMapId,
    double imageX,
    double imageY,
  ) async {
    final saved = await definitionRepository.saveDefinition(cavePlaceId, rasterMapId, imageX, imageY);
    // keep local list in sync so subsequent navigation reflects the persisted state
    final idx = _placesWithDefinitions.indexWhere((c) => c.cavePlace.id == cavePlaceId);
    if (idx >= 0) {
      _placesWithDefinitions[idx] = CavePlaceWithDefinition(_placesWithDefinitions[idx].cavePlace, saved);
    }
  }

  Future<bool> _handleAutoSaveRequested(
    int cavePlaceId,
    int rasterMapId,
    double imageX,
    double imageY,
  ) async {
    final shouldSave = await _confirmAutoSaveIfNeeded();
    if (!shouldSave) return false;
    await _saveDefinition(cavePlaceId, rasterMapId, imageX, imageY);
    return true;
  }

  Future<bool> _handleRemoveDefinition(int cavePlaceId, int rasterMapId) async {
    final removed = await definitionRepository.deleteDefinition(cavePlaceId, rasterMapId);
    if (removed) {
      // Update local list so the UI reflects the deletion immediately.
      final idx = _placesWithDefinitions.indexWhere((c) => c.cavePlace.id == cavePlaceId);
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
    if (rm.id == _selectedRasterMap.id) return;
    setState(() {
      _selectedRasterMap = rm;
      _imageFile = null;
      _imageLoaded = false;
    });
    await _loadDefinitionsForSelected();
  }

  void _onCavePlaceSelected(CavePlaceWithDefinition cpwd) {
    if (_selectedCavePlaceId == cpwd.cavePlace.id) return;
    setState(() {
      _selectedCavePlaceId = cpwd.cavePlace.id;
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

  /// Public function to zoom and pan to a specific cave place point
  void zoomToPoint(double imageX, double imageY, {double zoomLevel = 2.5}) {
    // Use the typed controller to programmatically pan/zoom the editor.
    try {
      _editorController.zoomToPoint(imageX, imageY, zoomLevel: zoomLevel);
    } catch (_) {}
  }

  void _definePlace() async {
    if (_imageSelectedX == null || _imageSelectedY == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocServ.inst.t('no_point_defined'))),
      );
      return;
    }

    // Use image-space coordinates (calculated from tap + controller).
    final saveX = _imageSelectedX!;
    final saveY = _imageSelectedY!;

    await _saveDefinition(
      _selectedCavePlaceId,
      _selectedRasterMap.id,
      saveX,
      saveY,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocServ.inst.t('define_place_on_map')),
          duration: const Duration(seconds: 1),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? cavePlaceTitle = _placesWithDefinitions
        .where((c) => c.cavePlace.id == _selectedCavePlaceId)
        .map((c) => c.cavePlace.title)
        .firstOrNull;

    final selectedCp = _placesWithDefinitions
        .where((c) => c.cavePlace.id == _selectedCavePlaceId)
        .map((c) => c.cavePlace)
        .firstOrNull;
    final caveAreaSuffix = (selectedCp?.caveAreaId != null &&
            _caveAreaTitles.containsKey(selectedCp!.caveAreaId))
        ? ' (${_caveAreaTitles[selectedCp.caveAreaId!]})'
        : '';

    return Scaffold(
      appBar: AppBar(
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
              SettingsHelper.saveStringConfig(compactNavBarKey, _compactNavBar.toString());
            },
          ),
        ],
      ),
      // bottom controls: legend + zoom controls + save button — responsive layout
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(8.0),
        child: LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;

          // final zoomControls = Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.grey, width: 1.2),
          //     borderRadius: BorderRadius.circular(8),
          //     color: Theme.of(context).colorScheme.surface,
          //   ),
          //   child: Row(mainAxisSize: MainAxisSize.min, children: [
          //     Tooltip(message: 'Zoom out', child: IconButton(iconSize: 20, onPressed: _editorController.zoomOut, icon: const Icon(Icons.remove))),
          //     Tooltip(message: 'Reset', child: IconButton(iconSize: 20, onPressed: _editorController.resetZoom, icon: const Icon(Icons.refresh))),
          //     Tooltip(message: 'Zoom in', child: IconButton(iconSize: 20, onPressed: _editorController.zoomIn, icon: const Icon(Icons.add))),
          //   ]),
          // );

          if (isNarrow) {
            return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(children: [
                  // const Expanded(child: RasterMapPointsLegend()),
                  // const SizedBox(width: 12),
                  // zoomControls,
                ]),
              ),
            ]);
          }

          return Row(children: [
            // const Padding(padding: EdgeInsets.only(left: 4.0), child: RasterMapPointsLegend()),
            // const SizedBox(width: 12),
            // zoomControls,
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
                          selectedRasterMapId: _selectedRasterMap.id,
                          navBarStyle: _compactNavBar ? const RasterMapNavBarStyle.compact() : const RasterMapNavBarStyle(),
                          onRasterMapSelected: _onRasterMapSelected,
                          onCavePlaceSelected: _onCavePlaceSelected,
                          onAutoSaveRequested: _handleAutoSaveRequested,
                          onRemoveDefinitionRequested: _handleRemoveDefinition,
                          onSaveDefinitionRequested: widget.isReadonly ? null : _definePlace,
                          caveId: widget.rasterMap.caveId,
                          onCavePlaceAdded: () {
                            _loadDefinitionsForSelected();
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
