import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/coordinate_formats.dart';

void main() {
  group('latLngToUtm', () {
    test('matches a known northern-hemisphere reference point', () {
      // CN Tower, Toronto — 17T 630084 4833439 (published reference).
      final utm = latLngToUtm(43.642567, -79.387139)!;
      expect(utm.zone, 17);
      expect(utm.band, 'T');
      expect(utm.easting, closeTo(630084, 1));
      expect(utm.northing, closeTo(4833439, 1));
    });

    test('matches a known southern-hemisphere reference point', () {
      // Flinders Peak — 55H 273741.297 5796489.777, the worked Redfearn
      // example from the GDA Technical Manual (GDA94 ≈ WGS84 within ~2 m).
      final utm = latLngToUtm(-37.95103342, 144.42486789)!;
      expect(utm.zone, 55);
      expect(utm.band, 'H');
      expect(utm.easting, closeTo(273741.297, 2));
      expect(utm.northing, closeTo(5796489.777, 2));
    });

    test('applies the Norway zone exception', () {
      final utm = latLngToUtm(60.0, 5.0)!; // Bergen area: 32V, not 31
      expect(utm.zone, 32);
      expect(utm.band, 'V');
    });

    test('applies the Svalbard zone exceptions', () {
      expect(latLngToUtm(78.0, 8.0)!.zone, 31);
      expect(latLngToUtm(78.0, 15.0)!.zone, 33);
      expect(latLngToUtm(78.0, 30.0)!.zone, 35);
      expect(latLngToUtm(78.0, 39.0)!.zone, 37);
    });

    test('returns null outside the UTM latitude range', () {
      expect(latLngToUtm(85.0, 10.0), isNull);
      expect(latLngToUtm(-81.0, 10.0), isNull);
    });

    test('longitude 180 projects like -180 (antimeridian)', () {
      final atPlus = latLngToUtm(10.0, 180.0)!;
      final atMinus = latLngToUtm(10.0, -180.0)!;
      expect(atPlus.zone, 1);
      expect(atPlus.easting, closeTo(atMinus.easting, 0.01));
      expect(atPlus.northing, closeTo(atMinus.northing, 0.01));
      // Zone 1's central meridian is -177: 180 sits 3° west of it.
      expect(atPlus.easting, lessThan(500000));
      expect(atPlus.easting, greaterThan(100000));
    });

    test('round-trips through utmToLatLng within centimeters', () {
      const points = [
        (45.3592, 22.7147), // Retezat
        (-33.856944, 151.215278),
        (0.5, 0.5),
        (-0.5, -0.5),
        (71.0, 25.7),
      ];
      for (final (lat, lng) in points) {
        final utm = latLngToUtm(lat, lng)!;
        final back = utmToLatLng(
          zone: utm.zone,
          northernHemisphere: utm.band.compareTo('N') >= 0,
          easting: utm.easting,
          northing: utm.northing,
        );
        expect(back.latitude, closeTo(lat, 1e-7), reason: '$lat,$lng');
        expect(back.longitude, closeTo(lng, 1e-7), reason: '$lat,$lng');
      }
    });
  });

  group('formatCoordinates', () {
    test('decimal', () {
      expect(
        formatCoordinates(45.3592, 22.7147, CoordinateDisplayFormat.decimal),
        '45.359200, 22.714700',
      );
    });

    test('dms', () {
      expect(
        formatCoordinates(
          45.359167,
          -22.714722,
          CoordinateDisplayFormat.dms,
        ),
        '45°21\'33.0"N 22°42\'53.0"W',
      );
    });

    test('dms rounding carries instead of printing 60.0 seconds', () {
      expect(formatDms(44.99999999, 10), startsWith('45°00\'00.0"N'));
    });

    test('utm', () {
      expect(
        formatCoordinates(43.642567, -79.387139, CoordinateDisplayFormat.utm),
        '17T 630084 4833439',
      );
    });

    test('utm falls back to decimal outside the projection range', () {
      expect(
        formatCoordinates(87.0, 10.0, CoordinateDisplayFormat.utm),
        '87.000000, 10.000000',
      );
    });
  });

  group('parseCoordinates', () {
    void expectPoint(String text, double lat, double lng, {double tol = 1e-6}) {
      final point = parseCoordinates(text);
      expect(point, isNotNull, reason: text);
      expect(point!.latitude, closeTo(lat, tol), reason: text);
      expect(point.longitude, closeTo(lng, tol), reason: text);
    }

    test('decimal variants', () {
      expectPoint('45.3592, 22.7147', 45.3592, 22.7147);
      expectPoint('45.3592 22.7147', 45.3592, 22.7147);
      expectPoint('45.3592;22.7147', 45.3592, 22.7147);
      expectPoint('45.3592,22.7147', 45.3592, 22.7147);
      expectPoint('45,3592 22,7147', 45.3592, 22.7147);
      expectPoint('-33.856944, 151.215278', -33.856944, 151.215278);
    });

    test('dms with symbols, letters trailing', () {
      expectPoint('45°21\'33.0"N 22°42\'53.0"E', 45.359167, 22.714722);
      expectPoint('45°21\'33"S, 22°42\'53"W', -45.359167, -22.714722);
    });

    test('dms with letters leading and bare numbers', () {
      expectPoint('N45 21 33 E22 42 53', 45.359167, 22.714722);
      expectPoint('N 45 21.55 E 22 42.883', 45.359167, 22.714717, tol: 1e-4);
    });

    test('longitude-first dms is reordered by hemisphere letters', () {
      expectPoint('22°42\'53"E 45°21\'33"N', 45.359167, 22.714722);
    });

    test('degrees-with-letter-only variants', () {
      expectPoint('45.3592°N 22.7147°E', 45.3592, 22.7147);
      expectPoint('45.3592 N 22.7147 E', 45.3592, 22.7147);
    });

    test('utm round-trips through the parser', () {
      final point = parseCoordinates('17T 630084 4833439');
      expect(point, isNotNull);
      expect(point!.latitude, closeTo(43.642567, 1e-4));
      expect(point.longitude, closeTo(-79.387139, 1e-4));

      final south = parseCoordinates('55H 273741 5796490');
      expect(south!.latitude, closeTo(-37.95103342, 1e-4));
      expect(south.longitude, closeTo(144.42486789, 1e-4));
    });

    test('rejects garbage and out-of-range values', () {
      expect(parseCoordinates(''), isNull);
      expect(parseCoordinates('hello'), isNull);
      expect(parseCoordinates('91.0, 10.0'), isNull);
      expect(parseCoordinates('45.0, 181.0'), isNull);
      expect(parseCoordinates('45°61\'00"N 22°00\'00"E'), isNull);
      expect(parseCoordinates('45 21 33'), isNull);
      expect(parseCoordinates('61X 100000 1'), isNull);
      expect(parseCoordinates('45.0'), isNull);
      // double.tryParse accepts these spellings; validation must not.
      expect(parseCoordinates('NaN, NaN'), isNull);
      expect(parseCoordinates('Infinity, 10'), isNull);
    });
  });
}
