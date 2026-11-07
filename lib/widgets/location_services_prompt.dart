import 'package:flutter/material.dart';
import 'package:speleoloc/services/beacon/beacon_scan_helper.dart';
import 'package:speleoloc/utils/localization.dart';

/// Ensures the location master switch is on before scanning. With it off
/// Android returns no BLE results (see
/// [BeaconScanHelper.isLocationServiceEnabled]) and the beacon plugin's own
/// check silently hangs instead of reporting it, so when disabled this
/// explains why and offers a shortcut to the system location settings; the
/// caller retries afterwards. Returns true when scanning may proceed.
/// Android-only; true elsewhere.
Future<bool> ensureLocationServicesEnabled(BuildContext context) async {
  if (await BeaconScanHelper.isLocationServiceEnabled()) return true;
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
  if (open == true) await BeaconScanHelper.openLocationSettings();
  return false;
}
