import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/trip_record_outcome.dart';
import 'package:speleoloc/utils/constants.dart';

/// The trip this device records into stops being active here once its row
/// is gone or ended, whoever removed or ended it. Every value is invented.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late CaveTripService service;
  late Uuid caveUuid;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);
    caveUuid = await container
        .read(caveRepositoryProvider)
        .addCave('Invented Cave');
    service = container.read(caveTripServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<String?> storedActiveTrip() =>
      ConfigurationRepository(db).readString(activeTripConfigKey);

  test('a trip deleted by a sync stops being active', () async {
    final trip = await service.startTrip(caveUuid, 'Invented trip');
    await service.pauseTrip();
    await (db.delete(
      db.caveTrips,
    )..where((t) => t.uuid.equalsValue(trip))).go();

    await service.reconcileActiveTrip();

    expect(service.activeTripIdNotifier.value, isNull);
    expect(service.isPausedNotifier.value, isFalse);
    expect(await storedActiveTrip(), isNull);
  });

  test('a trip ended on another device stops being active', () async {
    final trip = await service.startTrip(caveUuid, 'Invented trip');
    await (db.update(db.caveTrips)..where((t) => t.uuid.equalsValue(trip)))
        .write(const CaveTripsCompanion(tripEndedAt: Value(1)));

    await service.reconcileActiveTrip();

    expect(service.activeTripIdNotifier.value, isNull);
    expect(await storedActiveTrip(), isNull);
  });

  test('the trip of a deleted cave stops being active', () async {
    await service.startTrip(caveUuid, 'Invented trip');
    await container.read(caveRepositoryProvider).deleteCave(caveUuid);

    await service.reconcileActiveTrip();

    expect(service.activeTripIdNotifier.value, isNull);
  });

  test('a trip still running stays active', () async {
    final trip = await service.startTrip(caveUuid, 'Invented trip');

    await service.reconcileActiveTrip();

    expect(service.activeTripIdNotifier.value, trip);
    expect(await storedActiveTrip(), '$trip');
  });

  test('a rebuilt service picks the running trip up again', () async {
    final trip = await service.startTrip(caveUuid, 'Invented trip');
    container.invalidate(caveTripServiceProvider);

    final rebuilt = container.read(caveTripServiceProvider);
    await rebuilt.initActiveTrip();

    expect(rebuilt, isNot(same(service)));
    expect(rebuilt.activeTripIdNotifier.value, trip);
  });

  // The OS may kill the app underground; scans after the restart must not
  // land in a trip the caver paused.
  group('a pause survives a restart', () {
    Future<CaveTripService> restarted() async {
      container.invalidate(caveTripServiceProvider);
      final rebuilt = container.read(caveTripServiceProvider);
      await rebuilt.initActiveTrip();
      return rebuilt;
    }

    Future<String?> storedPause() =>
        ConfigurationRepository(db).readString(pausedTripConfigKey);

    test('a paused trip comes back paused', () async {
      final trip = await service.startTrip(caveUuid, 'Invented trip');
      await service.pauseTrip();

      final rebuilt = await restarted();

      expect(rebuilt.activeTripIdNotifier.value, trip);
      expect(rebuilt.isPausedNotifier.value, isTrue);
    });

    test('a resumed trip comes back recording', () async {
      final trip = await service.startTrip(caveUuid, 'Invented trip');
      await service.pauseTrip();
      expect(await storedPause(), '$trip');
      await service.resumeTrip();

      expect(await storedPause(), isNull);
      expect((await restarted()).isPausedNotifier.value, isFalse);
    });

    test('stopping a paused trip forgets the pause', () async {
      final trip = await service.startTrip(caveUuid, 'Invented trip');
      await service.pauseTrip();
      expect(await storedPause(), '$trip');
      await service.stopTrip();

      expect(await storedPause(), isNull);
      expect((await restarted()).isPausedNotifier.value, isFalse);
    });

    test('a new trip starts recording, not paused', () async {
      final first = await service.startTrip(caveUuid, 'Invented trip');
      await service.pauseTrip();
      // Stopping is how the caver gets to a new trip; the pause row is
      // planted again to show the start clears it whatever it names.
      await service.stopTrip();
      await ConfigurationRepository(
        db,
      ).writeString(pausedTripConfigKey, '$first');
      final second = await service.startTrip(caveUuid, 'Invented trip 2');

      expect(await storedPause(), isNull);
      final rebuilt = await restarted();
      expect(rebuilt.activeTripIdNotifier.value, second);
      expect(rebuilt.isPausedNotifier.value, isFalse);
    });

    test('a restarted trip starts recording, not paused', () async {
      final trip = await service.startTrip(caveUuid, 'Invented trip');
      await service.pauseTrip();
      await service.stopTrip();
      await ConfigurationRepository(
        db,
      ).writeString(pausedTripConfigKey, '$trip');
      await service.restartTrip(trip);

      expect(await storedPause(), isNull);
      expect((await restarted()).isPausedNotifier.value, isFalse);
    });

    test('a pause stored for another trip is ignored and dropped', () async {
      final trip = await service.startTrip(caveUuid, 'Invented trip');
      await ConfigurationRepository(
        db,
      ).writeString(pausedTripConfigKey, '${Uuid.v7()}');

      final rebuilt = await restarted();

      expect(rebuilt.activeTripIdNotifier.value, trip);
      expect(rebuilt.isPausedNotifier.value, isFalse);
      expect(await storedPause(), isNull);
    });

    test('a paused trip ended elsewhere leaves no pause behind', () async {
      final trip = await service.startTrip(caveUuid, 'Invented trip');
      await service.pauseTrip();
      expect(await storedPause(), '$trip');
      await (db.update(db.caveTrips)..where((t) => t.uuid.equalsValue(trip)))
          .write(const CaveTripsCompanion(tripEndedAt: Value(1)));

      await service.reconcileActiveTrip();

      expect(await storedPause(), isNull);
    });

    test('a paused trip found ended at start-up leaves no pause', () async {
      final trip = await service.startTrip(caveUuid, 'Invented trip');
      await service.pauseTrip();
      expect(await storedPause(), '$trip');
      await (db.update(db.caveTrips)..where((t) => t.uuid.equalsValue(trip)))
          .write(const CaveTripsCompanion(tripEndedAt: Value(1)));

      final rebuilt = await restarted();

      expect(rebuilt.activeTripIdNotifier.value, isNull);
      expect(rebuilt.isPausedNotifier.value, isFalse);
      expect(await storedPause(), isNull);
    });

    test('a pause that cannot be stored still holds while the app runs, '
        'and so does a resume', () async {
      final failing = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          configurationRepositoryProvider.overrideWithValue(
            _PauseStoreFails(db),
          ),
        ],
      );
      addTearDown(failing.dispose);
      final svc = failing.read(caveTripServiceProvider);
      final trip = await svc.startTrip(caveUuid, 'Invented trip');
      final places = failing.read(cavePlaceRepositoryProvider);
      await places.addCavePlace(caveUuid, 'Invented place');
      final place = (await places.findCavePlaceByTitle(
        caveUuid,
        'Invented place',
      ))!.uuid;

      await svc.pauseTrip();
      expect(svc.isPausedNotifier.value, isTrue);
      expect(await svc.recordPoint(place), TripRecordOutcome.paused);

      await svc.resumeTrip();
      expect(svc.isPausedNotifier.value, isFalse);
      expect(svc.activeTripIdNotifier.value, trip);
    });
  });
}

/// A store whose pause row can be neither written nor removed, as on a
/// full disk.
class _PauseStoreFails extends ConfigurationRepository {
  _PauseStoreFails(super.db);

  @override
  Future<void> writeString(
    String key,
    String value, {
    bool isSynced = false,
  }) async {
    if (key == pausedTripConfigKey) throw Exception('disk full');
    await super.writeString(key, value, isSynced: isSynced);
  }

  @override
  Future<void> delete(String key) async {
    if (key == pausedTripConfigKey) throw Exception('disk full');
    await super.delete(key);
  }
}
