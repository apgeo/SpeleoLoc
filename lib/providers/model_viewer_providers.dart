import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/services/cave_model/model_viewer_asset_server.dart';
import 'package:speleoloc/services/cave_model/survey_model_format.dart';
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
