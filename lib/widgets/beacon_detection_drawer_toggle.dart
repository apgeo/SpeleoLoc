import 'package:flutter/material.dart';
import 'package:speleoloc/services/beacon/beacon_detection_service.dart';
import 'package:speleoloc/utils/localization.dart';

/// Drawer quick-toggle mirroring the Settings → Beacon detection master
/// switch, so detection can be silenced or re-enabled without leaving the
/// current screen. Delegates to [BeaconDetectionService.setEnabled] — the
/// same flow (permissions, persistence, restart, feedback) as the settings
/// page, which therefore stays in sync via [enabledListenable].
class BeaconDetectionDrawerToggle extends StatefulWidget {
  const BeaconDetectionDrawerToggle({super.key});

  @override
  State<BeaconDetectionDrawerToggle> createState() =>
      _BeaconDetectionDrawerToggleState();
}

class _BeaconDetectionDrawerToggleState
    extends State<BeaconDetectionDrawerToggle> {
  bool _busy = false;

  Future<void> _toggle(bool enable) async {
    setState(() => _busy = true);
    await BeaconDetectionService.instance.setEnabled(enable);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: BeaconDetectionService.instance.enabledListenable,
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
