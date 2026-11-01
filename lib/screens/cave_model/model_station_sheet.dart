import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/model_viewer_event.dart';
import 'package:speleoloc/utils/localization.dart';

/// What the 3D viewer's screen can do for one station, offered by
/// [ModelStationSheet]. Null actions are not offered.
class ModelStationActions {
  const ModelStationActions({
    required this.onCentre,
    this.onMapPlace,
    this.onMapSplay,
    this.onCreatePlace,
    this.onOpenPlace,
    this.onOpenOnMap,
    this.onUnmap,
    this.onDistance,
  });

  final VoidCallback onCentre;
  final VoidCallback? onMapPlace;
  final VoidCallback? onMapSplay;
  final VoidCallback? onCreatePlace;
  final ValueChanged<CavePlace>? onOpenPlace;
  final ValueChanged<CavePlace>? onOpenOnMap;
  final ValueChanged<CavePlace>? onUnmap;
  final ValueChanged<CavePlace>? onDistance;
}

/// A station tapped in the 3D viewer: its name and position, the places
/// mapped to it, and what can be done there.
class ModelStationSheet extends StatelessWidget {
  const ModelStationSheet({
    super.key,
    required this.station,
    required this.actions,
    this.placesHere = const [],
    this.splayPlaces = const {},
  });

  final ModelViewerStationTapped station;
  final ModelStationActions actions;
  final List<CavePlace> placesHere;

  /// Places of [placesHere] mapped to one of the station's splay ends.
  final Set<Uuid> splayPlaces;

  String? get _position {
    final (x, y, z) = (station.x, station.y, station.z);
    if (x == null || y == null || z == null) return null;
    return LocServ.inst.t('model_station_position', {
      'x': x.toStringAsFixed(1),
      'y': y.toStringAsFixed(1),
      'z': z.toStringAsFixed(1),
    });
  }

  void _run(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocServ.inst.t('model_station_title'),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            SelectableText(station.station, style: theme.textTheme.titleMedium),
            if (position != null) ...[
              const SizedBox(height: 4),
              Text(position),
            ],
            for (final place in placesHere) _placeTile(context, place),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (actions.onMapPlace case final map?)
                  OutlinedButton.icon(
                    onPressed: () => _run(context, map),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(LocServ.inst.t('model_map_place_here')),
                  ),
                if (actions.onMapSplay case final splay?)
                  OutlinedButton.icon(
                    onPressed: () => _run(context, splay),
                    icon: const Icon(Icons.call_split),
                    label: Text(LocServ.inst.t('model_map_splay_end')),
                  ),
                if (actions.onCreatePlace case final create?)
                  OutlinedButton.icon(
                    onPressed: () => _run(context, create),
                    icon: const Icon(Icons.add),
                    label: Text(LocServ.inst.t('model_new_place_here')),
                  ),
                FilledButton.tonalIcon(
                  onPressed: () => _run(context, actions.onCentre),
                  icon: const Icon(Icons.center_focus_strong),
                  label: Text(LocServ.inst.t('model_station_centre')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeTile(BuildContext context, CavePlace place) {
    void Function()? bind(ValueChanged<CavePlace>? action) =>
        action == null ? null : () => _run(context, () => action(place));
    final openPlace = bind(actions.onOpenPlace);
    final openOnMap = bind(actions.onOpenOnMap);
    final distance = bind(actions.onDistance);
    final unmap = bind(actions.onUnmap);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.place, color: Color(0xFFFF9800)),
      title: Text(place.title),
      subtitle: splayPlaces.contains(place.uuid)
          ? Text(LocServ.inst.t('model_mapped_splay_review'))
          : null,
      onTap: openPlace,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (openOnMap != null)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: LocServ.inst.t('model_open_on_map'),
              onPressed: openOnMap,
            ),
          if (distance != null)
            IconButton(
              icon: const Icon(Icons.straighten),
              tooltip: LocServ.inst.t('model_distance_from'),
              onPressed: distance,
            ),
          if (unmap != null)
            IconButton(
              icon: const Icon(Icons.link_off),
              tooltip: LocServ.inst.t('model_unmap'),
              onPressed: unmap,
            ),
        ],
      ),
    );
  }
}
