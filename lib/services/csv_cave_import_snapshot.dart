import 'package:speleoloc/data/source/database/app_database.dart';

/// Mutable identity of one surface area as CSV cave import matching sees it.
class AreaSnapshotEntry {
  final Uuid uuid;
  final String title;

  /// Normalized: never the empty string.
  String? generalAreaIdentifier;

  AreaSnapshotEntry({
    required this.uuid,
    required this.title,
    this.generalAreaIdentifier,
  });
}

/// Mutable identity of one cave as CSV cave import matching sees it.
class CaveSnapshotEntry {
  final Uuid uuid;
  final String title;
  String? description;
  String? caveLocalIndex;
  Uuid? surfaceAreaUuid;

  CaveSnapshotEntry({
    required this.uuid,
    required this.title,
    this.description,
    this.caveLocalIndex,
    this.surfaceAreaUuid,
  });
}

/// Outcome of resolving a row's area columns: the area's effective title
/// plus the existing entry when one matches. A null [existing] means the
/// import would create this area.
typedef AreaResolution = ({String title, AreaSnapshotEntry? existing});

/// One in-memory view of the cave and surface-area identity axes the CSV
/// cave import matches on, shared by the duplicate preview, the update
/// planning and the import itself so the three phases cannot disagree.
///
/// Matching is case-insensitive on every text axis — titles, general area
/// identifiers and cave local indexes alike. The import mutates the
/// snapshot through the register/backfill/move methods as it creates and
/// updates rows, keeping later rows of the same run consistent with what
/// was already written.
class CaveImportSnapshot {
  final _areaByUuid = <Uuid, AreaSnapshotEntry>{};
  final _areaByIdentifier = <String, AreaSnapshotEntry>{};
  final _areaByTitle = <String, AreaSnapshotEntry>{};
  final _caveByUuid = <Uuid, CaveSnapshotEntry>{};
  final _caveByTitleIdx = <String, CaveSnapshotEntry>{};
  final _caveByTitleArea = <String, CaveSnapshotEntry>{};

  CaveImportSnapshot._();

  static Future<CaveImportSnapshot> load(AppDatabase db) async {
    final snapshot = CaveImportSnapshot._();
    final (areas, caves) = await (
      db.select(db.surfaceAreas).get(),
      db.select(db.caves).get(),
    ).wait;
    for (final a in areas) {
      final identifier = a.generalAreaIdentifier;
      snapshot.registerArea(
        AreaSnapshotEntry(
          uuid: a.uuid,
          title: a.title,
          generalAreaIdentifier: (identifier == null || identifier.isEmpty)
              ? null
              : identifier,
        ),
      );
    }
    for (final c in caves) {
      snapshot.registerCave(
        CaveSnapshotEntry(
          uuid: c.uuid,
          title: c.title,
          description: c.description,
          caveLocalIndex: c.caveLocalIndex,
          surfaceAreaUuid: c.surfaceAreaUuid,
        ),
      );
    }
    return snapshot;
  }

  static String _titleAreaKey(String title, Uuid? areaUuid) =>
      '${title.toLowerCase()}|${areaUuid ?? ''}';

  static String _titleIdxKey(String title, String localIndex) =>
      '${title.toLowerCase()}|${localIndex.toLowerCase()}';

  // ---------------------------------------------------------------------
  //  Areas
  // ---------------------------------------------------------------------

  void registerArea(AreaSnapshotEntry entry) {
    _areaByUuid[entry.uuid] = entry;
    _areaByTitle[entry.title.toLowerCase()] = entry;
    final identifier = entry.generalAreaIdentifier;
    if (identifier != null) {
      _areaByIdentifier[identifier.toLowerCase()] = entry;
    }
  }

  /// Records an identifier written onto an existing identifier-less area.
  void backfillAreaIdentifier(AreaSnapshotEntry entry, String identifier) {
    entry.generalAreaIdentifier = identifier;
    _areaByIdentifier[identifier.toLowerCase()] = entry;
  }

  String? areaTitleOf(Uuid uuid) => _areaByUuid[uuid]?.title;

  /// The shared area-resolution rule: an existing area matched by
  /// general area identifier wins, then one matched by title; the
  /// identifier doubles as the title when no title is given. Null when
  /// the row carries no area information at all.
  AreaResolution? resolveArea({String? identifier, String? title}) {
    if (identifier == null && title == null) return null;
    if (identifier != null) {
      final byIdentifier = _areaByIdentifier[identifier.toLowerCase()];
      if (byIdentifier != null) {
        return (title: byIdentifier.title, existing: byIdentifier);
      }
    }
    final effectiveTitle = title ?? identifier!;
    final byTitle = _areaByTitle[effectiveTitle.toLowerCase()];
    return (title: byTitle?.title ?? effectiveTitle, existing: byTitle);
  }

  // ---------------------------------------------------------------------
  //  Caves
  // ---------------------------------------------------------------------

  void registerCave(CaveSnapshotEntry entry) {
    _caveByUuid[entry.uuid] = entry;
    _caveByTitleArea[_titleAreaKey(entry.title, entry.surfaceAreaUuid)] = entry;
    final idx = entry.caveLocalIndex;
    if (idx != null && idx.isNotEmpty) {
      _caveByTitleIdx.putIfAbsent(_titleIdxKey(entry.title, idx), () => entry);
    }
  }

  CaveSnapshotEntry? caveByUuid(Uuid uuid) => _caveByUuid[uuid];

  CaveSnapshotEntry? caveByTitleAndArea(String title, Uuid? areaUuid) =>
      _caveByTitleArea[_titleAreaKey(title, areaUuid)];

  /// The shared "same cave" rule: title + local index first, then the
  /// (title, surface area) unique identity — the latter only when the row
  /// names no area or the area already exists, because an area the import
  /// has not created yet cannot hold a cave.
  CaveSnapshotEntry? matchCave({
    required String title,
    String? localIndex,
    required AreaResolution? area,
  }) {
    if (localIndex != null) {
      final byIdx = _caveByTitleIdx[_titleIdxKey(title, localIndex)];
      if (byIdx != null) return byIdx;
    }
    if (area != null && area.existing == null) return null;
    return caveByTitleAndArea(title, area?.existing?.uuid);
  }

  /// Records a local index written onto a cave, opening the
  /// title + local index axis for later rows.
  void setCaveLocalIndex(CaveSnapshotEntry entry, String localIndex) {
    entry.caveLocalIndex = localIndex;
    _caveByTitleIdx.putIfAbsent(
      _titleIdxKey(entry.title, localIndex),
      () => entry,
    );
  }

  /// Re-keys the cave under its new surface area, vacating the previous
  /// (title, area) slot so later rows can move into or create a cave there.
  void moveCaveToArea(CaveSnapshotEntry entry, Uuid? areaUuid) {
    _caveByTitleArea.removeWhere((_, e) => identical(e, entry));
    entry.surfaceAreaUuid = areaUuid;
    _caveByTitleArea[_titleAreaKey(entry.title, areaUuid)] = entry;
  }
}
