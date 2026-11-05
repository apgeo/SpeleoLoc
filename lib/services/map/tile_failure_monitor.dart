/// Tells a map that has lost its connection from one that merely missed a
/// few tiles: it trips when [threshold] failures land within [window].
///
/// A single 404 or a dropped request while online is routine, but an
/// offline map fails every tile of the screen at once.
class TileFailureMonitor {
  TileFailureMonitor({
    this.threshold = 4,
    this.window = const Duration(seconds: 15),
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  final int threshold;
  final Duration window;
  final DateTime Function() _now;
  final List<DateTime> _failures = [];

  /// Records one failed tile; true when the recent failures reach the
  /// threshold.
  bool record() {
    final at = _now();
    _failures
      ..removeWhere((t) => at.difference(t) > window)
      ..add(at);
    return _failures.length >= threshold;
  }

  /// True when no failure was recorded within [window], so the next one
  /// starts a new outage rather than continuing the last.
  bool get quiet {
    final at = _now();
    return _failures.every((t) => at.difference(t) > window);
  }

  void reset() => _failures.clear();
}
