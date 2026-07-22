/// One named point exchanged with other mapping tools via GPX or KML.
/// WGS84; [altitude] is meters when the source carried an elevation.
class GeoWaypoint {
  const GeoWaypoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.description,
  });

  final String name;
  final double latitude;
  final double longitude;
  final double? altitude;
  final String? description;
}
