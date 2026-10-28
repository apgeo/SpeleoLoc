import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_map_picture_copies.dart';
import 'package:speleoloc/services/silexgis/silexgis_map_pin_rule.dart';

/// Pins are in the original picture's pixels. A map whose picture the device
/// could only fetch drawn at a smaller size shows none until the original's
/// size is known; every other map shows its pins as before.
void main() {
  late AppDatabase db;
  late SilexgisFileCopyRepository copies;
  late SilexgisMapPinRule rule;
  final caveId = Uuid.v7();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    copies = SilexgisFileCopyRepository(db);
    rule = SilexgisMapPinRule(SilexgisMapPictureCopies(db));
    await db.into(db.caves).insert(Cave(uuid: caveId, title: 'Invented'));
  });
  tearDown(() => db.close());

  /// A map whose picture was fetched for a document as [heldAs], or the
  /// caver's own map when [heldAs] is null.
  Future<Uuid> map({SilexgisHeldAs? heldAs, bool replaced = false}) async {
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

  test('the rule itself', () {
    expect(SilexgisMapPinRule.pinsFit(null), isTrue);
    expect(SilexgisMapPinRule.pinsFit(SilexgisHeldAs.own), isTrue);
    expect(SilexgisMapPinRule.pinsFit(SilexgisHeldAs.original), isTrue);
    expect(SilexgisMapPinRule.pinsFit(SilexgisHeldAs.locationFree), isTrue);
    expect(SilexgisMapPinRule.pinsFit(SilexgisHeldAs.rendition), isFalse);
  });

  test('a map on a drawn picture shows no pins', () async {
    expect(
      await rule.pinsFitOn(await map(heldAs: SilexgisHeldAs.rendition)),
      isFalse,
    );
  });

  test('every other map shows them', () async {
    expect(await rule.pinsFitOn(await map()), isTrue);
    expect(
      await rule.pinsFitOn(await map(heldAs: SilexgisHeldAs.original)),
      isTrue,
    );
    expect(
      await rule.pinsFitOn(await map(heldAs: SilexgisHeldAs.locationFree)),
      isTrue,
    );
    // The caver has since given it a picture of their own.
    expect(
      await rule.pinsFitOn(
        await map(heldAs: SilexgisHeldAs.rendition, replaced: true),
      ),
      isTrue,
    );
  });
}
