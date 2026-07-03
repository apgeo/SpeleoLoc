import 'dart:async';

import 'package:flutter/material.dart';

// ───────────────────────────────────────────────────────────────────────────
// TOOLBAR STYLE CONSTANTS
// Edit values here to change the look of the entire side-toolbar system.
// ───────────────────────────────────────────────────────────────────────────
abstract final class RasterMapToolbarStyle {
  // ── Sizes ───────────────────────────────────────────────────────────────────

  /// Button cell width & height.  Small size is 32 px.
  static const double btnSize = 40.0;

  /// Icon size inside each button cell.  Scaled proportionally from 18 px.
  static const double iconSize = 28.0;

  /// Padding inside the toggle-button wrapper container.
  static const double togglePad = 1.0;

  /// Distance from the map edge to the toolbar / toggle anchor.
  static const double sideMargin = 10.0;

  /// Vertical gap between the toggle-button wrapper and the toolbar panel.
  static const double toggleGap = 4.0;

  /// Inner padding of the toolbar panel container.
  static const double panelPad = 1.0;

  /// Vertical gap between buttons inside the toolbar panel.
  static const double btnGap = 2.0;

  /// Corner radius for the toolbar / toggle wrapper containers.
  static const double radius = 8.0;

  /// Corner radius for individual button ink-well cells.
  static const double btnRadius = 6.0;

  /// Border width for toolbar containers.
  static const double borderWidth = 1.0;

  /// Drop-shadow blur radius.
  static const double shadowBlur = 4.0;

  // ── Transparency / colour ─────────────────────────────────────────────────

  /// Opacity of toolbar / toggle-wrapper background (semi-transparent).
  static const double bgAlpha = 0.55;

  /// Opacity of an active (highlighted) button background.
  static const double activeBgAlpha = 0.15;

  /// Opacity of normal (non-active, non-disabled) icons.
  static const double iconAlpha = 0.75;

  /// Border colour for toolbar containers.  Grey 400 ≈ #BDBDBD.
  static const Color borderColor = Color(0xFFBDBDBD);

  /// Drop-shadow colour.
  static const Color shadowColor = Colors.black26;

  // ── Derived ───────────────────────────────────────────────────────────────────

  /// Top offset of the toolbar panel =
  ///   sideMargin + (togglePad + btnSize + togglePad) + toggleGap.
  static const double toolbarTopOffset =
      sideMargin + (2 * togglePad + btnSize) + toggleGap;
}

// ───────────────────────────────────────────────────────────────────────────
// TOOLBAR WIDGETS
// ───────────────────────────────────────────────────────────────────────────

/// A plain icon button used inside the side toolbar.
/// Size and colours are driven entirely by [RasterMapToolbarStyle].
class OverlayIconButton extends StatelessWidget {
  const OverlayIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
    this.enabled = true,
    this.iconFlip = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
  final bool enabled;

  /// When true the icon is horizontally mirrored (for right-side chevrons).
  final bool iconFlip;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final iconColor = !enabled
        ? Theme.of(context).disabledColor
        : active
        ? primary
        : Theme.of(context).colorScheme.onSurface.withValues(
            alpha: RasterMapToolbarStyle.iconAlpha,
          );
    Widget iconWidget = Icon(
      icon,
      size: RasterMapToolbarStyle.iconSize,
      color: iconColor,
    );
    if (iconFlip) {
      iconWidget = Transform.scale(scaleX: -1, child: iconWidget);
    }
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(RasterMapToolbarStyle.btnRadius),
        child: Container(
          width: RasterMapToolbarStyle.btnSize,
          height: RasterMapToolbarStyle.btnSize,
          decoration: BoxDecoration(
            color: active
                ? primary.withValues(alpha: RasterMapToolbarStyle.activeBgAlpha)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              RasterMapToolbarStyle.btnRadius,
            ),
          ),
          alignment: Alignment.center,
          child: iconWidget,
        ),
      ),
    );
  }
}

/// A popup-menu button styled to match [OverlayIconButton].
/// Size and colours are driven entirely by [RasterMapToolbarStyle].
class OverlayPopupButton extends StatelessWidget {
  const OverlayPopupButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.items,
    required this.onSelected,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final List<PopupMenuEntry<String>> items;
  final FutureOr<void> Function(String) onSelected;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final iconColor = active
        ? primary
        : Theme.of(context).colorScheme.onSurface.withValues(
            alpha: RasterMapToolbarStyle.iconAlpha,
          );
    return PopupMenuButton<String>(
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: (_) => items,
      child: Container(
        width: RasterMapToolbarStyle.btnSize,
        height: RasterMapToolbarStyle.btnSize,
        decoration: BoxDecoration(
          color: active
              ? primary.withValues(alpha: RasterMapToolbarStyle.activeBgAlpha)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(RasterMapToolbarStyle.btnRadius),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: RasterMapToolbarStyle.iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}

/// A row with an icon and a label used inside popup menu items in the toolbar.
class OverlayMenuRow extends StatelessWidget {
  const OverlayMenuRow(this.icon, this.label, {super.key, this.active = false});
  final IconData icon;
  final String label;

  /// When true a check icon is shown on the right, indicating active state.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(
            alpha: RasterMapToolbarStyle.iconAlpha,
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: active
                ? TextStyle(color: color, fontWeight: FontWeight.w600)
                : null,
          ),
        ),
        if (active) ...[
          const SizedBox(width: 8),
          Icon(Icons.check, size: 16, color: color),
        ],
      ],
    );
  }
}
