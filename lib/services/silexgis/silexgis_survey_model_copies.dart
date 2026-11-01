import 'dart:io';

import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/model_links_cleanup.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_title.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// The local copies of server survey models: a documentation file under the
/// model's document identifier, hung on its cave.
///
/// Writes run with change logging suspended, as every server-driven write
/// does. **Only a copy the server handed down is ever replaced or removed**;
/// a model whose document is the caver's own file — one they uploaded that
/// the browser later made a model — is left as it is.
class SilexgisSurveyModelCopies {
  SilexgisSurveyModelCopies({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisFileCopyRepository copies,
    required Future<Directory> Function() baseDir,
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _copies = copies,
       _baseDir = baseDir,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisFileCopyRepository _copies;
  final Future<Directory> Function() _baseDir;
  final Clock _clock;

  static const String fileType = 'survey_model';

  /// The local row of [documentUuid], or null.
  Future<DocumentationFile?> local(Uuid documentUuid) => (_db.select(
    _db.documentationFiles,
  )..where((t) => t.uuid.equalsValue(documentUuid))).getSingleOrNull();

  /// Whether [documentUuid] is here as a copy a server handed down.
  Future<bool> isServerCopy(Uuid documentUuid) async =>
      (await _copies.read(documentUuid))?.origin == SilexgisCopyOrigin.server;

  /// Stores the fetched file at [relativePath] as [documentUuid], on
  /// [caveUuid]. A copy already here gets the new bytes in place, so its
  /// mappings and the cave's default stay with it.
  Future<void> store({
    required Uuid documentUuid,
    required Uuid caveUuid,
    required String title,
    required String relativePath,
    required int sizeBytes,
    required String sha256,
    String? versionId,
  }) async {
    final now = _clock.nowMs();
    String? replaced;
    await _logger.runSuspended(
      () => _db.transaction(() async {
        final existing = await local(documentUuid);
        if (existing == null) {
          await _db
              .into(_db.documentationFiles)
              .insert(
                DocumentationFilesCompanion.insert(
                  uuid: documentUuid,
                  title: SilexgisDocumentTitle.local(title),
                  fileName: relativePath,
                  fileSize: sizeBytes,
                  fileType: fileType,
                ).copyWith(
                  fileHash: Value(sha256),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
          await _db
              .into(_db.documentationFilesToGeofeatures)
              .insert(
                DocumentationFilesToGeofeaturesCompanion.insert(
                  uuid: Uuid.v7(),
                  geofeatureType: GeofeatureType.cave.dbValue,
                  documentationFileUuid: documentUuid,
                  geofeatureUuid: Value(caveUuid),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
        } else {
          replaced = existing.fileName;
          await (_db.update(
            _db.documentationFiles,
          )..where((t) => t.uuid.equalsValue(documentUuid))).write(
            DocumentationFilesCompanion(
              fileName: Value(relativePath),
              fileSize: Value(sizeBytes),
              fileHash: Value(sha256),
              updatedAt: Value(now),
            ),
          );
        }
        await _copies.register(
          SilexgisFileCopyEntry(
            documentUuid: documentUuid,
            heldAs: SilexgisHeldAs.original,
            origin: SilexgisCopyOrigin.server,
            versionId: versionId,
          ),
        );
      }),
    );
    if (replaced case final old? when old != relativePath) await _delete(old);
  }

  /// Removes the copy of [documentUuid] with everything tied to it here: its
  /// links, its place mappings and the cave's choice of it as the default.
  /// Returns the mappings that went, whose revisions the caller forgets.
  Future<List<Uuid>> remove(Uuid documentUuid) async {
    if (!await isServerCopy(documentUuid)) return const <Uuid>[];
    final row = await local(documentUuid);
    final mappings = <Uuid>[
      for (final m in await (_db.select(
        _db.cavePlaceModelStations,
      )..where((t) => t.documentationFileUuid.equalsValue(documentUuid))).get())
        m.uuid,
    ];
    await _logger.runSuspended(
      () => _db.transaction(() async {
        await deleteModelLinks(
          _db,
          _logger,
          documentationFileUuid: documentUuid,
        );
        await (_db.delete(_db.documentationFilesToGeofeatures)
              ..where((t) => t.documentationFileUuid.equalsValue(documentUuid)))
            .go();
        await (_db.delete(
          _db.documentationFiles,
        )..where((t) => t.uuid.equalsValue(documentUuid))).go();
        await (_db.delete(
          _db.silexgisFileCopy,
        )..where((t) => t.documentUuid.equalsValue(documentUuid))).go();
      }),
    );
    if (row != null) await _delete(row.fileName);
    return mappings;
  }

  Future<void> _delete(String relativePath) async {
    final file = File('${(await _baseDir()).path}/$relativePath');
    if (await file.exists()) await file.delete();
  }
}
