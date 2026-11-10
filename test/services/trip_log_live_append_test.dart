import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/trip_log_method.dart';
import 'package:speleoloc/utils/localization.dart';

/// Points scanned while the trip runs go into its log without touching
/// what the caver typed there, whatever the writing style — including the
/// narrative one, whose paragraphs cannot simply be appended to.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;
  late CaveTripService service;
  late Uuid caveUuid;
  late Uuid chamber;
  late Uuid sump;

  setUpAll(() async {
    await LocServ.inst.setLocale('en');
    await LocServ.inst.load();
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);
    caveUuid = await container.read(caveRepositoryProvider).addCave('Cave');
    final places = container.read(cavePlaceRepositoryProvider);
    await places.addCavePlace(caveUuid, 'Chamber');
    await places.addCavePlace(caveUuid, 'Sump');
    chamber = (await places.findCavePlaceByTitle(caveUuid, 'Chamber'))!.uuid;
    sump = (await places.findCavePlaceByTitle(caveUuid, 'Sump'))!.uuid;
    service = container.read(caveTripServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<CaveTrip> trip(Uuid uuid) async =>
      (await container.read(caveTripRepositoryProvider).findById(uuid))!;

  Future<void> type(Uuid uuid, String log) =>
      container.read(caveTripRepositoryProvider).updateTripLog(uuid, log);

  for (final method in TripLogMethod.values) {
    group('with the ${method.name} style', () {
      setUp(
        () =>
            container.read(currentUserServiceProvider).setTripLogMethod(method),
      );

      test('text typed after the generated part survives a scan', () async {
        final uuid = await service.startTrip(caveUuid, 'Trip');
        await service.recordPoint(chamber);
        await type(uuid, '${(await trip(uuid)).log}\n\nWater was high.');

        await service.recordPoint(sump);

        final log = (await trip(uuid)).log!;
        expect(log, contains('Water was high.'));
        expect(log, contains('Sump'));
      });

      test('text typed after the generated part survives stopping', () async {
        final uuid = await service.startTrip(caveUuid, 'Trip');
        await service.recordPoint(chamber);
        await type(uuid, '${(await trip(uuid)).log}\n\nWater was high.');

        await service.stopTrip();

        expect((await trip(uuid)).log, contains('Water was high.'));
      });
    });
  }

  group('with the narrative style', () {
    setUp(
      () => container
          .read(currentUserServiceProvider)
          .setTripLogMethod(TripLogMethod.narrative),
    );

    test('a log reworded by hand is kept and marked behind', () async {
      final uuid = await service.startTrip(caveUuid, 'Trip');
      await service.recordPoint(chamber);
      const reworded = 'Our own account of the day, written from scratch.';
      await type(uuid, reworded);

      await service.recordPoint(sump);

      final after = await trip(uuid);
      expect(after.log, reworded);
      expect(after.logStaleSince, isNotNull);
      expect(await db.getTripPoints(uuid), hasLength(2));
    });

    test('a log reworded by hand is kept when a document is linked', () async {
      final uuid = await service.startTrip(caveUuid, 'Trip');
      await service.recordPoint(chamber);
      const reworded = 'Our own account of the day, written from scratch.';
      await type(uuid, reworded);
      final doc = await db.insertDocumentationFile(
        companion: DocumentationFilesCompanion.insert(
          uuid: Uuid.v7(),
          title: 'Photo',
          fileName: 'photo.jpg',
          fileSize: 1,
          fileType: 'image',
        ),
      );

      await service.linkDocument(doc, documentTitle: 'Photo');

      final after = await trip(uuid);
      expect(after.log, reworded);
      expect(after.logStaleSince, isNotNull);
    });

    test('a log reworded by hand is kept when the trip stops', () async {
      final uuid = await service.startTrip(caveUuid, 'Trip');
      await service.recordPoint(chamber);
      const reworded = 'Our own account of the day, written from scratch.';
      await type(uuid, reworded);

      await service.stopTrip();

      expect((await trip(uuid)).log, reworded);
    });

    test('an untouched log follows the points', () async {
      final uuid = await service.startTrip(caveUuid, 'Trip');
      await service.recordPoint(chamber);
      await service.recordPoint(sump);

      final after = await trip(uuid);
      expect(after.log, contains('Sump'));
      expect(after.logStaleSince, isNull);
      expect(await service.regenerationWouldChangeLog(uuid), isFalse);
    });
  });
}
