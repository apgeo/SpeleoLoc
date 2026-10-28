import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';

/// One document going up in the `documents` section: what is said about a
/// file, and — when the row brings new content — the staged bytes it names.
///
/// **An absent member says nothing**, and that is used deliberately: a title
/// the caver did not change is left out rather than sent back, because the
/// phone may hold only the first fifty characters of it, and a caption left
/// out stands. Every member is therefore emitted only when it is stated.
class SyncUploadDocument implements SyncUploadItem {
  const SyncUploadDocument({
    required this.id,
    this.baseRevision,
    this.title,
    this.description,
    this.fileName,
    this.sha256,
    this.sizeBytes,
    this.stagedUploadId,
    this.capturedAt,
    this.createdByDeviceUserId,
    this.clientUpdatedAt,
    this.baseVersionId,
  }) : deleted = false;

  /// A removal, arbitrated on [baseRevision] as an edit is.
  const SyncUploadDocument.delete({required this.id, this.baseRevision})
    : deleted = true,
      title = null,
      description = null,
      fileName = null,
      sha256 = null,
      sizeBytes = null,
      stagedUploadId = null,
      capturedAt = null,
      createdByDeviceUserId = null,
      clientUpdatedAt = null,
      baseVersionId = null;

  /// The documentation file's own identifier, adopted verbatim on a create.
  final String id;

  /// The document's revision as last agreed, or null for a new document.
  final String? baseRevision;
  final bool deleted;

  /// Blank or absent keeps the name the document has.
  final String? title;

  /// A photo's caption. Absent leaves it; empty clears it. Ignored by the
  /// server for a file that is not a picture.
  final String? description;

  /// The file's original name, at most 255 characters.
  final String? fileName;

  /// Lower-case hex of the content the document has on the phone. Left out of
  /// an edit that names [baseVersionId] and brings no staged bytes.
  final String? sha256;
  final int? sizeBytes;

  /// The staged bytes this row makes the document's content.
  final String? stagedUploadId;

  /// Kept by the server only when the file states no capture time itself.
  final String? capturedAt;
  final String? createdByDeviceUserId;
  final String? clientUpdatedAt;

  /// The catalogue's `versionId` for the bytes the phone holds. With it, a
  /// row naming no staged bytes changes only what is said about the file —
  /// the one way a copy that is not the stored file can be edited at all.
  final String? baseVersionId;

  bool get isNew => baseRevision == null;

  SyncUploadDocument withStagedUpload(String transferId) => SyncUploadDocument(
    id: id,
    baseRevision: baseRevision,
    title: title,
    description: description,
    fileName: fileName,
    sha256: sha256,
    sizeBytes: sizeBytes,
    stagedUploadId: transferId,
    capturedAt: capturedAt,
    createdByDeviceUserId: createdByDeviceUserId,
    clientUpdatedAt: clientUpdatedAt,
    baseVersionId: baseVersionId,
  );

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'baseRevision': ?baseRevision,
    if (deleted) 'deleted': true,
    'title': ?title,
    'description': ?description,
    'fileName': ?fileName,
    'sha256': ?sha256,
    'sizeBytes': ?sizeBytes,
    'stagedUploadId': ?stagedUploadId,
    'capturedAt': ?capturedAt,
    'createdByDeviceUserId': ?createdByDeviceUserId,
    'clientUpdatedAt': ?clientUpdatedAt,
    'baseVersionId': ?baseVersionId,
  };
}

/// One link going up in the `documentLinks` section.
///
/// A link is named by its document and its target together; the phone keeps
/// no identifier of its own for it. The answer names the installation's.
class SyncUploadDocumentLink implements SyncUploadItem {
  const SyncUploadDocumentLink({
    required this.documentId,
    required this.targetKind,
    required this.targetId,
    this.role,
    this.caption,
    this.sortOrder,
    this.deleted = false,
  });

  final String documentId;

  /// `feature`, `tripRecording` or `tripPoint`.
  final String targetKind;
  final String targetId;

  /// Left out so the server derives it from the file and the target.
  final String? role;

  /// The link's own caption — what the file is called on that target, not
  /// the photo's description.
  final String? caption;
  final int? sortOrder;

  /// Takes the document down from the target; the document stays.
  final bool deleted;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'documentId': documentId,
    'target': <String, Object?>{'kind': targetKind, 'id': targetId},
    'role': ?role,
    'caption': ?caption,
    'sortOrder': ?sortOrder,
    'deleted': deleted,
  };
}
