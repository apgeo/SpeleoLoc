import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
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
  DocumentationRepository(this._database, this._logger);

  final AppDatabase _database;
  final ChangeLogger _logger;
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
    return (_database.select(
      _database.documentationFiles,
    )..where((t) => t.uuid.equalsValue(uuid))).getSingleOrNull();
  }

  @override
  Future<List<DocumentationFile>> findDuplicates({
    required int fileSize,
    required String fileHash,
  }) async {
    return (_database.select(_database.documentationFiles)..where(
          (t) => t.fileSize.equals(fileSize) & t.fileHash.equals(fileHash),
        ))
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

  @override
  Future<List<DocumentationFile>> getDocumentationFiles({
    DocumentationGeofeatureLink? parentLink,
  }) async {
    try {
      return await _database.getDocumentationFiles(parentLink: parentLink);
    } catch (e, st) {
      _log.severe('getDocumentationFiles failed', e, st);
      rethrow;
    }
  }

  @override
  Future<void> deleteDocumentationFile(Uuid uuid) async {
    try {
      await _database.transaction(() async {
        // Snapshot the rows the cascade will remove, then log a tombstone
        // for every one of them: sync propagates deletes per-uuid via
        // change_log, so a missing link tombstone leaves orphaned rows on
        // peers (and fails their deferred-FK check on import).
        final file = await findById(uuid);
        final geoLinks = await (_database.select(
          _database.documentationFilesToGeofeatures,
        )..where((t) => t.documentationFileUuid.equalsValue(uuid))).get();
        final tripLinks = await (_database.select(
          _database.documentationFilesToCaveTrips,
        )..where((t) => t.documentationFileUuid.equalsValue(uuid))).get();

        await _database.deleteDocumentationFileByUuid(uuid);

        if (file != null) {
          await _logger.logDelete(
            'documentation_files',
            uuid,
            oldValues: {'title': file.title, 'file_name': file.fileName},
          );
        }
        for (final l in geoLinks) {
          await _logger.logDelete(
            'documentation_files_to_geofeatures',
            l.uuid,
            oldValues: {
              'documentation_file_uuid': l.documentationFileUuid,
              'geofeature_uuid': l.geofeatureUuid,
              'geofeature_type': l.geofeatureType,
            },
          );
        }
        for (final l in tripLinks) {
          await _logger.logDelete(
            'documentation_files_to_cave_trips',
            l.uuid,
            oldValues: {
              'documentation_file_uuid': l.documentationFileUuid,
              'cave_trip_uuid': l.caveTripUuid,
            },
          );
        }
      });
    } catch (e, st) {
      _log.severe('deleteDocumentationFile failed', e, st);
      rethrow;
    }
  }

  @override
  Future<bool> hasAnyDocumentationFiles() async {
    try {
      return (_database.select(_database.documentationFiles)
            ..where((t) => t.deletedAt.isNull())
            ..limit(1))
          .getSingleOrNull()
          .then((row) => row != null);
    } catch (e, st) {
      _log.severe('hasAnyDocumentationFiles failed', e, st);
      rethrow;
    }
  }
}
