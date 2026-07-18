import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/ruuvi_live_page.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/beacon_picker_dialog.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// BLE tag registrations (iBeacon + Ruuvi) for one cave place: lists
/// assigned tags with an unassign action and offers "Assign beacon" via
/// the nearby picker. Shown only for persisted places (needs the place
/// uuid).
///
/// Self-contained: reads/writes through [ref.read(beaconRepositoryProvider)] directly, so the
/// cave-place form save flow stays untouched (registrations are immediate,
/// like documents).
class CavePlaceBeaconSection extends ConsumerStatefulWidget {
  const CavePlaceBeaconSection({
    super.key,
    required this.cavePlaceUuid,
    required this.caveUuid,
  });

  final Uuid cavePlaceUuid;
  final Uuid caveUuid;

  @override
  ConsumerState<CavePlaceBeaconSection> createState() =>
      _CavePlaceBeaconSectionState();
}

class _CavePlaceBeaconSectionState
    extends ConsumerState<CavePlaceBeaconSection> {
  List<CavePlaceBeacon> _beacons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final beacons = await ref
        .read(beaconRepositoryProvider)
        .getBeaconsForPlace(widget.cavePlaceUuid);
    if (!mounted) return;
    setState(() {
      _beacons = beacons;
      _loading = false;
    });
  }

  Future<void> _assign() async {
    // Disable identities already registered anywhere in this cave.
    final caveBeacons = await ref
        .read(beaconRepositoryProvider)
        .getBeaconsForCave(widget.caveUuid);
    if (!mounted) return;
    final registered = {
      for (final b in caveBeacons) ?BeaconRepository.identityOf(b.beacon),
    };
    final picked = await BeaconPickerDialog.show(
      context,
      registeredIdentities: registered,
    );
    if (picked == null || !mounted) return;
    try {
      final repo = ref.read(beaconRepositoryProvider);
      if (picked.isRuuvi) {
        await repo.registerRuuviTag(
          cavePlaceUuid: widget.cavePlaceUuid,
          caveUuid: widget.caveUuid,
          macAddress: picked.macAddress!,
          model: picked.model,
        );
      } else {
        await repo.registerBeacon(
          cavePlaceUuid: widget.cavePlaceUuid,
          caveUuid: widget.caveUuid,
          proximityUuid: picked.proximityUuid!,
          major: picked.major!,
          minor: picked.minor!,
          macAddress: picked.macAddress,
        );
      }
      SnackBarService.showSuccess(LocServ.inst.t('beacon_registered'));
      await _load();
    } on DuplicateEntryException {
      // Race with another registration (the picker already greys out known
      // identities) — name the cause instead of the generic DB error.
      SnackBarService.showWarning(LocServ.inst.t('beacon_already_registered'));
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
            'identity': beacon.beaconType == BeaconTypes.ruuvi
                ? beacon.macAddress ?? ''
                : '${beacon.major}/${beacon.minor}',
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
      await ref.read(beaconRepositoryProvider).unregisterBeacon(beacon.uuid);
      SnackBarService.showSuccess(LocServ.inst.t('beacon_unregistered'));
      await _load();
    } catch (e) {
      SnackBarService.showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The header renders immediately (loading only delays the beacon tiles)
    // so the section doesn't pop in and shift the form layout.
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
        if (!_loading)
          for (final b in _beacons)
            b.beaconType == BeaconTypes.ruuvi
                ? ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 28),
                    leading: const Icon(Icons.sensors, size: 20),
                    title: Text(
                      b.model ?? 'Ruuvi',
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      '${b.macAddress}'
                      '${b.lastBatteryMv != null ? ' · ${b.lastBatteryMv} mV' : ''}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: b.macAddress == null
                        ? null
                        : () => RuuviLivePage.push(
                            context,
                            macAddress: b.macAddress!,
                            title: b.model,
                          ),
                    trailing: IconButton(
                      icon: const Icon(Icons.link_off, size: 20),
                      tooltip: LocServ.inst.t('beacon_unassign'),
                      onPressed: () => _unassign(b),
                    ),
                  )
                : ListTile(
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
