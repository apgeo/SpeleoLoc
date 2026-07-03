import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/service_locator.dart';

/// Every trip-domain write must produce a change_log entry: the FTP upload
/// gate (`_hasLocalChangesSince`) only looks at change_log, so an unlogged
/// write means a device whose only activity is recording a trip never
/// uploads it.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    // CaveTripService reaches currentUserService and the configuration
    // repository through the legacy rootContainer, so register it like
    // main() does.
    initRootContainer(container);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<int> count(String table, int changeType) async =>
      (await db.select(db.changeLog).get())
          .where((r) => r.entityTable == table && r.changeType == changeType)
          .length;

  test('trip lifecycle writes change-log entries', () async {
    final caveUuid = await container
        .read(caveRepositoryProvider)
        .addCave('Cave');
    final placeRepo = container.read(cavePlaceRepositoryProvider);
    await placeRepo.addCavePlace(caveUuid, 'P1');
    final place = (await placeRepo.findCavePlaceByTitle(caveUuid, 'P1'))!;

    final service = container.read(caveTripServiceProvider);

    final tripUuid = await service.startTrip(caveUuid, 'Trip');
    expect(await count('cave_trips', ChangeType.insert), 1);

    await service.recordPoint(place.uuid);
    expect(await count('cave_trip_points', ChangeType.insert), 1);

    final docUuid = await db.insertDocumentationFile(
      companion: DocumentationFilesCompanion.insert(
        uuid: Uuid.v7(),
        title: 'Doc',
        fileName: 'doc.txt',
        fileSize: 1,
        fileType: 'text_document',
      ),
    );
    await service.linkDocument(docUuid);
    expect(
      await count('documentation_files_to_cave_trips', ChangeType.insert),
      1,
    );

    await service.stopTrip();
    expect(
      await count('cave_trips', ChangeType.update),
      greaterThanOrEqualTo(1),
      reason: 'ending a trip must log a trip_ended_at update',
    );

    final updatesBeforeRestart = await count('cave_trips', ChangeType.update);
    await service.restartTrip(tripUuid);
    expect(
      await count('cave_trips', ChangeType.update),
      greaterThan(updatesBeforeRestart),
      reason: 'restarting a trip must log an update',
    );
    await service.stopTrip();
  });

  test('repository rename, log edit and template insert are logged', () async {
    final caveUuid = await container
        .read(caveRepositoryProvider)
        .addCave('Cave');
    final service = container.read(caveTripServiceProvider);
    final tripUuid = await service.startTrip(caveUuid, 'Trip');
    await service.stopTrip();

    final repo = container.read(caveTripRepositoryProvider);

    final updatesBefore = await count('cave_trips', ChangeType.update);
    await repo.renameCaveTrip(tripUuid, 'Renamed');
    expect(await count('cave_trips', ChangeType.update), updatesBefore + 1);

    await repo.updateTripLog(tripUuid, 'user-edited log text');
    expect(await count('cave_trips', ChangeType.update), updatesBefore + 2);

    await repo.insertTripReportTemplate(
      title: 'Template',
      fileName: 't.odt',
      fileSize: 10,
      format: 'odt',
    );
    expect(await count('trip_report_templates', ChangeType.insert), 1);
  });
}
