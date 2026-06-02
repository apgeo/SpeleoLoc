import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';
import 'raster_map_image_filter.dart';

// ---------------------------------------------------------------------------
// RasterMapFilterPanel
//
// A self-contained widget that lets the user build an *additive* image-filter
// configuration by toggling individual effects and adjusting brightness /
// contrast sliders.  It is designed to be shown as a bottom sheet.
//
// Usage:
//   final result = await showRasterMapFilterPanel(context, currentFilter);
//   if (result != null) applyFilter(result);
//
// The widget is intentionally stateful and self-contained so it can be
// reused from any screen that hosts a raster-map editor, without coupling
// it to the editor's internal state.
// ---------------------------------------------------------------------------

/// Shows the [RasterMapFilterPanel] as a modal bottom sheet and returns the
/// [RasterMapImageFilter] chosen by the user, or `null` if the sheet was
/// dismissed without confirming.
Future<RasterMapImageFilter?> showRasterMapFilterPanel(
  BuildContext context,
  RasterMapImageFilter current,
) {
  return showModalBottomSheet<RasterMapImageFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => RasterMapFilterPanel(initial: current),
  );
}

/// The filter configuration panel widget.
class RasterMapFilterPanel extends StatefulWidget {
  const RasterMapFilterPanel({super.key, required this.initial});

  /// Filter state to pre-populate the panel with.
  final RasterMapImageFilter initial;

  @override
  State<RasterMapFilterPanel> createState() => _RasterMapFilterPanelState();
}

class _RasterMapFilterPanelState extends State<RasterMapFilterPanel> {
  late bool _invert;
  late bool _grayscale;
  late bool _sepia;
  late bool _highContrast;
  late bool _nightRed;
  late double _brightness;
  late double _contrast;

  @override
  void initState() {
    super.initState();
    // Always start from custom mode — resolve individual flags from whatever
    // the incoming filter was.
    final f = widget.initial;
    if (f.mode == RasterMapFilterMode.custom) {
      _invert       = f.invertEnabled;
      _grayscale    = f.grayscaleEnabled;
      _sepia        = f.sepiaEnabled;
      _highContrast = f.highContrastEnabled;
      _nightRed     = f.nightRedEnabled;
    } else {
      // Map a single-preset to its equivalent additive flags.
      _invert       = f.mode == RasterMapFilterMode.invert;
      _grayscale    = f.mode == RasterMapFilterMode.grayscale;
      _sepia        = f.mode == RasterMapFilterMode.sepia;
      _highContrast = f.mode == RasterMapFilterMode.highContrast;
      _nightRed     = f.mode == RasterMapFilterMode.nightRed;
    }
    _brightness = f.brightness;
    _contrast   = f.contrast;
  }

  RasterMapImageFilter get _current => RasterMapImageFilter(
    mode: RasterMapFilterMode.custom,
    invertEnabled:       _invert,
    grayscaleEnabled:    _grayscale,
    sepiaEnabled:        _sepia,
    highContrastEnabled: _highContrast,
    nightRedEnabled:     _nightRed,
    brightness:          _brightness,
    contrast:            _contrast,
  );

  bool get _anyEnabled =>
      _invert || _grayscale || _sepia || _highContrast || _nightRed ||
      _brightness != 0.0 || _contrast != 1.0;

  void _reset() => setState(() {
    _invert = _grayscale = _sepia = _highContrast = _nightRed = false;
    _brightness = 0.0;
    _contrast   = 1.0;
  });

  Widget _filterCheckbox({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CheckboxListTile(
      secondary: Icon(icon, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String Function(double) display,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 14))),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 40,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              display(value),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = LocServ.inst.t;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.tune, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('img_filter_panel_title'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                // Reset button
                TextButton.icon(
                  onPressed: _anyEnabled ? _reset : null,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(t('img_filter_reset')),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ),
          const Divider(height: 12),

          // ── Effect checkboxes ─────────────────────────────────────────────
          _filterCheckbox(
            icon: Icons.invert_colors,
            label: t('invert_colors'),
            value: _invert,
            onChanged: (v) => setState(() => _invert = v),
          ),
          _filterCheckbox(
            icon: Icons.filter_b_and_w,
            label: t('img_filter_grayscale'),
            value: _grayscale,
            onChanged: (v) => setState(() => _grayscale = v),
          ),
          _filterCheckbox(
            icon: Icons.photo_filter,
            label: t('img_filter_sepia'),
            value: _sepia,
            onChanged: (v) => setState(() => _sepia = v),
          ),
          _filterCheckbox(
            icon: Icons.contrast,
            label: t('img_filter_high_contrast'),
            value: _highContrast,
            onChanged: (v) => setState(() => _highContrast = v),
          ),
          _filterCheckbox(
            icon: Icons.nights_stay_outlined,
            label: t('img_filter_night_red'),
            value: _nightRed,
            onChanged: (v) => setState(() => _nightRed = v),
          ),

          const Divider(height: 12),

          // ── Brightness / Contrast sliders ─────────────────────────────────
          _sliderRow(
            label: t('img_filter_brightness'),
            value: _brightness,
            min: -1.0,
            max: 1.0,
            onChanged: (v) => setState(() => _brightness = v),
            display: (v) => (v >= 0 ? '+' : '') + v.toStringAsFixed(2),
          ),
          _sliderRow(
            label: t('img_filter_contrast'),
            value: _contrast,
            min: 0.2,
            max: 3.0,
            onChanged: (v) => setState(() => _contrast = v),
            display: (v) => v.toStringAsFixed(2),
          ),

          const SizedBox(height: 8),
          const Divider(height: 4),

          // ── Actions ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(t('cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_current),
                  child: Text(t('apply')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
