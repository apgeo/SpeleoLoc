import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// What this device knows about one recording or scan on one installation,
/// beyond its revision.
class SilexgisTripState {
  const SilexgisTripState({
    required this.entityUuid,
    required this.recordingUuid,
    this.isScan = false,
    this.received = false,
    this.sent = false,
    this.authorDeviceUserId,
  });

  final Uuid entityUuid;

  /// The recording itself, or the scan's recording.
  final Uuid recordingUuid;
  final bool isScan;

  /// First met by download: another phone made it.
  final bool received;

  /// This device has sent it.
  final bool sent;

  /// The author the installation names, when no user on this device is that
  /// one.
  final String? authorDeviceUserId;
}

/// The device's local-only record of the trip recordings and scans an
/// installation holds — see the `silexgis_trip_entry` table.
class SilexgisTripStateRepository {
  SilexgisTripStateRepository(this._db);

  final AppDatabase _db;

  /// Every entry of one installation, by recording or scan. Read once per run.
  Future<Map<Uuid, SilexgisTripState>> readAll(String profileUuid) async {
    final rows = await (_db.select(
      _db.silexgisTripEntry,
    )..where((t) => t.profileUuid.equals(profileUuid))).get();
    return <Uuid, SilexgisTripState>{
      for (final row in rows) row.entityUuid: _read(row),
    };
  }

  /// The recordings this device received from [profileUuid] and did not make.
  Future<Set<Uuid>> receivedRecordings(String profileUuid) async {
    final rows =
        await (_db.select(_db.silexgisTripEntry)..where(
              (t) =>
                  t.profileUuid.equals(profileUuid) &
                  t.isScan.equals(false) &
                  t.received.equals(true),
            ))
            .get();
    return <Uuid>{for (final row in rows) row.entityUuid};
  }

  /// Records that this device sent these rows. Whatever was known of where
  /// they came from stays.
  Future<void> recordSent(
    String profileUuid,
    Iterable<SilexgisTripState> entries,
  ) async {
    if (entries.isEmpty) return;
    await _db.batch((batch) {
      for (final entry in entries) {
        batch.insert(
          _db.silexgisTripEntry,
          SilexgisTripEntryCompanion.insert(
            profileUuid: profileUuid,
            entityUuid: entry.entityUuid,
            recordingUuid: entry.recordingUuid,
            isScan: Value(entry.isScan),
            sent: const Value(true),
          ),
          onConflict: DoUpdate(
            (_) => const SilexgisTripEntryCompanion(sent: Value(true)),
          ),
        );
      }
    });
  }

  /// Records a row the installation handed down: [received] when this device
  /// first met it there, and the author it names when no user here is that
  /// one. A row already recorded keeps whether it was received or sent.
  Future<void> recordDownloaded(
    String profileUuid,
    SilexgisTripState entry,
  ) async {
    await _db
        .into(_db.silexgisTripEntry)
        .insert(
          SilexgisTripEntryCompanion.insert(
            profileUuid: profileUuid,
            entityUuid: entry.entityUuid,
            recordingUuid: entry.recordingUuid,
            isScan: Value(entry.isScan),
            received: Value(entry.received),
            authorDeviceUserId: Value(entry.authorDeviceUserId),
          ),
          onConflict: DoUpdate(
            (_) => SilexgisTripEntryCompanion(
              authorDeviceUserId: Value(entry.authorDeviceUserId),
            ),
          ),
        );
  }

  /// The scans recorded under [recordingUuid].
  Future<Set<Uuid>> scansOf(String profileUuid, Uuid recordingUuid) async {
    final rows =
        await (_db.select(_db.silexgisTripEntry)..where(
              (t) =>
                  t.profileUuid.equals(profileUuid) &
                  t.recordingUuid.equalsValue(recordingUuid) &
                  t.isScan.equals(true),
            ))
            .get();
    return <Uuid>{for (final row in rows) row.entityUuid};
  }

  /// The installation no longer holds these rows.
  Future<void> forget(String profileUuid, Iterable<Uuid> entityUuids) async {
    if (entityUuids.isEmpty) return;
    await (_db.delete(_db.silexgisTripEntry)..where(
          (t) =>
              t.profileUuid.equals(profileUuid) &
              t.entityUuid.isIn(entityUuids.map((u) => u.bytes)),
        ))
        .go();
  }

  static SilexgisTripState _read(SilexgisTripEntryData row) =>
      SilexgisTripState(
        entityUuid: row.entityUuid,
        recordingUuid: row.recordingUuid,
        isScan: row.isScan,
        received: row.received,
        sent: row.sent,
        authorDeviceUserId: row.authorDeviceUserId,
      );
}
