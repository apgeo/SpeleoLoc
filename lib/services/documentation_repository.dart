import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Thin wrapper around the documentation-file helpers that currently live
/// on [AppDatabase].
///
/// Created as part of PR 2 so screens (document editors, documentation
/// list pages) can stop importing the global `appDatabase` symbol just to
/// build a [DocumentationGeofeatureLink]. The body simply delegates to
/// the existing helper to keep behaviour byte-identical; bigger
/// migrations of the write paths will land in later PR-2 slices.
class DocumentationRepository implements IDocumentationRepository {
  DocumentationRepository(this._database);

  final AppDatabase _database;
  final _log = AppLogger.of('DocumentationRepository');

  @override
  Future<DocumentationGeofeatureLink?> getDocumentationParentLink({
    Uuid? caveUuid,
    Uuid? cavePlaceUuid,
    Uuid? caveAreaUuid,
  }) async {
    try {
      return await _database.getDocumentationParentLink(
        caveUuid: caveUuid,
        cavePlaceUuid: cavePlaceUuid,
        caveAreaUuid: caveAreaUuid,
      );
    } catch (e, st) {
      _log.severe('getDocumentationParentLink failed', e, st);
      rethrow;
    }
  }

  @override
  Future<DocumentationFile?> findById(Uuid uuid) async {
    return (_database.select(_database.documentationFiles)
          ..where((t) => t.uuid.equalsValue(uuid)))
        .getSingleOrNull();
  }

  @override
  Future<List<DocumentationFile>> findDuplicates({
    required int fileSize,
    required String fileHash,
  }) async {
    return (_database.select(_database.documentationFiles)
          ..where((t) =>
              t.fileSize.equals(fileSize) & t.fileHash.equals(fileHash)))
        .get();
  }

  @override
  Future<Uuid> insertDocumentationFile({
    required DocumentationFilesCompanion companion,
    DocumentationGeofeatureLink? parentLink,
  }) async {
    try {
      return await _database.insertDocumentationFile(
        companion: companion,
        parentLink: parentLink,
      );
    } catch (e, st) {
      _log.severe('insertDocumentationFile failed', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateDocumentationFile({
    required Uuid uuid,
    required DocumentationFilesCompanion companion,
  }) async {
    try {
      await _database.updateDocumentationFile(uuid: uuid, companion: companion);
    } catch (e, st) {
      _log.severe('updateDocumentationFile failed', e, st);
      rethrow;
    }
  }

  @override
  Future<void> replaceDocumentationFile(DocumentationFile updated) async {
    try {
      await _database.update(_database.documentationFiles).replace(updated);
    } catch (e, st) {
      _log.severe('replaceDocumentationFile failed', e, st);
      rethrow;
    }
  }
}
