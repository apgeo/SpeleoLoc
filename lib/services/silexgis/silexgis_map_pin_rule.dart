import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_picture_frame.dart';
import 'package:speleoloc/services/silexgis/silexgis_pin_placement.dart';

/// Whether, and where, a raster map's pins can be shown on the picture this
/// device holds for it, and whether they can be placed there.
///
/// A pin is stored in the pixels of the map's picture as the installation
/// stores it. A copy without location data is that whole picture, so its
/// pixels are the stored ones. A picture the server drew at one of its fixed
/// sizes keeps the stored aspect but is drawn upright, so a picture stored on
/// its side comes out turned, and perhaps flipped. When the installation says
/// how, every pin is carried through the same flip, turn and scale. When it
/// does not, the turn cannot be read off the picture — a quarter turn one way
/// looks like one the other way, and a half turn like none — so pins are
/// scaled only when the drawn picture has the stored axes, and hidden when it
/// has them swapped or the stored size is unknown.
///
/// Pins are never placed on a drawn picture: one placed there would have to
/// go back through the inverse to be sent. The pins a map has stay stored
/// whatever is shown.
///
/// This is the one place that decides it.
abstract final class SilexgisMapPinRule {
  /// Whether pins can be placed on a picture held as [picture]; null is the
  /// caver's own picture or the original.
  static bool pinsPlaceable(SilexgisHeldAs? picture) =>
      picture != SilexgisHeldAs.rendition;

  /// Where the pins go on a picture held as [picture], whose own pixel size
  /// is [heldWidth] × [heldHeight] (null while not known), drawn from the
  /// stored picture [frame] describes.
  static SilexgisPinPlacement placement({
    required SilexgisHeldAs? picture,
    required SilexgisPictureFrame frame,
    required int? heldWidth,
    required int? heldHeight,
  }) {
    if (pinsPlaceable(picture)) return const SilexgisPinPlacement.asStored();

    final width = frame.width;
    final height = frame.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return const SilexgisPinPlacement.hidden();
    }
    if (heldWidth == null || heldHeight == null) {
      return const SilexgisPinPlacement.hidden();
    }
    if (heldWidth <= 0 || heldHeight <= 0) {
      return const SilexgisPinPlacement.hidden();
    }

    final turn = frame.turn;
    final mirrored = frame.mirrored;
    final turnKnown = mirrored != null && _turns.contains(turn);
    final quarter = turnKnown && (turn == 90 || turn == 270);
    final turnedWidth = quarter ? height : width;
    final turnedHeight = quarter ? width : height;
    // Unknown, the picture is taken as unturned; a picture whose drawn axes
    // are not the stored ones then cannot be placed on. Known, a picture
    // whose axes disagree is not the one described — an older picture still
    // held while the installation already names its next.
    if (!_sameAspect(heldWidth, heldHeight, turnedWidth, turnedHeight)) {
      return const SilexgisPinPlacement.hidden();
    }
    return SilexgisPinPlacement.drawn(
      width: width,
      height: height,
      mirrored: turnKnown && mirrored,
      turn: turnKnown ? turn! : 0,
      // Each side on its own factor: the drawn picture's shorter side was
      // rounded to whole pixels on its own.
      scaleX: heldWidth / turnedWidth,
      scaleY: heldHeight / turnedHeight,
    );
  }

  static const Set<int> _turns = <int>{0, 90, 180, 270};

  /// Whether a picture of [w] × [h] is one of [frameW] × [frameH] scaled,
  /// allowing the side the scaling did not fit to be off by a pixel either
  /// way. A square matches itself whichever way it was turned.
  static bool _sameAspect(int w, int h, int frameW, int frameH) =>
      (h - w * frameH / frameW).abs() <= 1 ||
      (w - h * frameW / frameH).abs() <= 1;
}
