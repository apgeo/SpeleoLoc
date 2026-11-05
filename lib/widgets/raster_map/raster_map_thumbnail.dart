import 'dart:io';

import 'package:flutter/material.dart';

/// A square list tile showing a raster map's picture.
///
/// Map pictures are survey scans of tens of megapixels. Decoded at full size,
/// every tile on screen holds a full-resolution bitmap that the image cache
/// cannot evict while the tile is live, so the picture is decoded at the
/// tile's pixel width on this screen instead.
class RasterMapThumbnail extends StatelessWidget {
  const RasterMapThumbnail({required this.file, this.size = 50, super.key});

  final File file;

  /// Edge length of the tile, in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final decodeWidth = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return Image(
      image: ResizeImage(FileImage(file), width: decodeWidth),
      width: size,
      height: size,
      fit: BoxFit.cover,
      // A missing or unreadable picture fails the decode, so nothing has to
      // stat the file while building.
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.broken_image, size: size * 0.6, color: Colors.grey),
    );
  }
}
