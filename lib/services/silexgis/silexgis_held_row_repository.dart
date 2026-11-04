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
    this.isConflict = false,
    this.isDeletedOnServer = false,
    this.isRefused = false,
    this.isResentAsNew = false,
  });

  final SyncUploadSection section;
  final Uuid entityUuid;
  final String entityTable;
  final String? wireKind;

  /// The proposal the row waits under. A row sent again with other content
  /// waits under a new one. Empty for a conflict, which no reviewer decides.
  final String reviewId;

  /// The proposal is a removal: the local row is already gone.
  final bool isDelete;

  /// The row's own stamp as it was sent.
  final int? sentLocalUpdatedAt;
  final int? heldAt;

  /// Null while the proposal waits, and for a conflict;
  /// [SyncReviewOutcome.rejected] or [SyncReviewOutcome.failed] once decided.
  final SyncReviewOutcome? outcome;
  final String? note;
  final String? code;
  final String? decidedAt;

  /// The server's own row, as [section]'s stream shapes it, when the decision
  /// or the conflict could hand it over.
  final Map<String, Object?>? current;

  /// When the caver chose to keep their version unsent.
  final int? keptAt;

  /// The row was not written because the installation holds a later version
  /// of it ([code] is `sync.conflict`), or because another pin already marks
  /// its place (`sync.pin_exists`). No reviewer is involved: only the caver
  /// can settle it.
  final bool isConflict;

  /// The installation removed the row while this device still held work on
  /// it, or inside it, that the server never had. The row is kept, and is not
  /// sent: there is nothing there left to write to. Only the caver can say
  /// whether it goes here too.
  final bool isDeletedOnServer;

  /// The installation refused the row outright, with a [code] that says
  /// sending it again as it is cannot succeed. No reviewer is involved.
  final bool isRefused;

  /// The caver sent the row again as new, under a new identifier, after the
  /// installation removed the old one. It goes up even as a new root, which
  /// the upload otherwise leaves to the caver's setting, and nobody waits on
  /// it: the entry goes with the row's first answer.
  final bool isResentAsNew;

  bool get isWaiting =>
      outcome == null &&
      !isConflict &&
      !isDeletedOnServer &&
      !isRefused &&
      !isResentAsNew;

  /// Decided against, in conflict, refused or removed on the server, and the
  /// caver has not yet said what to do about it.
  bool get awaitsCaver =>
      (outcome != null || isConflict || isDeletedOnServer || isRefused) &&
      keptAt == null;

  /// Removed on the server and kept here by the caver: neither sent nor
  /// asked about, until the caver edits it or sends it again as new.
  bool get isKeptAfterRemoval => isDeletedOnServer && keptAt != null;

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

/// A row an upload did not write because of the installation's own version,
/// ready to be recorded.
class SilexgisConflictEntry {
  const SilexgisConflictEntry({
    required this.section,
    required this.entityUuid,
    required this.entityTable,
    required this.code,
    this.wireKind,
    this.isDelete = false,
    this.sentLocalUpdatedAt,
    this.current,
  });

  final SyncUploadSection section;
  final Uuid entityUuid;
  final String entityTable;

  /// `sync.conflict` or `sync.pin_exists`.
  final String code;
  final String? wireKind;
  final bool isDelete;
  final int? sentLocalUpdatedAt;

  /// The server's row, when the answer echoed it.
  final Map<String, Object?>? current;
}

/// A row an upload refused for a reason sending it again cannot change, ready
/// to be recorded.
class SilexgisRefusedEntry {
  const SilexgisRefusedEntry({
    required this.section,
    required this.entityUuid,
    required this.entityTable,
    required this.code,
    this.wireKind,
    this.isDelete = false,
    this.sentLocalUpdatedAt,
  });

  final SyncUploadSection section;
  final Uuid entityUuid;
  final String entityTable;
  final String code;
  final String? wireKind;
  final bool isDelete;
  final int? sentLocalUpdatedAt;
}

/// How many held rows there are, by what they wait on.
class SilexgisReviewCounts {
  const SilexgisReviewCounts({
    this.waiting = 0,
    this.toDecide = 0,
    this.keptAfterRemoval = 0,
  });

  /// Waiting for a reviewer.
  final int waiting;

  /// Turned down, failed or in conflict, and waiting for the caver.
  final int toDecide;

  /// Removed on the server and kept on this device only.
  final int keptAfterRemoval;

  bool get isEmpty => waiting == 0 && toDecide == 0 && keptAfterRemoval == 0;
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

  /// What `outcome` holds for a conflict. Never a reviewer's word, so it
  /// cannot be mistaken for one.
  static const String conflictOutcome = 'conflict';

  /// What `outcome` holds for a row the installation removed while this
  /// device held unsent work on it. Not a reviewer's word either.
  static const String deletedOnServerOutcome = 'deleted';

  /// What `outcome` holds for a row the installation refused outright. Not a
  /// reviewer's word either.
  static const String refusedOutcome = 'refused';

  /// What `outcome` holds for a row the caver sent again as new. Not a
  /// reviewer's word either.
  static const String resentAsNewOutcome = 'resent';

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
      for (final row in rows) row.entityUuid: ?_read(row),
    };
  }

  /// Every held row of one installation.
  Future<List<SilexgisHeldItem>> readAll(String profileUuid) async {
    final rows = await (_db.select(
      _db.silexgisHeldRow,
    )..where((t) => t.profileUuid.equals(profileUuid))).get();
    return <SilexgisHeldItem>[for (final row in rows) ?_read(row)];
  }

  /// The row waiting under [reviewId], or null when none does — the review is
  /// an earlier proposal for a row sent again since, or the caver has already
  /// settled it.
  Future<SilexgisHeldItem?> byReviewId(
    String profileUuid,
    String reviewId,
  ) async {
    if (reviewId.isEmpty) return null;
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

  /// Records rows an upload answered with a conflict. Until the caver chooses,
  /// a row recorded here is held back from what a read brings and is not sent
  /// again while it says what was sent: sending it again would only meet the
  /// same later version.
  Future<void> recordConflicts(
    String profileUuid,
    Iterable<SilexgisConflictEntry> entries,
  ) async {
    if (entries.isEmpty) return;
    final now = _clock.nowMs();
    await _db.batch((batch) {
      for (final entry in entries) {
        final current = entry.current;
        batch.insert(
          _db.silexgisHeldRow,
          SilexgisHeldRowCompanion.insert(
            profileUuid: profileUuid,
            section: entry.section.wireName,
            entityUuid: entry.entityUuid,
            entityTable: entry.entityTable,
            wireKind: Value(entry.wireKind),
            reviewId: '',
            isDelete: Value(entry.isDelete),
            sentLocalUpdatedAt: Value(entry.sentLocalUpdatedAt),
            heldAt: Value(now),
            outcome: const Value(conflictOutcome),
            code: Value(entry.code),
            currentJson: Value(current == null ? null : jsonEncode(current)),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Records rows an upload refused for a reason that sending them again as
  /// they are cannot change. Like a conflict, a row recorded here is not sent
  /// again while it says what was sent, and waits for the caver.
  Future<void> recordRefused(
    String profileUuid,
    Iterable<SilexgisRefusedEntry> entries,
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
            reviewId: '',
            isDelete: Value(entry.isDelete),
            sentLocalUpdatedAt: Value(entry.sentLocalUpdatedAt),
            heldAt: Value(now),
            outcome: const Value(refusedOutcome),
            code: Value(entry.code),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Records that the installation removed a feature row this device keeps,
  /// because the row or something inside it holds work the server never had.
  /// Replaces whatever was held for the row: the version it waited on is gone.
  /// [localUpdatedAt] is the row's stamp now.
  Future<void> recordDeletedOnServer(
    String profileUuid,
    Uuid entityUuid, {
    required String entityTable,
    String? wireKind,
    int? localUpdatedAt,
  }) async {
    await _db
        .into(_db.silexgisHeldRow)
        .insert(
          SilexgisHeldRowCompanion.insert(
            profileUuid: profileUuid,
            section: SyncUploadSection.rows.wireName,
            entityUuid: entityUuid,
            entityTable: entityTable,
            wireKind: Value(wireKind),
            reviewId: '',
            sentLocalUpdatedAt: Value(localUpdatedAt),
            heldAt: Value(_clock.nowMs()),
            outcome: const Value(deletedOnServerOutcome),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// Records that the caver sends the feature row [entityUuid] again as new.
  Future<void> recordResentAsNew(
    String profileUuid,
    Uuid entityUuid, {
    required String entityTable,
    String? wireKind,
  }) async {
    await _db
        .into(_db.silexgisHeldRow)
        .insert(
          SilexgisHeldRowCompanion.insert(
            profileUuid: profileUuid,
            section: SyncUploadSection.rows.wireName,
            entityUuid: entityUuid,
            entityTable: entityTable,
            wireKind: Value(wireKind),
            reviewId: '',
            heldAt: Value(_clock.nowMs()),
            outcome: const Value(resentAsNewOutcome),
          ),
          mode: InsertMode.insertOrReplace,
        );
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
    if (reviewId.isEmpty) return;
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
    var kept = 0;
    for (final row in await readAll(profileUuid)) {
      if (row.isWaiting) waiting++;
      if (row.awaitsCaver) toDecide++;
      if (row.isKeptAfterRemoval) kept++;
    }
    return SilexgisReviewCounts(
      waiting: waiting,
      toDecide: toDecide,
      keptAfterRemoval: kept,
    );
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
    final isConflict = row.outcome == conflictOutcome;
    final isDeletedOnServer = row.outcome == deletedOnServerOutcome;
    final isRefused = row.outcome == refusedOutcome;
    final isResentAsNew = row.outcome == resentAsNewOutcome;
    return SilexgisHeldItem(
      section: section,
      entityUuid: row.entityUuid,
      entityTable: row.entityTable,
      wireKind: row.wireKind,
      reviewId: row.reviewId,
      isDelete: row.isDelete,
      sentLocalUpdatedAt: row.sentLocalUpdatedAt,
      heldAt: row.heldAt,
      outcome: isConflict || isDeletedOnServer || isRefused || isResentAsNew
          ? null
          : SyncReviewOutcome.tryParse(row.outcome),
      note: row.note,
      code: row.code,
      decidedAt: row.decidedAt,
      current: json == null
          ? null
          : Map<String, Object?>.from(jsonDecode(json) as Map),
      keptAt: row.keptAt,
      isConflict: isConflict,
      isDeletedOnServer: isDeletedOnServer,
      isRefused: isRefused,
      isResentAsNew: isResentAsNew,
    );
  }
}
