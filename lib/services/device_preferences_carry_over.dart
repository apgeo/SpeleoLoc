import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/constants.dart';

/// Keeps the preferences of the person holding this device across a
/// replace of the whole database file.
///
/// A replaced database brings the exporter's own preferences: the sample
/// archive offered on first start carries its author's language, which
/// switched a fresh English store build to Romanian. Each key here keeps
/// this device's value, or is removed when this device never set one, so
/// the build's default applies.
class DevicePreferencesCarryOver {
  DevicePreferencesCarryOver._(this._values);

  static const List<String> keys = [appLanguageKey];

  final Map<String, String?> _values;

  static Future<DevicePreferencesCarryOver> capture(AppDatabase db) async {
    final configs = ConfigurationRepository(db);
    return DevicePreferencesCarryOver._({
      for (final key in keys) key: await configs.readString(key),
    });
  }

  Future<void> applyTo(AppDatabase db) async {
    final configs = ConfigurationRepository(db);
    for (final MapEntry(:key, :value) in _values.entries) {
      if (value == null) {
        await configs.delete(key);
      } else {
        await configs.writeString(key, value);
      }
    }
  }
}
