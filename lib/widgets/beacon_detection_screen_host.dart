import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/beacon/beacon_detection_host.dart';
import 'package:speleoloc/services/beacon/beacon_enabled_notice.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/location/last_located_place.dart';
import 'package:speleoloc/services/map/best_raster_map_finder.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/trip_record_outcome.dart';
import 'package:speleoloc/utils/app_routes.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';
import 'package:speleoloc/widgets/trip_record_feedback.dart';

/// Beacon detection's messages as toasts, and its place opening through the
/// app's navigator, for a detection on screen and for a tapped detection
/// notification alike.
///
/// The trip service and repositories are read at each use, since a database
/// swap rebuilds them.
class BeaconDetectionScreenHost implements BeaconDetectionHost {
  BeaconDetectionScreenHost({
    required GlobalKey<NavigatorState> navigator,
    required CaveTripService Function() trips,
    required IRasterMapRepository Function() rasterMaps,
    required IDefinitionRepository Function() definitions,
    required LastLocatedPlace lastLocated,
  }) : _navigator = navigator,
       _trips = trips,
       _rasterMaps = rasterMaps,
       _definitions = definitions,
       _lastLocated = lastLocated;

  final GlobalKey<NavigatorState> _navigator;
  final CaveTripService Function() _trips;
  final IRasterMapRepository Function() _rasterMaps;
  final IDefinitionRepository Function() _definitions;
  final LastLocatedPlace _lastLocated;

  /// Long enough to read two sentences.
  static const _switchedOnNoticeDuration = Duration(seconds: 8);

  @override
  void permissionsMissing() => SnackBarService.showWarning(
    LocServ.inst.t('beacon_lab_permissions_missing'),
  );

  @override
  void scanningRefused(String reason) => SnackBarService.showWarning(reason);

  @override
  void switchedOn(BeaconEnabledNotice notice) {
    final loc = LocServ.inst;
    switch (notice) {
      case BeaconEnabledNotice.none:
        break;
      case BeaconEnabledNotice.notRunning:
        SnackBarService.showWarning(loc.t('beacon_detection_not_running'));
      case BeaconEnabledNotice.stopsWhenLocked:
        SnackBarService.showInfo(
          loc.t('beacon_detection_stops_when_locked'),
          duration: _switchedOnNoticeDuration,
        );
      case BeaconEnabledNotice.stopsWhenLockedUnlessBackground:
        SnackBarService.showInfo(
          loc.t('beacon_detection_stops_when_locked_hint', {
            'option': loc.t('beacon_background_enable'),
            'page': '${loc.t('settings')} → ${loc.t('settings_beacons')}',
          }),
          duration: _switchedOnNoticeDuration,
        );
    }
  }

  @override
  void placeDetected(CavePlace place, TripRecordOutcome? tripOutcome) =>
      showTripRecordFeedback(
        _trips(),
        tripOutcome,
        lead: '${LocServ.inst.t('beacon_place_detected')}: "${place.title}"',
      );

  /// Opens the place page of a place a detection notification named.
  void openPlacePage(Uuid caveUuid, Uuid placeUuid) {
    final context = _navigator.currentContext;
    if (context == null) return;
    AppRoutes.pushCavePlace(
      context,
      caveUuid: caveUuid,
      cavePlaceUuid: placeUuid,
    );
  }

  /// Opens the best raster map with the place pinned, falling back to the
  /// place page, as the QR flow does.
  @override
  Future<void> openPlace(CavePlace place) async {
    final context = _navigator.currentContext;
    if (context == null) return;

    _lastLocated.record(place.uuid);
    final bestMapUuid = await BestRasterMapFinder(
      _rasterMaps(),
      _definitions(),
    ).bestMapFor(place);
    if (!context.mounted) return;
    if (bestMapUuid != null) {
      await AppRoutes.pushCavePlaceView(
        context,
        cavePlaceUuid: place.uuid,
        caveUuid: place.caveUuid,
        initialRasterMapUuid: bestMapUuid,
      );
    } else {
      await AppRoutes.pushCavePlace(
        context,
        caveUuid: place.caveUuid,
        cavePlaceUuid: place.uuid,
      );
    }
  }
}
