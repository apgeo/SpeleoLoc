import 'dart:io';

import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_file_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_importer.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_fetched_copy.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// One file the caver asked for.
class SilexgisDownloadRequest {
  const SilexgisDownloadRequest({
    required this.documentId,
    required this.rendition,
  });

  final Uuid documentId;
  final SyncRendition rendition;
}

/// What became of one request.
enum SilexgisDownloadOutcome {
  /// Stored as a new documentation file.
  downloaded,

  /// The device already holds this file — under the document's identifier,
  /// or with the same bytes. Nothing was fetched and nothing replaced.
  alreadyHeld,

  /// Not in the catalogue, or not in the form asked for.
  notOffered,

  /// The installation no longer hands this document to this account. It is
  /// gone from the catalogue copy until a read lists it again.
  unavailable,

  /// Neither the file itself nor a picture of it is handed to this account.
  withheld,

  /// The fetch failed, or what arrived was not what was described. Nothing was
  /// stored.
  failed,
}

class SilexgisDownloadResult {
  const SilexgisDownloadResult({
    required this.documentId,
    required this.outcome,
    this.rendition,
    this.detail,
  });

  final Uuid documentId;
  final SilexgisDownloadOutcome outcome;

  /// The form actually stored, which may be another than the one asked for
  /// when the installation offered only that.
  final SyncRendition? rendition;
  final String? detail;
}

/// Fetches files the caver chose from the catalogue, and stores each as a
/// documentation file of its own.
///
/// **A file the server hands down never replaces the device's own copy**: a
/// document the device already holds, by identifier or by bytes, is not
/// fetched at all, and a fetched file is always written under a new name.
class SilexgisDocumentDownloader {
  SilexgisDocumentDownloader({
    required AppDatabase db,
    required SilexgisSyncApi api,
    required SilexgisFileFetcher fetcher,
    required SilexgisDocumentFileStore store,
    required SilexgisDocumentCatalogueRepository catalogue,
    required SilexgisDocumentImporter importer,
    required String profileUuid,
  }) : _db = db,
       _api = api,
       _fetcher = fetcher,
       _store = store,
       _catalogue = catalogue,
       _importer = importer,
       _profileUuid = profileUuid;

  final AppDatabase _db;
  final SilexgisSyncApi _api;
  final SilexgisFileFetcher _fetcher;
  final SilexgisDocumentFileStore _store;
  final SilexgisDocumentCatalogueRepository _catalogue;
  final SilexgisDocumentImporter _importer;
  final String _profileUuid;
  final _log = AppLogger.of('SilexgisDocumentDownloader');

  /// How many times an expired address is asked for again within one fetch.
  static const int maxAddressRenewals = 2;

  Future<List<SilexgisDownloadResult>> download(
    List<SilexgisDownloadRequest> requests, {
    void Function(int done, int total)? onProgress,
  }) async {
    final results = <SilexgisDownloadResult>[];
    final wanted = <Uuid, _Wanted>{};
    final asked = <Uuid>{};
    for (final request in requests) {
      // One local file per document: its identifier is the row's.
      if (!asked.add(request.documentId)) continue;
      final refusal = await _refuseBeforeFetching(request);
      if (refusal != null) {
        results.add(refusal);
        continue;
      }
      final document = (await _catalogue.document(
        _profileUuid,
        request.documentId,
      ))!;
      wanted[request.documentId] = _Wanted(document, request.rendition);
    }

    final addresses = await _askAddresses(wanted, results);
    var done = 0;
    onProgress?.call(done, addresses.length);
    for (final entry in addresses.entries) {
      results.add(await _fetchOne(wanted[entry.key]!, entry.value));
      onProgress?.call(++done, addresses.length);
    }
    return results;
  }

  /// Rule 13 and the catalogue, checked before anything goes over the wire.
  Future<SilexgisDownloadResult?> _refuseBeforeFetching(
    SilexgisDownloadRequest request,
  ) async {
    final id = request.documentId;
    final document = await _catalogue.document(_profileUuid, id);
    if (document == null) {
      return SilexgisDownloadResult(
        documentId: id,
        outcome: SilexgisDownloadOutcome.notOffered,
      );
    }
    if (await _holds(id, _storedHashOf(document))) {
      return SilexgisDownloadResult(
        documentId: id,
        outcome: SilexgisDownloadOutcome.alreadyHeld,
      );
    }
    if (!SilexgisCatalogueEntry.offeredFor(
      document,
    ).contains(request.rendition)) {
      return SilexgisDownloadResult(
        documentId: id,
        outcome: SilexgisDownloadOutcome.notOffered,
        rendition: request.rendition,
      );
    }
    return null;
  }

  /// The stored file's hash, when fetching it hands over exactly those bytes.
  static String? _storedHashOf(SilexgisDocumentData document) =>
      SyncDocumentReach.parse(document.reach) == SyncDocumentReach.original
      ? document.sha256
      : null;

  /// Whether the device holds this document, or a file with [sha256].
  Future<bool> _holds(Uuid id, String? sha256) async {
    final byId = await (_db.select(
      _db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();
    if (byId != null) return true;
    if (sha256 == null) return false;
    final byHash =
        await (_db.select(_db.documentationFiles)
              ..where((t) => t.fileHash.equals(sha256.toLowerCase()))
              ..limit(1))
            .getSingleOrNull();
    return byHash != null;
  }

  /// Asks for an address per wanted file, at most
  /// [SyncFileLinksAnswer.maxItems] to a request. A refused item is asked for
  /// once more in its other form where the catalogue offers one, as the
  /// refusal's action says; a second refusal stands.
  Future<Map<Uuid, SyncFileLink>> _askAddresses(
    Map<Uuid, _Wanted> wanted,
    List<SilexgisDownloadResult> results,
  ) async {
    final addresses = <Uuid, SyncFileLink>{};
    var round = <Uuid>[...wanted.keys];
    for (var attempt = 0; attempt < 2 && round.isNotEmpty; attempt++) {
      final retry = <Uuid>[];
      final answer = await _ask(<SyncFileLinkRequest>[
        for (final id in round)
          SyncFileLinkRequest(
            documentId: id.toString(),
            rendition: wanted[id]!.rendition,
          ),
      ]);
      for (final link in answer.links) {
        final id = Uuid.tryParse(link.documentId);
        if (id != null && wanted.containsKey(id)) addresses[id] = link;
      }
      for (final refused in answer.refused) {
        final id = Uuid.tryParse(refused.documentId);
        final want = id == null ? null : wanted[id];
        if (id == null || want == null) continue;
        final instead = attempt == 0 ? _otherForm(refused, want) : null;
        if (instead != null) {
          want.rendition = instead;
          retry.add(id);
          continue;
        }
        results.add(await _refused(id, refused));
      }
      round = retry;
    }
    return addresses;
  }

  /// The form to ask for instead of a refused one, or null when there is
  /// none.
  SyncRendition? _otherForm(SyncFileLinkRefusal refused, _Wanted want) {
    if (refused.action != SilexgisAction.applyAndResubmit) return null;
    final offered = SilexgisCatalogueEntry.offeredFor(want.document);
    switch (refused.code) {
      case SilexgisCodes.originalWithheld:
        final pictures = offered.where((r) => !r.isOriginal);
        return pictures.isEmpty ? null : pictures.first;
      case SilexgisCodes.renditionUnavailable:
        return offered.contains(SyncRendition.original)
            ? SyncRendition.original
            : null;
    }
    return null;
  }

  Future<SilexgisDownloadResult> _refused(
    Uuid id,
    SyncFileLinkRefusal refused,
  ) async {
    if (refused.code == SilexgisCodes.documentUnavailable) {
      await _catalogue.removeDocument(_profileUuid, id);
      return SilexgisDownloadResult(
        documentId: id,
        outcome: SilexgisDownloadOutcome.unavailable,
        detail: refused.code,
      );
    }
    return SilexgisDownloadResult(
      documentId: id,
      outcome: SilexgisDownloadOutcome.withheld,
      detail: refused.code,
    );
  }

  Future<SyncFileLinksAnswer> _ask(List<SyncFileLinkRequest> items) async {
    final links = <SyncFileLink>[];
    final refused = <SyncFileLinkRefusal>[];
    for (var i = 0; i < items.length; i += SyncFileLinksAnswer.maxItems) {
      final end = i + SyncFileLinksAnswer.maxItems < items.length
          ? i + SyncFileLinksAnswer.maxItems
          : items.length;
      final answer = await _api.fileLinks(items.sublist(i, end));
      links.addAll(answer.links);
      refused.addAll(answer.refused);
    }
    return SyncFileLinksAnswer(links: links, refused: refused);
  }

  Future<SilexgisDownloadResult> _fetchOne(
    _Wanted want,
    SyncFileLink first,
  ) async {
    final document = want.document;
    final id = document.documentId;
    final rendition = want.rendition;
    final partial = await _store.partialFile(
      id.toString(),
      document.versionId,
      rendition,
    );

    var link = first;
    SilexgisFetchedFile? fetched;
    for (var renewals = 0; fetched == null; renewals++) {
      try {
        // Only the file itself is worth resuming: its address lasts hours,
        // a picture's minutes, and a picture is small.
        fetched = await _fetcher.fetch(
          link.url,
          partial,
          resumable: rendition.isOriginal,
        );
      } on SilexgisAddressExpired {
        if (renewals >= maxAddressRenewals) {
          return _failed(id, partial, 'the address kept expiring');
        }
        final again = await _api.fileLinks(<SyncFileLinkRequest>[
          SyncFileLinkRequest(documentId: id.toString(), rendition: rendition),
        ]);
        if (again.links.isEmpty) {
          await _store.discard(partial);
          final refused = again.refused.isEmpty ? null : again.refused.first;
          if (refused == null) {
            return _failed(id, partial, 'no address was given');
          }
          return _refused(id, refused);
        }
        link = again.links.first;
      } on SilexgisTransportException catch (e) {
        // What arrived stays, for the next attempt to resume from.
        return SilexgisDownloadResult(
          documentId: id,
          outcome: SilexgisDownloadOutcome.failed,
          rendition: rendition,
          detail: e.message,
        );
      }
    }

    final heldAs = SilexgisFetchedCopy.heldAs(document, link);
    final mismatch = SilexgisFetchedCopy.mismatch(
      document,
      link,
      heldAs,
      fetched,
    );
    if (mismatch != null) return _failed(id, partial, mismatch);

    // Checked again on what arrived: the device may have come to hold the
    // file since, or hold these very bytes under another document.
    if (await _holds(id, fetched.sha256)) {
      await _store.discard(partial);
      return SilexgisDownloadResult(
        documentId: id,
        outcome: SilexgisDownloadOutcome.alreadyHeld,
      );
    }

    final fileName = SilexgisDocumentFileStore.fileNameFor(
      title: document.title,
      mimeType: rendition.isOriginal
          ? document.mimeType
          : fetched.contentType ?? document.mimeType,
      rendition: rendition,
    );
    final relativePath = await _store.commit(partial, fileName);
    await _importer.import(
      SilexgisFetchedDocument(
        document: document,
        links: await _catalogue.linksOf(_profileUuid, id),
        relativePath: relativePath,
        sizeBytes: fetched.length,
        sha256: fetched.sha256,
        heldAs: heldAs,
        rendition: rendition.size,
        revision: document.updatedAt ?? document.versionId ?? '',
      ),
    );
    return SilexgisDownloadResult(
      documentId: id,
      outcome: SilexgisDownloadOutcome.downloaded,
      rendition: rendition,
    );
  }

  Future<SilexgisDownloadResult> _failed(
    Uuid id,
    File partial,
    String detail,
  ) async {
    _log.warning('a fetched file was not stored: $detail');
    await _store.discard(partial);
    return SilexgisDownloadResult(
      documentId: id,
      outcome: SilexgisDownloadOutcome.failed,
      detail: detail,
    );
  }
}

class _Wanted {
  _Wanted(this.document, this.rendition);

  final SilexgisDocumentData document;
  SyncRendition rendition;
}
