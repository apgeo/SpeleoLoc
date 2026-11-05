import 'dart:async';

/// The longest time the calling isolate's event loop went without running a
/// timer while [work] ran: near the timer period when the work happens
/// elsewhere, the length of the work when it blocks this isolate.
Future<Duration> longestEventLoopStall(Future<void> Function() work) async {
  final clock = Stopwatch()..start();
  var last = Duration.zero;
  var longest = Duration.zero;
  void tick() {
    final now = clock.elapsed;
    if (now - last > longest) longest = now - last;
    last = now;
  }

  final timer = Timer.periodic(const Duration(milliseconds: 5), (_) => tick());
  try {
    await work();
  } finally {
    timer.cancel();
  }
  tick();
  return longest;
}
