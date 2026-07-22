import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/services/map/map_mbtiles_config.dart';
import 'package:speleoloc/services/map/mbtiles_isolate_reader.dart';
import 'package:speleoloc/services/map/mbtiles_registry.dart';
import 'package:speleoloc/services/map/tile_disk_cache.dart';
import 'package:speleoloc/services/map/tile_layer_sources.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/widgets/map/cached_network_tile_provider.dart';
import 'package:speleoloc/widgets/map/mbtiles_tile_provider.dart';

/// Owns the surface map's tile stack: the selected base layer, the
/// enabled overlays, the discovered MBTiles files with their
/// worker-isolate readers, and the persisted screen prefs (layer choice
/// plus last camera). Notifies when a layer choice changes or a reader
/// finishes opening.
class CaveMapLayersController extends ChangeNotifier {
  CaveMapLayersController({
    required IConfigurationRepository configRepository,
    required Future<List<MbTilesDescriptor>> Function() scanMbTiles,
  }) : _configRepository = configRepository,
       _scanMbTiles = scanMbTiles;

  static const String _userAgentPackageName = 'com.example.speleoloc';

  final IConfigurationRepository _configRepository;
  final Future<List<MbTilesDescriptor>> Function() _scanMbTiles;
  final _log = AppLogger.of('CaveMapLayersController');

  String _baseId = builtInTileSourcesDefaultId;
  Set<String> _enabledOverlays = {};
  MapMbTilesConfig _mbConfig = const MapMbTilesConfig();
  List<MbTilesDescriptor> _mbtiles = [];
  final Map<String, MbTilesIsolateReader?> _readers = {};
  final Set<String> _readerOpensInFlight = {};
  bool _disposed = false;
  bool _tileCacheEnabled = true;

  /// Disk cache for the online sources, injected by the page after the
  /// async directory lookup. Null (or the setting being off) falls back
  /// to flutter_map's plain network provider.
  TileDiskCache? tileCache;

  /// Last camera state, pushed by the page on every move so [savePrefs]
  /// can persist it. Not listenable — it changes every frame.
  LatLng? lastCenter;
  double? lastZoom;

  String get baseId => _baseId;
  Set<String> get enabledOverlays => _enabledOverlays;

  List<MbTilesDescriptor> get baseDescriptors => [
    for (final d in _mbtiles)
      if (d.metadata.isRaster && _mbConfig.roleOf(d.fileName) == MbTilesRole.base)
        d,
  ];

  List<MbTilesDescriptor> get overlayDescriptors => [
    for (final d in _mbtiles)
      if (d.metadata.isRaster &&
          _mbConfig.roleOf(d.fileName) == MbTilesRole.overlay)
        d,
  ];

  /// Loads the MBTiles config, scans the folder when auto-load is on and
  /// restores the persisted layer choice. Returns the raw prefs map so
  /// the caller can restore the camera from it.
  Future<Map<String, dynamic>> load() async {
    final prefs = await _configRepository.readJson(
      mapScreenPrefsKey,
      defaults: () => <String, dynamic>{},
    );
    _mbConfig = MapMbTilesConfig.fromJson(
      await _configRepository.readJson(
        mapMbtilesConfigKey,
        defaults: () => <String, dynamic>{},
      ),
    );
    if (_mbConfig.autoLoad) {
      _mbtiles = await _scanMbTiles();
    }
    _tileCacheEnabled =
        await _configRepository.readString(tileCacheEnabledKey) != 'false';

    final base = prefs['base'];
    if (base is String && baseLayerExists(base)) _baseId = base;
    final overlays = prefs['overlays'];
    if (overlays is List) {
      final known = overlayDescriptors.map((d) => d.fileName).toSet();
      _enabledOverlays = overlays
          .whereType<String>()
          .where(known.contains)
          .toSet();
    }
    return prefs;
  }

  Future<void> savePrefs() async {
    try {
      await _configRepository.writeJson(mapScreenPrefsKey, {
        'base': _baseId,
        'overlays': _enabledOverlays.toList(),
        if (lastCenter != null) 'lat': lastCenter!.latitude,
        if (lastCenter != null) 'lng': lastCenter!.longitude,
        if (lastZoom != null) 'zoom': lastZoom,
      });
    } catch (e, st) {
      _log.warning('Failed to persist map prefs', e, st);
    }
  }

  void selectBase(String id) {
    _baseId = id;
    notifyListeners();
    unawaited(savePrefs());
  }

  void toggleOverlay(String fileName, bool enabled) {
    if (enabled) {
      _enabledOverlays = {..._enabledOverlays, fileName};
    } else {
      _enabledOverlays = {..._enabledOverlays}..remove(fileName);
    }
    notifyListeners();
    unawaited(savePrefs());
  }

  bool baseLayerExists(String id) =>
      findTileSourceById(id) != null || _mbtilesBaseDescriptor(id) != null;

  /// Resolves a base-layer id of the form `mbtiles:<fileName>` to its
  /// descriptor; null for online-source ids and files no longer present.
  MbTilesDescriptor? _mbtilesBaseDescriptor(String id) {
    if (!id.startsWith('mbtiles:')) return null;
    final fileName = id.substring('mbtiles:'.length);
    for (final descriptor in baseDescriptors) {
      if (descriptor.fileName == fileName) return descriptor;
    }
    return null;
  }

  /// Returns the worker-isolate reader for [descriptor] once it is open;
  /// null while the first open is still in flight (kicked off here) and
  /// for files that failed to open.
  MbTilesIsolateReader? _readerFor(MbTilesDescriptor descriptor) {
    if (_readers.containsKey(descriptor.path)) {
      return _readers[descriptor.path];
    }
    if (_readerOpensInFlight.add(descriptor.path)) {
      unawaited(_openReader(descriptor));
    }
    return null;
  }

  Future<void> _openReader(MbTilesDescriptor descriptor) async {
    MbTilesIsolateReader? reader;
    try {
      reader = await MbTilesIsolateReader.open(descriptor.path);
    } catch (e, st) {
      _log.warning('Failed to open MBTiles ${descriptor.fileName}', e, st);
    }
    if (_disposed) {
      reader?.dispose();
      return;
    }
    // Failures are cached as null so a corrupt file is not re-opened on
    // every rebuild.
    _readers[descriptor.path] = reader;
    notifyListeners();
  }

  TileLayer? buildBaseLayer() {
    final descriptor = _mbtilesBaseDescriptor(_baseId);
    if (descriptor != null) {
      final reader = _readerFor(descriptor);
      if (reader != null) {
        return TileLayer(
          tileProvider: MbTilesTileProvider(reader),
          minNativeZoom: reader.metadata.minZoom ?? 0,
          maxNativeZoom: reader.metadata.maxZoom ?? 19,
        );
      }
      // First open still in flight: render no base layer for the frames
      // the worker needs, rather than flashing (and fetching) the online
      // fallback. An unreadable file falls through to the fallback.
      if (!_readers.containsKey(descriptor.path)) return null;
    }
    final source = findTileSourceById(_baseId) ?? builtInTileSources.first;
    final cache = tileCache;
    return TileLayer(
      urlTemplate: source.urlTemplate,
      subdomains: source.subdomains,
      maxNativeZoom: source.maxNativeZoom,
      userAgentPackageName: _userAgentPackageName,
      tileProvider: (_tileCacheEnabled && cache != null)
          ? CachedNetworkTileProvider(sourceId: source.id, cache: cache)
          : null,
    );
  }

  List<TileLayer> buildOverlayLayers() {
    final layers = <TileLayer>[];
    for (final descriptor in overlayDescriptors) {
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

  /// Mirrors [buildBaseLayer]'s resolution so the attribution always
  /// names the source actually rendered (an unreadable MBTiles file falls
  /// back to the online source in both places; one still opening renders
  /// blank tiles under its own name).
  String get attributionText {
    final descriptor = _mbtilesBaseDescriptor(_baseId);
    if (descriptor != null &&
        (_readerFor(descriptor) != null ||
            !_readers.containsKey(descriptor.path))) {
      return descriptor.displayName;
    }
    return (findTileSourceById(_baseId) ?? builtInTileSources.first)
        .attribution;
  }

  @override
  void dispose() {
    _disposed = true;
    for (final reader in _readers.values) {
      reader?.dispose();
    }
    super.dispose();
  }
}
