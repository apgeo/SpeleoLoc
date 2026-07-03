import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_routes.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Maintenance view: every beacon registered in one cave with its place,
/// identity, last-seen time and battery. Entry point: cave places list →
/// cave management menu.
class CaveBeaconsPage extends StatefulWidget {
  const CaveBeaconsPage({super.key, required this.caveUuid});

  final Uuid caveUuid;

  @override
  State<CaveBeaconsPage> createState() => _CaveBeaconsPageState();
}

class _CaveBeaconsPageState extends State<CaveBeaconsPage> {
  List<BeaconWithPlace> _beacons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final beacons = await beaconRepository.getBeaconsForCave(widget.caveUuid);
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
            'identity': '${item.beacon.major}/${item.beacon.minor}',
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
      await beaconRepository.unregisterBeacon(item.beacon.uuid);
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
    final lastSeen = b.lastSeenAt != null
        ? DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(DateTime.fromMillisecondsSinceEpoch(b.lastSeenAt!))
        : LocServ.inst.t('beacon_never_seen');
    return ListTile(
      leading: const Icon(Icons.wifi_tethering),
      title: Text(
        item.cavePlace.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'major ${b.major} / minor ${b.minor} · ${b.proximityUuid}\n'
        '${LocServ.inst.t('beacon_last_seen')}: $lastSeen'
        '${b.lastBatteryMv != null ? ' · ${b.lastBatteryMv} mV' : ''}'
        '${b.macAddress != null ? ' · ${b.macAddress}' : ''}',
        style: const TextStyle(fontSize: 12),
      ),
      isThreeLine: true,
      trailing: IconButton(
        icon: const Icon(Icons.link_off),
        tooltip: LocServ.inst.t('beacon_unassign'),
        onPressed: () => _unregister(item),
      ),
      onTap: () => AppRoutes.pushCavePlace(
        context,
        caveUuid: item.cavePlace.caveUuid,
        cavePlaceUuid: item.cavePlace.uuid,
      ),
    );
  }
}
