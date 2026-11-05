import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/database_swap/database_file_restore.dart';
import 'package:speleoloc/services/database_swap/live_database_swap.dart';

/// The one way the app replaces its live database file.
///
/// Watches nothing built on the database: a swap invalidates those, and the
/// swap in progress must not be rebuilt under itself.
final liveDatabaseSwapProvider = Provider<LiveDatabaseSwap>(
  (ref) => LiveDatabaseSwap(
    isSyncRunning: () =>
        ref.read(ftpSyncControllerProvider).isRunning ||
        ref.read(silexgisSyncControllerProvider).isRunning,
  ),
);

final databaseFileRestoreProvider = Provider<DatabaseFileRestore>(
  (ref) => DatabaseFileRestore(
    swap: ref.watch(liveDatabaseSwapProvider),
    silexgisTokens: ref.watch(silexgisTokenStoreProvider),
    silexgisSignIns: ref.watch(silexgisAuthRegistryProvider),
    // Touches only the keystore, so the repository of whichever database is
    // open at the time will do.
    adoptFtpProfiles: (profileUuid) =>
        ref.read(ftpProfileRepositoryProvider).forgetSecrets(profileUuid),
  ),
);
