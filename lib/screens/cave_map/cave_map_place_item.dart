import 'package:latlong2/latlong.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// A cave place prepared for rendering on the surface map: coordinates
/// resolved to a [LatLng], label precomputed, and focus/entrance flags
/// denormalized so the marker/label layers stay allocation-light.
class CaveMapPlaceItem {
  final CavePlace place;
  final String caveTitle;
  final LatLng point;
  final String label;
  final bool isEntrance;
  final bool isMainEntrance;

  /// True when the place belongs to the set the screen was opened for
  /// (the caves selected on HomePage, or the places filtered/checked on
  /// the cave-places list). Non-focus places are the "other caves" the
  /// toolbar toggle shows and hides.
  final bool isFocus;

  const CaveMapPlaceItem({
    required this.place,
    required this.caveTitle,
    required this.point,
    required this.label,
    required this.isEntrance,
    required this.isMainEntrance,
    required this.isFocus,
  });

  Uuid get uuid => place.uuid;

  /// Label used by the in-screen place lists (`<place> - <cave>` per spec,
  /// the reverse of the on-map label which leads with the cave).
  String get listLabel => '${place.title} - $caveTitle';
}
