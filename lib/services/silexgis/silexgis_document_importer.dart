import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_title.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_document_updater.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/utils/clock.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';

/// A verified file, ready to become a documentation file.
class SilexgisFetchedDocument {
  const SilexgisFetchedDocument({
    required this.document,
    required this.links,
    required this.relativePath,
    required this.sizeBytes,
    required this.sha256,
    required this.heldAs,
    required this.revision,
    this.rendition,
  });

  /// The catalogue's description of it.
  final SilexgisDocumentData document;

  /// Every catalogue link of the document.
  final List<SilexgisDocumentLinkData> links;
  final String relativePath;
  final int sizeBytes;
  final String sha256;
  final SilexgisHeldAs heldAs;
  final int? rendition;

  /// The server's revision of the document, stored as its base revision.
  final String revision;
}

/// Writes a fetched file into the local database as the server's document:
/// one documentation file under the document's own identifier, linked to
/// every feature this device holds that the catalogue hangs it on.
///
/// Runs with change logging suspended, as every server-driven write does: the
/// row is the server's, and a change-log entry would carry it to other devices
/// as if this device had made it.
class SilexgisDocumentImporter {
  SilexgisDocumentImporter({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required SilexgisFileCopyRepository copies,
    required String profileUuid,
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _copies = copies,
       _profileUuid = profileUuid,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final SilexgisFileCopyRepository _copies;
  final String _profileUuid;
  final Clock _clock;

  /// The catalogue's kinds as the local file types the viewers know.
  static const Map<String, String> _typeOfKind = <String, String>{
    'photo': 'photo',
    'video': 'video',
    'audio': 'audio',
    'document': 'text_document',
  };

  /// Imports [fetched]. Returns how many links it was given.
  Future<int> import(SilexgisFetchedDocument fetched) async {
    final document = fetched.document;
    final id = document.documentId;
    final now = _clock.nowMs();
    var linked = 0;
    await _logger.runSuspended(() async {
      await _db.transaction(() async {
        final detected = DocumentationFileHelper.detectFileType(
          fetched.relativePath,
        );
        await _db
            .into(_db.documentationFiles)
            .insert(
              DocumentationFilesCompanion.insert(
                uuid: id,
                title: SilexgisDocumentTitle.local(document.title),
                fileName: fetched.relativePath,
                fileSize: fetched.sizeBytes,
                fileType: detected != 'unknown'
                    ? detected
                    : _typeOfKind[document.fileKind] ?? 'unknown',
              ).copyWith(
                description: Value(document.description),
                fileHash: Value(fetched.sha256),
                createdAt: Value(now),
                updatedAt: Value(now),
                createdByUserUuid: Value(await _localAuthor(document)),
              ),
            );

        final linkedTargets = <Uuid>{};
        for (final link in fetched.links) {
          // A raster map's picture arrives with its map, not as a document.
          if (link.role == SyncDocumentLink.roleMap2d ||
              link.targetKind != 'feature') {
            continue;
          }
          if (!linkedTargets.add(link.targetId)) continue;
          final type = await _heldFeatureType(link.targetId);
          if (type == null) continue;
          await _db
              .into(_db.documentationFilesToGeofeatures)
              .insert(
                DocumentationFilesToGeofeaturesCompanion.insert(
                  uuid: Uuid.v7(),
                  geofeatureType: type.dbValue,
                  documentationFileUuid: id,
                  geofeatureUuid: Value(link.targetId),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
          linked++;
        }

        await _copies.register(
          SilexgisFileCopyEntry(
            documentUuid: id,
            heldAs: fetched.heldAs,
            origin: SilexgisCopyOrigin.server,
            versionId: document.versionId,
            rendition: fetched.rendition,
          ),
        );
        await _localState.writeRevision(
          _profileUuid,
          id,
          entityTable: SilexgisHeldDocumentUpdater.entityTable,
          wireKind: SilexgisHeldDocumentUpdater.wireKind,
          revision: fetched.revision,
          localUpdatedAt: now,
        );
      });
    });
    return linked;
  }

  /// The local user who sent the document, when the installation names a
  /// phone user this device has.
  Future<Uuid?> _localAuthor(SilexgisDocumentData document) async {
    final id = Uuid.tryParse(document.createdByDeviceUserId);
    if (id == null) return null;
    final user = await (_db.select(
      _db.users,
    )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();
    return user?.uuid;
  }

  /// Which kind of local feature [id] is, or null when this device does not
  /// hold it.
  Future<GeofeatureType?> _heldFeatureType(Uuid id) async {
    if (await (_db.select(
          _db.caves,
        )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull() !=
        null) {
      return GeofeatureType.cave;
    }
    if (await (_db.select(
          _db.cavePlaces,
        )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull() !=
        null) {
      return GeofeatureType.cavePlace;
    }
    if (await (_db.select(
          _db.caveAreas,
        )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull() !=
        null) {
      return GeofeatureType.caveArea;
    }
    return null;
  }
}
