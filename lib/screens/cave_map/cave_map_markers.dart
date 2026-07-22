import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_map/cave_map_pending_pin.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_item.dart';
import 'package:speleoloc/widgets/map/cave_map_marker_icons.dart';

/// Builds the surface map's marker list: one marker per paint-ordered
/// place item plus the red pending-placement pin.
class CaveMapMarkers {
  const CaveMapMarkers._();

  static List<Marker> build({
    required List<CaveMapPlaceItem> paintOrder,
    required bool highlightFocus,
    required Uuid? selectedUuid,
    required void Function(CaveMapPlaceItem) onTap,
    LatLng? pendingPoint,
    ValueChanged<LatLng>? onPendingDragged,
  }) => [
    for (final item in paintOrder)
      placeMarker(
        item,
        highlightFocus: highlightFocus,
        selectedUuid: selectedUuid,
        onTap: onTap,
      ),
    if (pendingPoint != null)
      pendingPinMarker(pendingPoint, onDragged: onPendingDragged),
  ];

  static Marker placeMarker(
    CaveMapPlaceItem item, {
    required bool highlightFocus,
    required Uuid? selectedUuid,
    required void Function(CaveMapPlaceItem) onTap,
  }) => Marker(
    key: ValueKey(item.uuid),
    point: item.point,
    width: item.isEntrance ? 30 : 20,
    height: item.isEntrance ? 26 : 20,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(item),
      child: Center(
        child: _icon(
          item,
          highlighted:
              (highlightFocus && item.isFocus) || item.uuid == selectedUuid,
        ),
      ),
    ),
  );

  static Marker pendingPinMarker(
    LatLng pendingPoint, {
    ValueChanged<LatLng>? onDragged,
  }) => Marker(
    point: pendingPoint,
    width: 40,
    height: 40,
    alignment: Alignment.topCenter,
    child: onDragged != null
        ? CaveMapPendingPin(point: pendingPoint, onDragged: onDragged)
        : const Icon(
            Icons.location_on,
            size: 40,
            color: Color(0xFFD32F2F),
            shadows: [Shadow(color: Colors.white, blurRadius: 4)],
          ),
  );

  static Widget _icon(CaveMapPlaceItem item, {required bool highlighted}) {
    if (item.isEntrance) {
      final color = !item.isFocus
          ? CaveMapMarkerStyle.entranceNonFocus
          : item.isMainEntrance
          ? CaveMapMarkerStyle.mainEntrance
          : CaveMapMarkerStyle.entrance;
      return CaveEntranceMarkerIcon(
        size: item.isMainEntrance
            ? CaveMapMarkerStyle.mainEntranceSize
            : CaveMapMarkerStyle.entranceSize,
        color: color,
        highlighted: highlighted,
      );
    }
    return PlacePointMarkerIcon(
      size: CaveMapMarkerStyle.placeDotSize,
      color: item.isFocus
          ? CaveMapMarkerStyle.placeDot
          : CaveMapMarkerStyle.placeDotNonFocus,
      highlighted: highlighted,
    );
  }
}
