/// How a manually chosen trip-point time sits relative to the trip's own
/// start / end boundaries.
enum TripPointTimeIssue {
  /// Earlier than `cave_trips.trip_started_at`.
  beforeTripStart,

  /// Later than `cave_trips.trip_ended_at` (only reachable on ended trips).
  afterTripEnd,
}

/// Classifies [at] against the trip window, returning null when it falls
/// inside it.
///
/// Out-of-window times stay legal: the log renderer already handles points
/// that predate `trip_started_at` (it synthesises an earlier start), and a
/// caver correcting a forgotten stop may legitimately land outside the
/// recorded window. The result therefore only decides whether the user is
/// warned, never whether the write proceeds.
TripPointTimeIssue? checkTripPointTime({
  required DateTime at,
  required DateTime tripStart,
  DateTime? tripEnd,
}) {
  if (at.isBefore(tripStart)) return TripPointTimeIssue.beforeTripStart;
  if (tripEnd != null && at.isAfter(tripEnd)) {
    return TripPointTimeIssue.afterTripEnd;
  }
  return null;
}
