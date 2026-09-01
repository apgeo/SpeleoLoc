import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';

/// A row that has gone: an identifier and the moment it went, and nothing
/// else, ever.
///
/// Everything else a feature row holds says something — a name is half of what
/// protection hides, and the ancestry would publish which cave a deleted place
/// hung under. A device needs neither: it already holds the row it is being
/// told to drop and matches it by identifier.
class SyncTombstone {
  const SyncTombstone({required this.id, required this.deletedAt});

  final String id;
  final String deletedAt;

  static SyncTombstone fromJson(Map<String, Object?> json) => SyncTombstone(
    id: json['id']! as String,
    deletedAt: json['deletedAt']! as String,
  );
}

/// One page of a sync set's download.
class SyncDownloadPage {
  const SyncDownloadPage({
    required this.setRevision,
    required this.settings,
    required this.features,
    required this.tombstones,
    required this.nextCursor,
    required this.hasMore,
  });

  /// A counter, not a timestamp: two edits inside one clock tick must still be
  /// distinguishable. It moves only when something about the set actually
  /// changed, and a move retires every cursor issued before it.
  final int setRevision;

  /// The device's own code-generation configuration, stored and returned
  /// verbatim. The server forms no opinion about what any of it means.
  final Map<String, Object?> settings;

  /// Live rows, in change order. Both halves of the payload share that order
  /// and the single cursor resumes either, so do not sort them — and expect a
  /// child before its parent, because the order has nothing to do with
  /// containment.
  final List<SyncFeatureRow> features;

  final List<SyncTombstone> tombstones;

  /// Opaque. Present whenever the page carried anything, so a device that has
  /// caught up still keeps a watermark to come back with; null only when there
  /// was nothing at or after the position it asked from.
  final String? nextCursor;

  /// Level with the server as of this read — the signal to stop looping now,
  /// not to stop syncing.
  final bool hasMore;

  static SyncDownloadPage fromJson(Map<String, Object?> json) =>
      SyncDownloadPage(
        setRevision: (json['setRevision'] as num?)?.toInt() ?? 0,
        settings: json['settings'] is Map
            ? Map<String, Object?>.from(json['settings']! as Map)
            : const <String, Object?>{},
        features: (json['features'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map((e) => SyncFeatureRow.fromJson(Map<String, Object?>.from(e)))
            .toList(growable: false),
        tombstones: (json['tombstones'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map((e) => SyncTombstone.fromJson(Map<String, Object?>.from(e)))
            .toList(growable: false),
        nextCursor: json['nextCursor'] as String?,
        hasMore: json['hasMore'] as bool? ?? false,
      );

  bool get isEmpty => features.isEmpty && tombstones.isEmpty;
}
