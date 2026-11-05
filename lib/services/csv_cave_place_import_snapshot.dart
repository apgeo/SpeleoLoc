import 'package:speleoloc/data/source/database/app_database.dart';

/// Mutable identity of one cave place as CSV place import matching sees it.
class PlaceSnapshotEntry {
  final Uuid uuid;
  final Uuid caveUuid;
  final String title;
  Uuid? caveAreaUuid;
  String? placeCode;

  PlaceSnapshotEntry({
    required this.uuid,
    required this.caveUuid,
    required this.title,
    this.caveAreaUuid,
    this.placeCode,
  });
}

/// Identity of one cave as CSV place import matching sees it.
typedef CaveSnapshotRef = ({Uuid uuid, String title});

/// Outcome of looking a name up: the single entry it names, or the
/// knowledge that it names several and the row cannot be placed. Neither
/// set means nothing matches yet.
typedef SnapshotMatch<T> = ({T? match, bool ambiguous});

/// One in-memory view of the caves, cave areas, places and place codes the
/// CSV place import matches against, built once per phase so the duplicate
/// preview, the code-conflict check and the import resolve every row the
/// same way without a query per row.
///
/// Names match case-insensitively on every axis, while place codes match
/// exactly, as the add-place form compares them. A place code is unique
/// only within its cave, so holders are kept per cave.
class CavePlaceImportSnapshot {
  final _cavesByTitle = <String, List<CaveSnapshotRef>>{};
  final _caveTitleByUuid = <Uuid, String>{};
  final _areaByKey = <String, Uuid>{};
  final _placesByKey = <String, List<PlaceSnapshotEntry>>{};
  final _holdersByKey = <String, List<PlaceSnapshotEntry>>{};

  CavePlaceImportSnapshot._();

  /// Loads every cave, and the areas and places of [caveUuid] alone when
  /// the import is scoped to one cave.
  static Future<CavePlaceImportSnapshot> load(
    AppDatabase db, {
    Uuid? caveUuid,
  }) async {
    final snapshot = CavePlaceImportSnapshot._();
    final areaQuery = db.select(db.caveAreas);
    final placeQuery = db.select(db.cavePlaces);
    if (caveUuid != null) {
      areaQuery.where((a) => a.caveUuid.equalsValue(caveUuid));
      placeQuery.where((p) => p.caveUuid.equalsValue(caveUuid));
    }
    final (caves, areas, places) = await (
      db.select(db.caves).get(),
      areaQuery.get(),
      placeQuery.get(),
    ).wait;
    for (final c in caves) {
      snapshot.registerCave(c.uuid, c.title);
    }
    for (final a in areas) {
      snapshot.registerArea(a.caveUuid, a.title, a.uuid);
    }
    for (final p in places) {
      snapshot.registerPlace(
        PlaceSnapshotEntry(
          uuid: p.uuid,
          caveUuid: p.caveUuid,
          title: p.title,
          caveAreaUuid: p.caveAreaUuid,
          placeCode: p.placeCodeIdentifier,
        ),
      );
    }
    return snapshot;
  }

  static String _key(Uuid caveUuid, String text) => '$caveUuid|$text';

  void registerCave(Uuid uuid, String title) {
    _caveTitleByUuid[uuid] = title;
    _cavesByTitle.putIfAbsent(title.toLowerCase(), () => []).add((
      uuid: uuid,
      title: title,
    ));
  }

  String? caveTitleOf(Uuid uuid) => _caveTitleByUuid[uuid];

  /// Caves are unique on title plus surface area, so one title can name
  /// several caves; the place CSV carries nothing that tells them apart.
  SnapshotMatch<CaveSnapshotRef> cavesTitled(String title) {
    final caves = _cavesByTitle[title.toLowerCase()] ?? const [];
    return (
      match: caves.length == 1 ? caves.single : null,
      ambiguous: caves.length > 1,
    );
  }

  void registerArea(Uuid caveUuid, String title, Uuid uuid) {
    _areaByKey.putIfAbsent(_key(caveUuid, title.toLowerCase()), () => uuid);
  }

  Uuid? areaOf(Uuid caveUuid, String title) =>
      _areaByKey[_key(caveUuid, title.toLowerCase())];

  void registerPlace(PlaceSnapshotEntry entry) {
    _placesByKey
        .putIfAbsent(_key(entry.caveUuid, entry.title.toLowerCase()), () => [])
        .add(entry);
    final code = entry.placeCode;
    if (code != null) {
      _holdersByKey
          .putIfAbsent(_key(entry.caveUuid, code), () => [])
          .add(entry);
    }
  }

  /// The place a row names inside one cave.
  ///
  /// Titles are unique per (cave, area), so a row that names an area picks
  /// the place in that area, else an area-less place it can be filed
  /// under; a place in a different area is a different place. A row with
  /// no area picks the only place of that name, else the area-less one.
  /// [areaUuid] is null for an area the import has not created yet, which
  /// no place can be in.
  SnapshotMatch<PlaceSnapshotEntry> placeIn(
    Uuid caveUuid,
    String title, {
    required bool rowNamesArea,
    Uuid? areaUuid,
  }) {
    final candidates = _placesByKey[_key(caveUuid, title.toLowerCase())];
    if (candidates == null || candidates.isEmpty) {
      return (match: null, ambiguous: false);
    }
    if (!rowNamesArea && candidates.length == 1) {
      return (match: candidates.single, ambiguous: false);
    }
    if (rowNamesArea && areaUuid != null) {
      final inArea = candidates.where((p) => p.caveAreaUuid == areaUuid);
      if (inArea.isNotEmpty) return _single(inArea.toList());
    }
    final areaLess = candidates.where((p) => p.caveAreaUuid == null).toList();
    if (areaLess.isEmpty) return (match: null, ambiguous: !rowNamesArea);
    return _single(areaLess);
  }

  static SnapshotMatch<PlaceSnapshotEntry> _single(
    List<PlaceSnapshotEntry> places,
  ) => (
    match: places.length == 1 ? places.single : null,
    ambiguous: places.length > 1,
  );

  /// Places of [caveUuid] holding [code], other than [except].
  List<PlaceSnapshotEntry> holdersOf(
    Uuid caveUuid,
    String code, {
    PlaceSnapshotEntry? except,
  }) => [
    for (final p in _holdersByKey[_key(caveUuid, code)] ?? const [])
      if (!identical(p, except)) p,
  ];

  /// Records a code written onto or removed from a place, keeping the
  /// holder index in step for later rows of the same run.
  void setPlaceCode(PlaceSnapshotEntry entry, String? code) {
    final old = entry.placeCode;
    if (old != null) {
      _holdersByKey[_key(entry.caveUuid, old)]?.remove(entry);
    }
    entry.placeCode = code;
    if (code != null) {
      _holdersByKey
          .putIfAbsent(_key(entry.caveUuid, code), () => [])
          .add(entry);
    }
  }
}
