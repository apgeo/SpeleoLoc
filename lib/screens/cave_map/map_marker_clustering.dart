import 'dart:ui';

/// One input point for the clustering pass: the caller's item plus its
/// screen-space position.
class ClusterPoint<T> {
  const ClusterPoint(this.item, this.offset);

  final T item;
  final Offset offset;
}

/// Screen-space grid clustering: points sharing a grid cell of [cellSize]
/// logical pixels merge into one group. O(n) and allocation-light — the
/// cell quantization (rather than a true radius) is the same trade
/// Leaflet-style cluster plugins make for their grid pass. Group order
/// follows the first member's position in [points].
List<List<ClusterPoint<T>>> clusterByGrid<T>(
  List<ClusterPoint<T>> points, {
  double cellSize = 64,
}) {
  final cells = <(int, int), List<ClusterPoint<T>>>{};
  for (final point in points) {
    final key = (
      (point.offset.dx / cellSize).floor(),
      (point.offset.dy / cellSize).floor(),
    );
    (cells[key] ??= []).add(point);
  }
  return [...cells.values];
}
