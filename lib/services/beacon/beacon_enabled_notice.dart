/// What the caver is told right after switching beacon detection on.
enum BeaconEnabledNotice {
  none,

  /// Detection could not start.
  notRunning,

  /// Detection stops when the screen locks, and this platform has no
  /// background mode.
  stopsWhenLocked,

  /// Detection stops when the screen locks unless background mode is
  /// switched on.
  stopsWhenLockedUnlessBackground,
}
