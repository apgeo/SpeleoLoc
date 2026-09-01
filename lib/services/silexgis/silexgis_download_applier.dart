import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/silexgis_feature_mapper.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Why a downloaded row was not written.
enum SilexgisSkipReason {
  /// Its `kind` or `featureTypeCode` is one this build does not model. Stored
  /// nowhere and left alone, which is safe only because this client never
  /// derives a deletion from what the server holds.
  unmodelledKind,

  /// Its container never arrived and is not here. The caller may read the row
  /// but not the cave above it, and a place with no cave is not a shape this
  /// application has.
  unresolvedParent,

  /// A local row of a different identity already holds the unique key this one
  /// wants — two devices that named the same chamber before they ever met. The
  /// local row is kept.
  uniqueCollision,
}

/// What one page did.
class SilexgisApplyReport {
  const SilexgisApplyReport({
    this.inserted = 0,
    this.updated = 0,
    this.deleted = 0,
    this.deferred = 0,
    this.skipped = const <SilexgisSkipReason, int>{},
  });

  final int inserted;
  final int updated;

  /// Tombstones applied. A tombstone for an identifier this device does not
  /// hold is a no-op and is not counted.
  final int deleted;

  /// Rows held back because their container has not arrived yet — the order is
  /// the change order and has nothing to do with containment, so a child can
  /// arrive a whole page before its parent.
  final int deferred;

  final Map<SilexgisSkipReason, int> skipped;

  int get skippedTotal => skipped.values.fold(0, (a, b) => a + b);

  SilexgisApplyReport plus(SilexgisApplyReport other) => SilexgisApplyReport(
    inserted: inserted + other.inserted,
    updated: updated + other.updated,
    deleted: deleted + other.deleted,
    deferred: other.deferred,
    skipped: <SilexgisSkipReason, int>{
      for (final reason in SilexgisSkipReason.values)
        if ((skipped[reason] ?? 0) + (other.skipped[reason] ?? 0) > 0)
          reason: (skipped[reason] ?? 0) + (other.skipped[reason] ?? 0),
    },
  );
}

/// Writes downloaded rows into the local database.
///
/// **The whole of it runs with change logging suspended.** Applying downloaded
/// rows is an import, not a user edit: logged, every one of them would look
/// like local work, the FTP upload gate would see it, and the same rows would
/// travel back out in the next archive — ping-pong between devices with no
/// user action anywhere in the loop.
///
/// One instance per sync run. It holds the rows whose container has not
/// arrived yet, because a page can carry a child a whole page before its
/// parent and the two are only related by containment, never by order.
class SilexgisDownloadApplier {
  SilexgisDownloadApplier({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required ICaveRepository caves,
    required ICavePlaceRepository places,
    required String profileUuid,
    SilexgisFeatureMapper mapper = const SilexgisFeatureMapper(),
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _caves = caves,
       _places = places,
       _profileUuid = profileUuid,
       _mapper = mapper;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final ICaveRepository _caves;
  final ICavePlaceRepository _places;
  final String _profileUuid;
  final SilexgisFeatureMapper _mapper;
  final _log = AppLogger.of('SilexgisDownloadApplier');

  /// Rows whose container is neither local nor yet downloaded, carried to the
  /// next page. A row still here when the run ends is one whose cave this
  /// account may not read.
  final List<MappedFeature> _pending = <MappedFeature>[];

  int get pendingCount => _pending.length;

  /// Applies one page and stores the position it hands back, in one
  /// transaction: a page that is written but whose cursor is lost would be
  /// re-read, and one whose cursor is stored without the rows would not.
  Future<SilexgisApplyReport> applyPage(
    SyncDownloadPage page, {
    required String setId,
  }) async {
    late SilexgisApplyReport report;
    await _logger.runSuspended(() async {
      await _db.transaction(() async {
        // A child may be written before its parent within one pass; the
        // deferred check lets that happen and still fails a genuinely broken
        // edge at commit.
        await _db.customStatement('PRAGMA defer_foreign_keys = ON');
        report = await _applyRows(page);
        final deletes = await _applyTombstones(page.tombstones);
        report = SilexgisApplyReport(
          inserted: report.inserted,
          updated: report.updated,
          deleted: deletes,
          deferred: _pending.length,
          skipped: report.skipped,
        );
        await _localState.writeSetState(
          _profileUuid,
          setId,
          cursor: page.nextCursor,
          setRevision: page.setRevision,
        );
      });
    });
    return report;
  }

  /// Rows the run never resolved, reported once at the end so a caver is told
  /// something was carried and not stored rather than left to notice.
  List<SyncFeatureRow> takeUnresolved() {
    final unresolved = _pending.map((m) => m.row).toList(growable: false);
    _pending.clear();
    return unresolved;
  }

  // ------------------------------------------------------------------- rows

  Future<SilexgisApplyReport> _applyRows(SyncDownloadPage page) async {
    var inserted = 0;
    var updated = 0;
    final skipped = <SilexgisSkipReason, int>{};
    void skip(SilexgisSkipReason reason) =>
        skipped[reason] = (skipped[reason] ?? 0) + 1;

    final queue = <MappedFeature>[..._pending];
    _pending.clear();
    for (final row in page.features) {
      final mapped = _mapper.read(row);
      if (mapped is UnmappedFeature) {
        // Not an error: an installation's taxonomy grows without a contract
        // change, and a selection carries everything under its roots.
        _log.fine(
          'ignoring a ${mapped.kind}/${mapped.featureTypeCode} row this build '
          'does not model',
        );
        skip(SilexgisSkipReason.unmodelledKind);
        continue;
      }
      queue.add(mapped);
    }

    // Repeated passes rather than one, because the order is the change order:
    // within a single page a child may precede its parent, and sorting the
    // arrays would break the cursor's meaning.
    final revisions = <SilexgisRevisionEntry>[];
    var progressed = true;
    while (progressed && queue.isNotEmpty) {
      progressed = false;
      for (final mapped in List<MappedFeature>.from(queue)) {
        final outcome = await _write(mapped, revisions);
        switch (outcome) {
          case _Outcome.inserted:
            inserted++;
          case _Outcome.updated:
            updated++;
          case _Outcome.collided:
            skip(SilexgisSkipReason.uniqueCollision);
          case _Outcome.deferred:
            continue;
        }
        queue.remove(mapped);
        progressed = true;
      }
    }
    _pending.addAll(queue);

    await _localState.writeRevisions(_profileUuid, revisions);
    return SilexgisApplyReport(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
    );
  }

  Future<_Outcome> _write(
    MappedFeature mapped,
    List<SilexgisRevisionEntry> revisions,
  ) async {
    final uuid = mapped.uuid;
    if (uuid == null) return _Outcome.collided;

    final _Outcome outcome;
    final String table;
    switch (mapped) {
      case MappedSurfaceArea():
        table = 'surface_areas';
        outcome = await _writeSurfaceArea(mapped, uuid);
      case MappedCave():
        table = 'caves';
        outcome = await _writeCave(mapped, uuid);
      case MappedCaveArea():
        table = 'cave_areas';
        outcome = await _writeCaveArea(mapped, uuid);
      case MappedCavePlace():
        table = 'cave_places';
        outcome = await _writeCavePlace(mapped, uuid);
      case UnmappedFeature():
        return _Outcome.collided;
    }

    if (outcome == _Outcome.inserted || outcome == _Outcome.updated) {
      // Stored only once the row itself is: a revision for a row that is not
      // here would make the next upload send an edit against a base the device
      // cannot show anybody.
      revisions.add(
        SilexgisRevisionEntry(
          entityUuid: uuid,
          entityTable: table,
          // Kept so a later removal can name the row's kind: by then the row
          // is physically gone from this device and nothing else remembers
          // whether it was an entrance.
          wireKind: mapped.row.kind,
          // The stamp this import just wrote onto the row, so the next upload
          // can tell a row that merely arrived from one the caver edited.
          localUpdatedAt: _epoch(mapped.row.updatedAt),
          revision: mapped.row.updatedAt,
        ),
      );
    }
    return outcome;
  }

  Future<_Outcome> _writeSurfaceArea(
    MappedSurfaceArea mapped,
    Uuid uuid,
  ) async {
    final local = await (_db.select(
      _db.surfaceAreas,
    )..where((t) => t.uuid.equalsValue(uuid))).getSingleOrNull();

    if (local == null) {
      return _insert(
        _db.surfaceAreas,
        SurfaceArea(
          uuid: uuid,
          title: mapped.title ?? '',
          description: mapped.description,
          generalAreaIdentifier: mapped.generalAreaIdentifier,
          createdAt: _epoch(mapped.row.createdAt),
          updatedAt: _epoch(mapped.row.updatedAt),
        ),
      );
    }
    return _update(
      _db.surfaceAreas,
      local.copyWith(
        title: mapped.title ?? local.title,
        description: Value(mapped.description),
        generalAreaIdentifier: Value(mapped.generalAreaIdentifier),
        updatedAt: Value(_epoch(mapped.row.updatedAt)),
      ),
    );
  }

  Future<_Outcome> _writeCave(MappedCave mapped, Uuid uuid) async {
    // A cave's container is a surface area. Unlike a place's, it is optional
    // locally, so a cave whose area this caller cannot read is still a cave.
    final parent = mapped.parentUuid;
    final local = await (_db.select(
      _db.caves,
    )..where((t) => t.uuid.equalsValue(uuid))).getSingleOrNull();

    if (local == null) {
      return _insert(
        _db.caves,
        Cave(
          uuid: uuid,
          title: mapped.title ?? '',
          description: mapped.description,
          surfaceAreaUuid: await _exists(_db.surfaceAreas, parent)
              ? parent
              : null,
          caveLocalIndex: mapped.caveLocalIndex,
          createdAt: _epoch(mapped.row.createdAt),
          updatedAt: _epoch(mapped.row.updatedAt),
        ),
      );
    }
    return _update(
      _db.caves,
      local.copyWith(
        title: mapped.title ?? local.title,
        description: Value(mapped.description),
        caveLocalIndex: Value(mapped.caveLocalIndex),
        updatedAt: Value(_epoch(mapped.row.updatedAt)),
      ),
    );
  }

  Future<_Outcome> _writeCaveArea(MappedCaveArea mapped, Uuid uuid) async {
    final local = await (_db.select(
      _db.caveAreas,
    )..where((t) => t.uuid.equalsValue(uuid))).getSingleOrNull();

    if (local == null) {
      final cave = mapped.parentUuid;
      if (!await _exists(_db.caves, cave)) return _Outcome.deferred;
      return _insert(
        _db.caveAreas,
        CaveArea(
          uuid: uuid,
          title: mapped.title ?? '',
          description: mapped.description,
          caveUuid: cave!,
          createdAt: _epoch(mapped.row.createdAt),
          updatedAt: _epoch(mapped.row.updatedAt),
        ),
      );
    }
    // Containment is not carried by this contract after a row is created, so
    // an existing row's cave is left where it is.
    return _update(
      _db.caveAreas,
      local.copyWith(
        title: mapped.title ?? local.title,
        description: Value(mapped.description),
        updatedAt: Value(_epoch(mapped.row.updatedAt)),
      ),
    );
  }

  Future<_Outcome> _writeCavePlace(MappedCavePlace mapped, Uuid uuid) async {
    final local = await (_db.select(
      _db.cavePlaces,
    )..where((t) => t.uuid.equalsValue(uuid))).getSingleOrNull();

    if (local == null) {
      // The container is either the cave or an area inside it. A place hung
      // under an area needs the area's cave too, which is why the area has to
      // be here first.
      final parent = mapped.parentUuid;
      Uuid? cave;
      Uuid? area;
      if (await _exists(_db.caves, parent)) {
        cave = parent;
      } else {
        final areaRow = parent == null
            ? null
            : await (_db.select(
                _db.caveAreas,
              )..where((t) => t.uuid.equalsValue(parent))).getSingleOrNull();
        if (areaRow == null) return _Outcome.deferred;
        area = areaRow.uuid;
        cave = areaRow.caveUuid;
      }

      return _insert(
        _db.cavePlaces,
        CavePlace(
          uuid: uuid,
          title: mapped.title ?? '',
          description: mapped.description,
          caveUuid: cave!,
          caveAreaUuid: area,
          placeCodeIdentifier: mapped.placeCodeIdentifier,
          qrCodeResourceIdentifier: mapped.qrCodeResourceIdentifier,
          latitude: mapped.latitude,
          longitude: mapped.longitude,
          altitude: mapped.altitude,
          depthInCave: mapped.depthInCave,
          isEntrance: mapped.isEntrance ? 1 : 0,
          // The download carries no main-entrance flag; what encodes it on the
          // server is that a cave's map point is a copy of its main entrance's.
          // A row first met here is not assumed to be one.
          isMainEntrance: 0,
          createdAt: _epoch(mapped.row.createdAt),
          updatedAt: _epoch(mapped.row.updatedAt),
        ),
      );
    }

    return _update(
      _db.cavePlaces,
      local.copyWith(
        title: mapped.title ?? local.title,
        description: Value(mapped.description),
        placeCodeIdentifier: Value(mapped.placeCodeIdentifier),
        qrCodeResourceIdentifier: Value(mapped.qrCodeResourceIdentifier),
        latitude: Value(mapped.latitude),
        longitude: Value(mapped.longitude),
        altitude: Value(mapped.altitude),
        depthInCave: Value(mapped.depthInCave),
        isEntrance: mapped.isEntrance ? 1 : 0,
        updatedAt: Value(_epoch(mapped.row.updatedAt)),
      ),
    );
  }

  // -------------------------------------------------------------- tombstones

  /// A delete is a row that says it was deleted, not the absence of one — so a
  /// tombstone is what stops a row this club removed from being re-uploaded by
  /// this device on its next run.
  ///
  /// The repositories do the removal, inside the same suspended block, because
  /// they also detach the map bindings, trip points, document links and beacon
  /// registrations that hang off a place. A tombstone for an identifier this
  /// device does not hold is a no-op.
  Future<int> _applyTombstones(List<SyncTombstone> tombstones) async {
    var applied = 0;
    for (final tombstone in tombstones) {
      final uuid = Uuid.tryParse(tombstone.id);
      if (uuid == null) continue;
      try {
        if (await _exists(_db.cavePlaces, uuid)) {
          await _places.deleteCavePlace(uuid);
        } else if (await _exists(_db.caveAreas, uuid)) {
          final area = await (_db.select(
            _db.caveAreas,
          )..where((t) => t.uuid.equalsValue(uuid))).getSingle();
          await _caves.deleteCaveArea(area);
        } else if (await _exists(_db.caves, uuid)) {
          await _caves.deleteCave(uuid);
        } else if (await _exists(_db.surfaceAreas, uuid)) {
          final area = await (_db.select(
            _db.surfaceAreas,
          )..where((t) => t.uuid.equalsValue(uuid))).getSingle();
          await _caves.deleteSurfaceArea(area);
        } else {
          // A tombstone can arrive for a row this device was never sent: the
          // withholding of a position applies to live rows only, and a
          // deletion that failed to propagate would be permanent.
          continue;
        }
      } on Exception catch (e) {
        _log.warning('could not apply the tombstone for $uuid: $e');
        continue;
      }
      // The identifier stays this row's identity for ever, but its revision on
      // this installation is gone: if the caver recreates it, it is new there.
      await _localState.forgetRevisions(_profileUuid, <Uuid>[uuid]);
      applied++;
    }
    return applied;
  }

  // ---------------------------------------------------------------- plumbing

  Future<_Outcome> _insert<T extends Table, D>(
    TableInfo<T, D> table,
    Insertable<D> row,
  ) async {
    try {
      await _db.into(table).insert(row);
      return _Outcome.inserted;
    } on Exception catch (e) {
      // A different local row already holds this one's unique key — two
      // devices that named the same chamber before they ever met. Keep the
      // local row: one collision must never sink a page.
      _log.warning(
        'unique-constraint collision inserting into '
        '${table.actualTableName}; keeping the local row: $e',
      );
      return _Outcome.collided;
    }
  }

  Future<_Outcome> _update<T extends Table, D>(
    TableInfo<T, D> table,
    Insertable<D> row,
  ) async {
    try {
      // By primary key, never insert-or-replace: SQLite's REPLACE deletes
      // every row conflicting on any unique index before re-inserting, so an
      // incoming edit whose new key collided with an unrelated local row would
      // silently destroy that row and orphan its children.
      await _db.update(table).replace(row);
      return _Outcome.updated;
    } on Exception catch (e) {
      _log.warning(
        'unique-constraint collision updating ${table.actualTableName}; '
        'keeping the local row: $e',
      );
      return _Outcome.collided;
    }
  }

  Future<bool> _exists<T extends Table, D>(
    TableInfo<T, D> table,
    Uuid? uuid,
  ) async {
    if (uuid == null) return false;
    final rows = await _db
        .customSelect(
          'SELECT 1 FROM ${table.actualTableName} WHERE uuid = ? LIMIT 1',
          variables: <Variable<Object>>[Variable<Uint8List>(uuid.bytes)],
        )
        .get();
    return rows.isNotEmpty;
  }

  /// The server's own stamp, as local epoch milliseconds.
  ///
  /// Deliberately not the moment of the import: device-to-device merges are
  /// still last-writer-wins on this column, and stamping "now" would make
  /// every downloaded row beat a peer's newer edit in the next archive merge.
  static int? _epoch(String? iso) {
    if (iso == null) return null;
    return DateTime.tryParse(iso)?.millisecondsSinceEpoch;
  }
}

enum _Outcome { inserted, updated, collided, deferred }
