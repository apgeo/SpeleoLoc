import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:speleoloc/data/source/database/app_database.dart';

/// Shared helper for loading and saving JSON-based configuration values
/// stored in the `configurations` table.
///
/// All settings pages should use these functions instead of duplicating
/// the upsert / read logic.
class SettingsHelper {
  const SettingsHelper._();

  // ---------------------------------------------------------------------------
  // Generic JSON config (stored as a JSON-encoded string in `value` column)
  // ---------------------------------------------------------------------------

  /// Load a JSON config map for the given [configKey].
  /// Returns [defaultConfig] when no row exists or parsing fails.
  static Future<Map<String, dynamic>> loadJsonConfig(
    String configKey,
    Map<String, dynamic> Function() defaultConfig,
  ) async {
    final row = await (appDatabase.select(appDatabase.configurations)
          ..where((c) => c.title.equals(configKey)))
        .getSingleOrNull();
    if (row == null) return defaultConfig();
    try {
      return jsonDecode(row.value ?? '{}') as Map<String, dynamic>;
    } catch (_) {
      return defaultConfig();
    }
  }

  /// Persist a JSON config map under the given [configKey] (upsert).
  static Future<void> saveJsonConfig(
    String configKey,
    Map<String, dynamic> cfg,
  ) async {
    final existing = await (appDatabase.select(appDatabase.configurations)
          ..where((c) => c.title.equals(configKey)))
        .getSingleOrNull();
    final jsonStr = jsonEncode(cfg);
    if (existing == null) {
      await appDatabase.into(appDatabase.configurations).insert(
          ConfigurationsCompanion.insert(
              title: configKey, value: drift.Value(jsonStr)));
    } else {
      await appDatabase.update(appDatabase.configurations).replace(
          Configuration(id: existing.id, title: configKey, value: jsonStr));
    }
  }

  // ---------------------------------------------------------------------------
  // Plain string config (single scalar value — e.g. language code, output kind)
  // ---------------------------------------------------------------------------

  /// Load a plain string value for the given [configKey].
  /// Returns [defaultValue] when no row exists.
  static Future<String> loadStringConfig(
    String configKey, [
    String defaultValue = '',
  ]) async {
    final row = await (appDatabase.select(appDatabase.configurations)
          ..where((c) => c.title.equals(configKey)))
        .getSingleOrNull();
    return row?.value ?? defaultValue;
  }

  /// Persist a plain string value under the given [configKey] (upsert).
  static Future<void> saveStringConfig(
    String configKey,
    String value,
  ) async {
    final existing = await (appDatabase.select(appDatabase.configurations)
          ..where((c) => c.title.equals(configKey)))
        .getSingleOrNull();
    if (existing == null) {
      await appDatabase.into(appDatabase.configurations).insert(
          ConfigurationsCompanion.insert(
              title: configKey, value: drift.Value(value)));
    } else {
      await appDatabase.update(appDatabase.configurations).replace(
          Configuration(id: existing.id, title: configKey, value: value));
    }
  }
}
