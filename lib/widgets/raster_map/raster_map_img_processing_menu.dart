import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_image_filter.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_toolbar_widgets.dart';

/// Builds the popup menu items for the raster-map image-processing button.
///
/// Pure UI: depends only on the [current] filter (used to mark the active
/// preset). Selection handling lives in the editor State.
List<PopupMenuEntry<String>> buildImgProcessingMenuItems(
  RasterMapImageFilter current,
) {
  final t = LocServ.inst.t;

  PopupMenuEntry<String> preset(
    String value,
    IconData icon,
    String label,
    bool active,
  ) => PopupMenuItem<String>(
    value: value,
    child: OverlayMenuRow(icon, label, active: active),
  );

  return [
    // Reset to normal
    preset('normal', Icons.image, t('img_mode_normal'), current.isNormal),
    const PopupMenuDivider(),
    // Single-mode presets
    preset(
      'invert',
      Icons.invert_colors,
      t('invert_colors'),
      current.mode == RasterMapFilterMode.invert,
    ),
    preset(
      'grayscale',
      Icons.filter_b_and_w,
      t('img_filter_grayscale'),
      current.mode == RasterMapFilterMode.grayscale,
    ),
    preset(
      'sepia',
      Icons.photo_filter,
      t('img_filter_sepia'),
      current.mode == RasterMapFilterMode.sepia,
    ),
    preset(
      'high_contrast',
      Icons.contrast,
      t('img_filter_high_contrast'),
      current.mode == RasterMapFilterMode.highContrast,
    ),
    preset(
      'night_red',
      Icons.nights_stay_outlined,
      t('img_filter_night_red'),
      current.mode == RasterMapFilterMode.nightRed,
    ),
    const PopupMenuDivider(),
    // Additive / advanced panel
    PopupMenuItem<String>(
      value: 'custom',
      child: OverlayMenuRow(
        Icons.tune,
        t('img_filter_custom'),
        active: current.mode == RasterMapFilterMode.custom,
      ),
    ),
  ];
}
