import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/service_locator.dart';
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
}
