import 'package:flutter/material.dart';
import 'package:speleoloc/screens/cave_map/cave_map_place_item.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/map/cave_map_marker_icons.dart';

/// Inline list of cave places (`<place title> - <cave title>`) shown on
/// the map screen itself. Tapping an entry asks the map to navigate to it.
class CaveMapPlaceListPanel extends StatelessWidget {
  const CaveMapPlaceListPanel({
    super.key,
    required this.items,
    required this.onItemSelected,
  });

  final List<CaveMapPlaceItem> items;
  final ValueChanged<CaveMapPlaceItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(LocServ.inst.t('map_no_places_with_coords')),
        ),
      );
    }
    final sorted = [...items]
      ..sort(
        (a, b) =>
            a.listLabel.toLowerCase().compareTo(b.listLabel.toLowerCase()),
      );
    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = sorted[index];
        return ListTile(
          dense: true,
          leading: item.isEntrance
              ? CaveEntranceMarkerIcon(
                  size: 22,
                  color: item.isMainEntrance
                      ? const Color(0xFF3E2723)
                      : const Color(0xFF6D4C41),
                )
              : const PlacePointMarkerIcon(size: 14, color: Colors.blueGrey),
          title: Text(item.listLabel, overflow: TextOverflow.ellipsis),
          subtitle: item.isMainEntrance
              ? Text(LocServ.inst.t('main_entrance'))
              : item.isEntrance
                  ? Text(LocServ.inst.t('entrance'))
                  : null,
          onTap: () => onItemSelected(item),
        );
      },
    );
  }
}
