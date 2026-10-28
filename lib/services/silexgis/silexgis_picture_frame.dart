import 'package:speleoloc/services/silexgis/model/sync_rasters.dart';

/// What an installation says of a map's picture as it stores it: the pixel
/// frame its pins are measured in, and how its upright renditions are drawn
/// from it.
///
/// Every member may be unknown. The size is null when the server could not
/// read it; the flip and the turn are null as well whenever a server does not
/// say them, since the rendition's look alone cannot tell a quarter turn one
/// way from the other, nor a half turn from none.
class SilexgisPictureFrame {
  const SilexgisPictureFrame({
    this.width,
    this.height,
    this.mirrored,
    this.turn,
  });

  factory SilexgisPictureFrame.of(SyncRasterMap map) => SilexgisPictureFrame(
    width: map.pictureWidth,
    height: map.pictureHeight,
    mirrored: map.pictureMirrored,
    turn: map.pictureTurn,
  );

  final int? width;
  final int? height;

  /// Whether a rendition is the stored picture flipped left to right before
  /// it is turned.
  final bool? mirrored;

  /// The clockwise turn in degrees, applied after the flip.
  final int? turn;

  @override
  bool operator ==(Object other) =>
      other is SilexgisPictureFrame &&
      other.width == width &&
      other.height == height &&
      other.mirrored == mirrored &&
      other.turn == turn;

  @override
  int get hashCode => Object.hash(width, height, mirrored, turn);
}
