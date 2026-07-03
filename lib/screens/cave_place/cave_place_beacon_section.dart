import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/beacon_picker_dialog.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// BLE beacon registrations for one cave place: lists assigned beacons
/// with an unassign action and offers "Assign beacon" via the nearby
/// picker. Shown only for persisted places (needs the place uuid).
///
/// Self-contained: reads/writes through [beaconRepository] directly, so the
/// cave-place form save flow stays untouched (registrations are immediate,
/// like documents).
class CavePlaceBeaconSection extends StatefulWidget {
  const CavePlaceBeaconSection({
    super.key,
    required this.cavePlaceUuid,
    required this.caveUuid,
  });

  final Uuid cavePlaceUuid;
  final Uuid caveUuid;

  @override
  State<CavePlaceBeaconSection> createState() => _CavePlaceBeaconSectionState();
}

class _CavePlaceBeaconSectionState extends State<CavePlaceBeaconSection> {
  List<CavePlaceBeacon> _beacons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final beacons = await beaconRepository.getBeaconsForPlace(
      widget.cavePlaceUuid,
    );
    if (!mounted) return;
    setState(() {
      _beacons = beacons;
      _loading = false;
    });
  }

  Future<void> _assign() async {
    // Disable identities already registered anywhere in this cave.
    final caveBeacons = await beaconRepository.getBeaconsForCave(
      widget.caveUuid,
    );
    if (!mounted) return;
    final registered = {
      for (final b in caveBeacons)
        '${b.beacon.proximityUuid}/${b.beacon.major}/${b.beacon.minor}',
    };
    final picked = await BeaconPickerDialog.show(
      context,
      registeredIdentities: registered,
    );
    if (picked == null || !mounted) return;
    try {
      await beaconRepository.registerBeacon(
        cavePlaceUuid: widget.cavePlaceUuid,
        caveUuid: widget.caveUuid,
        proximityUuid: picked.proximityUuid,
        major: picked.major,
        minor: picked.minor,
        macAddress: picked.macAddress,
      );
      SnackBarService.showSuccess(LocServ.inst.t('beacon_registered'));
      await _load();
    } catch (e) {
      SnackBarService.showError(e);
    }
  }

  Future<void> _unassign(CavePlaceBeacon beacon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(
          LocServ.inst.t('beacon_unassign_confirm', {
            'identity': '${beacon.major}/${beacon.minor}',
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
      await beaconRepository.unregisterBeacon(beacon.uuid);
      SnackBarService.showSuccess(LocServ.inst.t('beacon_unregistered'));
      await _load();
    } catch (e) {
      SnackBarService.showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bluetooth, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LocServ.inst.t('beacons_section_title'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_link, size: 18),
              label: Text(LocServ.inst.t('beacon_assign')),
              onPressed: _assign,
            ),
          ],
        ),
        for (final b in _beacons)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 28),
            leading: const Icon(Icons.wifi_tethering, size: 20),
            title: Text(
              'major ${b.major} / minor ${b.minor}',
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              '${b.proximityUuid}'
              '${b.macAddress != null ? '\n${b.macAddress}' : ''}'
              '${b.lastBatteryMv != null ? ' · ${b.lastBatteryMv} mV' : ''}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.link_off, size: 20),
              tooltip: LocServ.inst.t('beacon_unassign'),
              onPressed: () => _unassign(b),
            ),
          ),
      ],
    );
  }
}
