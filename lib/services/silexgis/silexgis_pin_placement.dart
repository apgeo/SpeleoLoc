/// Where a raster map's pins go on the picture this device holds for it, and
/// whether the caver may place or move them there.
///
/// Pins are stored in the pixels of the picture as the installation stores
/// it. A placement carries them into the pixels of the picture held: as they
/// are on that picture itself, or through the flip, turn and scale that drew
/// a server's reduced picture from it.
class SilexgisPinPlacement {
  /// The picture held is the one the pins are measured in.
  const SilexgisPinPlacement.asStored()
    : shown = true,
      editable = true,
      _width = 0,
      _height = 0,
      _mirrored = false,
      _turn = 0,
      _scaleX = 1,
      _scaleY = 1;

  /// Pins cannot be put where they belong on the picture held.
  const SilexgisPinPlacement.hidden()
    : shown = false,
      editable = false,
      _width = 0,
      _height = 0,
      _mirrored = false,
      _turn = 0,
      _scaleX = 1,
      _scaleY = 1;

  /// The picture held was drawn from a [width] × [height] stored one by
  /// flipping it left to right when [mirrored], then turning it [turn]
  /// degrees clockwise, then scaling it by [scaleX] and [scaleY].
  ///
  /// Read-only: a pin placed here would have to be carried back through the
  /// inverse to be sent, and is not.
  const SilexgisPinPlacement.drawn({
    required int width,
    required int height,
    required bool mirrored,
    required int turn,
    required double scaleX,
    required double scaleY,
  }) : shown = true,
       editable = false,
       _width = width,
       _height = height,
       _mirrored = mirrored,
       _turn = turn,
       _scaleX = scaleX,
       _scaleY = scaleY;

  /// Whether pins are drawn on the picture held.
  final bool shown;

  /// Whether pins may be placed, moved or removed on the picture held.
  final bool editable;

  final int _width;
  final int _height;
  final bool _mirrored;
  final int _turn;
  final double _scaleX;
  final double _scaleY;

  /// The pixel of the picture held where the stored pixel ([x], [y]) is.
  ({double x, double y}) place(int x, int y) {
    final w = _width - 1;
    final h = _height - 1;
    final fx = _mirrored ? w - x : x;
    final fy = y;
    final (tx, ty) = switch (_turn) {
      90 => (h - fy, fx),
      180 => (w - fx, h - fy),
      270 => (fy, w - fx),
      _ => (fx, fy),
    };
    return (x: tx * _scaleX, y: ty * _scaleY);
  }
}
