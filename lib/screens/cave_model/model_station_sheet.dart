import 'package:flutter/material.dart';
import 'package:speleoloc/services/cave_model/model_viewer_event.dart';
import 'package:speleoloc/utils/localization.dart';

/// What the app shows for a station tapped in the 3D viewer.
class ModelStationSheet extends StatelessWidget {
  const ModelStationSheet({
    super.key,
    required this.station,
    required this.onCentre,
  });

  final ModelViewerStationTapped station;
  final VoidCallback onCentre;

  String? get _position {
    final (x, y, z) = (station.x, station.y, station.z);
    if (x == null || y == null || z == null) return null;
    return LocServ.inst.t('model_station_position', {
      'x': x.toStringAsFixed(1),
      'y': y.toStringAsFixed(1),
      'z': z.toStringAsFixed(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocServ.inst.t('model_station_title'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            SelectableText(
              station.station,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (position != null) ...[
              const SizedBox(height: 4),
              Text(position),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onCentre,
                icon: const Icon(Icons.center_focus_strong),
                label: Text(LocServ.inst.t('model_station_centre')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
