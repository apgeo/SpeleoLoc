import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speleoloc/utils/localization.dart';

/// An inclusive integer range picked by the user.
class IndexRange {
  final int start;
  final int end;
  const IndexRange(this.start, this.end);

  int get count => end - start + 1;
}

/// Prompts for an inclusive `start`..`end` integer range. Returns null on
/// cancel. Validates that both are >= 1, `start <= end`, and the span does
/// not exceed [maxSize].
Future<IndexRange?> showIndexRangeDialog(
  BuildContext context, {
  required String title,
  int maxSize = 500,
}) {
  return showDialog<IndexRange>(
    context: context,
    builder: (_) => _IndexRangeDialog(title: title, maxSize: maxSize),
  );
}

class _IndexRangeDialog extends StatefulWidget {
  final String title;
  final int maxSize;

  const _IndexRangeDialog({required this.title, required this.maxSize});

  @override
  State<_IndexRangeDialog> createState() => _IndexRangeDialogState();
}

class _IndexRangeDialogState extends State<_IndexRangeDialog> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _submit() {
    final start = int.tryParse(_startController.text.trim());
    final end = int.tryParse(_endController.text.trim());
    if (start == null || end == null || start < 1 || end < start) {
      setState(() => _error = LocServ.inst.t('qr_range_invalid'));
      return;
    }
    if (end - start + 1 > widget.maxSize) {
      setState(
        () => _error = '${LocServ.inst.t('qr_range_too_large')} (${widget.maxSize})',
      );
      return;
    }
    Navigator.pop(context, IndexRange(start, end));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: LocServ.inst.t('qr_range_start'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _endController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: LocServ.inst.t('qr_range_end'),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocServ.inst.t('cancel')),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(LocServ.inst.t('ok')),
        ),
      ],
    );
  }
}
