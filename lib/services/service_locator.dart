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
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/repository_interfaces.dart';

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
IRasterMapRepository get rasterMapRepository =>
    rootContainer.read(rasterMapRepositoryProvider);
IDefinitionRepository get definitionRepository =>
    rootContainer.read(definitionRepositoryProvider);
