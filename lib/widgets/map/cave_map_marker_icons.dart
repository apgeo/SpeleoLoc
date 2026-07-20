import 'package:flutter/material.dart';

/// Cave-entrance waymark: a filled arch over a baseline, the symbol used
/// on hiking/topo maps for cave mouths. Drawn with a white casing so it
/// stays readable on any basemap.
class CaveEntranceMarkerIcon extends StatelessWidget {
  const CaveEntranceMarkerIcon({
    super.key,
    required this.size,
    required this.color,
    this.highlighted = false,
  });

  final double size;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.85),
      painter: _CaveArchPainter(color: color, highlighted: highlighted),
    );
  }
}

class _CaveArchPainter extends CustomPainter {
  const _CaveArchPainter({required this.color, required this.highlighted});

  final Color color;
  final bool highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseY = h * 0.88;
    final center = Offset(w / 2, baseY);
    final outerR = w * 0.42;
    final innerR = w * 0.20;

    final arch = Path()
      ..moveTo(center.dx - outerR, baseY)
      ..arcToPoint(
        Offset(center.dx + outerR, baseY),
        radius: Radius.circular(outerR),
      )
      ..lineTo(center.dx + innerR, baseY)
      ..arcToPoint(
        Offset(center.dx - innerR, baseY),
        radius: Radius.circular(innerR),
        clockwise: false,
      )
      ..close();
    final baseline = Rect.fromLTRB(
      center.dx - outerR - w * 0.06,
      baseY,
      center.dx + outerR + w * 0.06,
      baseY + h * 0.10,
    );

    if (highlighted) {
      final halo = Paint()
        ..color = Colors.orangeAccent.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx, h * 0.5), w * 0.58, halo);
    }

    final casing = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(arch, casing);
    canvas.drawRect(baseline.inflate(w * 0.03), casing);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(arch, fill);
    canvas.drawRect(baseline, fill);
  }

  @override
  bool shouldRepaint(_CaveArchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.highlighted != highlighted;
}

/// Plain-place marker: a small filled dot with a white casing.
class PlacePointMarkerIcon extends StatelessWidget {
  const PlacePointMarkerIcon({
    super.key,
    required this.size,
    required this.color,
    this.highlighted = false,
  });

  final double size;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: size * 0.14),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: Colors.orangeAccent.withValues(alpha: 0.9),
                  blurRadius: size * 0.45,
                  spreadRadius: size * 0.28,
                ),
              ]
            : null,
      ),
    );
  }
}
