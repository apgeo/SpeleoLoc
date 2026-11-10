import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/place_code/strategies/global_hierarchical_strategy.dart';

import '../../support/sync_device.dart';

/// A cave's index in its area is part of every place code made in it, so
/// once two phones have synced, each cave has one index on both, and no two
/// caves of an area share one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late SyncTestDevice a;
  late SyncTestDevice b;
  late Uuid area;

  const config = <String, dynamic>{
    GlobalHierarchicalStrategy.kCountryCode: '881',
    GlobalHierarchicalStrategy.kCountryCodeWidth: 3,
    GlobalHierarchicalStrategy.kOrganizationCode: '028',
    GlobalHierarchicalStrategy.kOrganizationCodeWidth: 3,
    GlobalHierarchicalStrategy.kAreaIdentifierWidth: 3,
    GlobalHierarchicalStrategy.kCaveLocalIndexWidth: 3,
    GlobalHierarchicalStrategy.kCavePlaceLocalIndexWidth: 4,
    GlobalHierarchicalStrategy.kAllowNonDigit: false,
    GlobalHierarchicalStrategy.kMainEntranceSuffix: '0001',
    GlobalHierarchicalStrategy.kSegmentSeparator: '',
  };

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cave_index_');
    a = await SyncTestDevice.create();
    b = await SyncTestDevice.create();
    area = await a.caves.addSurfaceArea(
      title: 'Invented Karst',
      generalAreaIdentifier: '204',
    );
    await a.sendTo(b, tmp, 'a0.zip');
    await tick();
  });
  tearDown(() async {
    await a.dispose();
    await b.dispose();
    await tmp.delete(recursive: true);
  });

  /// Adds a cave in the area on [d] and makes the first place code in it,
  /// which gives the cave its index.
  Future<Uuid> indexedCave(SyncTestDevice d, String title) async {
    final cave = await d.caves.addCave(title, surfaceAreaUuid: area);
    await d.places.addCavePlace(cave, 'Entrance');
    await GlobalHierarchicalStrategy(d.db, config, d.caves).generate(
      caveUuid: cave,
      cavePlaceUuid: await d.placeUuid(cave, 'Entrance'),
      isMainEntrance: true,
    );
    return cave;
  }

  Future<String?> indexOf(SyncTestDevice d, Uuid cave) async =>
      (await (d.db.select(
        d.db.caves,
      )..where((c) => c.uuid.equalsValue(cave))).getSingle()).caveLocalIndex;

  test('a cave indexed on one phone has that index on the other', () async {
    final cave = await indexedCave(a, 'Invented Cave A');
    await tick();

    await a.sendTo(b, tmp, 'a1.zip');

    expect(await indexOf(b, cave), await indexOf(a, cave));
    expect(await indexOf(b, cave), isNotNull);
  });

  test(
    'two phones each indexing a new cave of one area end with two indexes',
    () async {
      final caveA = await indexedCave(a, 'Invented Cave A');
      final caveB = await indexedCave(b, 'Invented Cave B');
      await tick();

      await a.sendTo(b, tmp, 'a1.zip');
      await b.sendTo(a, tmp, 'b1.zip');
      await a.sendTo(b, tmp, 'a2.zip');

      for (final cave in [caveA, caveB]) {
        expect(await indexOf(b, cave), await indexOf(a, cave));
      }
      expect(await indexOf(a, caveA), isNot(await indexOf(a, caveB)));
    },
    skip:
        'fix pending: two phones that each index a new cave of one area '
        'before syncing give both caves the same index',
  );
}
