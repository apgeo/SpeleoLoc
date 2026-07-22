import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/screens/cave_map/map_marker_clustering.dart';

void main() {
  group('clusterByGrid', () {
    test('points in the same cell merge into one group', () {
      final groups = clusterByGrid([
        const ClusterPoint('a', Offset(10, 10)),
        const ClusterPoint('b', Offset(50, 50)),
        const ClusterPoint('c', Offset(300, 300)),
      ], cellSize: 64);

      expect(groups, hasLength(2));
      final merged = groups.firstWhere((g) => g.length == 2);
      expect({merged[0].item, merged[1].item}, {'a', 'b'});
      expect(groups.firstWhere((g) => g.length == 1).single.item, 'c');
    });

    test('cell boundaries split, including negative offsets', () {
      final groups = clusterByGrid([
        const ClusterPoint('left', Offset(-1, 10)), // cell (-1, 0)
        const ClusterPoint('right', Offset(1, 10)), // cell (0, 0)
      ], cellSize: 64);
      expect(groups, hasLength(2));
    });

    test('group order follows the first member of each group', () {
      final groups = clusterByGrid([
        const ClusterPoint(1, Offset(300, 300)),
        const ClusterPoint(2, Offset(10, 10)),
        const ClusterPoint(3, Offset(310, 310)),
      ], cellSize: 64);
      expect(groups.first.first.item, 1);
      expect(groups.first, hasLength(2));
      expect(groups.last.single.item, 2);
    });

    test('empty input yields no groups', () {
      expect(clusterByGrid<int>(const []), isEmpty);
    });
  });
}
