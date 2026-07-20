/// One selectable online XYZ raster tile source (a base layer on the
/// surface map). `{s}` in [urlTemplate] is replaced by an entry of
/// [subdomains]; `{x}`/`{y}`/`{z}` by tile coordinates.
class TileLayerSource {
  final String id;
  final String name;
  final String urlTemplate;
  final List<String> subdomains;
  final String attribution;

  /// Highest zoom level the server actually offers; beyond it the map
  /// scales the last native tiles instead of requesting missing ones.
  final int maxNativeZoom;

  const TileLayerSource({
    required this.id,
    required this.name,
    required this.urlTemplate,
    this.subdomains = const [],
    required this.attribution,
    required this.maxNativeZoom,
  });
}

/// Base layer used before the user picks one (also the fallback when a
/// persisted selection no longer exists). OpenTopoMap: terrain shading and
/// contour lines suit cave field work best.
const String builtInTileSourcesDefaultId = 'opentopomap';

/// Built-in public XYZ tile servers selectable as base layers.
///
/// The Google entries use the widely deployed mt0–mt3 endpoints, which are
/// public but not an officially licensed API — kept by explicit owner
/// decision. Attribution strings follow each provider's usage policy.
const List<TileLayerSource> builtInTileSources = [
  TileLayerSource(
    id: 'opentopomap',
    name: 'OpenTopoMap',
    urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    attribution: '© OpenStreetMap contributors, SRTM | © OpenTopoMap (CC-BY-SA)',
    maxNativeZoom: 17,
  ),
  TileLayerSource(
    id: 'osm',
    name: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
    maxNativeZoom: 19,
  ),
  TileLayerSource(
    id: 'google_streets',
    name: 'Google Streets',
    urlTemplate: 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
    subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
    attribution: '© Google',
    maxNativeZoom: 20,
  ),
  TileLayerSource(
    id: 'google_satellite',
    name: 'Google Satellite',
    urlTemplate: 'https://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
    subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
    attribution: '© Google',
    maxNativeZoom: 20,
  ),
  TileLayerSource(
    id: 'google_hybrid',
    name: 'Google Hybrid',
    urlTemplate: 'https://{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
    subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
    attribution: '© Google',
    maxNativeZoom: 20,
  ),
  TileLayerSource(
    id: 'esri_imagery',
    name: 'Esri World Imagery',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '© Esri, Maxar, Earthstar Geographics',
    maxNativeZoom: 19,
  ),
  TileLayerSource(
    id: 'esri_topo',
    name: 'Esri World Topo',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
    attribution: '© Esri, HERE, Garmin, FAO, NOAA, USGS',
    maxNativeZoom: 19,
  ),
  TileLayerSource(
    id: 'carto_positron',
    name: 'Carto Positron',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c', 'd'],
    attribution: '© OpenStreetMap contributors © CARTO',
    maxNativeZoom: 20,
  ),
  TileLayerSource(
    id: 'cyclosm',
    name: 'CyclOSM',
    urlTemplate:
        'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    attribution: '© OpenStreetMap contributors | CyclOSM',
    maxNativeZoom: 19,
  ),
  TileLayerSource(
    id: 'osm_hot',
    name: 'OSM Humanitarian',
    urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    subdomains: ['a', 'b'],
    attribution: '© OpenStreetMap contributors | HOT OSM France',
    maxNativeZoom: 19,
  ),
];

/// Returns the built-in source with [id], or null when unknown (e.g. a
/// persisted selection from a removed source).
TileLayerSource? findTileSourceById(String id) {
  for (final s in builtInTileSources) {
    if (s.id == id) return s;
  }
  return null;
}
