import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/app.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/document_format_registry.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/app_start_counter.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize unified logging facade before anything else emits output.
  AppLogger.init();

  // Create the root Riverpod container. The same instance is shared with the
  // widget tree via `UncontrolledProviderScope`, and with imperative services
  // (e.g. [CaveTripService]) via [rootContainer] from service_locator.dart.
  final container = ProviderContainer();
  initRootContainer(container);

  // Register built-in document format handlers (editors & viewers).
  registerBuiltInDocumentFormats();

  // Track application start count.
  await AppStartCounter.increment();

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
        st);
  }

  // Load persisted menu mode preference (popup vs drawer).
  await initAppMenuMode();

  await container.read(caveTripServiceProvider).initActiveTrip();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SpeleoLocApp(),
    ),
  );
}