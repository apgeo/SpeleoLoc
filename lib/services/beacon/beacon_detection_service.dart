import 'dart:async';
import 'dart:io';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/beacon/beacon_match_engine.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/services/beacon/beacon_scan_helper.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/app_routes.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/navigator_key.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Foreground automatic beacon detection (plan Phase 2).
///
/// While the app is in the foreground and detection is enabled, ranges
/// iBeacons, feeds sightings through [BeaconMatchEngine], and on a trigger:
///  1. resolves the identity to a registered cave place
///     ([BeaconRepository.findByIdentity], ambiguity resolved quietly by
///     preferring the active-trip cave, then the last-open cave),
///  2. stamps beacon health (last seen),
///  3. records a trip point when a trip is active in that cave
///     (exactly like a QR scan),
///  4. shows a toast — or navigates to the place when
///     [BeaconDetectionConfig.autoOpenPlace] is on.
///
/// Entrance start/stop-trip prompts remain QR-only for now: modal dialogs
/// firing while walking past a beacon would be intrusive; Phase 4 revisits
/// this with notifications.
///
/// Lifecycle: [SpeleoLocApp] calls [onLifecycle]; scanning stops in the
/// background (background detection is plan Phase 4). Never requests
/// permissions itself — [start] silently stays off until the user enables
/// detection in Settings → Beacon detection (which runs the request flow).
class BeaconDetectionService {
  BeaconDetectionService._();
  static final BeaconDetectionService instance = BeaconDetectionService._();

  final _log = AppLogger.of('BeaconDetectionService');

  StreamSubscription<RangingResult>? _rangingSub;
  StreamSubscription<List<CavePlaceBeacon>>? _registrationsSub;
  BeaconMatchEngine? _engine;
  bool _running = false;
  bool get isRunning => _running;

  /// Starts detection when enabled AND permissions are already granted.
  /// Safe to call unconditionally (app start, resume, settings change) —
  /// every failure path only logs.
  Future<void> start() async {
    if (_running) return;
    try {
      final config = await BeaconDetectionConfig.load();
      if (!config.enabled) return;
      if (!await _permissionsAlreadyGranted()) {
        _log.info('Beacon detection enabled but permissions missing; '
            'staying off until granted via settings');
        return;
      }
      await flutterBeacon.initializeScanning;

      _engine = BeaconMatchEngine(config);
      _watchRegistrations();

      final uuids = await BeaconScanHelper.loadRegionUuids();
      _rangingSub =
          flutterBeacon.ranging(BeaconScanHelper.buildRegions(uuids)).listen(
        _onRangingResult,
        onError: (Object e, StackTrace st) =>
            _log.warning('Detection ranging error', e, st),
      );
      _running = true;
      _log.info('Beacon detection started '
          '(threshold ${config.rssiThresholdDbm} dBm, '
          'cooldown ${config.cooldownSec} s)');
    } catch (e, st) {
      // Platform channels are unavailable in widget tests and detection
      // must never break app startup — log and stay off.
      _log.warning('Beacon detection failed to start', e, st);
      await stop();
    }
  }

  Future<void> stop() async {
    await _rangingSub?.cancel();
    _rangingSub = null;
    await _registrationsSub?.cancel();
    _registrationsSub = null;
    _engine = null;
    if (_running) _log.info('Beacon detection stopped');
    _running = false;
  }

  /// Re-reads config and restarts (settings page calls this on save).
  Future<void> restart() async {
    await stop();
    await start();
  }

  /// App lifecycle hook: foreground-only scanning.
  void onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      stop();
    }
  }

  Future<bool> _permissionsAlreadyGranted() async {
    if (!Platform.isAndroid) return true;
    return await Permission.bluetoothScan.isGranted &&
        await Permission.locationWhenInUse.isGranted;
  }

  /// Keeps the engine's registered-identity cache in sync with the table
  /// (assign/unassign/import all refresh it automatically).
  void _watchRegistrations() {
    final db = appDatabase;
    _registrationsSub = (db.select(db.cavePlaceBeacons)
          ..where((b) => b.deletedAt.isNull()))
        .watch()
        .listen((rows) {
      _engine?.updateRegistrations({
        for (final r in rows)
          '${r.proximityUuid.toUpperCase()}/${r.major}/${r.minor}'
      });
    }, onError: (Object e, StackTrace st) {
      _log.warning('Registration watch error', e, st);
    });
  }

  void _onRangingResult(RangingResult result) {
    final engine = _engine;
    if (engine == null) return;
    final now = DateTime.now();
    for (final b in result.beacons) {
      final identity = '${b.proximityUUID.toUpperCase()}/${b.major}/${b.minor}';
      if (engine.observe(identity, b.rssi, now)) {
        // Sequential, not awaited: ranging callbacks must not queue up.
        unawaited(_handleTrigger(b));
      }
    }
  }

  Future<void> _handleTrigger(Beacon b) async {
    try {
      final matches = await beaconRepository.findByIdentity(
        b.proximityUUID,
        b.major,
        b.minor,
      );
      if (matches.isEmpty) return;

      final selected = await _selectMatch(matches);
      final place = selected.cavePlace;
      _log.info('Beacon trigger → place "${place.title}" '
          '(${b.proximityUUID}/${b.major}/${b.minor}, ${b.rssi} dBm)');

      unawaited(beaconRepository.updateHealth(selected.beacon.uuid));

      // Trip point — same semantics as a QR scan of this place.
      final activeTripCaveId = await caveTripService.getActiveTripCaveId();
      final tripPointRecorded = activeTripCaveId == place.caveUuid;
      if (tripPointRecorded) {
        await caveTripService.recordPoint(place.uuid,
            placeTitle: place.title);
      }

      SnackBarService.showSuccess(
        '${LocServ.inst.t('beacon_place_detected')}: "${place.title}"'
        '${tripPointRecorded ? ' · ${LocServ.inst.t('trip_point_added')}' : ''}',
      );

      if ((_engine?.config.autoOpenPlace ?? false)) {
        await _openPlace(place);
      }
    } catch (e, st) {
      _log.warning('Beacon trigger handling failed', e, st);
    }
  }

  /// Quiet cross-cave ambiguity resolution (no dialogs while walking):
  /// active-trip cave wins, then the last-open cave, then the first match.
  Future<BeaconWithPlace> _selectMatch(List<BeaconWithPlace> matches) async {
    if (matches.length == 1) return matches.first;
    final activeTripCaveId = await caveTripService.getActiveTripCaveId();
    if (activeTripCaveId != null) {
      for (final m in matches) {
        if (m.cavePlace.caveUuid == activeTripCaveId) return m;
      }
    }
    final lastCaveRaw = await SettingsHelper.loadStringConfig(lastOpenCaveKey);
    if (lastCaveRaw.isNotEmpty) {
      try {
        final lastCave = Uuid.parse(lastCaveRaw);
        for (final m in matches) {
          if (m.cavePlace.caveUuid == lastCave) return m;
        }
      } catch (_) {
        // unparsable stored value — fall through to first match
      }
    }
    return matches.first;
  }

  /// Mirrors the QR flow's navigation: open the best raster map with the
  /// place pinned, falling back to the place page.
  Future<void> _openPlace(CavePlace place) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final allMaps = await rasterMapRepository.getRasterMaps(place.caveUuid);
    Uuid? bestMapUuid;
    if (allMaps.isNotEmpty) {
      final sortOption = await RasterMapSortOption.load();
      final sortedMaps = sortOption.apply(allMaps, []);
      for (final rm in sortedMaps) {
        final def =
            await definitionRepository.findDefinition(place.uuid, rm.uuid);
        if (def != null) {
          bestMapUuid = rm.uuid;
          break;
        }
      }
    }
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
