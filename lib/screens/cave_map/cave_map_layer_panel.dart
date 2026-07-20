import 'package:flutter/material.dart';
import 'package:speleoloc/services/map/mbtiles_registry.dart';
import 'package:speleoloc/services/map/tile_layer_sources.dart';
import 'package:speleoloc/utils/localization.dart';

/// Inline layer picker: radio list of base layers (built-in online sources
/// plus MBTiles files configured as base maps) and checkboxes for MBTiles
/// overlays. Base selections use the id scheme of the map screen:
/// a built-in source id, or `mbtiles:<fileName>`.
class CaveMapLayerPanel extends StatelessWidget {
  const CaveMapLayerPanel({
    super.key,
    required this.baseSources,
    required this.mbtilesBaseFiles,
    required this.mbtilesOverlayFiles,
    required this.selectedBaseId,
    required this.enabledOverlayFiles,
    required this.onBaseSelected,
    required this.onOverlayToggled,
  });

  final List<TileLayerSource> baseSources;
  final List<MbTilesDescriptor> mbtilesBaseFiles;
  final List<MbTilesDescriptor> mbtilesOverlayFiles;
  final String selectedBaseId;
  final Set<String> enabledOverlayFiles;
  final ValueChanged<String> onBaseSelected;
  final void Function(String fileName, bool enabled) onOverlayToggled;

  static String baseIdForMbTiles(String fileName) => 'mbtiles:$fileName';

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            loc.t('map_base_layer'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        RadioGroup<String>(
          groupValue: selectedBaseId,
          onChanged: (v) {
            if (v != null) onBaseSelected(v);
          },
          child: Column(
            children: [
              for (final source in baseSources)
                RadioListTile<String>(
                  dense: true,
                  value: source.id,
                  title: Text(source.name),
                ),
              for (final file in mbtilesBaseFiles)
                RadioListTile<String>(
                  dense: true,
                  value: baseIdForMbTiles(file.fileName),
                  title: Text(file.displayName),
                  subtitle: Text(file.fileName),
                ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            loc.t('map_overlays'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (mbtilesOverlayFiles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              loc.t('map_mbtiles_none_found'),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
        for (final file in mbtilesOverlayFiles)
          CheckboxListTile(
            dense: true,
            value: enabledOverlayFiles.contains(file.fileName),
            title: Text(file.displayName),
            subtitle: Text(file.fileName),
            onChanged: (v) => onOverlayToggled(file.fileName, v ?? false),
          ),
      ],
    );
  }
}
