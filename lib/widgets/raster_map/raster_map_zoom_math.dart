import 'dart:ui';

/// Pure geometry helpers for the raster-map point editor, extracted during
/// Phase 2.3 of the refactoring so they can be unit-tested independently of
/// `PhotoView` and `BuildContext`.
///
/// The editor scales and pans the raster image inside a viewport. All math
/// uses the same convention: `viewport.center - imagePoint * scale`.

/// Minimum allowed zoom level for the PhotoView controller.
const double kMinZoom = 0.01;

/// Maximum allowed zoom level for the PhotoView controller.
const double kMaxZoom = 5.0;

/// Clamp [zoom] into the legal [kMinZoom] - [kMaxZoom] range.
double clampZoom(double zoom) => zoom.clamp(kMinZoom, kMaxZoom);

/// Returns the PhotoView `position` offset that centers the given image-space
/// point in [viewport] at the given [scale].
Offset offsetForPoint(
  double imageX,
  double imageY,
  double scale,
  Size viewport,
) {
  final offsetX = (viewport.width / 2) - (imageX * scale);
  final offsetY = (viewport.height / 2) - (imageY * scale);
  return Offset(offsetX, offsetY);
}

/// Represents the target PhotoView transform for [fitPointsTransform].
class FitPointsTransform {
  const FitPointsTransform({required this.scale, required this.offset});

  final double scale;
  final Offset offset;
}

/// Computes a scale + offset that tightly fits all [imagePoints] into
/// [viewport] with [padding] px of margin on each side.
///
/// Returns `null` when [imagePoints] is empty.
FitPointsTransform? fitPointsTransform(
  List<Offset> imagePoints,
  Size viewport, {
  double padding = 40.0,
}) {
  if (imagePoints.isEmpty) return null;

  double minX = imagePoints.first.dx, maxX = minX;
  double minY = imagePoints.first.dy, maxY = minY;
  for (final p in imagePoints) {
    if (p.dx < minX) minX = p.dx;
    if (p.dx > maxX) maxX = p.dx;
    if (p.dy < minY) minY = p.dy;
    if (p.dy > maxY) maxY = p.dy;
  }

  final imageW = (maxX - minX).clamp(1.0, double.infinity);
  final imageH = (maxY - minY).clamp(1.0, double.infinity);
  final scaleX = (viewport.width - padding * 2) / imageW;
  final scaleY = (viewport.height - padding * 2) / imageH;
  final scale = clampZoom(scaleX < scaleY ? scaleX : scaleY);

  final centerX = (minX + maxX) / 2;
  final centerY = (minY + maxY) / 2;
  final offset = offsetForPoint(centerX, centerY, scale, viewport);
  return FitPointsTransform(scale: scale, offset: offset);
}
