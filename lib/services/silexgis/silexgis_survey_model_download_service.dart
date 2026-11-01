import 'dart:io';

import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/current_survey_models.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_file_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_session.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_copies.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_repository.dart';

/// Fetches one server model's file when the caver asks for it, outside a
/// sync run.
///
/// Its places at stations came while its file was not here, so they were
/// left on the server; the stream's position is dropped, and the next run
/// reads it from the beginning and brings them.
class SilexgisSurveyModelDownloadService implements ServerSurveyModelFetcher {
  SilexgisSurveyModelDownloadService({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisProfileRepository profiles,
    required SilexgisLocalStateRepository localState,
    required SilexgisSurveyModelRepository models,
    required SilexgisFileCopyRepository copies,
    required SilexgisSessionBuilder sessionBuilder,
    required Future<Directory> Function() baseDir,
  }) : _db = db,
       _logger = logger,
       _profiles = profiles,
       _localState = localState,
       _models = models,
       _copies = copies,
       _sessionBuilder = sessionBuilder,
       _baseDir = baseDir;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisProfileRepository _profiles;
  final SilexgisLocalStateRepository _localState;
  final SilexgisSurveyModelRepository _models;
  final SilexgisFileCopyRepository _copies;
  final SilexgisSessionBuilder _sessionBuilder;
  final Future<Directory> Function() _baseDir;

  @override
  Future<ServerModelFetchOutcome> fetch(ServerSurveyModel model) async {
    final profile = await _profiles.find(model.profileUuid);
    if (profile == null) return ServerModelFetchOutcome.refused;
    final session = _sessionBuilder(profile);
    if (!await session.auth.restore()) return ServerModelFetchOutcome.signIn;

    final files = await SilexgisSurveyModelFetcher(
      db: _db,
      api: session.api,
      fetcher: session.files ?? SilexgisFileFetcher(baseUri: profile.baseUri),
      store: SilexgisDocumentFileStore(baseDir: _baseDir),
      models: _models,
      copies: SilexgisSurveyModelCopies(
        db: _db,
        logger: _logger,
        copies: _copies,
        baseDir: _baseDir,
      ),
      profileUuid: profile.profileUuid,
    ).fetchPending(only: <Uuid>{model.modelId});
    if (files.fetched.isNotEmpty) {
      if (profile.syncSetId case final setId?) {
        await _localState.dropStreamCursor(
          profile.profileUuid,
          setId,
          SyncStream.surveyModels,
        );
      }
      return ServerModelFetchOutcome.fetched;
    }
    return files.refused > 0
        ? ServerModelFetchOutcome.refused
        : ServerModelFetchOutcome.failed;
  }
}
