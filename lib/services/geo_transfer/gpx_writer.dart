import 'package:speleoloc/services/geo_transfer/geo_waypoint.dart';
import 'package:xml/xml.dart';

/// Serializes waypoints as a GPX 1.1 document (`<wpt>` elements only —
/// the interchange subset Garmin/Locus/QGIS all read).
String writeGpx(List<GeoWaypoint> waypoints) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element(
    'gpx',
    nest: () {
      builder.attribute('version', '1.1');
      builder.attribute('creator', 'SpeleoLoc');
      builder.attribute('xmlns', 'http://www.topografix.com/GPX/1/1');
      for (final waypoint in waypoints) {
        builder.element(
          'wpt',
          nest: () {
            builder.attribute('lat', waypoint.latitude.toStringAsFixed(7));
            builder.attribute('lon', waypoint.longitude.toStringAsFixed(7));
            if (waypoint.altitude != null) {
              builder.element(
                'ele',
                nest: waypoint.altitude!.toStringAsFixed(1),
              );
            }
            builder.element('name', nest: waypoint.name);
            if (waypoint.description?.isNotEmpty ?? false) {
              builder.element('desc', nest: waypoint.description);
            }
          },
        );
      }
    },
  );
  return builder.buildDocument().toXmlString(pretty: true, indent: '  ');
}
