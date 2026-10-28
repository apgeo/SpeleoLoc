import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';

/// One recording going up in the `tripRecordings` section.
///
/// What never travels is as deliberate as what does: who went, as typed on
/// the phone, whether the log fell behind its scans, and which device recorded
/// it stay on the phone.
class SyncUploadTripRecording implements SyncUploadItem {
  const SyncUploadTripRecording({
    required this.id,
    required this.baseRevision,
    required this.caveId,
    required this.title,
    required this.startedAt,
    this.description,
    this.log,
    this.endedAt,
    this.createdByDeviceUserId,
    this.clientUpdatedAt,
  }) : deleted = false;

  /// A removal: arbitrated on [baseRevision], and carrying nothing else.
  const SyncUploadTripRecording.delete({
    required this.id,
    required this.baseRevision,
  }) : deleted = true,
       caveId = null,
       title = null,
       startedAt = null,
       description = null,
       log = null,
       endedAt = null,
       createdByDeviceUserId = null,
       clientUpdatedAt = null;

  final String id;

  /// Null for a recording new to the installation.
  final String? baseRevision;
  final bool deleted;
  final String? caveId;
  final String? title;
  final String? description;
  final String? log;
  final String? startedAt;

  /// Absent while the recording is open. The upload that closes it is the one
  /// the server makes its trip report from.
  final String? endedAt;

  /// Absent means "unchanged": an author this device cannot name is never
  /// replaced by silence or by another.
  final String? createdByDeviceUserId;

  /// Provenance only, never compared.
  final String? clientUpdatedAt;

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'baseRevision': baseRevision,
      'deleted': deleted,
    };
    if (deleted) return json;
    return json..addAll(<String, Object?>{
      'caveId': caveId,
      'title': title,
      'description': description,
      'log': log,
      'startedAt': startedAt,
      'endedAt': ?endedAt,
      'createdByDeviceUserId': ?createdByDeviceUserId,
      'clientUpdatedAt': ?clientUpdatedAt,
    });
  }
}

/// One scan going up in the `tripPoints` section.
class SyncUploadTripPoint implements SyncUploadItem {
  const SyncUploadTripPoint({
    required this.id,
    required this.recordingId,
    required this.baseRevision,
    required this.scannedAt,
    this.placeId,
    this.notes,
    this.createdByDeviceUserId,
  }) : deleted = false;

  /// A removal names its recording too: a scan belongs to one for good.
  const SyncUploadTripPoint.delete({
    required this.id,
    required this.recordingId,
    required this.baseRevision,
  }) : deleted = true,
       scannedAt = null,
       placeId = null,
       notes = null,
       createdByDeviceUserId = null;

  final String id;
  final String recordingId;
  final String? baseRevision;
  final bool deleted;
  final String? placeId;
  final String? scannedAt;
  final String? notes;

  /// Absent means "unchanged", as for a recording.
  final String? createdByDeviceUserId;

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'recordingId': recordingId,
      'baseRevision': baseRevision,
      'deleted': deleted,
    };
    if (deleted) return json;
    return json..addAll(<String, Object?>{
      'placeId': placeId,
      'scannedAt': scannedAt,
      'notes': notes,
      'createdByDeviceUserId': ?createdByDeviceUserId,
    });
  }
}
