import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/ruuvi_live_page.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_advertisement_parser.dart';
import 'package:speleoloc/utils/app_routes.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Maintenance view: every tag registered in one cave (iBeacon or Ruuvi)
/// with its place, identity, last-seen time, battery and last readings.
/// Entry point: cave places list → cave management menu.
class CaveBeaconsPage extends ConsumerStatefulWidget {
  const CaveBeaconsPage({super.key, required this.caveUuid});

  final Uuid caveUuid;

  @override
  ConsumerState<CaveBeaconsPage> createState() => _CaveBeaconsPageState();
}

class _CaveBeaconsPageState extends ConsumerState<CaveBeaconsPage> {
  List<BeaconWithPlace> _beacons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final beacons = await ref
        .read(beaconRepositoryProvider)
        .getBeaconsForCave(widget.caveUuid);
    if (!mounted) return;
    beacons.sort((a, b) => a.cavePlace.title.compareTo(b.cavePlace.title));
    setState(() {
      _beacons = beacons;
      _loading = false;
    });
  }

  Future<void> _unregister(BeaconWithPlace item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(
          LocServ.inst.t('beacon_unassign_confirm', {
            'identity': item.beacon.beaconType == BeaconTypes.ruuvi
                ? item.beacon.macAddress ?? ''
                : '${item.beacon.major}/${item.beacon.minor}',
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('yes')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(beaconRepositoryProvider)
          .unregisterBeacon(item.beacon.uuid);
      SnackBarService.showSuccess(LocServ.inst.t('beacon_unregistered'));
      await _load();
    } catch (e) {
      SnackBarService.showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocServ.inst.t('cave_beacons_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _beacons.isEmpty
          ? Center(child: Text(LocServ.inst.t('cave_beacons_empty')))
          : ListView.separated(
              itemCount: _beacons.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _tile(_beacons[i]),
            ),
    );
  }

  Widget _tile(BeaconWithPlace item) {
    final b = item.beacon;
    final isRuuvi = b.beaconType == BeaconTypes.ruuvi;
    final lastSeen = b.lastSeenAt != null
        ? DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(DateTime.fromMillisecondsSinceEpoch(b.lastSeenAt!))
        : LocServ.inst.t('beacon_never_seen');
    final lowBattery =
        isRuuvi &&
        b.lastBatteryMv != null &&
        b.lastBatteryMv! < ruuviLowBatteryMv;
    final identityLine = isRuuvi
        ? '${b.model ?? 'Ruuvi'} · ${b.macAddress}'
              '${b.firmwareVersion != null ? ' · fw ${b.firmwareVersion}' : ''}'
        : 'major ${b.major} / minor ${b.minor} · ${b.proximityUuid}';
    final readings = [
      if (b.lastTemperatureC != null)
        '${b.lastTemperatureC!.toStringAsFixed(1)} °C',
      if (b.lastHumidityPct != null)
        '${b.lastHumidityPct!.toStringAsFixed(1)} %',
      if (b.lastPressureHpa != null)
        '${b.lastPressureHpa!.toStringAsFixed(1)} hPa',
    ].join(' · ');
    return ListTile(
      leading: Icon(isRuuvi ? Icons.sensors : Icons.wifi_tethering),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.cavePlace.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (lowBattery)
            Tooltip(
              message: LocServ.inst.t('ruuvi_low_battery'),
              child: const Icon(
                Icons.battery_alert,
                size: 18,
                color: Colors.orange,
              ),
            ),
        ],
      ),
      subtitle: Text(
        '$identityLine\n'
        '${LocServ.inst.t('beacon_last_seen')}: $lastSeen'
        '${b.lastBatteryMv != null ? ' · ${b.lastBatteryMv} mV' : ''}'
        '${!isRuuvi && b.macAddress != null ? ' · ${b.macAddress}' : ''}'
        '${readings.isNotEmpty ? ' · $readings' : ''}',
        style: const TextStyle(fontSize: 12),
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRuuvi && b.macAddress != null)
            IconButton(
              icon: const Icon(Icons.monitor_heart_outlined),
              tooltip: LocServ.inst.t('ruuvi_live_title'),
              onPressed: () => RuuviLivePage.push(
                context,
                macAddress: b.macAddress!,
                title: item.cavePlace.title,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.link_off),
            tooltip: LocServ.inst.t('beacon_unassign'),
            onPressed: () => _unregister(item),
          ),
        ],
      ),
      onTap: () => AppRoutes.pushCavePlace(
        context,
        caveUuid: item.cavePlace.caveUuid,
        cavePlaceUuid: item.cavePlace.uuid,
      ),
    );
  }
}
