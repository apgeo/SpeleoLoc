import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/utils/app_exceptions.dart';

void main() {
  late AppDatabase db;
  late BeaconRepository repo;
  late Uuid caveUuid;
  late Uuid placeUuid;

  const uuidA = 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825';
  const uuidB = 'FFFE2D12-1E4B-0FA4-994E-CEB531F40545';

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
    final caveRepo = CaveRepository(db, currentUser, loggerRef);
    final cavePlaceRepo = CavePlaceRepository(db, currentUser, loggerRef);
    repo = BeaconRepository(db, currentUser, loggerRef);

    caveUuid = await caveRepo.addCave('Test Cave');
    await cavePlaceRepo.addCavePlace(caveUuid, 'Gallery 1');
    placeUuid = (await cavePlaceRepo.getCavePlaces(caveUuid)).single.uuid;
  });

  tearDown(() async {
    await db.close();
  });

  group('BeaconRepository', () {
    test('register + list for place round-trip', () async {
      await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidA.toLowerCase(), // normalised to uppercase
        major: 10828,
        minor: 518,
        macAddress: 'F0:C8:70:01:08:00',
      );
      final beacons = await repo.getBeaconsForPlace(placeUuid);
      expect(beacons, hasLength(1));
      expect(beacons.single.proximityUuid, uuidA);
      expect(beacons.single.major, 10828);
      expect(beacons.single.minor, 518);
      expect(beacons.single.macAddress, 'F0:C8:70:01:08:00');
    });

    test('findByIdentity matches case-insensitively on UUID', () async {
      await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidA,
        major: 1,
        minor: 2,
      );
      final hits = await repo.findByIdentity(uuidA.toLowerCase(), 1, 2);
      expect(hits, hasLength(1));
      expect(hits.single.cavePlace.uuid, placeUuid);
      expect(hits.single.caveTitle, 'Test Cave');

      expect(await repo.findByIdentity(uuidB, 1, 2), isEmpty);
      expect(await repo.findByIdentity(uuidA, 1, 3), isEmpty);
    });

    test('duplicate identity in the same cave is rejected', () async {
      await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidA,
        major: 7,
        minor: 8,
      );
      expect(
        () => repo.registerBeacon(
          cavePlaceUuid: placeUuid,
          caveUuid: caveUuid,
          proximityUuid: uuidA,
          major: 7,
          minor: 8,
        ),
        throwsA(isA<DbException>()),
      );
    });

    test('multiple beacons per place are allowed', () async {
      await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidA,
        major: 1,
        minor: 1,
      );
      await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidB,
        major: 1,
        minor: 1, // same major/minor, different UUID → distinct identity
      );
      expect(await repo.getBeaconsForPlace(placeUuid), hasLength(2));
    });

    test('unregister soft-deletes and hides from queries', () async {
      final id = await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidA,
        major: 5,
        minor: 6,
      );
      await repo.unregisterBeacon(id);
      expect(await repo.getBeaconsForPlace(placeUuid), isEmpty);
      expect(await repo.findByIdentity(uuidA, 5, 6), isEmpty);
      expect(await repo.getBeaconsForCave(caveUuid), isEmpty);

      // Row still exists (soft delete), deleted_at is set.
      final raw = await (db.select(
        db.cavePlaceBeacons,
      )..where((b) => b.uuid.equalsValue(id))).getSingle();
      expect(raw.deletedAt, isNotNull);
    });

    test('unregistered identity can be registered again in the cave', () async {
      final first = await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidA,
        major: 5,
        minor: 6,
      );
      await repo.unregisterBeacon(first);
      // The soft-deleted row must not trip the identity guard (partial
      // unique index scoped to active rows).
      final second = await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidA,
        major: 5,
        minor: 6,
      );
      expect(second, isNot(first));
      expect(await repo.findByIdentity(uuidA, 5, 6), hasLength(1));
    });

    test('updateHealth stamps telemetry without touching updated_at', () async {
      final id = await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidA,
        major: 9,
        minor: 10,
      );
      final before = (await repo.getBeaconsForPlace(placeUuid)).single;
      await repo.updateHealth(
        id,
        batteryMv: 3287,
        temperatureC: 12.5,
        humidityPct: 98,
      );
      final after = (await repo.getBeaconsForPlace(placeUuid)).single;
      expect(after.lastSeenAt, isNotNull);
      expect(after.lastBatteryMv, 3287);
      expect(after.lastTemperatureC, 12.5);
      expect(after.lastHumidityPct, 98);
      expect(
        after.updatedAt,
        before.updatedAt,
        reason: 'telemetry must not bump the sync timestamp',
      );
    });

    test('updateTagInfo persists title/notes and bumps updated_at', () async {
      final id = await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidA,
        major: 21,
        minor: 22,
      );
      final before = (await repo.getBeaconsForPlace(placeUuid)).single;
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repo.updateTagInfo(id, title: 'North exit', notes: 'On the wall');
      final after = (await repo.getBeaconsForPlace(placeUuid)).single;
      expect(after.title, 'North exit');
      expect(after.notes, 'On the wall');
      expect(after.updatedAt, isNot(before.updatedAt));
    });

    test('getAllBeacons spans caves and skips deleted rows', () async {
      await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidA,
        major: 31,
        minor: 32,
      );
      final deleted = await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidB,
        major: 31,
        minor: 32,
      );
      await repo.unregisterBeacon(deleted);
      final all = await repo.getAllBeacons();
      expect(all, hasLength(1));
      expect(all.single.caveTitle, 'Test Cave');
    });

    test('getBeaconsForCave joins place and cave titles', () async {
      await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidB,
        major: 57362,
        minor: 45060,
      );
      final list = await repo.getBeaconsForCave(caveUuid);
      expect(list, hasLength(1));
      expect(list.single.cavePlace.title, 'Gallery 1');
      expect(list.single.caveTitle, 'Test Cave');
    });

    test('findByIdentity scoped to cave filters other caves', () async {
      await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidA,
        major: 11,
        minor: 12,
      );
      final otherCave = Uuid.v7();
      expect(
        await repo.findByIdentity(uuidA, 11, 12, currentCaveId: otherCave),
        isEmpty,
      );
      expect(
        await repo.findByIdentity(uuidA, 11, 12, currentCaveId: caveUuid),
        hasLength(1),
      );
    });
  });

  group('BeaconRepository (ruuvi)', () {
    const mac = 'CB:B8:33:4C:88:4F';

    test('register + findByMac round-trip, MAC normalised', () async {
      await repo.registerRuuviTag(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        macAddress: mac.toLowerCase(),
        model: 'RuuviTag Pro 3in1',
      );
      final beacons = await repo.getBeaconsForPlace(placeUuid);
      expect(beacons, hasLength(1));
      final b = beacons.single;
      expect(b.beaconType, BeaconTypes.ruuvi);
      expect(b.macAddress, mac);
      expect(b.proximityUuid, isNull);
      expect(b.major, isNull);
      expect(b.model, 'RuuviTag Pro 3in1');

      final hits = await repo.findByMac(mac.toLowerCase());
      expect(hits, hasLength(1));
      expect(hits.single.cavePlace.uuid, placeUuid);
      expect(await repo.findByMac('AA:AA:AA:AA:AA:AA'), isEmpty);
    });

    test('duplicate MAC in the same cave is rejected', () async {
      await repo.registerRuuviTag(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        macAddress: mac,
      );
      expect(
        () => repo.registerRuuviTag(
          cavePlaceUuid: placeUuid,
          caveUuid: caveUuid,
          macAddress: mac,
        ),
        throwsA(isA<DuplicateEntryException>()),
      );
    });

    test('unregistered MAC can be registered again in the cave', () async {
      final first = await repo.registerRuuviTag(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        macAddress: mac,
      );
      await repo.unregisterBeacon(first);
      final second = await repo.registerRuuviTag(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        macAddress: mac,
      );
      expect(second, isNot(first));
      expect(await repo.findByMac(mac), hasLength(1));
    });

    test('ruuvi and iBeacon registrations coexist on one place', () async {
      await repo.registerBeacon(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        proximityUuid: uuidA,
        major: 1,
        minor: 2,
      );
      await repo.registerRuuviTag(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        macAddress: mac,
      );
      final beacons = await repo.getBeaconsForPlace(placeUuid);
      expect(beacons, hasLength(2));
      expect(
        beacons.map(BeaconRepository.identityOf),
        containsAll(['$uuidA/1/2', 'RUUVI/$mac']),
      );
    });

    test('updateHealth stamps the ruuvi telemetry columns', () async {
      final id = await repo.registerRuuviTag(
        cavePlaceUuid: placeUuid,
        caveUuid: caveUuid,
        macAddress: mac,
      );
      final before = (await repo.getBeaconsForPlace(placeUuid)).single;
      await repo.updateHealth(
        id,
        batteryMv: 2977,
        temperatureC: 4.2,
        humidityPct: 98.5,
        pressureHpa: 1000.44,
        movementCounter: 66,
        firmwareVersion: '3.31.1',
      );
      final after = (await repo.getBeaconsForPlace(placeUuid)).single;
      expect(after.lastPressureHpa, 1000.44);
      expect(after.lastMovementCounter, 66);
      expect(after.firmwareVersion, '3.31.1');
      expect(
        after.updatedAt,
        before.updatedAt,
        reason: 'telemetry must not bump the sync timestamp',
      );
    });
  });
}
