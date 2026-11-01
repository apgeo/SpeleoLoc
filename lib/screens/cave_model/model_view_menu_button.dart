import 'package:flutter/material.dart';
import 'package:speleoloc/services/cave_model/model_viewer_command.dart';
import 'package:speleoloc/utils/localization.dart';

/// Turns the 3D viewer to look from one of the fixed directions. On a phone
/// held upright the viewer's own toolbar has room for the plan view only.
class ModelViewMenuButton extends StatelessWidget {
  const ModelViewMenuButton({super.key, required this.onSelected});

  final ValueChanged<ModelView> onSelected;

  static String _label(ModelView view) => LocServ.inst.t(switch (view) {
    ModelView.plan => 'model_view_plan',
    ModelView.north => 'model_view_north',
    ModelView.east => 'model_view_east',
    ModelView.south => 'model_view_south',
    ModelView.west => 'model_view_west',
  });

  @override
  Widget build(BuildContext context) => PopupMenuButton<ModelView>(
    icon: const Icon(Icons.explore_outlined),
    tooltip: LocServ.inst.t('model_viewer_views'),
    onSelected: onSelected,
    itemBuilder: (_) => [
      for (final view in ModelView.values)
        PopupMenuItem(value: view, child: Text(_label(view))),
    ],
  );
}
