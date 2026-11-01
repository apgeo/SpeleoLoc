import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_survey_models.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_paged_stream_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';

/// What reading the survey-models stream did.
class SilexgisSurveyModelsReport {
  const SilexgisSurveyModelsReport({
    required this.pages,
    required this.restarted,
    this.applied = const SilexgisSurveyModelsApplied(),
    this.files = const SilexgisSurveyModelFiles(),
  });

  final int pages;
  final bool restarted;
  final SilexgisSurveyModelsApplied applied;
  final SilexgisSurveyModelFiles files;
}

/// Reads the survey models, with their places at stations, on the stream's
/// own cursor, then fetches the files still to fetch. Run after the features,
/// so a model finds its cave and a mapping its place, and after the documents
/// catalogue, whose fetched survey files a mapping may name.
///
/// - A read from the beginning lists every model the account may hold now,
///   so the models it did not list are dropped: a change to the account's own
///   rights is never told as a tombstone.
/// - A mapping arrives only while its survey's file is here, so a run that
///   fetched a model's file for the first time reads the stream once more
///   from the beginning to bring that model's mappings.
class SilexgisSurveyModelsRunner {
  SilexgisSurveyModelsRunner({
    required SilexgisSyncApi api,
    required SilexgisLocalStateRepository localState,
    required SilexgisSurveyModelApplier applier,
    required SilexgisSurveyModelRepository models,
    required String profileUuid,
    SilexgisSurveyModelFetcher? fetcher,
  }) : _api = api,
       _localState = localState,
       _applier = applier,
       _models = models,
       _profileUuid = profileUuid,
       _fetcher = fetcher;

  final SilexgisSyncApi _api;
  final SilexgisLocalStateRepository _localState;
  final SilexgisSurveyModelApplier _applier;
  final SilexgisSurveyModelRepository _models;
  final String _profileUuid;

  /// Null when files are not fetched this run: the models are listed, and
  /// their files wait for a run that may fetch them or for the caver.
  final SilexgisSurveyModelFetcher? _fetcher;

  static const int preferredPageSize = 100;

  Future<SilexgisSurveyModelsReport> run(
    String setId, {
    required SilexgisCapabilities capabilities,
    bool fromBeginning = false,
  }) async {
    final cursors = SilexgisStreamCursorStore(
      localState: _localState,
      profileUuid: _profileUuid,
      setId: setId,
      stream: SyncStream.surveyModels,
    );
    var report = await _read(
      setId,
      cursors,
      capabilities: capabilities,
      fromBeginning: fromBeginning,
    );
    final files = await _fetcher?.fetchPending();
    if (files == null) return report;
    if (files.fetched.isNotEmpty) {
      final again = await _read(
        setId,
        cursors,
        capabilities: capabilities,
        fromBeginning: true,
      );
      report = SilexgisSurveyModelsReport(
        pages: report.pages + again.pages,
        restarted: report.restarted,
        applied: report.applied.plus(again.applied),
      );
    }
    return SilexgisSurveyModelsReport(
      pages: report.pages,
      restarted: report.restarted,
      applied: report.applied,
      files: files,
    );
  }

  Future<SilexgisSurveyModelsReport> _read(
    String setId,
    SilexgisStreamCursorStore cursors, {
    required SilexgisCapabilities capabilities,
    required bool fromBeginning,
  }) async {
    final pageSize = capabilities.pageSizeMax < preferredPageSize
        ? capabilities.pageSizeMax
        : preferredPageSize;
    final full = fromBeginning || await cursors.read() == null;
    final listed = <Uuid>{};

    var applied = const SilexgisSurveyModelsApplied();
    final read = await SilexgisPagedStreamRunner<SyncSurveyModelsPage>(
      name: 'survey models',
      cursors: cursors,
      fetch: (cursor) => _api.surveyModels(
        setId,
        cursor: cursor,
        pageSize: pageSize > 0 ? pageSize : null,
      ),
      apply: (page) async {
        listed.addAll(<Uuid>[
          for (final m in page.models) ?Uuid.tryParse(m.id),
        ]);
        applied = applied.plus(
          await _applier.applyPage(page, afterwards: () => cursors.write(page)),
        );
      },
    ).run(fromBeginning: fromBeginning);

    if (full || read.restarted) {
      final unlisted = <Uuid>[
        for (final id in (await _models.readAll(_profileUuid)).keys)
          if (!listed.contains(id)) id,
      ];
      applied = applied.plus(await _applier.removeModels(unlisted));
    }
    return SilexgisSurveyModelsReport(
      pages: read.pages,
      restarted: read.restarted,
      applied: applied,
    );
  }
}
