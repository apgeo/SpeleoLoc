import 'package:flutter/material.dart';
import 'package:speleoloc/services/beacon/beacon_detection_service.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Drawer quick-toggle mirroring the Settings → Beacon detection master
/// switch, so detection can be silenced or re-enabled without leaving the
/// current screen. Delegates to [BeaconDetectionService.setEnabled] — the
/// same flow (permissions, persistence, restart, feedback) as the settings
/// page, which therefore stays in sync via [enabledListenable].
class BeaconDetectionDrawerToggle extends StatefulWidget {
  const BeaconDetectionDrawerToggle({super.key, this.service});

  /// The detection service to drive; the app's own instance when null.
  final BeaconDetectionService? service;

  @override
  State<BeaconDetectionDrawerToggle> createState() =>
      _BeaconDetectionDrawerToggleState();
}

class _BeaconDetectionDrawerToggleState
    extends State<BeaconDetectionDrawerToggle> {
  bool _busy = false;

  BeaconDetectionService get _service =>
      widget.service ?? BeaconDetectionService.instance;

  Future<void> _toggle(bool enable) async {
    setState(() => _busy = true);
    try {
      await _service.setEnabled(enable);
    } catch (e, st) {
      AppLogger.of(
        'BeaconDetectionDrawerToggle',
      ).warning('detection could not be switched', e, st);
      SnackBarService.showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _service.enabledListenable,
      builder: (context, enabled, _) => SwitchListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        secondary: Icon(
          enabled ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
          size: 20,
        ),
        title: Text(
          LocServ.inst.t('beacon_detection_quick_toggle'),
          style: const TextStyle(fontSize: 13),
        ),
        value: enabled,
        onChanged: _busy ? null : _toggle,
      ),
    );
  }
}
