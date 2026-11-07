import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/active_trip_reconciler_provider.dart';
import 'package:speleoloc/providers/database_swap_providers.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/state/coordinate_format_notifier.dart';
import 'package:speleoloc/state/model_viewer_settings_notifier.dart';
import 'package:speleoloc/utils/clock.dart';
import 'package:speleoloc/utils/coordinate_formats.dart';

/// Providers that are checked elsewhere, or cannot be built without a
/// platform plugin or a family argument.
const _notReadHere = <String, String>{
  'cavePlacesStreamProvider': 'family: needs a cave uuid',
  'ruuviHistoryStreamProvider': 'family: needs a tag id',
  'rasterMapPictureProvider': 'family: needs a map and a size',
  'silexgisServerDocumentsProvider': 'family: needs a feature uuid',
  'silexgisCaverChoiceProvider': 'family: needs a user uuid',
  'caveModelsProvider': 'family: needs a cave uuid',
  'caveServerModelsProvider': 'family: needs a cave uuid',
  'tileDiskCacheProvider': 'opens the platform cache folder',
  'appDatabaseProvider': 'overridden here',
  'clockProvider': 'overridden here',
};

/// Every provider the app exposes builds on top of an in-memory database
/// and a fixed clock, without a missing override and without a cycle. A new
/// provider that reaches for a global the tests do not set up fails here
/// rather than on the first screen that happens to read it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(FakeClock(DateTime.utc(2026, 1, 2))),
      ],
    );
  });

  tearDown(() async {
    // Services started while building may still be reading the database.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    container.dispose();
    await db.close();
  });

  final providers = <String, ProviderBase<Object?>>{
    'configurationRepositoryProvider': configurationRepositoryProvider,
    'caveRepositoryProvider': caveRepositoryProvider,
    'userRepositoryProvider': userRepositoryProvider,
    'currentUserServiceProvider': currentUserServiceProvider,
    'currentUserResolverProvider': currentUserResolverProvider,
    'changeLoggerProvider': changeLoggerProvider,
    'syncArchiveServiceProvider': syncArchiveServiceProvider,
    'archiveHeldRowRepositoryProvider': archiveHeldRowRepositoryProvider,
    'syncMergeEngineProvider': syncMergeEngineProvider,
    'archiveSyncDecisionsServiceProvider': archiveSyncDecisionsServiceProvider,
    'ftpHostKeyStoreProvider': ftpHostKeyStoreProvider,
    'ftpProfileRepositoryProvider': ftpProfileRepositoryProvider,
    'ftpSyncControllerProvider': ftpSyncControllerProvider,
    'silexgisTokenStoreProvider': silexgisTokenStoreProvider,
    'silexgisAuthRegistryProvider': silexgisAuthRegistryProvider,
    'silexgisLocalStateProvider': silexgisLocalStateProvider,
    'silexgisServerPresenceProvider': silexgisServerPresenceProvider,
    'silexgisHeldRowsProvider': silexgisHeldRowsProvider,
    'silexgisPeopleRepositoryProvider': silexgisPeopleRepositoryProvider,
    'silexgisDocumentCatalogueProvider': silexgisDocumentCatalogueProvider,
    'documentationByteEditServiceProvider':
        documentationByteEditServiceProvider,
    'silexgisFileCopyRepositoryProvider': silexgisFileCopyRepositoryProvider,
    'silexgisServerLinksProvider': silexgisServerLinksProvider,
    'silexgisDocumentsServiceProvider': silexgisDocumentsServiceProvider,
    'silexgisPeopleServiceProvider': silexgisPeopleServiceProvider,
    'silexgisTripOriginServiceProvider': silexgisTripOriginServiceProvider,
    'silexgisDecisionsServiceProvider': silexgisDecisionsServiceProvider,
    'silexgisProfileRepositoryProvider': silexgisProfileRepositoryProvider,
    'silexgisSyncControllerProvider': silexgisSyncControllerProvider,
    'silexgisSurveyModelsProvider': silexgisSurveyModelsProvider,
    'cavePlaceRepositoryProvider': cavePlaceRepositoryProvider,
    'beaconRepositoryProvider': beaconRepositoryProvider,
    'ruuviHistoryRepositoryProvider': ruuviHistoryRepositoryProvider,
    'ruuviHistoryServiceProvider': ruuviHistoryServiceProvider,
    'placeCodeServiceProvider': placeCodeServiceProvider,
    'placeCodeBatchRunnerProvider': placeCodeBatchRunnerProvider,
    'rangeCodeGeneratorProvider': rangeCodeGeneratorProvider,
    'rasterMapRepositoryProvider': rasterMapRepositoryProvider,
    'definitionRepositoryProvider': definitionRepositoryProvider,
    'caveTripServiceProvider': caveTripServiceProvider,
    'caveDocumentImportServiceProvider': caveDocumentImportServiceProvider,
    'mediaScanCacheProvider': mediaScanCacheProvider,
    'tripMediaAccessResolverProvider': tripMediaAccessResolverProvider,
    'tripMediaImportServiceProvider': tripMediaImportServiceProvider,
    'caveTripRepositoryProvider': caveTripRepositoryProvider,
    'qrCodeLookupHandlerProvider': qrCodeLookupHandlerProvider,
    'lastLocatedPlaceProvider': lastLocatedPlaceProvider,
    'documentationRepositoryProvider': documentationRepositoryProvider,
    'mbTilesRegistryProvider': mbTilesRegistryProvider,
    'caveGeoServiceProvider': caveGeoServiceProvider,
    'placeTransferServiceProvider': placeTransferServiceProvider,
    'sessionPrefsProvider': sessionPrefsProvider,
    'networkKindProbeProvider': networkKindProbeProvider,
    'locationServiceProvider': locationServiceProvider,
    'debugModeProvider': debugModeProvider,
    'homePageRefreshProvider': homePageRefreshProvider,
    'activeTripIdProvider': activeTripIdProvider,
    'tripPausedProvider': tripPausedProvider,
    'activeTripSyncReconcilerProvider': activeTripSyncReconcilerProvider,
    'liveDatabaseSwapProvider': liveDatabaseSwapProvider,
    'databaseFileRestoreProvider': databaseFileRestoreProvider,
    'modelViewerBuilderProvider': modelViewerBuilderProvider,
    'modelViewerLoadTimeoutProvider': modelViewerLoadTimeoutProvider,
    'modelViewerAssetServerFactoryProvider':
        modelViewerAssetServerFactoryProvider,
    'placeStationMappingRepositoryProvider':
        placeStationMappingRepositoryProvider,
    'caveDefaultModelRepositoryProvider': caveDefaultModelRepositoryProvider,
    'caveModelLocatorProvider': caveModelLocatorProvider,
    'serverSurveyModelFetcherProvider': serverSurveyModelFetcherProvider,
  };

  test('every synchronous provider builds from the database and the clock', () {
    final failures = <String>[];
    for (final entry in providers.entries) {
      try {
        container.read(entry.value);
      } on Object catch (e) {
        failures.add('${entry.key}: $e');
      }
    }
    expect(failures, isEmpty);
  });

  test('the asynchronous providers resolve without an error', () async {
    final asyncProviders = <String, ProviderBase<AsyncValue<Object?>>>{
      'usersStreamProvider': usersStreamProvider,
      'cavesStreamProvider': cavesStreamProvider,
      'silexgisProfilesProvider': silexgisProfilesProvider,
    };
    for (final entry in asyncProviders.entries) {
      final sub = container.listen(entry.value, (_, _) {});
      addTearDown(sub.close);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(sub.read().hasError, isFalse, reason: entry.key);
    }
  });

  test('every provider declared in the provider files is covered here', () {
    final declared = <String>{};
    for (final file in [
      'lib/providers/providers.dart',
      'lib/providers/model_viewer_providers.dart',
      'lib/providers/database_swap_providers.dart',
      'lib/providers/active_trip_reconciler_provider.dart',
    ]) {
      for (final m in RegExp(
        r'^final (\w+Provider)\b',
        multiLine: true,
      ).allMatches(File(file).readAsStringSync())) {
        declared.add(m[1]!);
      }
    }
    declared.removeAll(_notReadHere.keys);
    final thisFile = File('test/providers/provider_wiring_test.dart');
    final text = thisFile.readAsStringSync();
    final missing = [
      for (final name in declared)
        if (!text.contains("'$name'")) name,
    ];
    expect(missing, isEmpty, reason: 'add them to the lists above');
  });

  test('the coordinate format and the model viewer settings persist', () async {
    expect(
      await container.read(coordinateFormatProvider.future),
      CoordinateDisplayFormat.decimal,
    );
    await container
        .read(coordinateFormatProvider.notifier)
        .set(CoordinateDisplayFormat.dms);

    final reader = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(reader.dispose);
    expect(
      await reader.read(coordinateFormatProvider.future),
      CoordinateDisplayFormat.dms,
    );

    final settings = await container.read(modelViewerSettingsProvider.future);
    final changed = settings.copyWith(
      markColourByArea: !settings.markColourByArea,
    );
    await container.read(modelViewerSettingsProvider.notifier).set(changed);
    expect(
      (await reader.read(modelViewerSettingsProvider.future)).toJson(),
      changed.toJson(),
    );
  });
}
