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
/// Each helper's return type is fixed to match the matching
/// `MaterialPageRoute<T>` declared in `app.dart`'s `onGenerateRoute`.
/// Do NOT add a `<T>` type parameter to these methods: with the named
/// route machinery, `Navigator.pushNamed<T>` performs a runtime
/// `route as Route<T?>?` cast, so the `T` on `pushNamed` MUST equal the
/// `T` baked into the constructed `MaterialPageRoute<T>` or the cast
/// throws (`MaterialPageRoute<X> is not a subtype of Route<Y?>?`).
///
/// Companion to PR 9 (i18n reconcile). Full `go_router` migration is
/// deferred (logged as PR 9b in `REFACTORING_PLAN.md`); this class
/// delivers the "type-safe routing" half without touching `navigatorKey`
/// or `DeepLinkHandler` integration.
class AppRoutes {
  const AppRoutes._();

  static Future<void> pushHomeReplaceAll(BuildContext c) =>
      Navigator.pushNamedAndRemoveUntil<void>(c, homeRoute, (_) => false);

  static Future<bool?> pushCave(BuildContext c, Uuid caveUuid) =>
      Navigator.pushNamed<bool>(c, caveRoute, arguments: caveUuid);

  static Future<bool?> pushCavePlace(
    BuildContext c, {
    required Uuid caveUuid,
    Uuid? cavePlaceUuid,
  }) =>
      Navigator.pushNamed<bool>(
        c,
        cavePlaceRoute,
        arguments: CavePlaceRouteArgs(
          caveUuid: caveUuid,
          cavePlaceUuid: cavePlaceUuid,
        ),
      );

  static Future<void> pushCavePlaceView(
    BuildContext c, {
    required Uuid cavePlaceUuid,
    Uuid? caveUuid,
    Uuid? initialRasterMapUuid,
  }) =>
      Navigator.pushNamed<void>(
        c,
        cavePlaceViewRoute,
        arguments: CavePlaceViewRouteArgs(
          cavePlaceUuid: cavePlaceUuid,
          caveUuid: caveUuid,
          initialRasterMapUuid: initialRasterMapUuid,
        ),
      );

  static Future<bool?> pushRasterMaps(BuildContext c, Uuid caveUuid) =>
      Navigator.pushNamed<bool>(c, rasterMapsRoute, arguments: caveUuid);

  static Future<void> pushSettings(BuildContext c) =>
      Navigator.pushNamed<void>(c, settingsRoute);

  static Future<bool?> pushCaveTrip(BuildContext c, Uuid tripUuid) =>
      Navigator.pushNamed<bool>(c, caveTripRoute, arguments: tripUuid);

  static Future<void> pushCaveTripList(BuildContext c, Uuid caveUuid) =>
      Navigator.pushNamed<void>(c, caveTripListRoute, arguments: caveUuid);

  static Future<void> pushCaveTripLog(BuildContext c, Uuid tripUuid) =>
      Navigator.pushNamed<void>(c, caveTripLogRoute, arguments: tripUuid);

  static Future<void> pushTripReportTemplates(BuildContext c) =>
      Navigator.pushNamed<void>(c, tripReportTemplatesRoute);
}
