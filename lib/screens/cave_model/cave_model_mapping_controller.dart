import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/model_mark_colours.dart';
import 'package:speleoloc/services/cave_model/model_splay_offset.dart';
import 'package:speleoloc/services/cave_model/model_viewer_command.dart';
import 'package:speleoloc/services/repository_interfaces.dart';

/// The cave's places and their mappings in the model on screen, for the 3D
/// viewer: what to mark, what is at a station, what is still unmapped.
class CaveModelMappingController extends ChangeNotifier {
  CaveModelMappingController({
    required this.caveUuid,
    required this.modelUuid,
    required ICavePlaceRepository places,
    required ICaveRepository caves,
    required IPlaceStationMappingRepository mappings,
  }) : _places = places,
       _caves = caves,
       _mappings = mappings;

  final Uuid caveUuid;
  final Uuid modelUuid;
  final ICavePlaceRepository _places;
  final ICaveRepository _caves;
  final IPlaceStationMappingRepository _mappings;

  StreamSubscription<List<CavePlace>>? _placeWatch;
  StreamSubscription<List<CavePlaceModelStation>>? _mappingWatch;

  List<CavePlace> places = const [];
  Map<Uuid, CaveArea> areas = const {};
  Map<Uuid, CavePlaceModelStation> mappingByPlace = const {};

  /// Mapped places whose station the loaded model does not have.
  Set<Uuid> unresolved = const {};

  Future<void> start() async {
    areas = {for (final a in await _caves.getCaveAreas(caveUuid)) a.uuid: a};
    _placeWatch = _places.watchCavePlaces(caveUuid).listen((rows) {
      places = rows..sort((a, b) => a.title.compareTo(b.title));
      notifyListeners();
    });
    _mappingWatch = _mappings.watchMappingsForModel(modelUuid).listen((rows) {
      mappingByPlace = {for (final m in rows) m.cavePlaceUuid: m};
      notifyListeners();
    });
  }

  CavePlace? place(Uuid uuid) {
    for (final p in places) {
      if (p.uuid == uuid) return p;
    }
    return null;
  }

  CavePlaceModelStation? mappingOf(Uuid placeUuid) => mappingByPlace[placeUuid];

  List<CavePlace> placesAt(String station) => [
    for (final p in places)
      if (mappingByPlace[p.uuid]?.station == station) p,
  ];

  List<CavePlace> get mappedPlaces => [
    for (final p in places)
      if (mappingByPlace.containsKey(p.uuid)) p,
  ];

  List<CavePlace> get unmappedPlaces => [
    for (final p in places)
      if (!mappingByPlace.containsKey(p.uuid)) p,
  ];

  /// The first unmapped place after [after] in title order, wrapping round;
  /// null when every place is mapped.
  CavePlace? nextUnmapped({Uuid? after}) {
    final unmapped = unmappedPlaces;
    if (unmapped.isEmpty) return null;
    if (after == null) return unmapped.first;
    final all = places.map((p) => p.uuid).toList();
    final start = all.indexOf(after);
    for (var i = 1; i <= all.length; i++) {
      final candidate = place(all[(start + i) % all.length]);
      if (candidate != null && !mappingByPlace.containsKey(candidate.uuid)) {
        return candidate;
      }
    }
    return null;
  }

  ModelSplayOffset? splayOf(CavePlaceModelStation mapping) {
    final (e, n, u) = (mapping.splayEast, mapping.splayNorth, mapping.splayUp);
    return e == null || n == null || u == null
        ? null
        : ModelSplayOffset(e, n, u);
  }

  List<ModelMark> marks({required bool colourByArea}) {
    final colours = colourByArea
        ? ModelMarkColours.byArea(areas.values)
        : const <Uuid, String>{};
    return [
      for (final p in mappedPlaces)
        ModelMark(
          id: p.uuid.toString(),
          station: mappingByPlace[p.uuid]!.station,
          offset: splayOf(mappingByPlace[p.uuid]!),
          label: p.title,
          color: colours[p.caveAreaUuid] ?? ModelMarkColours.mapped,
        ),
    ];
  }

  void markUnresolved(Iterable<String> ids) {
    unresolved = {for (final id in ids) ?Uuid.tryParse(id)};
    notifyListeners();
  }

  Future<void> map(
    CavePlace place,
    String station, {
    ModelSplayOffset? splay,
  }) => _mappings.saveMapping(
    cavePlaceUuid: place.uuid,
    caveUuid: caveUuid,
    documentationFileUuid: modelUuid,
    station: station,
    splay: splay,
  );

  Future<void> unmap(CavePlace place) =>
      _mappings.deleteMapping(place.uuid, modelUuid);

  /// Adds a place to the cave and returns it, for mapping a station that has
  /// no place yet. [depthInCave] in metres below the cave's reference.
  Future<CavePlace?> createPlace(String title, {double? depthInCave}) async {
    final uuid = await _places.addCavePlaceFromCompanion(
      CavePlacesCompanion.insert(
        uuid: Uuid.v7(),
        title: title,
        caveUuid: caveUuid,
        depthInCave: depthInCave == null
            ? const Value.absent()
            : Value(depthInCave),
      ),
    );
    return (await _places.getCavePlaces(
      caveUuid,
    )).where((p) => p.uuid == uuid).firstOrNull;
  }

  @override
  void dispose() {
    unawaited(_placeWatch?.cancel());
    unawaited(_mappingWatch?.cancel());
    super.dispose();
  }
}
