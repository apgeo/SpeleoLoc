import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/csv_cave_place_importer.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/place_code/place_code_service.dart';
import 'package:speleoloc/services/user_repository.dart';

void main() {
  late AppDatabase db;
  late CSVCavePlaceImporter importer;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger logger;
    final currentUser = CurrentUserService(
      db,
      UserRepository(db, () => logger),
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    logger = ChangeLogger(db, currentUser);
    importer = CSVCavePlaceImporter(
      db,
      currentUser,
      PlaceCodeService(
        db,
        caveIndexWriter: CaveRepository(db, currentUser, logger),
      ),
      logger,
    );
  });

  tearDown(() => db.close());

  Future<List<(String, Uuid, int)>> logged() async => [
    for (final l in await db.select(db.changeLog).get())
      (l.entityTable, l.entityUuid, l.changeType),
  ];

  final multiCave = CSVCavePlacesImportConfig(
    caveNameColumn: 0,
    cavePlaceNameColumn: 1,
    qrCodeColumn: 2,
    caveAreaColumn: 3,
  );

  test('logs every cave, cave area and place the import creates', () async {
    await importer.importRows([
      CSVCavePlaceImportRow(
        caveName: 'Cave A',
        cavePlaceName: 'Place 1',
        caveArea: 'Upper gallery',
      ),
      CSVCavePlaceImportRow(caveName: 'Cave A', cavePlaceName: 'Place 2'),
    ], multiCave);

    final cave = await db.select(db.caves).getSingle();
    final area = await db.select(db.caveAreas).getSingle();
    final places = await db.select(db.cavePlaces).get();
    expect(places, hasLength(2));
    expect(
      await logged(),
      unorderedEquals([
        ('caves', cave.uuid, ChangeType.insert),
        ('cave_areas', area.uuid, ChangeType.insert),
        for (final p in places) ('cave_places', p.uuid, ChangeType.insert),
      ]),
    );
  });

  test('logs the code and area it writes onto an existing place', () async {
    final cave = Uuid.v7();
    await db
        .into(db.caves)
        .insert(CavesCompanion.insert(uuid: cave, title: 'Cave A'));
    final place = Uuid.v7();
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlacesCompanion.insert(
            uuid: place,
            title: 'Place 1',
            caveUuid: cave,
            placeCodeIdentifier: const Value('OLD-1'),
          ),
        );

    await importer.importRows(
      [
        CSVCavePlaceImportRow(
          caveName: 'Cave A',
          cavePlaceName: 'Place 1',
          qrCode: 'NEW-1',
          caveArea: 'Upper gallery',
        ),
      ],
      multiCave,
      overwriteQr: true,
    );

    final area = await db.select(db.caveAreas).getSingle();
    expect(
      await logged(),
      unorderedEquals([
        ('cave_areas', area.uuid, ChangeType.insert),
        ('cave_places', place, ChangeType.update),
        ('cave_places', place, ChangeType.update),
      ]),
    );
    final fields = await db.select(db.changeLogField).get();
    expect(
      fields.map((f) => f.fieldName),
      containsAll(['place_code_identifier', 'cave_area_uuid']),
    );
  });
}
