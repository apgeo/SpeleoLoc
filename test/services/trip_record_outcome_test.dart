import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/trip_record_outcome.dart';

/// A live scan or a new document says what it did to the trip, so a pause
/// that dropped it is never reported as recorded.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late CaveTripService service;
  late Uuid caveUuid;
  late Uuid place;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);
    caveUuid = await container.read(caveRepositoryProvider).addCave('Cave');
    final places = container.read(cavePlaceRepositoryProvider);
    await places.addCavePlace(caveUuid, 'Chamber');
    place = (await places.findCavePlaceByTitle(caveUuid, 'Chamber'))!.uuid;
    service = container.read(caveTripServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<Uuid> document() => db.insertDocumentationFile(
    companion: DocumentationFilesCompanion.insert(
      uuid: Uuid.v7(),
      title: 'Photo',
      fileName: 'photo.jpg',
      fileSize: 1,
      fileType: 'image',
    ),
  );

  test('a scan with no trip recording says so', () async {
    expect(await service.recordPoint(place), TripRecordOutcome.noActiveTrip);
  });

  test('a scan while recording is recorded', () async {
    final trip = await service.startTrip(caveUuid, 'Trip');

    expect(await service.recordPoint(place), TripRecordOutcome.recorded);
    expect(await db.getTripPoints(trip), hasLength(1));
  });

  test('a scan while paused says paused and records nothing', () async {
    final trip = await service.startTrip(caveUuid, 'Trip');
    await service.pauseTrip();

    expect(await service.recordPoint(place), TripRecordOutcome.paused);
    expect(await db.getTripPoints(trip), isEmpty);
  });

  test('a document made while paused says paused and is not linked', () async {
    final trip = await service.startTrip(caveUuid, 'Trip');
    await service.pauseTrip();
    final doc = await document();

    expect(await service.linkDocument(doc), TripRecordOutcome.paused);
    final links = await (db.select(
      db.documentationFilesToCaveTrips,
    )..where((l) => l.caveTripUuid.equalsValue(trip))).get();
    expect(links, isEmpty);

    await service.resumeTrip();
    expect(await service.linkDocument(doc), TripRecordOutcome.recorded);
  });
}
