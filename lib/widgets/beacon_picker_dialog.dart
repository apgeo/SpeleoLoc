import 'dart:async';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/services/beacon/beacon_scan_helper.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_scan_service.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// A tag chosen from the nearby-scan picker: an iBeacon (identity triple)
/// or a Ruuvi tag (identity MAC), discriminated by [beaconType].
class PickedBeacon {
  final String beaconType;
  final String? proximityUuid;
  final int? major;
  final int? minor;
  final String? macAddress;
  final String? model;
  final int rssi;

  const PickedBeacon({
    required this.beaconType,
    this.proximityUuid,
    this.major,
    this.minor,
    this.macAddress,
    this.model,
    required this.rssi,
  });

  bool get isRuuvi => beaconType == BeaconTypes.ruuvi;
}

/// Live dialog listing nearby tags sorted by signal strength (strongest
/// first — hold the phone against the tag being installed). Two scan
/// sources feed one list: iBeacon ranging and the shared Ruuvi
/// advertisement scan. Identities already registered are marked and
/// disabled via [registeredIdentities] (`UUID/major/minor` or
/// `RUUVI/<MAC>`, uppercase).
///
/// Resolves to the tapped tag or null on cancel.
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
  /// A tag not seen for this long has moved away (or stopped) — drop it
  /// so its stale RSSI can't outrank the tag actually held to the phone.
  static const _staleAfter = Duration(seconds: 15);

  final _log = AppLogger.of('BeaconPickerDialog');
  StreamSubscription<RangingResult>? _rangingSub;
  StreamSubscription<RuuviSighting>? _ruuviSub;
  final Map<String, _Seen> _seen = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _rangingSub?.cancel();
    _ruuviSub?.cancel();
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
    _rangingSub = flutterBeacon
        .ranging(BeaconScanHelper.buildRegions(uuids))
        .listen(
          (result) {
            final now = DateTime.now();
            for (final b in result.beacons) {
              final key =
                  '${b.proximityUUID.toUpperCase()}/${b.major}/${b.minor}';
              _seen[key] = _Seen.iBeacon(b, now);
            }
            _refresh(now, changed: result.beacons.isNotEmpty);
          },
          onError: (Object e, StackTrace st) {
            _log.warning('Beacon picker ranging error', e, st);
            if (mounted) setState(() => _error = e.toString());
          },
        );
    _ruuviSub = RuuviScanService.instance.sightings.listen((s) {
      _seen[s.identity] = _Seen.ruuvi(s);
      _refresh(DateTime.now(), changed: true);
    });
  }

  void _refresh(DateTime now, {required bool changed}) {
    final sizeBefore = _seen.length;
    _seen.removeWhere((_, s) => now.difference(s.lastSeen) > _staleAfter);
    if (mounted && (changed || _seen.length != sizeBefore)) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _seen.entries.toList()
      ..sort((a, b) => b.value.rssi.compareTo(a.value.rssi));
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
                itemBuilder: (_, i) => _tile(entries[i].key, entries[i].value),
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

  Widget _tile(String key, _Seen seen) {
    final registered = widget.registeredIdentities.contains(key);
    final registeredSuffix = registered
        ? ' — ${LocServ.inst.t('beacon_already_registered')}'
        : '';
    final ruuvi = seen.ruuvi;
    if (ruuvi != null) {
      final adv = ruuvi.advertisement;
      final readings = [
        if (adv.temperatureC != null)
          '${adv.temperatureC!.toStringAsFixed(2)} °C',
        if (adv.humidityPct != null)
          '${adv.humidityPct!.toStringAsFixed(1)} %',
        if (adv.pressureHpa != null)
          '${adv.pressureHpa!.toStringAsFixed(1)} hPa',
        if (adv.batteryMv != null) '${adv.batteryMv} mV',
      ].join(' · ');
      return ListTile(
        dense: true,
        enabled: !registered,
        leading: Icon(
          registered ? Icons.check_circle : Icons.sensors,
          color: registered ? Colors.green : null,
        ),
        title: Text(
          '${adv.inferredModel.label}$registeredSuffix',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${adv.macAddress}\n${ruuvi.rssi} dBm · $readings',
          style: const TextStyle(fontSize: 11),
        ),
        isThreeLine: true,
        onTap: registered
            ? null
            : () => Navigator.pop(
                context,
                PickedBeacon(
                  beaconType: BeaconTypes.ruuvi,
                  macAddress: adv.macAddress,
                  model: adv.inferredModel.label,
                  rssi: ruuvi.rssi,
                ),
              ),
      );
    }
    final b = seen.beacon!;
    return ListTile(
      dense: true,
      enabled: !registered,
      leading: Icon(
        registered ? Icons.check_circle : Icons.bluetooth_searching,
        color: registered ? Colors.green : null,
      ),
      title: Text(
        'major ${b.major} / minor ${b.minor}$registeredSuffix',
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
                beaconType: BeaconTypes.iBeacon,
                proximityUuid: b.proximityUUID.toUpperCase(),
                major: b.major,
                minor: b.minor,
                macAddress: b.macAddress,
                rssi: b.rssi,
              ),
            ),
    );
  }
}

class _Seen {
  final Beacon? beacon;
  final RuuviSighting? ruuvi;
  final DateTime lastSeen;

  const _Seen.iBeacon(Beacon this.beacon, this.lastSeen) : ruuvi = null;

  _Seen.ruuvi(RuuviSighting this.ruuvi) : beacon = null, lastSeen = ruuvi.seenAt;

  int get rssi => ruuvi?.rssi ?? beacon!.rssi;
}
