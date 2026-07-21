import 'package:speleoloc/data/source/database/app_database.dart';

/// Entrance semantics of a [CavePlace] row (the flags are stored as 0/1
/// INTEGER columns). Single source of the "counts as an entrance" rule so
/// map rendering, QR scoping, and sorting cannot drift apart.
extension CavePlaceFlags on CavePlace {
  bool get isAnyEntrance => isEntrance == 1 || isMainEntrance == 1;

  /// Ordering rank: main entrance (2) > entrance (1) > plain place (0).
  int get entranceRank => isMainEntrance == 1 ? 2 : (isEntrance == 1 ? 1 : 0);
}
