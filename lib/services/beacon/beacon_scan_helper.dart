import 'dart:io';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/beacon/bp1003_advertisement_parser.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';

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

  /// Ensures the location master switch is on before scanning. With it off
  /// Android returns no BLE results (see [isLocationServiceEnabled]) and the
  /// beacon plugin's own check silently hangs instead of reporting it, so when
  /// disabled this explains why and offers a shortcut to the system location
  /// settings; the caller retries afterwards. Returns true when scanning may
  /// proceed. Android-only; true elsewhere.
  static Future<bool> ensureLocationServicesEnabled(
    BuildContext context,
  ) async {
    if (await isLocationServiceEnabled()) return true;
    if (!context.mounted) return false;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('beacon_location_services_off_title')),
        content: Text(LocServ.inst.t('beacon_location_services_off_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('open_settings')),
          ),
        ],
      ),
    );
    if (open == true) await Geolocator.openLocationSettings();
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
            Region(identifier: 'speleoloc-$uuid', proximityUUID: uuid),
        ]
      : [Region(identifier: 'speleoloc-all')];
}
