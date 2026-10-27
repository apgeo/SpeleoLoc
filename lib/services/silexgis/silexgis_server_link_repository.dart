import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/clock.dart';

/// One document link an installation holds.
class SilexgisServerLinkEntry {
  const SilexgisServerLinkEntry({
    required this.documentUuid,
    required this.targetKind,
    required this.targetId,
    this.linkId,
  });

  final Uuid documentUuid;

  /// `feature`, `tripRecording` or `tripPoint`, as the link travels.
  final String targetKind;
  final Uuid targetId;

  /// The installation's identifier for the link, once it has named one.
  final String? linkId;

  SilexgisLinkKey get key => (documentUuid, targetId);
}

/// A link is named by its document and its target together.
typedef SilexgisLinkKey = (Uuid document, Uuid target);

/// The device's local-only record of which document links an installation
/// holds.
///
/// It is what tells a link the caver removed here — the local row is gone and
/// the entry is not — from one that was never on the server, which is the only
/// way a removal can still be sent once the row itself no longer exists.
class SilexgisServerLinkRepository {
  SilexgisServerLinkRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  Future<Map<SilexgisLinkKey, SilexgisServerLinkEntry>> readAll(
    String profileUuid,
  ) async {
    final rows = await (_db.select(
      _db.silexgisServerLink,
    )..where((t) => t.profileUuid.equals(profileUuid))).get();
    return <SilexgisLinkKey, SilexgisServerLinkEntry>{
      for (final row in rows)
        (row.documentUuid, row.targetId): SilexgisServerLinkEntry(
          documentUuid: row.documentUuid,
          targetKind: row.targetKind,
          targetId: row.targetId,
          linkId: row.linkId,
        ),
    };
  }

  Future<void> record(String profileUuid, SilexgisServerLinkEntry entry) => _db
      .into(_db.silexgisServerLink)
      .insertOnConflictUpdate(
        SilexgisServerLinkCompanion.insert(
          profileUuid: profileUuid,
          documentUuid: entry.documentUuid,
          targetKind: entry.targetKind,
          targetId: entry.targetId,
          linkId: Value(entry.linkId),
          updatedAt: Value(_clock.nowMs()),
        ),
      );

  /// The installation no longer holds these links.
  Future<void> forget(
    String profileUuid,
    Iterable<SilexgisLinkKey> keys,
  ) async {
    for (final (document, target) in keys) {
      await (_db.delete(_db.silexgisServerLink)..where(
            (t) =>
                t.profileUuid.equals(profileUuid) &
                t.documentUuid.equalsValue(document) &
                t.targetId.equalsValue(target),
          ))
          .go();
    }
  }
}
