import 'package:flutter/material.dart';
import 'package:speleoloc/screens/cave_map/cave_map_measure.dart';
import 'package:speleoloc/utils/localization.dart';

/// Bottom bar shown in measure mode: total distance, the last leg's
/// distance and bearing, undo-last-point and close.
class CaveMapMeasureBar extends StatelessWidget {
  const CaveMapMeasureBar({
    super.key,
    required this.path,
    required this.onUndo,
    required this.onClose,
  });

  final MeasurePath path;
  final VoidCallback onUndo;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final leg = path.lastLegMeters;
    final bearing = path.lastLegBearingDegrees;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            const Icon(Icons.straighten, size: 20, color: Color(0xFFE65100)),
            const SizedBox(width: 10),
            Expanded(
              child: path.points.length < 2
                  ? Text(
                      loc.t('map_measure_hint'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${loc.t('map_measure_total')}: '
                          '${MeasurePath.formatMeters(path.totalMeters)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${loc.t('map_measure_leg')}: '
                          '${MeasurePath.formatMeters(leg!)} · '
                          '${bearing!.round()}°',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.undo, size: 20),
              tooltip: loc.t('map_measure_undo'),
              visualDensity: VisualDensity.compact,
              onPressed: path.points.isEmpty ? null : onUndo,
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: loc.t('close'),
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
