import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// The red pin marking the point being placed. Draggable: panning the
/// pin moves the point under the finger (without panning the map), as a
/// finer-grained alternative to tapping the target location.
class CaveMapPendingPin extends StatelessWidget {
  const CaveMapPendingPin({
    super.key,
    required this.point,
    required this.onDragged,
  });

  final LatLng point;
  final ValueChanged<LatLng> onDragged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        // The parent rebuilds with each reported point, so applying only
        // this update's delta to the current point tracks the finger.
        final camera = MapCamera.of(context);
        final current = camera.latLngToScreenOffset(point);
        onDragged(camera.screenOffsetToLatLng(current + details.delta));
      },
      child: const Icon(
        Icons.location_on,
        size: 40,
        color: Color(0xFFD32F2F),
        shadows: [Shadow(color: Colors.white, blurRadius: 4)],
      ),
    );
  }
}
