import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/screens/scanner_page.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Opens the camera scanner and returns the code it read, or `null` when the
/// user backed out or the camera may not be used.
///
/// Every place that starts a scan goes through here so that a denied camera
/// permission always ends in an explanation (and a way to the system
/// settings when the denial is permanent) instead of the scanner library's
/// bare error view.
Future<String?> openQrScanner(BuildContext context) async {
  var status = await Permission.camera.status;
  if (!status.isGranted) {
    status = await Permission.camera.request();
  }
  if (!context.mounted) return null;

  if (status.isGranted) {
    String? scannedCode;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerPage(onScan: (code) => scannedCode = code),
      ),
    );
    return scannedCode;
  }

  if (status.isPermanentlyDenied) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('permission_required')),
        content: Text(LocServ.inst.t('camera_permission_required')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(ctx).pop();
            },
            child: Text(LocServ.inst.t('open_settings')),
          ),
        ],
      ),
    );
  } else {
    SnackBarService.showWarning(LocServ.inst.t('camera_permission_denied'));
  }
  return null;
}
