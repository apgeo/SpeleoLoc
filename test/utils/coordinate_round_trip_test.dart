import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/coordinate_formats.dart';

/// Great-circle distance in metres; good to centimetres at these sizes.
double _metres(double lat1, double lon1, double lat2, double lon2) {
  const radius = 6371008.8;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a =
      pow(sin(dLat / 2), 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLon / 2), 2);
  return 2 * radius * asin(min(1.0, sqrt(a)));
}

/// What printing a point and reading it back may lose, by format: decimal
/// keeps six places, DMS a tenth of an arcsecond, UTM whole metres.
const _tolerance = {
  CoordinateDisplayFormat.decimal: 0.5,
  CoordinateDisplayFormat.dms: 4.0,
  CoordinateDisplayFormat.utm: 2.0,
};

/// The round trip may refuse a spelling, never read it as another place.
void main() {
  final random = Random(20261107);
  final points = [
    for (var i = 0; i < 1000; i++)
      (
        lat: (random.nextDouble() * 2 - 1) * 79.9,
        lon: (random.nextDouble() * 2 - 1) * 179.9,
      ),
  ];

  for (final format in CoordinateDisplayFormat.values) {
    for (final comma in [false, true]) {
      test('${format.id} with a decimal ${comma ? 'comma' : 'point'} reads '
          'back as the same place or not at all', () {
        final wrong = <String>[];
        var read = 0;
        for (final p in points) {
          var text = formatCoordinates(p.lat, p.lon, format);
          if (comma) text = text.replaceAll('.', ',');
          final parsed = parseCoordinates(text);
          if (parsed == null) continue;
          read++;
          final off = _metres(p.lat, p.lon, parsed.latitude, parsed.longitude);
          if (off > _tolerance[format]!) {
            wrong.add('$text is ${off.toStringAsFixed(1)} m off');
          }
        }
        expect(wrong, isEmpty, reason: wrong.take(5).join('\n'));
        if (!comma) {
          expect(read, points.length, reason: 'the app reads its own output');
        }
      });
    }
  }
}
