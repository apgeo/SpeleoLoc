import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_map/cave_map_clustered_places.dart';
import 'package:speleoloc/screens/cave_map/cave_map_controller.dart';
import 'package:speleoloc/screens/cave_map/cave_map_layer_panel.dart';
import 'package:speleoloc/screens/cave_map/cave_map_layers_controller.dart';
import 'package:speleoloc/screens/cave_map/cave_map_measure.dart';
import 'package:speleoloc/screens/cave_map/cave_map_measure_bar.dart';
import 'package:speleoloc/screens/cave_map/cave_map_measure_overlay.dart';
import 'package:speleoloc/screens/cave_map/cave_map_my_location.dart';
import 'package:speleoloc/screens/cave_map/cave_map_panel.dart';
import 'package:speleoloc/screens/cave_map/cave_map_pick.dart';
import 'package:speleoloc/screens/cave_map/cave_map_placement.dart';
import 'package:speleoloc/screens/cave_map/cave_map_placement_bar.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_info_card.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_item.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_list_panel.dart';
import 'package:speleoloc/screens/cave_map/cave_map_prompts.dart';
import 'package:speleoloc/screens/cave_map/cave_map_toolbar.dart';
import 'package:speleoloc/screens/cave_place_page.dart';
import 'package:speleoloc/services/location/gps_running_average.dart';
import 'package:speleoloc/services/location/location_service.dart';
import 'package:speleoloc/services/map/place_label_resolver.dart';
import 'package:speleoloc/services/map/tile_layer_sources.dart';
import 'package:speleoloc/state/coordinate_format_notifier.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/coordinate_formats.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Full-screen geographic map of cave places (no AppBar; a compact
/// toolbar sits on top of the map) that doubles as a GPS/geodata point
/// manager: it shows the current position and lets the user place points
/// (by tapping, long-pressing, or using the GPS fix) to add caves,
/// entrances, or set a place's coordinates.
///
/// Entry modes:
/// - from HomePage: [focusCaveUuids] = the filtered/checked caves;
/// - from CavePlacesListPage: [focusPlaceUuids] = the filtered/checked
///   places of one cave, drawn highlighted among the other caves' places
///   ([highlightFocus]);
/// - from CavePlacePage: [pickRequest] turns the screen into a coordinate
///   picker that pops a [CaveMapPickResult].
///
/// The page itself is wiring and the placement/GPS flows; the view state
/// lives in [CaveMapController] and the tile stack in
/// [CaveMapLayersController].
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
  static const LatLng _fallbackCenter = LatLng(45.9432, 24.9668);

  final _log = AppLogger.of('CaveMapPage');
  final MapController _mapController = MapController();

  late final CaveMapController _map;
  late final CaveMapLayersController _layers;

  bool _loaded = false;
  CaveMapPanel _panel = CaveMapPanel.none;

  // Point placement (create/move/pick). Null when just browsing.
  CaveMapPlacement? _placement;
  LatLng? _pendingPoint;
  bool _placementBusy = false;
  bool _locating = false;

  // Averaged GPS capture for the pending point: while active, every fix
  // feeds the running mean and the pin follows it.
  GpsRunningAverage? _averaging;
  StreamSubscription<Position>? _averagingSub;

  // Live GPS position. The dot renders whenever a fix exists; _followMe
  // additionally keeps the camera on it until the user pans away.
  StreamSubscription<Position>? _positionSub;
  Position? _myPosition;
  bool _followMe = false;

  // Distance-measuring mode: taps (and marker taps, snapping to the
  // place) append to the path. Mutually exclusive with placement.
  bool _measuring = false;
  final List<LatLng> _measurePoints = [];

  LatLng _initialCenter = _fallbackCenter;
  double _initialZoom = 6;
  CameraFit? _initialFit;

  bool get _isExternalPicker => widget.pickRequest != null;

  LocationService get _location => ref.read(locationServiceProvider);

  @override
  void initState() {
    super.initState();
    _map = CaveMapController(
      placeRepository: ref.read(cavePlaceRepositoryProvider),
      caveRepository: ref.read(caveRepositoryProvider),
      focusCaveUuids: widget.focusCaveUuids,
      focusPlaceUuids: widget.focusPlaceUuids,
    );
    _layers = CaveMapLayersController(
      configRepository: ref.read(configurationRepositoryProvider),
      scanMbTiles: ref.read(mbTilesRegistryProvider).scan,
    );
    _map.addListener(_onControllersChanged);
    _layers.addListener(_onControllersChanged);

    final pick = widget.pickRequest;
    if (pick != null) {
      _placement = CaveMapPlacement(
        kind: PlacementKind.returnToCaller,
        subjectLabel: resolveListLabel(
          caveTitle: pick.caveTitle,
          placeTitle: pick.placeTitle,
        ),
      );
      if (pick.hasInitialPosition) {
        _pendingPoint = LatLng(pick.initialLatitude!, pick.initialLongitude!);
      }
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_layers.savePrefs());
    unawaited(_positionSub?.cancel());
    _map.removeListener(_onControllersChanged);
    _layers.removeListener(_onControllersChanged);
    _map.dispose();
    _layers.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onControllersChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      try {
        _layers.tileCache = await ref.read(tileDiskCacheProvider.future);
      } catch (e, st) {
        // No cache directory just means online tiles skip the disk cache.
        _log.warning('Tile cache unavailable', e, st);
      }
      final prefs = await _layers.load();
      await _map.loadItems();
      _computeInitialCamera(prefs);
      if (mounted) setState(() => _loaded = true);
    } catch (e, st) {
      _log.severe('Failed to load surface map data', e, st);
      if (mounted) {
        SnackBarService.showError('${LocServ.inst.t('error')}: $e');
      }
    }
  }

  void _computeInitialCamera(Map<String, dynamic> prefs) {
    if (_pendingPoint != null) {
      _initialCenter = _pendingPoint!;
      _initialZoom = 16;
      return;
    }

    var points = [
      for (final item in _map.items)
        if (item.isFocus) item.point,
    ];
    if (points.isEmpty) points = [for (final item in _map.items) item.point];

    if (points.length == 1) {
      _initialCenter = points.first;
      _initialZoom = 15;
    } else if (points.isNotEmpty) {
      _initialFit = CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(48, 110, 48, 96),
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

  void _moveTo(LatLng point, {double minZoom = 16}) {
    // Before the first FlutterMap frame the controller has no camera —
    // reachable via the toolbar/GPS while the loading spinner shows.
    if (!_loaded) return;
    final zoom = _mapController.camera.zoom;
    _mapController.move(point, zoom < minZoom ? minZoom : zoom);
  }

  // ---------------------------------------------------------------------
  // Map interaction
  // ---------------------------------------------------------------------

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    if (_measuring) {
      setState(() => _measurePoints.add(latLng));
      return;
    }
    if (_placement != null) {
      setState(() => _pendingPoint = latLng);
      _map.select(null);
      return;
    }
    setState(() => _panel = CaveMapPanel.none);
    _map.select(null);
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng latLng) {
    if (_placement != null || _measuring || _isExternalPicker) return;
    unawaited(_openAddMenu(initialPoint: latLng));
  }

  void _onMarkerTap(CaveMapPlaceItem item) {
    // In measure mode a marker tap snaps the next measure point to the
    // place, so distances between recorded points are exact.
    if (_measuring) {
      setState(() => _measurePoints.add(item.point));
      return;
    }
    // During placement a marker tap identifies the place (highlight +
    // label priority) without hijacking the pending point — moving the
    // point stays an explicit map tap / GPS action.
    if (_placement == null) setState(() => _panel = CaveMapPanel.none);
    _map.select(item.uuid);
  }

  void _onClusterTap(List<CaveMapPlaceItem> members) {
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [for (final member in members) member.point],
        padding: const EdgeInsets.fromLTRB(60, 120, 60, 100),
        maxZoom: 17,
      ),
    );
  }

  void _toggleMeasure() {
    setState(() {
      _measuring = !_measuring;
      _measurePoints.clear();
      if (_measuring) _panel = CaveMapPanel.none;
    });
    if (_measuring) _map.select(null);
  }

  void _onPanelToggled(CaveMapPanel panel) {
    setState(() => _panel = _panel == panel ? CaveMapPanel.none : panel);
  }

  void _navigateToItem(CaveMapPlaceItem item) {
    setState(() => _panel = CaveMapPanel.none);
    _map.reveal(item);
    _moveTo(item.point, minZoom: 15);
  }

  Future<void> _openSelectedPlace() async {
    final item = _map.selectedItem;
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
      await _map.loadItems();
    } catch (e, st) {
      _log.warning('Reload after place edit failed', e, st);
    }
  }

  // ---------------------------------------------------------------------
  // Live GPS position
  // ---------------------------------------------------------------------

  /// Ensures location services + permission are usable, showing an
  /// actionable snackbar and returning false when they are not.
  Future<bool> _ensureLocationReady() async {
    final loc = LocServ.inst;
    final readiness = await _location.ensureReady();
    if (!mounted) return false;
    switch (readiness) {
      case LocationReadiness.ready:
        return true;
      case LocationReadiness.serviceDisabled:
        SnackBarService.showWarning(loc.t('gps_service_disabled_short'));
        unawaited(_location.openLocationSettings());
        return false;
      case LocationReadiness.permissionDenied:
        SnackBarService.showWarning(loc.t('gps_permission_denied_short'));
        return false;
      case LocationReadiness.permissionDeniedForever:
        SnackBarService.showWarning(loc.t('gps_permission_denied_short'));
        unawaited(_location.openAppSettings());
        return false;
    }
  }

  void _startPositionStream() {
    if (_positionSub != null) return;
    // A small distance filter keeps a stationary device from triggering
    // full-page rebuilds (markers + label declutter) every second.
    _positionSub = _location.positionStream(distanceFilterMeters: 3).listen(
      (position) {
        if (!mounted) return;
        setState(() => _myPosition = position);
        if (_followMe) {
          _moveTo(LatLng(position.latitude, position.longitude), minZoom: 16);
        }
      },
      onError: (Object e, StackTrace st) =>
          _log.warning('Position stream error', e, st),
    );
  }

  Future<void> _toggleMyLocation() async {
    if (_followMe) {
      setState(() => _followMe = false);
      return;
    }
    if (!await _ensureLocationReady()) return;
    _startPositionStream();
    final fix = await _location.currentPosition();
    if (!mounted) return;
    setState(() {
      _followMe = true;
      if (fix != null) _myPosition = fix;
    });
    if (fix != null) _moveTo(LatLng(fix.latitude, fix.longitude), minZoom: 16);
  }

  // ---------------------------------------------------------------------
  // Point placement
  // ---------------------------------------------------------------------

  void _startPlacement(
    PlacementKind kind, {
    LatLng? point,
    CavePlace? existingPlace,
    String? subjectLabel,
  }) {
    setState(() {
      _measuring = false;
      _measurePoints.clear();
      _placement = CaveMapPlacement(
        kind: kind,
        existingPlace: existingPlace,
        subjectLabel: subjectLabel,
      );
      _pendingPoint =
          point ??
          (existingPlace != null &&
                  existingPlace.latitude != null &&
                  existingPlace.longitude != null
              ? LatLng(existingPlace.latitude!, existingPlace.longitude!)
              : null);
      _panel = CaveMapPanel.none;
    });
    _map.select(null);
    if (_pendingPoint != null) _moveTo(_pendingPoint!, minZoom: 15);
  }

  void _startMovePlace(CaveMapPlaceItem item) {
    _startPlacement(
      PlacementKind.moveExistingPlace,
      existingPlace: item.place,
      subjectLabel: item.listLabel,
    );
  }

  Future<void> _openAddMenu({LatLng? initialPoint}) async {
    final loc = LocServ.inst;
    final kind = await showModalBottomSheet<PlacementKind>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_location_alt),
              title: Text(loc.t('map_new_cave')),
              subtitle: Text(loc.t('map_new_cave_desc')),
              onTap: () => Navigator.pop(ctx, PlacementKind.newCave),
            ),
            ListTile(
              leading: const Icon(Icons.door_front_door),
              title: Text(loc.t('map_new_entrance')),
              subtitle: Text(loc.t('map_new_entrance_desc')),
              onTap: () => Navigator.pop(ctx, PlacementKind.newEntrance),
            ),
          ],
        ),
      ),
    );
    if (kind != null) _startPlacement(kind, point: initialPoint);
  }

  /// First tap starts an averaged GPS capture: every fix feeds a running
  /// mean and the pin follows it, converging far tighter than a single
  /// fix. A second tap (or a manual tap/drag of the point) stops it and
  /// keeps the mean.
  Future<void> _useMyLocationForPending() async {
    if (_averaging != null) {
      _stopAveraging();
      return;
    }
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await _ensureLocationReady()) return;
      if (!mounted) return;
      final average = GpsRunningAverage();
      // Dedicated unfiltered stream: the my-location stream's distance
      // filter would starve a stationary averaging session of samples.
      _averagingSub = _location.positionStream().listen(
        (position) {
          if (!mounted) return;
          average.add(position);
          final mean = LatLng(average.latitude!, average.longitude!);
          setState(() {
            _myPosition = position;
            _pendingPoint = mean;
          });
          if (average.sampleCount == 1) _moveTo(mean, minZoom: 16);
        },
        onError: (Object e, StackTrace st) =>
            _log.warning('Averaging stream error', e, st),
      );
      setState(() => _averaging = average);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _stopAveraging() {
    if (_averaging == null) return;
    unawaited(_averagingSub?.cancel());
    _averagingSub = null;
    setState(() => _averaging = null);
  }

  void _cancelPlacement() {
    _stopAveraging();
    if (_isExternalPicker) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _placement = null;
      _pendingPoint = null;
    });
  }

  Future<void> _confirmPlacement() async {
    final placement = _placement;
    final point = _pendingPoint;
    if (placement == null || point == null) return;

    final loc = LocServ.inst;
    final geo = ref.read(caveGeoServiceProvider);
    Uuid? selectAfter;
    try {
      switch (placement.kind) {
        case PlacementKind.returnToCaller:
          Navigator.pop(
            context,
            CaveMapPickResult(
              latitude: point.latitude,
              longitude: point.longitude,
            ),
          );
          return;
        case PlacementKind.moveExistingPlace:
          setState(() => _placementBusy = true);
          await geo.setPlaceLocation(
            cavePlaceUuid: placement.existingPlace!.uuid,
            latitude: point.latitude,
            longitude: point.longitude,
          );
          selectAfter = placement.existingPlace!.uuid;
          SnackBarService.showSuccess(loc.t('map_place_moved'));
        case PlacementKind.newEntrance:
          final caves = await ref.read(caveRepositoryProvider).getCaves()
            ..sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
            );
          if (!mounted) return;
          if (caves.isEmpty) {
            SnackBarService.showWarning(loc.t('map_no_caves_for_entrance'));
            return;
          }
          final caveUuid = await showCaveChooser(context, caves);
          if (caveUuid == null || !mounted) return;
          final title = await showTextPrompt(
            context,
            titleKey: 'map_new_entrance',
            labelKey: 'title',
            initial: loc.t('entrance'),
          );
          if (title == null || !mounted) return;
          setState(() => _placementBusy = true);
          selectAfter = await geo.addEntranceAt(
            caveUuid: caveUuid,
            title: title,
            latitude: point.latitude,
            longitude: point.longitude,
          );
          _map.addToFocus(placeUuid: selectAfter);
          SnackBarService.showSuccess(loc.t('map_entrance_added'));
        case PlacementKind.newCave:
          final input = await showNewCavePrompt(context);
          if (input == null || !mounted) return;
          setState(() => _placementBusy = true);
          final created = await geo.addCaveWithEntranceAt(
            caveTitle: input.caveTitle,
            entranceTitle: input.entranceTitle,
            latitude: point.latitude,
            longitude: point.longitude,
          );
          _map.addToFocus(
            caveUuid: created.caveUuid,
            placeUuid: created.entranceUuid,
          );
          selectAfter = created.entranceUuid;
          SnackBarService.showSuccess(loc.t('map_cave_added'));
      }

      await _map.loadItems();
      if (!mounted) return;
      setState(() {
        _placement = null;
        _pendingPoint = null;
        _placementBusy = false;
      });
      _map.select(selectAfter);
      _moveTo(point, minZoom: 15);
    } catch (e, st) {
      _log.warning('Placement confirm failed', e, st);
      if (mounted) {
        setState(() => _placementBusy = false);
        SnackBarService.showError('${loc.t('error')}: $e');
      }
    }
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
                      onLongPress: _onMapLongPress,
                      onPositionChanged: (camera, hasGesture) {
                        _layers.lastCenter = camera.center;
                        _layers.lastZoom = camera.zoom;
                        if (hasGesture && _followMe) {
                          setState(() => _followMe = false);
                        }
                      },
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      ?_layers.buildBaseLayer(),
                      ..._layers.buildOverlayLayers(),
                      if (_myPosition != null)
                        ...CaveMapMyLocation.layers(_myPosition!),
                      CaveMapClusteredPlaces(
                        paintOrder: _map.paintOrder,
                        visibleItems: _map.visibleItems,
                        highlightFocus: widget.highlightFocus,
                        selectedUuid: _map.selectedUuid,
                        onTap: _onMarkerTap,
                        onClusterTap: _onClusterTap,
                        pendingPoint: _placement != null
                            ? _pendingPoint
                            : null,
                        onPendingDragged: (point) =>
                            setState(() => _pendingPoint = point),
                      ),
                      if (_measuring)
                        ...CaveMapMeasureOverlay.layers(_measurePoints),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              _layers.attributionText,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black.withValues(alpha: 0.65),
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.6,
                                ),
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
                  showOtherCaves: _map.showOtherCaves,
                  showNonEntrances: _map.showNonEntrances,
                  locationActive: _followMe,
                  activePanel: _panel,
                  onBack: () => Navigator.pop(context),
                  onMyLocation: () => unawaited(_toggleMyLocation()),
                  onToggleOtherCaves: _map.toggleOtherCaves,
                  onToggleNonEntrances: _map.toggleNonEntrances,
                  onPanelToggled: _onPanelToggled,
                  measureActive: _measuring,
                  onMeasure: _placement != null ? null : _toggleMeasure,
                  onAdd: (_isExternalPicker || _placement != null)
                      ? null
                      : () => unawaited(_openAddMenu()),
                ),
                Expanded(
                  child: _panel == CaveMapPanel.none
                      ? const IgnorePointer(child: SizedBox.expand())
                      : Material(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.97),
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
          mbtilesBaseFiles: _layers.baseDescriptors,
          mbtilesOverlayFiles: _layers.overlayDescriptors,
          selectedBaseId: _layers.baseId,
          enabledOverlayFiles: _layers.enabledOverlays,
          onBaseSelected: _onBaseSelected,
          onOverlayToggled: _layers.toggleOverlay,
        );
      case CaveMapPanel.allPlaces:
        return CaveMapPlaceListPanel(
          items: _map.items,
          onItemSelected: _navigateToItem,
        );
      case CaveMapPanel.entrances:
        return CaveMapPlaceListPanel(
          items: [
            for (final item in _map.items)
              if (item.isEntrance) item,
          ],
          onItemSelected: _navigateToItem,
        );
      case CaveMapPanel.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomOverlay() {
    if (_measuring) {
      return CaveMapMeasureBar(
        path: MeasurePath(_measurePoints),
        onUndo: () => setState(() => _measurePoints.removeLast()),
        onClose: _toggleMeasure,
      );
    }
    if (_placement != null) {
      return CaveMapPlacementBar(
        placement: _placement!,
        point: _pendingPoint,
        busy: _placementBusy,
        locating: _locating,
        onUseLocation: () => unawaited(_useMyLocationForPending()),
        onCancel: _cancelPlacement,
        onConfirm: () => unawaited(_confirmPlacement()),
        coordinateFormat: _coordinateFormat,
      );
    }
    final selected = _map.selectedItem;
    if (selected != null) {
      return CaveMapPlaceInfoCard(
        item: selected,
        onClose: () => _map.select(null),
        onOpenPlace: _isExternalPicker
            ? null
            : () => unawaited(_openSelectedPlace()),
        onSetLocation: _isExternalPicker
            ? null
            : () => _startMovePlace(selected),
        coordinateFormat: _coordinateFormat,
      );
    }
    return const SizedBox.shrink();
  }

  CoordinateDisplayFormat get _coordinateFormat =>
      ref.watch(coordinateFormatProvider).valueOrNull ??
      CoordinateDisplayFormat.decimal;

  void _onBaseSelected(String id) {
    setState(() => _panel = CaveMapPanel.none);
    _layers.selectBase(id);
  }
}
