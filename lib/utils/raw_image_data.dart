import 'dart:typed_data';

// Lightweight decoded-image container used for async decoding (isolate -> UI).
class RawImageData {
  final int width;
  final int height;
  final Uint8List pixels; // RGBA order
  RawImageData(this.width, this.height, this.pixels);

  int _index(int x, int y) => (y * width + x) * 4;

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
