import 'package:flutter/material.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_controller.dart';
import 'package:speleoloc/utils/localization.dart';

/// PCI (Place Code Identifier) row: a lock toggle, the editable field
/// with green dirty-tint, and an auto-generate button.
///
/// Extracted from `cave_place_page.dart` build method. Rendered as part
/// of the cave-place form; hidden by [visible] when the QCRI mirrors PCI.
class CavePlacePciSection extends StatelessWidget {
  const CavePlacePciSection({
    super.key,
    required this.visible,
    required this.form,
    required this.editable,
    required this.onEditableToggled,
    required this.onAutoGenerate,
    this.rowKey,
  });

  final bool visible;
  final CavePlaceFormController form;
  final bool editable;
  final VoidCallback onEditableToggled;
  final VoidCallback onAutoGenerate;
  final Key? rowKey;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Row(
      key: rowKey,
      children: [
        IconButton(
          icon: Icon(
            editable ? Icons.lock_open : Icons.lock_outline,
          ),
          tooltip: editable
              ? LocServ.inst.t('disable_qr_edit')
              : LocServ.inst.t('enable_qr_edit'),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          onPressed: onEditableToggled,
        ),
        Expanded(
          child: TextFormField(
            controller: form.qr,
            decoration: InputDecoration(
              labelText: LocServ.inst.t('place_code_identifier'),
              filled: form.qrModified,
              fillColor: form.qrModified
                  ? Colors.green.withValues(alpha: 0.06)
                  : null,
            ),
            enabled: editable,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.auto_awesome, size: 20),
          tooltip: LocServ.inst.t('auto_generate'),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          onPressed: editable ? onAutoGenerate : null,
        ),
      ],
    );
  }
}
