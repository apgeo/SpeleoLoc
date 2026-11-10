import 'dart:io';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/services/beacon/bp1003_advertisement_parser.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Configuration key holding the comma-separated proximity UUID list used
/// for iBeacon ranging regions (required on iOS, informative on Android).
const String beaconRegionUuidsKey = 'beacon_lab_region_uuids';

/// Shared plumbing for iBeacon ranging: runtime permissions, the persisted
/// proximity-UUID list, and region construction. Used by the Beacon Lab
/// diagnostics, the assign-beacon picker, and (later) the detection service.
class BeaconScanHelper {
  const BeaconScanHelper._();

  static final _log = AppLogger.of('BeaconScanHelper');

  /// Android runtime permissions for BLE scanning. On iOS the plugins
  /// trigger the native CoreLocation / CoreBluetooth prompts themselves.
  /// Returns true when scanning may proceed. When permanently denied,
  /// opens the app settings screen.
  static Future<bool> ensureAndroidPermissions() async {
    if (!Platform.isAndroid) return true;
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    final denied = statuses.entries.where((e) => !e.value.isGranted).toList();
    if (denied.isEmpty) return true;
    _log.warning(
      'BLE permissions denied: '
      '${denied.map((e) => e.key.toString()).join(', ')}',
    );
    if (denied.any((e) => e.value.isPermanentlyDenied)) {
      await openAppSettings();
    }
    return false;
  }

  /// Whether the device's location master switch is on. Android gates BLE
  /// scan *results* behind location services (not merely the permission),
  /// because our `BLUETOOTH_SCAN` is declared without `neverForLocation`;
  /// with the switch off a scan silently returns nothing. iOS does not
  /// couple the two, so this is Android-only and true elsewhere.
  static Future<bool> isLocationServiceEnabled() async {
    if (!Platform.isAndroid) return true;
    return Geolocator.isLocationServiceEnabled();
  }

  /// Opens the system location settings, where the master switch is.
  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();

  /// Initializes the beacon plugin; with [checkPermissions] it also asks for
  /// what scanning needs and fails when it is missing.
  ///
  /// On iOS the plugin asks for "Always" location by default, a prompt iOS
  /// suppresses unless the app declares the Always purpose string, so the
  /// authorization stayed undetermined and ranging never started. Ranging
  /// here runs only while the app is on screen (background detection is
  /// Android-only), which When-In-Use covers. The call is a no-op on
  /// Android.
  static Future<bool> initializeScanning({
    required bool checkPermissions,
  }) async {
    await flutterBeacon.setLocationAuthorizationTypeDefault(
      AuthorizationStatus.whenInUse,
    );
    return checkPermissions
        ? flutterBeacon.initializeAndCheckScanning
        : flutterBeacon.initializeScanning;
  }

  /// Loads the persisted proximity-UUID list; defaults to the HoneyComm
  /// factory UUID. Values are canonical uppercase.
  static Future<List<String>> loadRegionUuids() async {
    final raw =
        await configurationRepository.readString(beaconRegionUuidsKey) ?? '';
    final uuids = raw
        .split(',')
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();
    return uuids.isEmpty ? [honeyCommDefaultProximityUuid] : uuids;
  }

  static Future<void> saveRegionUuids(List<String> uuids) =>
      configurationRepository.writeString(
        beaconRegionUuidsKey,
        uuids.join(','),
      );

  /// Ranging regions for the current platform: iOS requires one region per
  /// known proximity UUID; Android ranges every iBeacon with a single
  /// wildcard region.
  static List<Region> buildRegions(List<String> uuids) => Platform.isIOS
      ? [
          for (final uuid in uuids)
            Region(identifier: 'speleoloc-$uuid', proximityUUID: uuid),
        ]
      : [Region(identifier: 'speleoloc-all')];
}
