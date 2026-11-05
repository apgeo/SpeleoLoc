/// What became of a live scan, beacon detection or new document that would
/// add to the trip recording on this device. Callers tell the caver from
/// this, so a paused trip never answers as if it had recorded.
enum TripRecordOutcome {
  /// Added to the active trip.
  recorded,

  /// A trip is active but paused, so nothing was added.
  paused,

  /// No trip is recording on this device.
  noActiveTrip,

  /// A trip was recording, but writing to it failed.
  failed,
}
