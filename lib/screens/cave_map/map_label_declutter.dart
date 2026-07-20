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

  final placed = <Rect>[];
  final visible = <Object>{};
  for (final (_, candidate) in indexed) {
    final rect = candidate.rect.inflate(padding);
    var overlaps = false;
    for (final other in placed) {
      if (rect.overlaps(other)) {
        overlaps = true;
        break;
      }
    }
    if (!overlaps) {
      placed.add(rect);
      visible.add(candidate.id);
    }
  }
  return visible;
}
