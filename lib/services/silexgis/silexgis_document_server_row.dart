import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_document_updater.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_row_handler.dart';
import 'package:speleoloc/utils/clock.dart';

/// The server's row of a photo or document: the catalogue's `document`.
///
/// Metadata only, as on the documents stream: the catalogue's copy and the
/// local row's title and description follow it, and a file is never fetched
/// from here. A document the caver removed comes back to the catalogue, from
/// which they may fetch it again.
class SilexgisDocumentServerRow implements SilexgisServerRowHandler {
  SilexgisDocumentServerRow({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required SilexgisDocumentCatalogueRepository catalogue,
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _catalogue = catalogue,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final SilexgisDocumentCatalogueRepository _catalogue;
  final Clock _clock;

  @override
  Set<SyncUploadSection> get sections => const <SyncUploadSection>{
    SyncUploadSection.documents,
  };

  @override
  SyncStream get stream => SyncStream.documents;

  @override
  Future<bool> write(
    String profileUuid,
    SilexgisHeldItem held,
    Map<String, Object?> current,
  ) async {
    final document = SyncDocument.fromJson(current);
    final catalogued = await _catalogue.refreshDocument(profileUuid, document);
    if (held.isDelete) return catalogued;
    return SilexgisHeldDocumentUpdater(
      db: _db,
      logger: _logger,
      localState: _localState,
      profileUuid: profileUuid,
      clock: _clock,
    ).follow(document);
  }
}
