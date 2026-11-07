import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:speleoloc/app.dart';
import 'package:speleoloc/app_bootstrap.dart';
import 'package:speleoloc/providers/active_trip_reconciler_provider.dart';
import 'package:speleoloc/providers/database_swap_providers.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/documents/document_format_registry.dart';
import 'package:speleoloc/services/database_swap/live_database_swap.dart';
import 'package:speleoloc/services/database_swap/set_aside_database_pruner.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/startup/startup_recovery.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_seed.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/app_start_counter.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

// DSN is injected at build time: --dart-define=SENTRY_DSN=https://...
// An empty DSN means Sentry.init is a no-op, so debug/CI builds without
// a DSN work normally without any changes here.
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

void main() async {
  const sentryDsn = _sentryDsn;

  await SentryFlutter.init((options) {
    options.dsn = sentryDsn;
    // Only capture events in release builds to avoid noise during development.
    options.environment = kReleaseMode ? 'production' : 'development';
    options.tracesSampleRate = kReleaseMode ? 0.2 : 0.0;
  }, appRunner: () => _runApp());
}

Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize unified logging facade before anything else emits output.
  // The AppLogger listener forwards WARNING+ records to Sentry automatically.
  AppLogger.init();

  // A release built without a DSN ships with no crash reporting at all —
  // surface the omission in the device log so it gets noticed.
  if (kReleaseMode && _sentryDsn.isEmpty) {
    AppLogger.of(
      'Main',
    ).warning('SENTRY_DSN is empty: crash reporting is disabled');
  }

  // Create the root Riverpod container. The same instance is shared with the
  // widget tree via `UncontrolledProviderScope`, and with imperative services
  // (e.g. [CaveTripService]) via [rootContainer] from service_locator.dart.
  final container = ProviderContainer();
  initRootContainer(container);

  // Register built-in document format handlers (editors & viewers).
  registerBuiltInDocumentFormats();

  final swap = container.read(liveDatabaseSwapProvider);
  await startApp(
    start: () => _startServices(container, swap),
    prepareRetry: swap.reopenLiveDatabase,
    recovery: DatabaseStartupRecovery(swap),
    app: () => UncontrolledProviderScope(
      container: container,
      child: const SpeleoLocApp(),
    ),
  );
}

/// Everything that must be ready before the first screen. Any step may
/// throw; [startApp] then shows the start-up failure screen.
Future<void> _startServices(
  ProviderContainer container,
  LiveDatabaseSwap swap,
) async {
  // Before anything opens the database: a swap cut short by a kill left the
  // caver's previous database aside, and it goes back now.
  await swap.recoverInterruptedSwap();
  // Only after the recovery, which may have set a copy aside just now.
  await const SetAsideDatabasePruner().prune(await swap.liveDatabaseFile());

  // Track application start count. Only statistics: a full disk must not
  // stop the app over it.
  try {
    await AppStartCounter.increment();
  } catch (e, st) {
    AppLogger.of('Main').warning('Start count could not be saved', e, st);
  }

  // Load localization strings from JSON assets.
  await LocServ.inst.load();

  // Load saved language preference before building the widget tree (#14, #25)
  try {
    final lang = await container
        .read(configurationRepositoryProvider)
        .readString(appLanguageKey);
    if (lang != null && lang.isNotEmpty) {
      await LocServ.inst.setLocale(lang);
    }
  } catch (e, st) {
    // DB not ready yet — use default locale
    AppLogger.of('Main').warning(
      'Saved language preference could not be loaded; using default locale',
      e,
      st,
    );
  }

  // Load persisted menu mode preference (popup vs drawer).
  await initAppMenuMode();

  // Ensure device + current-user identity is loaded before anything can
  // record a change_log row (attribution + device filtering depend on it).
  // The provider kicks this off fire-and-forget; awaiting the same cached
  // future here guarantees it has actually finished.
  await container.read(currentUserServiceProvider).initialize();

  await container.read(caveTripServiceProvider).initActiveTrip();
  container.read(activeTripSyncReconcilerProvider);

  // Builds that bake in a shared sync endpoint install it here; a build
  // without one does nothing. Failure must not block startup — the user can
  // always configure the endpoint by hand.
  try {
    await ensureSeededFtpProfile(container.read(ftpProfileRepositoryProvider));
  } catch (e, st) {
    AppLogger.of(
      'Main',
    ).warning('Seeding the built-in FTP profile failed', e, st);
  }
}
