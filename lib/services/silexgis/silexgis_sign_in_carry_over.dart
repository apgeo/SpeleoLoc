import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_registry.dart';

/// Keeps this device's SilexGIS sign-ins from following a replace of the
/// whole database file to another host.
///
/// Refresh tokens stay in this device's keystore keyed by profile uuid, while
/// a replaced database brings its own profile list. A database handed over
/// with this device's profile uuid next to another address would get the
/// 45-day token posted there on the next run, without ever passing through
/// [SilexgisProfileRepository.save]. So each profile this device had keeps
/// its sign-in only when the new database names the same server for it.
class SilexgisSignInCarryOver {
  SilexgisSignInCarryOver._(this._before);

  final List<SilexgisProfile> _before;
  static final _log = AppLogger.of('SilexgisSignInCarryOver');

  static Future<SilexgisSignInCarryOver> capture(
    AppDatabase db,
    SilexgisRefreshTokenStore tokens,
  ) async => SilexgisSignInCarryOver._(await _profiles(db, tokens).list());

  /// Drops the stored token of every profile the new database [db] no longer
  /// has, or has pointed at another server. A token the keystore will not
  /// let go of takes its profile out of the new list instead, so nothing can
  /// send it. The live sign-in of each such profile in [signIns] is retired
  /// first, so a refresh already on its way cannot store a token afterwards.
  Future<void> applyTo(
    AppDatabase db,
    SilexgisRefreshTokenStore tokens, {
    SilexgisAuthRegistry? signIns,
  }) async {
    final profiles = _profiles(db, tokens);
    final after = {for (final p in await profiles.list()) p.profileUuid: p};
    for (final old in _before) {
      final now = after[old.profileUuid];
      if (now != null && old.isSameServerAs(now)) continue;
      signIns?.retire(old.profileUuid);
      await tokens.delete(old.profileUuid);
      final left = await tokens.read(old.profileUuid);
      if (now != null && left != null && left.isNotEmpty) {
        _log.warning(
          'a SilexGIS sign-in could not be removed; dropping its profile',
        );
        await profiles.delete(old.profileUuid);
      }
    }
  }

  static SilexgisProfileRepository _profiles(
    AppDatabase db,
    SilexgisRefreshTokenStore tokens,
  ) => SilexgisProfileRepository(
    ConfigurationRepository(db),
    tokens,
    SilexgisLocalStateRepository(db),
  );
}
