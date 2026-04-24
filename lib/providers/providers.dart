import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/definition_repository.dart';
import 'package:speleoloc/services/raster_map_repository.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/services/sync/ftp/ftp_sync_controller.dart';
import 'package:speleoloc/services/user_repository.dart';
import 'package:speleoloc/state/app_notifiers.dart';

/// Central place that wires all app-wide dependencies via Riverpod.
///
/// Every concrete dependency (database, repositories, services) is exposed as
/// a `Provider<Interface>` so tests can override wholesale via
/// `ProviderScope(overrides: [...])` without touching production wiring.

/// The single [AppDatabase] instance.
///
/// During the migration away from the legacy global `appDatabase`, this
/// provider returns the same instance. Tests override with an in-memory DB.
final appDatabaseProvider = Provider<AppDatabase>((ref) => appDatabase);

final caveRepositoryProvider = Provider<ICaveRepository>(
  (ref) => CaveRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(currentUserServiceProvider),
    ref.watch(changeLoggerProvider),
  ),
);

final userRepositoryProvider = Provider<IUserRepository>(_buildUserRepository);

IUserRepository _buildUserRepository(Ref ref) => UserRepository(
      ref.watch(appDatabaseProvider),
      () => ref.read(changeLoggerProvider),
    );

final currentUserServiceProvider = Provider<CurrentUserService>((ref) {
  final svc = CurrentUserService(
    ref.watch(appDatabaseProvider),
    ref.watch(userRepositoryProvider),
  );
  // Fire-and-forget init; readers that need the values before init finishes
  // should await `svc.initialize()` themselves.
  svc.initialize();
  return svc;
});

final changeLoggerProvider = Provider<ChangeLogger>(
  (ref) => ChangeLogger(
    ref.watch(appDatabaseProvider),
    ref.watch(currentUserServiceProvider),
  ),
);

final syncArchiveServiceProvider = Provider<SyncArchiveService>(
  (ref) => SyncArchiveService(
    ref.watch(appDatabaseProvider),
    ref.watch(changeLoggerProvider),
  ),
);

/// Stores configured FTP/SFTP endpoints plus their passwords (passwords are
/// kept in the OS keystore, not in the SQLite DB).
final ftpProfileRepositoryProvider = Provider<FtpProfileRepository>(
  (ref) => FtpProfileRepository(ref.watch(appDatabaseProvider)),
);

/// Singleton orchestrator for one-tap FTP sync. Exposed as a ChangeNotifier
/// so UI can react to live progress via `ref.watch(...).progress`.
final ftpSyncControllerProvider = ChangeNotifierProvider<FtpSyncController>(
  (ref) => FtpSyncController(
    db: ref.watch(appDatabaseProvider),
    profileRepository: ref.watch(ftpProfileRepositoryProvider),
    archiveService: ref.watch(syncArchiveServiceProvider),
    currentUserService: ref.watch(currentUserServiceProvider),
  ),
);

final usersStreamProvider = StreamProvider<List<User>>((ref) {
  return ref.watch(userRepositoryProvider).watchUsers();
});

final cavePlaceRepositoryProvider = Provider<ICavePlaceRepository>(
  (ref) => CavePlaceRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(currentUserServiceProvider),
    ref.watch(changeLoggerProvider),
  ),
);

final rasterMapRepositoryProvider = Provider<IRasterMapRepository>(
  (ref) => RasterMapRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(currentUserServiceProvider),
    ref.watch(changeLoggerProvider),
  ),
);

final definitionRepositoryProvider = Provider<IDefinitionRepository>(
  (ref) => DefinitionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(currentUserServiceProvider),
    ref.watch(changeLoggerProvider),
  ),
);

final caveTripServiceProvider = Provider<CaveTripService>(
  (ref) => CaveTripService.instance,
);

/// Session-level preferences that persist for the lifetime of the app process.
class SessionPrefs {
  SessionPrefs._();
  static final SessionPrefs instance = SessionPrefs._();

  /// User has confirmed auto-save when switching map/place.
  /// Resets on app restart.
  bool autoSaveConfirmed = false;

  void reset() {
    autoSaveConfirmed = false;
  }
}

final sessionPrefsProvider = Provider<SessionPrefs>((ref) => SessionPrefs.instance);

// -----------------------------------------------------------------------------
// Stream providers — reactive list of rows backed by Drift `.watch()`.
// -----------------------------------------------------------------------------

/// Live stream of all caves. Emits on any write to the `caves` table.
final cavesStreamProvider = StreamProvider<List<Cave>>((ref) {
  return ref.watch(caveRepositoryProvider).watchCaves();
});

/// Live stream of cave places filtered by cave id.
final cavePlacesStreamProvider =
    StreamProvider.family<List<CavePlace>, Uuid>((ref, caveUuid) {
  return ref.watch(cavePlaceRepositoryProvider).watchCavePlaces(caveUuid);
});

// -----------------------------------------------------------------------------
// Global UI-state notifiers exposed as Riverpod providers.
// The underlying [ValueNotifier] instances in `lib/state/app_notifiers.dart`
// remain the source of truth during the migration. These providers surface
// the current value and rebuild consumers on change.
// -----------------------------------------------------------------------------

final debugModeProvider = ChangeNotifierProvider<ValueNotifier<bool>>(
  (ref) => debugModeNotifier,
);

final homePageRefreshProvider = ChangeNotifierProvider<ValueNotifier<int>>(
  (ref) => homePageRefreshNotifier,
);

final activeTripIdProvider = ChangeNotifierProvider<ValueNotifier<Uuid?>>(
  (ref) => ref.watch(caveTripServiceProvider).activeTripIdNotifier,
);

final tripPausedProvider = ChangeNotifierProvider<ValueNotifier<bool>>(
  (ref) => ref.watch(caveTripServiceProvider).isPausedNotifier,
);
