import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/silexgis_feature_mapper.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';

/// One row this device means to send, with the local table it came from.
class PendingUploadRow {
  const PendingUploadRow({
    required this.row,
    required this.entityTable,
    required this.entityUuid,
    this.localUpdatedAt,
  });

  final SyncUploadRow row;

  /// Where the revision this row's answer carries has to be stored.
  final String entityTable;
  final Uuid entityUuid;

  /// The local row's stamp as sent. Stored beside the revision that comes back,
  /// and what a later run compares against to tell whether the row moved again.
  /// Null for a tombstone, whose row is already gone.
  final int? localUpdatedAt;

  bool get isDelete => row.deleted;
}

/// Chooses what to send, and in what order.
///
/// **What travels is what this device already carries on that installation,
/// plus what a caver has since put inside it.** A row goes up when the server
/// already knows it — the device holds a revision for it — or when its
/// container is one of those, or is itself going up in the same batch. A cave
/// surveyed in an unrelated massif is not pushed to the club's server merely
/// because a profile is configured: putting a new root there is a deliberate
/// act, made by adding it to the sync set.
///
/// That rule is this client's, not the contract's. The contract leaves what a
/// device uploads to the device; what it fixes is that containment is the only
/// structure the server derives protection from, which is why a row with no
/// container that the server already holds has nowhere safe to land.
///
/// Live rows come in containment order — surface areas, caves, cave areas,
/// then places — because a batch is applied in the order it is given and a
/// container has to exist before the row that hangs under it.
class SilexgisUploadBuilder {
  SilexgisUploadBuilder({
    required AppDatabase db,
    required SilexgisLocalStateRepository localState,
    required String profileUuid,
    SilexgisFeatureMapper mapper = const SilexgisFeatureMapper(),
  }) : _db = db,
       _localState = localState,
       _profileUuid = profileUuid,
       _mapper = mapper;

  final AppDatabase _db;
  final SilexgisLocalStateRepository _localState;
  final String _profileUuid;
  final SilexgisFeatureMapper _mapper;

  /// Everything this run has to send, in the order to send it.
  Future<List<PendingUploadRow>> build() async {
    final revisions = await _localState.readRevisions(_profileUuid);
    final pending = <PendingUploadRow>[];

    // A row is known to this installation when the device holds a revision for
    // it. The set grows as this walk goes: a new cave under a known area is
    // itself a container for the places inside it.
    final known = revisions.keys.toSet();

    for (final area in await _db.select(_db.surfaceAreas).get()) {
      final stored = revisions[area.uuid];
      // A surface area sits at the top of everything. Only one the server
      // already holds is updated from here; a new one is a new root.
      if (stored == null || !_isDirty(area.updatedAt, stored)) continue;
      pending.add(
        PendingUploadRow(
          row: _mapper.surfaceAreaRow(area, baseRevision: stored.revision),
          entityTable: 'surface_areas',
          entityUuid: area.uuid,
          localUpdatedAt: area.updatedAt,
        ),
      );
    }

    final sendableCaves = <Uuid, Cave>{};
    for (final cave in await _db.select(_db.caves).get()) {
      final stored = revisions[cave.uuid];
      final parent = cave.surfaceAreaUuid;
      final containerIsThere = parent != null && known.contains(parent);
      if (stored == null && !containerIsThere) continue;

      sendableCaves[cave.uuid] = cave;
      known.add(cave.uuid);
      if (stored != null && !_isDirty(cave.updatedAt, stored)) continue;
      pending.add(
        PendingUploadRow(
          row: _mapper.caveRow(
            cave,
            baseRevision: stored?.revision,
            parentSurfaceAreaId: parent?.toString(),
          ),
          entityTable: 'caves',
          entityUuid: cave.uuid,
          localUpdatedAt: cave.updatedAt,
        ),
      );
    }

    final sendableCaveAreas = <Uuid, CaveArea>{};
    for (final area in await _db.select(_db.caveAreas).get()) {
      if (!sendableCaves.containsKey(area.caveUuid)) continue;
      sendableCaveAreas[area.uuid] = area;
      known.add(area.uuid);

      final stored = revisions[area.uuid];
      if (stored != null && !_isDirty(area.updatedAt, stored)) continue;
      pending.add(
        PendingUploadRow(
          row: _mapper.caveAreaRow(
            area,
            baseRevision: stored?.revision,
            parentCaveId: area.caveUuid.toString(),
          ),
          entityTable: 'cave_areas',
          entityUuid: area.uuid,
          localUpdatedAt: area.updatedAt,
        ),
      );
    }

    final areaIdentifiers = <Uuid, String?>{
      for (final area in await _db.select(_db.surfaceAreas).get())
        area.uuid: area.generalAreaIdentifier,
    };

    for (final place in await _db.select(_db.cavePlaces).get()) {
      final cave = sendableCaves[place.caveUuid];
      if (cave == null) continue;

      final stored = revisions[place.uuid];
      if (stored != null && !_isDirty(place.updatedAt, stored)) continue;

      // A place hangs under its cave area when it names one, and under the
      // cave otherwise. That edge is what decides what guards it, because
      // protection is inherited along containment and along nothing else.
      final areaUuid = place.caveAreaUuid;
      final parentId =
          areaUuid != null && sendableCaveAreas.containsKey(areaUuid)
          ? areaUuid.toString()
          : place.caveUuid.toString();

      pending.add(
        PendingUploadRow(
          row: _mapper.cavePlaceRow(
            CavePlaceUpload(
              place: place,
              caveLocalIndex: cave.caveLocalIndex,
              generalAreaIdentifier:
                  areaIdentifiers[cave.surfaceAreaUuid ?? Uuid.zero],
            ),
            baseRevision: stored?.revision,
            parentId: parentId,
          ),
          entityTable: 'cave_places',
          entityUuid: place.uuid,
          localUpdatedAt: place.updatedAt,
        ),
      );
    }

    pending.addAll(await _tombstones(revisions));
    return pending;
  }

  /// A revision for a row that is no longer in its table is a row the caver
  /// removed here.
  ///
  /// That is the whole of the delete detection, and it needs no watermark: a
  /// local delete is physical, so the absence *is* the record, and the revision
  /// beside it says the server still holds the row.
  ///
  /// Child-first, so a place goes before the cave that contained it. A removal
  /// takes the row's whole containment subtree with it there, and a device that
  /// sent the cave first would be told its places were already gone — true, but
  /// it would learn nothing about whether each removal was allowed.
  Future<List<PendingUploadRow>> _tombstones(
    Map<Uuid, StoredRevision> revisions,
  ) async {
    final present = <String, Set<Uuid>>{
      'cave_places': (await _db.select(_db.cavePlaces).get())
          .map((r) => r.uuid)
          .toSet(),
      'cave_areas': (await _db.select(_db.caveAreas).get())
          .map((r) => r.uuid)
          .toSet(),
      'caves': (await _db.select(_db.caves).get()).map((r) => r.uuid).toSet(),
      'surface_areas': (await _db.select(_db.surfaceAreas).get())
          .map((r) => r.uuid)
          .toSet(),
    };
    // What the local table implies, for a revision stored before the kind was
    // recorded. A `cave_places` row may be either kind, which is exactly why
    // the kind is kept beside the revision rather than guessed here.
    const impliedKinds = <String, SyncUploadKind>{
      'cave_places': SyncUploadKind.generic,
      'cave_areas': SyncUploadKind.generic,
      'caves': SyncUploadKind.cave,
      'surface_areas': SyncUploadKind.generic,
    };

    final gone = <PendingUploadRow>[];
    for (final table in present.keys) {
      for (final entry in revisions.entries) {
        final stored = entry.value;
        if (stored.entityTable != table) continue;
        if (present[table]!.contains(entry.key)) continue;
        gone.add(
          PendingUploadRow(
            row: _mapper.deleteRow(
              entityUuid: entry.key,
              kind: _kindOf(stored) ?? impliedKinds[table]!,
              baseRevision: stored.revision,
            ),
            entityTable: table,
            entityUuid: entry.key,
          ),
        );
      }
    }
    return gone;
  }

  /// The kind this row last travelled as, when the device recorded one.
  static SyncUploadKind? _kindOf(StoredRevision stored) {
    for (final kind in SyncUploadKind.values) {
      if (kind.wireName == stored.wireKind) return kind;
    }
    return null;
  }

  /// A row is due to be sent when its own stamp no longer equals the one the
  /// two sides last agreed about.
  ///
  /// An exact comparison rather than one against a clock reading, and that is
  /// the point: comparing a row's stamp to *when* a revision was stored leaves
  /// a window at each end — an edit in the same millisecond as an upload is
  /// missed, and a server whose clock runs ahead makes a freshly downloaded row
  /// look edited for ever. Two stamps either match or they do not.
  ///
  /// A row that has never carried a stamp is treated as due: there is nothing
  /// to compare, and one `unchanged` answer per run costs less than an edit
  /// that never leaves the device.
  bool _isDirty(int? updatedAt, StoredRevision stored) {
    if (updatedAt == null && stored.localUpdatedAt == null) return true;
    return updatedAt != stored.localUpdatedAt;
  }
}
