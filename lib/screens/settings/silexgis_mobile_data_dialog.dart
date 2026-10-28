import 'package:flutter/material.dart';
import 'package:speleoloc/services/silexgis/silexgis_files_network_gate.dart';
import 'package:speleoloc/utils/format_bytes.dart';
import 'package:speleoloc/utils/localization.dart';

/// Asks the caver, from the screen that started the run, whether files may
/// go over mobile data now.
class SilexgisMobileDataDialogDecider implements SilexgisMobileDataDecider {
  const SilexgisMobileDataDialogDecider(this._context);

  /// The screen's context while it is still mounted, or null once it is gone
  /// — then nobody is asked and the files wait.
  final BuildContext? Function() _context;

  @override
  Future<SilexgisMobileDataAnswer?> askToSendOverMobileData({
    required int files,
    required int bytes,
  }) async {
    final context = _context();
    if (context == null) return null;
    return showDialog<SilexgisMobileDataAnswer>(
      context: context,
      builder: (_) => SilexgisMobileDataDialog(files: files, bytes: bytes),
    );
  }
}

/// "Send files over mobile data?", with a choice to remember the answer.
class SilexgisMobileDataDialog extends StatefulWidget {
  const SilexgisMobileDataDialog({
    required this.files,
    required this.bytes,
    super.key,
  });

  final int files;
  final int bytes;

  @override
  State<SilexgisMobileDataDialog> createState() =>
      _SilexgisMobileDataDialogState();
}

class _SilexgisMobileDataDialogState extends State<SilexgisMobileDataDialog> {
  bool _remember = false;

  void _answer(bool send) => Navigator.pop(
    context,
    SilexgisMobileDataAnswer(send: send, remember: _remember),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(LocServ.inst.t('silexgis_mobile_data_title')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocServ.inst.t('silexgis_mobile_data_body', <String, String>{
            'count': '${widget.files}',
            'size': formatByteSize(widget.bytes),
          }),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _remember,
          onChanged: (v) => setState(() => _remember = v ?? false),
          title: Text(LocServ.inst.t('silexgis_mobile_data_remember')),
        ),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => _answer(false),
        child: Text(LocServ.inst.t('silexgis_mobile_data_wait')),
      ),
      FilledButton(
        onPressed: () => _answer(true),
        child: Text(LocServ.inst.t('silexgis_mobile_data_send')),
      ),
    ],
  );
}
