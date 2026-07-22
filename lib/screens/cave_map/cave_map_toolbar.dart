import 'package:flutter/material.dart';
import 'package:speleoloc/screens/cave_map/cave_map_panel.dart';
import 'package:speleoloc/utils/localization.dart';

/// Compact horizontal toolbar pinned to the top of the surface map (the
/// screen hides its AppBar). Hosts navigation, the my-location toggle, the
/// layer picker, the two visibility toggles, the two place-list buttons and
/// the create-point menu.
class CaveMapToolbar extends StatelessWidget {
  const CaveMapToolbar({
    super.key,
    required this.showOtherCaves,
    required this.showNonEntrances,
    required this.locationActive,
    required this.activePanel,
    required this.onBack,
    required this.onMyLocation,
    required this.onToggleOtherCaves,
    required this.onToggleNonEntrances,
    required this.onPanelToggled,
    this.measureActive = false,
    this.onMeasure,
    this.onAdd,
  });

  final bool showOtherCaves;
  final bool showNonEntrances;
  final bool locationActive;
  final CaveMapPanel activePanel;
  final VoidCallback onBack;
  final VoidCallback onMyLocation;
  final VoidCallback onToggleOtherCaves;
  final VoidCallback onToggleNonEntrances;
  final ValueChanged<CaveMapPanel> onPanelToggled;

  /// Toggles distance-measuring mode. Null hides the button (while a
  /// point placement is in progress).
  final bool measureActive;
  final VoidCallback? onMeasure;

  /// Opens the create-point menu. Null hides the button (e.g. while the map
  /// is being used as an external coordinate picker).
  final VoidCallback? onAdd;

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
                icon: locationActive
                    ? Icons.my_location
                    : Icons.location_searching,
                tooltip: loc.t('map_my_location'),
                active: locationActive,
                onPressed: onMyLocation,
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
              if (onMeasure != null)
                button(
                  icon: Icons.straighten,
                  tooltip: loc.t('map_measure'),
                  active: measureActive,
                  onPressed: onMeasure,
                ),
              if (onAdd != null) ...[
                const SizedBox(width: 4),
                button(
                  icon: Icons.add_location_alt,
                  tooltip: loc.t('map_add_point'),
                  onPressed: onAdd,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
