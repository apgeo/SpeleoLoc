import 'package:flutter/material.dart';
import 'package:speleoloc/state/raster_map_sort_options.dart';
import 'package:speleoloc/utils/localization.dart';

// The sort models (enums + option classes) are pure Dart and live in
// lib/state/ so non-UI code can use them; re-export them here so widget-layer
// callers keep a single import for models + picker dialogs.
export 'package:speleoloc/state/raster_map_sort_options.dart';

/// Opens a dialog for choosing a [CavePlaceSortOption] for the nav bar list.
///
/// Returns the chosen option, or `null` if dismissed.
Future<CavePlaceSortOption?> showCavePlacesSortDialog(
  BuildContext context,
  CavePlaceSortOption current,
) {
  return showDialog<CavePlaceSortOption>(
    context: context,
    builder: (context) => _CavePlacesSortDialog(current: current),
  );
}

class _CavePlacesSortDialog extends StatefulWidget {
  const _CavePlacesSortDialog({required this.current});
  final CavePlaceSortOption current;

  @override
  State<_CavePlacesSortDialog> createState() => _CavePlacesSortDialogState();
}

class _CavePlacesSortDialogState extends State<_CavePlacesSortDialog> {
  late CavePlaceSortField _field;
  late bool _ascending;

  @override
  void initState() {
    super.initState();
    _field = widget.current.field;
    _ascending = widget.current.ascending;
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    return AlertDialog(
      title: Text(loc.t('sort_cave_places_navbar')),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SingleChildScrollView(
        child: RadioGroup<CavePlaceSortField>(
          groupValue: _field,
          onChanged: (v) => setState(() => _field = v!),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in CavePlaceSortField.values)
                RadioListTile<CavePlaceSortField>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.t('sort_cave_place_field_${field.name}')),
                  value: field,
                ),
              const Divider(height: 16),
              Row(
                children: [
                  ChoiceChip(
                    label: Text(loc.t('sort_asc')),
                    selected: _ascending,
                    onSelected: (_) => setState(() => _ascending = true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(loc.t('sort_desc')),
                    selected: !_ascending,
                    onSelected: (_) => setState(() => _ascending = false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            CavePlaceSortOption(field: _field, ascending: _ascending),
          ),
          child: Text(loc.t('apply')),
        ),
      ],
    );
  }
}

/// Opens a dialog that lets the user choose a [RasterMapSortOption].
///
/// Returns the chosen option, or null if the dialog was dismissed.
Future<RasterMapSortOption?> showRasterMapSortDialog(
  BuildContext context,
  RasterMapSortOption current,
) {
  return showDialog<RasterMapSortOption>(
    context: context,
    builder: (context) => _RasterMapSortDialog(current: current),
  );
}

class _RasterMapSortDialog extends StatefulWidget {
  const _RasterMapSortDialog({required this.current});
  final RasterMapSortOption current;

  @override
  State<_RasterMapSortDialog> createState() => _RasterMapSortDialogState();
}

class _RasterMapSortDialogState extends State<_RasterMapSortDialog> {
  late RasterMapSortField _field;
  late bool _ascending;

  @override
  void initState() {
    super.initState();
    _field = widget.current.field;
    _ascending = widget.current.ascending;
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    return AlertDialog(
      title: Text(loc.t('sort_raster_maps')),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: RadioGroup<RasterMapSortField>(
        groupValue: _field,
        onChanged: (v) => setState(() => _field = v!),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final field in RasterMapSortField.values)
              RadioListTile<RasterMapSortField>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(loc.t('sort_field_${field.name}')),
                value: field,
              ),
            const Divider(height: 16),
            Row(
              children: [
                ChoiceChip(
                  label: Text(loc.t('sort_asc')),
                  selected: _ascending,
                  onSelected: (_) => setState(() => _ascending = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(loc.t('sort_desc')),
                  selected: !_ascending,
                  onSelected: (_) => setState(() => _ascending = false),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            RasterMapSortOption(field: _field, ascending: _ascending),
          ),
          child: Text(loc.t('apply')),
        ),
      ],
    );
  }
}
