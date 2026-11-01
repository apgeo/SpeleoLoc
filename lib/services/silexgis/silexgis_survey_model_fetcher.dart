import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_file_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_copies.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// What fetching survey model files did.
class SilexgisSurveyModelFiles {
  const SilexgisSurveyModelFiles({
    this.fetched = const <Uuid>[],
    this.failed = 0,
    this.refused = 0,
  });

  /// Models whose file is here now, at the version listed.
  final List<Uuid> fetched;

  /// Fetches that broke off, or brought bytes other than the ones listed.
  /// Nothing was stored; the next run tries again.
  final int failed;

  /// Models the installation would not hand over now.
  final int refused;
}

/// Fetches the files of survey models into local copies.
///
/// Only a model of a cave this device holds is fetched, and only when its
/// file is not here at the version listed. What arrives is checked against
/// the listed size and fingerprint before it is stored. A model whose
/// document is the caver's own file is never fetched over it: it counts as
/// here when the bytes match.
class SilexgisSurveyModelFetcher {
  SilexgisSurveyModelFetcher({
    required AppDatabase db,
    required SilexgisSyncApi api,
    required SilexgisFileFetcher fetcher,
    required SilexgisDocumentFileStore store,
    required SilexgisSurveyModelRepository models,
    required SilexgisSurveyModelCopies copies,
    required String profileUuid,
  }) : _db = db,
       _api = api,
       _fetcher = fetcher,
       _store = store,
       _models = models,
       _copies = copies,
       _profileUuid = profileUuid;

  final AppDatabase _db;
  final SilexgisSyncApi _api;
  final SilexgisFileFetcher _fetcher;
  final SilexgisDocumentFileStore _store;
  final SilexgisSurveyModelRepository _models;
  final SilexgisSurveyModelCopies _copies;
  final String _profileUuid;
  final _log = AppLogger.of('SilexgisSurveyModelFetcher');

  /// Fetches every model still to fetch, or only [only] when given — the
  /// caver's own request, which also fetches a copy they deleted.
  Future<SilexgisSurveyModelFiles> fetchPending({Set<Uuid>? only}) async {
    final fetched = <Uuid>[];
    var failed = 0;
    var refused = 0;
    // The cave's current model first: it is the one most likely opened.
    final listed = (await _models.readAll(_profileUuid)).values.toList()
      ..sort(
        (a, b) => a.isCurrent == b.isCurrent
            ? (a.name ?? '').compareTo(b.name ?? '')
            : (a.isCurrent ? -1 : 1),
      );
    for (final model in listed) {
      if (only != null && !only.contains(model.modelId)) continue;
      final upToDate =
          model.fetchedVersionId != null &&
          model.fetchedVersionId == model.versionId;
      // A copy the caver deleted stays deleted, until they ask for it.
      if (upToDate &&
          (only == null || await _copies.local(model.documentId) != null)) {
        continue;
      }
      if (!await _caveIsHere(model.caveId)) continue;
      switch (await _fetchOne(model)) {
        case _Outcome.fetched:
          fetched.add(model.modelId);
        case _Outcome.failed:
          failed++;
        case _Outcome.refused:
          refused++;
        case _Outcome.skipped:
          break;
      }
    }
    return SilexgisSurveyModelFiles(
      fetched: fetched,
      failed: failed,
      refused: refused,
    );
  }

  Future<_Outcome> _fetchOne(SilexgisSurveyModelData model) async {
    final document = model.documentId;
    final local = await _copies.local(document);
    if (local != null && !await _copies.isServerCopy(document)) {
      final same =
          model.sha256 != null &&
          model.sha256!.toLowerCase() == local.fileHash?.toLowerCase();
      if (!same) return _Outcome.skipped;
      await _models.recordFetched(_profileUuid, model.modelId, model.versionId);
      return _Outcome.fetched;
    }

    final answer = await _api.fileLinks(<SyncFileLinkRequest>[
      SyncFileLinkRequest(
        documentId: document.toString(),
        rendition: SyncRendition.original,
      ),
    ]);
    final link = answer.links
        .where((l) => l.documentId == document.toString())
        .firstOrNull;
    if (link == null) {
      _log.info('a survey model file was not handed over');
      return _Outcome.refused;
    }

    final partial = await _store.partialFile(
      document.toString(),
      model.versionId,
      SyncRendition.original,
    );
    final SilexgisFetchedFile fetched;
    try {
      fetched = await _fetcher.fetch(link.url, partial);
    } on SilexgisAddressExpired {
      // A model's address lasts hours; the next run asks again.
      return _Outcome.failed;
    } on SilexgisTransportException catch (e) {
      // What arrived stays, for the next attempt to resume from.
      _log.info('a survey model fetch broke off: ${e.message}');
      return _Outcome.failed;
    }
    final sha = model.sha256?.toLowerCase();
    if ((sha != null && sha != fetched.sha256) ||
        (model.sizeBytes != null && model.sizeBytes != fetched.length)) {
      _log.warning('a survey model file is not the one listed; discarded');
      await _store.discard(partial);
      return _Outcome.failed;
    }

    final relativePath = await _store.commit(partial, _fileName(model));
    await _copies.store(
      documentUuid: document,
      caveUuid: model.caveId,
      title: _fileName(model),
      relativePath: relativePath,
      sizeBytes: fetched.length,
      sha256: fetched.sha256,
      versionId: model.versionId,
    );
    await _models.recordFetched(_profileUuid, model.modelId, model.versionId);
    return _Outcome.fetched;
  }

  /// The model's name with its format's extension, which is how the viewer
  /// tells the two formats apart.
  static String _fileName(SilexgisSurveyModelData model) {
    final extension = model.format == '3d' ? '3d' : 'lox';
    final name = (model.name ?? '').trim();
    final stem = name.isEmpty ? 'survey' : name;
    return stem.toLowerCase().endsWith('.$extension')
        ? stem
        : '$stem.$extension';
  }

  Future<bool> _caveIsHere(Uuid cave) async =>
      await (_db.select(
        _db.caves,
      )..where((t) => t.uuid.equalsValue(cave))).getSingleOrNull() !=
      null;
}

enum _Outcome { fetched, failed, refused, skipped }
