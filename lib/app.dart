import 'package:flutter/material.dart';
import 'package:speleoloc/screens/home_page.dart';
import 'package:speleoloc/screens/cave_places_list_page.dart';
import 'package:speleoloc/screens/cave_place_page.dart';
import 'package:speleoloc/screens/cave_trip_page.dart';
import 'package:speleoloc/screens/cave_trip_list_page.dart';
import 'package:speleoloc/screens/cave_trip_log_page.dart';
import 'package:speleoloc/screens/trip_report_templates_page.dart';
import 'package:speleoloc/screens/map_viewer_page.dart';
import 'package:speleoloc/screens/general_data/raster_maps_page.dart';
import 'package:speleoloc/screens/settings/settings_main_page.dart';
import 'package:speleoloc/utils/app_routes.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/deep_link_handler.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/navigator_key.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';
import 'package:speleoloc/utils/uuid.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;

class SpeleoLocApp extends StatefulWidget {
  const SpeleoLocApp({super.key});

  @override
  State<SpeleoLocApp> createState() => _SpeleoLocAppState();
}

class _SpeleoLocAppState extends State<SpeleoLocApp> {
  @override
  void initState() {
    super.initState();
    DeepLinkHandler.instance.init(navigatorKey);
  }

  @override
  void dispose() {
    DeepLinkHandler.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PR 9: derive Material's supportedLocales from the loaded LocServ
    // bundles (which come from `assets/i18n/*.json`) rather than the old
    // hard-coded `[Locale('en')]`. This makes Material/Cupertino/Quill
    // framework widgets pick up date/time and form labels in the user's
    // language whenever a matching bundle ships in the app. `LocServ`
    // returns BCP-47 language tags like `en` / `fr` / `pt_BR`; split on
    // `_` so the latter maps to `Locale('pt', 'BR')`. Falls back to
    // `[Locale('en')]` if LocServ failed to load any bundles (e.g. asset
    // bundle missing in a test harness) so the app still boots.
    final loaded = LocServ.inst.supportedLocales();
    final supported = loaded.isEmpty
        ? const <Locale>[Locale('en')]
        : loaded.map((code) {
            final parts = code.split('_');
            return parts.length == 2
                ? Locale(parts[0], parts[1])
                : Locale(parts[0]);
          }).toList(growable: false);
    return MaterialApp(
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supported,
      title: appName,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
      ),
      initialRoute: homeRoute,
      // PR 9 follow-up: use `onGenerateRoute` instead of `routes:` so each
      // route is built as a `MaterialPageRoute<T>` whose `T` matches what
      // the page actually pops. The `routes:` map always produces
      // `MaterialPageRoute<dynamic>`, which makes `Navigator.pushNamed<T>`
      // throw `MaterialPageRoute<dynamic> is not a subtype of Route<T?>?`
      // for any non-dynamic `T` (see `AppRoutes.pushCave`/`pushCavePlace`
      // call sites that await a `bool` result).
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case homeRoute:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const HomePage(title: appName),
            );
          case caveRoute:
            final args = settings.arguments as Uuid?;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => CavePlacesListPage(caveUuid: args ?? Uuid.zero),
            );
          case cavePlaceRoute:
            final args = settings.arguments as CavePlaceRouteArgs?;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => CavePlacePage(
                caveUuid: args?.caveUuid ?? Uuid.zero,
                cavePlaceUuid: args?.cavePlaceUuid,
              ),
            );
          case cavePlaceViewRoute:
            final args = settings.arguments as CavePlaceViewRouteArgs?;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => MapViewerPage(
                cavePlaceUuid: args?.cavePlaceUuid ?? Uuid.zero,
                caveUuid: args?.caveUuid,
                initialRasterMapUuid: args?.initialRasterMapUuid,
              ),
            );
          case rasterMapsRoute:
            final args = settings.arguments as Uuid?;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => RasterMapsPage(caveUuid: args ?? Uuid.zero),
            );
          case settingsRoute:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const SettingsMainPage(),
            );
          case caveTripRoute:
            final args = settings.arguments as Uuid?;
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => CaveTripPage(tripUuid: args ?? Uuid.zero),
            );
          case caveTripListRoute:
            final args = settings.arguments as Uuid?;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => CaveTripListPage(caveUuid: args ?? Uuid.zero),
            );
          case caveTripLogRoute:
            final args = settings.arguments as Uuid?;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => CaveTripLogPage(tripUuid: args ?? Uuid.zero),
            );
          case tripReportTemplatesRoute:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const TripReportTemplatesPage(),
            );
        }
        return null;
      },
      builder: (context, child) => Stack(
        children: [SizedBox.expand(child: child!), const AppToastHost()],
      ),
    );
  }
}