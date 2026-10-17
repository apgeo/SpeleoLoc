/// What a change to a trip's recorded points does to its written log.
///
/// The log is text a caver may have added to by hand, and rendering it again
/// from the points replaces all of it. So whether an edit rewrites it is the
/// user's setting, and a screen may ask before the setting's choice is
/// carried out.
enum TripLogUpdate {
  /// Render the log again from the points. Replaces whatever was typed into
  /// it by hand.
  regenerate,

  /// Leave the text alone and record that it no longer matches the points,
  /// so the trip and its log page can say so.
  markStale,

  /// Neither, yet: the caller is making several changes in a row and
  /// settles the log once at the end, rather than re-rendering it per change.
  leaveToCaller,
}
