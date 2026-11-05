import 'dart:io';

import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/data_archive_service.dart';
import 'package:speleoloc/services/database_restore_helper.dart';
import 'package:speleoloc/services/database_swap/live_database_swap.dart';
import 'package:speleoloc/services/device_preferences_carry_over.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_registry.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_sign_in_carry_over.dart';
import 'package:speleoloc/services/user_identity/user_handover.dart';

/// Replaces the live database with a database file the caver picked, keeping
/// this device's identity, signed-in user and own settings.
class DatabaseFileRestore {
  DatabaseFileRestore({
    required LiveDatabaseSwap swap,
    required SilexgisRefreshTokenStore silexgisTokens,
    SilexgisAuthRegistry? silexgisSignIns,
    ForgetFtpProfileSecrets? adoptFtpProfiles,
  }) : _swap = swap,
       _silexgisTokens = silexgisTokens,
       _silexgisSignIns = silexgisSignIns,
       _adoptFtpProfiles = adoptFtpProfiles;

  final LiveDatabaseSwap _swap;
  final SilexgisRefreshTokenStore _silexgisTokens;
  final SilexgisAuthRegistry? _silexgisSignIns;
  final ForgetFtpProfileSecrets? _adoptFtpProfiles;

  /// Throws, with the live database unchanged and open, when [picked] is not
  /// a sound database of this app or of an older version, when a sync run is
  /// in progress, or when any step after the swap fails. The caller restarts
  /// the app after a successful restore.
  Future<void> restoreFrom(File picked) async {
    _swap.ensureNoSyncRunning();
    final live = appDatabase;
    final configs = ConfigurationRepository(live);
    final savedDeviceUuid = await configs.readString('device_uuid');
    final copyUuidFromFile = DataArchiveService.copiesDeviceUuidFromArchive(
      await configs.readString('archive_sync_import_export_config'),
    );
    final userHandover = await UserHandoverStore(live).capture();
    final devicePreferences = await DevicePreferencesCarryOver.capture(live);
    final silexgisSignIns = await SilexgisSignInCarryOver.capture(
      live,
      _silexgisTokens,
    );

    await _swap.replaceWith(
      picked,
      afterOpen: (db) async {
        DatabaseRestoreHelper.logMigrationIfAny(
          source: 'external-database-restore',
        );
        // This device keeps its own UUID unless the setting says to adopt
        // the restored file's.
        if (!copyUuidFromFile &&
            savedDeviceUuid != null &&
            savedDeviceUuid.isNotEmpty) {
          await ConfigurationRepository(
            db,
          ).writeString('device_uuid', savedDeviceUuid);
        }
        await UserHandoverStore(db).handOver(userHandover);
        await devicePreferences.applyTo(
          db,
          adoptFtpProfiles: _adoptFtpProfiles,
        );
        await silexgisSignIns.applyTo(
          db,
          _silexgisTokens,
          signIns: _silexgisSignIns,
        );
      },
    );
  }
}
