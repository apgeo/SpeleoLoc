import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';

/// One scan of a recording, as the trips stream hands it.
///
/// It carries no position of its own: where it was is its place's position,
/// which the feature stream delivers or withholds.
class SyncTripPoint {
  const SyncTripPoint({
    required this.id,
    required this.scannedAt,
    this.placeId,
    this.notes,
    this.createdByDeviceUserId,
    this.revision,
  });

  final String id;

  /// The place scanned, or null for a scan that names none.
  final String? placeId;
  final String scannedAt;
  final String? notes;

  /// The phone user who made the scan, which may be a user of another phone.
  final String? createdByDeviceUserId;

  /// The scan's own revision, sent back as its `baseRevision`.
  final String? revision;

  static SyncTripPoint fromJson(Map<String, Object?> json) => SyncTripPoint(
    id: json['id']! as String,
    placeId: json['placeId'] as String?,
    scannedAt: json['scannedAt']! as String,
    notes: json['notes'] as String?,
    createdByDeviceUserId: json['createdByDeviceUserId'] as String?,
    revision: json['revision'] as String?,
  );
}

/// A scan removed from a recording, named by the trips stream.
///
/// Only a scan the account would be given were it live is named; the removal
/// of a scan of a withheld place stays silent.
class SyncPointTombstone {
  const SyncPointTombstone({
    required this.id,
    required this.recordingId,
    required this.deletedAt,
  });

  final String id;
  final String recordingId;
  final String deletedAt;

  static SyncPointTombstone fromJson(Map<String, Object?> json) =>
      SyncPointTombstone(
        id: json['id']! as String,
        recordingId: json['recordingId']! as String,
        deletedAt: json['deletedAt']! as String,
      );
}

/// One recording on the trips stream, with its live scans.
class SyncTripRecording {
  const SyncTripRecording({
    required this.id,
    required this.caveId,
    required this.startedAt,
    this.title,
    this.description,
    this.log,
    this.endedAt,
    this.createdByDeviceUserId,
    this.revision,
    this.points = const <SyncTripPoint>[],
  });

  final String id;
  final String caveId;
  final String? title;
  final String? description;
  final String? log;
  final String startedAt;

  /// Null while the recording is still open.
  final String? endedAt;

  /// The phone user who started it, which may be a user of another phone.
  final String? createdByDeviceUserId;

  /// The recording's own revision, sent back as its `baseRevision`.
  final String? revision;

  /// In the order they were made. **Scans of a place this account is not
  /// handed are left out**, so a scan missing here may have been removed or
  /// may only be withheld; the list says nothing to tell the two apart.
  final List<SyncTripPoint> points;

  static SyncTripRecording fromJson(Map<String, Object?> json) =>
      SyncTripRecording(
        id: json['id']! as String,
        caveId: json['caveId']! as String,
        title: json['title'] as String?,
        description: json['description'] as String?,
        log: json['log'] as String?,
        startedAt: json['startedAt']! as String,
        endedAt: json['endedAt'] as String?,
        createdByDeviceUserId: json['createdByDeviceUserId'] as String?,
        revision: json['revision'] as String?,
        points: (json['points'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map((e) => SyncTripPoint.fromJson(Map<String, Object?>.from(e)))
            .toList(growable: false),
      );
}

/// One page of the trips stream, on its own cursor.
class SyncTripsPage implements SyncStreamPage {
  const SyncTripsPage({
    required this.setRevision,
    required this.recordings,
    required this.tombstones,
    required this.pointTombstones,
    required this.nextCursor,
    required this.hasMore,
  });

  @override
  final int setRevision;
  final List<SyncTripRecording> recordings;

  /// Recordings removed after the cursor. A removed scan is not one; it is
  /// named in [pointTombstones].
  final List<SyncTombstone> tombstones;

  /// Scans removed after the cursor, **or null when the page has no such
  /// member** — a server that does not name removed scans, whose recording
  /// comes again without the scan and says nothing more. An empty list is an
  /// answer: no scan was removed, so a scan missing from a recording's list is
  /// only withheld.
  final List<SyncPointTombstone>? pointTombstones;

  @override
  final String? nextCursor;

  @override
  final bool hasMore;

  static SyncTripsPage fromJson(Map<String, Object?> json) => SyncTripsPage(
    setRevision: (json['setRevision'] as num?)?.toInt() ?? 0,
    recordings: (json['recordings'] as List? ?? const <Object?>[])
        .whereType<Map>()
        .map((e) => SyncTripRecording.fromJson(Map<String, Object?>.from(e)))
        .toList(growable: false),
    tombstones: (json['tombstones'] as List? ?? const <Object?>[])
        .whereType<Map>()
        .map((e) => SyncTombstone.fromJson(Map<String, Object?>.from(e)))
        .toList(growable: false),
    pointTombstones: (json['pointTombstones'] as List?)
        ?.whereType<Map>()
        .map((e) => SyncPointTombstone.fromJson(Map<String, Object?>.from(e)))
        .toList(growable: false),
    nextCursor: json['nextCursor'] as String?,
    hasMore: json['hasMore'] as bool? ?? false,
  );
}
