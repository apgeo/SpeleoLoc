import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/qr_code_lookup_service.dart';

/// Guards finding 4.7: a scanned code must resolve regardless of case.
void main() {
  late AppDatabase db;
  late QrCodeLookupService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = QrCodeLookupService(db);
  });

  tearDown(() => db.close());

  Future<Uuid> addCave(String title) async {
    final uuid = Uuid.v7();
    await db
        .into(db.caves)
        .insert(CavesCompanion.insert(uuid: uuid, title: title));
    return uuid;
  }

  Future<void> addPlace(
    Uuid caveUuid, {
    required String title,
    String? pci,
    String? qcri,
  }) async {
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlacesCompanion.insert(
            uuid: Uuid.v7(),
            title: title,
            caveUuid: caveUuid,
            placeCodeIdentifier: Value(pci),
            qrCodeResourceIdentifier: Value(qcri),
          ),
        );
  }

  test('PCI lookup is case-insensitive', () async {
    final cave = await addCave('Cave');
    await addPlace(cave, title: 'P1', pci: 'AbC-123');

    for (final scanned in ['AbC-123', 'abc-123', 'ABC-123']) {
      final hits = await service.lookup(scanned);
      expect(hits, hasLength(1), reason: 'should match "$scanned"');
      expect(hits.single.cavePlace.title, 'P1');
    }
  });

  test('QCRI lookup is case-insensitive', () async {
    final cave = await addCave('Cave');
    await addPlace(cave, title: 'P2', qcri: 'xyz9');

    final hits = await service.lookup('XYZ9');
    expect(hits, hasLength(1));
    expect(hits.single.cavePlace.title, 'P2');
  });

  test('a non-matching code returns nothing', () async {
    final cave = await addCave('Cave');
    await addPlace(cave, title: 'P3', pci: 'AAA');
    expect(await service.lookup('BBB'), isEmpty);
  });

  test('currentCaveId restricts the search', () async {
    final caveA = await addCave('A');
    final caveB = await addCave('B');
    await addPlace(caveA, title: 'InA', pci: 'DUP');
    await addPlace(caveB, title: 'InB', pci: 'DUP');

    final scoped = await service.lookup('dup', currentCaveId: caveA);
    expect(scoped.map((h) => h.cavePlace.title), ['InA']);
  });
}
