import 'dart:math' as math;

/// How coordinates are rendered throughout the app (map info card,
/// placement bar, cave-place form). Stored in `configurations` under
/// `coordinateFormatKey` by [id]; parsing on entry always accepts every
/// format regardless of the display choice.
enum CoordinateDisplayFormat {
  decimal('decimal'),
  dms('dms'),
  utm('utm');

  const CoordinateDisplayFormat(this.id);

  final String id;

  static CoordinateDisplayFormat fromId(String? id) => values.firstWhere(
    (f) => f.id == id,
    orElse: () => CoordinateDisplayFormat.decimal,
  );
}

/// A WGS84 → UTM projection result. [band] is the MGRS latitude band
/// letter (C–X, no I/O); bands N and above are the northern hemisphere.
typedef UtmCoordinate = ({int zone, String band, double easting, double northing});

typedef GeoPoint = ({double latitude, double longitude});

/// Formats [latitude], [longitude] in the given display format. UTM falls
/// back to decimal degrees outside the projection's ±80°/84° latitude
/// range.
String formatCoordinates(
  double latitude,
  double longitude,
  CoordinateDisplayFormat format,
) {
  switch (format) {
    case CoordinateDisplayFormat.decimal:
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    case CoordinateDisplayFormat.dms:
      return formatDms(latitude, longitude);
    case CoordinateDisplayFormat.utm:
      final utm = latLngToUtm(latitude, longitude);
      if (utm == null) {
        return formatCoordinates(
          latitude,
          longitude,
          CoordinateDisplayFormat.decimal,
        );
      }
      return '${utm.zone}${utm.band} '
          '${utm.easting.round()} ${utm.northing.round()}';
  }
}

/// `45°21'33.0"N 22°42'53.0"E`. Seconds carry one decimal; rounding is done
/// in tenths of arcseconds so 59.96" carries into the minute instead of
/// rendering as 60.0".
String formatDms(double latitude, double longitude) {
  String part(double value, String positive, String negative) {
    final hemisphere = value < 0 ? negative : positive;
    // Total tenths of arcseconds, rounded once, then decomposed.
    var tenths = (value.abs() * 36000).round();
    final degrees = tenths ~/ 36000;
    tenths -= degrees * 36000;
    final minutes = tenths ~/ 600;
    tenths -= minutes * 600;
    final seconds = tenths / 10;
    return "$degrees°${minutes.toString().padLeft(2, '0')}'"
        '${seconds.toStringAsFixed(1).padLeft(4, '0')}"$hemisphere';
  }

  return '${part(latitude, 'N', 'S')} ${part(longitude, 'E', 'W')}';
}

// ---------------------------------------------------------------------------
//  UTM projection (WGS84, Snyder series — accurate to well under a meter)
// ---------------------------------------------------------------------------

const double _a = 6378137.0; // WGS84 semi-major axis
const double _f = 1 / 298.257223563;
const double _k0 = 0.9996;
const double _e2 = _f * (2 - _f); // first eccentricity squared
const double _ep2 = _e2 / (1 - _e2); // second eccentricity squared

const String _bandLetters = 'CDEFGHJKLMNPQRSTUVWX';

/// MGRS latitude band for [latitude], or null outside [-80, 84].
String? utmBandLetter(double latitude) {
  if (latitude < -80 || latitude > 84) return null;
  if (latitude == 84) return 'X'; // X is 12° tall (72..84)
  final index = ((latitude + 80) / 8).floor().clamp(0, 19);
  return _bandLetters[index];
}

/// UTM zone for a point, including the Norway (32V) and Svalbard
/// exceptions to the plain 6° slicing.
int utmZone(double latitude, double longitude) {
  // Normalize longitude to [-180, 180).
  final lon = ((longitude + 180) % 360 + 360) % 360 - 180;
  if (latitude >= 56 && latitude < 64 && lon >= 3 && lon < 12) return 32;
  if (latitude >= 72 && latitude <= 84) {
    if (lon >= 0 && lon < 9) return 31;
    if (lon >= 9 && lon < 21) return 33;
    if (lon >= 21 && lon < 33) return 35;
    if (lon >= 33 && lon < 42) return 37;
  }
  return ((lon + 180) / 6).floor() % 60 + 1;
}

/// Projects WGS84 [latitude], [longitude] to UTM. Null outside the UTM
/// latitude range [-80, 84].
UtmCoordinate? latLngToUtm(double latitude, double longitude) {
  final band = utmBandLetter(latitude);
  if (band == null) return null;

  final zone = utmZone(latitude, longitude);
  final lonOrigin = (zone - 1) * 6 - 180 + 3;

  final phi = latitude * math.pi / 180;
  final dLambda = (longitude - lonOrigin) * math.pi / 180;

  final sinPhi = math.sin(phi), cosPhi = math.cos(phi), tanPhi = math.tan(phi);
  final n = _a / math.sqrt(1 - _e2 * sinPhi * sinPhi);
  final t = tanPhi * tanPhi;
  final c = _ep2 * cosPhi * cosPhi;
  final bigA = cosPhi * dLambda;

  final e4 = _e2 * _e2, e6 = e4 * _e2;
  final m = _a *
      ((1 - _e2 / 4 - 3 * e4 / 64 - 5 * e6 / 256) * phi -
          (3 * _e2 / 8 + 3 * e4 / 32 + 45 * e6 / 1024) * math.sin(2 * phi) +
          (15 * e4 / 256 + 45 * e6 / 1024) * math.sin(4 * phi) -
          (35 * e6 / 3072) * math.sin(6 * phi));

  final a2 = bigA * bigA, a3 = a2 * bigA, a4 = a3 * bigA;
  final a5 = a4 * bigA, a6 = a5 * bigA;
  final easting = _k0 *
          n *
          (bigA +
              (1 - t + c) * a3 / 6 +
              (5 - 18 * t + t * t + 72 * c - 58 * _ep2) * a5 / 120) +
      500000.0;
  var northing = _k0 *
      (m +
          n *
              tanPhi *
              (a2 / 2 +
                  (5 - t + 9 * c + 4 * c * c) * a4 / 24 +
                  (61 - 58 * t + t * t + 600 * c - 330 * _ep2) * a6 / 720));
  if (latitude < 0) northing += 10000000.0;

  return (zone: zone, band: band, easting: easting, northing: northing);
}

/// Inverse UTM → WGS84 for a zone/hemisphere pair.
GeoPoint utmToLatLng({
  required int zone,
  required bool northernHemisphere,
  required double easting,
  required double northing,
}) {
  final x = easting - 500000.0;
  final y = northernHemisphere ? northing : northing - 10000000.0;

  final m = y / _k0;
  final e4 = _e2 * _e2, e6 = e4 * _e2;
  final mu = m / (_a * (1 - _e2 / 4 - 3 * e4 / 64 - 5 * e6 / 256));

  final sqrt1e2 = math.sqrt(1 - _e2);
  final e1 = (1 - sqrt1e2) / (1 + sqrt1e2);
  final e1p2 = e1 * e1, e1p3 = e1p2 * e1, e1p4 = e1p3 * e1;
  final phi1 = mu +
      (3 * e1 / 2 - 27 * e1p3 / 32) * math.sin(2 * mu) +
      (21 * e1p2 / 16 - 55 * e1p4 / 32) * math.sin(4 * mu) +
      (151 * e1p3 / 96) * math.sin(6 * mu) +
      (1097 * e1p4 / 512) * math.sin(8 * mu);

  final sinPhi1 = math.sin(phi1), cosPhi1 = math.cos(phi1);
  final tanPhi1 = math.tan(phi1);
  final c1 = _ep2 * cosPhi1 * cosPhi1;
  final t1 = tanPhi1 * tanPhi1;
  final oneMinusE2Sin2 = 1 - _e2 * sinPhi1 * sinPhi1;
  final n1 = _a / math.sqrt(oneMinusE2Sin2);
  final r1 = _a * (1 - _e2) / (oneMinusE2Sin2 * math.sqrt(oneMinusE2Sin2));
  final d = x / (n1 * _k0);

  final d2 = d * d, d3 = d2 * d, d4 = d3 * d, d5 = d4 * d, d6 = d5 * d;
  final phi = phi1 -
      (n1 * tanPhi1 / r1) *
          (d2 / 2 -
              (5 + 3 * t1 + 10 * c1 - 4 * c1 * c1 - 9 * _ep2) * d4 / 24 +
              (61 + 90 * t1 + 298 * c1 + 45 * t1 * t1 - 252 * _ep2 -
                      3 * c1 * c1) *
                  d6 /
                  720);
  final lambda = (d -
          (1 + 2 * t1 + c1) * d3 / 6 +
          (5 - 2 * c1 + 28 * t1 - 3 * c1 * c1 + 8 * _ep2 + 24 * t1 * t1) *
              d5 /
              120) /
      cosPhi1;

  final lonOrigin = (zone - 1) * 6 - 180 + 3;
  return (
    latitude: phi * 180 / math.pi,
    longitude: lonOrigin + lambda * 180 / math.pi,
  );
}

// ---------------------------------------------------------------------------
//  Parsing (entry accepts any supported format, auto-detected)
// ---------------------------------------------------------------------------

/// Parses coordinates typed or pasted in any supported format:
/// - UTM: `34T 634604 5023721`
/// - DMS / degrees-minutes: `45°21'33"N 22°42'53"E`, `N45 21.55 E22 42.88`
/// - decimal degrees: `45.359167, 22.714722` (also `45,359167 22,714722`)
///
/// Returns null when the text matches nothing or fails range validation.
GeoPoint? parseCoordinates(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  return _parseUtm(trimmed) ?? _parseDms(trimmed) ?? _parseDecimal(trimmed);
}

final RegExp _utmPattern = RegExp(
  r'^(\d{1,2})\s*([C-HJ-NP-X])\s+(\d{1,6}(?:[.,]\d+)?)\s*[,;\s]\s*(\d{1,8}(?:[.,]\d+)?)$',
  caseSensitive: false,
);

GeoPoint? _parseUtm(String text) {
  final match = _utmPattern.firstMatch(text);
  if (match == null) return null;
  final zone = int.parse(match.group(1)!);
  if (zone < 1 || zone > 60) return null;
  final band = match.group(2)!.toUpperCase();
  final easting = double.parse(match.group(3)!.replaceAll(',', '.'));
  final northing = double.parse(match.group(4)!.replaceAll(',', '.'));
  if (easting < 100000 || easting > 900000) return null;
  if (northing < 0 || northing > 10000000) return null;

  final point = utmToLatLng(
    zone: zone,
    northernHemisphere: band.compareTo('N') >= 0,
    easting: easting,
    northing: northing,
  );
  return _validated(point.latitude, point.longitude);
}

/// DMS tokenizer. Commas are treated as separators (DMS fractions use a
/// dot); hemisphere letters may lead or trail each part.
GeoPoint? _parseDms(String text) {
  if (!RegExp("[°º'\"′″]|[NSEW]", caseSensitive: false).hasMatch(text)) {
    return null;
  }
  final tokens = <Object>[]; // double for numbers, String for hemispheres
  for (final match in RegExp(
    r'(\d+(?:\.\d+)?)|([NSEWnsew])(?![a-zA-Z])',
  ).allMatches(text)) {
    if (match.group(1) != null) {
      tokens.add(double.parse(match.group(1)!));
    } else {
      tokens.add(match.group(2)!.toUpperCase());
    }
  }

  final letterIndexes = [
    for (var i = 0; i < tokens.length; i++)
      if (tokens[i] is String) i,
  ];
  if (letterIndexes.length != 2) return null;
  final [first, second] = letterIndexes;

  List<double>? numbersIn(int start, int end) {
    final slice = tokens.sublist(start, end).cast<double>();
    return (slice.isEmpty || slice.length > 3) ? null : slice;
  }

  final List<double>? group1, group2;
  if (first == 0) {
    // Letters lead: N 45 21 33 E 22 42 53
    group1 = numbersIn(1, second);
    group2 = numbersIn(second + 1, tokens.length);
  } else if (second == tokens.length - 1) {
    // Letters trail: 45 21 33 N 22 42 53 E
    group1 = numbersIn(0, first);
    group2 = numbersIn(first + 1, second);
  } else {
    return null;
  }
  if (group1 == null || group2 == null) return null;

  double? valueOf(List<double> parts, String hemisphere) {
    final degrees = parts[0];
    final minutes = parts.length > 1 ? parts[1] : 0.0;
    final seconds = parts.length > 2 ? parts[2] : 0.0;
    if (minutes >= 60 || seconds >= 60) return null;
    // A fractional degree entry cannot also carry minutes.
    if (parts.length > 1 && degrees != degrees.truncateToDouble()) return null;
    if (parts.length > 2 && minutes != minutes.truncateToDouble()) return null;
    final value = degrees + minutes / 60 + seconds / 3600;
    return (hemisphere == 'S' || hemisphere == 'W') ? -value : value;
  }

  final hemisphere1 = tokens[first == 0 ? 0 : first] as String;
  final hemisphere2 = tokens[second] as String;
  final value1 = valueOf(group1, hemisphere1);
  final value2 = valueOf(group2, hemisphere2);
  if (value1 == null || value2 == null) return null;

  final isLat1 = hemisphere1 == 'N' || hemisphere1 == 'S';
  final isLat2 = hemisphere2 == 'N' || hemisphere2 == 'S';
  if (isLat1 == isLat2) return null;
  return isLat1
      ? _validated(value1, value2)
      : _validated(value2, value1);
}

GeoPoint? _parseDecimal(String text) {
  var tokens = text
      .split(RegExp(r'[;\s]+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.length == 1 && tokens.single.contains(',')) {
    // "45.36,22.71" — the comma is the separator.
    tokens = tokens.single.split(',');
  }
  if (tokens.length == 2) {
    // "45.36, 22.71" split on whitespace leaves a trailing comma.
    tokens = [for (final t in tokens) t.replaceAll(RegExp(r',$'), '')];
  }
  if (tokens.length != 2) return null;
  final lat = double.tryParse(tokens[0].replaceAll(',', '.'));
  final lng = double.tryParse(tokens[1].replaceAll(',', '.'));
  if (lat == null || lng == null) return null;
  return _validated(lat, lng);
}

GeoPoint? _validated(double latitude, double longitude) =>
    (latitude.abs() <= 90 && longitude.abs() <= 180)
        ? (latitude: latitude, longitude: longitude)
        : null;
