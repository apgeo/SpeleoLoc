import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/cave_default_model_repository.dart';
import 'package:speleoloc/services/cave_model/place_station_mapping_repository.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/definition_repository.dart';
import 'package:speleoloc/services/raster_map_repository.dart';
import 'package:speleoloc/services/sync/sync_table_registry.dart';

import '../support/populated_cave.dart';
import '../support/sync_assertions.dart';
import '../support/sync_device.dart';

/// Every synced table's deletions reach a peer: the record goes there too,
/// with what hangs on it, the import commits without a warning, and both
/// phones end with the same records. A table added to the sync without a
/// way to delete its rows here fails the first test, rather than in the
/// field.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late SyncTestDevice a;
  late SyncTestDevice b;
  late PopulatedCave full;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('tombstone_tables_');
    a = await SyncTestDevice.create();
    b = await SyncTestDevice.create();
    full = await PopulatedCave.build(a);
    await a.trips.insertTripReportTemplate(
      title: 'Invented template',
      fileName: 'invented_template.docx',
      fileSize: 1,
      format: 'docx',
    );
    await a.sendTo(b, tmp, 'a0.zip');
    await tick();
  });
  tearDown(() async {
    await a.dispose();
    await b.dispose();
    await tmp.delete(recursive: true);
  });

  /// Deletes a link row the way the app's cascades do: the row, then its
  /// tombstone.
  Future<void> dropLink(SyncTestDevice d, String table, Uuid link) async {
    await d.db.customStatement('DELETE FROM $table WHERE uuid = ?', [
      link.bytes,
    ]);
    await d.logger.logDelete(table, link, oldValues: const {});
  }

  /// How the app deletes a record of each synced table on [d].
  final deletions = <String, Future<void> Function(SyncTestDevice d)>{
    'surface_areas': (d) async =>
        d.caves.deleteSurfaceArea((await d.caves.getSurfaceAreas()).single),
    'caves': (d) => d.caves.deleteCave(full.cave),
    'cave_areas': (d) async =>
        d.caves.deleteCaveArea((await d.caves.findCaveAreaById(full.area))!),
    'cave_places': (d) => d.places.deleteCavePlace(full.pinnedPlace),
    'cave_place_beacons': (d) =>
        d.beacons.unregisterBeacon(full.rows['cave_place_beacons']!.single),
    // A pinned map: its pins go first, as the maps page and the server
    // decisions do.
    'raster_maps': (d) async {
      await DefinitionRepository(
        d.db,
        d.currentUser,
        d.logger,
      ).deleteAllDefinitionsForRasterMap(full.map);
      await RasterMapRepository(
        d.db,
        d.currentUser,
        d.logger,
      ).deleteRasterMap(full.map);
    },
    'cave_place_to_raster_map_definitions': (d) => DefinitionRepository(
      d.db,
      d.currentUser,
      d.logger,
    ).deleteDefinition(full.pinnedPlace, full.map),
    'cave_trips': (d) => d.trips.deleteCaveTrip(full.trip),
    // A point with a photo on it.
    'cave_trip_points': (d) => CaveTripService(
      d.db,
      d.logger,
      d.currentUser,
      ConfigurationRepository(d.db),
    ).deletePoint(full.visit),
    // A document linked to a trip.
    'documentation_files': (d) =>
        d.documents.deleteDocumentationFile(full.recording),
    'documentation_files_to_geofeatures': (d) async => dropLink(
      d,
      'documentation_files_to_geofeatures',
      (await d.uuidsOf('documentation_files_to_geofeatures')).first,
    ),
    'documentation_files_to_cave_trips': (d) async => dropLink(
      d,
      'documentation_files_to_cave_trips',
      (await d.uuidsOf('documentation_files_to_cave_trips')).single,
    ),
    'documentation_files_to_cave_trip_points': (d) async => dropLink(
      d,
      'documentation_files_to_cave_trip_points',
      (await d.uuidsOf('documentation_files_to_cave_trip_points')).single,
    ),
    'cave_place_model_stations': (d) => PlaceStationMappingRepository(
      d.db,
      d.currentUser,
      d.logger,
    ).deleteMapping(full.pinnedPlace, full.model),
    'cave_default_survey_models': (d) => CaveDefaultModelRepository(
      d.db,
      d.currentUser,
      d.logger,
    ).clearDefaultModel(full.cave),
    'trip_report_templates': (d) async => d.trips.deleteTripReportTemplate(
      (await d.uuidsOf('trip_report_templates')).single,
    ),
  };

  test('every synced table has a deletion here', () {
    final synced = {for (final t in SyncTableRegistry(a.db).tables()) t.name}
      ..removeAll({'users', SyncTableRegistry.configurationsTable});
    expect(deletions.keys.toSet(), synced);
  });

  /// The rows of [table] on [d] still in use: a beacon is unregistered by
  /// stamping it deleted, and stays in its table.
  Future<Set<Uuid>> live(SyncTestDevice d, String table) async {
    final columns = await d.db.customSelect('PRAGMA table_info($table)').get();
    final soft = columns.any((c) => c.read<String>('name') == 'deleted_at');
    return {
      for (final r
          in await d.db
              .customSelect(
                'SELECT uuid FROM $table${soft ? ' WHERE deleted_at IS NULL' : ''}',
              )
              .get())
        Uuid.fromBytes(r.read('uuid')),
    };
  }

  for (final MapEntry(key: table, value: delete) in deletions.entries) {
    test('a deletion in $table reaches the peer', () async {
      final before = await live(a, table);
      await delete(a);
      final gone = before.difference(await live(a, table));
      expect(gone, isNotEmpty, reason: 'nothing was deleted');
      await tick();

      final report = await a.sendTo(b, tmp, 'a1.zip');

      expect(
        report.warnings.where((w) => !w.startsWith('remapped user')),
        isEmpty,
      );
      expect((await live(b, table)).intersection(gone), isEmpty);
      await expectNoOrphans(b.db);
      await expectConverged(a.db, b.db);
    });
  }

  test('a deletion the peer could not apply is not taken as applied: the '
      'next import applies it', () async {
    await a.places.deleteCavePlace(full.pinnedPlace);
    await tick();
    final deletion = await a.export(tmp, 'a1.zip');
    await b.db.customStatement('''
      CREATE TEMP TRIGGER refuse_place_delete BEFORE DELETE ON cave_places
      BEGIN SELECT RAISE(ABORT, 'invented storage failure'); END
      ''');

    await expectLater(b.sync.importFromZip(deletion.path), throwsA(anything));
    expect(await b.uuidsOf('cave_places'), contains(full.pinnedPlace));
    final logged = await (b.db.select(
      b.db.changeLog,
    )..where((c) => c.entityUuid.equalsValue(full.pinnedPlace))).get();
    expect(
      logged.where((c) => c.changeType == ChangeType.delete),
      isEmpty,
      reason: 'a deletion recorded here would not be applied again',
    );

    await b.db.customStatement('DROP TRIGGER refuse_place_delete');
    await b.sync.importFromZip(deletion.path);

    expect(await b.uuidsOf('cave_places'), isNot(contains(full.pinnedPlace)));
    await expectNoOrphans(b.db);
  });
}
