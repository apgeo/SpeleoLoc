import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_title.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// Keeps the title and description of documents this device fetched in step
/// with the catalogue.
///
/// Metadata only: a file is never replaced from here. And only for a row the
/// caver has not edited since the two sides last agreed — an unsent local edit
/// is the caver's, and goes up rather than being written over.
class SilexgisHeldDocumentUpdater {
  SilexgisHeldDocumentUpdater({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required String profileUuid,
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _profileUuid = profileUuid,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final String _profileUuid;
  final Clock _clock;

  static const String entityTable = 'documentation_files';
  static const String wireKind = 'document';

  /// The revision a document is stored under: the server's own stamp.
  static String revisionOf(SyncDocument document) =>
      document.updatedAt ?? document.versionId ?? '';

  /// Applies [documents]. Returns how many local rows changed.
  Future<int> apply(Iterable<SyncDocument> documents) async {
    var changed = 0;
    await _logger.runSuspended(() async {
      final agreed = await _localState.readRevisions(_profileUuid);
      for (final document in documents) {
        if (await _follow(document, agreed) == _Followed.changed) changed++;
      }
    });
    return changed;
  }

  /// Applies one [document] that did not come on a page — the server's own
  /// version, handed back with a reviewer's decision. Returns whether the
  /// local row now says what the server's does.
  Future<bool> follow(SyncDocument document) => _logger.runSuspended(
    () async =>
        await _follow(
          document,
          await _localState.readRevisions(_profileUuid),
        ) !=
        _Followed.skipped,
  );

  Future<_Followed> _follow(
    SyncDocument document,
    Map<Uuid, StoredRevision> agreed,
  ) async {
    final id = Uuid.tryParse(document.id);
    if (id == null) return _Followed.skipped;
    final stored = agreed[id];
    if (stored == null || stored.entityTable != entityTable) {
      return _Followed.skipped;
    }
    final row = await (_db.select(
      _db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();
    if (row == null || !stored.agreesWith(row.updatedAt)) {
      return _Followed.skipped;
    }

    final title = SilexgisDocumentTitle.local(document.title);
    var localUpdatedAt = row.updatedAt;
    var followed = _Followed.unchanged;
    if (row.title != title || row.description != document.description) {
      localUpdatedAt = _clock.nowMs();
      await (_db.update(
        _db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(id))).write(
        DocumentationFilesCompanion(
          title: Value(title),
          description: Value(document.description),
          updatedAt: Value(localUpdatedAt),
        ),
      );
      followed = _Followed.changed;
    }
    await _localState.writeRevision(
      _profileUuid,
      id,
      entityTable: entityTable,
      wireKind: wireKind,
      revision: revisionOf(document),
      localUpdatedAt: localUpdatedAt,
    );
    return followed;
  }
}

enum _Followed { skipped, unchanged, changed }
