import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

/// Finds a station of the model by its name. Pops with the name, or null.
class ModelStationSearchSheet extends StatefulWidget {
  const ModelStationSearchSheet({super.key, required this.names});

  final List<String> names;

  @override
  State<ModelStationSearchSheet> createState() =>
      _ModelStationSearchSheetState();
}

class _ModelStationSearchSheetState extends State<ModelStationSearchSheet> {
  // A survey can name ten thousand stations; a list that long is no help
  // until a few letters narrow it.
  static const _shownAtMost = 200;
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final needle = _filter.toLowerCase();
    final matches = needle.isEmpty
        ? const <String>[]
        : widget.names
              .where((n) => n.toLowerCase().contains(needle))
              .take(_shownAtMost)
              .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: LocServ.inst.t('model_search_station_hint', {
                  'count': '${widget.names.length}',
                }),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: matches.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(matches[i]),
                onTap: () => Navigator.of(context).pop(matches[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
