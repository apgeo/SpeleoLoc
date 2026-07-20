import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_map/cave_map_label_layer.dart';
import 'package:speleoloc/screens/cave_map/cave_map_layer_panel.dart';
import 'package:speleoloc/screens/cave_map/cave_map_my_location.dart';
import 'package:speleoloc/screens/cave_map/cave_map_panel.dart';
import 'package:speleoloc/screens/cave_map/cave_map_pick.dart';
import 'package:speleoloc/screens/cave_map/cave_map_placement.dart';
import 'package:speleoloc/screens/cave_map/cave_map_placement_bar.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_info_card.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_item.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_list_panel.dart';
import 'package:speleoloc/screens/cave_map/cave_map_toolbar.dart';
import 'package:speleoloc/screens/cave_place_page.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/location/location_service.dart';
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

/// Details entered for a new cave created from the map.
class _NewCaveInput {
  final String caveTitle;
  final String entranceTitle;
  const _NewCaveInput(this.caveTitle, this.entranceTitle);
}

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

  // Point placement (create/move/pick). Null when just browsing.
  CaveMapPlacement? _placement;
  LatLng? _pendingPoint;
  bool _placementBusy = false;
  bool _locating = false;

  // Live GPS position.
  StreamSubscription<Position>? _positionSub;
  Position? _myPosition;
  bool _locationActive = false;
  bool _followMe = false;

  // Caves created during this session are treated as in-focus so they show
  // and highlight even when the map was opened for a narrower set.
  final Set<Uuid> _createdCaveUuids = {};

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

  bool get _isExternalPicker => widget.pickRequest != null;

  LocationService get _location => ref.read(locationServiceProvider);

  @override
  void initState() {
    super.initState();
    final pick = widget.pickRequest;
    if (pick != null) {
      _placement = CaveMapPlacement(
        kind: PlacementKind.returnToCaller,
        subjectLabel: '${pick.placeTitle} — ${pick.caveTitle}',
      );
      if (pick.hasInitialPosition) {
        _pendingPoint = LatLng(pick.initialLatitude!, pick.initialLongitude!);
      }
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_savePrefs());
    unawaited(_positionSub?.cancel());
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
  /// camera, so it is also safe after a create/edit.
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
    if (_createdCaveUuids.contains(place.caveUuid)) return true;
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
      _enabledOverlays =
          overlays.whereType<String>().where(known.contains).toSet();
    }
  }

  bool _baseLayerExists(String id) {
    if (findTileSourceById(id) != null) return true;
    if (!id.startsWith('mbtiles:')) return false;
    final fileName = id.substring('mbtiles:'.length);
    return _baseDescriptors.any((d) => d.fileName == fileName);
  }

  void _computeInitialCamera(Map<String, dynamic> prefs) {
    if (_pendingPoint != null) {
      _initialCenter = _pendingPoint!;
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
    _readers[descriptor.path] = reader;
    return reader;
  }

  void _moveTo(LatLng point, {double minZoom = 16}) {
    final zoom = _mapController.camera.zoom;
    _mapController.move(point, zoom < minZoom ? minZoom : zoom);
  }

  // ---------------------------------------------------------------------
  // Map interaction
  // ---------------------------------------------------------------------

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    if (_placement != null) {
      setState(() => _pendingPoint = latLng);
      return;
    }
    setState(() {
      _selectedUuid = null;
      _panel = CaveMapPanel.none;
    });
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng latLng) {
    if (_placement != null || _isExternalPicker) return;
    unawaited(_openAddMenu(initialPoint: latLng));
  }

  void _onMarkerTap(CaveMapPlaceItem item) {
    if (_placement != null) {
      // While placing, snap the pending point onto the tapped marker.
      setState(() => _pendingPoint = item.point);
      return;
    }
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
      if (!item.isFocus) _showOtherCaves = true;
      if (!item.isEntrance) _showNonEntrances = true;
    });
    _moveTo(item.point, minZoom: 15);
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
    try {
      await _loadItems();
    } catch (e, st) {
      _log.warning('Reload after place edit failed', e, st);
    }
    if (mounted) setState(() {});
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
    unawaited(_positionSub?.cancel());
    _positionSub = _location.positionStream().listen(
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
    if (!await _ensureLocationReady()) return;
    if (!_locationActive) _startPositionStream();
    final fix = await _location.currentPosition();
    if (!mounted) return;
    setState(() {
      _locationActive = true;
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
      _placement = CaveMapPlacement(
        kind: kind,
        existingPlace: existingPlace,
        subjectLabel: subjectLabel,
      );
      _pendingPoint = point ??
          (existingPlace != null &&
                  existingPlace.latitude != null &&
                  existingPlace.longitude != null
              ? LatLng(existingPlace.latitude!, existingPlace.longitude!)
              : null);
      _panel = CaveMapPanel.none;
      _selectedUuid = null;
    });
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

  Future<void> _useMyLocationForPending() async {
    setState(() => _locating = true);
    try {
      if (!await _ensureLocationReady()) return;
      if (!_locationActive) _startPositionStream();
      final fix = await _location.currentPosition();
      if (!mounted || fix == null) return;
      final point = LatLng(fix.latitude, fix.longitude);
      setState(() {
        _locationActive = true;
        _myPosition = fix;
        _pendingPoint = point;
      });
      _moveTo(point, minZoom: 16);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _cancelPlacement() {
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

    if (placement.kind == PlacementKind.returnToCaller) {
      Navigator.pop(
        context,
        CaveMapPickResult(
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      );
      return;
    }

    final loc = LocServ.inst;
    final geo = ref.read(caveGeoServiceProvider);
    Uuid? selectAfter;
    try {
      switch (placement.kind) {
        case PlacementKind.returnToCaller:
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
          final caveUuid = await _chooseCave();
          if (caveUuid == null || !mounted) return;
          final title = await _promptText(
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
          SnackBarService.showSuccess(loc.t('map_entrance_added'));
        case PlacementKind.newCave:
          final input = await _promptNewCave();
          if (input == null || !mounted) return;
          setState(() => _placementBusy = true);
          final created = await geo.addCaveWithEntranceAt(
            caveTitle: input.caveTitle,
            entranceTitle: input.entranceTitle,
            latitude: point.latitude,
            longitude: point.longitude,
          );
          _createdCaveUuids.add(created.caveUuid);
          selectAfter = created.entranceUuid;
          SnackBarService.showSuccess(loc.t('map_cave_added'));
      }

      await _loadItems();
      if (!mounted) return;
      setState(() {
        _placement = null;
        _pendingPoint = null;
        _placementBusy = false;
        _selectedUuid = selectAfter;
      });
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
  // Prompts
  // ---------------------------------------------------------------------

  Future<Uuid?> _chooseCave() async {
    final loc = LocServ.inst;
    final caves = await ref.read(caveRepositoryProvider).getCaves()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    if (!mounted) return null;
    if (caves.isEmpty) {
      SnackBarService.showWarning(loc.t('map_no_caves_for_entrance'));
      return null;
    }
    var query = '';
    return showModalBottomSheet<Uuid>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final filtered = query.isEmpty
              ? caves
              : caves
                  .where((c) => c.title.toLowerCase().contains(query))
                  .toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      loc.t('map_choose_cave'),
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: loc.t('search'),
                      ),
                      onChanged: (v) =>
                          setSheet(() => query = v.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: Text(filtered[i].title),
                        onTap: () => Navigator.pop(ctx, filtered[i].uuid),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _promptText({
    required String titleKey,
    required String labelKey,
    String initial = '',
  }) async {
    final loc = LocServ.inst;
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t(titleKey)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: loc.t(labelKey)),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(loc.t('ok')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<_NewCaveInput?> _promptNewCave() async {
    final loc = LocServ.inst;
    final caveController = TextEditingController();
    final entranceController = TextEditingController(text: loc.t('entrance'));
    final result = await showDialog<_NewCaveInput>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('map_new_cave')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: caveController,
              autofocus: true,
              decoration: InputDecoration(labelText: loc.t('cave_title')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: entranceController,
              decoration: InputDecoration(
                labelText: loc.t('map_entrance_title'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final caveTitle = caveController.text.trim();
              if (caveTitle.isEmpty) return;
              final entrance = entranceController.text.trim();
              Navigator.pop(
                ctx,
                _NewCaveInput(
                  caveTitle,
                  entrance.isEmpty ? loc.t('entrance') : entrance,
                ),
              );
            },
            child: Text(loc.t('add')),
          ),
        ],
      ),
    );
    caveController.dispose();
    entranceController.dispose();
    return result;
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
      if (_placement != null && _pendingPoint != null)
        Marker(
          point: _pendingPoint!,
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
                      onLongPress: _onMapLongPress,
                      onPositionChanged: (camera, hasGesture) {
                        _lastCenter = camera.center;
                        _lastZoom = camera.zoom;
                        if (hasGesture && _followMe) {
                          setState(() => _followMe = false);
                        }
                      },
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      _buildBaseLayer(),
                      ..._buildOverlayLayers(),
                      if (_locationActive && _myPosition != null)
                        ...CaveMapMyLocation.layers(_myPosition!),
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
                  showOtherCaves: _showOtherCaves,
                  showNonEntrances: _showNonEntrances,
                  locationActive: _locationActive && _followMe,
                  activePanel: _panel,
                  onBack: () => Navigator.pop(context),
                  onMyLocation: () => unawaited(_toggleMyLocation()),
                  onToggleOtherCaves: _onToggleOtherCaves,
                  onToggleNonEntrances: _onToggleNonEntrances,
                  onPanelToggled: _onPanelToggled,
                  onAdd: (_isExternalPicker || _placement != null)
                      ? null
                      : () => unawaited(_openAddMenu()),
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
    if (_placement != null) {
      return CaveMapPlacementBar(
        placement: _placement!,
        point: _pendingPoint,
        busy: _placementBusy,
        locating: _locating,
        onUseLocation: () => unawaited(_useMyLocationForPending()),
        onCancel: _cancelPlacement,
        onConfirm: () => unawaited(_confirmPlacement()),
      );
    }
    final selected = _selectedItem;
    if (selected != null) {
      return CaveMapPlaceInfoCard(
        item: selected,
        onClose: () => setState(() => _selectedUuid = null),
        onOpenPlace: _isExternalPicker ? null : _openSelectedPlace,
        onSetLocation:
            _isExternalPicker ? null : () => _startMovePlace(selected),
      );
    }
    return const SizedBox.shrink();
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
}
