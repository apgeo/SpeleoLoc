import 'package:speleoloc/data/source/database/app_database.dart';

/// The colours of the app's marks on a 3D model.
abstract final class ModelMarkColours {
  /// A mapped place, when marks are not coloured by area.
  static const mapped = '#ff9800';

  /// "You are here".
  static const here = '#00e676';

  /// The route drawn for a distance or a replayed trip.
  static const route = '#00bcd4';

  // Told apart on the model's black background and from the height ramp's
  // ends; a cave with more areas reuses them in order.
  static const _areaPalette = [
    '#ff9800',
    '#e91e63',
    '#03a9f4',
    '#8bc34a',
    '#ffeb3b',
    '#9c27b0',
    '#00bcd4',
    '#ff5722',
  ];

  /// One colour per cave area, in the areas' title order; a place without an
  /// area keeps [mapped].
  static Map<Uuid, String> byArea(Iterable<CaveArea> areas) {
    final sorted = areas.toList()..sort((a, b) => a.title.compareTo(b.title));
    return {
      for (var i = 0; i < sorted.length; i++)
        sorted[i].uuid: _areaPalette[i % _areaPalette.length],
    };
  }
}
