import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/screens/cave_map/map_label_declutter.dart';

void main() {
  LabelCandidate candidate(
    String id,
    double left,
    double top, {
    int priority = 1,
    double width = 50,
    double height = 14,
  }) => LabelCandidate(
    id: id,
    rect: Rect.fromLTWH(left, top, width, height),
    priority: priority,
  );

  group('selectVisibleLabels', () {
    test('non-overlapping labels are all visible', () {
      final visible = selectVisibleLabels([
        candidate('a', 0, 0),
        candidate('b', 100, 0),
        candidate('c', 0, 100),
      ]);
      expect(visible, {'a', 'b', 'c'});
    });

    test('on overlap the higher priority label wins', () {
      final visible = selectVisibleLabels([
        candidate('place', 0, 0, priority: 1),
        candidate('entrance', 10, 5, priority: 2),
        candidate('main', 20, 10, priority: 3),
      ]);
      expect(visible, {'main'});
    });

    test('equal priority keeps the earlier candidate', () {
      final visible = selectVisibleLabels([
        candidate('first', 0, 0),
        candidate('second', 10, 5),
      ]);
      expect(visible, {'first'});
    });

    test('padding hides labels that only almost touch', () {
      // 1px gap between rects; the default 2px inflation makes them collide.
      final visible = selectVisibleLabels([
        candidate('a', 0, 0, width: 50),
        candidate('b', 51, 0, priority: 0),
      ]);
      expect(visible, {'a'});

      final noPadding = selectVisibleLabels(
        [
          candidate('a', 0, 0, width: 50),
          candidate('b', 51, 0, priority: 0),
        ],
        padding: 0,
      );
      expect(noPadding, {'a', 'b'});
    });

    test('a chain of overlaps keeps every other label', () {
      final visible = selectVisibleLabels([
        for (var i = 0; i < 5; i++) candidate('l$i', i * 30.0, 0),
      ], padding: 0);
      // 50px wide labels every 30px: 0 overlaps 1, 1 overlaps 2, ...
      expect(visible, {'l0', 'l2', 'l4'});
    });

    test('overlaps across grid cell boundaries are still detected', () {
      // Rects straddling the 64px spatial-hash cell edges, including
      // negative coordinates (labels partially off-screen).
      final visible = selectVisibleLabels([
        candidate('a', 60, 60),
        candidate('b', 62, 62, priority: 0),
        candidate('c', -10, -10),
        candidate('d', -12, -8, priority: 0),
      ], padding: 0);
      expect(visible, {'a', 'c'});
    });

    test('a dense field stays consistent with pairwise checking', () {
      // 20x20 labels on a 40px grid: 50px wide rects overlap horizontal
      // neighbors only, so every other column survives per row.
      final candidates = [
        for (var row = 0; row < 20; row++)
          for (var col = 0; col < 20; col++)
            candidate('r${row}c$col', col * 40.0, row * 20.0),
      ];
      final visible = selectVisibleLabels(candidates, padding: 0);
      expect(visible, hasLength(200));
      for (var row = 0; row < 20; row++) {
        for (var col = 0; col < 20; col += 2) {
          expect(visible, contains('r${row}c$col'));
        }
      }
    });
  });
}
