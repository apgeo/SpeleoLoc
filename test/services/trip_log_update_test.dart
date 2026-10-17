import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/trip_log_update.dart';
import 'package:speleoloc/services/trip_media/trip_media_import_service.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';
import 'package:speleoloc/utils/localization.dart';

/// Editing a trip's points used to rewrite its log every time, which threw
/// away anything typed into it. Now that is the user's setting, off by
/// default: the log is kept as written and the trip records that it has
/// fallen behind, until the user regenerates it or accepts it.
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

  /// An ended trip whose log has a line typed into it by hand.
  Future<Uuid> tripWithHandWrittenLog() async {
    final uuid = await service.startTrip(caveUuid, 'Trip');
    await service.stopTrip();
    final written = '${(await trip(uuid)).log}\nMet the other team here.';
    await container
        .read(caveTripRepositoryProvider)
        .updateTripLog(uuid, written);
    return uuid;
  }

  Future<List<String>> loggedFields(Uuid tripUuid) async {
    final rows = await db
        .customSelect(
          'SELECT f.field_name AS name FROM change_log c '
          'JOIN change_log_field f ON f.change_uuid = c.uuid '
          "WHERE c.entity_table = 'cave_trips' AND c.entity_uuid = ? "
          'ORDER BY c.rowid',
          variables: [Variable<Uint8List>(tripUuid.bytes)],
        )
        .get();
    return [for (final r in rows) r.read<String>('name')];
  }

  Future<void> setRegenerateOnEdit(bool on) =>
      container.read(currentUserServiceProvider).setTripLogRegenerateOnEdit(on);

  group('by default an edit keeps the log as written', () {
    test('the text is untouched and the trip is marked behind', () async {
      final uuid = await tripWithHandWrittenLog();
      final before = (await trip(uuid)).log;

      await service.addPointAt(
        tripUuid: uuid,
        cavePlaceUuid: chamber,
        at: DateTime(2026, 10, 13, 10),
      );

      final after = await trip(uuid);
      expect(after.log, before);
      expect(after.logStaleSince, isNotNull);
    });

    test('a second edit keeps the moment it first fell behind', () async {
      final uuid = await tripWithHandWrittenLog();
      await service.addPointAt(
        tripUuid: uuid,
        cavePlaceUuid: chamber,
        at: DateTime(2026, 10, 13, 10),
      );
      final first = (await trip(uuid)).logStaleSince;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await service.addPointAt(
        tripUuid: uuid,
        cavePlaceUuid: sump,
        at: DateTime(2026, 10, 13, 11),
      );
      expect((await trip(uuid)).logStaleSince, first);
    });

    test('the mark is logged, so it reaches other devices', () async {
      final uuid = await tripWithHandWrittenLog();
      await service.addPointAt(
        tripUuid: uuid,
        cavePlaceUuid: chamber,
        at: DateTime(2026, 10, 13, 10),
      );
      expect(await loggedFields(uuid), contains('log_stale_since'));
    });
  });

  test('with the setting on an edit regenerates the log', () async {
    await setRegenerateOnEdit(true);
    final uuid = await tripWithHandWrittenLog();

    await service.addPointAt(
      tripUuid: uuid,
      cavePlaceUuid: chamber,
      at: DateTime(2026, 10, 13, 10),
    );

    final after = await trip(uuid);
    expect(after.log, isNot(contains('Met the other team here.')));
    expect(after.log, contains('Chamber'));
    expect(after.logStaleSince, isNull);
  });

  group('what the caller asks for wins over the setting', () {
    test('keeping the log although the setting regenerates', () async {
      await setRegenerateOnEdit(true);
      final uuid = await tripWithHandWrittenLog();
      final before = (await trip(uuid)).log;
      await service.addPointAt(
        tripUuid: uuid,
        cavePlaceUuid: chamber,
        at: DateTime(2026, 10, 13, 10),
        logUpdate: TripLogUpdate.markStale,
      );
      expect((await trip(uuid)).log, before);
      expect((await trip(uuid)).logStaleSince, isNotNull);
    });

    test('regenerating although the setting keeps', () async {
      final uuid = await tripWithHandWrittenLog();
      await service.addPointAt(
        tripUuid: uuid,
        cavePlaceUuid: chamber,
        at: DateTime(2026, 10, 13, 10),
        logUpdate: TripLogUpdate.regenerate,
      );
      expect((await trip(uuid)).log, contains('Chamber'));
      expect((await trip(uuid)).logStaleSince, isNull);
    });

    test('leaving it to the caller does neither', () async {
      final uuid = await tripWithHandWrittenLog();
      final before = (await trip(uuid)).log;
      await service.addPointAt(
        tripUuid: uuid,
        cavePlaceUuid: chamber,
        at: DateTime(2026, 10, 13, 10),
        logUpdate: TripLogUpdate.leaveToCaller,
      );
      expect((await trip(uuid)).log, before);
      expect((await trip(uuid)).logStaleSince, isNull);
    });
  });

  group('settling a log that fell behind', () {
    Future<Uuid> staleTrip() async {
      final uuid = await tripWithHandWrittenLog();
      await service.addPointAt(
        tripUuid: uuid,
        cavePlaceUuid: chamber,
        at: DateTime(2026, 10, 13, 10),
      );
      expect((await trip(uuid)).logStaleSince, isNotNull);
      return uuid;
    }

    test('regenerating rewrites it and clears the mark', () async {
      final uuid = await staleTrip();
      await service.regenerateLog(uuid);
      final after = await trip(uuid);
      expect(after.log, contains('Chamber'));
      expect(after.logStaleSince, isNull);
      expect(await loggedFields(uuid), contains('log'));
    });

    test('keeping it as written clears the mark and leaves the text', () async {
      final uuid = await staleTrip();
      final before = (await trip(uuid)).log;
      await service.keepLogAsWritten(uuid);
      final after = await trip(uuid);
      expect(after.log, before);
      expect(after.logStaleSince, isNull);
    });

    test('keeping a log that was not behind changes nothing', () async {
      final uuid = await tripWithHandWrittenLog();
      final fieldsBefore = await loggedFields(uuid);
      await service.keepLogAsWritten(uuid);
      expect(await loggedFields(uuid), fieldsBefore);
    });
  });

  group('whether regenerating would change the text', () {
    test('not for a log just rendered from its points', () async {
      final uuid = await service.startTrip(caveUuid, 'Trip');
      await service.stopTrip();
      expect(await service.regenerationWouldChangeLog(uuid), isFalse);
    });

    test('yes once something was typed into it', () async {
      final uuid = await tripWithHandWrittenLog();
      expect(await service.regenerationWouldChangeLog(uuid), isTrue);
    });

    test('yes once it has fallen behind its points', () async {
      final uuid = await service.startTrip(caveUuid, 'Trip');
      await service.stopTrip();
      await service.addPointAt(
        tripUuid: uuid,
        cavePlaceUuid: chamber,
        at: DateTime(2026, 10, 13, 10),
      );
      expect(await service.regenerationWouldChangeLog(uuid), isTrue);
    });
  });

  group('a media import settles the log once', () {
    TripMediaCommit commit(String id, Uuid place, DateTime at) =>
        TripMediaCommit(
          item: TripMediaItem(
            id: id,
            kind: TripMediaKind.photo,
            capturedAt: at,
            capturedAtSource: MediaTimeSource.library,
          ),
          cavePlaceUuid: place,
          at: at,
        );

    test('marking it behind once, not per picture', () async {
      final uuid = await tripWithHandWrittenLog();
      final before = (await trip(uuid)).log;
      await container
          .read(tripMediaImportServiceProvider)
          .apply(
            tripUuid: uuid,
            commits: [
              commit('a', chamber, DateTime(2026, 10, 13, 10)),
              commit('b', sump, DateTime(2026, 10, 13, 11)),
              commit('c', chamber, DateTime(2026, 10, 13, 12)),
            ],
            importFiles: false,
            compressImages: false,
          );
      expect((await trip(uuid)).log, before);
      expect(
        (await loggedFields(uuid)).where((f) => f == 'log_stale_since'),
        hasLength(1),
      );
    });

    test('or regenerating it once with every picture in it', () async {
      final uuid = await tripWithHandWrittenLog();
      await container
          .read(tripMediaImportServiceProvider)
          .apply(
            tripUuid: uuid,
            commits: [
              commit('a', sump, DateTime(2026, 10, 13, 11)),
              commit('b', chamber, DateTime(2026, 10, 13, 10)),
            ],
            importFiles: false,
            compressImages: false,
            logUpdate: TripLogUpdate.regenerate,
          );
      final log = (await trip(uuid)).log!;
      expect(log.indexOf('Chamber'), lessThan(log.indexOf('Sump')));
      expect((await trip(uuid)).logStaleSince, isNull);
    });
  });
}
