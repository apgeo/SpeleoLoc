import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_review.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/utils/clock.dart';

/// A local row an installation is holding for a reviewer, or has decided
/// about and is waiting on the caver.
class SilexgisHeldItem {
  const SilexgisHeldItem({
    required this.section,
    required this.entityUuid,
    required this.entityTable,
    required this.reviewId,
    this.wireKind,
    this.isDelete = false,
    this.sentLocalUpdatedAt,
    this.heldAt,
    this.outcome,
    this.note,
    this.code,
    this.decidedAt,
    this.current,
    this.keptAt,
  });

  final SyncUploadSection section;
  final Uuid entityUuid;
  final String entityTable;
  final String? wireKind;

  /// The proposal the row waits under. A row sent again with other content
  /// waits under a new one.
  final String reviewId;

  /// The proposal is a removal: the local row is already gone.
  final bool isDelete;

  /// The row's own stamp as it was sent.
  final int? sentLocalUpdatedAt;
  final int? heldAt;

  /// Null while the proposal waits; [SyncReviewOutcome.rejected] or
  /// [SyncReviewOutcome.failed] once decided.
  final SyncReviewOutcome? outcome;
  final String? note;
  final String? code;
  final String? decidedAt;

  /// The server's own row, as the feature stream shapes it, when the decision
  /// could hand it over.
  final Map<String, Object?>? current;

  /// When the caver chose to keep their version unsent.
  final int? keptAt;

  bool get isWaiting => outcome == null;

  /// Decided against, and the caver has not yet said what to do about it.
  bool get awaitsCaver => outcome != null && keptAt == null;

  /// Whether the local row still says what was sent for review.
  ///
  /// While it does, sending it again is pointless at best — the same content
  /// is answered with the same review — and, once a reviewer has decided,
  /// would replace the decision with a new proposal. A row with no stamp
  /// counts as unchanged for the same reason.
  bool stillAsSent(int? localUpdatedAt) => sentLocalUpdatedAt == localUpdatedAt;
}

/// What an upload answered `held`, ready to be recorded.
class SilexgisHeldEntry {
  const SilexgisHeldEntry({
    required this.section,
    required this.entityUuid,
    required this.entityTable,
    required this.reviewId,
    this.wireKind,
    this.isDelete = false,
    this.sentLocalUpdatedAt,
  });

  final SyncUploadSection section;
  final Uuid entityUuid;
  final String entityTable;
  final String reviewId;
  final String? wireKind;
  final bool isDelete;
  final int? sentLocalUpdatedAt;
}

/// How many held rows there are, by what they wait on.
class SilexgisReviewCounts {
  const SilexgisReviewCounts({this.waiting = 0, this.toDecide = 0});

  /// Waiting for a reviewer.
  final int waiting;

  /// Turned down or failed, and waiting for the caver.
  final int toDecide;

  bool get isEmpty => waiting == 0 && toDecide == 0;
}

/// The device's local-only record of rows held for review on an installation.
///
/// Like every other piece of SilexGIS state it never leaves the device: a
/// review is a fact about one account's uploads to one installation.
class SilexgisHeldRowRepository {
  SilexgisHeldRowRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  /// Every held row of one section, by row identifier. Read once per run.
  Future<Map<Uuid, SilexgisHeldItem>> readSection(
    String profileUuid,
    SyncUploadSection section,
  ) async {
    final rows =
        await (_db.select(_db.silexgisHeldRow)..where(
              (t) =>
                  t.profileUuid.equals(profileUuid) &
                  t.section.equals(section.wireName),
            ))
            .get();
    return <Uuid, SilexgisHeldItem>{
      for (final row in rows)
        row.entityUuid: ?_read(row),
    };
  }

  /// Every held row of one installation.
  Future<List<SilexgisHeldItem>> readAll(String profileUuid) async {
    final rows = await (_db.select(
      _db.silexgisHeldRow,
    )..where((t) => t.profileUuid.equals(profileUuid))).get();
    return <SilexgisHeldItem>[
      for (final row in rows)
        ?_read(row),
    ];
  }

  /// The row waiting under [reviewId], or null when none does — the review is
  /// an earlier proposal for a row sent again since, or the caver has already
  /// settled it.
  Future<SilexgisHeldItem?> byReviewId(
    String profileUuid,
    String reviewId,
  ) async {
    final row =
        await (_db.select(_db.silexgisHeldRow)
              ..where(
                (t) =>
                    t.profileUuid.equals(profileUuid) &
                    t.reviewId.equals(reviewId),
              )
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _read(row);
  }

  /// Records what an upload answered `held`. A row held before is held again
  /// under its new review, and whatever was decided about the earlier one no
  /// longer stands.
  Future<void> recordHeld(
    String profileUuid,
    Iterable<SilexgisHeldEntry> entries,
  ) async {
    if (entries.isEmpty) return;
    final now = _clock.nowMs();
    await _db.batch((batch) {
      for (final entry in entries) {
        batch.insert(
          _db.silexgisHeldRow,
          SilexgisHeldRowCompanion.insert(
            profileUuid: profileUuid,
            section: entry.section.wireName,
            entityUuid: entry.entityUuid,
            entityTable: entry.entityTable,
            wireKind: Value(entry.wireKind),
            reviewId: entry.reviewId,
            isDelete: Value(entry.isDelete),
            sentLocalUpdatedAt: Value(entry.sentLocalUpdatedAt),
            heldAt: Value(now),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Records a reviewer's decision against the row waiting under [reviewId].
  /// The last decision read for a review is the one that stands.
  Future<void> recordDecision(
    String profileUuid, {
    required String reviewId,
    required SyncReviewOutcome outcome,
    String? note,
    String? code,
    String? decidedAt,
    Map<String, Object?>? current,
  }) async {
    await (_db.update(_db.silexgisHeldRow)..where(
          (t) =>
              t.profileUuid.equals(profileUuid) & t.reviewId.equals(reviewId),
        ))
        .write(
          SilexgisHeldRowCompanion(
            outcome: Value(outcome.name),
            note: Value(note),
            code: Value(code),
            decidedAt: Value(decidedAt),
            currentJson: Value(current == null ? null : jsonEncode(current)),
            keptAt: const Value(null),
          ),
        );
  }

  /// The caver keeps their version on the device and unsent until they edit
  /// it again.
  Future<void> markKept(
    String profileUuid,
    SyncUploadSection section,
    Uuid entityUuid,
  ) async {
    await (_db.update(_db.silexgisHeldRow)
          ..where(_key(profileUuid, section, entityUuid)))
        .write(SilexgisHeldRowCompanion(keptAt: Value(_clock.nowMs())));
  }

  /// Forgets the held entries of these rows — they were answered otherwise,
  /// accepted, or settled by the caver.
  Future<void> clear(
    String profileUuid,
    SyncUploadSection section,
    Iterable<Uuid> entityUuids,
  ) async {
    if (entityUuids.isEmpty) return;
    await (_db.delete(_db.silexgisHeldRow)..where(
          (t) =>
              t.profileUuid.equals(profileUuid) &
              t.section.equals(section.wireName) &
              t.entityUuid.isIn(entityUuids.map((u) => u.bytes)),
        ))
        .go();
  }

  Future<SilexgisReviewCounts> counts(String profileUuid) async {
    var waiting = 0;
    var toDecide = 0;
    for (final row in await readAll(profileUuid)) {
      if (row.isWaiting) waiting++;
      if (row.awaitsCaver) toDecide++;
    }
    return SilexgisReviewCounts(waiting: waiting, toDecide: toDecide);
  }

  Expression<bool> Function(SilexgisHeldRow) _key(
    String profileUuid,
    SyncUploadSection section,
    Uuid entityUuid,
  ) =>
      (t) =>
          t.profileUuid.equals(profileUuid) &
          t.section.equals(section.wireName) &
          t.entityUuid.equalsValue(entityUuid);

  /// Null for an entry of a section this build no longer knows.
  static SilexgisHeldItem? _read(SilexgisHeldRowData row) {
    final section = SyncUploadSection.tryParse(row.section);
    if (section == null) return null;
    final json = row.currentJson;
    return SilexgisHeldItem(
      section: section,
      entityUuid: row.entityUuid,
      entityTable: row.entityTable,
      wireKind: row.wireKind,
      reviewId: row.reviewId,
      isDelete: row.isDelete,
      sentLocalUpdatedAt: row.sentLocalUpdatedAt,
      heldAt: row.heldAt,
      outcome: SyncReviewOutcome.tryParse(row.outcome),
      note: row.note,
      code: row.code,
      decidedAt: row.decidedAt,
      current: json == null
          ? null
          : Map<String, Object?>.from(jsonDecode(json) as Map),
      keptAt: row.keptAt,
    );
  }
}
