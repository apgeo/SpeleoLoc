/// Resolves the surface-map label of a cave place.
///
/// The sole entrance of a single-entrance cave is labelled with the cave
/// title alone (the entrance *is* the cave on a surface map); every other
/// place — entrances of multi-entrance caves and non-entrance places —
/// gets `<cave title> - <place title>`.
String resolvePlaceLabel({
  required String caveTitle,
  required String placeTitle,
  required bool isEntrance,
  required int caveEntranceCount,
}) {
  if (isEntrance && caveEntranceCount == 1) return caveTitle;
  return '$caveTitle - $placeTitle';
}

/// List/subject pairing used by the map's inline lists and the placement
/// bar: `<place title> - <cave title>` (the reverse of the on-map label).
/// Kept beside [resolvePlaceLabel] so the pairing rule and separator live
/// in one place.
String resolveListLabel({
  required String caveTitle,
  required String placeTitle,
}) => '$placeTitle - $caveTitle';
