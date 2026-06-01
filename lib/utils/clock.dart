/// Abstraction over wall-clock time. Inject a [Clock] (instead of calling
/// `DateTime.now()` directly) into services that need to be deterministic
/// under unit tests.
abstract class Clock {
  const Clock();

  /// Current wall-clock time.
  DateTime now();

  /// Current wall-clock time as Unix epoch milliseconds. Convenience for
  /// the many `DateTime.now().millisecondsSinceEpoch` call sites in the
  /// repositories.
  int nowMs();
}

/// Default real-time implementation backed by `DateTime.now()`.
class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}

/// Fixed-time test clock. Use [advance] to step time forward.
class FakeClock extends Clock {
  FakeClock(DateTime initial) : _now = initial;

  DateTime _now;

  @override
  DateTime now() => _now;

  @override
  int nowMs() => _now.millisecondsSinceEpoch;

  void advance(Duration d) => _now = _now.add(d);
  void set(DateTime t) => _now = t;
}
