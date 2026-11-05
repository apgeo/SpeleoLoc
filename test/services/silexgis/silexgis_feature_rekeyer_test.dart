import 'package:drift/drift.dart' show Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/silexgis_feature_rekeyer.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// A row sent again as new takes new identifiers with everything inside it,
/// and everything on the device that names those rows follows them.
void main() {
  const profile = 'p-1';
  final clock = FakeClock(DateTime.utc(2026, 11, 4, 8));

  late AppDatabase db;
  late SilexgisLocalStateRepository localState;
  late SilexgisServerLinkRepository serverLinks;
  late SilexgisFeatureRekeyer rekeyer;

  final caveId = Uuid.v7();
  final areaId = Uuid.v7();
  final placeId = Uuid.v7();
  final tripId = Uuid.v7();
  final pointId = Uuid.v7();
  final mapId = Uuid.v7();
  final documentId = Uuid.v7();
  final linkId = Uuid.v7();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final users = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      users,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    final logger = loggerRef = ChangeLogger(db, currentUser, clock: clock);
    localState = SilexgisLocalStateRepository(db, clock: clock);
    serverLinks = SilexgisServerLinkRepository(db, clock: clock);
    rekeyer = SilexgisFeatureRekeyer(
      db: db,
      logger: logger,
      localState: localState,
      heldRows: SilexgisHeldRowRepository(db, clock: clock),
      serverLinks: serverLinks,
      clock: clock,
    );

    await db.into(db.caves).insert(Cave(uuid: caveId, title: 'Invented'));
    await db
        .into(db.caveAreas)
        .insert(
          CaveAreasCompanion.insert(
            uuid: areaId,
            title: 'Lower level',
            caveUuid: caveId,
          ),
        );
    await db
        .into(db.cavePlaces)
        .insert(
          CavePlace(
            uuid: placeId,
            title: 'Sump',
            caveUuid: caveId,
            caveAreaUuid: areaId,
            isEntrance: 0,
            isMainEntrance: 0,
          ),
        );
    await db
        .into(db.caveTrips)
        .insert(
          CaveTripsCompanion.insert(
            uuid: tripId,
            caveUuid: caveId,
            title: 'Invented trip',
            tripStartedAt: 1,
          ),
        );
    await db
        .into(db.caveTripPoints)
        .insert(
          CaveTripPointsCompanion.insert(
            uuid: pointId,
            caveTripUuid: tripId,
            scannedAt: 2,
            cavePlaceUuid: Value(placeId),
          ),
        );
    await db
        .into(db.rasterMaps)
        .insert(
          RasterMapsCompanion.insert(
            uuid: mapId,
            title: 'Plan',
            mapType: 'plane view',
            fileName: 'raster_maps/plan.png',
            caveUuid: caveId,
            caveAreaUuid: Value(areaId),
          ),
        );
    await db
        .into(db.documentationFiles)
        .insert(
          DocumentationFilesCompanion.insert(
            uuid: documentId,
            title: 'entrance.jpg',
            fileName: 'documentation_files/entrance.jpg',
            fileSize: 10,
            fileType: 'photo',
          ),
        );
    await db
        .into(db.documentationFilesToGeofeatures)
        .insert(
          DocumentationFilesToGeofeaturesCompanion.insert(
            uuid: linkId,
            geofeatureType: GeofeatureType.cavePlace.dbValue,
            documentationFileUuid: documentId,
            geofeatureUuid: Value(placeId),
          ),
        );
    for (final (id, table) in <(Uuid, String)>[
      (areaId, 'cave_areas'),
      (placeId, 'cave_places'),
    ]) {
      await localState.writeRevision(
        profile,
        id,
        entityTable: table,
        revision: '2026-10-01T08:00:00Z',
      );
    }
    await serverLinks.record(
      profile,
      SilexgisServerLinkEntry(
        documentUuid: documentId,
        targetKind: SyncDocumentLink.targetFeature,
        targetId: placeId,
        linkId: 'link-1',
      ),
    );
    await db.delete(db.changeLog).go();
  });
  tearDown(() => db.close());

  test('a cave takes its areas and places along, and what names them '
      'follows', () async {
    clock.advance(const Duration(minutes: 1));
    final renamed = await rekeyer.rekey(profile, 'caves', caveId);

    expect(renamed.keys.toSet(), <Uuid>{caveId, areaId, placeId});
    final cave = renamed[caveId]!;
    final area = renamed[areaId]!;
    final place = renamed[placeId]!;

    final stored = (await db.select(db.cavePlaces).get()).single;
    expect(stored.uuid, place);
    expect(stored.caveUuid, cave);
    expect(stored.caveAreaUuid, area);
    expect((await db.select(db.caveAreas).get()).single.caveUuid, cave);

    // Trips, scans, maps and document links keep their own identifiers.
    final trip = (await db.select(db.caveTrips).get()).single;
    expect(trip.uuid, tripId);
    expect(trip.caveUuid, cave);
    expect(trip.updatedAt, clock.nowMs());
    expect(
      (await db.select(db.caveTripPoints).get()).single.cavePlaceUuid,
      place,
    );
    final map = (await db.select(db.rasterMaps).get()).single;
    expect(map.caveUuid, cave);
    expect(map.caveAreaUuid, area);
    final link =
        (await db.select(db.documentationFilesToGeofeatures).get()).single;
    expect(link.uuid, linkId);
    expect(link.geofeatureUuid, place);

    // Every name agrees again.
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);

    // The installation's record of the old rows goes; the new ones are new
    // there, and so is the link to the new place.
    expect(await localState.readRevisions(profile), isEmpty);
    expect(await serverLinks.readAll(profile), isEmpty);

    final logged = await db.select(db.changeLog).get();
    expect(
      logged
          .where((e) => e.changeType == ChangeType.delete)
          .map((e) => e.entityUuid)
          .toSet(),
      <Uuid>{caveId, areaId, placeId},
    );
    // Each old identifier is logged as merged into its new one, so a peer
    // moves what only it holds inside the old rows over to the new ones.
    final mergedInto = <Uuid, Uuid>{
      for (final row
          in await db
              .customSelect(
                'SELECT l.entity_uuid AS old, f.old_value_short AS fresh '
                'FROM change_log l JOIN change_log_field f '
                'ON f.change_uuid = l.uuid WHERE f.field_name = ?',
                variables: const [Variable<String>(kMergedIntoField)],
              )
              .get())
        Uuid.fromBytes(row.read('old')): Uuid.fromBytes(row.read('fresh')),
    };
    expect(mergedInto, renamed);
    expect(
      logged
          .where((e) => e.changeType == ChangeType.insert)
          .map((e) => e.entityUuid)
          .toSet(),
      <Uuid>{cave, area, place},
    );
    expect(
      logged
          .where((e) => e.changeType == ChangeType.update)
          .map((e) => e.entityUuid)
          .toSet(),
      containsAll(<Uuid>{tripId, pointId, mapId, linkId}),
    );
  });

  test('an area takes its places along and leaves its cave', () async {
    final renamed = await rekeyer.rekey(profile, 'cave_areas', areaId);

    expect(renamed.keys.toSet(), <Uuid>{areaId, placeId});
    expect((await db.select(db.caves).get()).single.uuid, caveId);
    final place = (await db.select(db.cavePlaces).get()).single;
    expect(place.caveUuid, caveId);
    expect(place.caveAreaUuid, renamed[areaId]);
  });

  test('a row no longer here changes nothing', () async {
    expect(await rekeyer.rekey(profile, 'caves', Uuid.v7()), isEmpty);
    expect((await db.select(db.caves).get()).single.uuid, caveId);
  });
}
