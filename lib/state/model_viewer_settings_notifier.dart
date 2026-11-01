import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_model/model_viewer_settings.dart';

/// The 3D viewer's settings, backed by the `configurations` table and kept
/// on this device. Screens watch [modelViewerSettingsProvider] and use the
/// defaults while the first read is in flight.
class ModelViewerSettingsNotifier extends AsyncNotifier<ModelViewerSettings> {
  @override
  Future<ModelViewerSettings> build() async => ModelViewerSettings.fromJson(
    await ref
        .watch(configurationRepositoryProvider)
        .readJson(ModelViewerSettings.storageKey),
  );

  Future<void> set(ModelViewerSettings settings) async {
    state = AsyncData(settings);
    await ref
        .read(configurationRepositoryProvider)
        .writeJson(ModelViewerSettings.storageKey, settings.toJson());
  }
}

final modelViewerSettingsProvider =
    AsyncNotifierProvider<ModelViewerSettingsNotifier, ModelViewerSettings>(
      ModelViewerSettingsNotifier.new,
    );

/// The current settings, the defaults until they are read. Watches the
/// provider, so callers rebuild on change.
ModelViewerSettings watchModelViewerSettings(WidgetRef ref) =>
    ref.watch(modelViewerSettingsProvider).valueOrNull ??
    const ModelViewerSettings();
