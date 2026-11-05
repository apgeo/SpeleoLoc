import 'dart:typed_data';

/// Decoded pixels of a picture, for sampling colours at picture coordinates.
///
/// [pixels] may hold a reduced copy: [width] × [height] is the picture's own
/// frame, which callers sample in, and [gridWidth] × [gridHeight] the copy's
/// grid, which samples are read from.
class RawImageData {
  final int width;
  final int height;
  final Uint8List pixels; // RGBA order
  final int gridWidth;
  final int gridHeight;
  RawImageData(
    this.width,
    this.height,
    this.pixels, {
    int? gridWidth,
    int? gridHeight,
  }) : gridWidth = gridWidth ?? width,
       gridHeight = gridHeight ?? height;

  int _index(int x, int y) {
    final gx = width == gridWidth ? x : x * gridWidth ~/ width;
    final gy = height == gridHeight ? y : y * gridHeight ~/ height;
    return (gy * gridWidth + gx) * 4;
  }

  PixelRgb getPixel(int x, int y) {
    final i = _index(x, y);
    // defensive: if the underlying byte buffer is malformed (wrong stride
    // or truncated), avoid throwing and return a safe default pixel.
    if (i < 0 || i + 3 >= pixels.length) {
      return const PixelRgb(0, 0, 0, 0);
    }
    final r = pixels[i];
    final g = pixels[i + 1];
    final b = pixels[i + 2];
    final a = pixels[i + 3];
    return PixelRgb(r, g, b, a);
  }
}

class PixelRgb {
  final int r;
  final int g;
  final int b;
  final int a;
  const PixelRgb(this.r, this.g, this.b, this.a);
}
