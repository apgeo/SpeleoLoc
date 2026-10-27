import 'package:speleoloc/services/silexgis/model/sync_stream.dart';

/// What fetching a document's file would hand this account, decided by the
/// installation's location rules.
enum SyncDocumentReach {
  /// The stored file, byte for byte; the catalogue's size and hash are its own.
  original('original'),

  /// The whole picture at full size, rewritten without its location data. The
  /// catalogue quotes no size or hash for it: the copy is made on request.
  locationFree('locationFree'),

  /// No file itself, only the pictures the server draws of it.
  renditions('renditions'),

  /// Neither: listed, and not to be fetched by this account.
  none('none');

  const SyncDocumentReach(this.wireName);
  final String wireName;

  /// Whether the file itself, in some form, may be asked for.
  bool get offersOriginal => this == original || this == locationFree;

  /// Unknown reaches are read as [none]: nothing is fetched that the device
  /// cannot describe.
  static SyncDocumentReach parse(String? wireName) {
    for (final value in SyncDocumentReach.values) {
      if (value.wireName == wireName) return value;
    }
    return none;
  }
}

/// The document a catalogue row embeds: the file and what is said about it.
class SyncDocument {
  const SyncDocument({
    required this.id,
    required this.title,
    required this.fileKind,
    required this.reach,
    this.description,
    this.mimeType,
    this.sizeBytes,
    this.sha256,
    this.versionId,
    this.renditions = const <int>[],
    this.capturedAt,
    this.createdAt,
    this.updatedAt,
    this.createdByDeviceUserId,
  });

  final String id;

  /// The full title, however long. A local row keeps 50 characters of it.
  final String title;
  final String? description;

  /// `photo`, `video`, `audio`, `document` or `other`.
  final String fileKind;
  final String? mimeType;

  /// The stored file's size and hash. Absent under [SyncDocumentReach.locationFree].
  final int? sizeBytes;
  final String? sha256;

  /// Changes whenever new bytes replace the file.
  final String? versionId;
  final SyncDocumentReach reach;

  /// The picture sizes the server draws, largest first; empty for anything
  /// that is not an image.
  final List<int> renditions;
  final String? capturedAt;
  final String? createdAt;
  final String? updatedAt;

  /// The phone user who sent the document, where the installation keeps it.
  /// Older installations leave it out.
  final String? createdByDeviceUserId;

  static SyncDocument fromJson(Map<String, Object?> json) => SyncDocument(
    id: json['id']! as String,
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    fileKind: json['fileKind'] as String? ?? 'other',
    mimeType: json['mimeType'] as String?,
    sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
    sha256: json['sha256'] as String?,
    versionId: json['versionId'] as String?,
    reach: SyncDocumentReach.parse(json['reach'] as String?),
    renditions: (json['renditions'] as List? ?? const <Object?>[])
        .whereType<num>()
        .map((n) => n.toInt())
        .toList(growable: false),
    capturedAt: json['capturedAt'] as String?,
    createdAt: json['createdAt'] as String?,
    updatedAt: json['updatedAt'] as String?,
    createdByDeviceUserId: json['createdByDeviceUserId'] as String?,
  );
}

/// One catalogue row: a document hung on one feature.
class SyncDocumentLink {
  const SyncDocumentLink({
    required this.id,
    required this.documentId,
    required this.targetKind,
    required this.targetId,
    required this.document,
    this.role,
    this.caption,
    this.sortOrder = 0,
    this.isPrimary = false,
    this.inDefaultSet = false,
    this.revision,
  });

  /// The link's own identifier, which a tombstone names.
  final String id;
  final String documentId;
  final String targetKind;
  final String targetId;

  /// `photoEntrance`, `photoInterior`, `photoSurface`, `document`, `map2d`,
  /// `surveyData`, `other` or `report`.
  final String? role;
  final String? caption;
  final int sortOrder;
  final bool isPrimary;

  /// Among "the usual files" somebody curating the feature chose to carry.
  final bool inDefaultSet;
  final String? revision;
  final SyncDocument document;

  /// The role of a raster map's picture, which arrives with its map.
  static const String roleMap2d = 'map2d';

  static SyncDocumentLink fromJson(Map<String, Object?> json) {
    final target = Map<String, Object?>.from(
      json['target'] as Map? ?? const <String, Object?>{},
    );
    return SyncDocumentLink(
      id: json['id']! as String,
      documentId: json['documentId']! as String,
      targetKind: target['kind'] as String? ?? '',
      targetId: target['id'] as String? ?? '',
      role: json['role'] as String?,
      caption: json['caption'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isPrimary: json['isPrimary'] as bool? ?? false,
      inDefaultSet: json['inDefaultSet'] as bool? ?? false,
      revision: json['revision'] as String?,
      document: SyncDocument.fromJson(
        Map<String, Object?>.from(json['document']! as Map),
      ),
    );
  }
}

/// A catalogue link that went: detached, or left behind by a deleted document.
class SyncDocumentTombstone {
  const SyncDocumentTombstone({required this.id, this.deletedAt});

  final String id;
  final String? deletedAt;

  static SyncDocumentTombstone fromJson(Map<String, Object?> json) =>
      SyncDocumentTombstone(
        id: json['id']! as String,
        deletedAt: json['deletedAt'] as String?,
      );
}

/// One page of the documents catalogue, on the documents stream's own cursor.
class SyncDocumentsPage implements SyncStreamPage {
  const SyncDocumentsPage({
    required this.setRevision,
    required this.links,
    required this.tombstones,
    required this.nextCursor,
    required this.hasMore,
  });

  @override
  final int setRevision;
  final List<SyncDocumentLink> links;
  final List<SyncDocumentTombstone> tombstones;

  @override
  final String? nextCursor;

  @override
  final bool hasMore;

  static SyncDocumentsPage fromJson(Map<String, Object?> json) =>
      SyncDocumentsPage(
        setRevision: (json['setRevision'] as num?)?.toInt() ?? 0,
        links: (json['links'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map((e) => SyncDocumentLink.fromJson(Map<String, Object?>.from(e)))
            .toList(growable: false),
        tombstones: (json['tombstones'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map(
              (e) =>
                  SyncDocumentTombstone.fromJson(Map<String, Object?>.from(e)),
            )
            .toList(growable: false),
        nextCursor: json['nextCursor'] as String?,
        hasMore: json['hasMore'] as bool? ?? false,
      );
}
