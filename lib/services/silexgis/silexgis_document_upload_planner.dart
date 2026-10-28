import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_document_updater.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_staged_upload_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';

/// A documentation file this run has something to say about.
class SilexgisPlannedDocument {
  const SilexgisPlannedDocument({
    required this.id,
    this.row,
    this.stored,
    this.copy,
    this.catalogued,
    this.sendsBytes = false,
  });

  final Uuid id;

  /// The local row, or null for a removal.
  final DocumentationFile? row;

  /// What the two sides last agreed about it, or null for a new document.
  final StoredRevision? stored;

  /// What the file is a copy of, or null for the caver's own.
  final SilexgisFileCopyEntry? copy;

  /// The installation's catalogue entry for it, when it lists one.
  final SilexgisDocumentData? catalogued;

  /// Whether this row brings new content, whose bytes are staged first.
  final bool sendsBytes;

  bool get isDelete => row == null;
  bool get isNew => stored == null;
  SilexgisHeldAs get heldAs => copy?.heldAs ?? SilexgisHeldAs.own;

  /// The revision of the bytes the phone holds, when it is known.
  String? get baseVersionId => copy?.versionId ?? catalogued?.versionId;
}

/// A link this run hangs or takes down.
class SilexgisPlannedLink {
  const SilexgisPlannedLink({
    required this.documentId,
    required this.targetKind,
    required this.targetId,
    this.local,
  });

  final Uuid documentId;
  final String targetKind;
  final Uuid targetId;

  /// The local link row, or null for a removal.
  final DocumentationFilesToGeofeature? local;

  bool get isDelete => local == null;
  SilexgisLinkKey get key => (documentId, targetId);
}

/// What one run's two document sections carry.
class SilexgisDocumentPlan {
  const SilexgisDocumentPlan({
    this.documents = const <SilexgisPlannedDocument>[],
    this.links = const <SilexgisPlannedLink>[],
  });

  final List<SilexgisPlannedDocument> documents;
  final List<SilexgisPlannedLink> links;
}

/// Chooses which documentation files and links go up, by the same rule the
/// feature rows follow: what the installation already holds, plus what hangs
/// on something it holds or this run sends.
///
/// - A file goes up new when one of its links targets such a feature, and
///   only when it is the caver's own or the server's stored file: a copy
///   without location or a drawn picture is never offered upward as if it
///   were the original.
/// - A file the installation holds goes up when it was edited here since the
///   two sides last agreed. It brings bytes only when its content is not what
///   the installation holds — and never for such a copy, whose edit says only
///   what is said about the file.
/// - A file removed here goes up as a removal.
/// - A link goes up when its document goes or is held there and its target
///   is such a feature; a link the installation holds and this device no
///   longer has goes up as a removal.
///
/// Rows held for a reviewer are not sent again until the caver edits them.
class SilexgisDocumentUploadPlanner {
  SilexgisDocumentUploadPlanner({
    required AppDatabase db,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisFileCopyRepository copies,
    required SilexgisStagedUploadRepository staged,
    required SilexgisDocumentCatalogueRepository catalogue,
    required SilexgisServerLinkRepository serverLinks,
    required String profileUuid,
  }) : _db = db,
       _localState = localState,
       _heldRows = heldRows,
       _copies = copies,
       _staged = staged,
       _catalogue = catalogue,
       _serverLinks = serverLinks,
       _profileUuid = profileUuid;

  final AppDatabase _db;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisFileCopyRepository _copies;
  final SilexgisStagedUploadRepository _staged;
  final SilexgisDocumentCatalogueRepository _catalogue;
  final SilexgisServerLinkRepository _serverLinks;
  final String _profileUuid;

  static const String linkTable = 'documentation_files_to_geofeatures';

  /// The local tables whose rows are features on the server.
  static const Set<String> featureTables = <String>{
    'surface_areas',
    'caves',
    'cave_areas',
    'cave_places',
  };

  Future<SilexgisDocumentPlan> plan(SilexgisUploadContext context) async {
    final revisions = await _localState.readRevisions(_profileUuid);
    final features = <Uuid>{
      for (final e in revisions.entries)
        if (featureTables.contains(e.value.entityTable)) e.key,
      ...context.rowsSent,
    };
    final heldDocuments = await _heldRows.readSection(
      _profileUuid,
      SyncUploadSection.documents,
    );
    final heldLinks = await _heldRows.readSection(
      _profileUuid,
      SyncUploadSection.documentLinks,
    );
    final adopted = await _staged.adoptedHashes(_profileUuid);
    final serverLinks = await _serverLinks.readAll(_profileUuid);

    final links = await (_db.select(
      _db.documentationFilesToGeofeatures,
    )..where((t) => t.deletedAt.isNull())).get();
    final linkedToServer = <Uuid>{
      for (final link in links)
        if (features.contains(link.geofeatureUuid)) link.documentationFileUuid,
    };

    final documents = <SilexgisPlannedDocument>[];
    final going = <Uuid>{};
    final rows = await (_db.select(
      _db.documentationFiles,
    )..where((t) => t.deletedAt.isNull())).get();
    final present = <Uuid>{for (final row in rows) row.uuid};

    for (final row in rows) {
      final stored = _documentRevision(revisions[row.uuid]);
      if (stored != null) going.add(row.uuid);
      if (heldDocuments[row.uuid]?.stillAsSent(row.updatedAt) ?? false) {
        continue;
      }
      final copy = await _copies.read(row.uuid);
      final heldAs = copy?.heldAs ?? SilexgisHeldAs.own;
      final mayCarryBytes = !SilexgisHeldAs.serverOnlyCopies.contains(heldAs);

      if (stored == null) {
        if (!mayCarryBytes || !linkedToServer.contains(row.uuid)) continue;
        going.add(row.uuid);
        documents.add(
          SilexgisPlannedDocument(
            id: row.uuid,
            row: row,
            copy: copy,
            sendsBytes: true,
          ),
        );
        continue;
      }

      if (stored.agreesWith(row.updatedAt)) continue;
      final catalogued = await _catalogue.document(_profileUuid, row.uuid);
      final held = adopted[row.uuid] ?? _storedHashOf(catalogued);
      documents.add(
        SilexgisPlannedDocument(
          id: row.uuid,
          row: row,
          stored: stored,
          copy: copy,
          catalogued: catalogued,
          // With nothing to compare against, the bytes go: identical bytes
          // are only an edit of what is said, and missing ones would be a
          // revision that never leaves the device.
          sendsBytes:
              mayCarryBytes &&
              (held == null || held != row.fileHash?.toLowerCase()),
        ),
      );
    }

    for (final entry in revisions.entries) {
      final stored = entry.value;
      if (stored.entityTable != SilexgisHeldDocumentUpdater.entityTable) {
        continue;
      }
      if (present.contains(entry.key)) continue;
      // A removal is never edited again, so a held one waits for its decision.
      if (heldDocuments[entry.key]?.isDelete ?? false) continue;
      documents.add(SilexgisPlannedDocument(id: entry.key, stored: stored));
    }

    final plannedLinks = <SilexgisPlannedLink>[];
    final live = <SilexgisLinkKey>{};
    for (final link in links) {
      final target = link.geofeatureUuid;
      if (target == null) continue;
      final key = (link.documentationFileUuid, target);
      live.add(key);
      if (serverLinks.containsKey(key)) continue;
      if (!going.contains(link.documentationFileUuid)) continue;
      if (!features.contains(target)) continue;
      if (heldLinks[link.uuid]?.stillAsSent(link.updatedAt) ?? false) continue;
      if (await _cataloguedLink(key) case final linkId?) {
        // Already hung there, as the catalogue says: recorded, not sent.
        await _serverLinks.record(
          _profileUuid,
          SilexgisServerLinkEntry(
            documentUuid: key.$1,
            targetKind: SyncDocumentLink.targetFeature,
            targetId: target,
            linkId: linkId,
          ),
        );
        continue;
      }
      plannedLinks.add(
        SilexgisPlannedLink(
          documentId: link.documentationFileUuid,
          targetKind: SyncDocumentLink.targetFeature,
          targetId: target,
          local: link,
        ),
      );
    }
    for (final entry in serverLinks.values) {
      if (live.contains(entry.key)) continue;
      plannedLinks.add(
        SilexgisPlannedLink(
          documentId: entry.documentUuid,
          targetKind: entry.targetKind,
          targetId: entry.targetId,
        ),
      );
    }

    return SilexgisDocumentPlan(documents: documents, links: plannedLinks);
  }

  static StoredRevision? _documentRevision(StoredRevision? stored) =>
      stored?.entityTable == SilexgisHeldDocumentUpdater.entityTable
      ? stored
      : null;

  /// The stored file's hash, when the catalogue hands over exactly those
  /// bytes.
  static String? _storedHashOf(SilexgisDocumentData? document) =>
      document != null &&
          SyncDocumentReach.parse(document.reach) == SyncDocumentReach.original
      ? document.sha256?.toLowerCase()
      : null;

  /// The installation's identifier for a link its catalogue already lists.
  Future<String?> _cataloguedLink(SilexgisLinkKey key) async {
    for (final link in await _catalogue.linksOf(_profileUuid, key.$1)) {
      if (link.targetId == key.$2 &&
          link.targetKind == SyncDocumentLink.targetFeature) {
        return link.linkId;
      }
    }
    return null;
  }
}
