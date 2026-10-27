import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// Hangs documents fetched from an installation on the features this device
/// holds, wherever the catalogue hangs them.
///
/// A fetched file is linked when it arrives, but only to the features held
/// then; a feature that arrives later, or that the caver adds to the
/// selection, gets the link on the next catalogue read. Every link made here
/// is recorded as one the installation holds, so a link the caver removes is
/// a removal to send, not a gap to fill again: a pair the installation holds
/// with no local link is left alone.
///
/// Server-driven, so it runs with change logging suspended: a change-log
/// entry would carry the link to other devices as if this device had made it.
class SilexgisDocumentLinker {
  SilexgisDocumentLinker({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisDocumentCatalogueRepository catalogue,
    required SilexgisFileCopyRepository copies,
    required SilexgisServerLinkRepository serverLinks,
    required String profileUuid,
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _catalogue = catalogue,
       _copies = copies,
       _serverLinks = serverLinks,
       _profileUuid = profileUuid,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisDocumentCatalogueRepository _catalogue;
  final SilexgisFileCopyRepository _copies;
  final SilexgisServerLinkRepository _serverLinks;
  final String _profileUuid;
  final Clock _clock;

  /// Links every fetched document still on this device to the catalogue's
  /// targets it holds. Returns how many links it made.
  Future<int> linkFetched() async {
    var linked = 0;
    await _logger.runSuspended(() async {
      await _db.transaction(() async {
        for (final id in await _copies.fetchedFromServer()) {
          final row = await (_db.select(
            _db.documentationFiles,
          )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();
          if (row == null || row.deletedAt != null) continue;
          linked += await linkDocument(
            id,
            await _catalogue.linksOf(_profileUuid, id),
          );
        }
      });
    });
    return linked;
  }

  /// Links [documentId] to each feature target of [links] this device holds.
  /// The caller suspends change logging. Returns how many links it made.
  Future<int> linkDocument(
    Uuid documentId,
    Iterable<SilexgisDocumentLinkData> links,
  ) async {
    final held = await _serverLinks.readAll(_profileUuid);
    final now = _clock.nowMs();
    final seen = <Uuid>{};
    var linked = 0;
    for (final link in links) {
      // A raster map's picture arrives with its map, not as a document.
      if (link.role == SyncDocumentLink.roleMap2d ||
          link.targetKind != SyncDocumentLink.targetFeature) {
        continue;
      }
      if (!seen.add(link.targetId)) continue;
      final entry = SilexgisServerLinkEntry(
        documentUuid: documentId,
        targetKind: link.targetKind,
        targetId: link.targetId,
        linkId: link.linkId,
      );
      final local =
          await (_db.select(_db.documentationFilesToGeofeatures)
                ..where(
                  (t) =>
                      t.documentationFileUuid.equalsValue(documentId) &
                      t.geofeatureUuid.equalsValue(link.targetId),
                )
                ..limit(1))
              .getSingleOrNull();
      if (local != null) {
        // Already hung here, by the caver or by an earlier fetch.
        if (!held.containsKey(entry.key)) {
          await _serverLinks.record(_profileUuid, entry);
        }
        continue;
      }
      // Held there and not here: the caver took it down, and the removal
      // goes up rather than the link coming back.
      if (held.containsKey(entry.key)) continue;
      final type = await _heldFeatureType(link.targetId);
      if (type == null) continue;
      await _db
          .into(_db.documentationFilesToGeofeatures)
          .insert(
            DocumentationFilesToGeofeaturesCompanion.insert(
              uuid: Uuid.v7(),
              geofeatureType: type.dbValue,
              documentationFileUuid: documentId,
              geofeatureUuid: Value(link.targetId),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await _serverLinks.record(_profileUuid, entry);
      linked++;
    }
    return linked;
  }

  /// Which kind of local feature [id] is, or null when this device does not
  /// hold it.
  Future<GeofeatureType?> _heldFeatureType(Uuid id) async {
    if (await (_db.select(
          _db.caves,
        )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull() !=
        null) {
      return GeofeatureType.cave;
    }
    if (await (_db.select(
          _db.cavePlaces,
        )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull() !=
        null) {
      return GeofeatureType.cavePlace;
    }
    if (await (_db.select(
          _db.caveAreas,
        )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull() !=
        null) {
      return GeofeatureType.caveArea;
    }
    return null;
  }
}
