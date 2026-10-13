import 'package:speleoloc/data/source/database/app_database.dart';

/// What a set of entrance-place media markers implies for a trip that
/// already has entrance points and a recorded window.
///
/// A photograph taken at a cave entrance is not an ordinary stop: it is the
/// record of going in or coming out. So when the import produces one, two
/// things that were already recorded may now be wrong — the entrance points
/// the trip carries, and the trip's own start and end times.
class TripMediaEntrancePlan {
  const TripMediaEntrancePlan({
    this.supersededPoints = const [],
    this.proposedTripStart,
    this.proposedTripEnd,
  });

  /// Pre-existing entrance points the new markers stand in for. Offered for
  /// deletion one by one — never removed without the user saying so.
  final List<CaveTripPoint> supersededPoints;

  /// A new `trip_started_at`, when an entrance marker disagrees with the
  /// recorded one. Null when nothing should change.
  final DateTime? proposedTripStart;

  /// A new `trip_ended_at`, on the same terms. Always null for a trip that
  /// has not ended — there is no end to move.
  final DateTime? proposedTripEnd;

  bool get isEmpty =>
      supersededPoints.isEmpty &&
      proposedTripStart == null &&
      proposedTripEnd == null;
}

/// Works out what the entrance markers in a media import change.
///
/// [newEntranceTimes] are the capture times of the selected items assigned
/// to an entrance place; [entrancePlaceUuids] is the set of places in the
/// cave flagged as entrances, which is what makes an existing point an
/// entrance point.
///
/// Two or more markers read as "went in at the first, came out at the last".
/// A single marker is ambiguous, so it moves whichever end of the trip it
/// lies nearer to — the reading that leaves the other end alone rather than
/// collapsing the trip to an instant.
TripMediaEntrancePlan planEntranceReconciliation({
  required DateTime tripStart,
  required DateTime? tripEnd,
  required List<DateTime> newEntranceTimes,
  required List<CaveTripPoint> existingPoints,
  required Set<Uuid> entrancePlaceUuids,
}) {
  if (newEntranceTimes.isEmpty) return const TripMediaEntrancePlan();

  final markers = [...newEntranceTimes]..sort();

  final superseded =
      existingPoints
          .where(
            (p) =>
                p.cavePlaceUuid != null &&
                entrancePlaceUuids.contains(p.cavePlaceUuid),
          )
          .toList()
        ..sort((a, b) => a.scannedAt.compareTo(b.scannedAt));

  DateTime? proposedStart;
  DateTime? proposedEnd;

  if (markers.length == 1) {
    final marker = markers.first;
    if (tripEnd == null) {
      // An unended trip has only a start to disagree with.
      proposedStart = marker;
    } else {
      final toStart = (marker.difference(tripStart)).abs();
      final toEnd = (marker.difference(tripEnd)).abs();
      if (toStart <= toEnd) {
        proposedStart = marker;
      } else {
        proposedEnd = marker;
      }
    }
  } else {
    proposedStart = markers.first;
    if (tripEnd != null) proposedEnd = markers.last;
  }

  // Drop a proposal that matches what is already recorded.
  //
  // No ordering guard is needed on top of this: the pair branch takes its
  // two ends from a sorted list, and a lone marker is always nearer the end
  // it lies outside of, so neither branch can produce a start after an end.
  if (proposedStart != null && proposedStart.isAtSameMomentAs(tripStart)) {
    proposedStart = null;
  }
  if (proposedEnd != null && proposedEnd.isAtSameMomentAs(tripEnd!)) {
    proposedEnd = null;
  }

  return TripMediaEntrancePlan(
    supersededPoints: superseded,
    proposedTripStart: proposedStart,
    proposedTripEnd: proposedEnd,
  );
}
