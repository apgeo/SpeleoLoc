import 'package:speleoloc/services/silexgis/model/sync_upload_documents.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_title.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_planner.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';

/// The bytes a row brings, once staged.
class SilexgisStagedContent {
  const SilexgisStagedContent({
    required this.transferId,
    required this.sha256,
    required this.sizeBytes,
  });

  final String transferId;
  final String sha256;
  final int sizeBytes;
}

/// Turns a planned documentation file into the row that goes up.
///
/// What it leaves out matters as much as what it states, because an absent
/// member says nothing on this wire:
///
/// - The title goes on a create, and on an edit only when the caver changed
///   it here. A local row holds fifty characters of a longer server title,
///   and sending those back would rename the document for every reader.
/// - The caption goes only for a photo, the one kind the server keeps one for.
/// - The bytes' description — name, hash, size, staged upload — goes only
///   with new content. An edit names [SyncUploadDocument.baseVersionId]
///   whenever the revision is known, and then needs no hash at all; a copy
///   without location or a drawn picture is only ever edited that way.
/// - No capture time. A row's creation time is when the file came onto this
///   device — the import, for a picked file — and the server keeps a stated
///   capture time wherever the file states none, so sending it would assert
///   a moment nobody witnessed. The file's own metadata is the better witness.
class SilexgisDocumentRowComposer {
  const SilexgisDocumentRowComposer();

  /// The row for [document], or null when no row can safely be sent for it.
  SyncUploadDocument? compose(
    SilexgisPlannedDocument document, {
    SilexgisStagedContent? content,
  }) {
    final row = document.row;
    if (row == null) {
      return SyncUploadDocument.delete(
        id: document.id.toString(),
        baseRevision: document.stored?.revision,
      );
    }
    final isPhoto = row.fileType == 'photo';
    final author = row.createdByUserUuid?.toString();
    final updatedAt = _iso(row.updatedAt ?? row.createdAt);

    if (document.isNew) {
      if (content == null) return null;
      return SyncUploadDocument(
        id: document.id.toString(),
        title: row.title,
        description: isPhoto && (row.description?.isNotEmpty ?? false)
            ? row.description
            : null,
        fileName: fileNameOf(row.fileName),
        sha256: content.sha256,
        sizeBytes: content.sizeBytes,
        stagedUploadId: content.transferId,
        createdByDeviceUserId: author,
        clientUpdatedAt: updatedAt,
      );
    }

    final baseVersionId = document.baseVersionId;
    final ownFile = document.heldAs == SilexgisHeldAs.own;
    if (content == null &&
        baseVersionId == null &&
        SilexgisHeldAs.serverOnlyCopies.contains(document.heldAs)) {
      // Without the revision, the server would weigh the copy's hash against
      // the stored file's and take a caption edit for new content.
      return null;
    }
    if (document.sendsBytes && content == null) return null;

    final server = document.catalogued;
    String? title;
    if (server != null) {
      if (SilexgisDocumentTitle.changedLocally(row.title, server.title)) {
        title = row.title;
      }
    } else if (ownFile) {
      // Its title is the one this device sent.
      title = row.title;
    }

    String? description;
    if (isPhoto) {
      final local = row.description ?? '';
      // A caption is never cut here, so without the catalogue's it is sent
      // as it stands.
      if (server == null || local != (server.description ?? '')) {
        description = local;
      }
    }

    return SyncUploadDocument(
      id: document.id.toString(),
      baseRevision: document.stored?.revision,
      baseVersionId: baseVersionId,
      title: title,
      description: description,
      fileName: content == null ? null : fileNameOf(row.fileName),
      sha256:
          content?.sha256 ??
          (baseVersionId == null ? row.fileHash?.toLowerCase() : null),
      sizeBytes: content?.sizeBytes,
      stagedUploadId: content?.transferId,
      createdByDeviceUserId: author,
      clientUpdatedAt: updatedAt,
    );
  }

  /// The name a stored file was given, without the prefix storage added to
  /// keep it unique, and within the 255 characters the server keeps.
  static String fileNameOf(String storedPath) {
    final base = storedPath.split('/').last;
    final name = base.replaceFirst(RegExp(r'^(doc|srv)_\d+_(\d+_)?'), '');
    final chosen = name.isEmpty ? base : name;
    return chosen.length <= 255 ? chosen : chosen.substring(0, 255);
  }

  static String? _iso(int? ms) => ms == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();
}
