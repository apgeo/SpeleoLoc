import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_controller.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_utils.dart';
import 'package:speleoloc/utils/localization.dart';

/// The depth field + cave-area dropdown row.
///
/// Shows:
/// - A fixed-width depth `+/-` text field (bound to [form.depth]).
/// - An expanded cave-area [DropdownButtonFormField]; clearing an existing
///   selection requires confirmation.
/// - A manage-areas icon button whose action is entirely delegated to
///   [onManageAreas] (the parent navigates to CaveAreasPage and reloads).
/// - An optional "show PCI row" eye icon (visible when [pciRowHidden]).
class CavePlaceAreaRow extends StatefulWidget {
  const CavePlaceAreaRow({
    super.key,
    required this.form,
    required this.caveAreas,
    required this.depthFieldKey,
    required this.pciRowHidden,
    required this.onAreaChanged,
    required this.onManageAreas,
    required this.onShowPciRow,
  });

  final CavePlaceFormController form;
  final List<CaveArea> caveAreas;
  final Key depthFieldKey;
  final bool pciRowHidden;

  /// Called with the confirmed [Uuid?] when the user changes the area
  /// selection (including confirmed "clear area").
  final void Function(Uuid?) onAreaChanged;

  /// Called when the user taps the manage-areas button.
  /// The parent is responsible for navigation, reloading, and setState.
  final Future<void> Function() onManageAreas;

  /// Called when the user taps the "show PCI row" eye button.
  final VoidCallback onShowPciRow;

  @override
  State<CavePlaceAreaRow> createState() => _CavePlaceAreaRowState();
}

class _CavePlaceAreaRowState extends State<CavePlaceAreaRow> {
  /// The dropdown field changes its own value before `onChanged` runs and
  /// takes a new one from the form only when `initialValue` changes, so a
  /// refused change has to be undone through the field itself.
  final _areaField = GlobalKey<FormFieldState<Uuid?>>();

  /// Set while the field is being put back, which calls `onChanged` again.
  bool _restoring = false;

  CavePlaceFormController get form => widget.form;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 80,
          child: TextFormField(
            key: widget.depthFieldKey,
            controller: form.depth,
            decoration: InputDecoration(
              labelText: "Depth '+/-'",
              filled: form.depthModified,
              fillColor: form.depthModified
                  ? Colors.green.withValues(alpha: 0.06)
                  : null,
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [depthInputFormatter],
          ),
        ),

        const SizedBox(width: 28),

        Expanded(
          child: DropdownButtonFormField<Uuid?>(
            key: _areaField,
            initialValue: form.selectedCaveAreaId,
            decoration: InputDecoration(
              labelText: LocServ.inst.t('area_title'),
            ),
            items: [
              DropdownMenuItem<Uuid?>(
                value: null,
                child: Text(LocServ.inst.t('none')),
              ),
              ...widget.caveAreas.map(
                (a) => DropdownMenuItem<Uuid?>(
                  value: a.uuid,
                  child: Text(a.title),
                ),
              ),
            ],
            onChanged: (v) async {
              if (_restoring) return;
              final old = form.selectedCaveAreaId;
              if (v == null && old != null) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(LocServ.inst.t('confirm')),
                    content: Text(LocServ.inst.t('clear_area_confirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(LocServ.inst.t('cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(LocServ.inst.t('yes')),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  widget.onAreaChanged(null);
                } else {
                  _restoring = true;
                  _areaField.currentState?.didChange(old);
                  _restoring = false;
                }
              } else {
                widget.onAreaChanged(v);
              }
            },
          ),
        ),

        IconButton(
          icon: const Icon(Icons.layers),
          tooltip: LocServ.inst.t('manage_cave_areas'),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: widget.onManageAreas,
        ),

        if (widget.pciRowHidden)
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: LocServ.inst.t('show_place_code_row'),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: widget.onShowPciRow,
          ),
      ],
    );
  }
}
