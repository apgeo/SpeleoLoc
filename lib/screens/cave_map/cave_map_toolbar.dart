import 'package:flutter/material.dart';
import 'package:speleoloc/screens/cave_map/cave_map_panel.dart';
import 'package:speleoloc/utils/localization.dart';

/// Compact horizontal toolbar pinned to the top of the surface map (the
/// screen hides its AppBar). Hosts navigation, the layer picker, the two
/// visibility toggles and the two place-list buttons; in pick mode it adds
/// the confirm action.
class CaveMapToolbar extends StatelessWidget {
  const CaveMapToolbar({
    super.key,
    required this.pickMode,
    required this.canConfirmPick,
    required this.showOtherCaves,
    required this.showNonEntrances,
    required this.activePanel,
    required this.onBack,
    required this.onToggleOtherCaves,
    required this.onToggleNonEntrances,
    required this.onPanelToggled,
    required this.onConfirmPick,
  });

  final bool pickMode;
  final bool canConfirmPick;
  final bool showOtherCaves;
  final bool showNonEntrances;
  final CaveMapPanel activePanel;
  final VoidCallback onBack;
  final VoidCallback onToggleOtherCaves;
  final VoidCallback onToggleNonEntrances;
  final ValueChanged<CaveMapPanel> onPanelToggled;
  final VoidCallback? onConfirmPick;

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final scheme = Theme.of(context).colorScheme;
    final activeColor = scheme.primary;
    final inactiveColor = scheme.onSurfaceVariant;

    Widget button({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
      bool active = false,
    }) {
      return IconButton(
        icon: Icon(icon, size: 24),
        color: active ? activeColor : inactiveColor,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
      );
    }

    return Material(
      elevation: 4,
      color: scheme.surface.withValues(alpha: 0.95),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              button(
                icon: Icons.arrow_back,
                tooltip: loc.t('back'),
                onPressed: onBack,
              ),
              button(
                icon: Icons.layers,
                tooltip: loc.t('map_layers'),
                active: activePanel == CaveMapPanel.layers,
                onPressed: () => onPanelToggled(CaveMapPanel.layers),
              ),
              const SizedBox(width: 4),
              button(
                icon: showOtherCaves ? Icons.public : Icons.public_off,
                tooltip: loc.t(
                  showOtherCaves
                      ? 'map_hide_other_caves'
                      : 'map_show_other_caves',
                ),
                active: showOtherCaves,
                onPressed: onToggleOtherCaves,
              ),
              button(
                icon: showNonEntrances
                    ? Icons.scatter_plot
                    : Icons.scatter_plot_outlined,
                tooltip: loc.t(
                  showNonEntrances
                      ? 'map_hide_non_entrances'
                      : 'map_show_non_entrances',
                ),
                active: showNonEntrances,
                onPressed: onToggleNonEntrances,
              ),
              const SizedBox(width: 4),
              button(
                icon: Icons.format_list_bulleted,
                tooltip: loc.t('map_all_places_list'),
                active: activePanel == CaveMapPanel.allPlaces,
                onPressed: () => onPanelToggled(CaveMapPanel.allPlaces),
              ),
              button(
                icon: Icons.door_front_door,
                tooltip: loc.t('map_entrances_list'),
                active: activePanel == CaveMapPanel.entrances,
                onPressed: () => onPanelToggled(CaveMapPanel.entrances),
              ),
              if (pickMode) ...[
                const SizedBox(width: 4),
                button(
                  icon: Icons.check_circle,
                  tooltip: loc.t('map_pick_save'),
                  active: canConfirmPick,
                  onPressed: canConfirmPick ? onConfirmPick : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
