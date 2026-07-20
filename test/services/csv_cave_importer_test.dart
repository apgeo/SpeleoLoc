import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/csv_cave_importer.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

void main() {
  late AppDatabase db;
  late CSVCaveImporter importer;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final users = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      users,
      ConfigurationRepository(db),
    );
    loggerRef = ChangeLogger(db, currentUser);
    importer = CSVCaveImporter(
      db,
      currentUser,
      CavePlaceRepository(db, currentUser, loggerRef),
      clock: FakeClock(DateTime.utc(2026, 7, 20)),
    );
  });

  tearDown(() => db.close());

  final config = CSVCavesImportConfig(
    caveNameColumn: 0,
    descriptionColumn: 1,
    caveLocalIndexColumn: 2,
    surfaceAreaColumn: 3,
    generalAreaIdentifierColumn: 4,
  );

  List<List<dynamic>> csv(List<List<dynamic>> dataRows) => [
    ['name', 'description', 'local index', 'area', 'area identifier'],
    ...dataRows,
  ];

  Future<Uuid> insertArea(String title, {String? identifier}) async {
    final uuid = Uuid.v7();
    await db
        .into(db.surfaceAreas)
        .insert(
          SurfaceAreasCompanion.insert(
            uuid: uuid,
            title: title,
            generalAreaIdentifier: Value(identifier),
          ),
        );
    return uuid;
  }

  Future<Uuid> insertCave(
    String title, {
    String? localIndex,
    Uuid? areaUuid,
    String? description,
  }) async {
    final uuid = Uuid.v7();
    await db
        .into(db.caves)
        .insert(
          CavesCompanion.insert(
            uuid: uuid,
            title: title,
            description: Value(description),
            caveLocalIndex: Value(localIndex),
            surfaceAreaUuid: Value(areaUuid),
          ),
        );
    return uuid;
  }

  Future<void> insertEntrance(Uuid caveUuid, {String title = 'Existing'}) async {
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlacesCompanion.insert(
            uuid: Uuid.v7(),
            title: title,
            caveUuid: caveUuid,
            isEntrance: const Value(1),
          ),
        );
  }

  group('parseRows', () {
    test('extracts cave local index and general area identifier', () {
      final rows = importer.parseRows(
        csv([
          ['Cave A', 'desc', '007', 'Padis', '005'],
          ['', 'row without cave name is skipped', 'x', 'y', 'z'],
        ]),
        config,
      );

      expect(rows, hasLength(1));
      expect(rows.single.caveLocalIndex, '007');
      expect(rows.single.generalAreaIdentifier, '005');
    });

    test('empty cells map to null', () {
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', '', ''],
        ]),
        config,
      );

      expect(rows.single.description, isNull);
      expect(rows.single.caveLocalIndex, isNull);
      expect(rows.single.surfaceArea, isNull);
      expect(rows.single.generalAreaIdentifier, isNull);
    });
  });

  group('importRows surface area resolution', () {
    test('identifier match wins over a differing title', () async {
      final padis = await insertArea('Padis', identifier: '005');

      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', 'Some Other Name', '005'],
        ]),
        config,
      );
      final result = await importer.importRows(rows, config);

      expect(result.cavesCreated, 1);
      expect(result.surfaceAreasCreated, 0);
      final cave = await db.select(db.caves).getSingle();
      expect(cave.surfaceAreaUuid, padis);
      final areas = await db.select(db.surfaceAreas).get();
      expect(areas, hasLength(1));
      expect(areas.single.title, 'Padis');
    });

    test('title match backfills a missing identifier', () async {
      final padis = await insertArea('Padis');

      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', 'Padis', '005'],
        ]),
        config,
      );
      final result = await importer.importRows(rows, config);

      expect(result.surfaceAreasCreated, 0);
      final cave = await db.select(db.caves).getSingle();
      expect(cave.surfaceAreaUuid, padis);
      final area = await db.select(db.surfaceAreas).getSingle();
      expect(area.generalAreaIdentifier, '005');
    });

    test('title match never overwrites a differing identifier', () async {
      final padis = await insertArea('Padis', identifier: '007');

      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', 'Padis', '005'],
        ]),
        config,
      );
      final result = await importer.importRows(rows, config);

      expect(result.surfaceAreasCreated, 0);
      final cave = await db.select(db.caves).getSingle();
      expect(cave.surfaceAreaUuid, padis);
      final area = await db.select(db.surfaceAreas).getSingle();
      expect(area.generalAreaIdentifier, '007');
    });

    test('unmatched identifier creates an area titled by the identifier', () async {
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', '', '005'],
        ]),
        config,
      );
      final result = await importer.importRows(rows, config);

      expect(result.surfaceAreasCreated, 1);
      final area = await db.select(db.surfaceAreas).getSingle();
      expect(area.title, '005');
      expect(area.generalAreaIdentifier, '005');
      final cave = await db.select(db.caves).getSingle();
      expect(cave.surfaceAreaUuid, area.uuid);
    });

    test('unmatched identifier with title creates an area with both', () async {
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', 'Padis', '005'],
        ]),
        config,
      );
      final result = await importer.importRows(rows, config);

      expect(result.surfaceAreasCreated, 1);
      final area = await db.select(db.surfaceAreas).getSingle();
      expect(area.title, 'Padis');
      expect(area.generalAreaIdentifier, '005');
    });

    test('rows sharing a new identifier reuse the created area', () async {
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', 'Padis', '005'],
          ['Cave B', '', '', '', '005'],
        ]),
        config,
      );
      final result = await importer.importRows(rows, config);

      expect(result.cavesCreated, 2);
      expect(result.surfaceAreasCreated, 1);
      final area = await db.select(db.surfaceAreas).getSingle();
      final caves = await db.select(db.caves).get();
      expect(caves.map((c) => c.surfaceAreaUuid), everyElement(area.uuid));
    });

    test('re-importing the same data is idempotent', () async {
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', '', '005'],
        ]),
        config,
      );
      await importer.importRows(rows, config);
      final second = await importer.importRows(rows, config);

      expect(second.cavesCreated, 0);
      expect(second.surfaceAreasCreated, 0);
      expect(second.skippedDuplicates, 1);
      expect(await db.select(db.surfaceAreas).get(), hasLength(1));
      expect(await db.select(db.caves).get(), hasLength(1));
    });
  });

  group('importRows cave local index', () {
    test('stored on newly created caves', () async {
      final rows = importer.parseRows(
        csv([
          ['Cave A', 'desc', '012', '', ''],
        ]),
        config,
      );
      await importer.importRows(rows, config);

      final cave = await db.select(db.caves).getSingle();
      expect(cave.caveLocalIndex, '012');
    });

    test('updated on duplicate caves when the user approves', () async {
      await insertCave('Cave A', localIndex: '012');
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '013', '', ''],
        ]),
        config,
      );

      final candidates = await importer.planCaveUpdates(rows, config);
      expect(candidates, hasLength(1));
      expect(
        candidates.single.changes.single.field,
        CSVCaveField.caveLocalIndex,
      );

      final result = await importer.importRows(
        rows,
        config,
        updateCandidates: candidates,
        approvedUpdates: {candidates.single.rowIndex},
      );

      expect(result.cavesUpdated, 1);
      expect(result.cavesCreated, 0);
      final cave = await db.select(db.caves).getSingle();
      expect(cave.caveLocalIndex, '013');
    });

    test('kept when the update is declined', () async {
      await insertCave('Cave A', localIndex: '012');
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '013', '', ''],
        ]),
        config,
      );

      final candidates = await importer.planCaveUpdates(rows, config);
      final result = await importer.importRows(
        rows,
        config,
        updateCandidates: candidates,
      );

      expect(result.cavesUpdated, 0);
      expect(result.skippedDuplicates, 1);
      final cave = await db.select(db.caves).getSingle();
      expect(cave.caveLocalIndex, '012');
    });

    test('kept on approved update when the column is empty', () async {
      await insertCave('Cave A', localIndex: '012');
      final rows = importer.parseRows(
        csv([
          ['Cave A', 'new description', '', '', ''],
        ]),
        config,
      );

      final candidates = await importer.planCaveUpdates(rows, config);
      expect(candidates.single.changes.single.field, CSVCaveField.description);

      await importer.importRows(
        rows,
        config,
        updateCandidates: candidates,
        approvedUpdates: {candidates.single.rowIndex},
      );

      final cave = await db.select(db.caves).getSingle();
      expect(cave.caveLocalIndex, '012');
      expect(cave.description, 'new description');
    });
  });

  group('planCaveUpdates', () {
    test('no candidates when the CSV matches the stored values', () async {
      final rows = importer.parseRows(
        csv([
          ['Cave A', 'desc', '012', 'Padis', '005'],
        ]),
        config,
      );
      await importer.importRows(rows, config);

      expect(await importer.planCaveUpdates(rows, config), isEmpty);
    });

    test('same title and local index in another area proposes a move', () async {
      await insertArea('Padis', identifier: '005');
      await insertCave('Cave A', localIndex: '042', description: 'old');
      final rows = importer.parseRows(
        csv([
          ['Cave A', 'new', '042', '', '005'],
        ]),
        config,
      );

      final candidates = await importer.planCaveUpdates(rows, config);

      expect(candidates, hasLength(1));
      final fields = candidates.single.changes.map((c) => c.field).toSet();
      expect(fields, {CSVCaveField.description, CSVCaveField.surfaceArea});
      final areaChange = candidates.single.changes.firstWhere(
        (c) => c.field == CSVCaveField.surfaceArea,
      );
      expect(areaChange.oldValue, isNull);
      expect(areaChange.newValue, 'Padis');
    });

    test('area move is suppressed when the slot is occupied', () async {
      final padis = await insertArea('Padis', identifier: '005');
      await insertCave('Cave A', localIndex: '042');
      await insertCave('Cave A', localIndex: '099', areaUuid: padis);
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '042', '', '005'],
        ]),
        config,
      );

      expect(await importer.planCaveUpdates(rows, config), isEmpty);
    });
  });

  group('importRows approved updates', () {
    test('moves the cave into the area matched by identifier', () async {
      final padis = await insertArea('Padis', identifier: '005');
      await insertCave('Cave A', localIndex: '042', description: 'old');
      final rows = importer.parseRows(
        csv([
          ['Cave A', 'new', '042', '', '005'],
        ]),
        config,
      );

      final candidates = await importer.planCaveUpdates(rows, config);
      final result = await importer.importRows(
        rows,
        config,
        updateCandidates: candidates,
        approvedUpdates: {candidates.single.rowIndex},
      );

      expect(result.cavesUpdated, 1);
      expect(result.cavesCreated, 0);
      final cave = await db.select(db.caves).getSingle();
      expect(cave.surfaceAreaUuid, padis);
      expect(cave.description, 'new');
    });

    test('creates the target surface area when it does not exist', () async {
      await insertCave('Cave A', localIndex: '042');
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '042', 'Padis', ''],
        ]),
        config,
      );

      final candidates = await importer.planCaveUpdates(rows, config);
      expect(candidates.single.changes.single.field, CSVCaveField.surfaceArea);

      final result = await importer.importRows(
        rows,
        config,
        updateCandidates: candidates,
        approvedUpdates: {candidates.single.rowIndex},
      );

      expect(result.surfaceAreasCreated, 1);
      final area = await db.select(db.surfaceAreas).getSingle();
      expect(area.title, 'Padis');
      final cave = await db.select(db.caves).getSingle();
      expect(cave.surfaceAreaUuid, area.uuid);
    });

    test('declined move leaves no duplicate cave behind', () async {
      await insertArea('Padis', identifier: '005');
      await insertCave('Cave A', localIndex: '042');
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '042', '', '005'],
        ]),
        config,
      );

      final candidates = await importer.planCaveUpdates(rows, config);
      final result = await importer.importRows(
        rows,
        config,
        updateCandidates: candidates,
      );

      expect(result.cavesCreated, 0);
      expect(result.skippedDuplicates, 1);
      expect(await db.select(db.caves).get(), hasLength(1));
    });
  });

  group('importRows entrance place', () {
    final entranceConfig = CSVCavesImportConfig(
      caveNameColumn: 0,
      descriptionColumn: 1,
      caveLocalIndexColumn: 2,
      surfaceAreaColumn: 3,
      generalAreaIdentifierColumn: 4,
      entrancePlaceTitle: 'Entrance',
    );

    test('each new cave gets a main entrance place', () async {
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', '', ''],
          ['Cave B', '', '', 'Padis', ''],
        ]),
        entranceConfig,
      );
      await importer.importRows(rows, entranceConfig);

      final caves = await db.select(db.caves).get();
      final places = await db.select(db.cavePlaces).get();
      expect(places, hasLength(2));
      expect(
        places.map((p) => p.caveUuid).toSet(),
        caves.map((c) => c.uuid).toSet(),
      );
      for (final place in places) {
        expect(place.title, 'Entrance');
        expect(place.isEntrance, 1);
        expect(place.isMainEntrance, 1);
      }
    });

    test('skipped duplicates get no additional entrance', () async {
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', '', ''],
        ]),
        entranceConfig,
      );
      await importer.importRows(rows, entranceConfig);
      final second = await importer.importRows(rows, entranceConfig);

      expect(second.skippedDuplicates, 1);
      expect(await db.select(db.cavePlaces).get(), hasLength(1));
    });

    test('an approved update backfills a missing entrance', () async {
      await insertCave('Cave A', localIndex: '042');
      final rows = importer.parseRows(
        csv([
          ['Cave A', 'new', '042', '', ''],
        ]),
        entranceConfig,
      );
      final candidates = await importer.planCaveUpdates(rows, entranceConfig);
      final result = await importer.importRows(
        rows,
        entranceConfig,
        updateCandidates: candidates,
        approvedUpdates: {candidates.single.rowIndex},
      );

      expect(result.cavesUpdated, 1);
      final places = await db.select(db.cavePlaces).get();
      expect(places, hasLength(1));
      expect(places.single.title, 'Entrance');
      expect(places.single.isMainEntrance, 1);
    });

    test('an exact duplicate backfills a missing entrance', () async {
      await insertCave('Cave A', localIndex: '042');
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '042', '', ''],
        ]),
        entranceConfig,
      );
      final result = await importer.importRows(rows, entranceConfig);

      expect(result.cavesUpdated, 0);
      expect(result.skippedDuplicates, 1);
      final places = await db.select(db.cavePlaces).get();
      expect(places, hasLength(1));
      expect(places.single.title, 'Entrance');
    });

    test('a declined update still backfills a missing entrance', () async {
      await insertCave('Cave A', localIndex: '042');
      final rows = importer.parseRows(
        csv([
          ['Cave A', 'new', '042', '', ''],
        ]),
        entranceConfig,
      );
      final candidates = await importer.planCaveUpdates(rows, entranceConfig);
      final result = await importer.importRows(
        rows,
        entranceConfig,
        updateCandidates: candidates,
      );

      expect(result.cavesUpdated, 0);
      expect(result.skippedDuplicates, 1);
      final places = await db.select(db.cavePlaces).get();
      expect(places, hasLength(1));
      expect(places.single.title, 'Entrance');
    });

    test('a matched cave keeps its single existing entrance', () async {
      final caveA = await insertCave('Cave A', localIndex: '042');
      await insertEntrance(caveA);
      final rows = importer.parseRows(
        csv([
          ['Cave A', 'new', '042', '', ''],
        ]),
        entranceConfig,
      );
      final candidates = await importer.planCaveUpdates(rows, entranceConfig);
      await importer.importRows(
        rows,
        entranceConfig,
        updateCandidates: candidates,
        approvedUpdates: {candidates.single.rowIndex},
      );

      expect(await db.select(db.cavePlaces).get(), hasLength(1));
    });

    test('no entrance is created when the title is not configured', () async {
      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', '', ''],
        ]),
        config,
      );
      await importer.importRows(rows, config);

      expect(await db.select(db.cavePlaces).get(), isEmpty);
    });
  });

  group('findExistingCaves', () {
    test('matches duplicates through the identifier', () async {
      final padis = await insertArea('Padis', identifier: '005');
      await db
          .into(db.caves)
          .insert(
            CavesCompanion.insert(
              uuid: Uuid.v7(),
              title: 'Cave A',
              surfaceAreaUuid: Value(padis),
            ),
          );

      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', '', '005'],
        ]),
        config,
      );
      final existing = await importer.findExistingCaves(rows, config);

      expect(existing.totalCount, 1);
      expect(existing.matches.single.surfaceArea, 'Padis');
    });

    test('identifier-only row does not match caves without an area', () async {
      await db
          .into(db.caves)
          .insert(CavesCompanion.insert(uuid: Uuid.v7(), title: 'Cave A'));

      final rows = importer.parseRows(
        csv([
          ['Cave A', '', '', '', '005'],
        ]),
        config,
      );
      final existing = await importer.findExistingCaves(rows, config);

      expect(existing.totalCount, 0);
    });
  });
}
