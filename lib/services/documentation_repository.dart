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
}
