import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';

/// Which form of a document to fetch: the file itself, or a picture the
/// server draws of it at one of its fixed sizes.
class SyncRendition {
  const SyncRendition._(this.size);

  /// The file itself — under `locationFree` reach, the copy without its
  /// location data.
  static const SyncRendition original = SyncRendition._(null);

  /// The sizes the server draws, largest first. Nothing else may be asked
  /// for: an unknown size refuses the whole request.
  static const List<int> sizes = <int>[2400, 1200, 480, 160];

  /// A picture [size] pixels across. Only one of [sizes].
  factory SyncRendition.picture(int size) {
    if (!sizes.contains(size)) {
      throw ArgumentError.value(size, 'size', 'not a size the server draws');
    }
    return SyncRendition._(size);
  }

  /// Null for [original].
  final int? size;

  bool get isOriginal => size == null;

  Object toJson() => size ?? 'original';

  /// The rendition [json] names, or null for one this build cannot ask for.
  static SyncRendition? tryParse(Object? json) {
    if (json == 'original') return original;
    if (json is num && sizes.contains(json.toInt())) {
      return SyncRendition._(json.toInt());
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is SyncRendition && other.size == size;

  @override
  int get hashCode => size.hashCode;

  @override
  String toString() => size == null ? 'original' : '$size';
}

/// One item of a file-address request.
class SyncFileLinkRequest {
  const SyncFileLinkRequest({
    required this.documentId,
    required this.rendition,
  });

  final String documentId;
  final SyncRendition rendition;

  Map<String, Object?> toJson() => <String, Object?>{
    'documentId': documentId,
    'rendition': rendition.toJson(),
  };
}

/// An address handed out for one item.
class SyncFileLink {
  const SyncFileLink({
    required this.documentId,
    required this.rendition,
    required this.url,
    this.expiresAt,
    this.sizeBytes,
    this.sha256,
  });

  final String documentId;
  final SyncRendition rendition;

  /// Relative to the server. The signed token in it is the credential, so it
  /// is opened without the bearer token.
  final String url;
  final String? expiresAt;

  /// The rewritten copy's own numbers, for an original handed under
  /// `locationFree` reach on an installation that describes those copies;
  /// null otherwise.
  final int? sizeBytes;
  final String? sha256;

  static SyncFileLink? tryParse(Map<String, Object?> json) {
    final rendition = SyncRendition.tryParse(json['rendition']);
    final url = json['url'] as String?;
    final documentId = json['documentId'] as String?;
    if (rendition == null || url == null || documentId == null) return null;
    return SyncFileLink(
      documentId: documentId,
      rendition: rendition,
      url: url,
      expiresAt: json['expiresAt'] as String?,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
      sha256: json['sha256'] as String?,
    );
  }
}

/// An item the installation would not give an address for.
class SyncFileLinkRefusal {
  const SyncFileLinkRefusal({
    required this.documentId,
    required this.code,
    this.rendition,
  });

  final String documentId;
  final SyncRendition? rendition;
  final String code;

  /// The one action for this item.
  ///
  /// - `sync.document_unavailable`: the caver is told, and the document leaves
  ///   the catalogue copy; the next catalogue read says whether it is listed.
  /// - `sync.original_withheld`: ask for a picture instead where the catalogue
  ///   lists any.
  /// - `sync.rendition_unavailable`: ask for the file itself instead, where
  ///   the reach allows it.
  SilexgisAction get action => switch (code) {
    SilexgisCodes.documentUnavailable => SilexgisAction.surfaceToUser,
    SilexgisCodes.originalWithheld ||
    SilexgisCodes.renditionUnavailable => SilexgisAction.applyAndResubmit,
    _ => SilexgisAction.surfaceToUser,
  };

  static SyncFileLinkRefusal fromJson(Map<String, Object?> json) =>
      SyncFileLinkRefusal(
        documentId: json['documentId'] as String? ?? '',
        rendition: SyncRendition.tryParse(json['rendition']),
        code: json['code'] as String? ?? '',
      );
}

/// What the file-address route answered.
class SyncFileLinksAnswer {
  const SyncFileLinksAnswer({required this.links, required this.refused});

  final List<SyncFileLink> links;
  final List<SyncFileLinkRefusal> refused;

  /// At most this many items go in one request; more refuses it whole.
  static const int maxItems = 200;

  static SyncFileLinksAnswer fromJson(Map<String, Object?> json) =>
      SyncFileLinksAnswer(
        links: (json['links'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map((e) => SyncFileLink.tryParse(Map<String, Object?>.from(e)))
            .whereType<SyncFileLink>()
            .toList(growable: false),
        refused: (json['refused'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map(
              (e) => SyncFileLinkRefusal.fromJson(Map<String, Object?>.from(e)),
            )
            .toList(growable: false),
      );
}
