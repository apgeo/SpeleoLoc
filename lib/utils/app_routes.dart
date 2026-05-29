import 'package:flutter/widgets.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/uuid.dart';

/// Typed argument bundle for `cavePlaceRoute`. Replaces the previous
/// `Map<String, Uuid?>` payload + unsafe cast in `app.dart`.
class CavePlaceRouteArgs {
  const CavePlaceRouteArgs({required this.caveUuid, this.cavePlaceUuid});
  final Uuid caveUuid;
  final Uuid? cavePlaceUuid;
}

/// Typed argument bundle for `cavePlaceViewRoute`.
class CavePlaceViewRouteArgs {
  const CavePlaceViewRouteArgs({
    required this.cavePlaceUuid,
    this.caveUuid,
    this.initialRasterMapUuid,
  });
  final Uuid cavePlaceUuid;
  final Uuid? caveUuid;
  final Uuid? initialRasterMapUuid;
}

/// Centralised, type-safe navigation helpers. Wraps the named-route
/// machinery so call-sites never have to pass `arguments: <untyped>` and
/// the page builders never have to do `as Map<String, Uuid?>?` casts —
/// the unsafe boundary lives in exactly one place (`app.dart`).
///
/// Companion to PR 9 (i18n reconcile). Full `go_router` migration is
/// deferred (logged as PR 9b in `REFACTORING_PLAN.md`); this class
/// delivers the "type-safe routing" half without touching `navigatorKey`
/// or `DeepLinkHandler` integration.
class AppRoutes {
  const AppRoutes._();

  static Future<T?> pushHomeReplaceAll<T>(BuildContext c) =>
      Navigator.pushNamedAndRemoveUntil<T>(c, homeRoute, (_) => false);

  static Future<T?> pushCave<T>(BuildContext c, Uuid caveUuid) =>
      Navigator.pushNamed<T>(c, caveRoute, arguments: caveUuid);

  static Future<T?> pushCavePlace<T>(
    BuildContext c, {
    required Uuid caveUuid,
    Uuid? cavePlaceUuid,
  }) =>
      Navigator.pushNamed<T>(
        c,
        cavePlaceRoute,
        arguments: CavePlaceRouteArgs(
          caveUuid: caveUuid,
          cavePlaceUuid: cavePlaceUuid,
        ),
      );

  static Future<T?> pushCavePlaceView<T>(
    BuildContext c, {
    required Uuid cavePlaceUuid,
    Uuid? caveUuid,
    Uuid? initialRasterMapUuid,
  }) =>
      Navigator.pushNamed<T>(
        c,
        cavePlaceViewRoute,
        arguments: CavePlaceViewRouteArgs(
          cavePlaceUuid: cavePlaceUuid,
          caveUuid: caveUuid,
          initialRasterMapUuid: initialRasterMapUuid,
        ),
      );

  static Future<T?> pushRasterMaps<T>(BuildContext c, Uuid caveUuid) =>
      Navigator.pushNamed<T>(c, rasterMapsRoute, arguments: caveUuid);

  static Future<T?> pushSettings<T>(BuildContext c) =>
      Navigator.pushNamed<T>(c, settingsRoute);

  static Future<T?> pushCaveTrip<T>(BuildContext c, Uuid tripUuid) =>
      Navigator.pushNamed<T>(c, caveTripRoute, arguments: tripUuid);

  static Future<T?> pushCaveTripList<T>(BuildContext c, Uuid caveUuid) =>
      Navigator.pushNamed<T>(c, caveTripListRoute, arguments: caveUuid);

  static Future<T?> pushCaveTripLog<T>(BuildContext c, Uuid tripUuid) =>
      Navigator.pushNamed<T>(c, caveTripLogRoute, arguments: tripUuid);

  static Future<T?> pushTripReportTemplates<T>(BuildContext c) =>
      Navigator.pushNamed<T>(c, tripReportTemplatesRoute);
}
