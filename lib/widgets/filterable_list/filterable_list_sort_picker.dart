import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/filterable_list/filterable_list_models.dart';

/// Outcome of [showFilterableListSortPicker]: either a chosen [spec], or a
/// [cleared] signal (user pressed "Clear"). A null return from the picker
/// means the dialog was dismissed and nothing should change.
@immutable
class FilterableListSortPickerResult {
  const FilterableListSortPickerResult({
    required this.spec,
    this.cleared = false,
  });
  final FilterableListSortSpec? spec;
  final bool cleared;
}

/// Shows the two-level (primary + optional secondary) sort picker for [fields]
/// (id/label pairs), starting from [initial]. Returns null if dismissed.
Future<FilterableListSortPickerResult?> showFilterableListSortPicker(
  BuildContext context, {
  required List<({String id, String label})> fields,
  required FilterableListSortSpec? initial,
}) {
  return showDialog<FilterableListSortPickerResult>(
    context: context,
    builder: (ctx) => _SortPickerDialog(
      fields: fields
          .map((f) => _SortPickerField(id: f.id, label: f.label))
          .toList(growable: false),
      initial: initial,
    ),
  );
}

@immutable
class _SortPickerField {
  const _SortPickerField({required this.id, required this.label});
  final String id;
  final String label;
}

class _SortPickerDialog extends StatefulWidget {
  const _SortPickerDialog({required this.fields, required this.initial});

  final List<_SortPickerField> fields;
  final FilterableListSortSpec? initial;

  @override
  State<_SortPickerDialog> createState() => _SortPickerDialogState();
}

class _SortPickerDialogState extends State<_SortPickerDialog> {
  String? _primary;
  bool _primaryAsc = true;
  String? _secondary;
  bool _secondaryAsc = true;

  @override
  void initState() {
    super.initState();
    final ids = {for (final f in widget.fields) f.id};
    final init = widget.initial;
    if (init != null && ids.contains(init.primaryFieldId)) {
      _primary = init.primaryFieldId;
      _primaryAsc = init.primaryAscending;
      if (init.secondaryFieldId != null &&
          ids.contains(init.secondaryFieldId!)) {
        _secondary = init.secondaryFieldId;
        _secondaryAsc = init.secondaryAscending;
      }
    }
  }

  void _selectPrimary(String id, bool asc) {
    setState(() {
      _primary = id;
      _primaryAsc = asc;
      // Don't allow primary == secondary.
      if (_secondary == id) _secondary = null;
    });
  }

  void _selectSecondary(String? id, bool asc) {
    setState(() {
      _secondary = id;
      _secondaryAsc = asc;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final theme = Theme.of(context);
    final headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.primary,
    );
    return AlertDialog(
      title: Text(loc.t('sort_by')),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.t('sort_primary'), style: headerStyle),
              const SizedBox(height: 4),
              for (final f in widget.fields)
                _SortFieldRow(
                  label: f.label,
                  selected: _primary == f.id,
                  ascending: _primaryAsc,
                  onAscending: () => _selectPrimary(f.id, true),
                  onDescending: () => _selectPrimary(f.id, false),
                ),
              const Divider(height: 16),
              Text(loc.t('sort_secondary'), style: headerStyle),
              const SizedBox(height: 4),
              _SortFieldRow(
                label: loc.t('none'),
                selected: _secondary == null,
                ascending: true,
                showArrows: false,
                onSelect: () => _selectSecondary(null, true),
              ),
              for (final f in widget.fields)
                if (f.id != _primary)
                  _SortFieldRow(
                    label: f.label,
                    selected: _secondary == f.id,
                    ascending: _secondaryAsc,
                    enabled: _primary != null,
                    onAscending: () => _selectSecondary(f.id, true),
                    onDescending: () => _selectSecondary(f.id, false),
                  ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: widget.initial == null
                  ? null
                  : () => Navigator.pop(
                      context,
                      const FilterableListSortPickerResult(
                        spec: null,
                        cleared: true,
                      ),
                    ),
              child: Text(loc.t('sort_clear')),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.t('cancel')),
            ),
            TextButton(
              onPressed: _primary == null
                  ? null
                  : () => Navigator.pop(
                      context,
                      FilterableListSortPickerResult(
                        spec: FilterableListSortSpec(
                          primaryFieldId: _primary!,
                          primaryAscending: _primaryAsc,
                          secondaryFieldId: _secondary,
                          secondaryAscending: _secondaryAsc,
                        ),
                      ),
                    ),
              child: Text(loc.t('ok')),
            ),
          ],
        ),
      ],
    );
  }
}

class _SortFieldRow extends StatelessWidget {
  const _SortFieldRow({
    required this.label,
    required this.selected,
    required this.ascending,
    this.onAscending,
    this.onDescending,
    this.onSelect,
    this.enabled = true,
    this.showArrows = true,
  });

  final String label;
  final bool selected;
  final bool ascending;
  final VoidCallback? onAscending;
  final VoidCallback? onDescending;
  final VoidCallback? onSelect;
  final bool enabled;
  final bool showArrows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final disabledColor = theme.disabledColor;
    final inactive = Colors.grey.shade500;
    final loc = LocServ.inst;

    // Compute the callback for a label tap:
    //   "None" / no-arrow rows → onSelect
    //   Arrow rows → first tap selects ascending; subsequent taps toggle direction.
    VoidCallback? labelTap;
    if (enabled) {
      if (onSelect != null && !showArrows) {
        labelTap = onSelect;
      } else if (showArrows) {
        if (!selected) {
          labelTap = onAscending; // first selection
        } else {
          labelTap = ascending ? onDescending : onAscending; // toggle
        }
      }
    }

    final labelText = Text(
      label,
      style: TextStyle(
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        color: !enabled ? disabledColor : (selected ? accent : null),
      ),
    );

    final labelWidget = InkWell(
      onTap: labelTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: labelText,
      ),
    );

    return Row(
      children: [
        if (selected)
          Icon(Icons.check, size: 16, color: accent)
        else
          const SizedBox(width: 16),
        const SizedBox(width: 4),
        Expanded(child: labelWidget),
        if (showArrows) ...[
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: loc.t('sort_ascending'),
            icon: Icon(
              Icons.arrow_upward,
              size: 18,
              color: !enabled
                  ? disabledColor
                  : (selected && ascending ? accent : inactive),
            ),
            onPressed: enabled ? onAscending : null,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: loc.t('sort_descending'),
            icon: Icon(
              Icons.arrow_downward,
              size: 18,
              color: !enabled
                  ? disabledColor
                  : (selected && !ascending ? accent : inactive),
            ),
            onPressed: enabled ? onDescending : null,
          ),
        ],
      ],
    );
  }
}
