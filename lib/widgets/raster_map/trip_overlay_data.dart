import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// Trip overlay data for displaying trip route on a raster map.
///
/// Contains the ordered sequence of cave place IDs visited during a trip.
/// The editor uses this together with [CavePlaceWithDefinition] data to
/// draw lines between consecutive points, direction arrows, and incremental
/// numbering.
class TripOverlayData {
  /// Ordered list of cave place IDs in the order they were visited.
  /// A place may appear more than once if revisited during the trip.
  final List<Uuid> orderedCavePlaceIds;

  /// Line/arrow color for the trip route.
  final Color routeColor;

  /// Line width for the trip route.
  final double routeLineWidth;

  /// Size of the incremental number labels.
  final double numberFontSize;

  const TripOverlayData({
    required this.orderedCavePlaceIds,
    this.routeColor = Colors.blue,
    this.routeLineWidth = 2.5,
    this.numberFontSize = 12.0,
  });
}
