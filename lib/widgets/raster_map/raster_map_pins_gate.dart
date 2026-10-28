import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/utils/localization.dart';

/// Shows a raster map's editor with its pins only when they fit the picture
/// this device holds for the map.
///
/// When they do not, [builder] is handed the places without their pins and
/// told pins cannot be placed, and a short note above the map says why. The
/// pins themselves stay stored.
class RasterMapPinsGate extends ConsumerWidget {
  const RasterMapPinsGate({
    required this.rasterMapUuid,
    required this.places,
    required this.builder,
    super.key,
  });

  /// The map shown, or null when none is.
  final Uuid? rasterMapUuid;
  final List<CavePlaceWithDefinition> places;

  /// Builds the editor from the places to show and whether pins can be
  /// shown and placed.
  final Widget Function(
    BuildContext context,
    List<CavePlaceWithDefinition> places,
    bool pinsFit,
  )
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = rasterMapUuid;
    // Until the answer is in, the map is shown as it always was.
    final fit = map == null
        ? true
        : ref.watch(rasterMapPinsFitProvider(map)).value ?? true;
    if (fit) return builder(context, places, true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: <Widget>[
                const Icon(Icons.photo_size_select_large, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LocServ.inst.t('raster_map_reduced_picture'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: builder(context, <CavePlaceWithDefinition>[
            for (final place in places)
              CavePlaceWithDefinition(place.cavePlace, null),
          ], false),
        ),
      ],
    );
  }
}
