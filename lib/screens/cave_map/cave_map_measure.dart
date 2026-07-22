import 'package:latlong2/latlong.dart';

/// The active measuring path: the ordered points tapped in measure mode
/// plus the derived readouts shown in the measure bar.
class MeasurePath {
  const MeasurePath(this.points);

  final List<LatLng> points;

  static const Distance _distance = Distance();

  double get totalMeters {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += _distance.distance(points[i - 1], points[i]);
    }
    return total;
  }

  double? get lastLegMeters => points.length < 2
      ? null
      : _distance.distance(points[points.length - 2], points.last);

  /// Initial bearing of the last leg, normalized to [0, 360).
  double? get lastLegBearingDegrees {
    if (points.length < 2) return null;
    final bearing = _distance.bearing(points[points.length - 2], points.last);
    return (bearing % 360 + 360) % 360;
  }

  /// `853 m` below one kilometer, `1.25 km` from there on.
  static String formatMeters(double meters) => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(2)} km';
}
