import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/raw_image_data.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';

/// Helper class that builds the overlay widgets (marker dots, labels, pulse
/// animation) for [RasterMapPlacePointEditor].
///
/// All methods are pure functions — they read state via parameters and return
/// widget lists without mutating anything.
class RasterMapMarkerBuilder {
  const RasterMapMarkerBuilder._();

  // Marker sizes (mirrors constants in the editor state)
  static const double currentMarkerSize = 18.0;
  static const double initialCircleSize = 24.0;
  static const double innerDotSize = 8.0;
  static const double redDotSize = 10.0;

  /// Transform image-space coordinates to PhotoView viewport-space coordinates.
  static Offset imageToViewport(
    double imageX,
    double imageY,
    PhotoViewControllerValue cv,
  ) {
    final scale = cv.scale ?? 1.0;
    final offset = cv.position;
    return Offset(imageX * scale + offset.dx, imageY * scale + offset.dy);
  }

  /// Returns a text color based on image pixel luminance at [x],[y].
  /// Falls back to [defaultColor] when sampling is disabled or out of range.
  static Color textColorFromImage(
    int x,
    int y, {
    required bool useImageTextColor,
    required RawImageData? img,
    required Color defaultColor,
  }) {
    if (!useImageTextColor) return defaultColor;
    if (img == null || x < 0 || y < 0 || x >= img.width || y >= img.height) {
      return defaultColor;
    }
    final pixel = img.getPixel(x, y);
    final luminance =
        (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255;
    return luminance > 0.5 ? Colors.black : defaultColor;
  }

  /// Returns the opposite contrast color for [color] (black ↔ white).
  static Color oppositeColor(Color color) {
    final lum = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b);
    return lum > 0.5 ? Colors.black : Colors.white;
  }

  /// Build a label widget with optional text outline and/or background box.
  static Widget buildLabel(
    String text,
    Color textColor, {
    bool outlineEnabled = true,
    double outlineWidth = 2.0,
    bool bgEnabled = false,
  }) {
    Widget labelWidget;
    if (outlineEnabled) {
      final strokeColor = oppositeColor(textColor);
      labelWidget = Stack(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = outlineWidth
                ..color = strokeColor,
            ),
          ),
          Text(text, style: TextStyle(fontSize: 10, color: textColor)),
        ],
      );
    } else {
      labelWidget = Text(
        text,
        style: TextStyle(fontSize: 10, color: textColor),
      );
    }

    if (bgEnabled) {
      labelWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: labelWidget,
      );
    }
    return labelWidget;
  }

  /// Build overlay widgets for existing cave-place definition markers (red dots
  /// + labels), skipping "special" points that get their own distinct markers.
  static List<Widget> buildDefinitionMarkers({
    required List<CavePlaceWithDefinition> definitions,
    required PhotoViewControllerValue controllerValue,
    required Set<String> specialPointKeys,
    required bool useImageTextColor,
    required RawImageData? img,
    required Color defaultLabelColor,
    required bool outlineEnabled,
    required double outlineWidth,
    required bool bgEnabled,
    required Future<void> Function(CavePlaceWithDefinition cpwd) onTap,
    required void Function(String title) onLongPress,
  }) {
    final List<Widget> widgets = [];

    for (final cpwd
        in definitions.where((cpwd) => cpwd.definition != null)) {
      final def = cpwd.definition!;
      final imageX = (def.xCoordinate ?? 0).toDouble();
      final imageY = (def.yCoordinate ?? 0).toDouble();
      final viewportPos =
          imageToViewport(imageX, imageY, controllerValue);
      final textColor = textColorFromImage(
        imageX.toInt(),
        imageY.toInt(),
        useImageTextColor: useImageTextColor,
        img: img,
        defaultColor: defaultLabelColor,
      );

      final key = '${imageX.toInt()},${imageY.toInt()}';
      final isSpecial = specialPointKeys.contains(key);

      if (!isSpecial) {
        widgets.add(
          Positioned(
            left: viewportPos.dx - (redDotSize / 2),
            top: viewportPos.dy - (redDotSize / 2),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => onTap(cpwd),
              onLongPress: () => onLongPress(cpwd.cavePlace.title),
              child: Container(
                width: redDotSize + 8,
                height: redDotSize + 8,
                alignment: Alignment.center,
                child: Container(
                  width: redDotSize,
                  height: redDotSize,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        // Transparent hit-test area for special points
        widgets.add(
          Positioned(
            left: viewportPos.dx - (redDotSize / 2),
            top: viewportPos.dy - (redDotSize / 2),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => onTap(cpwd),
              onLongPress: () => onLongPress(cpwd.cavePlace.title),
              child: SizedBox(
                width: redDotSize + 8,
                height: redDotSize + 8,
              ),
            ),
          ),
        );
      }

      widgets.add(
        Positioned(
          left: viewportPos.dx + 10,
          top: viewportPos.dy - 10,
          child: buildLabel(
            '${cpwd.cavePlace.title} ${cpwd.definition?.cavePlaceId ?? ''}',
            textColor,
            outlineEnabled: outlineEnabled,
            outlineWidth: outlineWidth,
            bgEnabled: bgEnabled,
          ),
        ),
      );
    }

    return widgets;
  }

  /// Build the "new point" marker (blue circle + orange inner dot) and
  /// optionally the "old point" outline if the user moved the point.
  static List<Widget> buildNewPointMarkers({
    required double newX,
    required double newY,
    required double? oldX,
    required double? oldY,
    required PhotoViewControllerValue controllerValue,
    required String Function(String qualifierKey) markerLabel,
    required bool useImageTextColor,
    required RawImageData? img,
    required Color defaultLabelColor,
    required bool outlineEnabled,
    required double outlineWidth,
    required bool bgEnabled,
  }) {
    final List<Widget> widgets = [];

    // Show old-point outline if there was an original saved point that differs
    if (oldX != null &&
        (newX.toInt() != oldX.toInt() || newY.toInt() != oldY!.toInt())) {
      final oldVp = imageToViewport(oldX, oldY!, controllerValue);
      widgets.add(
        Positioned(
          left: oldVp.dx - (initialCircleSize / 2),
          top: oldVp.dy - (initialCircleSize / 2),
          child: Container(
            width: initialCircleSize,
            height: initialCircleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(color: Colors.blue, width: 2),
            ),
          ),
        ),
      );
      widgets.add(
        Positioned(
          left: oldVp.dx + 10,
          top: oldVp.dy - 10,
          child: buildLabel(
            markerLabel('old_point'),
            textColorFromImage(oldX.toInt(), oldY.toInt(),
                useImageTextColor: useImageTextColor,
                img: img,
                defaultColor: defaultLabelColor),
            outlineEnabled: outlineEnabled,
            outlineWidth: outlineWidth,
            bgEnabled: bgEnabled,
          ),
        ),
      );
    }

    final newVp = imageToViewport(newX, newY, controllerValue);

    // Filled blue outer marker
    widgets.add(
      Positioned(
        left: newVp.dx - (currentMarkerSize / 2),
        top: newVp.dy - (currentMarkerSize / 2),
        child: Container(
          width: currentMarkerSize,
          height: currentMarkerSize,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    // Inner orange dot
    widgets.add(
      Positioned(
        left: newVp.dx - (innerDotSize / 2),
        top: newVp.dy - (innerDotSize / 2),
        child: Container(
          width: innerDotSize,
          height: innerDotSize,
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    // Label
    widgets.add(
      Positioned(
        left: newVp.dx + 10,
        top: newVp.dy - 10,
        child: buildLabel(
          markerLabel('new_point'),
          textColorFromImage(newX.toInt(), newY.toInt(),
              useImageTextColor: useImageTextColor,
              img: img,
              defaultColor: defaultLabelColor),
          outlineEnabled: outlineEnabled,
          outlineWidth: outlineWidth,
          bgEnabled: bgEnabled,
        ),
      ),
    );

    return widgets;
  }

  /// Build the controller-selected cave place blue marker (no orange dot).
  static List<Widget> buildControllerPlaceMarker({
    required double imageX,
    required double imageY,
    required PhotoViewControllerValue controllerValue,
    required List<CavePlaceWithDefinition> definitions,
    required bool useImageTextColor,
    required RawImageData? img,
    required Color defaultLabelColor,
    required bool outlineEnabled,
    required double outlineWidth,
    required bool bgEnabled,
    required void Function(String title) onLongPress,
  }) {
    final vp = imageToViewport(imageX, imageY, controllerValue);

    String label = '';
    try {
      final match = definitions
          .where((c) =>
              c.definition != null &&
              c.definition!.xCoordinate == imageX.toInt() &&
              c.definition!.yCoordinate == imageY.toInt())
          .firstOrNull;
      label = match?.cavePlace.title ?? '';
    } catch (_) {}

    return [
      Positioned(
        left: vp.dx - (currentMarkerSize / 2),
        top: vp.dy - (currentMarkerSize / 2),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () {
            if (label.isNotEmpty) onLongPress(label);
          },
          child: Container(
            width: currentMarkerSize + 8,
            height: currentMarkerSize + 8,
            alignment: Alignment.center,
            child: Container(
              width: currentMarkerSize,
              height: currentMarkerSize,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: vp.dx + 10,
        top: vp.dy - 10,
        child: buildLabel(
          label,
          textColorFromImage(imageX.toInt(), imageY.toInt(),
              useImageTextColor: useImageTextColor,
              img: img,
              defaultColor: defaultLabelColor),
          outlineEnabled: outlineEnabled,
          outlineWidth: outlineWidth,
          bgEnabled: bgEnabled,
        ),
      ),
    ];
  }

  /// Build the legacy "old point" outline marker (blue ring + label).
  static List<Widget> buildLegacyOldPointMarker({
    required double imageX,
    required double imageY,
    required PhotoViewControllerValue controllerValue,
    required String Function(String qualifierKey) markerLabel,
    required bool useImageTextColor,
    required RawImageData? img,
    required Color defaultLabelColor,
    required bool outlineEnabled,
    required double outlineWidth,
    required bool bgEnabled,
  }) {
    final vp = imageToViewport(imageX, imageY, controllerValue);
    return [
      Positioned(
        left: vp.dx - (initialCircleSize / 2),
        top: vp.dy - (initialCircleSize / 2),
        child: Container(
          width: initialCircleSize,
          height: initialCircleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: Colors.blue, width: 2),
          ),
        ),
      ),
      Positioned(
        left: vp.dx + 10,
        top: vp.dy - 10,
        child: buildLabel(
          markerLabel('old_point'),
          textColorFromImage(imageX.toInt(), imageY.toInt(),
              useImageTextColor: useImageTextColor,
              img: img,
              defaultColor: defaultLabelColor),
          outlineEnabled: outlineEnabled,
          outlineWidth: outlineWidth,
          bgEnabled: bgEnabled,
        ),
      ),
    ];
  }

  /// Build the pulse animation ring overlay.
  static Widget? buildPulseOverlay({
    required double? pulseImageX,
    required double? pulseImageY,
    required double pulseValue,
    required PhotoViewControllerValue controllerValue,
    required Color primaryColor,
  }) {
    if (pulseImageX == null || pulseImageY == null || pulseValue <= 0) {
      return null;
    }
    final vp = imageToViewport(pulseImageX, pulseImageY, controllerValue);
    final t = pulseValue;
    const base = 22.0;
    final size = base + (28.0 * t);
    return Positioned(
      left: vp.dx - (size / 2),
      top: vp.dy - (size / 2),
      child: IgnorePointer(
        child: Opacity(
          opacity: 1.0 - t,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.95),
                width: 2.0 * (1.0 - t) + 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Compute the set of "special" point keys so the red-dot loop can skip them.
  static Set<String> computeSpecialPointKeys({
    required bool userHasSelectedNewPoint,
    required double? selectedX,
    required double? selectedY,
    required double? initialX,
    required double? initialY,
    required double? controllerX,
    required double? controllerY,
  }) {
    final Set<String> keys = {};
    String ptKey(int x, int y) => '$x,$y';

    if (userHasSelectedNewPoint && selectedX != null && selectedY != null) {
      keys.add(ptKey(selectedX.toInt(), selectedY.toInt()));
      if (initialX != null && initialY != null) {
        keys.add(ptKey(initialX.toInt(), initialY.toInt()));
      }
    } else if (controllerX != null && controllerY != null) {
      keys.add(ptKey(controllerX.toInt(), controllerY.toInt()));
    } else if (initialX != null && initialY != null) {
      keys.add(ptKey(initialX.toInt(), initialY.toInt()));
    }
    return keys;
  }

  /// Build the trip route overlay: lines between consecutive trip points,
  /// directional arrows at the midpoint of each line, and incremental
  /// numbered labels next to each point.
  static List<Widget> buildTripOverlay({
    required TripOverlayData tripOverlay,
    required List<CavePlaceWithDefinition> definitions,
    required PhotoViewControllerValue controllerValue,
  }) {
    final List<Widget> widgets = [];

    // Build a map from cavePlaceId -> image (x, y)
    final Map<int, Offset> coordsById = {};
    for (final cpwd in definitions) {
      final def = cpwd.definition;
      if (def != null && def.xCoordinate != null && def.yCoordinate != null) {
        coordsById[cpwd.cavePlace.id] = Offset(
          def.xCoordinate!.toDouble(),
          def.yCoordinate!.toDouble(),
        );
      }
    }

    // Resolve ordered trip points to viewport coordinates
    final List<Offset?> imagePoints = [];
    for (final placeId in tripOverlay.orderedCavePlaceIds) {
      imagePoints.add(coordsById[placeId]);
    }

    // Draw lines + arrows between consecutive points that both have coords
    for (int i = 0; i < imagePoints.length - 1; i++) {
      final from = imagePoints[i];
      final to = imagePoints[i + 1];
      if (from == null || to == null) continue;

      final vpFrom = imageToViewport(from.dx, from.dy, controllerValue);
      final vpTo = imageToViewport(to.dx, to.dy, controllerValue);

      // Line + arrow via CustomPaint
      widgets.add(
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TripRoutePainter(
                from: vpFrom,
                to: vpTo,
                color: tripOverlay.routeColor,
                strokeWidth: tripOverlay.routeLineWidth,
              ),
            ),
          ),
        ),
      );
    }

    // Detect how many sequential trip markers share the same image point
    // so we can spread them around the point instead of stacking.
    // Group consecutive indices that map to the same image coordinate.
    final Map<int, List<int>> groupedByCoord = {}; // hash -> [indices]
    for (int i = 0; i < imagePoints.length; i++) {
      final pt = imagePoints[i];
      if (pt == null) continue;
      final key = pt.dx.toInt() * 100000 + pt.dy.toInt();
      (groupedByCoord[key] ??= []).add(i);
    }

    // Draw incremental numbers next to each point
    for (int i = 0; i < imagePoints.length; i++) {
      final pt = imagePoints[i];
      if (pt == null) continue;
      final vp = imageToViewport(pt.dx, pt.dy, controllerValue);

      final key = pt.dx.toInt() * 100000 + pt.dy.toInt();
      final group = groupedByCoord[key]!;
      final isStacked = group.length > 1;
      final indexInGroup = group.indexOf(i);

      // When multiple markers share the same point, spread them in a ring
      double offsetX = 0, offsetY = 0;
      double circleSize = 18;
      double fontSize = tripOverlay.numberFontSize * 0.75;
      if (isStacked) {
        circleSize = 22;
        fontSize = tripOverlay.numberFontSize * 0.6;
        final angleStep = 2 * math.pi / group.length;
        final radius = 14.0;
        final angle = -math.pi / 2 + angleStep * indexInGroup;
        offsetX = radius * math.cos(angle);
        offsetY = radius * math.sin(angle);
      }

      widgets.add(
        Positioned(
          left: vp.dx - circleSize / 2 + offsetX,
          top: vp.dy - circleSize / 2 + offsetY,
          child: IgnorePointer(
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: tripOverlay.routeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.0),
              ),
              alignment: Alignment.center,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

/// Custom painter that draws a line and a directional arrow at the midpoint.
class _TripRoutePainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;
  final double strokeWidth;

  _TripRoutePainter({
    required this.from,
    required this.to,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw the line
    canvas.drawLine(from, to, paint);

    // Draw an arrow at 65% of the line length (toward destination)
    final mid = Offset(
      from.dx + (to.dx - from.dx) * 0.65,
      from.dy + (to.dy - from.dy) * 0.65,
    );
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowLength = 10.0;
    const arrowAngle = 0.5; // ~28.6 degrees

    final arrowP1 = Offset(
      mid.dx - arrowLength * math.cos(angle - arrowAngle),
      mid.dy - arrowLength * math.sin(angle - arrowAngle),
    );
    final arrowP2 = Offset(
      mid.dx - arrowLength * math.cos(angle + arrowAngle),
      mid.dy - arrowLength * math.sin(angle + arrowAngle),
    );

    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(mid.dx, mid.dy)
      ..lineTo(arrowP1.dx, arrowP1.dy)
      ..lineTo(arrowP2.dx, arrowP2.dy)
      ..close();
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(_TripRoutePainter oldDelegate) =>
      from != oldDelegate.from ||
      to != oldDelegate.to ||
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth;
}
