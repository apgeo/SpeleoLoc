import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_map_picture_copies.dart';

/// Whether a raster map's pins can be shown on, and placed on, the picture
/// this device holds for it.
///
/// A pin is stored in the pixels of the map's original picture. A picture the
/// server drew at one of its fixed sizes has fewer pixels, and nothing tells
/// the device how large the original is, so a pin cannot be put where it
/// belongs on it — nor placed on it and sent back as the original's. Until the
/// original's size is known, such a map shows no pins and takes none; the pins
/// it has stay stored. A copy without location data is the whole picture, so
/// its pixels are the original's.
///
/// This is the one place that decides it.
class SilexgisMapPinRule {
  const SilexgisMapPinRule(this._copies);

  final SilexgisMapPictureCopies _copies;

  /// Whether pins fit a picture held as [picture]; null is the caver's own
  /// picture or the original.
  static bool pinsFit(SilexgisHeldAs? picture) =>
      picture != SilexgisHeldAs.rendition;

  Future<bool> pinsFitOn(Uuid mapUuid) async =>
      pinsFit(await _copies.pictureOf(mapUuid));
}
