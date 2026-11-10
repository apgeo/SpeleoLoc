import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/definition_repository.dart';
import 'package:speleoloc/services/raster_map_repository.dart';

import '../support/sync_assertions.dart';
import '../support/sync_device.dart';

/// Each kind of unique key a merge can meet: two phones that each made a
/// record under the same key, one with something inside it. The import
/// commits, the local record stays as it was, the incoming one waits for a
/// decision with what hangs on it, nothing is left pointing at a missing
/// record, and the same archive again changes nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late SyncTestDevice a;
  late SyncTestDevice b;
  late Uuid surface;
  late Uuid cave;
  late Uuid area;
  late Uuid place;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('unique_keys_');
    a = await SyncTestDevice.create();
    b = await SyncTestDevice.create();
    surface = await a.caves.addSurfaceArea(title: 'Shared Karst');
    cave = await a.caves.addCave('Shared Cave', surfaceAreaUuid: surface);
    area = await a.caves.addCaveArea(cave, 'Shared Hall');
    await a.places.addCavePlace(cave, 'Shared Junction');
    place = await a.placeUuid(cave, 'Shared Junction');
    await a.sendTo(b, tmp, 'a0.zip');
    await tick();
  });
  tearDown(() async {
    await a.dispose();
    await b.dispose();
    await tmp.delete(recursive: true);
  });

  Future<Uuid> placeInArea(SyncTestDevice d, String title) async {
    final id = Uuid.v7();
    final now = DateTime.now().millisecondsSinceEpoch;
    await d.db
        .into(d.db.cavePlaces)
        .insert(
          CavePlacesCompanion.insert(
            uuid: id,
            title: title,
            caveUuid: cave,
            caveAreaUuid: Value(area),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return id;
  }

  Future<Uuid> map(SyncTestDevice d, String title, String fileName) async {
    await RasterMapRepository(d.db, d.currentUser, d.logger).addRasterMap(
      RasterMapsCompanion.insert(
        uuid: Uuid.v7(),
        title: title,
        mapType: 'plane view',
        fileName: fileName,
        caveUuid: cave,
      ),
    );
    return (await (d.db.select(
      d.db.rasterMaps,
    )..where((m) => m.title.equals(title))).getSingle()).uuid;
  }

  Future<Uuid> trip(SyncTestDevice d) => d.db.insertCaveTrip(
    caveUuid: cave,
    title: 'Invented trip',
    startedAt: DateTime.now().millisecondsSinceEpoch,
    authorUuid: d.author,
  );

  /// Per kind of key: makes the record on [d] and returns it, with the
  /// record made inside it on A (null where none can be).
  final kinds =
      <
        String,
        (
          String,
          Future<Uuid> Function(SyncTestDevice d),
          Future<(String, Uuid)?> Function(SyncTestDevice d, Uuid record),
        )
      >{
        'a surface area\'s title': (
          'surface_areas',
          (d) => d.caves.addSurfaceArea(title: 'Twin Karst'),
          (d, record) async => (
            'caves',
            await d.caves.addCave('Inside Twin Karst', surfaceAreaUuid: record),
          ),
        ),
        'a cave\'s title in its surface area': (
          'caves',
          (d) => d.caves.addCave('Twin Cave', surfaceAreaUuid: surface),
          (d, record) async {
            await d.places.addCavePlace(record, 'Inside Twin Cave');
            return (
              'cave_places',
              await d.placeUuid(record, 'Inside Twin Cave'),
            );
          },
        ),
        'a place\'s title in its area': (
          'cave_places',
          (d) => placeInArea(d, 'Twin Pool'),
          (d, record) async => (
            'cave_trip_points',
            await d.db.insertTripPoint(
              tripUuid: await trip(d),
              cavePlaceUuid: record,
              authorUuid: d.author,
            ),
          ),
        ),
        'a map\'s title': (
          'raster_maps',
          (d) => map(d, 'Twin Plan', 'plan_${d.author}.png'),
          (d, record) async => (
            'cave_place_to_raster_map_definitions',
            (await DefinitionRepository(
              d.db,
              d.currentUser,
              d.logger,
            ).saveDefinition(place, record, 10, 20)).uuid,
          ),
        ),
        'a map\'s file name': (
          'raster_maps',
          (d) => map(d, 'Plan by ${d.author}', 'twin_plan.png'),
          (d, record) async => (
            'cave_place_to_raster_map_definitions',
            (await DefinitionRepository(
              d.db,
              d.currentUser,
              d.logger,
            ).saveDefinition(place, record, 10, 20)).uuid,
          ),
        ),
        'a report template\'s title': (
          'trip_report_templates',
          (d) => d.trips.insertTripReportTemplate(
            title: 'Twin template',
            fileName: 'template_${d.author}.docx',
            fileSize: 1,
            format: 'docx',
          ),
          (_, _) async => null,
        ),
      };

  for (final MapEntry(key: kind, value: (table, make, inside))
      in kinds.entries) {
    test(kind, () async {
      final local = await make(b);
      final incoming = await make(a);
      final child = await inside(a, incoming);
      await tick();
      final localBefore = await syncedContent(b.db);

      final report = await a.sendTo(b, tmp, 'a1.zip');

      expect(await b.uuidsOf(table), contains(local));
      expect(await b.uuidsOf(table), isNot(contains(incoming)));
      expect(
        (await syncedContent(b.db))[table],
        localBefore[table],
        reason: 'the local record is unchanged',
      );
      expect(report.decisionsPending, 1);
      final decision = (await b.decisions.decisions()).single;
      expect(decision.root.uuid, incoming);
      expect(decision.root.collidesWith, local);
      if (child != null) {
        final (childTable, childId) = child;
        expect(await b.uuidsOf(childTable), isNot(contains(childId)));
        expect(decision.waiting.map((w) => w.uuid), contains(childId));
      }
      await expectNoOrphans(b.db);

      final after = await syncedContent(b.db);
      final again = await a.sendTo(b, tmp, 'a2.zip');
      expect(again.rowsInserted, 0);
      expect(await b.decisions.decisions(), hasLength(1));
      expect(await syncedContent(b.db), after);
    });
  }
}
