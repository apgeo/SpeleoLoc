import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_row_handler.dart';

/// The server's row of a cave, area or place: a feature of the feature
/// download, written by the download's applier with change logging
/// suspended.
class SilexgisFeatureServerRow implements SilexgisServerRowHandler {
  SilexgisFeatureServerRow({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required ICaveRepository caves,
    required ICavePlaceRepository places,
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _heldRows = heldRows,
       _caves = caves,
       _places = places;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final ICaveRepository _caves;
  final ICavePlaceRepository _places;

  @override
  Set<SyncUploadSection> get sections => const <SyncUploadSection>{
    SyncUploadSection.rows,
  };

  @override
  SyncStream? get stream => null;

  /// A row whose container is not on this device waits for the download, so
  /// it is not in place.
  @override
  Future<bool> write(
    String profileUuid,
    SilexgisHeldItem held,
    Map<String, Object?> current,
  ) async {
    final report = await SilexgisDownloadApplier(
      db: _db,
      logger: _logger,
      localState: _localState,
      heldRows: _heldRows,
      caves: _caves,
      places: _places,
      profileUuid: profileUuid,
    ).applyRows(<SyncFeatureRow>[SyncFeatureRow.fromJson(current)]);
    return report.inserted + report.updated > 0;
  }
}
