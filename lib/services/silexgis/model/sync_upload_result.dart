import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';

/// What happened to one uploaded row.
///
/// Arbitration is per row and so is the answer: a device that edited forty
/// caves offline and lost one to a conflict is told which one, and the other
/// thirty-nine are not thrown away with it. So a verdict rides a `200`.
enum SyncRowStatus {
  created,
  updated,
  deleted,

  /// Nothing was written and nothing was wrong: the row already said what was
  /// asked. A resent create whose identifier is already here lands here, and
  /// so does a delete of a row that was never received.
  unchanged,

  /// Somebody wrote the row after the device last read it. The device's
  /// version was **not** applied.
  conflict,

  rejected;

  static SyncRowStatus? tryParse(String? wireName) {
    for (final value in SyncRowStatus.values) {
      if (value.name == wireName) return value;
    }
    return null;
  }
}

/// One row's verdict.
class SyncRowResult {
  const SyncRowResult({
    required this.id,
    required this.status,
    this.rawStatus,
    this.revision,
    this.code,
    this.detail,
  });

  final String id;

  /// Null when the server named a status this build has not heard of; the wire
  /// value is then in [rawStatus]. A new status is a contract change and
  /// arrives with one, so this is a guard rather than a case to handle.
  final SyncRowStatus? status;
  final String? rawStatus;

  /// **Store this** — it is what the next edit of the row sends as its
  /// `baseRevision`. Null on a refusal.
  final String? revision;

  /// Named only on [SyncRowStatus.conflict] and [SyncRowStatus.rejected].
  final String? code;
  final String? detail;

  bool get isWritten =>
      status == SyncRowStatus.created ||
      status == SyncRowStatus.updated ||
      status == SyncRowStatus.deleted;

  /// The one action to take for this row. The row loop's vocabulary is the
  /// same closed set the problem documents use.
  SilexgisAction get action {
    switch (status) {
      case SyncRowStatus.created:
      case SyncRowStatus.updated:
      case SyncRowStatus.deleted:
      case SyncRowStatus.unchanged:
        return SilexgisAction.ignore;
      case SyncRowStatus.conflict:
      case SyncRowStatus.rejected:
      case null:
        break;
    }
    switch (code) {
      case SilexgisCodes.conflict:
      case SilexgisCodes.rowNotFound:
      case SilexgisCodes.rowDeleted:
      case SilexgisCodes.parentRequired:
      case SilexgisCodes.parentNotFound:
      // Resubmittable only if the client can mend the shape; where it cannot,
      // the caller escalates to the caver rather than looping on it.
      case SilexgisCodes.geometryInvalid:
        return SilexgisAction.applyAndResubmit;

      case SilexgisCodes.idConflict:
      case SilexgisCodes.typeUnknown:
        return SilexgisAction.surfaceToUser;

      case SilexgisCodes.rowForbidden:
      case SilexgisCodes.rowDeleteForbidden:
      case SilexgisCodes.createForbidden:
      case SilexgisCodes.parentForbidden:
      case SilexgisCodes.locationForbidden:
      case SilexgisCodes.kindUnsupported:
        return SilexgisAction.stop;
    }
    // A write-service code passed through from the shared write service — a
    // broken containment shape, a property document that fails its schema. The
    // detail says which.
    return SilexgisAction.surfaceToUser;
  }

  static SyncRowResult fromJson(Map<String, Object?> json) {
    final rawStatus = json['status'] as String?;
    return SyncRowResult(
      id: json['id']! as String,
      status: SyncRowStatus.tryParse(rawStatus),
      rawStatus: rawStatus,
      revision: json['revision'] as String?,
      code: json['code'] as String?,
      detail: json['detail'] as String?,
    );
  }
}

/// A row already on the server, near one this batch created.
class NearbyFeature {
  const NearbyFeature({
    required this.id,
    this.name,
    this.kind,
    this.distanceMeters,
    this.caveFeatureId,
  });

  final String id;
  final String? name;
  final String? kind;
  final double? distanceMeters;

  /// The cave the neighbour belongs to, when it has one.
  final String? caveFeatureId;

  static NearbyFeature fromJson(Map<String, Object?> json) => NearbyFeature(
    id: json['id']! as String,
    name: json['name'] as String?,
    kind: json['kind'] as String?,
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    caveFeatureId: json['caveFeatureId'] as String?,
  );
}

/// What was already here, near a row this batch **created**.
///
/// Never a verdict: every row listed was written and its entry in `rows` says
/// so. It exists because a device is offline when it decides to add a cave and
/// cannot ask first — deciding whether the two are the same cave is the
/// caver's, not the server's.
///
/// Two properties to plan for. Rows this same batch wrote are never each
/// other's duplicates, and the pool searched is what the account may read
/// *and* place exactly — so an empty report is not evidence of no duplicates,
/// and neither is a `DuplicateRadiusMeters` of zero, which turns the report
/// off entirely without announcing it anywhere.
class SyncDuplicateReport {
  const SyncDuplicateReport({required this.id, required this.nearby});

  /// The row this batch created.
  final String id;
  final List<NearbyFeature> nearby;

  static SyncDuplicateReport fromJson(Map<String, Object?> json) =>
      SyncDuplicateReport(
        id: json['id']! as String,
        nearby: (json['nearby'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map((e) => NearbyFeature.fromJson(Map<String, Object?>.from(e)))
            .toList(growable: false),
      );
}

/// The answer to one upload attempt.
class SyncUploadResult {
  const SyncUploadResult({
    required this.batchId,
    required this.importBatchId,
    required this.replayed,
    required this.written,
    required this.refused,
    required this.rows,
    required this.conflicts,
    required this.duplicates,
  });

  final String batchId;

  /// Every upload becomes an import batch, which is what lets a caver look at
  /// what a phone put into the registry and take all of it back through the
  /// screen that undoes a bad file.
  final String importBatchId;

  /// True when this batch identifier had already been applied: the stored
  /// answer is being returned and nothing was written a second time.
  final bool replayed;

  final int written;
  final int refused;

  final List<SyncRowResult> rows;

  /// The server's own version of every row that lost a conflict, shaped
  /// exactly as a download would have delivered it.
  ///
  /// **A row that lost and is missing from here is a row whose position this
  /// account may not have** — the same answer the download gives, absence
  /// rather than a blurred stand-in. Re-read it instead of treating the gap as
  /// an error.
  final List<SyncFeatureRow> conflicts;

  final List<SyncDuplicateReport> duplicates;

  SyncFeatureRow? conflictFor(String rowId) {
    for (final row in conflicts) {
      if (row.id == rowId) return row;
    }
    return null;
  }

  static SyncUploadResult fromJson(Map<String, Object?> json) =>
      SyncUploadResult(
        batchId: json['batchId']! as String,
        importBatchId: json['importBatchId'] as String? ?? '',
        replayed: json['replayed'] as bool? ?? false,
        written: (json['written'] as num?)?.toInt() ?? 0,
        refused: (json['refused'] as num?)?.toInt() ?? 0,
        rows: (json['rows'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map((e) => SyncRowResult.fromJson(Map<String, Object?>.from(e)))
            .toList(growable: false),
        conflicts: (json['conflicts'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map((e) => SyncFeatureRow.fromJson(Map<String, Object?>.from(e)))
            .toList(growable: false),
        duplicates: (json['duplicates'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map(
              (e) => SyncDuplicateReport.fromJson(Map<String, Object?>.from(e)),
            )
            .toList(growable: false),
      );
}
