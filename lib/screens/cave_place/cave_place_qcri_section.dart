import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_controller.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/cave_place_qr_preview_dialog.dart';

/// QCRI (QR Code Resource Identifier) row: view-QR button, lock toggle,
/// editable field with green dirty-tint, auto-generate button, and a
/// scan button with long-press to open manual entry.
///
/// Extracted from `cave_place_page.dart` build method. The view-QR
/// button is shown only when the cave place is persisted ([cavePlace]
/// non-null) and the QCRI text is non-empty.
class CavePlaceQcriSection extends StatelessWidget {
  const CavePlaceQcriSection({
    super.key,
    required this.form,
    required this.editable,
    required this.onEditableToggled,
    required this.onAutoGenerate,
    required this.onOpenScanner,
    required this.onScanLongPressStart,
    required this.onScanLongPressEnd,
    required this.cavePlace,
    required this.currentCavePlaceId,
  });

  final CavePlaceFormController form;
  final bool editable;
  final VoidCallback onEditableToggled;
  final VoidCallback onAutoGenerate;
  final VoidCallback onOpenScanner;
  final VoidCallback onScanLongPressStart;
  final VoidCallback onScanLongPressEnd;
  final CavePlace? cavePlace;
  final Uuid? currentCavePlaceId;

  @override
  Widget build(BuildContext context) {
    final qcriText = form.qcri.text.trim();
    final canPreview = currentCavePlaceId != null && qcriText.isNotEmpty;
    return Row(
      children: [
        if (canPreview)
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: LocServ.inst.t('view_qr_code'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () {
              CavePlaceQrPreviewDialog.show(
                context,
                cavePlace!,
                qrIdentifierOverride: qcriText.isEmpty ? null : qcriText,
              );
            },
          )
        else
          const SizedBox(width: 40),
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
            controller: form.qcri,
            decoration: InputDecoration(
              labelText: LocServ.inst.t('qr_code_resource_identifier'),
              filled: form.qcriModified,
              fillColor: form.qcriModified
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
        const SizedBox(width: 4),
        Listener(
          onPointerDown: enableQrManualInput ? (_) => onScanLongPressStart() : null,
          onPointerUp: enableQrManualInput ? (_) => onScanLongPressEnd() : null,
          onPointerCancel: enableQrManualInput ? (_) => onScanLongPressEnd() : null,
          child: IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: LocServ.inst.t('scan'),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: onOpenScanner,
          ),
        ),
      ],
    );
  }
}
