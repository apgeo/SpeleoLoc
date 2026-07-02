import 'dart:io';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/beacon/bp1003_advertisement_parser.dart';
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
    _log.warning('BLE permissions denied: '
        '${denied.map((e) => e.key.toString()).join(', ')}');
    if (denied.any((e) => e.value.isPermanentlyDenied)) {
      await openAppSettings();
    }
    return false;
  }

  /// Loads the persisted proximity-UUID list; defaults to the HoneyComm
  /// factory UUID. Values are canonical uppercase.
  static Future<List<String>> loadRegionUuids() async {
    final raw = await SettingsHelper.loadStringConfig(beaconRegionUuidsKey);
    final uuids = raw
        .split(',')
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();
    return uuids.isEmpty ? [honeyCommDefaultProximityUuid] : uuids;
  }

  static Future<void> saveRegionUuids(List<String> uuids) =>
      SettingsHelper.saveStringConfig(beaconRegionUuidsKey, uuids.join(','));

  /// Ranging regions for the current platform: iOS requires one region per
  /// known proximity UUID; Android ranges every iBeacon with a single
  /// wildcard region.
  static List<Region> buildRegions(List<String> uuids) => Platform.isIOS
      ? [
          for (final uuid in uuids)
            Region(identifier: 'speleoloc-$uuid', proximityUUID: uuid)
        ]
      : [Region(identifier: 'speleoloc-all')];
}
