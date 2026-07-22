import 'package:speleoloc/services/geo_transfer/geo_waypoint.dart';
import 'package:xml/xml.dart';

/// Parses waypoints out of GPX (`<wpt>`) or KML (point `<Placemark>`)
/// text, detected by the root element. Namespace prefixes are ignored —
/// files in the wild carry all sorts of them. Entries without a valid
/// position are skipped; a file that is not GPX/KML at all throws
/// [FormatException].
List<GeoWaypoint> parseWaypoints(String xmlText) {
  final XmlDocument document;
  try {
    document = XmlDocument.parse(xmlText);
  } on XmlException {
    throw const FormatException('Not an XML document');
  }
  final root = document.rootElement.localName.toLowerCase();
  return switch (root) {
    'gpx' => _parseGpx(document),
    'kml' => _parseKml(document),
    _ => throw FormatException('Unsupported root element <$root>'),
  };
}

Iterable<XmlElement> _elementsNamed(XmlNode node, String localName) => node
    .descendants
    .whereType<XmlElement>()
    .where((e) => e.localName.toLowerCase() == localName);

String? _childText(XmlElement element, String localName) {
  for (final child in element.childElements) {
    if (child.localName.toLowerCase() == localName) {
      final text = child.innerText.trim();
      return text.isEmpty ? null : text;
    }
  }
  return null;
}

// double.tryParse accepts 'NaN'/'Infinity', and NaN passes any range
// comparison, so validity needs an explicit isFinite check.
bool _validPosition(double? lat, double? lon) =>
    lat != null &&
    lon != null &&
    lat.isFinite &&
    lon.isFinite &&
    lat.abs() <= 90 &&
    lon.abs() <= 180;

List<GeoWaypoint> _parseGpx(XmlDocument document) {
  final waypoints = <GeoWaypoint>[];
  for (final wpt in _elementsNamed(document, 'wpt')) {
    final lat = double.tryParse(wpt.getAttribute('lat') ?? '');
    final lon = double.tryParse(wpt.getAttribute('lon') ?? '');
    if (!_validPosition(lat, lon)) continue;
    waypoints.add(
      GeoWaypoint(
        name: _childText(wpt, 'name') ?? '',
        latitude: lat!,
        longitude: lon!,
        altitude: double.tryParse(_childText(wpt, 'ele') ?? ''),
        description: _childText(wpt, 'desc') ?? _childText(wpt, 'cmt'),
      ),
    );
  }
  return waypoints;
}

List<GeoWaypoint> _parseKml(XmlDocument document) {
  final waypoints = <GeoWaypoint>[];
  for (final placemark in _elementsNamed(document, 'placemark')) {
    // Only point placemarks import; lines/polygons are not cave places.
    final points = _elementsNamed(placemark, 'point');
    if (points.isEmpty) continue;
    final coordinates = _childText(points.first, 'coordinates');
    if (coordinates == null) continue;
    // lon,lat[,ele]; tolerate stray whitespace/newlines inside the tag.
    final parts = coordinates.split(RegExp(r'[\s]+')).first.split(',');
    if (parts.length < 2) continue;
    final lon = double.tryParse(parts[0]);
    final lat = double.tryParse(parts[1]);
    if (!_validPosition(lat, lon)) continue;
    waypoints.add(
      GeoWaypoint(
        name: _childText(placemark, 'name') ?? '',
        latitude: lat!,
        longitude: lon!,
        altitude: parts.length > 2 ? double.tryParse(parts[2]) : null,
        description: _childText(placemark, 'description'),
      ),
    );
  }
  return waypoints;
}
