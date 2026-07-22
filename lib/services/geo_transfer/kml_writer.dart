import 'package:speleoloc/services/geo_transfer/geo_waypoint.dart';
import 'package:xml/xml.dart';

/// Serializes waypoints as a KML document of point placemarks (Google
/// Earth's interchange subset).
String writeKml(List<GeoWaypoint> waypoints) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element(
    'kml',
    nest: () {
      builder.attribute('xmlns', 'http://www.opengis.net/kml/2.2');
      builder.element(
        'Document',
        nest: () {
          for (final waypoint in waypoints) {
            builder.element(
              'Placemark',
              nest: () {
                builder.element('name', nest: waypoint.name);
                if (waypoint.description?.isNotEmpty ?? false) {
                  builder.element('description', nest: waypoint.description);
                }
                builder.element(
                  'Point',
                  nest: () {
                    // KML orders coordinates lon,lat[,ele].
                    final parts = [
                      waypoint.longitude.toStringAsFixed(7),
                      waypoint.latitude.toStringAsFixed(7),
                      if (waypoint.altitude != null)
                        waypoint.altitude!.toStringAsFixed(1),
                    ];
                    builder.element('coordinates', nest: parts.join(','));
                  },
                );
              },
            );
          }
        },
      );
    },
  );
  return builder.buildDocument().toXmlString(pretty: true, indent: '  ');
}
