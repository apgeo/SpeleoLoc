import 'dart:convert';

import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/constants.dart';

/// Drops every secret this device keeps under an FTP profile uuid — its
/// saved password and the SFTP host key it trusts. Throws when it cannot.
typedef ForgetFtpProfileSecrets = Future<void> Function(String profileUuid);

/// Keeps this device's own settings across a replace of the whole database
/// file.
///
/// A replaced database brings the exporter's own settings. The sample
/// archive offered on first start carries its author's language, which
/// switched a fresh English store build to Romanian. Worse, FTP passwords
/// stay in this device's keystore keyed by profile uuid, so the exporter's
/// profile list would send a saved password to whichever host that list
/// names for the same uuid. Each key here keeps this device's value, or is
/// removed when this device never set one, so the build's default applies.
///
/// Which trip this device is recording into is its own too: an archive
/// exported mid-trip would otherwise hand the exporter's trip to this device,
/// and the next scans would be recorded into it. Whether that trip is paused
/// goes with it, or the exporter's pause would stop this device recording.
/// So is beacon detection: an archive must not switch scanning on, with its
/// battery cost and automatic trip points, on a device whose caver never
/// chose it.
///
/// The one exception is a restore of the caver's own data onto a device with
/// no FTP profiles yet, such as a new phone: the archive's profiles are taken
/// so they need not be typed again. Their passwords never travel, and any
/// secret this device still holds under an incoming uuid is dropped first.
class DevicePreferencesCarryOver {
  DevicePreferencesCarryOver._(this._values);

  static const List<String> keys = [
    appLanguageKey,
    activeTripConfigKey,
    pausedTripConfigKey,
    beaconDetectionConfigKey,
    ConfigKey.ftpProfiles,
    ConfigKey.ftpDefaultProfileUuid,
  ];

  static const List<String> _ftpKeys = [
    ConfigKey.ftpProfiles,
    ConfigKey.ftpDefaultProfileUuid,
  ];

  static final _log = AppLogger.of('DevicePreferencesCarryOver');

  final Map<String, String?> _values;

  static Future<DevicePreferencesCarryOver> capture(AppDatabase db) async {
    final configs = ConfigurationRepository(db);
    return DevicePreferencesCarryOver._({
      for (final key in keys) key: await configs.readString(key),
    });
  }

  /// Pass [adoptFtpProfiles] for a restore of the caver's own data. Without
  /// it — the sample dataset, a reinitialize — this device's FTP profiles
  /// always stay, and the replacing data's are dropped.
  Future<void> applyTo(
    AppDatabase db, {
    ForgetFtpProfileSecrets? adoptFtpProfiles,
  }) async {
    final configs = ConfigurationRepository(db);
    final adopts =
        adoptFtpProfiles != null &&
        _profileUuids(_values[ConfigKey.ftpProfiles]).isEmpty;
    for (final MapEntry(:key, :value) in _values.entries) {
      if (adopts && _ftpKeys.contains(key)) continue;
      if (value == null) {
        await configs.delete(key);
      } else {
        await configs.writeString(key, value);
      }
    }
    if (adopts) await _adoptFtpProfiles(configs, adoptFtpProfiles);
  }

  /// Keeps the replacing data's profiles only once nothing of this device's
  /// can attach to them; failing that, keeps none.
  static Future<void> _adoptFtpProfiles(
    ConfigurationRepository configs,
    ForgetFtpProfileSecrets forget,
  ) async {
    final incoming = _profileUuids(
      await configs.readString(ConfigKey.ftpProfiles),
    );
    try {
      for (final uuid in incoming) {
        await forget(uuid);
      }
    } on Object catch (e, st) {
      _log.warning(
        'Could not clear stored FTP secrets; not taking the archive profiles',
        e,
        st,
      );
      for (final key in _ftpKeys) {
        await configs.delete(key);
      }
      return;
    }
    final defaultUuid = await configs.readString(
      ConfigKey.ftpDefaultProfileUuid,
    );
    if (defaultUuid != null && !incoming.contains(defaultUuid)) {
      await configs.delete(ConfigKey.ftpDefaultProfileUuid);
    }
  }

  /// The profile uuids a stored list names; an unreadable list names none,
  /// which is also how the FTP settings read it.
  static List<String> _profileUuids(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final entry in decoded)
          if (entry is Map && entry['profileUuid'] is String)
            entry['profileUuid'] as String,
      ];
    } on FormatException {
      return const [];
    }
  }
}
