import 'dart:convert';

import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Persists the configured SilexGIS installations.
///
/// The same split the FTP profiles use, and for the same reason: metadata in
/// the `configurations` table, which is local to the device and already holds
/// the entire caving dataset, and the credential in the platform keystore. It
/// follows that *pattern* without joining that machinery — a SilexGIS profile
/// is its own configuration key, and no value of the FTP protocol enum ever
/// stands for one.
///
/// Thin on purpose, like its FTP counterpart: no caching and no change
/// streams. The settings UI reads on open and writes on an explicit action.
class SilexgisProfileRepository {
  SilexgisProfileRepository(this._configs, this._tokens, this._localState);

  final IConfigurationRepository _configs;
  final SilexgisRefreshTokenStore _tokens;
  final SilexgisLocalStateRepository _localState;
  final _log = AppLogger.of('SilexgisProfileRepository');

  Future<List<SilexgisProfile>> list() async {
    final raw = await _configs.readString(ConfigKey.silexgisProfiles);
    if (raw == null || raw.isEmpty) return const <SilexgisProfile>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <SilexgisProfile>[];
      return decoded
          .whereType<Map<String, Object?>>()
          .map(SilexgisProfile.fromJson)
          .toList(growable: false);
    } on FormatException catch (e) {
      // A corrupt list must not stop the application starting: with no server
      // configured it behaves exactly as it does today, which is the case this
      // whole design exists to protect.
      _log.warning('Stored SilexGIS profiles could not be decoded: $e');
      return const <SilexgisProfile>[];
    }
  }

  Future<SilexgisProfile?> find(String profileUuid) async {
    for (final profile in await list()) {
      if (profile.profileUuid == profileUuid) return profile;
    }
    return null;
  }

  Future<void> save(SilexgisProfile profile) async {
    final current = await list();
    final updated = <SilexgisProfile>[
      for (final existing in current)
        if (existing.profileUuid != profile.profileUuid) existing,
    ];
    updated.add(profile);
    await _write(updated);
    if (updated.length == 1) {
      await setDefaultUuid(profile.profileUuid);
    }
  }

  /// Removes a profile, its stored credential, and everything this device
  /// remembered about its conversation with that installation.
  ///
  /// The cursor and the row revisions go with it: they are readable only by
  /// the installation that issued them, and a position kept for a server this
  /// device no longer talks to is at best dead weight and at worst something
  /// to be sent back after the account changed.
  Future<void> delete(String profileUuid) async {
    final updated = <SilexgisProfile>[
      for (final existing in await list())
        if (existing.profileUuid != profileUuid) existing,
    ];
    await _write(updated);
    await _tokens.delete(profileUuid);
    await _localState.forgetProfile(profileUuid);

    if (await getDefaultUuid() == profileUuid) {
      if (updated.isEmpty) {
        await _configs.delete(ConfigKey.silexgisDefaultProfileUuid);
      } else {
        await setDefaultUuid(updated.first.profileUuid);
      }
    }
  }

  Future<String?> getDefaultUuid() =>
      _configs.readString(ConfigKey.silexgisDefaultProfileUuid);

  Future<void> setDefaultUuid(String profileUuid) =>
      _configs.writeString(ConfigKey.silexgisDefaultProfileUuid, profileUuid);

  /// The profile a one-tap sync uses, or null when none is configured — which
  /// is not an error and is the ordinary case.
  Future<SilexgisProfile?> getDefaultProfile() async {
    final uuid = await getDefaultUuid();
    if (uuid == null) return null;
    return find(uuid);
  }

  Future<void> _write(List<SilexgisProfile> profiles) => _configs.writeString(
    ConfigKey.silexgisProfiles,
    jsonEncode(profiles.map((p) => p.toJson()).toList(growable: false)),
  );
}
