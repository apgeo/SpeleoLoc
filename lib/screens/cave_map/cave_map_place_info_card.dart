import 'package:flutter/material.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_item.dart';
import 'package:speleoloc/utils/coordinate_formats.dart';
import 'package:speleoloc/utils/localization.dart';

/// Bottom info card shown when a marker is tapped: place identity plus a
/// button to open the cave-place page (hidden in pick mode, where the map
/// only returns coordinates).
class CaveMapPlaceInfoCard extends StatelessWidget {
  const CaveMapPlaceInfoCard({
    super.key,
    required this.item,
    required this.onClose,
    this.onOpenPlace,
    this.onSetLocation,
    this.coordinateFormat = CoordinateDisplayFormat.decimal,
  });

  final CaveMapPlaceItem item;
  final VoidCallback onClose;
  final VoidCallback? onOpenPlace;

  /// Re-positions this place by placing a new point (tap / GPS). Null while
  /// the map is an external coordinate picker.
  final VoidCallback? onSetLocation;

  final CoordinateDisplayFormat coordinateFormat;

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final place = item.place;
    final details = <String>[
      formatCoordinates(place.latitude!, place.longitude!, coordinateFormat),
      if (place.altitude != null)
        '${loc.t('altitude')}: ${place.altitude!.toStringAsFixed(1)} m',
      if (place.depthInCave != null)
        '${loc.t('depth_in_cave')}: ${place.depthInCave!.toStringAsFixed(1)} m',
    ];

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.isMainEntrance
                        ? '${item.caveTitle} — ${loc.t('main_entrance')}'
                        : item.isEntrance
                            ? '${item.caveTitle} — ${loc.t('entrance')}'
                            : item.caveTitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  for (final line in details)
                    Text(line, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: loc.t('close'),
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                ),
                if (onOpenPlace != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20),
                    tooltip: loc.t('map_open_place'),
                    visualDensity: VisualDensity.compact,
                    onPressed: onOpenPlace,
                  ),
                if (onSetLocation != null)
                  IconButton(
                    icon: const Icon(Icons.edit_location_alt, size: 20),
                    tooltip: loc.t('map_set_location'),
                    visualDensity: VisualDensity.compact,
                    onPressed: onSetLocation,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
