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
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/deep_link_handler.dart';
import 'package:speleoloc/utils/navigator_key.dart';
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
    return MaterialApp(
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      title: appName,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
      ),
      initialRoute: homeRoute,
      routes: {
        homeRoute: (context) => const HomePage(title: appName),
        caveRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Uuid?;
          return CavePlacesListPage(caveUuid: args ?? Uuid.zero);
        },
        cavePlaceRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, Uuid?>?;
          return CavePlacePage(caveUuid: args?['caveUuid'] ?? Uuid.zero, cavePlaceUuid: args?['cavePlaceUuid']);
        },
        cavePlaceViewRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, Uuid?>?;
          return MapViewerPage(cavePlaceUuid: args?['cavePlaceUuid'] ?? Uuid.zero, caveUuid: args?['caveUuid']);
        },
        rasterMapsRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Uuid?;
          return RasterMapsPage(caveUuid: args ?? Uuid.zero);
        },
        settingsRoute: (context) => const SettingsMainPage(),
        caveTripRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Uuid?;
          return CaveTripPage(tripUuid: args ?? Uuid.zero);
        },
        caveTripListRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Uuid?;
          return CaveTripListPage(caveUuid: args ?? Uuid.zero);
        },
        caveTripLogRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Uuid?;
          return CaveTripLogPage(tripUuid: args ?? Uuid.zero);
        },
        tripReportTemplatesRoute: (context) =>
            const TripReportTemplatesPage(),
      },
    );
  }
}