import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

/// Whether a place has a QR code, as a glyph (filled vs outlined) with a
/// spoken and long-press label, so the state does not rest on colour alone.
class PlaceQrStatusIcon extends StatelessWidget {
  const PlaceQrStatusIcon({super.key, required this.hasCode});

  final bool hasCode;

  @override
  Widget build(BuildContext context) {
    final label = LocServ.inst.t(
      hasCode ? 'place_status_qr_yes' : 'place_status_qr_no',
    );
    return Tooltip(
      message: label,
      child: Icon(
        hasCode ? Icons.qr_code : Icons.qr_code_outlined,
        color: hasCode ? Colors.green.shade800 : Colors.grey.shade700,
        size: 20,
      ),
    );
  }
}

/// How many raster maps a place is placed on, out of [totalMaps] in its
/// cave. Each state has its own glyph, the count is written out, and the
/// whole chip is read aloud as a sentence; colour only reinforces it.
class PlaceMapStatusChip extends StatelessWidget {
  const PlaceMapStatusChip({
    super.key,
    required this.count,
    required this.totalMaps,
    required this.onTap,
  });

  final int count;
  final int totalMaps;
  final VoidCallback onTap;

  bool get _onAllMaps => totalMaps > 0 && count == totalMaps;

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final IconData icon;
    final Color color;
    final String label;
    if (count == 0) {
      icon = Icons.location_off;
      color = Colors.red.shade800;
      label = loc.t('place_status_maps_none');
    } else if (_onAllMaps) {
      icon = Icons.where_to_vote;
      color = Colors.green.shade800;
      label = loc.t('place_status_maps_all', {'total': '$totalMaps'});
    } else {
      icon = Icons.place;
      color = Colors.grey.shade700;
      label = loc.t('place_status_maps_some', {
        'count': '$count',
        'total': '$totalMaps',
      });
    }
    return Tooltip(
      message: label,
      // The sentence is already the chip's semantic label.
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 2),
                Text('$count', style: TextStyle(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
