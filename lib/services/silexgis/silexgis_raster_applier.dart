import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_rasters.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_file_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_missing_item_rule.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/clock.dart';

/// What applying the rasters stream did.
class SilexgisRastersApplied {
  const SilexgisRastersApplied({
    this.mapsInserted = 0,
    this.mapsUpdated = 0,
    this.mapsRemoved = 0,
    this.pinsInserted = 0,
    this.pinsUpdated = 0,
    this.pinsRemoved = 0,
    this.heldBack = 0,
    this.withoutCave = 0,
    this.pinsWithoutPlace = 0,
    this.collisions = const <Uuid>[],
  });

  final int mapsInserted;
  final int mapsUpdated;
  final int mapsRemoved;
  final int pinsInserted;
  final int pinsUpdated;
  final int pinsRemoved;

  /// Maps and pins with a local edit not yet sent, or waiting for a reviewer,
  /// left as the caver has them.
  final int heldBack;

  /// Maps of a cave this device does not hold.
  final int withoutCave;

  /// Pins of a place this device does not hold.
  final int pinsWithoutPlace;

  /// Maps and pins whose unique key a different local row already holds. The
  /// local row is kept.
  final List<Uuid> collisions;

  int get changed => mapsInserted + mapsUpdated + pinsInserted + pinsUpdated;
  int get removed => mapsRemoved + pinsRemoved;

  SilexgisRastersApplied plus(SilexgisRastersApplied other) =>
      SilexgisRastersApplied(
        mapsInserted: mapsInserted + other.mapsInserted,
        mapsUpdated: mapsUpdated + other.mapsUpdated,
        mapsRemoved: mapsRemoved + other.mapsRemoved,
        pinsInserted: pinsInserted + other.pinsInserted,
        pinsUpdated: pinsUpdated + other.pinsUpdated,
        pinsRemoved: pinsRemoved + other.pinsRemoved,
        heldBack: heldBack + other.heldBack,
        withoutCave: withoutCave + other.withoutCave,
        pinsWithoutPlace: pinsWithoutPlace + other.pinsWithoutPlace,
        collisions: <Uuid>[...collisions, ...other.collisions],
      );
}

/// Writes raster maps and pins read from the rasters stream under the
/// installation's identifiers.
///
/// **Change logging is suspended throughout**: a map read from the
/// installation is an import, not a caver's edit, and logged it would travel
/// on to other devices as this device's work.
///
/// - A row with a local edit not yet sent, or waiting for a reviewer, is left
///   as the caver has it, exactly as a feature is.
/// - A map first met here gets no picture yet: its file name is where the
///   picture will be stored, named by its document, and the picture is
///   fetched after the stream is read.
/// - An area this device does not hold leaves the map's own column null and
///   is kept in local-only state, so an edit never clears it there.
/// - A pin of a place this device does not hold is skipped.
/// - A pin the stream names as removed goes, unless the caver has an edit of
///   it not yet sent. A pin merely missing from its map's list is kept, as it
///   may only be withheld; only a server that does not name removed pins
///   leaves that to [SilexgisMissingItemRule].
/// - A row whose unique key a different local row holds is not written; the
///   local row is kept and the collision reported.
class SilexgisRasterApplier {
  SilexgisRasterApplier({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisRasterStateRepository rasters,
    required SilexgisDocumentCatalogueRepository catalogue,
    required String profileUuid,
    SilexgisMissingItemRule mergeRule = const SilexgisMissingItemRule(),
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _heldRows = heldRows,
       _rasters = rasters,
       _catalogue = catalogue,
       _profileUuid = profileUuid,
       _mergeRule = mergeRule,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisRasterStateRepository _rasters;
  final SilexgisDocumentCatalogueRepository _catalogue;
  final String _profileUuid;
  final SilexgisMissingItemRule _mergeRule;
  final Clock _clock;
  final _log = AppLogger.of('SilexgisRasterApplier');

  Map<Uuid, StoredRevision> _agreed = const <Uuid, StoredRevision>{};
  Set<Uuid> _held = const <Uuid>{};
  Map<Uuid, SilexgisRasterState> _states = const <Uuid, SilexgisRasterState>{};

  /// The file name a map's picture is stored under before it is fetched, when
  /// the catalogue does not say what it is.
  static const String defaultExtension = 'jpg';

  /// Where the picture of a map of [caveUuid] held as [documentId] is stored,
  /// relative to the documents folder.
  static String picturePath(Uuid caveUuid, Uuid documentId, String extension) =>
      'cave_$caveUuid/raster_$documentId.$extension';

  /// Applies one page; [afterwards] runs inside the same transaction, which
  /// is where the caller stores the page's position.
  Future<SilexgisRastersApplied> applyPage(
    SyncRastersPage page, {
    Future<void> Function()? afterwards,
  }) async {
    var applied = const SilexgisRastersApplied();
    await _logger.runSuspended(() async {
      await _db.transaction(() async {
        _agreed = await _localState.readRevisions(_profileUuid);
        _held = <Uuid>{
          ...(await _heldRows.readSection(
            _profileUuid,
            SyncUploadSection.rasterMaps,
          )).keys,
          ...(await _heldRows.readSection(
            _profileUuid,
            SyncUploadSection.rasterPins,
          )).keys,
        };
        _states = await _rasters.readAll(_profileUuid);
        final namesRemovedPins = page.pinTombstones != null;
        for (final map in page.maps) {
          applied = applied.plus(
            await _map(map, namesRemovedPins: namesRemovedPins),
          );
        }
        applied = applied.plus(await _tombstones(page.tombstones));
        applied = applied.plus(
          await _pinTombstones(page.pinTombstones ?? const []),
        );
        await afterwards?.call();
      });
    });
    return applied;
  }

  // -------------------------------------------------------------------- maps

  Future<SilexgisRastersApplied> _map(
    SyncRasterMap server, {
    required bool namesRemovedPins,
  }) async {
    final id = Uuid.tryParse(server.id);
    final cave = Uuid.tryParse(server.caveId);
    if (id == null || cave == null) {
      _log.warning('a map the stream sent could not be read');
      return const SilexgisRastersApplied();
    }
    final document = Uuid.tryParse(server.documentId);
    final area = Uuid.tryParse(server.caveAreaId);
    final heldArea = area != null && await _areaIsHere(area) ? area : null;
    final foreignArea = heldArea == null ? area : null;
    final mapType = server.mapType.localName;
    final stamp = _clock.nowMs();
    final local = await (_db.select(
      _db.rasterMaps,
    )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();

    var applied = const SilexgisRastersApplied();
    if (local == null) {
      if (!await _caveIsHere(cave)) {
        return const SilexgisRastersApplied(withoutCave: 1);
      }
      final title = _title(server.title) ?? 'Map';
      final fileName = picturePath(
        cave,
        document ?? id,
        await _extensionOf(document),
      );
      if (await _mapCollides(id, cave, mapType, title, fileName)) {
        return SilexgisRastersApplied(collisions: <Uuid>[id]);
      }
      await _db
          .into(_db.rasterMaps)
          .insert(
            RasterMapsCompanion.insert(
              uuid: id,
              title: title,
              mapType: mapType,
              fileName: fileName,
              caveUuid: cave,
            ).copyWith(
              orderIndex: Value(server.sortOrder ?? 0),
              caveAreaUuid: Value(heldArea),
              createdAt: Value(stamp),
              updatedAt: Value(stamp),
            ),
          );
      await _agree(id, SilexgisRasterTables.maps, server.revision, stamp);
      await _rasters.recordDownloaded(
        _profileUuid,
        SilexgisRasterState(
          entityUuid: id,
          mapUuid: id,
          received: true,
          documentId: document,
          areaId: foreignArea,
        ),
      );
      applied = const SilexgisRastersApplied(mapsInserted: 1);
    } else if (local.caveUuid != cave) {
      // A map stays with the cave it was made for; this one is another's
      // here.
      return SilexgisRastersApplied(collisions: <Uuid>[id]);
    } else if (_editedHere(id, local.updatedAt)) {
      applied = const SilexgisRastersApplied(heldBack: 1);
    } else {
      final title = _title(server.title) ?? local.title;
      if (await _mapCollides(id, cave, mapType, title, local.fileName)) {
        return SilexgisRastersApplied(collisions: <Uuid>[id]);
      }
      await (_db.update(
        _db.rasterMaps,
      )..where((t) => t.uuid.equalsValue(id))).write(
        RasterMapsCompanion(
          title: Value(title),
          mapType: Value(mapType),
          orderIndex: Value(server.sortOrder ?? local.orderIndex),
          caveAreaUuid: Value(heldArea),
          updatedAt: Value(stamp),
        ),
      );
      await _agree(id, SilexgisRasterTables.maps, server.revision, stamp);
      await _rasters.recordDownloaded(
        _profileUuid,
        SilexgisRasterState(
          entityUuid: id,
          mapUuid: id,
          documentId: document,
          areaId: foreignArea,
        ),
      );
      applied = const SilexgisRastersApplied(mapsUpdated: 1);
    }
    return applied.plus(
      await _pins(id, server.pins, namesRemovedPins: namesRemovedPins),
    );
  }

  // --------------------------------------------------------------------- pins

  Future<SilexgisRastersApplied> _pins(
    Uuid map,
    List<SyncRasterPin> pins, {
    required bool namesRemovedPins,
  }) async {
    var applied = const SilexgisRastersApplied();
    final listed = <Uuid>{};
    for (final pin in pins) {
      final id = Uuid.tryParse(pin.id);
      if (id == null) continue;
      listed.add(id);
      applied = applied.plus(await _pin(map, id, pin));
    }
    if (namesRemovedPins) return applied;

    final local = await (_db.select(
      _db.cavePlaceToRasterMapDefinitions,
    )..where((t) => t.rasterMapUuid.equalsValue(map))).get();
    final removed = <Uuid>[];
    for (final pin in local) {
      if (listed.contains(pin.uuid)) continue;
      if (!_mergeRule.removesMissing(
        _states[pin.uuid],
        editedHere: _editedHere(pin.uuid, pin.updatedAt),
      )) {
        continue;
      }
      await _deletePin(pin.uuid);
      removed.add(pin.uuid);
    }
    await _forget(removed);
    return applied.plus(SilexgisRastersApplied(pinsRemoved: removed.length));
  }

  Future<void> _deletePin(Uuid id) => (_db.delete(
    _db.cavePlaceToRasterMapDefinitions,
  )..where((t) => t.uuid.equalsValue(id))).go();

  Future<SilexgisRastersApplied> _pin(
    Uuid map,
    Uuid id,
    SyncRasterPin server,
  ) async {
    final place = Uuid.tryParse(server.placeId);
    if (place == null || !await _placeIsHere(place)) {
      return const SilexgisRastersApplied(pinsWithoutPlace: 1);
    }
    final stamp = _clock.nowMs();
    final local = await (_db.select(
      _db.cavePlaceToRasterMapDefinitions,
    )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();

    if (local == null) {
      if (await _pinCollides(id, map, place)) {
        return SilexgisRastersApplied(collisions: <Uuid>[id]);
      }
      await _db
          .into(_db.cavePlaceToRasterMapDefinitions)
          .insert(
            CavePlaceToRasterMapDefinitionsCompanion.insert(
              uuid: id,
              cavePlaceUuid: place,
              rasterMapUuid: map,
            ).copyWith(
              xCoordinate: Value(server.x),
              yCoordinate: Value(server.y),
              createdAt: Value(stamp),
              updatedAt: Value(stamp),
            ),
          );
      await _agree(id, SilexgisRasterTables.pins, server.revision, stamp);
      await _rasters.recordDownloaded(
        _profileUuid,
        SilexgisRasterState(
          entityUuid: id,
          mapUuid: map,
          isPin: true,
          received: true,
        ),
      );
      return const SilexgisRastersApplied(pinsInserted: 1);
    }
    if (local.rasterMapUuid != map) {
      // A pin belongs to its map for good; this one is another's here.
      return SilexgisRastersApplied(collisions: <Uuid>[id]);
    }
    if (_editedHere(id, local.updatedAt)) {
      return const SilexgisRastersApplied(heldBack: 1);
    }
    if (await _pinCollides(id, map, place)) {
      return SilexgisRastersApplied(collisions: <Uuid>[id]);
    }
    await (_db.update(
      _db.cavePlaceToRasterMapDefinitions,
    )..where((t) => t.uuid.equalsValue(id))).write(
      CavePlaceToRasterMapDefinitionsCompanion(
        cavePlaceUuid: Value(place),
        xCoordinate: Value(server.x),
        yCoordinate: Value(server.y),
        updatedAt: Value(stamp),
      ),
    );
    await _agree(id, SilexgisRasterTables.pins, server.revision, stamp);
    await _rasters.recordDownloaded(
      _profileUuid,
      SilexgisRasterState(entityUuid: id, mapUuid: map, isPin: true),
    );
    return const SilexgisRastersApplied(pinsUpdated: 1);
  }

  // --------------------------------------------------------------- tombstones

  /// A removed map goes, with its pins — unless the caver has an edit of it
  /// not yet sent, which is theirs and is answered when it goes up. Its
  /// picture file stays, as it does when the caver removes a map.
  Future<SilexgisRastersApplied> _tombstones(
    List<SyncTombstone> tombstones,
  ) async {
    var removed = 0;
    var heldBack = 0;
    for (final tombstone in tombstones) {
      final id = Uuid.tryParse(tombstone.id);
      if (id == null) continue;
      final local = await (_db.select(
        _db.rasterMaps,
      )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();
      if (local == null) continue;
      if (_editedHere(id, local.updatedAt)) {
        heldBack++;
        continue;
      }
      final pins = await (_db.select(
        _db.cavePlaceToRasterMapDefinitions,
      )..where((t) => t.rasterMapUuid.equalsValue(id))).get();
      await (_db.delete(
        _db.cavePlaceToRasterMapDefinitions,
      )..where((t) => t.rasterMapUuid.equalsValue(id))).go();
      await (_db.delete(
        _db.rasterMaps,
      )..where((t) => t.uuid.equalsValue(id))).go();
      await _forget(<Uuid>[id, for (final pin in pins) pin.uuid]);
      removed++;
    }
    return SilexgisRastersApplied(mapsRemoved: removed, heldBack: heldBack);
  }

  /// A removed pin goes — unless the caver has an edit of it not yet sent,
  /// which is theirs and is answered when it goes up, as a removed map's is.
  Future<SilexgisRastersApplied> _pinTombstones(
    List<SyncPinTombstone> tombstones,
  ) async {
    final removed = <Uuid>[];
    var heldBack = 0;
    for (final tombstone in tombstones) {
      final id = Uuid.tryParse(tombstone.id);
      if (id == null) continue;
      final local = await (_db.select(
        _db.cavePlaceToRasterMapDefinitions,
      )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();
      if (local == null) continue;
      if (_editedHere(id, local.updatedAt)) {
        heldBack++;
        continue;
      }
      await _deletePin(id);
      removed.add(id);
    }
    await _forget(removed);
    return SilexgisRastersApplied(
      pinsRemoved: removed.length,
      heldBack: heldBack,
    );
  }

  // ---------------------------------------------------------------- plumbing

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
    await _rasters.forget(_profileUuid, ids);
  }

  /// The extension the catalogue's type of [documentId] implies, or
  /// [defaultExtension] until the picture says otherwise.
  Future<String> _extensionOf(Uuid? documentId) async {
    if (documentId == null) return defaultExtension;
    final document = await _catalogue.document(_profileUuid, documentId);
    return SilexgisDocumentFileStore.extensionFor(document?.mimeType) ??
        defaultExtension;
  }

  static String? _title(String? title) {
    final trimmed = title?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Whether a different local map of [cave] and [mapType] already holds
  /// [title] or [fileName] — the map table's two unique keys.
  ///
  /// Asked before writing rather than learnt from a refused write: the keys
  /// are declared `ON CONFLICT ROLLBACK`, which would take the whole page's
  /// transaction with it.
  Future<bool> _mapCollides(
    Uuid id,
    Uuid cave,
    String mapType,
    String title,
    String fileName,
  ) async {
    final twin =
        await (_db.select(_db.rasterMaps)
              ..where(
                (t) =>
                    t.uuid.equalsValue(id).not() &
                    t.caveUuid.equalsValue(cave) &
                    t.mapType.equals(mapType) &
                    (t.title.equals(title) | t.fileName.equals(fileName)),
              )
              ..limit(1))
            .getSingleOrNull();
    if (twin != null) _log.warning('a map collides with ${twin.uuid}');
    return twin != null;
  }

  /// Whether a different local pin already marks [place] on [map] — the pin
  /// table's unique key, asked before writing for the same reason.
  Future<bool> _pinCollides(Uuid id, Uuid map, Uuid place) async {
    final twin =
        await (_db.select(_db.cavePlaceToRasterMapDefinitions)
              ..where(
                (t) =>
                    t.uuid.equalsValue(id).not() &
                    t.rasterMapUuid.equalsValue(map) &
                    t.cavePlaceUuid.equalsValue(place),
              )
              ..limit(1))
            .getSingleOrNull();
    if (twin != null) _log.warning('a pin collides with ${twin.uuid}');
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

  Future<bool> _areaIsHere(Uuid area) async =>
      await (_db.select(
        _db.caveAreas,
      )..where((t) => t.uuid.equalsValue(area))).getSingleOrNull() !=
      null;
}
