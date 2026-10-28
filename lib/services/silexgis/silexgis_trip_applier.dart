import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_trips.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_missing_item_rule.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_upload_answers.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/clock.dart';

/// What applying the trips stream did.
class SilexgisTripsApplied {
  const SilexgisTripsApplied({
    this.recordingsInserted = 0,
    this.recordingsUpdated = 0,
    this.recordingsRemoved = 0,
    this.scansInserted = 0,
    this.scansUpdated = 0,
    this.scansRemoved = 0,
    this.heldBack = 0,
    this.withoutCave = 0,
    this.scansWithoutPlace = 0,
    this.collisions = const <Uuid>[],
  });

  final int recordingsInserted;
  final int recordingsUpdated;
  final int recordingsRemoved;
  final int scansInserted;
  final int scansUpdated;
  final int scansRemoved;

  /// Recordings and scans with a local edit not yet sent, or waiting for a
  /// reviewer, left as the caver has them.
  final int heldBack;

  /// Recordings in a cave this device does not hold.
  final int withoutCave;

  /// Scans of a place this device does not hold.
  final int scansWithoutPlace;

  /// Recordings and scans whose unique key a different local row already
  /// holds. The local row is kept.
  final List<Uuid> collisions;

  int get changed =>
      recordingsInserted + recordingsUpdated + scansInserted + scansUpdated;
  int get removed => recordingsRemoved + scansRemoved;

  SilexgisTripsApplied plus(SilexgisTripsApplied other) => SilexgisTripsApplied(
    recordingsInserted: recordingsInserted + other.recordingsInserted,
    recordingsUpdated: recordingsUpdated + other.recordingsUpdated,
    recordingsRemoved: recordingsRemoved + other.recordingsRemoved,
    scansInserted: scansInserted + other.scansInserted,
    scansUpdated: scansUpdated + other.scansUpdated,
    scansRemoved: scansRemoved + other.scansRemoved,
    heldBack: heldBack + other.heldBack,
    withoutCave: withoutCave + other.withoutCave,
    scansWithoutPlace: scansWithoutPlace + other.scansWithoutPlace,
    collisions: <Uuid>[...collisions, ...other.collisions],
  );
}

/// Writes recordings and scans read from the trips stream under the
/// installation's identifiers.
///
/// **Change logging is suspended throughout**: a recording read from the
/// installation is an import, not a caver's edit, and logged it would travel
/// on to other devices as this device's work.
///
/// - A row with a local edit not yet sent, or waiting for a reviewer, is left
///   as the caver has it, exactly as a feature is.
/// - A recording first met here is marked as the installation's — another
///   phone made it — and its author, when no user on this device is that one,
///   is kept in local-only state with the row's foreign key left null.
/// - Who went, the log's staleness and the device are never in the stream,
///   and an update leaves them as they are.
/// - A scan of a place this device does not hold is skipped.
/// - A scan the stream names as removed goes, unless the caver has an edit of
///   it not yet sent. A scan merely missing from its recording's list is kept,
///   as it may only be withheld; only a server that does not name removed
///   scans leaves that to [SilexgisMissingItemRule].
/// - A row whose unique key a different local row holds is not written; the
///   local row is kept and the collision reported.
class SilexgisTripApplier {
  SilexgisTripApplier({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisTripStateRepository trips,
    required String profileUuid,
    SilexgisMissingItemRule mergeRule = const SilexgisMissingItemRule(),
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _heldRows = heldRows,
       _trips = trips,
       _profileUuid = profileUuid,
       _mergeRule = mergeRule,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisTripStateRepository _trips;
  final String _profileUuid;
  final SilexgisMissingItemRule _mergeRule;
  final Clock _clock;
  final _log = AppLogger.of('SilexgisTripApplier');

  Map<Uuid, StoredRevision> _agreed = const <Uuid, StoredRevision>{};
  Set<Uuid> _held = const <Uuid>{};
  Map<Uuid, SilexgisTripState> _states = const <Uuid, SilexgisTripState>{};
  Set<Uuid> _users = const <Uuid>{};

  /// Applies one page; [afterwards] runs inside the same transaction, which
  /// is where the caller stores the page's position.
  Future<SilexgisTripsApplied> applyPage(
    SyncTripsPage page, {
    Future<void> Function()? afterwards,
  }) async {
    var applied = const SilexgisTripsApplied();
    await _logger.runSuspended(() async {
      await _db.transaction(() async {
        _agreed = await _localState.readRevisions(_profileUuid);
        _held = <Uuid>{
          ...(await _heldRows.readSection(
            _profileUuid,
            SyncUploadSection.tripRecordings,
          )).keys,
          ...(await _heldRows.readSection(
            _profileUuid,
            SyncUploadSection.tripPoints,
          )).keys,
        };
        _states = await _trips.readAll(_profileUuid);
        _users = <Uuid>{
          for (final user in await _db.select(_db.users).get()) user.uuid,
        };
        final namesRemovedScans = page.pointTombstones != null;
        for (final recording in page.recordings) {
          applied = applied.plus(
            await _recording(recording, namesRemovedScans: namesRemovedScans),
          );
        }
        applied = applied.plus(await _tombstones(page.tombstones));
        applied = applied.plus(
          await _pointTombstones(page.pointTombstones ?? const []),
        );
        await afterwards?.call();
      });
    });
    return applied;
  }

  // -------------------------------------------------------------- recordings

  Future<SilexgisTripsApplied> _recording(
    SyncTripRecording server, {
    required bool namesRemovedScans,
  }) async {
    final id = Uuid.tryParse(server.id);
    final started = _epoch(server.startedAt);
    if (id == null || started == null) {
      _log.warning('a recording the stream sent could not be read');
      return const SilexgisTripsApplied();
    }
    final (localAuthor, foreignAuthor) = _author(server.createdByDeviceUserId);
    final stamp = _clock.nowMs();
    final local = await (_db.select(
      _db.caveTrips,
    )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();

    var applied = const SilexgisTripsApplied();
    if (local == null) {
      final cave = Uuid.tryParse(server.caveId);
      if (cave == null || !await _caveIsHere(cave)) {
        return const SilexgisTripsApplied(withoutCave: 1);
      }
      // Read with no device of its own, so its unique key never meets
      // another row's.
      await _db
          .into(_db.caveTrips)
          .insert(
            CaveTripsCompanion.insert(
              uuid: id,
              caveUuid: cave,
              title: server.title ?? '',
              tripStartedAt: started,
              description: Value(server.description),
              tripEndedAt: Value(_epoch(server.endedAt)),
              log: Value(server.log),
              createdAt: Value(stamp),
              updatedAt: Value(stamp),
              createdByUserUuid: Value(localAuthor),
            ),
          );
      await _agree(id, SilexgisTripTables.recordings, server.revision, stamp);
      await _trips.recordDownloaded(
        _profileUuid,
        SilexgisTripState(
          entityUuid: id,
          recordingUuid: id,
          received: true,
          authorDeviceUserId: foreignAuthor,
        ),
      );
      applied = const SilexgisTripsApplied(recordingsInserted: 1);
    } else if (_editedHere(id, local.updatedAt)) {
      applied = const SilexgisTripsApplied(heldBack: 1);
    } else {
      final title = server.title ?? local.title;
      // The author is never changed by a read: a recording this device made
      // keeps its own, and one it cannot name stays unnamed.
      final author = local.createdByUserUuid ?? localAuthor;
      if (await _recordingCollides(local, title, author)) {
        return SilexgisTripsApplied(collisions: <Uuid>[id]);
      }
      await (_db.update(
        _db.caveTrips,
      )..where((t) => t.uuid.equalsValue(id))).write(
        CaveTripsCompanion(
          title: Value(title),
          description: Value(server.description),
          tripStartedAt: Value(started),
          tripEndedAt: Value(_epoch(server.endedAt)),
          log: Value(server.log),
          updatedAt: Value(stamp),
          createdByUserUuid: Value(author),
        ),
      );
      await _agree(id, SilexgisTripTables.recordings, server.revision, stamp);
      await _trips.recordDownloaded(
        _profileUuid,
        SilexgisTripState(
          entityUuid: id,
          recordingUuid: id,
          authorDeviceUserId: local.createdByUserUuid == null
              ? foreignAuthor
              : null,
        ),
      );
      applied = const SilexgisTripsApplied(recordingsUpdated: 1);
    }
    return applied.plus(
      await _scans(id, server.points, namesRemovedScans: namesRemovedScans),
    );
  }

  // -------------------------------------------------------------------- scans

  Future<SilexgisTripsApplied> _scans(
    Uuid recording,
    List<SyncTripPoint> points, {
    required bool namesRemovedScans,
  }) async {
    var applied = const SilexgisTripsApplied();
    final listed = <Uuid>{};
    for (final point in points) {
      final id = Uuid.tryParse(point.id);
      if (id == null) continue;
      listed.add(id);
      applied = applied.plus(await _scan(recording, id, point));
    }
    if (namesRemovedScans) return applied;

    final local = await (_db.select(
      _db.caveTripPoints,
    )..where((t) => t.caveTripUuid.equalsValue(recording))).get();
    final removed = <Uuid>[];
    for (final scan in local) {
      if (listed.contains(scan.uuid)) continue;
      if (!_mergeRule.removesMissing(
        _states[scan.uuid],
        editedHere: _editedHere(scan.uuid, scan.updatedAt),
      )) {
        continue;
      }
      await _deleteScan(scan.uuid);
      removed.add(scan.uuid);
    }
    await _forget(removed);
    return applied.plus(SilexgisTripsApplied(scansRemoved: removed.length));
  }

  Future<void> _deleteScan(Uuid id) async {
    await _db.deleteTripPointDocumentLinks(id);
    await _db.deleteTripPoint(id);
  }

  Future<SilexgisTripsApplied> _scan(
    Uuid recording,
    Uuid id,
    SyncTripPoint server,
  ) async {
    final scanned = _epoch(server.scannedAt);
    if (scanned == null) return const SilexgisTripsApplied();
    final place = Uuid.tryParse(server.placeId);
    if (server.placeId != null &&
        (place == null || !await _placeIsHere(place))) {
      return const SilexgisTripsApplied(scansWithoutPlace: 1);
    }
    final (localAuthor, foreignAuthor) = _author(server.createdByDeviceUserId);
    final stamp = _clock.nowMs();
    final local = await (_db.select(
      _db.caveTripPoints,
    )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();

    if (local == null) {
      if (await _scanCollides(id, recording, place, scanned)) {
        return SilexgisTripsApplied(collisions: <Uuid>[id]);
      }
      await _db
          .into(_db.caveTripPoints)
          .insert(
            CaveTripPointsCompanion.insert(
              uuid: id,
              caveTripUuid: recording,
              scannedAt: scanned,
              cavePlaceUuid: Value(place),
              notes: Value(server.notes),
              createdAt: Value(stamp),
              updatedAt: Value(stamp),
              createdByUserUuid: Value(localAuthor),
            ),
          );
      await _agree(id, SilexgisTripTables.scans, server.revision, stamp);
      await _trips.recordDownloaded(
        _profileUuid,
        SilexgisTripState(
          entityUuid: id,
          recordingUuid: recording,
          isScan: true,
          received: true,
          authorDeviceUserId: foreignAuthor,
        ),
      );
      return const SilexgisTripsApplied(scansInserted: 1);
    }
    if (local.caveTripUuid != recording) {
      // A scan belongs to one recording for good; this one is another's here.
      return SilexgisTripsApplied(collisions: <Uuid>[id]);
    }
    if (_editedHere(id, local.updatedAt)) {
      return const SilexgisTripsApplied(heldBack: 1);
    }
    if (await _scanCollides(id, recording, place, scanned)) {
      return SilexgisTripsApplied(collisions: <Uuid>[id]);
    }
    await (_db.update(
      _db.caveTripPoints,
    )..where((t) => t.uuid.equalsValue(id))).write(
      CaveTripPointsCompanion(
        cavePlaceUuid: Value(place),
        scannedAt: Value(scanned),
        notes: Value(server.notes),
        updatedAt: Value(stamp),
        createdByUserUuid: Value(local.createdByUserUuid ?? localAuthor),
      ),
    );
    await _agree(id, SilexgisTripTables.scans, server.revision, stamp);
    await _trips.recordDownloaded(
      _profileUuid,
      SilexgisTripState(
        entityUuid: id,
        recordingUuid: recording,
        isScan: true,
        authorDeviceUserId: local.createdByUserUuid == null
            ? foreignAuthor
            : null,
      ),
    );
    return const SilexgisTripsApplied(scansUpdated: 1);
  }

  // --------------------------------------------------------------- tombstones

  /// A removed recording goes, with its scans and the photos' links on them —
  /// unless the caver has an edit of it not yet sent, which is theirs and is
  /// answered when it goes up.
  Future<SilexgisTripsApplied> _tombstones(
    List<SyncTombstone> tombstones,
  ) async {
    var removed = 0;
    var heldBack = 0;
    for (final tombstone in tombstones) {
      final id = Uuid.tryParse(tombstone.id);
      if (id == null) continue;
      final local = await (_db.select(
        _db.caveTrips,
      )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();
      if (local == null) continue;
      if (_editedHere(id, local.updatedAt)) {
        heldBack++;
        continue;
      }
      final scans = await _db.getTripPoints(id);
      await _db.deleteCaveTrip(id);
      await _forget(<Uuid>[id, for (final scan in scans) scan.uuid]);
      removed++;
    }
    return SilexgisTripsApplied(recordingsRemoved: removed, heldBack: heldBack);
  }

  /// A removed scan goes, with the photos' links on it — unless the caver has
  /// an edit of it not yet sent, which is theirs and is answered when it goes
  /// up, as a removed recording's is.
  Future<SilexgisTripsApplied> _pointTombstones(
    List<SyncPointTombstone> tombstones,
  ) async {
    final removed = <Uuid>[];
    var heldBack = 0;
    for (final tombstone in tombstones) {
      final id = Uuid.tryParse(tombstone.id);
      if (id == null) continue;
      final local = await (_db.select(
        _db.caveTripPoints,
      )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();
      if (local == null) continue;
      if (_editedHere(id, local.updatedAt)) {
        heldBack++;
        continue;
      }
      await _deleteScan(id);
      removed.add(id);
    }
    await _forget(removed);
    return SilexgisTripsApplied(
      scansRemoved: removed.length,
      heldBack: heldBack,
    );
  }

  // ---------------------------------------------------------------- plumbing

  /// The author as a user of this device, or the installation's identifier
  /// for one this device does not have.
  (Uuid?, String?) _author(String? deviceUserId) {
    final id = Uuid.tryParse(deviceUserId);
    if (id != null && _users.contains(id)) return (id, null);
    return (null, deviceUserId);
  }

  bool _editedHere(Uuid id, int? localUpdatedAt) {
    if (_held.contains(id)) return true;
    final agreed = _agreed[id];
    return agreed != null && !agreed.agreesWith(localUpdatedAt);
  }

  Future<void> _agree(
    Uuid id,
    String table,
    String? revision,
    int localUpdatedAt,
  ) async {
    if (revision == null) return;
    await _localState.writeRevision(
      _profileUuid,
      id,
      entityTable: table,
      revision: revision,
      localUpdatedAt: localUpdatedAt,
    );
  }

  Future<void> _forget(List<Uuid> ids) async {
    await _localState.forgetRevisions(_profileUuid, ids);
    await _trips.forget(_profileUuid, ids);
  }

  /// Whether a different local recording already holds the unique key
  /// [local] would have with [title] and [author].
  ///
  /// Asked before writing rather than learnt from a refused write: the key is
  /// declared `ON CONFLICT ROLLBACK`, which would take the whole page's
  /// transaction with it. A key with no author or no device never meets
  /// another, since each null is distinct.
  Future<bool> _recordingCollides(
    CaveTrip local,
    String title,
    Uuid? author,
  ) async {
    final device = local.deviceUuid;
    if (author == null || device == null) return false;
    final twin =
        await (_db.select(_db.caveTrips)
              ..where(
                (t) =>
                    t.uuid.equalsValue(local.uuid).not() &
                    t.title.equals(title) &
                    t.caveUuid.equalsValue(local.caveUuid) &
                    t.createdByUserUuid.equalsValue(author) &
                    t.deviceUuid.equalsValue(device),
              )
              ..limit(1))
            .getSingleOrNull();
    if (twin != null) _log.warning('a recording collides with ${twin.uuid}');
    return twin != null;
  }

  /// Whether a different local scan of [recording] holds the same place and
  /// moment — the scan table's unique key, asked before writing for the same
  /// reason.
  Future<bool> _scanCollides(
    Uuid id,
    Uuid recording,
    Uuid? place,
    int scanned,
  ) async {
    if (place == null) return false;
    final twin =
        await (_db.select(_db.caveTripPoints)
              ..where(
                (t) =>
                    t.uuid.equalsValue(id).not() &
                    t.caveTripUuid.equalsValue(recording) &
                    t.cavePlaceUuid.equalsValue(place) &
                    t.scannedAt.equals(scanned),
              )
              ..limit(1))
            .getSingleOrNull();
    if (twin != null) _log.warning('a scan collides with ${twin.uuid}');
    return twin != null;
  }

  Future<bool> _caveIsHere(Uuid cave) async =>
      await (_db.select(
        _db.caves,
      )..where((t) => t.uuid.equalsValue(cave))).getSingleOrNull() !=
      null;

  Future<bool> _placeIsHere(Uuid place) async =>
      await (_db.select(
        _db.cavePlaces,
      )..where((t) => t.uuid.equalsValue(place))).getSingleOrNull() !=
      null;

  /// A moment the stream states as a field, as local epoch milliseconds.
  ///
  /// Never applied to a `revision`: revisions are opaque and travel back
  /// verbatim, so a row's local stamp is the moment of the read.
  static int? _epoch(String? iso) {
    if (iso == null) return null;
    return DateTime.tryParse(iso)?.millisecondsSinceEpoch;
  }
}
