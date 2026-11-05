import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';

/// Takes a document link down here when the installation took it down —
/// in its web interface, say — so the phone shows what the club sees.
///
/// The local link goes together with the record that the installation held
/// it: leaving the record would keep the two apart for good, and dropping
/// it alone would send the link straight back as one this device made.
///
/// A tombstone does not say whether the link was detached or left behind by
/// a document deleted outright. For a file the device fetched from the
/// installation both mean the same here. For the caver's own file they do
/// not: when its last link on the server goes, the document itself may be
/// what went, and its next upload then re-creates it with the links it has
/// here. So the caver's own file keeps its local link unless the
/// installation still lists the document elsewhere.
///
/// Server-driven, so it runs with change logging suspended, as the links the
/// catalogue hangs here are made.
class SilexgisLinkRemovalFollower {
  SilexgisLinkRemovalFollower({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisDocumentCatalogueRepository catalogue,
    required SilexgisFileCopyRepository copies,
    required SilexgisServerLinkRepository serverLinks,
    required SilexgisHeldRowRepository heldRows,
    required String profileUuid,
  }) : _db = db,
       _logger = logger,
       _catalogue = catalogue,
       _copies = copies,
       _serverLinks = serverLinks,
       _heldRows = heldRows,
       _profileUuid = profileUuid;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisDocumentCatalogueRepository _catalogue;
  final SilexgisFileCopyRepository _copies;
  final SilexgisServerLinkRepository _serverLinks;
  final SilexgisHeldRowRepository _heldRows;
  final String _profileUuid;

  /// Follows each of [tombstonedLinkIds], after the catalogue page that
  /// carried them is stored; [removed] is the catalogue's copy of the ones it
  /// held. Returns how many local links went.
  Future<int> follow(
    Iterable<String> tombstonedLinkIds,
    Map<String, SilexgisDocumentLinkData> removed,
  ) async {
    if (tombstonedLinkIds.isEmpty) return 0;
    final held = await _serverLinks.readAll(_profileUuid);
    final heldById = <String, SilexgisServerLinkEntry>{
      for (final entry in held.values) ?entry.linkId: entry,
    };
    return _logger.runSuspended(() async {
      var gone = 0;
      for (final id in tombstonedLinkIds) {
        final catalogued = removed[id];
        // A raster map's picture goes with its map, not as a document link.
        if (catalogued?.role == SyncDocumentLink.roleMap2d) continue;
        final link = catalogued != null
            ? _Removed(
                catalogued.documentId,
                catalogued.targetKind,
                catalogued.targetId,
              )
            : switch (heldById[id]) {
                final entry? => _Removed(
                  entry.documentUuid,
                  entry.targetKind,
                  entry.targetId,
                ),
                null => null,
              };
        if (link == null) continue;
        if (await _stillListed(link)) continue;
        if (!await _fetched(link.document) &&
            await _catalogue.document(_profileUuid, link.document) == null) {
          continue;
        }
        final locals = await _removeLocal(link);
        await _heldRows.clear(
          _profileUuid,
          SyncUploadSection.documentLinks,
          locals,
        );
        await _serverLinks.forget(_profileUuid, <SilexgisLinkKey>[
          (link.document, link.target),
        ]);
        gone += locals.length;
      }
      return gone;
    });
  }

  /// The same pair hung again under another identifier, in the same page:
  /// replaced, not taken down.
  Future<bool> _stillListed(_Removed link) async {
    for (final other in await _catalogue.linksOf(_profileUuid, link.document)) {
      if (other.targetId == link.target && other.targetKind == link.kind) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _fetched(Uuid document) async =>
      (await _copies.read(document))?.origin == SilexgisCopyOrigin.server;

  /// Deletes the local link of the pair from the table its kind lives in.
  /// Returns the identifiers of the rows that went.
  Future<List<Uuid>> _removeLocal(_Removed link) async {
    switch (link.kind) {
      case SyncDocumentLink.targetFeature:
        final table = _db.documentationFilesToGeofeatures;
        final rows =
            await (_db.select(table)..where(
                  (t) =>
                      t.documentationFileUuid.equalsValue(link.document) &
                      t.geofeatureUuid.equalsValue(link.target),
                ))
                .get();
        await (_db.delete(table)..where(
              (t) =>
                  t.documentationFileUuid.equalsValue(link.document) &
                  t.geofeatureUuid.equalsValue(link.target),
            ))
            .go();
        return <Uuid>[for (final row in rows) row.uuid];
      case SyncDocumentLink.targetTripRecording:
        final table = _db.documentationFilesToCaveTrips;
        final rows =
            await (_db.select(table)..where(
                  (t) =>
                      t.documentationFileUuid.equalsValue(link.document) &
                      t.caveTripUuid.equalsValue(link.target),
                ))
                .get();
        await (_db.delete(table)..where(
              (t) =>
                  t.documentationFileUuid.equalsValue(link.document) &
                  t.caveTripUuid.equalsValue(link.target),
            ))
            .go();
        return <Uuid>[for (final row in rows) row.uuid];
      case SyncDocumentLink.targetTripPoint:
        final table = _db.documentationFilesToCaveTripPoints;
        final rows =
            await (_db.select(table)..where(
                  (t) =>
                      t.documentationFileUuid.equalsValue(link.document) &
                      t.caveTripPointUuid.equalsValue(link.target),
                ))
                .get();
        await (_db.delete(table)..where(
              (t) =>
                  t.documentationFileUuid.equalsValue(link.document) &
                  t.caveTripPointUuid.equalsValue(link.target),
            ))
            .go();
        return <Uuid>[for (final row in rows) row.uuid];
    }
    return const <Uuid>[];
  }
}

class _Removed {
  const _Removed(this.document, this.kind, this.target);

  final Uuid document;
  final String kind;
  final Uuid target;
}
