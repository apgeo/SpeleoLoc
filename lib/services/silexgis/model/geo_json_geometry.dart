/// A GeoJSON geometry as it travels on the sync wire, SRID 4326.
///
/// The document is kept verbatim rather than decomposed. A selection carries
/// everything under its roots, of every kind, so a device meets geometries it
/// has no local shape for — a surveyed centerline arrives as a
/// `MultiLineString` — and a type this build does not model must survive
/// storage and re-emission unchanged rather than being narrowed to a point and
/// silently truncated.
class GeoJsonGeometry {
  const GeoJsonGeometry(this._json);

  final Map<String, Object?> _json;

  /// `Point`, `MultiLineString`, … Never assume a closed set.
  String? get type => _json['type'] as String?;

  bool get isPoint => type == 'Point';

  /// The position of a `Point`, or null for any other geometry.
  ///
  /// GeoJSON orders a coordinate longitude-first; the application's own rows
  /// are latitude/longitude, which is the swap this pair exists to make
  /// explicit at exactly one place.
  double? get latitude => _pointOrdinate(1);
  double? get longitude => _pointOrdinate(0);

  /// The third ordinate of a `Point`, which is where an altitude comes back.
  ///
  /// **This is the only way an altitude is readable on a downloaded row.** A
  /// downloaded row has no `altitude` member of its own: an upload carries one
  /// in its own field and the server stores it as the point's third ordinate,
  /// which is also how it is handed back. A point with no altitude arrives
  /// two-dimensional, so a null here means none was recorded.
  double? get altitude => _pointOrdinate(2);

  double? _pointOrdinate(int index) {
    if (!isPoint) return null;
    final coordinates = _json['coordinates'];
    if (coordinates is! List || coordinates.length <= index) return null;
    final value = coordinates[index];
    return value is num ? value.toDouble() : null;
  }

  /// A point built from the application's own latitude/longitude pair.
  ///
  /// The altitude is deliberately **not** folded in as a third ordinate here:
  /// an upload carries it in its own `altitude` field, and sending both would
  /// state the same thing twice with no rule saying which wins.
  factory GeoJsonGeometry.point({
    required double latitude,
    required double longitude,
  }) => GeoJsonGeometry(<String, Object?>{
    'type': 'Point',
    'coordinates': <Object?>[longitude, latitude],
  });

  static GeoJsonGeometry? fromJson(Object? json) =>
      json is Map ? GeoJsonGeometry(Map<String, Object?>.from(json)) : null;

  Map<String, Object?> toJson() => _json;
}
