import 'dart:async';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speleoloc/services/beacon/beacon_scan_helper.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// A beacon chosen from the nearby-scan picker.
class PickedBeacon {
  final String proximityUuid;
  final int major;
  final int minor;
  final String? macAddress;
  final int rssi;

  const PickedBeacon({
    required this.proximityUuid,
    required this.major,
    required this.minor,
    this.macAddress,
    required this.rssi,
  });
}

/// Live-ranging dialog listing nearby iBeacons sorted by signal strength
/// (strongest first — hold the phone against the tag being installed).
/// Identities already registered are marked and disabled via
/// [registeredIdentities] (`UUID/major/minor`, uppercase UUID).
///
/// Resolves to the tapped beacon or null on cancel.
class BeaconPickerDialog extends StatefulWidget {
  const BeaconPickerDialog({super.key, this.registeredIdentities = const {}});

  final Set<String> registeredIdentities;

  static Future<PickedBeacon?> show(
    BuildContext context, {
    Set<String> registeredIdentities = const {},
  }) async {
    if (!await BeaconScanHelper.ensureAndroidPermissions()) {
      if (context.mounted) {
        SnackBarService.showWarning(
          LocServ.inst.t('beacon_lab_permissions_missing'),
        );
      }
      return null;
    }
    if (!context.mounted) return null;
    // BLE scan results are also gated behind the location master switch on
    // Android: with it off the scan silently returns nothing and the plugin's
    // own check hangs, so prompt the user to enable it before opening.
    if (!await BeaconScanHelper.ensureLocationServicesEnabled(context)) {
      return null;
    }
    if (!context.mounted) return null;
    return showDialog<PickedBeacon>(
      context: context,
      builder: (_) =>
          BeaconPickerDialog(registeredIdentities: registeredIdentities),
    );
  }

  @override
  State<BeaconPickerDialog> createState() => _BeaconPickerDialogState();
}

class _BeaconPickerDialogState extends State<BeaconPickerDialog> {
  /// A tag not ranged for this long has moved away (or stopped) — drop it
  /// so its stale RSSI can't outrank the tag actually held to the phone.
  static const _staleAfter = Duration(seconds: 15);

  final _log = AppLogger.of('BeaconPickerDialog');
  StreamSubscription<RangingResult>? _sub;
  final Map<String, _Seen> _seen = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await flutterBeacon.initializeAndCheckScanning;
    } on PlatformException catch (e, st) {
      _log.warning('Beacon picker init failed', e, st);
      if (mounted) setState(() => _error = e.message ?? e.code);
      return;
    }
    final uuids = await BeaconScanHelper.loadRegionUuids();
    // Dialog dismissed during init: subscribing now would outlive dispose.
    if (!mounted) return;
    _sub = flutterBeacon
        .ranging(BeaconScanHelper.buildRegions(uuids))
        .listen(
          (result) {
            final now = DateTime.now();
            for (final b in result.beacons) {
              final key =
                  '${b.proximityUUID.toUpperCase()}/${b.major}/${b.minor}';
              _seen[key] = _Seen(beacon: b, lastSeen: now);
            }
            final sizeBefore = _seen.length;
            _seen.removeWhere(
              (_, s) => now.difference(s.lastSeen) > _staleAfter,
            );
            if (mounted &&
                (result.beacons.isNotEmpty || _seen.length != sizeBefore)) {
              setState(() {});
            }
          },
          onError: (Object e, StackTrace st) {
            _log.warning('Beacon picker ranging error', e, st);
            if (mounted) setState(() => _error = e.toString());
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _seen.entries.toList()
      ..sort((a, b) => b.value.beacon.rssi.compareTo(a.value.beacon.rssi));
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(LocServ.inst.t('beacon_picker_title'))),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 340,
        child: _error != null
            ? Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            : entries.isEmpty
            ? Center(child: Text(LocServ.inst.t('beacon_picker_searching')))
            : ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final key = entries[i].key;
                  final b = entries[i].value.beacon;
                  final registered = widget.registeredIdentities.contains(key);
                  return ListTile(
                    dense: true,
                    enabled: !registered,
                    leading: Icon(
                      registered
                          ? Icons.check_circle
                          : Icons.bluetooth_searching,
                      color: registered ? Colors.green : null,
                    ),
                    title: Text(
                      'major ${b.major} / minor ${b.minor}'
                      '${registered ? ' — ${LocServ.inst.t('beacon_already_registered')}' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${b.proximityUUID.toUpperCase()}\n'
                      '${b.rssi} dBm'
                      '${b.macAddress != null ? ' · ${b.macAddress}' : ''}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    isThreeLine: true,
                    onTap: registered
                        ? null
                        : () => Navigator.pop(
                            context,
                            PickedBeacon(
                              proximityUuid: b.proximityUUID.toUpperCase(),
                              major: b.major,
                              minor: b.minor,
                              macAddress: b.macAddress,
                              rssi: b.rssi,
                            ),
                          ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocServ.inst.t('cancel')),
        ),
      ],
    );
  }
}

class _Seen {
  final Beacon beacon;
  final DateTime lastSeen;
  const _Seen({required this.beacon, required this.lastSeen});
}
