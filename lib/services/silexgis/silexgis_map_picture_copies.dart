import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_picture_frame.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_applier.dart';

/// A map's picture held as a server copy, with what the installation says of
/// the picture as it stores it.
class SilexgisMapPicture {
  const SilexgisMapPicture(this.heldAs, this.frame);

  final SilexgisHeldAs heldAs;
  final SilexgisPictureFrame frame;
}

/// Which raster maps on this device show a picture the server handed down as
/// something other than the file itself — without its location data, or
/// drawn at one of its fixed sizes.
///
/// A map counts while it still holds the picture fetched for its document,
/// under the name the fetch gave it. A map the device made, a map whose
/// picture the caver has since replaced, and a map received as the original
/// are not such maps.
///
/// The register of copies is about the files on this device, not about any
/// one installation, so every installation's maps are looked at.
class SilexgisMapPictureCopies {
  const SilexgisMapPictureCopies(this._db);

  final AppDatabase _db;

  /// Each such map, with what its picture is.
  Future<Map<Uuid, SilexgisHeldAs>> serverOnlyPictures() async =>
      <Uuid, SilexgisHeldAs>{
        for (final MapEntry(:key, :value) in (await _read()).entries)
          key: value.heldAs,
      };

  /// What [mapUuid]'s picture is, when it is such a copy; otherwise null.
  Future<SilexgisMapPicture?> pictureOf(Uuid mapUuid) async =>
      (await _read(mapUuid))[mapUuid];

  Future<Map<Uuid, SilexgisMapPicture>> _read([Uuid? mapUuid]) async {
    final kinds = <String>[
      for (final kind in SilexgisHeldAs.serverOnlyCopies) kind.wireName,
    ];
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT m.uuid AS map, m.cave_uuid AS cave, '
          'm.file_name AS file_name, e.document_id AS document, '
          'c.held_as AS held_as, e.picture_width AS width, '
          'e.picture_height AS height, e.picture_mirrored AS mirrored, '
          'e.picture_turn AS turn '
          'FROM raster_maps m '
          'JOIN silexgis_raster_entry e '
          'ON e.entity_uuid = m.uuid AND e.is_pin = 0 '
          'JOIN silexgis_file_copy c ON c.document_uuid = e.document_id '
          'WHERE c.held_as IN (${List<String>.filled(kinds.length, '?').join(', ')})'
          '${mapUuid == null ? '' : ' AND m.uuid = ?'}',
          variables: <Variable<Object>>[
            for (final kind in kinds) Variable<String>(kind),
            if (mapUuid != null) Variable<Uint8List>(mapUuid.bytes),
          ],
        )
        .get();
    final copies = <Uuid, SilexgisMapPicture>{};
    for (final row in rows) {
      final map = Uuid.fromBytes(row.read<Uint8List>('map'));
      final cave = Uuid.fromBytes(row.read<Uint8List>('cave'));
      final document = Uuid.fromBytes(row.read<Uint8List>('document'));
      final heldAs = SilexgisHeldAs.tryParse(row.read<String>('held_as'));
      if (heldAs == null) continue;
      // The fetched picture's name without its extension, which the fetch
      // took from what the bytes turned out to be.
      final fetched = SilexgisRasterApplier.picturePath(cave, document, '');
      if (!row.read<String>('file_name').startsWith(fetched)) continue;
      copies[map] = SilexgisMapPicture(
        heldAs,
        SilexgisPictureFrame(
          width: row.read<int?>('width'),
          height: row.read<int?>('height'),
          mirrored: row.read<bool?>('mirrored'),
          turn: row.read<int?>('turn'),
        ),
      );
    }
    return copies;
  }
}
