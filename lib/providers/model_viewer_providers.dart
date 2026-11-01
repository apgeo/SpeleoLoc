import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_model/cave_default_model_repository.dart';
import 'package:speleoloc/services/cave_model/cave_model_locator.dart';
import 'package:speleoloc/services/cave_model/model_viewer_asset_server.dart';
import 'package:speleoloc/services/cave_model/place_station_mapping_repository.dart';
import 'package:speleoloc/services/cave_model/survey_model_format.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
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
  ),
);

/// The survey models attached to a cave, read afresh each time a screen
/// that offers the 3D viewer is built.
final caveModelsProvider = FutureProvider.autoDispose
    .family<List<DocumentationFile>, Uuid>(
      (ref, caveUuid) => ref.watch(caveModelLocatorProvider).modelsOf(caveUuid),
    );
