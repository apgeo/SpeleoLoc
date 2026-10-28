import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_map_picture_copies.dart';
import 'package:speleoloc/services/silexgis/silexgis_picture_frame.dart';

/// A map showing a picture the server handed down as a copy is told apart,
/// with what the installation says of the picture as stored; every other map
/// is not such a map.
void main() {
  late AppDatabase db;
  late SilexgisFileCopyRepository copies;
  late SilexgisMapPictureCopies pictures;
  final caveId = Uuid.v7();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    copies = SilexgisFileCopyRepository(db);
    pictures = SilexgisMapPictureCopies(db);
    await db.into(db.caves).insert(Cave(uuid: caveId, title: 'Invented'));
  });
  tearDown(() => db.close());

  /// A map whose picture was fetched for a document as [heldAs], or the
  /// caver's own map when [heldAs] is null.
  Future<Uuid> map({
    SilexgisHeldAs? heldAs,
    bool replaced = false,
    SilexgisPictureFrame frame = const SilexgisPictureFrame(),
  }) async {
    final id = Uuid.v7();
    final document = Uuid.v7();
    await db
        .into(db.rasterMaps)
        .insert(
          RasterMapsCompanion.insert(
            uuid: id,
            title: 'Plan $id',
            mapType: 'plane view',
            fileName: heldAs == null || replaced
                ? 'cave_$caveId/raster_${Uuid.v7()}.png'
                : 'cave_$caveId/raster_$document.jpg',
            caveUuid: caveId,
          ),
        );
    if (heldAs != null) {
      await db
          .into(db.silexgisRasterEntry)
          .insert(
            SilexgisRasterEntryCompanion.insert(
              profileUuid: 'p-1',
              entityUuid: id,
              mapUuid: id,
              received: const Value(true),
              documentId: Value(document),
              pictureWidth: Value(frame.width),
              pictureHeight: Value(frame.height),
              pictureMirrored: Value(frame.mirrored),
              pictureTurn: Value(frame.turn),
            ),
          );
      await copies.register(
        SilexgisFileCopyEntry(
          documentUuid: document,
          heldAs: heldAs,
          origin: SilexgisCopyOrigin.server,
        ),
      );
    }
    return id;
  }

  test('a map on a drawn picture names it, with the stored frame', () async {
    const frame = SilexgisPictureFrame(
      width: 400,
      height: 300,
      mirrored: true,
      turn: 270,
    );
    final picture = await pictures.pictureOf(
      await map(heldAs: SilexgisHeldAs.rendition, frame: frame),
    );
    expect(picture?.heldAs, SilexgisHeldAs.rendition);
    expect(picture?.frame, frame);
  });

  test('an unstated frame reads as unknown', () async {
    final picture = await pictures.pictureOf(
      await map(heldAs: SilexgisHeldAs.rendition),
    );
    expect(picture?.frame, const SilexgisPictureFrame());
  });

  test('a copy without location data is named too', () async {
    final picture = await pictures.pictureOf(
      await map(heldAs: SilexgisHeldAs.locationFree),
    );
    expect(picture?.heldAs, SilexgisHeldAs.locationFree);
  });

  test('every other map is not such a map', () async {
    expect(await pictures.pictureOf(await map()), isNull);
    expect(
      await pictures.pictureOf(await map(heldAs: SilexgisHeldAs.original)),
      isNull,
    );
    // The caver has since given it a picture of their own.
    expect(
      await pictures.pictureOf(
        await map(heldAs: SilexgisHeldAs.rendition, replaced: true),
      ),
      isNull,
    );
  });
}
