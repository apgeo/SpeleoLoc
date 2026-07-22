import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:speleoloc/screens/cave_map/cave_map_measure.dart';

void main() {
  group('MeasurePath', () {
    test('empty and single-point paths have no legs', () {
      expect(const MeasurePath([]).totalMeters, 0);
      expect(const MeasurePath([]).lastLegMeters, isNull);
      expect(
        const MeasurePath([LatLng(45, 22)]).lastLegBearingDegrees,
        isNull,
      );
    });

    test('one degree of latitude is ~111 km due north', () {
      const path = MeasurePath([LatLng(45, 22), LatLng(46, 22)]);
      expect(path.totalMeters, closeTo(111000, 500));
      expect(path.lastLegBearingDegrees, closeTo(0, 0.5));
    });

    test('eastward leg at the equator bears 90°', () {
      const path = MeasurePath([LatLng(0, 22), LatLng(0, 23)]);
      expect(path.lastLegBearingDegrees, closeTo(90, 0.5));
      expect(path.totalMeters, closeTo(111000, 500));
    });

    test('westward bearing is normalized into [0, 360)', () {
      const path = MeasurePath([LatLng(0, 23), LatLng(0, 22)]);
      expect(path.lastLegBearingDegrees, closeTo(270, 0.5));
    });

    test('total sums every leg, last leg reads the final segment', () {
      const path = MeasurePath([
        LatLng(45, 22),
        LatLng(45, 22.01),
        LatLng(45.01, 22.01),
      ]);
      final leg1 = const MeasurePath([
        LatLng(45, 22),
        LatLng(45, 22.01),
      ]).totalMeters;
      final leg2 = const MeasurePath([
        LatLng(45, 22.01),
        LatLng(45.01, 22.01),
      ]).totalMeters;
      expect(path.totalMeters, closeTo(leg1 + leg2, 0.01));
      expect(path.lastLegMeters, closeTo(leg2, 0.01));
    });

    test('formatMeters switches to kilometers at 1000 m', () {
      expect(MeasurePath.formatMeters(853.4), '853 m');
      expect(MeasurePath.formatMeters(999.4), '999 m');
      expect(MeasurePath.formatMeters(1250), '1.25 km');
    });
  });
}
