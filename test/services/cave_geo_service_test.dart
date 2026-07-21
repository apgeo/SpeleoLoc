import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_geo_service.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/user_repository.dart';

void main() {
  late AppDatabase db;
  late CaveRepository caveRepo;
  late CavePlaceRepository placeRepo;
  late CaveGeoService geo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final userRepo = UserRepository(db, () => loggerRef);
    final currentUser = CurrentUserService(
      db,
      userRepo,
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    loggerRef = ChangeLogger(db, currentUser);
    caveRepo = CaveRepository(db, currentUser, loggerRef);
    placeRepo = CavePlaceRepository(db, currentUser, loggerRef);
    geo = CaveGeoService(caveRepo, placeRepo);
  });

  tearDown(() async {
    await db.close();
  });

  group('addEntranceAt', () {
    test('the first entrance of a cave becomes its main entrance', () async {
      final caveUuid = await caveRepo.addCave('Cave');
      final id = await geo.addEntranceAt(
        caveUuid: caveUuid,
        title: 'Main',
        latitude: 45.1,
        longitude: 22.2,
      );

      final place = await placeRepo.findById(id);
      expect(place, isNotNull);
      expect(place!.isEntrance, 1);
      expect(place.isMainEntrance, 1);
      expect(place.latitude, 45.1);
      expect(place.longitude, 22.2);
      expect(place.caveUuid, caveUuid);
    });

    test('a duplicate default title is made unique within the cave', () async {
      final caveUuid = await caveRepo.addCave('Cave');
      final firstId = await geo.addEntranceAt(
        caveUuid: caveUuid,
        title: 'Entrance',
        latitude: 45.1,
        longitude: 22.2,
      );
      final secondId = await geo.addEntranceAt(
        caveUuid: caveUuid,
        title: 'Entrance',
        latitude: 45.11,
        longitude: 22.21,
      );
      final thirdId = await geo.addEntranceAt(
        caveUuid: caveUuid,
        title: 'Entrance',
        latitude: 45.12,
        longitude: 22.22,
      );

      expect((await placeRepo.findById(firstId))!.title, 'Entrance');
      expect((await placeRepo.findById(secondId))!.title, 'Entrance 2');
      expect((await placeRepo.findById(thirdId))!.title, 'Entrance 3');
    });

    test('a second entrance is not marked as main', () async {
      final caveUuid = await caveRepo.addCave('Cave');
      await geo.addEntranceAt(
        caveUuid: caveUuid,
        title: 'First',
        latitude: 45.1,
        longitude: 22.2,
      );
      final secondId = await geo.addEntranceAt(
        caveUuid: caveUuid,
        title: 'Second',
        latitude: 45.15,
        longitude: 22.25,
      );

      final second = await placeRepo.findById(secondId);
      expect(second!.isEntrance, 1);
      expect(second.isMainEntrance, 0);
    });
  });

  group('addCaveWithEntranceAt', () {
    test('creates a cave and a main-entrance place at the point', () async {
      final result = await geo.addCaveWithEntranceAt(
        caveTitle: 'Pestera Noua',
        entranceTitle: 'Intrare',
        latitude: 46.0,
        longitude: 23.0,
        altitude: 800,
      );

      final caves = await caveRepo.getCaves();
      expect(caves.single.uuid, result.caveUuid);
      expect(caves.single.title, 'Pestera Noua');

      final entrance = await placeRepo.findById(result.entranceUuid);
      expect(entrance!.title, 'Intrare');
      expect(entrance.caveUuid, result.caveUuid);
      expect(entrance.isEntrance, 1);
      expect(entrance.isMainEntrance, 1);
      expect(entrance.latitude, 46.0);
      expect(entrance.longitude, 23.0);
      expect(entrance.altitude, 800);
    });
  });

  group('setPlaceLocation', () {
    test('updates the coordinates of an existing place', () async {
      final caveUuid = await caveRepo.addCave('Cave');
      await placeRepo.addCavePlace(caveUuid, 'Chamber');
      final place = (await placeRepo.getCavePlaces(caveUuid)).single;
      expect(place.latitude, isNull);

      await geo.setPlaceLocation(
        cavePlaceUuid: place.uuid,
        latitude: 44.5,
        longitude: 21.5,
      );

      final updated = await placeRepo.findById(place.uuid);
      expect(updated!.latitude, 44.5);
      expect(updated.longitude, 21.5);
    });
  });
}
