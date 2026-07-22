import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_map/cave_map_label_layer.dart';
import 'package:speleoloc/screens/cave_map/cave_map_markers.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_item.dart';
import 'package:speleoloc/screens/cave_map/map_marker_clustering.dart';
import 'package:speleoloc/widgets/map/cave_map_marker_icons.dart';

/// The place markers plus their labels, clustered at low zoom.
///
/// Owns both layers so they stay coherent: below [clusterBelowZoom] the
/// markers collapse into count bubbles and only the remaining singles keep
/// labels; from that zoom on it renders exactly the classic marker + label
/// pair. Rebuilds on every camera change via [MapCamera.of].
class CaveMapClusteredPlaces extends StatelessWidget {
  const CaveMapClusteredPlaces({
    super.key,
    required this.paintOrder,
    required this.visibleItems,
    required this.highlightFocus,
    required this.selectedUuid,
    required this.onTap,
    required this.onClusterTap,
    this.pendingPoint,
    this.onPendingDragged,
  });

  /// Camera zoom below which markers cluster.
  static const double clusterBelowZoom = 14;

  final List<CaveMapPlaceItem> paintOrder;
  final List<CaveMapPlaceItem> visibleItems;
  final bool highlightFocus;
  final Uuid? selectedUuid;
  final void Function(CaveMapPlaceItem) onTap;

  /// Tapped a count bubble; the page zooms the camera onto the members.
  final void Function(List<CaveMapPlaceItem>) onClusterTap;

  final LatLng? pendingPoint;
  final ValueChanged<LatLng>? onPendingDragged;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    if (camera.zoom >= clusterBelowZoom) {
      return _layers(
        CaveMapMarkers.build(
          paintOrder: paintOrder,
          highlightFocus: highlightFocus,
          selectedUuid: selectedUuid,
          onTap: onTap,
          pendingPoint: pendingPoint,
          onPendingDragged: onPendingDragged,
        ),
        labelItems: visibleItems,
      );
    }

    // Cluster in screen space. Off-screen points (with a margin, so edge
    // clusters keep their counts while panning) are dropped — the marker
    // layer would cull them anyway.
    final screen = camera.nonRotatedSize;
    final points = <ClusterPoint<CaveMapPlaceItem>>[];
    for (final item in paintOrder) {
      final offset = camera.latLngToScreenOffset(item.point);
      if (offset.dx < -100 ||
          offset.dy < -100 ||
          offset.dx > screen.width + 100 ||
          offset.dy > screen.height + 100) {
        continue;
      }
      points.add(ClusterPoint(item, offset));
    }

    final markers = <Marker>[];
    final singles = <CaveMapPlaceItem>[];
    for (final group in clusterByGrid(points)) {
      if (group.length == 1) {
        final item = group.single.item;
        singles.add(item);
        markers.add(
          CaveMapMarkers.placeMarker(
            item,
            highlightFocus: highlightFocus,
            selectedUuid: selectedUuid,
            onTap: onTap,
          ),
        );
      } else {
        markers.add(_clusterMarker([for (final p in group) p.item]));
      }
    }
    if (pendingPoint != null) {
      markers.add(
        CaveMapMarkers.pendingPinMarker(
          pendingPoint!,
          onDragged: onPendingDragged,
        ),
      );
    }
    return _layers(markers, labelItems: singles);
  }

  Widget _layers(List<Marker> markers, {
    required List<CaveMapPlaceItem> labelItems,
  }) => Stack(
    children: [
      MarkerLayer(markers: markers),
      CaveMapLabelLayer(items: labelItems, selectedUuid: selectedUuid),
    ],
  );

  Marker _clusterMarker(List<CaveMapPlaceItem> members) {
    var latitudeSum = 0.0, longitudeSum = 0.0;
    var anyFocus = false;
    for (final member in members) {
      latitudeSum += member.point.latitude;
      longitudeSum += member.point.longitude;
      anyFocus = anyFocus || member.isFocus;
    }
    final center = LatLng(
      latitudeSum / members.length,
      longitudeSum / members.length,
    );
    final size = members.length < 10
        ? 32.0
        : members.length < 100
        ? 38.0
        : 44.0;
    return Marker(
      point: center,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onClusterTap(members),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: anyFocus
                ? CaveMapMarkerStyle.placeDot
                : CaveMapMarkerStyle.placeDotNonFocus,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4),
            ],
          ),
          child: Center(
            child: Text(
              '${members.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
