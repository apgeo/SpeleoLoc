import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Builds the "my location" map layers: a translucent accuracy circle (when
/// the fix reports a usable accuracy) topped by a blue location dot.
class CaveMapMyLocation {
  const CaveMapMyLocation._();

  static const Color _blue = Color(0xFF1A73E8);

  static List<Widget> layers(Position position) {
    final point = LatLng(position.latitude, position.longitude);
    final accuracy = position.accuracy;
    return [
      if (!accuracy.isNaN && accuracy > 0)
        CircleLayer(
          circles: [
            CircleMarker(
              point: point,
              radius: accuracy,
              useRadiusInMeter: true,
              color: _blue.withValues(alpha: 0.12),
              borderColor: _blue.withValues(alpha: 0.4),
              borderStrokeWidth: 1,
            ),
          ],
        ),
      MarkerLayer(
        markers: [
          Marker(
            point: point,
            width: 22,
            height: 22,
            child: const _LocationDot(),
          ),
        ],
      ),
    ];
  }
}

class _LocationDot extends StatelessWidget {
  const _LocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CaveMapMyLocation._blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}
