import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_zoom_math.dart';

void main() {
  group('clampZoom', () {
    test('clamps below min', () {
      expect(clampZoom(0.0), kMinZoom);
    });
    test('clamps above max', () {
      expect(clampZoom(100.0), kMaxZoom);
    });
    test('passes through valid', () {
      expect(clampZoom(1.5), 1.5);
    });
  });

  group('offsetForPoint', () {
    const viewport = Size(800, 600);

    test('centers a point at scale=1', () {
      expect(offsetForPoint(400, 300, 1.0, viewport), Offset.zero);
    });

    test('offsets for non-center point at scale=1', () {
      expect(offsetForPoint(0, 0, 1.0, viewport), const Offset(400, 300));
    });

    test('applies scale', () {
      expect(offsetForPoint(200, 100, 2.0, viewport),
          Offset(800 / 2 - 200 * 2, 600 / 2 - 100 * 2));
    });
  });

  group('fitPointsTransform', () {
    const viewport = Size(800, 600);

    test('empty list returns null', () {
      expect(fitPointsTransform(const [], viewport), isNull);
    });

    test('single point: chooses max scale, centers point', () {
      final t = fitPointsTransform([const Offset(100, 100)], viewport)!;
      expect(t.scale, kMaxZoom);
      // Centered: offset = viewport/2 - point * scale
      expect(t.offset,
          Offset(400 - 100 * kMaxZoom, 300 - 100 * kMaxZoom));
    });

    test('spread points: scale fits bounding box with padding', () {
      final t = fitPointsTransform(
        [const Offset(0, 0), const Offset(1000, 500)],
        viewport,
        padding: 40.0,
      )!;
      // imageW=1000, imageH=500; scaleX=(800-80)/1000=0.72, scaleY=(600-80)/500=1.04
      // -> scale=min=0.72
      expect(t.scale, closeTo(0.72, 1e-6));
    });

    test('clamps scale to kMaxZoom when points are tiny', () {
      final t = fitPointsTransform(
        [const Offset(0, 0), const Offset(0.001, 0.001)],
        viewport,
      )!;
      expect(t.scale, kMaxZoom);
    });
  });
}
