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

/// The server's row of where a document hangs: a catalogue link, with its
/// document.
///
/// Stored as a page of the documents stream would store it. With the link in
/// the catalogue, the next upload records the local link as one the
/// installation holds instead of sending it.
class SilexgisDocumentLinkServerRow implements SilexgisServerRowHandler {
  SilexgisDocumentLinkServerRow({
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
    SyncUploadSection.documentLinks,
  };

  @override
  SyncStream get stream => SyncStream.documents;

  @override
  Future<bool> write(
    String profileUuid,
    SilexgisHeldItem held,
    Map<String, Object?> current,
  ) async {
    final applied = await _catalogue.applyPage(
      profileUuid,
      SyncDocumentsPage(
        setRevision: 0,
        links: <SyncDocumentLink>[SyncDocumentLink.fromJson(current)],
        tombstones: const <SyncDocumentTombstone>[],
        nextCursor: null,
        hasMore: false,
      ),
    );
    await SilexgisHeldDocumentUpdater(
      db: _db,
      logger: _logger,
      localState: _localState,
      profileUuid: profileUuid,
      clock: _clock,
    ).apply(applied.documents);
    return applied.links > 0;
  }
}
