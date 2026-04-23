import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({super.key, required this.text});
 // const RasterMapForm({super.key, required this.caveUuid, this.rasterMap});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocServ.inst.t('confirm')),
      content: Text(text.toString()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(LocServ.inst.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(LocServ.inst.t('yes')),
        ),
      ],
    );
  }
}
