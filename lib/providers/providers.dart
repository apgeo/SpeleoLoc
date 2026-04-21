import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_place_repository.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/definition_repository.dart';
import 'package:speleoloc/services/raster_map_repository.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
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
  (ref) => CaveRepository(ref.watch(appDatabaseProvider)),
);

final cavePlaceRepositoryProvider = Provider<ICavePlaceRepository>(
  (ref) => CavePlaceRepository(ref.watch(appDatabaseProvider)),
);

final rasterMapRepositoryProvider = Provider<IRasterMapRepository>(
  (ref) => RasterMapRepository(ref.watch(appDatabaseProvider)),
);

final definitionRepositoryProvider = Provider<IDefinitionRepository>(
  (ref) => DefinitionRepository(ref.watch(appDatabaseProvider)),
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
    StreamProvider.family<List<CavePlace>, int>((ref, caveId) {
  return ref.watch(cavePlaceRepositoryProvider).watchCavePlaces(caveId);
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

final activeTripIdProvider = ChangeNotifierProvider<ValueNotifier<int?>>(
  (ref) => ref.watch(caveTripServiceProvider).activeTripIdNotifier,
);

final tripPausedProvider = ChangeNotifierProvider<ValueNotifier<bool>>(
  (ref) => ref.watch(caveTripServiceProvider).isPausedNotifier,
);
