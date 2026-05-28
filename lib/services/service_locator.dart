/// Legacy global accessors, kept during the Phase 1 → Phase 3 migration.
///
/// New code should depend on the matching Riverpod provider from
/// [lib/providers/providers.dart](providers.dart) via `ref.read`/`ref.watch`.
/// These top-level accessors are a stop-gap so imperative services and
/// non-widget code (e.g. [CaveTripService.instance]) can still reach
/// repositories during migration. They resolve against the root
/// [ProviderContainer] created in `main.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/place_code/place_code_service.dart';
import 'package:speleoloc/services/place_code/batch/place_code_batch_runner.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/user_repository.dart';

// Re-export SessionPrefs so callers importing this file keep working.
export 'package:speleoloc/providers/providers.dart' show SessionPrefs;

/// Root [ProviderContainer] assigned once in `main.dart` and shared with the
/// widget tree via `UncontrolledProviderScope`. Throws if accessed before
/// [initRootContainer] has run.
ProviderContainer get rootContainer {
  final c = _rootContainer;
  if (c == null) {
    throw StateError(
      'rootContainer accessed before initRootContainer() was called.',
    );
  }
  return c;
}

ProviderContainer? _rootContainer;

void initRootContainer(ProviderContainer container) {
  _rootContainer = container;
}

// Convenience shortcuts matching the previous `service_locator.dart` globals.
// Prefer `ref.read(xxxProvider)` inside widgets; use these only in code that
// has no access to a `Ref`.
ICaveRepository get caveRepository =>
    rootContainer.read(caveRepositoryProvider);
ICavePlaceRepository get cavePlaceRepository =>
    rootContainer.read(cavePlaceRepositoryProvider);
PlaceCodeService get placeCodeService =>
    rootContainer.read(placeCodeServiceProvider);
PlaceCodeBatchRunner get placeCodeBatchRunner =>
    rootContainer.read(placeCodeBatchRunnerProvider);
IRasterMapRepository get rasterMapRepository =>
    rootContainer.read(rasterMapRepositoryProvider);
IDefinitionRepository get definitionRepository =>
    rootContainer.read(definitionRepositoryProvider);
IUserRepository get userRepository =>
    rootContainer.read(userRepositoryProvider);
CurrentUserService get currentUserService =>
    rootContainer.read(currentUserServiceProvider);

/// Configuration repository accessor with a test-friendly fallback.
///
/// Most callers go through the provider; widget tests that pump
/// [SpeleoLocApp] directly (without an [UncontrolledProviderScope]) cannot
/// resolve through [rootContainer]. To preserve the pre-PR-1 behaviour for
/// those tests — and any imperative bootstrap code that runs before
/// [initRootContainer] — fall back to a fresh repository backed by the
/// global [appDatabase]. Both code paths target the same database, so
/// behaviour is observationally identical.
IConfigurationRepository get configurationRepository {
  final c = _rootContainer;
  if (c == null) return ConfigurationRepository(appDatabase);
  return c.read(configurationRepositoryProvider);
}
ChangeLogger get changeLogger => rootContainer.read(changeLoggerProvider);
