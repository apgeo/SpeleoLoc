import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/localization.dart';

/// Picks the cave place to map to a station. Places already mapped in this
/// model say where; picking one moves it. Pops with the place, or null.
class ModelPlacePickerSheet extends StatefulWidget {
  const ModelPlacePickerSheet({
    super.key,
    required this.places,
    required this.stationOf,
  });

  final List<CavePlace> places;

  /// The station a place is mapped to in this model, or null.
  final String? Function(CavePlace place) stationOf;

  @override
  State<ModelPlacePickerSheet> createState() => _ModelPlacePickerSheetState();
}

class _ModelPlacePickerSheetState extends State<ModelPlacePickerSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final needle = _filter.toLowerCase();
    final shown = [
      for (final p in widget.places)
        if (needle.isEmpty || p.title.toLowerCase().contains(needle)) p,
    ];
    // Unmapped places first: they are what is usually being mapped.
    shown.sort((a, b) {
      final am = widget.stationOf(a) != null ? 1 : 0;
      final bm = widget.stationOf(b) != null ? 1 : 0;
      return am != bm ? am - bm : a.title.compareTo(b.title);
    });
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: LocServ.inst.t('model_pick_place_hint'),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(child: Text(LocServ.inst.t('model_no_places')))
                : ListView.builder(
                    controller: scroll,
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final place = shown[i];
                      final station = widget.stationOf(place);
                      return ListTile(
                        leading: Icon(
                          station == null ? Icons.place_outlined : Icons.place,
                        ),
                        title: Text(place.title),
                        subtitle: station == null
                            ? null
                            : Text(
                                LocServ.inst.t('model_mapped_at', {
                                  'station': station,
                                }),
                              ),
                        onTap: () => Navigator.of(context).pop(place),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
