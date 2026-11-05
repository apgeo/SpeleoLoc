import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_model/cave_default_model_repository.dart';
import 'package:speleoloc/services/cave_model/cave_model_locator.dart';
import 'package:speleoloc/services/cave_model/current_survey_models.dart';
import 'package:speleoloc/services/cave_model/model_viewer_asset_server.dart';
import 'package:speleoloc/services/cave_model/place_station_mapping_repository.dart';
import 'package:speleoloc/services/cave_model/survey_model_format.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/silexgis_session.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_download_service.dart';
import 'package:speleoloc/widgets/model_viewer/caveview_web_view.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_builder.dart';

/// Builds the platform's 3D viewer, or null where it has no WebView (the
/// Linux desktop build).
final modelViewerBuilderProvider = Provider<ModelViewerBuilder?>((ref) {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;
  return ({required pageUri, required controller, required onEvent}) =>
      CaveViewWebView(
        pageUri: pageUri,
        controller: controller,
        onEvent: onEvent,
      );
});

/// How long the page may take to draw the model before the screen gives up
/// and offers a retry. Parsing a large model on a phone is slow, hence long.
final modelViewerLoadTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 90),
);

typedef ModelViewerAssetServerFactory =
    ModelViewerAssetServer Function(File modelFile, SurveyModelFormat format);

final modelViewerAssetServerFactoryProvider =
    Provider<ModelViewerAssetServerFactory>((ref) {
      // rootBundle.load throws an Error for a key it does not bundle, which
      // the server must not catch; the manifest says beforehand.
      final manifest = AssetManifest.loadFromAssetBundle(rootBundle);
      Future<ByteData?> load(String key) async {
        if (!(await manifest).listAssets().contains(key)) return null;
        return rootBundle.load(key);
      }

      return (modelFile, format) => ModelViewerAssetServer(
        loadAsset: load,
        modelFile: modelFile,
        format: format,
      );
    });

final placeStationMappingRepositoryProvider =
    Provider<IPlaceStationMappingRepository>(
      (ref) => PlaceStationMappingRepository(
        ref.watch(appDatabaseProvider),
        ref.watch(currentUserServiceProvider),
        ref.watch(changeLoggerProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final caveDefaultModelRepositoryProvider =
    Provider<ICaveDefaultModelRepository>(
      (ref) => CaveDefaultModelRepository(
        ref.watch(appDatabaseProvider),
        ref.watch(currentUserServiceProvider),
        ref.watch(changeLoggerProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final caveModelLocatorProvider = Provider<CaveModelLocator>(
  (ref) => CaveModelLocator(
    ref.watch(documentationRepositoryProvider),
    ref.watch(caveDefaultModelRepositoryProvider),
    ref.watch(placeStationMappingRepositoryProvider),
    ref.watch(cavePlaceRepositoryProvider),
    server: ref.watch(silexgisSurveyModelsProvider),
  ),
);

/// The survey models attached to a cave, read afresh each time a screen
/// that offers the 3D viewer is built.
final caveModelsProvider = FutureProvider.autoDispose
    .family<List<DocumentationFile>, Uuid>(
      (ref, caveUuid) => ref.watch(caveModelLocatorProvider).modelsOf(caveUuid),
    );

/// A cave's models on a server whose file is not on this device, read afresh
/// each time the viewer's model list is opened.
final caveServerModelsProvider = FutureProvider.autoDispose
    .family<List<ServerSurveyModel>, Uuid>(
      (ref, caveUuid) =>
          ref.watch(silexgisSurveyModelsProvider).notHeld(caveUuid),
    );

/// Fetches a server model when the caver asks for it.
final serverSurveyModelFetcherProvider = Provider<ServerSurveyModelFetcher>((
  ref,
) {
  final signIns = ref.watch(silexgisAuthRegistryProvider);
  return SilexgisSurveyModelDownloadService(
    db: ref.watch(appDatabaseProvider),
    logger: ref.watch(changeLoggerProvider),
    profiles: ref.watch(silexgisProfileRepositoryProvider),
    localState: ref.watch(silexgisLocalStateProvider),
    models: ref.watch(silexgisSurveyModelsProvider),
    copies: ref.watch(silexgisFileCopyRepositoryProvider),
    sessionBuilder: (profile) => SilexgisSession.signedIn(profile, signIns),
    baseDir: getApplicationDocumentsDirectory,
  );
});
