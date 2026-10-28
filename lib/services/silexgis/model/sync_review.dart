import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';

/// What a reviewer's decision did to a held row.
enum SyncReviewOutcome {
  /// Written, whole or in part. Its revision is the row's new base revision.
  accepted,

  /// Turned down; nothing was written. A reviewer may still accept it later,
  /// which arrives as a later decision under the same review.
  rejected,

  /// The device sent the same row again with other content, which waits in
  /// its place under a new review. Nothing to do.
  superseded,

  /// Accepted, but refused when it was written — the account may have lost a
  /// right since it sent the row.
  failed;

  static SyncReviewOutcome? tryParse(String? wireName) {
    for (final value in SyncReviewOutcome.values) {
      if (value.name == wireName) return value;
    }
    return null;
  }
}

/// One decision on the reviews stream.
class SyncReview {
  const SyncReview({
    required this.reviewId,
    required this.entity,
    required this.rowId,
    required this.outcome,
    this.section,
    this.rawOutcome,
    this.decidedAt,
    this.note,
    this.revision,
    this.code,
    this.partial = false,
    this.current,
  });

  /// The id the upload answered the row with. The same one can appear again
  /// with a later decision, and the later one is what stands.
  final String reviewId;

  /// The upload section the row came in, as named on the wire.
  final String entity;

  /// [entity] as a section this build knows, or null for one it does not.
  final SyncUploadSection? section;

  /// The row's id as the upload answered it.
  final String rowId;

  /// Null for an outcome this build has not heard of; the wire value is then
  /// in [rawOutcome].
  final SyncReviewOutcome? outcome;
  final String? rawOutcome;

  final String? decidedAt;

  /// What the reviewer wrote to the uploader.
  final String? note;

  /// The revision the server holds the row at now, when this account may read
  /// it. Absent for a new row that was not written.
  final String? revision;

  /// Why a [SyncReviewOutcome.failed] row could not be written.
  final String? code;

  /// An accepted edit of which the reviewer wrote only some fields: the
  /// device's version of the others is not the server's.
  final bool partial;

  /// The server's row after a turned-down or failed edit or removal, or a
  /// [partial] acceptance, shaped exactly as [section]'s own stream delivers
  /// it. **Absent whenever that stream would not hand this account the row
  /// now**, and always for `people`.
  final Map<String, Object?>? current;

  /// [current] read as a feature row, when it is one.
  SyncFeatureRow? get currentRow =>
      section == SyncUploadSection.rows && current != null
      ? SyncFeatureRow.fromJson(current!)
      : null;

  static SyncReview fromJson(Map<String, Object?> json) {
    final entity = json['entity'] as String? ?? '';
    final rawOutcome = json['outcome'] as String?;
    return SyncReview(
      reviewId: json['reviewId']! as String,
      entity: entity,
      section: SyncUploadSection.tryParse(entity),
      rowId: json['rowId']! as String,
      outcome: SyncReviewOutcome.tryParse(rawOutcome),
      rawOutcome: rawOutcome,
      decidedAt: json['decidedAt'] as String?,
      note: json['note'] as String?,
      revision: json['revision'] as String?,
      code: json['code'] as String?,
      partial: json['partial'] == true,
      current: json['current'] is Map
          ? Map<String, Object?>.from(json['current']! as Map)
          : null,
    );
  }
}

/// One page of the reviews stream, oldest decision first.
class SyncReviewsPage implements SyncStreamPage {
  const SyncReviewsPage({
    required this.setRevision,
    required this.reviews,
    required this.nextCursor,
    required this.hasMore,
  });

  @override
  final int setRevision;

  final List<SyncReview> reviews;

  @override
  final String? nextCursor;

  @override
  final bool hasMore;

  static SyncReviewsPage fromJson(Map<String, Object?> json) => SyncReviewsPage(
    setRevision: (json['setRevision'] as num?)?.toInt() ?? 0,
    reviews: (json['reviews'] as List? ?? const <Object?>[])
        .whereType<Map>()
        .map((e) => SyncReview.fromJson(Map<String, Object?>.from(e)))
        .toList(growable: false),
    nextCursor: json['nextCursor'] as String?,
    hasMore: json['hasMore'] as bool? ?? false,
  );
}
