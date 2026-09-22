import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/utils/localization.dart';

/// Single-selection picker over the places of one cave, filtered by a
/// substring of the title or place code.
///
/// Resolves to the tapped [CavePlace], or null on cancel.
class CavePlacePickerDialog extends ConsumerStatefulWidget {
  const CavePlacePickerDialog({super.key, required this.caveUuid});

  final Uuid caveUuid;

  static Future<CavePlace?> show(BuildContext context, Uuid caveUuid) {
    return showDialog<CavePlace>(
      context: context,
      builder: (_) => CavePlacePickerDialog(caveUuid: caveUuid),
    );
  }

  @override
  ConsumerState<CavePlacePickerDialog> createState() =>
      _CavePlacePickerDialogState();
}

class _CavePlacePickerDialogState extends ConsumerState<CavePlacePickerDialog> {
  final _queryController = TextEditingController();
  List<CavePlace>? _places;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final places = await ref
        .read(cavePlaceRepositoryProvider)
        .getCavePlaces(widget.caveUuid);
    places.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    if (mounted) setState(() => _places = places);
  }

  List<CavePlace> get _filtered {
    final all = _places ?? const <CavePlace>[];
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where(
          (p) =>
              p.title.toLowerCase().contains(q) ||
              (p.placeCodeIdentifier?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final places = _places;
    final filtered = _filtered;
    return AlertDialog(
      title: Text(LocServ.inst.t('trip_point_pick_place_title')),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: LocServ.inst.t('search'),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: places == null
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? Center(
                      child: Text(
                        LocServ.inst.t('trip_point_no_places'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final place = filtered[i];
                        return ListTile(
                          dense: true,
                          title: Text(place.title),
                          subtitle: place.placeCodeIdentifier != null
                              ? Text(place.placeCodeIdentifier!)
                              : null,
                          onTap: () => Navigator.pop(context, place),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocServ.inst.t('cancel')),
        ),
      ],
    );
  }
}
