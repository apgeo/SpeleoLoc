import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:speleoloc/utils/localization.dart';

/// Bottom action bar of pick mode: shows which place is being positioned,
/// the currently picked coordinates (or the tap hint), and cancel/save.
class CaveMapPickBar extends StatelessWidget {
  const CaveMapPickBar({
    super.key,
    required this.placeTitle,
    required this.pickedPoint,
    required this.onCancel,
    required this.onSave,
  });

  final String placeTitle;
  final LatLng? pickedPoint;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final picked = pickedPoint;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    placeTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    picked == null
                        ? loc.t('map_pick_hint')
                        : '${picked.latitude.toStringAsFixed(6)}, '
                            '${picked.longitude.toStringAsFixed(6)}'
                            '  ·  ${loc.t('map_pick_tap_to_change')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onCancel,
              child: Text(loc.t('cancel')),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: picked != null ? onSave : null,
              child: Text(loc.t('map_pick_save')),
            ),
          ],
        ),
      ),
    );
  }
}
