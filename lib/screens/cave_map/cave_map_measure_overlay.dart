import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Map layers for the measure tool: the path polyline plus small vertex
/// dots. The dots carry no gesture handlers, so map taps (which add the
/// next point) pass straight through them.
class CaveMapMeasureOverlay {
  const CaveMapMeasureOverlay._();

  static const Color _color = Color(0xFFE65100);

  static List<Widget> layers(List<LatLng> points) => [
    if (points.length >= 2)
      PolylineLayer(
        polylines: [
          Polyline(
            points: points,
            strokeWidth: 3,
            color: _color,
            pattern: const StrokePattern.dotted(),
          ),
        ],
      ),
    if (points.isNotEmpty)
      MarkerLayer(
        markers: [
          for (final point in points)
            Marker(
              point: point,
              width: 12,
              height: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _color,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
  ];
}
