import 'package:flutter/material.dart';
import 'package:speleoloc/screens/home_page.dart';
import 'package:speleoloc/screens/cave_places_list_page.dart';
import 'package:speleoloc/screens/cave_place_page.dart';
// fix import as bellow
// import 'package:speleoloc/screens/general_data/raster_maps_page.dart';
import 'screens/general_data/raster_maps_page.dart';
import 'package:speleoloc/screens/settings/settings_main_page.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/deep_link_handler.dart';

class SpeleoLocApp extends StatefulWidget {
  const SpeleoLocApp({super.key});

  @override
  State<SpeleoLocApp> createState() => _SpeleoLocAppState();
}

class _SpeleoLocAppState extends State<SpeleoLocApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    DeepLinkHandler.instance.init(_navigatorKey);
  }

  @override
  void dispose() {
    DeepLinkHandler.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
      ),
      initialRoute: homeRoute,
      routes: {
        homeRoute: (context) => const HomePage(title: appName),
        caveRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as int?;
          return CavePlacesListPage(caveId: args ?? 0);
        },
        cavePlaceRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, int>?;
          return CavePlacePage(caveId: args?['caveId'] ?? 0, cavePlaceId: args?['cavePlaceId']);
        },
        rasterMapsRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as int?;
          return RasterMapsPage(caveId: args ?? 0);
        },
        settingsRoute: (context) => const SettingsMainPage(),
      },
    );
  }
}