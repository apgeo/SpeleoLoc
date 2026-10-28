import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// One catalogue row read back: a document hung on one feature.
class SilexgisCatalogueEntry {
  const SilexgisCatalogueEntry({required this.link, required this.document});

  final SilexgisDocumentLinkData link;
  final SilexgisDocumentData document;

  Uuid get documentId => document.documentId;
  SyncDocumentReach get reach => SyncDocumentReach.parse(document.reach);
  List<int> get renditions => decodeRenditions(document.renditions);

  /// What the caver may ask for. See [offeredFor].
  List<SyncRendition> get offered => offeredFor(document);

  /// The size of [rendition] when the catalogue knows it: only the stored
  /// file's, handed over byte for byte.
  int? sizeOf(SyncRendition rendition) =>
      rendition.isOriginal && reach == SyncDocumentReach.original
      ? document.sizeBytes
      : null;

  /// What may be asked for of [document]: the file itself when the reach
  /// hands it over, then each picture size the server draws, largest first.
  static List<SyncRendition> offeredFor(SilexgisDocumentData document) {
    final reach = SyncDocumentReach.parse(document.reach);
    return <SyncRendition>[
      if (reach.offersOriginal) SyncRendition.original,
      if (reach != SyncDocumentReach.none)
        for (final size in decodeRenditions(document.renditions))
          if (SyncRendition.sizes.contains(size)) SyncRendition.picture(size),
    ];
  }

  static String encodeRenditions(List<int> sizes) => sizes.join(',');

  static List<int> decodeRenditions(String? text) => text == null || text == ''
      ? const <int>[]
      : text
            .split(',')
            .map(int.tryParse)
            .whereType<int>()
            .toList(growable: false);
}

/// What applying one catalogue page did.
class SilexgisCatalogueApplyReport {
  const SilexgisCatalogueApplyReport({
    this.links = 0,
    this.removed = 0,
    this.documents = const <SyncDocument>[],
  });

  final int links;

  /// Tombstones that removed a link this device held.
  final int removed;

  /// The documents the page described, for whatever keeps local copies of
  /// them in step.
  final List<SyncDocument> documents;
}

/// The device's local-only copy of an installation's photo and document
/// catalogue.
///
/// Metadata only, and never a reason to fetch anything: a caver chooses what
/// to carry. Like the rest of the SilexGIS state it never leaves the device.
class SilexgisDocumentCatalogueRepository {
  SilexgisDocumentCatalogueRepository(this._db);

  final AppDatabase _db;
  final _log = AppLogger.of('SilexgisDocumentCatalogueRepository');

  /// Stores one page. A link sent again replaces the copy held; a tombstone
  /// removes its link, and a document left with no link goes with it. A
  /// tombstone for a link never held is a no-op.
  Future<SilexgisCatalogueApplyReport> applyPage(
    String profileUuid,
    SyncDocumentsPage page,
  ) async {
    var links = 0;
    final documents = <String, SyncDocument>{};
    final touched = <Uuid>{};
    for (final link in page.links) {
      final documentId = Uuid.tryParse(link.documentId);
      final targetId = Uuid.tryParse(link.targetId);
      if (documentId == null || targetId == null) {
        _log.warning('a catalogue link names an identifier that is not one');
        continue;
      }
      await _writeDocument(profileUuid, documentId, link.document);
      final previous = await _linkDocument(profileUuid, link.id);
      if (previous != null && previous != documentId) touched.add(previous);
      await _db
          .into(_db.silexgisDocumentLink)
          .insertOnConflictUpdate(
            SilexgisDocumentLinkCompanion.insert(
              profileUuid: profileUuid,
              linkId: link.id,
              documentId: documentId,
              targetKind: link.targetKind,
              targetId: targetId,
              role: Value(link.role),
              caption: Value(link.caption),
              sortOrder: Value(link.sortOrder),
              isPrimary: Value(link.isPrimary),
              inDefaultSet: Value(link.inDefaultSet),
              revision: Value(link.revision),
            ),
          );
      documents[link.documentId] = link.document;
      links++;
    }

    var removed = 0;
    for (final tombstone in page.tombstones) {
      final documentId = await _linkDocument(profileUuid, tombstone.id);
      if (documentId == null) continue;
      await (_db.delete(_db.silexgisDocumentLink)..where(
            (t) =>
                t.profileUuid.equals(profileUuid) &
                t.linkId.equals(tombstone.id),
          ))
          .go();
      touched.add(documentId);
      removed++;
    }
    for (final documentId in touched) {
      await _dropIfUnlinked(profileUuid, documentId);
    }

    return SilexgisCatalogueApplyReport(
      links: links,
      removed: removed,
      documents: documents.values.toList(growable: false),
    );
  }

  /// Replaces the copy held of [document] — the server's own version, handed
  /// back with a reviewer's decision. A document the catalogue does not list
  /// is not added: it is listed only while something here hangs on it.
  /// Returns whether a copy was held.
  Future<bool> refreshDocument(
    String profileUuid,
    SyncDocument document,
  ) async {
    final documentId = Uuid.tryParse(document.id);
    if (documentId == null ||
        await this.document(profileUuid, documentId) == null) {
      return false;
    }
    await _writeDocument(profileUuid, documentId, document);
    return true;
  }

  /// Forgets [documentId] and every link to it — the installation said it is
  /// no longer there for this account. The next read says whether it is
  /// listed again.
  Future<void> removeDocument(String profileUuid, Uuid documentId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.silexgisDocumentLink)..where(
            (t) =>
                t.profileUuid.equals(profileUuid) &
                t.documentId.equalsValue(documentId),
          ))
          .go();
      await (_db.delete(_db.silexgisDocument)..where(
            (t) =>
                t.profileUuid.equals(profileUuid) &
                t.documentId.equalsValue(documentId),
          ))
          .go();
    });
  }

  /// Empties one installation's catalogue — it no longer offers documents to
  /// this account, which is also what hides them.
  ///
  /// The documents stream's position goes with it: a position past rows the
  /// device no longer holds would never bring them again.
  Future<void> clear(String profileUuid) async {
    await _db.transaction(() async {
      await (_db.delete(_db.silexgisStreamCursor)..where(
            (t) =>
                t.profileUuid.equals(profileUuid) &
                t.stream.equals(SyncStream.documents.routeName),
          ))
          .go();
      await (_db.delete(
        _db.silexgisDocumentLink,
      )..where((t) => t.profileUuid.equals(profileUuid))).go();
      await (_db.delete(
        _db.silexgisDocument,
      )..where((t) => t.profileUuid.equals(profileUuid))).go();
    });
  }

  /// Every catalogue row hung on [targetId], in the order the installation
  /// shows them.
  Future<List<SilexgisCatalogueEntry>> entriesFor(
    String profileUuid,
    Uuid targetId,
  ) async {
    final query =
        _db.select(_db.silexgisDocumentLink).join(<Join>[
            innerJoin(
              _db.silexgisDocument,
              _db.silexgisDocument.profileUuid.equalsExp(
                    _db.silexgisDocumentLink.profileUuid,
                  ) &
                  _db.silexgisDocument.documentId.equalsExp(
                    _db.silexgisDocumentLink.documentId,
                  ),
            ),
          ])
          ..where(
            _db.silexgisDocumentLink.profileUuid.equals(profileUuid) &
                _db.silexgisDocumentLink.targetId.equalsValue(targetId),
          )
          ..orderBy(<OrderingTerm>[
            OrderingTerm.asc(_db.silexgisDocumentLink.sortOrder),
            OrderingTerm.asc(_db.silexgisDocument.title),
          ]);
    return (await query.get())
        .map(
          (row) => SilexgisCatalogueEntry(
            link: row.readTable(_db.silexgisDocumentLink),
            document: row.readTable(_db.silexgisDocument),
          ),
        )
        .toList(growable: false);
  }

  /// One document as catalogued, or null when it is not.
  Future<SilexgisDocumentData?> document(String profileUuid, Uuid documentId) =>
      (_db.select(_db.silexgisDocument)..where(
            (t) =>
                t.profileUuid.equals(profileUuid) &
                t.documentId.equalsValue(documentId),
          ))
          .getSingleOrNull();

  /// Every catalogue link of [documentId].
  Future<List<SilexgisDocumentLinkData>> linksOf(
    String profileUuid,
    Uuid documentId,
  ) =>
      (_db.select(_db.silexgisDocumentLink)..where(
            (t) =>
                t.profileUuid.equals(profileUuid) &
                t.documentId.equalsValue(documentId),
          ))
          .get();

  /// Whether this installation's catalogue lists anything at all.
  Future<bool> isEmpty(String profileUuid) async =>
      await (_db.select(_db.silexgisDocument)
            ..where((t) => t.profileUuid.equals(profileUuid))
            ..limit(1))
          .getSingleOrNull() ==
      null;

  Future<void> _writeDocument(
    String profileUuid,
    Uuid documentId,
    SyncDocument document,
  ) => _db
      .into(_db.silexgisDocument)
      .insertOnConflictUpdate(
        SilexgisDocumentCompanion.insert(
          profileUuid: profileUuid,
          documentId: documentId,
          versionId: Value(document.versionId),
          title: document.title,
          description: Value(document.description),
          fileKind: document.fileKind,
          mimeType: Value(document.mimeType),
          sizeBytes: Value(document.sizeBytes),
          sha256: Value(document.sha256),
          reach: document.reach.wireName,
          renditions: Value(
            SilexgisCatalogueEntry.encodeRenditions(document.renditions),
          ),
          capturedAt: Value(document.capturedAt),
          updatedAt: Value(document.updatedAt),
          createdByDeviceUserId: Value(document.createdByDeviceUserId),
        ),
      );

  Future<Uuid?> _linkDocument(String profileUuid, String linkId) async =>
      (await (_db.select(_db.silexgisDocumentLink)..where(
                (t) =>
                    t.profileUuid.equals(profileUuid) & t.linkId.equals(linkId),
              ))
              .getSingleOrNull())
          ?.documentId;

  Future<void> _dropIfUnlinked(String profileUuid, Uuid documentId) async {
    if ((await linksOf(profileUuid, documentId)).isNotEmpty) return;
    await (_db.delete(_db.silexgisDocument)..where(
          (t) =>
              t.profileUuid.equals(profileUuid) &
              t.documentId.equalsValue(documentId),
        ))
        .go();
  }
}
