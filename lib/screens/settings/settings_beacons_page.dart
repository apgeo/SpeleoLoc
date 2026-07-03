import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/screens/settings/beacon_lab_page.dart';
import 'package:speleoloc/services/beacon/beacon_alert_notifier.dart';
import 'package:speleoloc/services/beacon/beacon_detection_service.dart';
import 'package:speleoloc/services/beacon/beacon_match_engine.dart';
import 'package:speleoloc/services/beacon/beacon_scan_helper.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Settings → Beacon detection: master switch (runs the permission flow on
/// enable), RSSI trigger threshold, re-trigger cooldown, auto-open toggle,
/// and a shortcut to the Beacon Lab diagnostics.
class SettingsBeaconsPage extends StatefulWidget {
  const SettingsBeaconsPage({super.key});

  @override
  State<SettingsBeaconsPage> createState() => _SettingsBeaconsPageState();
}

class _SettingsBeaconsPageState extends State<SettingsBeaconsPage> {
  BeaconDetectionConfig? _config;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await BeaconDetectionConfig.load();
    if (mounted) setState(() => _config = cfg);
  }

  Future<void> _update(BeaconDetectionConfig cfg) async {
    setState(() => _config = cfg);
    await cfg.save();
    await BeaconDetectionService.instance.restart();
  }

  Future<void> _toggleEnabled(bool enable) async {
    final cfg = _config;
    if (cfg == null) return;
    if (enable) {
      // Full permission flow now, so detection can silently auto-start on
      // every later app launch.
      if (!await BeaconScanHelper.ensureAndroidPermissions()) {
        SnackBarService.showWarning(
          LocServ.inst.t('beacon_lab_permissions_missing'),
        );
        return;
      }
      try {
        await flutterBeacon.initializeAndCheckScanning;
      } on PlatformException catch (e) {
        SnackBarService.showWarning(e.message ?? e.code);
        return;
      }
    }
    await _update(cfg.copyWith(enabled: enable));
    if (enable && !BeaconDetectionService.instance.isRunning) {
      SnackBarService.showWarning(
        LocServ.inst.t('beacon_detection_not_running'),
      );
    }
  }

  Future<void> _toggleBackground(bool enable) async {
    final cfg = _config;
    if (cfg == null) return;
    if (enable) {
      // Loud alerts need notification permission (Android 13+/iOS)…
      await BeaconAlertNotifier.instance.ensureInitialized();
      final notifOk = await BeaconAlertNotifier.instance.requestPermission();
      if (!notifOk) {
        SnackBarService.showWarning(
          LocServ.inst.t('beacon_background_notif_denied'),
        );
        return;
      }
      // …and multi-hour scanning needs a battery-optimisation exemption.
      if (Platform.isAndroid &&
          !await Permission.ignoreBatteryOptimizations.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }
    await _update(cfg.copyWith(backgroundEnabled: enable));
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    return Scaffold(
      appBar: AppBar(title: Text(LocServ.inst.t('settings_beacons'))),
      body: cfg == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(LocServ.inst.t('beacon_detection_enable')),
                  subtitle: Text(
                    LocServ.inst.t('beacon_detection_enable_desc'),
                  ),
                  value: cfg.enabled,
                  onChanged: _toggleEnabled,
                ),
                const Divider(),
                ListTile(
                  title: Text(LocServ.inst.t('beacon_detection_threshold')),
                  subtitle: Text(
                    LocServ.inst.t('beacon_detection_threshold_desc', {
                      'v': '${cfg.rssiThresholdDbm}',
                    }),
                  ),
                ),
                Slider(
                  min: -100,
                  max: -40,
                  divisions: 60,
                  value: cfg.rssiThresholdDbm.toDouble(),
                  label: '${cfg.rssiThresholdDbm} dBm',
                  onChanged: cfg.enabled
                      ? (v) => setState(
                          () => _config = cfg.copyWith(
                            rssiThresholdDbm: v.round(),
                          ),
                        )
                      : null,
                  onChangeEnd: (v) =>
                      _update(cfg.copyWith(rssiThresholdDbm: v.round())),
                ),
                ListTile(
                  title: Text(LocServ.inst.t('beacon_detection_cooldown')),
                  subtitle: Text(
                    LocServ.inst.t('beacon_detection_cooldown_desc', {
                      'v': (cfg.cooldownSec / 60).toStringAsFixed(0),
                    }),
                  ),
                ),
                Slider(
                  min: 60,
                  max: 1800,
                  divisions: 29,
                  value: cfg.cooldownSec.toDouble().clamp(60, 1800),
                  label: '${(cfg.cooldownSec / 60).toStringAsFixed(0)} min',
                  onChanged: cfg.enabled
                      ? (v) => setState(
                          () => _config = cfg.copyWith(cooldownSec: v.round()),
                        )
                      : null,
                  onChangeEnd: (v) =>
                      _update(cfg.copyWith(cooldownSec: v.round())),
                ),
                SwitchListTile(
                  title: Text(LocServ.inst.t('beacon_detection_auto_open')),
                  subtitle: Text(
                    LocServ.inst.t('beacon_detection_auto_open_desc'),
                  ),
                  value: cfg.autoOpenPlace,
                  onChanged: cfg.enabled
                      ? (v) => _update(cfg.copyWith(autoOpenPlace: v))
                      : null,
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(LocServ.inst.t('beacon_background_enable')),
                  subtitle: Text(
                    LocServ.inst.t('beacon_background_enable_desc'),
                  ),
                  value: cfg.backgroundEnabled,
                  onChanged: cfg.enabled ? _toggleBackground : null,
                ),
                ListTile(
                  title: Text(LocServ.inst.t('beacon_background_interval')),
                  subtitle: Text(
                    LocServ.inst.t('beacon_background_interval_desc', {
                      'v': '${cfg.backgroundScanIntervalSec}',
                    }),
                  ),
                ),
                Slider(
                  min: 20,
                  max: 60,
                  divisions: 8,
                  value: cfg.backgroundScanIntervalSec.toDouble().clamp(20, 60),
                  label: '${cfg.backgroundScanIntervalSec} s',
                  onChanged: cfg.enabled && cfg.backgroundEnabled
                      ? (v) => setState(
                          () => _config = cfg.copyWith(
                            backgroundScanIntervalSec: v.round(),
                          ),
                        )
                      : null,
                  onChangeEnd: (v) => _update(
                    cfg.copyWith(backgroundScanIntervalSec: v.round()),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.bluetooth_searching),
                  title: Text(LocServ.inst.t('beacon_lab')),
                  subtitle: Text(LocServ.inst.t('beacon_lab_desc')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BeaconLabPage()),
                  ),
                ),
              ],
            ),
    );
  }
}
