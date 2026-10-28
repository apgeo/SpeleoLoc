import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/silexgis/silexgis_map_picture_copies.dart';
import 'package:speleoloc/services/silexgis/silexgis_map_pin_rule.dart';
import 'package:speleoloc/services/silexgis/silexgis_picture_frame.dart';
import 'package:speleoloc/services/silexgis/silexgis_pin_placement.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/raster_map/raster_map_picture_size.dart';

/// Shows a raster map's editor with its pins where they belong on the
/// picture this device holds for the map, as [SilexgisMapPinRule] decides.
///
/// On a server's reduced picture [builder] is handed the places with their
/// points carried into that picture's pixels, or without them when they
/// cannot be, and told pins cannot be placed; a short note above the map
/// says which. The pins themselves stay stored as they are.
class RasterMapPinsGate extends ConsumerStatefulWidget {
  const RasterMapPinsGate({
    required this.rasterMapUuid,
    required this.picture,
    required this.places,
    required this.builder,
    super.key,
  });

  /// The map shown, or null when none is.
  final Uuid? rasterMapUuid;

  /// The picture the editor shows for the map, sized as the editor sizes it.
  final ImageProvider picture;
  final List<CavePlaceWithDefinition> places;

  /// Builds the editor from the places to show and whether pins can be
  /// placed.
  final Widget Function(
    BuildContext context,
    List<CavePlaceWithDefinition> places,
    bool pinsEditable,
  )
  builder;

  @override
  ConsumerState<RasterMapPinsGate> createState() => _RasterMapPinsGateState();
}

class _RasterMapPinsGateState extends ConsumerState<RasterMapPinsGate> {
  ({int width, int height})? _size;
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  @override
  void didUpdateWidget(RasterMapPinsGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.picture != widget.picture) _measure();
  }

  void _measure() {
    final picture = widget.picture;
    _size = null;
    _measured = false;
    unawaited(
      rasterMapPictureSize(picture).then((size) {
        if (!mounted || widget.picture != picture) return;
        setState(() {
          _size = size;
          _measured = true;
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.rasterMapUuid;
    final known = map == null
        ? const AsyncData<SilexgisMapPicture?>(null)
        : ref.watch(rasterMapPictureProvider(map));
    // Until the answer is in, the map is shown as it always was.
    if (!known.hasValue) return widget.builder(context, widget.places, true);

    final picture = known.value;
    final placement = SilexgisMapPinRule.placement(
      picture: picture?.heldAs,
      frame: picture?.frame ?? const SilexgisPictureFrame(),
      heldWidth: _size?.width,
      heldHeight: _size?.height,
    );
    if (placement.editable) {
      return widget.builder(context, widget.places, true);
    }
    // While the reduced picture is still being sized, it is shown bare and
    // without a note that might turn out wrong.
    if (!placement.shown && !_measured) {
      return widget.builder(context, _withoutPins(), false);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _note(
          context,
          placement.shown
              ? 'raster_map_reduced_picture_read_only'
              : 'raster_map_reduced_picture',
        ),
        Expanded(
          child: widget.builder(
            context,
            placement.shown ? _placed(placement) : _withoutPins(),
            false,
          ),
        ),
      ],
    );
  }

  List<CavePlaceWithDefinition> _withoutPins() => <CavePlaceWithDefinition>[
    for (final place in widget.places)
      CavePlaceWithDefinition(place.cavePlace, null),
  ];

  List<CavePlaceWithDefinition> _placed(SilexgisPinPlacement placement) =>
      <CavePlaceWithDefinition>[
        for (final place in widget.places)
          CavePlaceWithDefinition(
            place.cavePlace,
            _placedDefinition(place.definition, placement),
          ),
      ];

  static CavePlaceToRasterMapDefinition? _placedDefinition(
    CavePlaceToRasterMapDefinition? definition,
    SilexgisPinPlacement placement,
  ) {
    final x = definition?.xCoordinate;
    final y = definition?.yCoordinate;
    if (definition == null || x == null || y == null) return definition;
    final at = placement.place(x, y);
    return definition.copyWith(
      xCoordinate: Value(at.x.round()),
      yCoordinate: Value(at.y.round()),
    );
  }

  static Widget _note(BuildContext context, String key) => Material(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: <Widget>[
          const Icon(Icons.photo_size_select_large, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              LocServ.inst.t(key),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ),
  );
}
