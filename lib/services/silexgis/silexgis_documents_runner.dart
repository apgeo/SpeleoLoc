import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_linker.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_document_updater.dart';
import 'package:speleoloc/services/silexgis/silexgis_link_removal_follower.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_paged_stream_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';

/// What reading the documents catalogue did.
class SilexgisDocumentsReport {
  const SilexgisDocumentsReport({
    required this.pages,
    required this.restarted,
    this.links = 0,
    this.removed = 0,
    this.renamed = 0,
    this.linked = 0,
    this.unlinked = 0,
  });

  final int pages;
  final bool restarted;

  /// Catalogue links stored or replaced.
  final int links;

  /// Catalogue links a tombstone removed.
  final int removed;

  /// Fetched documents whose title or description followed the server's.
  final int renamed;

  /// Links made from fetched documents to features this device came to hold.
  final int linked;

  /// Local links taken down because the installation took them down.
  final int unlinked;
}

/// Reads the photo and document catalogue on the documents stream's own
/// cursor into the local-only catalogue. Nothing is fetched: a caver chooses
/// what to carry, and the catalogue is what they choose from.
class SilexgisDocumentsRunner {
  SilexgisDocumentsRunner({
    required AppDatabase db,
    required SilexgisSyncApi api,
    required SilexgisLocalStateRepository localState,
    required SilexgisDocumentCatalogueRepository catalogue,
    required SilexgisHeldDocumentUpdater heldDocuments,
    required SilexgisDocumentLinker linker,
    required SilexgisLinkRemovalFollower removals,
    required String profileUuid,
  }) : _db = db,
       _api = api,
       _localState = localState,
       _catalogue = catalogue,
       _heldDocuments = heldDocuments,
       _linker = linker,
       _removals = removals,
       _profileUuid = profileUuid;

  final AppDatabase _db;
  final SilexgisSyncApi _api;
  final SilexgisLocalStateRepository _localState;
  final SilexgisDocumentCatalogueRepository _catalogue;
  final SilexgisHeldDocumentUpdater _heldDocuments;
  final SilexgisDocumentLinker _linker;
  final SilexgisLinkRemovalFollower _removals;
  final String _profileUuid;

  static const int preferredPageSize = 200;

  Future<SilexgisDocumentsReport> run(
    String setId, {
    required SilexgisCapabilities capabilities,
    bool fromBeginning = false,
  }) async {
    final pageSize = capabilities.pageSizeMax < preferredPageSize
        ? capabilities.pageSizeMax
        : preferredPageSize;
    final cursors = SilexgisStreamCursorStore(
      localState: _localState,
      profileUuid: _profileUuid,
      setId: setId,
      stream: SyncStream.documents,
    );

    var links = 0;
    var removed = 0;
    var renamed = 0;
    var unlinked = 0;
    final read = await SilexgisPagedStreamRunner<SyncDocumentsPage>(
      name: 'documents',
      cursors: cursors,
      fetch: (cursor) => _api.documents(
        setId,
        cursor: cursor,
        pageSize: pageSize > 0 ? pageSize : null,
      ),
      apply: (page) => _db.transaction(() async {
        final applied = await _catalogue.applyPage(_profileUuid, page);
        links += applied.links;
        removed += applied.removed;
        renamed += await _heldDocuments.apply(applied.documents);
        unlinked += await _removals.follow(
          applied.tombstonedLinkIds,
          applied.removedLinks,
        );
        await cursors.write(page);
      }),
    ).run(fromBeginning: fromBeginning);

    // After the read, and so after this run's feature download too: a file
    // fetched before its feature arrived is hung on it now.
    final linked = await _linker.linkFetched();

    return SilexgisDocumentsReport(
      pages: read.pages,
      restarted: read.restarted,
      links: links,
      removed: removed,
      renamed: renamed,
      linked: linked,
      unlinked: unlinked,
    );
  }
}
