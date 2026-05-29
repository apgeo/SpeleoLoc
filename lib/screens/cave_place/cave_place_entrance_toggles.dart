import 'package:flutter/material.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_controller.dart';
import 'package:speleoloc/utils/localization.dart';

/// Pair of CheckboxListTiles for "is cave entrance" + "is main entrance".
/// The main-entrance row is disabled when the entrance flag is off.
class CavePlaceEntranceToggles extends StatelessWidget {
  const CavePlaceEntranceToggles({
    super.key,
    required this.form,
    required this.onEntranceChanged,
    required this.onMainEntranceChanged,
  });

  final CavePlaceFormController form;
  final ValueChanged<bool> onEntranceChanged;
  final ValueChanged<bool> onMainEntranceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: form.isEntrance,
          title: Text(LocServ.inst.t('is_cave_entrance')),
          onChanged: (v) => onEntranceChanged(v ?? false),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: form.isMainEntrance,
            title: Text(LocServ.inst.t('is_main_cave_entrance')),
            onChanged: form.isEntrance
                ? (v) => onMainEntranceChanged(v ?? false)
                : null,
          ),
        ),
      ],
    );
  }
}
