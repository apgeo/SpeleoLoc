import 'dart:ui';

/// One label competing for screen space during decluttering.
class LabelCandidate {
  final Object id;

  /// Screen-space rectangle the rendered label would occupy.
  final Rect rect;

  /// Higher wins: main entrances > entrances > plain places, so when the
  /// map gets crowded the non-entrance labels disappear first.
  final int priority;

  const LabelCandidate({
    required this.id,
    required this.rect,
    required this.priority,
  });
}

/// Greedy priority decluttering: candidates claim space in priority order
/// and a label is hidden when its rectangle overlaps one already placed.
/// Ties keep the input order so the visible set is stable across frames.
///
/// Placed rectangles live in a uniform spatial hash, so each candidate is
/// tested only against neighbors in the cells it touches — the pass stays
/// near-linear on maps with thousands of on-screen labels, where checking
/// every placed rect per candidate would be quadratic.
Set<Object> selectVisibleLabels(
  List<LabelCandidate> candidates, {
  double padding = 2,
}) {
  final indexed = List<(int, LabelCandidate)>.generate(
    candidates.length,
    (i) => (i, candidates[i]),
  );
  indexed.sort((a, b) {
    final byPriority = b.$2.priority.compareTo(a.$2.priority);
    return byPriority != 0 ? byPriority : a.$1.compareTo(b.$1);
  });

  // Cell edge on the order of an inflated label's height keeps bucket
  // occupancy low while a typical label only spans a handful of cells.
  const cellSize = 64.0;
  final grid = <(int, int), List<Rect>>{};
  final visible = <Object>{};
  for (final (_, candidate) in indexed) {
    final rect = candidate.rect.inflate(padding);
    final x0 = (rect.left / cellSize).floor();
    final x1 = (rect.right / cellSize).floor();
    final y0 = (rect.top / cellSize).floor();
    final y1 = (rect.bottom / cellSize).floor();

    var overlaps = false;
    outer:
    for (var gx = x0; gx <= x1; gx++) {
      for (var gy = y0; gy <= y1; gy++) {
        final bucket = grid[(gx, gy)];
        if (bucket == null) continue;
        for (final other in bucket) {
          if (rect.overlaps(other)) {
            overlaps = true;
            break outer;
          }
        }
      }
    }
    if (!overlaps) {
      for (var gx = x0; gx <= x1; gx++) {
        for (var gy = y0; gy <= y1; gy++) {
          (grid[(gx, gy)] ??= []).add(rect);
        }
      }
      visible.add(candidate.id);
    }
  }
  return visible;
}
