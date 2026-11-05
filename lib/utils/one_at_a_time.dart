/// Runs one async action at a time: a call that arrives while another action
/// is running is dropped, the way a second tap on a busy button should be.
///
/// [idle] lets a caller that must not be dropped (saving, leaving) wait for
/// the running action instead.
class OneAtATime {
  Future<void>? _running;

  bool get busy => _running != null;

  Future<void> run(Future<void> Function() action) async {
    if (_running != null) return;
    final running = action();
    _running = running;
    try {
      await running;
    } finally {
      _running = null;
    }
  }

  /// Completes once no action is running, including one that started while
  /// this was waiting for an earlier one.
  Future<void> get idle async {
    for (var running = _running; running != null; running = _running) {
      try {
        await running;
      } catch (_) {
        // The caller of [run] receives the failure; a waiter only needs to
        // know that the action is over.
      }
    }
  }
}
