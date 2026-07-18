import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speleoloc/screens/ruuvi_history_page.dart';
import 'package:speleoloc/services/beacon/beacon_scan_helper.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_scan_service.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Live readout of one Ruuvi tag from its advertisements — no connection
/// needed: current temperature/humidity/pressure/battery, motion
/// (movement counter + acceleration) and signal diagnostics (RSSI, TX
/// power, packet-loss estimate from measurement-sequence gaps).
class RuuviLivePage extends StatefulWidget {
  const RuuviLivePage({super.key, required this.macAddress, this.title});

  final String macAddress;

  /// Context line, e.g. the place the tag is assigned to.
  final String? title;

  /// Runs the scan permission/location gate, then opens the page.
  static Future<void> push(
    BuildContext context, {
    required String macAddress,
    String? title,
  }) async {
    if (!await BeaconScanHelper.ensureAndroidPermissions()) {
      if (context.mounted) {
        SnackBarService.showWarning(
          LocServ.inst.t('beacon_lab_permissions_missing'),
        );
      }
      return;
    }
    if (!context.mounted) return;
    if (!await BeaconScanHelper.ensureLocationServicesEnabled(context)) {
      return;
    }
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RuuviLivePage(macAddress: macAddress, title: title),
      ),
    );
  }

  @override
  State<RuuviLivePage> createState() => _RuuviLivePageState();
}

class _RuuviLivePageState extends State<RuuviLivePage> {
  StreamSubscription<RuuviSighting>? _sub;
  Timer? _ageTicker;
  RuuviSighting? _last;

  // Packet-loss estimate: the measurement sequence increments once per
  // advertisement interval, so gaps between received values ≈ missed
  // packets (duplicates within one interval are ignored).
  int _received = 0;
  int _expected = 0;
  int? _lastSequence;

  @override
  void initState() {
    super.initState();
    _sub = RuuviScanService.instance.sightings.listen((s) {
      if (s.advertisement.macAddress != widget.macAddress.toUpperCase()) {
        return;
      }
      _trackSequence(s.advertisement.measurementSequence);
      if (mounted) setState(() => _last = s);
    });
    // Repaint the "updated Ns ago" line while no packets arrive.
    _ageTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _last != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ageTicker?.cancel();
    super.dispose();
  }

  void _trackSequence(int? sequence) {
    if (sequence == null) return;
    final last = _lastSequence;
    _lastSequence = sequence;
    if (last == null) {
      _received = 1;
      _expected = 1;
      return;
    }
    // Wraps at 65534 → 0; delta 0 is a re-received copy of the same frame.
    final delta = (sequence - last + 65535) % 65535;
    if (delta == 0) return;
    _received += 1;
    _expected += delta;
  }

  @override
  Widget build(BuildContext context) {
    final s = _last;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? LocServ.inst.t('ruuvi_live_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: LocServ.inst.t('ruuvi_history_title'),
            onPressed: () => RuuviHistoryPage.push(
              context,
              macAddress: widget.macAddress,
              title: widget.title,
            ),
          ),
        ],
      ),
      body: s == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  LocServ.inst.t('ruuvi_live_waiting'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _content(s),
    );
  }

  Widget _content(RuuviSighting s) {
    final adv = s.advertisement;
    final age = DateTime.now().difference(s.seenAt).inSeconds;
    final lossPct = _expected > 1
        ? (100 * (1 - _received / _expected)).clamp(0, 100).toStringAsFixed(0)
        : null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${adv.inferredModel.label} · ${adv.macAddress}\n'
          '${LocServ.inst.t('ruuvi_updated_ago', {'s': '$age'})}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.9,
          children: [
            _metric(
              LocServ.inst.t('ruuvi_temperature'),
              adv.temperatureC != null
                  ? '${adv.temperatureC!.toStringAsFixed(2)} °C'
                  : '—',
            ),
            _metric(
              LocServ.inst.t('ruuvi_humidity'),
              adv.humidityPct != null
                  ? '${adv.humidityPct!.toStringAsFixed(1)} %'
                  : '—',
            ),
            _metric(
              LocServ.inst.t('ruuvi_pressure'),
              adv.pressureHpa != null
                  ? '${adv.pressureHpa!.toStringAsFixed(1)} hPa'
                  : '—',
            ),
            _metric(
              LocServ.inst.t('ruuvi_battery'),
              adv.batteryMv != null ? '${adv.batteryMv} mV' : '—',
              warn: adv.isLowBattery,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.vibration),
          title: Text(LocServ.inst.t('ruuvi_motion')),
          subtitle: Text(
            '${LocServ.inst.t('ruuvi_movement_count')}: '
            '${adv.movementCounter ?? '—'}\n'
            '${LocServ.inst.t('ruuvi_acceleration')}: '
            '(${adv.accelerationXMg ?? '—'}, ${adv.accelerationYMg ?? '—'}, '
            '${adv.accelerationZMg ?? '—'}) mG',
          ),
          isThreeLine: true,
        ),
        ListTile(
          leading: const Icon(Icons.network_check),
          title: Text(LocServ.inst.t('ruuvi_signal')),
          subtitle: Text(
            'RSSI: ${s.rssi} dBm'
            '${adv.txPowerDbm != null ? ' · ${LocServ.inst.t('ruuvi_tx_power')}: ${adv.txPowerDbm} dBm' : ''}'
            '${lossPct != null ? '\n${LocServ.inst.t('ruuvi_packet_loss')}: $lossPct % ($_received/$_expected)' : ''}',
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, String value, {bool warn = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (warn)
                  const Icon(
                    Icons.battery_alert,
                    size: 16,
                    color: Colors.orange,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
