import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_map/cave_map_label_layer.dart';
import 'package:speleoloc/screens/cave_map/cave_map_layer_panel.dart';
import 'package:speleoloc/screens/cave_map/cave_map_panel.dart';
import 'package:speleoloc/screens/cave_map/cave_map_pick.dart';
import 'package:speleoloc/screens/cave_map/cave_map_pick_bar.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_info_card.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_item.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_list_panel.dart';
import 'package:speleoloc/screens/cave_map/cave_map_toolbar.dart';
import 'package:speleoloc/screens/cave_place_page.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/map/map_mbtiles_config.dart';
import 'package:speleoloc/services/map/mbtiles_reader.dart';
import 'package:speleoloc/services/map/mbtiles_registry.dart';
import 'package:speleoloc/services/map/place_label_resolver.dart';
import 'package:speleoloc/services/map/tile_layer_sources.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/map/cave_map_marker_icons.dart';
import 'package:speleoloc/widgets/map/mbtiles_tile_provider.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Full-screen geographic map of cave places (no AppBar; a compact
/// toolbar sits on top of the map instead).
///
/// Entry modes:
/// - from HomePage: [focusCaveUuids] = the filtered/checked caves;
/// - from CavePlacesListPage: [focusPlaceUuids] = the filtered/checked
///   places of one cave, drawn highlighted among the other caves' places
///   ([highlightFocus]);
/// - from CavePlacePage: [pickRequest] turns the screen into a coordinate
///   picker that pops a [CaveMapPickResult].
class CaveMapPage extends ConsumerStatefulWidget {
  const CaveMapPage({
    super.key,
    this.focusCaveUuids,
    this.focusPlaceUuids,
    this.highlightFocus = false,
    this.pickRequest,
  });

  final Set<Uuid>? focusCaveUuids;
  final Set<Uuid>? focusPlaceUuids;
  final bool highlightFocus;
  final CaveMapPickRequest? pickRequest;

  @override
  ConsumerState<CaveMapPage> createState() => _CaveMapPageState();
}

class _CaveMapPageState extends ConsumerState<CaveMapPage> {
  static const String _userAgentPackageName = 'com.example.speleoloc';
  static const LatLng _fallbackCenter = LatLng(45.9432, 24.9668);

  final _log = AppLogger.of('CaveMapPage');
  final MapController _mapController = MapController();

  bool _loaded = false;
  List<CaveMapPlaceItem> _items = [];

  bool _showOtherCaves = true;
  bool _showNonEntrances = true;
  CaveMapPanel _panel = CaveMapPanel.none;
  Uuid? _selectedUuid;
  LatLng? _pickedPoint;

  String _baseId = builtInTileSourcesDefaultId;
  Set<String> _enabledOverlays = {};
  MapMbTilesConfig _mbConfig = const MapMbTilesConfig();
  List<MbTilesDescriptor> _mbtiles = [];
  final Map<String, MbTilesReader?> _readers = {};

  LatLng _initialCenter = _fallbackCenter;
  double _initialZoom = 6;
  CameraFit? _initialFit;
  LatLng? _lastCenter;
  double? _lastZoom;

  bool get _pickMode => widget.pickRequest != null;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_savePrefs());
    for (final reader in _readers.values) {
      reader?.dispose();
    }
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SettingsHelper.loadJsonConfig(
        mapScreenPrefsKey,
        () => <String, dynamic>{},
      );
      _mbConfig = MapMbTilesConfig.fromJson(
        await SettingsHelper.loadJsonConfig(
          mapMbtilesConfigKey,
          () => <String, dynamic>{},
        ),
      );
      if (_mbConfig.autoLoad) {
        _mbtiles = await ref.read(mbTilesRegistryProvider).scan();
      }

      await _loadItems();

      _restorePrefs(prefs);
      _computeInitialCamera(prefs);
      if (mounted) setState(() => _loaded = true);
    } catch (e, st) {
      _log.severe('Failed to load surface map data', e, st);
      if (mounted) {
        SnackBarService.showError('${LocServ.inst.t('error')}: $e');
      }
    }
  }

  /// (Re)builds the render items from the database. Does not touch the
  /// camera, so it is also safe after returning from a place edit.
  Future<void> _loadItems() async {
    final placeRepo = ref.read(cavePlaceRepositoryProvider);
    final places = await placeRepo.getCavePlacesWithCoordinates();
    final entranceCounts = await placeRepo.getEntranceCountsByCave();
    final caves = await ref.read(caveRepositoryProvider).getCaves();
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
            isEntrance: place.isEntrance == 1 || place.isMainEntrance == 1,
            caveEntranceCount: entranceCounts[place.caveUuid] ?? 0,
          ),
          isEntrance: place.isEntrance == 1 || place.isMainEntrance == 1,
          isMainEntrance: place.isMainEntrance == 1,
          isFocus: _isFocusPlace(place),
        ),
    ];
  }

  bool _isFocusPlace(CavePlace place) {
    final placeUuids = widget.focusPlaceUuids;
    if (placeUuids != null) return placeUuids.contains(place.uuid);
    final caveUuids = widget.focusCaveUuids;
    if (caveUuids != null) return caveUuids.contains(place.caveUuid);
    return true;
  }

  void _restorePrefs(Map<String, dynamic> prefs) {
    final base = prefs['base'];
    if (base is String && _baseLayerExists(base)) _baseId = base;
    final overlays = prefs['overlays'];
    if (overlays is List) {
      final known = _overlayDescriptors.map((d) => d.fileName).toSet();
      _enabledOverlays = overlays.whereType<String>().where(known.contains).toSet();
    }
  }

  bool _baseLayerExists(String id) {
    if (findTileSourceById(id) != null) return true;
    if (!id.startsWith('mbtiles:')) return false;
    final fileName = id.substring('mbtiles:'.length);
    return _baseDescriptors.any((d) => d.fileName == fileName);
  }

  void _computeInitialCamera(Map<String, dynamic> prefs) {
    final pick = widget.pickRequest;
    if (pick != null && pick.hasInitialPosition) {
      _pickedPoint = LatLng(pick.initialLatitude!, pick.initialLongitude!);
      _initialCenter = _pickedPoint!;
      _initialZoom = 16;
      return;
    }

    var points = [
      for (final item in _items)
        if (item.isFocus) item.point,
    ];
    if (points.isEmpty) points = [for (final item in _items) item.point];

    if (points.length == 1) {
      _initialCenter = points.first;
      _initialZoom = 15;
    } else if (points.isNotEmpty) {
      _initialFit = CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(48, 110, 48, 64),
        maxZoom: 17,
      );
    } else {
      final lat = prefs['lat'], lng = prefs['lng'], zoom = prefs['zoom'];
      if (lat is num && lng is num && zoom is num) {
        _initialCenter = LatLng(lat.toDouble(), lng.toDouble());
        _initialZoom = zoom.toDouble();
      }
    }
  }

  Future<void> _savePrefs() async {
    try {
      await SettingsHelper.saveJsonConfig(mapScreenPrefsKey, {
        'base': _baseId,
        'overlays': _enabledOverlays.toList(),
        if (_lastCenter != null) 'lat': _lastCenter!.latitude,
        if (_lastCenter != null) 'lng': _lastCenter!.longitude,
        if (_lastZoom != null) 'zoom': _lastZoom,
      });
    } catch (e, st) {
      _log.warning('Failed to persist map prefs', e, st);
    }
  }

  // ---------------------------------------------------------------------
  // Derived collections
  // ---------------------------------------------------------------------

  List<MbTilesDescriptor> get _baseDescriptors => [
        for (final d in _mbtiles)
          if (d.metadata.isRaster &&
              _mbConfig.roleOf(d.fileName) == MbTilesRole.base)
            d,
      ];

  List<MbTilesDescriptor> get _overlayDescriptors => [
        for (final d in _mbtiles)
          if (d.metadata.isRaster &&
              _mbConfig.roleOf(d.fileName) == MbTilesRole.overlay)
            d,
      ];

  List<CaveMapPlaceItem> get _visibleItems => [
        for (final item in _items)
          if ((item.isFocus || _showOtherCaves) &&
              (item.isEntrance || _showNonEntrances))
            item,
      ];

  CaveMapPlaceItem? get _selectedItem {
    for (final item in _visibleItems) {
      if (item.uuid == _selectedUuid) return item;
    }
    return null;
  }

  MbTilesReader? _readerFor(MbTilesDescriptor descriptor) {
    if (_readers.containsKey(descriptor.path)) {
      return _readers[descriptor.path];
    }
    MbTilesReader? reader;
    try {
      reader = MbTilesReader.open(descriptor.path);
    } catch (e, st) {
      _log.warning('Failed to open MBTiles ${descriptor.fileName}', e, st);
    }
    // Failures are cached as null so a corrupt file is not re-opened on
    // every rebuild.
    _readers[descriptor.path] = reader;
    return reader;
  }

  // ---------------------------------------------------------------------
  // Interaction
  // ---------------------------------------------------------------------

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      if (_pickMode) {
        _pickedPoint = latLng;
      }
      _selectedUuid = null;
      _panel = CaveMapPanel.none;
    });
  }

  void _onMarkerTap(CaveMapPlaceItem item) {
    setState(() {
      _selectedUuid = item.uuid;
      _panel = CaveMapPanel.none;
    });
  }

  void _onPanelToggled(CaveMapPanel panel) {
    setState(() => _panel = _panel == panel ? CaveMapPanel.none : panel);
  }

  void _onToggleOtherCaves() {
    setState(() {
      _showOtherCaves = !_showOtherCaves;
      if (_selectedItem == null) _selectedUuid = null;
    });
  }

  void _onToggleNonEntrances() {
    setState(() {
      _showNonEntrances = !_showNonEntrances;
      if (_selectedItem == null) _selectedUuid = null;
    });
  }

  void _navigateToItem(CaveMapPlaceItem item) {
    setState(() {
      _panel = CaveMapPanel.none;
      _selectedUuid = item.uuid;
      // Make sure the target is not filtered out of view.
      if (!item.isFocus) _showOtherCaves = true;
      if (!item.isEntrance) _showNonEntrances = true;
    });
    final zoom = _mapController.camera.zoom;
    _mapController.move(item.point, zoom < 15 ? 15 : zoom);
  }

  Future<void> _openSelectedPlace() async {
    final item = _selectedItem;
    if (item == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CavePlacePage(
          caveUuid: item.place.caveUuid,
          cavePlaceUuid: item.uuid,
        ),
      ),
    );
    // Coordinates/titles may have changed while the place was open.
    try {
      await _loadItems();
    } catch (e, st) {
      _log.warning('Reload after place edit failed', e, st);
    }
    if (mounted) setState(() {});
  }

  void _confirmPick() {
    final picked = _pickedPoint;
    if (picked == null) return;
    Navigator.pop(
      context,
      CaveMapPickResult(
        latitude: picked.latitude,
        longitude: picked.longitude,
      ),
    );
  }

  void _onBaseSelected(String id) {
    setState(() {
      _baseId = id;
      _panel = CaveMapPanel.none;
    });
    unawaited(_savePrefs());
  }

  void _onOverlayToggled(String fileName, bool enabled) {
    setState(() {
      if (enabled) {
        _enabledOverlays = {..._enabledOverlays, fileName};
      } else {
        _enabledOverlays = {..._enabledOverlays}..remove(fileName);
      }
    });
    unawaited(_savePrefs());
  }

  // ---------------------------------------------------------------------
  // Layers
  // ---------------------------------------------------------------------

  TileLayer _buildBaseLayer() {
    if (_baseId.startsWith('mbtiles:')) {
      final fileName = _baseId.substring('mbtiles:'.length);
      for (final descriptor in _baseDescriptors) {
        if (descriptor.fileName != fileName) continue;
        final reader = _readerFor(descriptor);
        if (reader == null) break;
        return TileLayer(
          tileProvider: MbTilesTileProvider(reader),
          minNativeZoom: reader.metadata.minZoom ?? 0,
          maxNativeZoom: reader.metadata.maxZoom ?? 19,
        );
      }
    }
    final source = findTileSourceById(_baseId) ?? builtInTileSources.first;
    return TileLayer(
      urlTemplate: source.urlTemplate,
      subdomains: source.subdomains,
      maxNativeZoom: source.maxNativeZoom,
      userAgentPackageName: _userAgentPackageName,
    );
  }

  List<TileLayer> _buildOverlayLayers() {
    final layers = <TileLayer>[];
    for (final descriptor in _overlayDescriptors) {
      if (!_enabledOverlays.contains(descriptor.fileName)) continue;
      final reader = _readerFor(descriptor);
      if (reader == null) continue;
      layers.add(
        TileLayer(
          tileProvider: MbTilesTileProvider(reader),
          minNativeZoom: reader.metadata.minZoom ?? 0,
          maxNativeZoom: reader.metadata.maxZoom ?? 19,
        ),
      );
    }
    return layers;
  }

  String get _attributionText {
    if (_baseId.startsWith('mbtiles:')) {
      final fileName = _baseId.substring('mbtiles:'.length);
      for (final descriptor in _baseDescriptors) {
        if (descriptor.fileName == fileName) return descriptor.displayName;
      }
      return fileName;
    }
    return (findTileSourceById(_baseId) ?? builtInTileSources.first)
        .attribution;
  }

  List<Marker> _buildMarkers() {
    int rank(CaveMapPlaceItem item) {
      var r = item.isEntrance ? 1 : 0;
      if (item.isFocus) r += 2;
      if (item.uuid == _selectedUuid) r += 100;
      return r;
    }

    final ordered = [..._visibleItems]
      ..sort((a, b) => rank(a).compareTo(rank(b)));

    return [
      for (final item in ordered)
        Marker(
          key: ValueKey(item.uuid),
          point: item.point,
          width: item.isEntrance ? 30 : 20,
          height: item.isEntrance ? 26 : 20,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onMarkerTap(item),
            child: Center(child: _markerIcon(item)),
          ),
        ),
      if (_pickMode && _pickedPoint != null)
        Marker(
          point: _pickedPoint!,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const Icon(
            Icons.location_on,
            size: 40,
            color: Color(0xFFD32F2F),
            shadows: [Shadow(color: Colors.white, blurRadius: 4)],
          ),
        ),
    ];
  }

  Widget _markerIcon(CaveMapPlaceItem item) {
    final highlighted =
        (widget.highlightFocus && item.isFocus) || item.uuid == _selectedUuid;
    if (item.isEntrance) {
      final color = !item.isFocus
          ? const Color(0xFF8D8D8D)
          : item.isMainEntrance
              ? const Color(0xFF3E2723)
              : const Color(0xFF6D4C41);
      return CaveEntranceMarkerIcon(
        size: item.isMainEntrance ? 26 : 22,
        color: color,
        highlighted: highlighted,
      );
    }
    return PlacePointMarkerIcon(
      size: 13,
      color: item.isFocus ? const Color(0xFF1565C0) : const Color(0xFF90A4AE),
      highlighted: highlighted,
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _initialCenter,
                      initialZoom: _initialZoom,
                      initialCameraFit: _initialFit,
                      minZoom: 2,
                      maxZoom: 20,
                      onTap: _onMapTap,
                      onPositionChanged: (camera, hasGesture) {
                        _lastCenter = camera.center;
                        _lastZoom = camera.zoom;
                      },
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      _buildBaseLayer(),
                      ..._buildOverlayLayers(),
                      MarkerLayer(markers: _buildMarkers()),
                      CaveMapLabelLayer(
                        items: _visibleItems,
                        selectedUuid: _selectedUuid,
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              _attributionText,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black.withValues(alpha: 0.65),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Positioned.fill(
            child: Column(
              children: [
                CaveMapToolbar(
                  pickMode: _pickMode,
                  canConfirmPick: _pickedPoint != null,
                  showOtherCaves: _showOtherCaves,
                  showNonEntrances: _showNonEntrances,
                  activePanel: _panel,
                  onBack: () => Navigator.pop(context),
                  onToggleOtherCaves: _onToggleOtherCaves,
                  onToggleNonEntrances: _onToggleNonEntrances,
                  onPanelToggled: _onPanelToggled,
                  onConfirmPick: _confirmPick,
                ),
                Expanded(
                  child: _panel == CaveMapPanel.none
                      ? const IgnorePointer(child: SizedBox.expand())
                      : Material(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.97),
                          child: _buildPanel(),
                        ),
                ),
              ],
            ),
          ),
          if (_panel == CaveMapPanel.none)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(child: _buildBottomOverlay()),
            ),
        ],
      ),
    );
  }

  Widget _buildPanel() {
    switch (_panel) {
      case CaveMapPanel.layers:
        return CaveMapLayerPanel(
          baseSources: builtInTileSources,
          mbtilesBaseFiles: _baseDescriptors,
          mbtilesOverlayFiles: _overlayDescriptors,
          selectedBaseId: _baseId,
          enabledOverlayFiles: _enabledOverlays,
          onBaseSelected: _onBaseSelected,
          onOverlayToggled: _onOverlayToggled,
        );
      case CaveMapPanel.allPlaces:
        return CaveMapPlaceListPanel(
          items: _items,
          onItemSelected: _navigateToItem,
        );
      case CaveMapPanel.entrances:
        return CaveMapPlaceListPanel(
          items: [
            for (final item in _items)
              if (item.isEntrance) item,
          ],
          onItemSelected: _navigateToItem,
        );
      case CaveMapPanel.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomOverlay() {
    final selected = _selectedItem;
    if (selected != null) {
      return CaveMapPlaceInfoCard(
        item: selected,
        onClose: () => setState(() => _selectedUuid = null),
        onOpenPlace: _pickMode ? null : _openSelectedPlace,
      );
    }
    if (_pickMode) {
      return CaveMapPickBar(
        placeTitle:
            '${widget.pickRequest!.placeTitle} — ${widget.pickRequest!.caveTitle}',
        pickedPoint: _pickedPoint,
        onCancel: () => Navigator.pop(context),
        onSave: _confirmPick,
      );
    }
    return const SizedBox.shrink();
  }
}
