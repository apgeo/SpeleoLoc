import 'package:speleoloc/services/service_locator.dart';

/// Thin static facade over [IConfigurationRepository] kept for source
/// compatibility with the (many) existing call sites in settings pages.
///
/// New code should depend on `configurationRepositoryProvider` directly via
/// Riverpod. This facade defers to the root container's instance, so tests
/// can override the provider without touching SettingsHelper itself.
class SettingsHelper {
  const SettingsHelper._();

  /// Load a JSON config map for the given [configKey].
  /// Returns [defaultConfig] when no row exists or parsing fails.
  static Future<Map<String, dynamic>> loadJsonConfig(
    String configKey,
    Map<String, dynamic> Function() defaultConfig,
  ) =>
      configurationRepository.readJson(configKey, defaults: defaultConfig);

  /// Persist a JSON config map under the given [configKey] (upsert).
  ///
  /// [isSynced] controls whether a newly-inserted row participates in
  /// archive/FTP sync. For existing rows the `is_synced` flag is preserved
  /// (see [IConfigurationRepository.writeString]).
  static Future<void> saveJsonConfig(
    String configKey,
    Map<String, dynamic> cfg, {
    bool isSynced = false,
  }) =>
      configurationRepository.writeJson(configKey, cfg, isSynced: isSynced);

  /// Load a plain string value for the given [configKey].
  /// Returns [defaultValue] when no row exists.
  static Future<String> loadStringConfig(
    String configKey, [
    String defaultValue = '',
  ]) async {
    final value = await configurationRepository.readString(configKey);
    return value ?? defaultValue;
  }

  /// Persist a plain string value under the given [configKey] (upsert).
  /// See [saveJsonConfig] for [isSynced] semantics.
  static Future<void> saveStringConfig(
    String configKey,
    String value, {
    bool isSynced = false,
  }) =>
      configurationRepository.writeString(configKey, value, isSynced: isSynced);
}
