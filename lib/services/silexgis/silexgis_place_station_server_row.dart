import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_survey_models.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_row_handler.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_copies.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// The server's row of a place at a station, written by the survey-models
/// stream's applier.
class SilexgisPlaceStationServerRow implements SilexgisServerRowHandler {
  SilexgisPlaceStationServerRow({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _heldRows = heldRows,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final Clock _clock;

  @override
  Set<SyncUploadSection> get sections => const <SyncUploadSection>{
    SyncUploadSection.placeStations,
  };

  @override
  SyncStream get stream => SyncStream.surveyModels;

  @override
  Future<bool> write(
    String profileUuid,
    SilexgisHeldItem held,
    Map<String, Object?> current,
  ) async {
    final applied = await SilexgisSurveyModelApplier(
      db: _db,
      logger: _logger,
      localState: _localState,
      heldRows: _heldRows,
      models: SilexgisSurveyModelRepository(_db),
      // Only a model's removal touches files, and a mapping's row never
      // removes one.
      copies: SilexgisSurveyModelCopies(
        db: _db,
        logger: _logger,
        copies: SilexgisFileCopyRepository(_db),
        baseDir: getApplicationDocumentsDirectory,
      ),
      profileUuid: profileUuid,
      clock: _clock,
    ).applyMapping(SyncPlaceStation.fromJson(current));
    return applied.changed > 0;
  }
}
