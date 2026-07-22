import 'package:flutter/material.dart';
import 'package:speleoloc/utils/coordinate_formats.dart';
import 'package:speleoloc/utils/localization.dart';

/// Dialog with a single free-text field accepting coordinates in any
/// supported format (decimal degrees, DMS, UTM — auto-detected by
/// [parseCoordinates]). Pops the parsed point, or null on cancel.
Future<GeoPoint?> showCoordinateEntryDialog(BuildContext context) =>
    showDialog<GeoPoint>(
      context: context,
      builder: (_) => const _CoordinateEntryDialog(),
    );

class _CoordinateEntryDialog extends StatefulWidget {
  const _CoordinateEntryDialog();

  @override
  State<_CoordinateEntryDialog> createState() => _CoordinateEntryDialogState();
}

class _CoordinateEntryDialogState extends State<_CoordinateEntryDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final point = parseCoordinates(_controller.text);
    if (point == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, point);
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    return AlertDialog(
      title: Text(loc.t('coord_enter_title')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: loc.t('coord_enter_label'),
          helperText: '45.359167, 22.714722\n'
              '45°21\'33.0"N 22°42\'53.0"E\n'
              '34T 634605 5023721',
          helperMaxLines: 3,
          errorText: _invalid ? loc.t('coord_enter_invalid') : null,
        ),
        onChanged: (_) {
          if (_invalid) setState(() => _invalid = false);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.t('cancel')),
        ),
        TextButton(onPressed: _submit, child: Text(loc.t('ok'))),
      ],
    );
  }
}
