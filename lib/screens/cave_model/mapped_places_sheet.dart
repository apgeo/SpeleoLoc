import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_model/cave_model_mapping_controller.dart';
import 'package:speleoloc/utils/localization.dart';

/// The places mapped in the model on screen. A tap flies the camera to the
/// place and keeps the list open; the trailing buttons open the place's
/// raster map or its page. Places whose station the model lacks are listed
/// apart.
class MappedPlacesSheet extends StatefulWidget {
  const MappedPlacesSheet({
    super.key,
    required this.controller,
    required this.onFly,
    required this.onOpenOnMap,
    required this.onOpenPlace,
    required this.onMapUnmapped,
  });

  final CaveModelMappingController controller;
  final ValueChanged<CavePlace> onFly;
  final ValueChanged<CavePlace> onOpenOnMap;
  final ValueChanged<CavePlace> onOpenPlace;
  final VoidCallback onMapUnmapped;

  @override
  State<MappedPlacesSheet> createState() => _MappedPlacesSheetState();
}

class _MappedPlacesSheetState extends State<MappedPlacesSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.45,
    minChildSize: 0.2,
    maxChildSize: 0.9,
    builder: (context, scroll) => ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final needle = _filter.toLowerCase();
        bool shown(CavePlace p) =>
            needle.isEmpty || p.title.toLowerCase().contains(needle);
        final drawn = [
          for (final p in c.mappedPlaces)
            if (!c.unresolved.contains(p.uuid) && shown(p)) p,
        ];
        final missing = [
          for (final p in c.mappedPlaces)
            if (c.unresolved.contains(p.uuid) && shown(p)) p,
        ];
        final unmappedCount = c.unmappedPlaces.length;
        return ListView(
          controller: scroll,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: LocServ.inst.t('model_pick_place_hint'),
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            if (drawn.isEmpty && missing.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  LocServ.inst.t('model_no_mapped_places'),
                  textAlign: TextAlign.center,
                ),
              ),
            for (final p in drawn) _tile(p, c),
            if (missing.isNotEmpty) ...[
              ListTile(
                title: Text(
                  LocServ.inst.t('model_mapped_missing'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              for (final p in missing) _tile(p, c, missing: true),
            ],
            if (unmappedCount > 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onMapUnmapped();
                  },
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: Text(
                    LocServ.inst.t('model_map_unmapped', {
                      'count': '$unmappedCount',
                    }),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _tile(
    CavePlace place,
    CaveModelMappingController c, {
    bool missing = false,
  }) {
    final mapping = c.mappingOf(place.uuid)!;
    final splay = mapping.needsReview == 1;
    return ListTile(
      leading: Icon(
        missing ? Icons.location_disabled : Icons.place,
        color: missing ? null : const Color(0xFFFF9800),
      ),
      title: Text(place.title),
      subtitle: Text(
        splay
            ? '${mapping.station} · ${LocServ.inst.t('model_mapped_splay_review')}'
            : mapping.station,
      ),
      onTap: missing ? null : () => widget.onFly(place),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: LocServ.inst.t('model_open_on_map'),
            onPressed: () => widget.onOpenOnMap(place),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: LocServ.inst.t('model_open_place'),
            onPressed: () => widget.onOpenPlace(place),
          ),
        ],
      ),
    );
  }
}
