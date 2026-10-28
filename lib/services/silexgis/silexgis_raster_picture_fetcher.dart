import 'dart:io';

import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_file_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_fetched_copy.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/image_format_sniffer.dart';

/// What fetching the map pictures did.
class SilexgisMapPicturesReport {
  const SilexgisMapPicturesReport({this.fetched = 0, this.notFetched = 0});

  final int fetched;

  /// Pictures the installation did not hand over, or that did not arrive
  /// whole. Their maps stay without a picture, and the next run asks again.
  final int notFetched;
}

/// Fetches the pictures of maps read from the rasters stream, outside the
/// page's transaction.
///
/// A map's picture is a document of the documents stream, fetched through the
/// file-address route like any photograph: the file itself where the reach
/// hands it over — the copy without location data when that is what this
/// account gets — or else the largest picture the server draws. It is stored
/// as `cave_<cave>/raster_<document>.<extension>`, the extension read from the
/// catalogue's type, else from what arrived; recorded in the copy register,
/// so what it is a copy of is known; and recorded as the local picture that
/// stands for the installation's, so it never goes back up as new bytes. It
/// is never made a documentation file: the picture belongs to its map.
///
/// A picture is fetched when the map has none yet, or when the catalogue names
/// a newer revision than the one held and the caver has not changed the map
/// since. A picture this device sent is taken to be the revision the
/// catalogue names when it first names one.
class SilexgisRasterPictureFetcher {
  SilexgisRasterPictureFetcher({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisSyncApi api,
    required SilexgisFileFetcher fetcher,
    required SilexgisLocalStateRepository localState,
    required SilexgisDocumentCatalogueRepository catalogue,
    required SilexgisFileCopyRepository copies,
    required SilexgisRasterStateRepository rasters,
    required Future<Directory> Function() baseDir,
    required String profileUuid,
  }) : _db = db,
       _logger = logger,
       _api = api,
       _fetcher = fetcher,
       _localState = localState,
       _catalogue = catalogue,
       _copies = copies,
       _rasters = rasters,
       _baseDir = baseDir,
       _profileUuid = profileUuid;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisSyncApi _api;
  final SilexgisFileFetcher _fetcher;
  final SilexgisLocalStateRepository _localState;
  final SilexgisDocumentCatalogueRepository _catalogue;
  final SilexgisFileCopyRepository _copies;
  final SilexgisRasterStateRepository _rasters;
  final Future<Directory> Function() _baseDir;
  final String _profileUuid;
  final _log = AppLogger.of('SilexgisRasterPictureFetcher');

  /// The picture asked for when the catalogue does not describe the document
  /// and the file itself is withheld.
  static const int fallbackPicture = 2400;

  Future<SilexgisMapPicturesReport> fetchPending() async {
    final revisions = await _localState.readRevisions(_profileUuid);
    var fetched = 0;
    var notFetched = 0;
    for (final state in (await _rasters.readAll(_profileUuid)).values) {
      final documentId = state.documentId;
      if (state.isPin || documentId == null) continue;
      final map = await (_db.select(
        _db.rasterMaps,
      )..where((t) => t.uuid.equalsValue(state.entityUuid))).getSingleOrNull();
      if (map == null) continue;
      final document = await _catalogue.document(_profileUuid, documentId);
      final version = document?.versionId;

      if (state.pictureSha256 != null) {
        if (version == null || version == state.pictureVersion) continue;
        if (state.pictureVersion == null) {
          // Bytes this device sent: the revision the catalogue names first.
          await _rasters.recordPicture(
            _profileUuid,
            map.uuid,
            sha256: state.pictureSha256!,
            version: version,
          );
          continue;
        }
        // A newer picture there, unless the caver changed the map here since:
        // their picture is the one to send, not to replace.
        final agreed = revisions[map.uuid];
        if (agreed == null ||
            !agreed.agreesWith(map.updatedAt) ||
            map.fileHash != state.pictureSha256) {
          continue;
        }
      }

      if (await _fetch(map, documentId, document)) {
        fetched++;
      } else {
        notFetched++;
      }
    }
    return SilexgisMapPicturesReport(fetched: fetched, notFetched: notFetched);
  }

  /// Fetches and stores one map's picture; false when it could not be had.
  Future<bool> _fetch(
    RasterMap map,
    Uuid documentId,
    SilexgisDocumentData? document,
  ) async {
    final rendition = _wanted(document);
    if (rendition == null) {
      _log.info('a map picture is not handed to this account in any form');
      return false;
    }
    final SyncFileLink? link;
    try {
      link = await _address(documentId, rendition, document == null);
    } on SilexgisException catch (e) {
      // One picture's address is not the run's: the maps are stored, and the
      // next run asks again.
      _log.info('no address for a map picture: ${e.message}');
      return false;
    }
    if (link == null) return false;

    final base = await _baseDir();
    final folder = Directory('${base.path}/cave_${map.caveUuid}');
    final partial = File('${folder.path}/.raster_$documentId.part');
    SilexgisFetchedFile arrived;
    try {
      arrived = await _fetchFrom(link, partial);
    } on SilexgisException catch (e) {
      // What arrived stays, for the next run to resume from.
      _log.info('a map picture did not arrive: ${e.message}');
      return false;
    } on SilexgisAddressExpired {
      return false;
    }

    final heldAs = SilexgisFetchedCopy.heldAs(document, link);
    final mismatch = SilexgisFetchedCopy.mismatch(
      document,
      link,
      heldAs,
      arrived,
    );
    if (mismatch != null) {
      _log.warning('a fetched map picture was not stored: $mismatch');
      if (await partial.exists()) await partial.delete();
      return false;
    }

    final extension = await _extension(
      link.rendition.isOriginal ? document?.mimeType : null,
      arrived.contentType,
      partial,
    );
    final relative = SilexgisRasterApplier.picturePath(
      map.caveUuid,
      documentId,
      extension,
    );
    final collides =
        relative != map.fileName &&
        await (_db.select(_db.rasterMaps)
                  ..where(
                    (t) =>
                        t.uuid.equalsValue(map.uuid).not() &
                        t.caveUuid.equalsValue(map.caveUuid) &
                        t.mapType.equals(map.mapType) &
                        t.fileName.equals(relative),
                  )
                  ..limit(1))
                .getSingleOrNull() !=
            null;
    if (collides) {
      _log.warning('a map picture would take another map\'s file name');
      await partial.delete();
      return false;
    }
    await partial.rename('${base.path}/$relative');
    if (relative != map.fileName && _isFetchedName(map, documentId)) {
      // The name given before the picture said what it is.
      final earlier = File('${base.path}/${map.fileName}');
      if (await earlier.exists()) await earlier.delete();
    }

    // The map's own stamp stays: the picture is the installation's, and the
    // map agrees with it as it did before.
    await _logger.runSuspended(() async {
      await (_db.update(
        _db.rasterMaps,
      )..where((t) => t.uuid.equalsValue(map.uuid))).write(
        RasterMapsCompanion(
          fileName: Value(relative),
          fileHash: Value(arrived.sha256),
          fileSize: Value(arrived.length),
        ),
      );
    });
    await _copies.register(
      SilexgisFileCopyEntry(
        documentUuid: documentId,
        heldAs: heldAs,
        origin: SilexgisCopyOrigin.server,
        versionId: document?.versionId,
        rendition: link.rendition.size,
      ),
    );
    await _rasters.recordPicture(
      _profileUuid,
      map.uuid,
      sha256: arrived.sha256,
      version: document?.versionId,
    );
    return true;
  }

  /// The file itself where the reach hands it over, else the largest picture
  /// the server draws; with no catalogue entry, the file itself is asked for.
  static SyncRendition? _wanted(SilexgisDocumentData? document) {
    if (document == null) return SyncRendition.original;
    final offered = SilexgisCatalogueEntry.offeredFor(document);
    return offered.isEmpty ? null : offered.first;
  }

  /// An address for [rendition], or for the largest picture when the file
  /// itself is withheld from a document the catalogue does not describe.
  Future<SyncFileLink?> _address(
    Uuid documentId,
    SyncRendition rendition,
    bool mayFallBack,
  ) async {
    var asked = rendition;
    for (var attempt = 0; attempt < 2; attempt++) {
      final answer = await _api.fileLinks(<SyncFileLinkRequest>[
        SyncFileLinkRequest(
          documentId: documentId.toString(),
          rendition: asked,
        ),
      ]);
      if (answer.links.isNotEmpty) return answer.links.first;
      final code = answer.refused.isEmpty ? null : answer.refused.first.code;
      if (mayFallBack &&
          asked.isOriginal &&
          code == SilexgisCodes.originalWithheld) {
        asked = SyncRendition.picture(fallbackPicture);
        continue;
      }
      _log.info('a map picture was refused: $code');
      return null;
    }
    return null;
  }

  /// Fetches [link] into [partial], asking for a new address once when it
  /// expired on the way.
  Future<SilexgisFetchedFile> _fetchFrom(
    SyncFileLink link,
    File partial,
  ) async {
    final resumable = link.rendition.isOriginal;
    try {
      return await _fetcher.fetch(link.url, partial, resumable: resumable);
    } on SilexgisAddressExpired {
      final again = await _api.fileLinks(<SyncFileLinkRequest>[
        SyncFileLinkRequest(
          documentId: link.documentId,
          rendition: link.rendition,
        ),
      ]);
      if (again.links.isEmpty) rethrow;
      return _fetcher.fetch(
        again.links.first.url,
        partial,
        resumable: resumable,
      );
    }
  }

  /// The extension for what arrived: the catalogue's type, the response's,
  /// the bytes themselves, or the applier's default.
  static Future<String> _extension(
    String? catalogueType,
    String? responseType,
    File file,
  ) async {
    final named =
        SilexgisDocumentFileStore.extensionFor(catalogueType) ??
        SilexgisDocumentFileStore.extensionFor(responseType);
    if (named != null) return named;
    final head = await file
        .openRead(0, 16)
        .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
    return ImageFormatSniffer.extensionFor(Uint8List.fromList(head)) ??
        SilexgisRasterApplier.defaultExtension;
  }

  /// Whether the map's file name is one this fetcher gives — so the file
  /// behind it is the installation's copy, never a picture the caver picked.
  static bool _isFetchedName(RasterMap map, Uuid documentId) =>
      map.fileName.startsWith('cave_${map.caveUuid}/raster_$documentId.');
}
