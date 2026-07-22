import 'dart:async';
import 'dart:io';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/beacon/beacon_alert_notifier.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/beacon/beacon_match_engine.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/services/beacon/beacon_scan_helper.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_advertisement_parser.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_scan_service.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/app_routes.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/navigator_key.dart';
import 'package:speleoloc/state/raster_map_sort_options.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Foreground automatic beacon detection (plan Phase 2).
///
/// While the app is in the foreground and detection is enabled, two frame
/// sources — iBeacon ranging and the shared Ruuvi advertisement scan
/// (active only while Ruuvi registrations exist) — feed one
/// [BeaconMatchEngine], and on a trigger:
///  1. resolves the identity to a registered cave place
///     ([BeaconRepository.findByIdentity] / [BeaconRepository.findByMac],
///     ambiguity resolved quietly by preferring the active-trip cave,
///     then the last-open cave),
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
  BeaconDetectionService._() {
    // The registration watch subscribes against the appDatabase instance
    // current at start; re-subscribe whenever a restore/import swaps it.
    onAppDatabaseReplaced(() => unawaited(restart()));
  }
  static final BeaconDetectionService instance = BeaconDetectionService._();

  final _log = AppLogger.of('BeaconDetectionService');

  /// Mirrors [BeaconDetectionConfig.enabled] so lightweight UI (the drawer
  /// quick-toggle) can bind to the master switch without re-reading the
  /// config. Kept current by [start] (which loads the config on every
  /// launch/resume) and [setEnabled].
  final ValueNotifier<bool> enabledListenable = ValueNotifier(false);

  StreamSubscription<RangingResult>? _rangingSub;
  StreamSubscription<RuuviSighting>? _ruuviSub;
  StreamSubscription<List<CavePlaceBeacon>>? _registrationsSub;
  StreamSubscription<BluetoothState>? _btStateSub;
  Timer? _ruuviDutyTimer;
  Timer? _startRetryTimer;
  BeaconMatchEngine? _engine;
  bool _running = false;
  bool get isRunning => _running;

  /// Delay before retrying a [start] that failed on a transient error
  /// (database still opening, platform channel not ready, Bluetooth
  /// adapter initializing). Retries stop as soon as one attempt gets far
  /// enough to read the config.
  static const _startRetryDelay = Duration(seconds: 30);

  /// Registered identities, mirrored from the watch — gates the passive
  /// Ruuvi health harvesting without a DB lookup per advertisement.
  Set<String> _registeredIdentities = const {};
  bool _ruuviNeeded = false;

  /// Proximity UUIDs of registered iBeacons, mirrored from the watch. iOS
  /// only ranges explicitly listed UUIDs (Android uses a wildcard region),
  /// so ranging must cover these on top of the Beacon Lab region list —
  /// otherwise a tag registered with a UUID the lab never saved is
  /// undetectable on iOS.
  Set<String> _registeredProximityUuids = const {};

  /// Ruuvi advertisements arrive ~every 1.3 s; telemetry writes are
  /// throttled to one per tag per minute.
  static const _ruuviHealthInterval = Duration(minutes: 1);
  final Map<String, DateTime> _lastRuuviHealth = {};

  /// True between app-pause and app-resume while the foreground service
  /// keeps scanning; triggers then alert via notification + loud sound.
  bool _inBackground = false;
  bool _fgsInitialized = false;

  /// Scan burst length in background duty-cycle mode.
  static const int _backgroundScanBurstMs = 5000;

  /// AltBeacon foreground defaults, restored when returning to the app.
  static const int _foregroundScanPeriodMs = 1100;

  /// Starts detection when enabled AND permissions are already granted.
  /// Safe to call unconditionally (app start, resume, settings change) —
  /// every failure path only logs.
  Future<void> start() async {
    if (_running) return;
    _startRetryTimer?.cancel();
    _startRetryTimer = null;
    try {
      final config = await BeaconDetectionConfig.load();
      enabledListenable.value = config.enabled;
      if (!config.enabled) return;
      if (!await _permissionsAlreadyGranted()) {
        _log.info(
          'Beacon detection enabled but permissions missing; '
          'staying off until granted via settings',
        );
        return;
      }
      if (!await BeaconScanHelper.isLocationServiceEnabled()) {
        // Android silently returns no BLE results with the location master
        // switch off; keep going (the switch may come on any time) but
        // leave a trace for "detection is enabled yet finds nothing".
        _log.warning(
          'Beacon detection started with location services off — '
          'Android will deliver no scan results until they are enabled',
        );
      }
      await flutterBeacon.initializeScanning;

      _engine = BeaconMatchEngine(config);
      _watchRegistrations();
      _watchBluetoothState();

      _listenRanging(await BeaconScanHelper.loadRegionUuids());
      _running = true;
      _log.info(
        'Beacon detection started '
        '(threshold ${config.rssiThresholdDbm} dBm, '
        'cooldown ${config.cooldownSec} s)',
      );
    } catch (e, st) {
      // Platform channels are unavailable in widget tests and detection
      // must never break app startup — log, stay off, and retry once the
      // transient cold-start condition may have cleared.
      _log.warning('Beacon detection failed to start', e, st);
      await stop();
      _startRetryTimer = Timer(_startRetryDelay, () {
        _startRetryTimer = null;
        if (!_running) unawaited(start());
      });
    }
  }

  Future<void> stop() async {
    _startRetryTimer?.cancel();
    _startRetryTimer = null;
    await _btStateSub?.cancel();
    _btStateSub = null;
    await _rangingSub?.cancel();
    _rangingSub = null;
    _ruuviDutyTimer?.cancel();
    _ruuviDutyTimer = null;
    await _ruuviSub?.cancel();
    _ruuviSub = null;
    await _registrationsSub?.cancel();
    _registrationsSub = null;
    _registeredIdentities = const {};
    _registeredProximityUuids = const {};
    _ruuviNeeded = false;
    _engine = null;
    if (_inBackground) {
      _inBackground = false;
      try {
        await FlutterForegroundTask.stopService();
      } catch (e, st) {
        _log.warning('Foreground service stop failed', e, st);
      }
    }
    if (_running) _log.info('Beacon detection stopped');
    _running = false;
  }

  /// Re-reads config and restarts (settings page calls this on save).
  Future<void> restart() async {
    await stop();
    await start();
  }

  /// Persists the master switch and applies it — the one enable/disable
  /// flow shared by the settings page and the drawer quick-toggle.
  /// Enabling runs the full permission flow (so detection can silently
  /// auto-start on every later app launch) and verifies the platform can
  /// scan; all user feedback is raised here so callers stay passive.
  /// Returns false when a permission or platform check blocked the change.
  Future<bool> setEnabled(bool enable) async {
    if (enable) {
      if (!await BeaconScanHelper.ensureAndroidPermissions()) {
        SnackBarService.showWarning(
          LocServ.inst.t('beacon_lab_permissions_missing'),
        );
        return false;
      }
      try {
        await flutterBeacon.initializeAndCheckScanning;
      } on PlatformException catch (e) {
        SnackBarService.showWarning(e.message ?? e.code);
        return false;
      }
    }
    final config = await BeaconDetectionConfig.load();
    await config.copyWith(enabled: enable).save();
    enabledListenable.value = enable;
    await restart();
    if (enable && !_running) {
      SnackBarService.showWarning(
        LocServ.inst.t('beacon_detection_not_running'),
      );
    }
    return true;
  }

  /// App lifecycle hook. With background detection enabled the scan
  /// survives app pause inside a foreground service (duty-cycled);
  /// otherwise scanning is foreground-only.
  void onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_inBackground) {
        unawaited(_exitBackgroundMode());
      } else {
        start();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_running && (_engine?.config.backgroundEnabled ?? false)) {
        unawaited(_enterBackgroundMode());
      } else {
        stop();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Background mode (Android foreground service + duty-cycled scanning)
  // ---------------------------------------------------------------------------

  Future<void> _enterBackgroundMode() async {
    if (_inBackground || !Platform.isAndroid) return;
    try {
      final config = _engine?.config;
      if (config == null) return;
      _initForegroundTask();
      final result = await FlutterForegroundTask.startService(
        serviceId: 7001,
        serviceTypes: const [ForegroundServiceTypes.connectedDevice],
        notificationTitle: LocServ.inst.t('beacon_background_notif_title'),
        notificationText: LocServ.inst.t('beacon_background_notif_text'),
      );
      if (result is! ServiceRequestSuccess) {
        _log.warning(
          'Foreground service refused: $result — '
          'stopping detection with the app',
        );
        await stop();
        return;
      }
      // Duty cycle: one ~5 s burst per configured interval. A burst
      // delivers a single aggregated ranging callback, so debounce is
      // dropped to 1 in background (2 bursts could be a minute apart).
      final between =
          (config.backgroundScanIntervalSec * 1000 - _backgroundScanBurstMs)
              .clamp(0, 3600000);
      await flutterBeacon.setScanPeriod(_backgroundScanBurstMs);
      await flutterBeacon.setBetweenScanPeriod(between);
      _engine?.config = config.copyWith(debounceCount: 1);
      _inBackground = true;
      // The Ruuvi scan has no AltBeacon-style duty cycle, so burst it with
      // a timer: subscribe (starts the shared scan) for one burst length,
      // then release (stops it) until the next interval.
      if (_ruuviNeeded) {
        await _ruuviSub?.cancel();
        _ruuviSub = null;
        _ruuviDutyTimer = Timer.periodic(
          Duration(seconds: config.backgroundScanIntervalSec),
          (_) => _ruuviBurst(),
        );
        _ruuviBurst();
      }
      _log.info(
        'Background detection: burst ${_backgroundScanBurstMs}ms '
        'every ${config.backgroundScanIntervalSec}s',
      );
    } catch (e, st) {
      _log.warning('Failed to enter background detection mode', e, st);
      await stop();
    }
  }

  void _ruuviBurst() {
    if (!_inBackground || !_ruuviNeeded || _ruuviSub != null) return;
    _ruuviSub = RuuviScanService.instance.sightings.listen(
      _onRuuviSighting,
      onError: (Object e, StackTrace st) =>
          _log.warning('Background ruuvi scan error', e, st),
    );
    Timer(const Duration(milliseconds: _backgroundScanBurstMs), () {
      if (!_inBackground) return;
      unawaited(_ruuviSub?.cancel());
      _ruuviSub = null;
    });
  }

  Future<void> _exitBackgroundMode() async {
    _inBackground = false;
    _ruuviDutyTimer?.cancel();
    _ruuviDutyTimer = null;
    _syncRuuviSubscription();
    if (!Platform.isAndroid) return;
    try {
      await FlutterForegroundTask.stopService();
    } catch (e, st) {
      _log.warning('Foreground service stop failed', e, st);
    }
    try {
      await flutterBeacon.setScanPeriod(_foregroundScanPeriodMs);
      await flutterBeacon.setBetweenScanPeriod(0);
    } catch (e, st) {
      _log.warning('Restoring scan periods failed', e, st);
    }
    // Restore the persisted debounce settings. On failure keep the engine's
    // current config, but surface the failure so a broken debounce config
    // isn't silently ignored.
    try {
      final config = await BeaconDetectionConfig.load();
      _engine?.config = config;
    } catch (e, st) {
      _log.warning(
        'Loading beacon detection config failed; '
        'keeping current config',
        e,
        st,
      );
    }
    if (!_running) await start();
  }

  void _initForegroundTask() {
    if (_fgsInitialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'beacon_background_service',
        channelName: 'Beacon background scanning',
        channelDescription:
            'Keeps beacon detection running while SpeleoLoc is not on screen',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
      ),
    );
    _fgsInitialized = true;
  }

  Future<bool> _permissionsAlreadyGranted() async {
    if (!Platform.isAndroid) return true;
    return await Permission.bluetoothScan.isGranted &&
        await Permission.locationWhenInUse.isGranted;
  }

  /// Re-arms iBeacon ranging when Bluetooth turns (back) on. A ranging
  /// subscription opened while the adapter is off/still initializing —
  /// e.g. detection auto-starting at app launch — can otherwise stay
  /// silent until the next full restart.
  void _watchBluetoothState() {
    _btStateSub = flutterBeacon.bluetoothStateChanged().listen(
      (state) {
        if (state != BluetoothState.stateOn || !_running) return;
        unawaited(
          _resubscribeRanging().catchError((Object e, StackTrace st) {
            _log.warning('Ranging restart on Bluetooth-on failed', e, st);
          }),
        );
      },
      onError: (Object e, StackTrace st) =>
          _log.warning('Bluetooth state watch error', e, st),
    );
  }

  Future<void> _resubscribeRanging() async {
    final uuids = {
      ...await BeaconScanHelper.loadRegionUuids(),
      ..._registeredProximityUuids,
    }.toList();
    await _rangingSub?.cancel();
    _rangingSub = null;
    if (!_running) return;
    _listenRanging(uuids);
  }

  void _listenRanging(List<String> uuids) {
    _rangingSub = flutterBeacon
        .ranging(BeaconScanHelper.buildRegions(uuids))
        .listen(
          _onRangingResult,
          onError: (Object e, StackTrace st) =>
              _log.warning('Detection ranging error', e, st),
        );
  }

  /// Keeps the engine's registered-identity cache in sync with the table
  /// (assign/unassign/import all refresh it automatically).
  ///
  /// Bound to the [appDatabase] instance current at subscribe time — the
  /// watch does not survive `replaceAppDatabase()`. The constructor's
  /// [onAppDatabaseReplaced] listener restarts detection after every swap,
  /// so the watch re-subscribes even if a flow ever skips the app restart.
  void _watchRegistrations() {
    final db = appDatabase;
    _registrationsSub =
        (db.select(
          db.cavePlaceBeacons,
        )..where((b) => b.deletedAt.isNull())).watch().listen(
          (rows) {
            _registeredIdentities = {
              for (final r in rows) ?BeaconRepository.identityOf(r),
            };
            _engine?.updateRegistrations(_registeredIdentities);
            _ruuviNeeded = rows.any(
              (r) => r.beaconType == BeaconTypes.ruuvi,
            );
            _syncRuuviSubscription();
            final proximityUuids = {
              for (final r in rows)
                if (r.beaconType == BeaconTypes.iBeacon &&
                    r.proximityUuid != null)
                  r.proximityUuid!.toUpperCase(),
            };
            final needsRegionRefresh =
                Platform.isIOS &&
                !_registeredProximityUuids.containsAll(proximityUuids);
            _registeredProximityUuids = proximityUuids;
            if (needsRegionRefresh) {
              unawaited(
                _resubscribeRanging().catchError((Object e, StackTrace st) {
                  _log.warning('Ranging region refresh failed', e, st);
                }),
              );
            }
          },
          onError: (Object e, StackTrace st) {
            _log.warning('Registration watch error', e, st);
          },
        );
  }

  /// Attaches/detaches the Ruuvi frame source to match the registration
  /// set — the shared scan only runs while a registered Ruuvi tag exists.
  /// In background mode the duty-cycle timer owns the subscription instead.
  void _syncRuuviSubscription() {
    if (_inBackground) return;
    if (_ruuviNeeded && _engine != null) {
      _ruuviSub ??= RuuviScanService.instance.sightings.listen(
        _onRuuviSighting,
        onError: (Object e, StackTrace st) =>
            _log.warning('Detection ruuvi scan error', e, st),
      );
    } else {
      unawaited(_ruuviSub?.cancel());
      _ruuviSub = null;
    }
  }

  void _onRuuviSighting(RuuviSighting s) {
    final engine = _engine;
    if (engine == null) return;
    if (engine.observe(s.identity, s.rssi, DateTime.now())) {
      // Sequential, not awaited: scan callbacks must not queue up.
      unawaited(_handleRuuviTrigger(s));
    } else if (_registeredIdentities.contains(s.identity)) {
      // No trigger, but the tag broadcasts telemetry anyway — harvest it.
      unawaited(_harvestRuuviHealth(s));
    }
  }

  /// Passive telemetry from advertisements of registered tags, throttled
  /// per tag; stamps every registration of the physical tag (any cave).
  Future<void> _harvestRuuviHealth(RuuviSighting s) async {
    try {
      final now = DateTime.now();
      final last = _lastRuuviHealth[s.identity];
      if (last != null && now.difference(last) < _ruuviHealthInterval) return;
      _lastRuuviHealth[s.identity] = now;
      final mac = s.advertisement.macAddress;
      if (mac == null) return;
      for (final m in await beaconRepository.findByMac(mac)) {
        await _stampRuuviHealth(m.beacon.uuid, s.advertisement);
      }
    } catch (e, st) {
      _log.warning('Ruuvi health harvest failed', e, st);
    }
  }

  Future<void> _stampRuuviHealth(Uuid beaconUuid, RuuviAdvertisement adv) =>
      beaconRepository.updateHealth(
        beaconUuid,
        batteryMv: adv.batteryMv,
        temperatureC: adv.temperatureC,
        humidityPct: adv.humidityPct,
        pressureHpa: adv.pressureHpa,
        movementCounter: adv.movementCounter,
      );

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
      unawaited(beaconRepository.updateHealth(selected.beacon.uuid));
      await _completeTrigger(
        selected,
        '${b.proximityUUID}/${b.major}/${b.minor}, ${b.rssi} dBm',
      );
    } catch (e, st) {
      _log.warning('Beacon trigger handling failed', e, st);
    }
  }

  Future<void> _handleRuuviTrigger(RuuviSighting s) async {
    try {
      final mac = s.advertisement.macAddress;
      if (mac == null) return;
      final matches = await beaconRepository.findByMac(mac);
      if (matches.isEmpty) return;
      final selected = await _selectMatch(matches);
      _lastRuuviHealth[s.identity] = DateTime.now();
      unawaited(_stampRuuviHealth(selected.beacon.uuid, s.advertisement));
      await _completeTrigger(selected, '${s.identity}, ${s.rssi} dBm');
    } catch (e, st) {
      _log.warning('Ruuvi trigger handling failed', e, st);
    }
  }

  /// The shared post-identification tail, identical for both frame
  /// sources: trip point, then notification / toast / navigation.
  Future<void> _completeTrigger(
    BeaconWithPlace selected,
    String logDetail,
  ) async {
    final place = selected.cavePlace;
    _log.info('Beacon trigger → place "${place.title}" ($logDetail)');

    // Trip point — same semantics as a QR scan of this place.
    final activeTripCaveId = await caveTripService.getActiveTripCaveId();
    final tripPointRecorded = activeTripCaveId == place.caveUuid;
    if (tripPointRecorded) {
      await caveTripService.recordPoint(place.uuid, placeTitle: place.title);
    }

    if (_inBackground) {
      // App not on screen: loud notification instead of a toast.
      await BeaconAlertNotifier.instance.showDetection(
        placeTitle: place.title,
        tripPointRecorded: tripPointRecorded,
        caveUuid: place.caveUuid,
        placeUuid: place.uuid,
      );
    } else {
      SnackBarService.showSuccess(
        '${LocServ.inst.t('beacon_place_detected')}: "${place.title}"'
        '${tripPointRecorded ? ' · ${LocServ.inst.t('trip_point_added')}' : ''}',
      );
      if ((_engine?.config.autoOpenPlace ?? false)) {
        await _openPlace(place);
      }
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
        final def = await definitionRepository.findDefinition(
          place.uuid,
          rm.uuid,
        );
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
