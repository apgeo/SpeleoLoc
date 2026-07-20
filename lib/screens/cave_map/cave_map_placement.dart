import 'package:speleoloc/data/source/database/app_database.dart';

/// What confirming a placed point does. The surface map treats "pick a
/// coordinate" as one interaction and branches on the outcome, so the
/// external pick flow and the in-map create/move flows share one code path.
enum PlacementKind {
  /// Return the coordinates to the caller (the cave-place form picker).
  returnToCaller,

  /// Create a new cave together with its (main) entrance at the point.
  newCave,

  /// Create a new entrance cave place (a cave is chosen on confirm).
  newEntrance,

  /// Set/replace the coordinates of an existing cave place.
  moveExistingPlace,
}

/// An in-progress point placement: the outcome kind plus the auxiliary data
/// that outcome needs. One instance is active at a time on the map.
class CaveMapPlacement {
  final PlacementKind kind;

  /// For [PlacementKind.moveExistingPlace]: the place being repositioned.
  final CavePlace? existingPlace;

  /// Label shown in the placement bar (e.g. the cave place / cave title).
  final String? subjectLabel;

  const CaveMapPlacement({
    required this.kind,
    this.existingPlace,
    this.subjectLabel,
  });
}
