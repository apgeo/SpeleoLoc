import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_item.dart';
import 'package:speleoloc/screens/cave_map/map_label_declutter.dart';

/// Draws the place labels as a flutter_map layer. Rebuilds on every camera
/// change (via [MapCamera.of]) and runs the greedy declutter pass so that
/// on crowded views only the highest-priority labels survive — plain
/// places drop out first, then secondary entrances.
class CaveMapLabelLayer extends StatelessWidget {
  const CaveMapLabelLayer({
    super.key,
    required this.items,
    this.selectedUuid,
  });

  final List<CaveMapPlaceItem> items;

  /// The tapped/selected place; its label always wins the declutter pass.
  final Uuid? selectedUuid;

  static const TextStyle _style = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF17233A),
    // White halo so labels stay legible over imagery basemaps.
    shadows: [
      Shadow(color: Colors.white, blurRadius: 2),
      Shadow(color: Colors.white, blurRadius: 2, offset: Offset(1, 0)),
      Shadow(color: Colors.white, blurRadius: 2, offset: Offset(-1, 0)),
      Shadow(color: Colors.white, blurRadius: 2, offset: Offset(0, 1)),
      Shadow(color: Colors.white, blurRadius: 2, offset: Offset(0, -1)),
    ],
  );

  /// Text-size cache: measuring with a TextPainter every frame for every
  /// label is the hot path of this layer, and label strings are stable.
  static final Map<String, Size> _sizeCache = {};

  static Size _measure(String text) {
    final cached = _sizeCache[text];
    if (cached != null) return cached;
    final painter = TextPainter(
      text: TextSpan(text: text, style: _style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (_sizeCache.length > 4000) _sizeCache.clear();
    return _sizeCache[text] = painter.size;
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final screen = camera.nonRotatedSize;

    final candidates = <LabelCandidate>[];
    final placements = <Uuid, Rect>{};
    for (final item in items) {
      final offset = camera.latLngToScreenOffset(item.point);
      if (offset.dx < -160 ||
          offset.dy < -60 ||
          offset.dx > screen.width + 160 ||
          offset.dy > screen.height + 60) {
        continue;
      }
      final textSize = _measure(item.label);
      // Label sits under the marker, horizontally centered on it.
      final markerHalfHeight = item.isEntrance ? 12.0 : 8.0;
      final rect = Rect.fromLTWH(
        offset.dx - textSize.width / 2,
        offset.dy + markerHalfHeight + 1,
        textSize.width,
        textSize.height,
      );
      final basePriority = item.isMainEntrance
          ? 3
          : item.isEntrance
              ? 2
              : 1;
      final priority = (item.uuid == selectedUuid ? 1 << 20 : 0) +
          (item.isFocus ? 10 : 0) +
          basePriority;
      candidates.add(
        LabelCandidate(id: item.uuid, rect: rect, priority: priority),
      );
      placements[item.uuid] = rect;
    }

    final visible = selectVisibleLabels(candidates);

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (final item in items)
            if (visible.contains(item.uuid))
              Positioned(
                left: placements[item.uuid]!.left,
                top: placements[item.uuid]!.top,
                width: placements[item.uuid]!.width,
                height: placements[item.uuid]!.height,
                child: Text(
                  item.label,
                  style: _style,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
              ),
        ],
      ),
    );
  }
}
