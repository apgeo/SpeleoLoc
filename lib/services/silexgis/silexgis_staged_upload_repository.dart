import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/clock.dart';

/// Where a documentation file's bytes are on their way to an installation.
enum SilexgisStagedState {
  /// A transfer is open and pieces are still going.
  sending('sending'),

  /// Completed, and waiting for a document row to adopt them.
  staged('staged'),

  /// A document row made them the document's file. The hash is then what the
  /// installation holds for the document.
  adopted('adopted');

  const SilexgisStagedState(this.wireName);
  final String wireName;

  static SilexgisStagedState? tryParse(String? wireName) {
    for (final value in SilexgisStagedState.values) {
      if (value.wireName == wireName) return value;
    }
    return null;
  }
}

/// One file's bytes, as far as they got.
class SilexgisStagedFile {
  const SilexgisStagedFile({
    required this.documentUuid,
    required this.sha256,
    required this.sizeBytes,
    required this.state,
    this.transferId,
    this.receivedBytes = 0,
    this.expiresAt,
  });

  final Uuid documentUuid;
  final String sha256;
  final int sizeBytes;
  final SilexgisStagedState state;
  final String? transferId;
  final int receivedBytes;

  /// The server's stamp, verbatim.
  final String? expiresAt;

  /// Whether [expiresAt] has passed at [now]. A stamp that cannot be read
  /// counts as not passed: the server is asked instead.
  bool expiredAt(DateTime now) {
    final at = DateTime.tryParse(expiresAt ?? '');
    return at != null && !at.isAfter(now);
  }

  SilexgisStagedFile copyWith({
    SilexgisStagedState? state,
    int? receivedBytes,
    String? expiresAt,
  }) => SilexgisStagedFile(
    documentUuid: documentUuid,
    sha256: sha256,
    sizeBytes: sizeBytes,
    state: state ?? this.state,
    transferId: transferId,
    receivedBytes: receivedBytes ?? this.receivedBytes,
    expiresAt: expiresAt ?? this.expiresAt,
  );
}

/// The device's local-only record of file bytes sent ahead of the uploads
/// that name them, per installation.
class SilexgisStagedUploadRepository {
  SilexgisStagedUploadRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  Future<SilexgisStagedFile?> read(
    String profileUuid,
    Uuid documentUuid,
  ) async {
    final row =
        await (_db.select(_db.silexgisStagedUpload)..where(
              (t) =>
                  t.profileUuid.equals(profileUuid) &
                  t.documentUuid.equalsValue(documentUuid),
            ))
            .getSingleOrNull();
    final state = SilexgisStagedState.tryParse(row?.state);
    if (row == null || state == null) return null;
    return SilexgisStagedFile(
      documentUuid: row.documentUuid,
      sha256: row.sha256,
      sizeBytes: row.sizeBytes,
      state: state,
      transferId: row.transferId,
      receivedBytes: row.receivedBytes,
      expiresAt: row.expiresAt,
    );
  }

  /// Every adopted file's hash, by document: what the installation holds.
  Future<Map<Uuid, String>> adoptedHashes(String profileUuid) async {
    final rows =
        await (_db.select(_db.silexgisStagedUpload)..where(
              (t) =>
                  t.profileUuid.equals(profileUuid) &
                  t.state.equals(SilexgisStagedState.adopted.wireName),
            ))
            .get();
    return <Uuid, String>{for (final row in rows) row.documentUuid: row.sha256};
  }

  Future<void> write(String profileUuid, SilexgisStagedFile upload) => _db
      .into(_db.silexgisStagedUpload)
      .insertOnConflictUpdate(
        SilexgisStagedUploadCompanion.insert(
          profileUuid: profileUuid,
          documentUuid: upload.documentUuid,
          sha256: upload.sha256,
          sizeBytes: upload.sizeBytes,
          transferId: Value(upload.transferId),
          receivedBytes: Value(upload.receivedBytes),
          expiresAt: Value(upload.expiresAt),
          state: upload.state.wireName,
          updatedAt: Value(_clock.nowMs()),
        ),
      );

  /// A row adopted the staged bytes named [transferId]: they are the
  /// document's file now. A different transfer, staged since, is left alone.
  Future<void> markAdopted(
    String profileUuid,
    Uuid documentUuid,
    String transferId,
  ) async {
    final upload = await read(profileUuid, documentUuid);
    if (upload == null || upload.transferId != transferId) return;
    await write(
      profileUuid,
      upload.copyWith(state: SilexgisStagedState.adopted),
    );
  }

  Future<void> delete(String profileUuid, Uuid documentUuid) =>
      (_db.delete(_db.silexgisStagedUpload)..where(
            (t) =>
                t.profileUuid.equals(profileUuid) &
                t.documentUuid.equalsValue(documentUuid),
          ))
          .go();
}
