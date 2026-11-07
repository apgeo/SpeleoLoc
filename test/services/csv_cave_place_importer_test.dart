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

  group('QR codes', () {
    late Uuid caveA;
    late Uuid caveB;

    Future<Uuid> place(Uuid cave, String title, {String? code}) async {
      final uuid = Uuid.v7();
      await db
          .into(db.cavePlaces)
          .insert(
            CavePlacesCompanion.insert(
              uuid: uuid,
              title: title,
              caveUuid: cave,
              placeCodeIdentifier: Value(code),
              qrCodeResourceIdentifier: Value(code),
            ),
          );
      return uuid;
    }

    Future<CavePlace> placeByUuid(Uuid uuid) => (db.select(
      db.cavePlaces,
    )..where((p) => p.uuid.equalsValue(uuid))).getSingle();

    Future<CavePlace> placeTitled(String title) => (db.select(
      db.cavePlaces,
    )..where((p) => p.title.equals(title))).getSingle();

    setUp(() async {
      caveA = Uuid.v7();
      caveB = Uuid.v7();
      await db
          .into(db.caves)
          .insert(CavesCompanion.insert(uuid: caveA, title: 'Test Cave A'));
      await db
          .into(db.caves)
          .insert(CavesCompanion.insert(uuid: caveB, title: 'Test Cave B'));
    });

    CSVCavePlacesImportConfig singleCave(Uuid cave) =>
        CSVCavePlacesImportConfig(
          caveUuid: cave,
          cavePlaceNameColumn: 0,
          qrCodeColumn: 1,
        );

    test('a code shared by two caves is checked within the target cave '
        'only', () async {
      final holderA = await place(caveA, 'Holder A', code: '0001');
      await place(caveB, 'Holder B', code: '0001');

      final conflicts = await importer.findQrCodeConflicts([
        CSVCavePlaceImportRow(cavePlaceName: 'Newcomer', qrCode: '0001'),
      ], singleCave(caveA));

      expect(conflicts.map((c) => c.cavePlaceName), ['Holder A']);
      expect(conflicts.single.caveName, 'Test Cave A');
      expect((await placeByUuid(holderA)).placeCodeIdentifier, '0001');
    });

    test('re-importing a place with the code it already holds is no '
        'conflict', () async {
      await place(caveA, 'Holder A', code: '0001');

      final conflicts = await importer.findQrCodeConflicts([
        CSVCavePlaceImportRow(cavePlaceName: 'Holder A', qrCode: '0001'),
      ], singleCave(caveA));

      expect(conflicts, isEmpty);
    });

    test('a code held in another cave is given to the new place', () async {
      await place(caveB, 'Holder B', code: '0001');

      final result = await importer.importRows([
        CSVCavePlaceImportRow(cavePlaceName: 'Newcomer', qrCode: '0001'),
      ], singleCave(caveA));

      expect((await placeTitled('Newcomer')).placeCodeIdentifier, '0001');
      expect(result.issues, isEmpty);
    });

    test('skip leaves a code held in the cave with its holder and adds the '
        'new place without it', () async {
      final holder = await place(caveA, 'Holder A', code: '0007');

      final result = await importer.importRows(
        [
          CSVCavePlaceImportRow(
            cavePlaceName: 'Newcomer',
            qrCode: '0007',
            lineNumber: 2,
          ),
        ],
        singleCave(caveA),
        overwriteQr: false,
      );

      final newcomer = await placeTitled('Newcomer');
      expect(newcomer.placeCodeIdentifier, isNull);
      expect(newcomer.qrCodeResourceIdentifier, isNull);
      expect((await placeByUuid(holder)).placeCodeIdentifier, '0007');
      expect(result.cavePlacesCreated, 1);
      expect(result.qrCodesCleared, 0);
      final issue = result.issues.single;
      expect(issue.kind, CSVCavePlaceRowIssueKind.qrCodeTaken);
      expect(issue.lineNumber, 2);
      expect(issue.qrCode, '0007');
      expect(issue.holderTitle, 'Holder A');
    });

    test('overwrite moves the code from its holder to the new place', () async {
      final holder = await place(caveA, 'Holder A', code: '0007');

      final result = await importer.importRows(
        [CSVCavePlaceImportRow(cavePlaceName: 'Newcomer', qrCode: '0007')],
        singleCave(caveA),
        overwriteQr: true,
      );

      final newcomer = await placeTitled('Newcomer');
      expect(newcomer.placeCodeIdentifier, '0007');
      expect(newcomer.qrCodeResourceIdentifier, isNotNull);
      final old = await placeByUuid(holder);
      expect(old.placeCodeIdentifier, isNull);
      expect(old.qrCodeResourceIdentifier, isNull);
      expect(result.qrCodesCleared, 1);
      expect(result.issues, isEmpty);
      expect(
        await logged(),
        contains(('cave_places', holder, ChangeType.update)),
      );
    });

    test('skip keeps the code an existing place already holds and reports '
        'the row', () async {
      final existing = await place(caveA, 'Holder A', code: 'OLD-1');
      final rows = [
        CSVCavePlaceImportRow(
          cavePlaceName: 'Holder A',
          qrCode: 'NEW-1',
          lineNumber: 2,
        ),
      ];

      // The question is asked for this place, so declining it must show.
      final conflicts = await importer.findQrCodeConflicts(
        rows,
        singleCave(caveA),
      );
      expect(conflicts.map((c) => c.cavePlaceName), ['Holder A']);

      final result = await importer.importRows(
        rows,
        singleCave(caveA),
        overwriteQr: false,
      );

      expect((await placeByUuid(existing)).placeCodeIdentifier, 'OLD-1');
      expect(result.qrCodesUpdated, 0);
      final issue = result.issues.single;
      expect(issue.kind, CSVCavePlaceRowIssueKind.qrCodeKept);
      expect(issue.lineNumber, 2);
      expect(issue.qrCode, 'NEW-1');
      expect(issue.keptCode, 'OLD-1');
    });

    test('an existing place without a code receives the file code', () async {
      final existing = await place(caveA, 'Holder A');

      final result = await importer.importRows([
        CSVCavePlaceImportRow(cavePlaceName: 'Holder A', qrCode: 'NEW-1'),
      ], singleCave(caveA));

      expect((await placeByUuid(existing)).placeCodeIdentifier, 'NEW-1');
      expect(result.qrCodesUpdated, 1);
    });

    test('a code repeated in the file goes to the first row only', () async {
      final result = await importer.importRows(
        [
          CSVCavePlaceImportRow(
            cavePlaceName: 'First',
            qrCode: '0042',
            lineNumber: 2,
          ),
          CSVCavePlaceImportRow(
            cavePlaceName: 'Second',
            qrCode: '0042',
            lineNumber: 3,
          ),
        ],
        singleCave(caveA),
        overwriteQr: true,
      );

      expect((await placeTitled('First')).placeCodeIdentifier, '0042');
      expect((await placeTitled('Second')).placeCodeIdentifier, isNull);
      final issue = result.issues.single;
      expect(issue.kind, CSVCavePlaceRowIssueKind.qrCodeRepeated);
      expect(issue.lineNumber, 3);
      expect(issue.holderTitle, 'First');
    });
  });

  group('existing place lookup', () {
    late Uuid cave;
    late Uuid areaA;
    late Uuid areaB;

    setUp(() async {
      cave = Uuid.v7();
      areaA = Uuid.v7();
      areaB = Uuid.v7();
      await db
          .into(db.caves)
          .insert(CavesCompanion.insert(uuid: cave, title: 'Test Cave'));
      for (final (uuid, title) in [(areaA, 'Area A'), (areaB, 'Area B')]) {
        await db
            .into(db.caveAreas)
            .insert(
              CaveAreasCompanion.insert(
                uuid: uuid,
                title: title,
                caveUuid: cave,
              ),
            );
      }
    });

    Future<Uuid> place(String title, {Uuid? area}) async {
      final uuid = Uuid.v7();
      await db
          .into(db.cavePlaces)
          .insert(
            CavePlacesCompanion.insert(
              uuid: uuid,
              title: title,
              caveUuid: cave,
              caveAreaUuid: Value(area),
            ),
          );
      return uuid;
    }

    test('a name held in two areas is reported, not thrown', () async {
      await place('Junction', area: areaA);
      await place('Junction', area: areaB);

      final rows = [
        CSVCavePlaceImportRow(
          caveName: 'Test Cave',
          cavePlaceName: 'Junction',
          qrCode: 'J-1',
          lineNumber: 2,
        ),
      ];
      final existing = await importer.findExistingCombinations(rows, multiCave);
      final conflicts = await importer.findQrCodeConflicts(rows, multiCave);
      final result = await importer.importRows(rows, multiCave);

      expect(existing.totalCount, 0);
      expect(conflicts, isEmpty);
      expect(result.cavePlacesCreated, 0);
      expect(result.qrCodesUpdated, 0);
      final issue = result.issues.single;
      expect(issue.kind, CSVCavePlaceRowIssueKind.placeAmbiguous);
      expect(issue.lineNumber, 2);
      final places = await db.select(db.cavePlaces).get();
      expect(places.map((p) => p.placeCodeIdentifier), [null, null]);
    });

    test('the area in the file selects among same-named places', () async {
      final inA = await place('Junction', area: areaA);
      await place('Junction', area: areaB);

      final result = await importer.importRows([
        CSVCavePlaceImportRow(
          caveName: 'Test Cave',
          cavePlaceName: 'Junction',
          qrCode: 'J-1',
          caveArea: 'area a',
        ),
      ], multiCave);

      expect(result.issues, isEmpty);
      final updated = await (db.select(
        db.cavePlaces,
      )..where((p) => p.uuid.equalsValue(inA))).getSingle();
      expect(updated.placeCodeIdentifier, 'J-1');
    });

    test('a place in another area is left alone and a new one is created in '
        'the named area', () async {
      await place('P1', area: areaB);

      final result = await importer.importRows([
        CSVCavePlaceImportRow(
          caveName: 'Test Cave',
          cavePlaceName: 'P1',
          caveArea: 'Area A',
        ),
      ], multiCave);

      expect(result.cavePlacesCreated, 1);
      final places = await db.select(db.cavePlaces).get();
      expect(
        places.map((p) => (p.title, p.caveAreaUuid)),
        unorderedEquals([('P1', areaA), ('P1', areaB)]),
      );
    });

    test('names match ignoring capitalisation, as the preview does', () async {
      final existing = await place('Sala Mare');

      final rows = [
        CSVCavePlaceImportRow(
          caveName: 'Test Cave',
          cavePlaceName: 'sala mare',
          qrCode: 'SM-1',
        ),
      ];
      final preview = await importer.findExistingCombinations(rows, multiCave);
      final result = await importer.importRows(rows, multiCave);

      expect(preview.totalCount, 1);
      expect(result.cavePlacesCreated, 0);
      final places = await db.select(db.cavePlaces).get();
      expect(places.single.uuid, existing);
      expect(places.single.placeCodeIdentifier, 'SM-1');
    });
  });

  test('multi-cave mode reports a cave name shared by two caves instead of '
      'picking one', () async {
    final areaX = Uuid.v7();
    final areaY = Uuid.v7();
    for (final (uuid, title) in [(areaX, 'Area X'), (areaY, 'Area Y')]) {
      await db
          .into(db.surfaceAreas)
          .insert(SurfaceAreasCompanion.insert(uuid: uuid, title: title));
    }
    for (final area in [areaX, areaY]) {
      await db
          .into(db.caves)
          .insert(
            CavesCompanion.insert(
              uuid: Uuid.v7(),
              title: 'Twin Cave',
              surfaceAreaUuid: Value(area),
            ),
          );
    }

    final rows = [
      CSVCavePlaceImportRow(
        caveName: 'twin cave',
        cavePlaceName: 'Place 1',
        caveArea: 'Upper gallery',
        lineNumber: 2,
      ),
    ];
    final preview = await importer.findExistingCombinations(rows, multiCave);
    final result = await importer.importRows(rows, multiCave);

    expect(preview.totalCount, 0);
    expect(result.cavesCreated, 0);
    expect(result.cavePlacesCreated, 0);
    expect(result.caveAreasCreated, 0);
    final issue = result.issues.single;
    expect(issue.kind, CSVCavePlaceRowIssueKind.caveAmbiguous);
    expect(issue.caveName, 'twin cave');
    expect(issue.lineNumber, 2);
    expect(await db.select(db.cavePlaces).get(), isEmpty);
  });

  group('parsing', () {
    final config = CSVCavePlacesImportConfig(
      caveUuid: Uuid.v7(),
      cavePlaceNameColumn: 0,
      qrCodeColumn: 1,
    );

    List<(String?, String?)> parsed(String csv) => [
      for (final r in importer.parseRows(importer.parseCSV(csv), config))
        (r.cavePlaceName, r.qrCode),
    ];

    test('a file with only a header has no rows', () {
      expect(parsed('name,code\n'), isEmpty);
      expect(parsed('name,code'), isEmpty);
      expect(parsed(''), isEmpty);
    });

    test('a row shorter than the header keeps what it has', () {
      expect(parsed('name,code\nShort\nFull,7\n'), [
        ('Short', null),
        ('Full', '7'),
      ]);
    });

    test('blank and whitespace-only names are skipped', () {
      expect(parsed('name,code\n,1\n   ,2\n\t,3\nKept,4\n'), [('Kept', '4')]);
    });

    test('names and codes are trimmed', () {
      expect(parsed('name,code\n  Sala Mare  , PN-01 \n'), [
        ('Sala Mare', 'PN-01'),
      ]);
    });

    test('quoted commas and line breaks stay inside one cell', () {
      expect(parsed('name,code\n"Hall, east",1\n"Two\nlines",2\n'), [
        ('Hall, east', '1'),
        ('Two\nlines', '2'),
      ]);
    });

    test('Windows and old Mac line endings read like Unix ones', () {
      expect(parsed('name,code\r\nA,1\r\nB,2\r\n'), [('A', '1'), ('B', '2')]);
      expect(parsed('name,code\rA,1\rB,2\r'), [('A', '1'), ('B', '2')]);
    });

    test('a semicolon-delimited file is read as columns', () {
      expect(parsed('name;code\nA;1\nB;2\n'), [('A', '1'), ('B', '2')]);
      expect(parsed('name;code\r\n"Hall, east";1,5\r\n'), [
        ('Hall, east', '1,5'),
      ]);
    });

    test('the separator is read from the header outside quotes', () {
      expect(parsed('"name;alias;other",code\nA;B,1\n'), [('A;B', '1')]);
      expect(parsed('"name, alias";code\nA,B;1\n'), [('A,B', '1')]);
      expect(parsed('"name\n;;;",code\nA,1\n'), [('A', '1')]);
    });
  });

  test(
    'Romanian names match whichever form of s and t they are typed in',
    () async {
      final cave = Uuid.v7();
      await db
          .into(db.caves)
          .insert(CavesCompanion.insert(uuid: cave, title: 'Test Cave'));
      final existing = Uuid.v7();
      await db
          .into(db.cavePlaces)
          .insert(
            CavePlacesCompanion.insert(
              uuid: existing,
              title: 'Sala \u0218tefan',
              caveUuid: cave,
            ),
          );

      final result = await importer.importRows([
        CSVCavePlaceImportRow(cavePlaceName: 'Sala \u015Etefan', qrCode: 'S-1'),
      ], CSVCavePlacesImportConfig(caveUuid: cave, cavePlaceNameColumn: 0));

      expect(result.cavePlacesCreated, 0);
      final place = (await db.select(db.cavePlaces).get()).single;
      expect(place.uuid, existing);
      expect(place.title, 'Sala \u0218tefan');
    },
  );

  test('a cave and an area match across the cedilla and comma-below letters, '
      'in either case, and keep their stored spelling', () async {
    final cave = Uuid.v7();
    await db
        .into(db.caves)
        .insert(
          CavesCompanion.insert(uuid: cave, title: 'Pe\u0219tera Mic\u0103'),
        );
    final area = Uuid.v7();
    await db
        .into(db.caveAreas)
        .insert(
          CaveAreasCompanion.insert(
            uuid: area,
            title: 'Galeria \u021Aurcanilor',
            caveUuid: cave,
          ),
        );

    final result = await importer.importRows([
      CSVCavePlaceImportRow(
        caveName: 'PE\u015ETERA MIC\u0102',
        cavePlaceName: 'Punct 1',
        caveArea: 'galeria \u0163urcanilor',
        lineNumber: 2,
      ),
      CSVCavePlaceImportRow(
        caveName: 'Pe\u015Ftera Mic\u0103',
        cavePlaceName: 'Punct 2',
        caveArea: 'Galeria \u0162urcanilor',
        lineNumber: 3,
      ),
    ], multiCave);

    expect(result.cavesCreated, 0);
    expect(result.caveAreasCreated, 0);
    expect(result.cavePlacesCreated, 2);
    expect(
      (await db.select(db.caves).get()).single.title,
      'Pe\u0219tera Mic\u0103',
    );
    expect(
      (await db.select(db.caveAreas).get()).single.title,
      'Galeria \u021Aurcanilor',
    );
    final places = await db.select(db.cavePlaces).get();
    expect(places.map((p) => (p.caveUuid, p.caveAreaUuid)).toSet(), {
      (cave, area),
    });
  });

  test("parsing records each row's line in the file", () {
    final rows = importer.parseRows(
      importer.parseCSV('name,code\nFirst,1\n,2\nThird,3\n'),
      CSVCavePlacesImportConfig(
        caveUuid: Uuid.v7(),
        cavePlaceNameColumn: 0,
        qrCodeColumn: 1,
      ),
    );

    expect(rows.map((r) => (r.cavePlaceName, r.lineNumber)), [
      ('First', 2),
      ('Third', 4),
    ]);
  });
}
