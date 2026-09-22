import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/localization.dart';

/// After-the-fact corrections to a trip's points: a stop scanned at the
/// wrong moment, one never scanned at all, one scanned twice. Each must
/// land in `cave_trip_points`, leave a change_log entry (the FTP upload
/// gate reads nothing else) and re-render the trip log in the new order.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late CaveTripService service;
  late Uuid caveUuid;
  late Uuid placeA;
  late Uuid placeB;

  // The rendered-order assertion reads place titles out of the log, and
  // `LocServ.t` drops its params when the bundle is not loaded.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await LocServ.inst.setLocale('en');
    await LocServ.inst.load();
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    // CaveTripService reaches currentUserService and the configuration
    // repository through the legacy rootContainer, so register it like
    // main() does.
    initRootContainer(container);

    caveUuid = await container.read(caveRepositoryProvider).addCave('Cave');
    final placeRepo = container.read(cavePlaceRepositoryProvider);
    await placeRepo.addCavePlace(caveUuid, 'Entrance');
    await placeRepo.addCavePlace(caveUuid, 'Sump');
    placeA = (await placeRepo.findCavePlaceByTitle(caveUuid, 'Entrance'))!.uuid;
    placeB = (await placeRepo.findCavePlaceByTitle(caveUuid, 'Sump'))!.uuid;
    service = container.read(caveTripServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<int> count(String table, int changeType) async =>
      (await db.select(db.changeLog).get())
          .where((r) => r.entityTable == table && r.changeType == changeType)
          .length;

  /// Starts a trip and immediately ends it, so the tests operate on a past
  /// trip with a known [start, end] window.
  Future<Uuid> endedTrip() async {
    final tripUuid = await service.startTrip(caveUuid, 'Trip');
    await service.stopTrip();
    return tripUuid;
  }

  test('a point can be added to an ended trip at a chosen time', () async {
    final tripUuid = await endedTrip();
    final at = DateTime(2026, 9, 22, 11, 30);

    final pointUuid = await service.addPointAt(
      tripUuid: tripUuid,
      cavePlaceUuid: placeA,
      at: at,
    );

    final points = await db.getTripPoints(tripUuid);
    expect(points, hasLength(1));
    expect(points.single.uuid, pointUuid);
    expect(points.single.scannedAt, at.millisecondsSinceEpoch);
    expect(await count('cave_trip_points', ChangeType.insert), 1);
  });

  test('adding a point ignores the paused flag', () async {
    final tripUuid = await service.startTrip(caveUuid, 'Trip');
    await service.pauseTrip();

    // recordPoint is the live-scan path and stays suppressed while paused.
    await service.recordPoint(placeA);
    expect(await db.getTripPoints(tripUuid), isEmpty);

    await service.addPointAt(
      tripUuid: tripUuid,
      cavePlaceUuid: placeA,
      at: DateTime(2026, 9, 22, 11, 30),
    );
    expect(await db.getTripPoints(tripUuid), hasLength(1));
  });

  test('a point time can be moved, and the log re-renders in order', () async {
    final tripUuid = await endedTrip();
    final first = await service.addPointAt(
      tripUuid: tripUuid,
      cavePlaceUuid: placeA,
      at: DateTime(2026, 9, 22, 11, 0),
    );
    await service.addPointAt(
      tripUuid: tripUuid,
      cavePlaceUuid: placeB,
      at: DateTime(2026, 9, 22, 12, 0),
    );

    // Move the first point past the second: the rendered log must follow.
    await service.updatePointTime(first, DateTime(2026, 9, 22, 13, 0));

    final moved = await db.getTripPoint(first);
    expect(
      moved!.scannedAt,
      DateTime(2026, 9, 22, 13, 0).millisecondsSinceEpoch,
    );
    expect(await count('cave_trip_points', ChangeType.update), 1);

    final trip = await container
        .read(caveTripRepositoryProvider)
        .findById(tripUuid);
    final log = trip!.log!;
    expect(
      log.indexOf('Sump'),
      lessThan(log.indexOf('Entrance')),
      reason: 'the re-rendered log must list the points in their new order',
    );
  });

  test('deleting a point removes it and leaves a tombstone', () async {
    final tripUuid = await endedTrip();
    final pointUuid = await service.addPointAt(
      tripUuid: tripUuid,
      cavePlaceUuid: placeA,
      at: DateTime(2026, 9, 22, 11, 0),
    );

    await service.deletePoint(pointUuid);

    expect(await db.getTripPoints(tripUuid), isEmpty);
    expect(await count('cave_trip_points', ChangeType.delete), 1);
  });

  test('editing a vanished point is a no-op, not a crash', () async {
    final tripUuid = await endedTrip();
    final pointUuid = await service.addPointAt(
      tripUuid: tripUuid,
      cavePlaceUuid: placeA,
      at: DateTime(2026, 9, 22, 11, 0),
    );
    await service.deletePoint(pointUuid);

    await service.updatePointTime(pointUuid, DateTime(2026, 9, 22, 12, 0));
    await service.deletePoint(pointUuid);
    expect(await db.getTripPoints(tripUuid), isEmpty);
  });

  test('a same-place, same-time collision surfaces as a duplicate', () async {
    final tripUuid = await endedTrip();
    final at = DateTime(2026, 9, 22, 11, 0);
    await service.addPointAt(tripUuid: tripUuid, cavePlaceUuid: placeA, at: at);

    expect(
      () =>
          service.addPointAt(tripUuid: tripUuid, cavePlaceUuid: placeA, at: at),
      throwsA(isA<DuplicateEntryException>()),
    );
  });

  test('moving a point onto a sibling surfaces as a duplicate', () async {
    final tripUuid = await endedTrip();
    final at = DateTime(2026, 9, 22, 11, 0);
    await service.addPointAt(tripUuid: tripUuid, cavePlaceUuid: placeA, at: at);
    final second = await service.addPointAt(
      tripUuid: tripUuid,
      cavePlaceUuid: placeA,
      at: DateTime(2026, 9, 22, 12, 0),
    );

    expect(
      () => service.updatePointTime(second, at),
      throwsA(isA<DuplicateEntryException>()),
    );
  });
}
