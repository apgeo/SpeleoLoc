import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/clock.dart';

/// A picture that was read before: its label's raw text, or null when it
/// had none.
class CachedQrRead {
  const CachedQrRead(this.payload);

  final String? payload;
}

/// Remembers what reading each device picture for a QR label found, keyed
/// by [TripMediaSource.scanKey], so the points-from-pictures screen does not
/// decode the same pictures every time it opens.
///
/// Local to this device and never logged as a change: the keys identify
/// pictures here and nowhere else.
class MediaScanCache {
  MediaScanCache(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  /// What [mediaKey] was found to hold, or null when it was never read.
  Future<CachedQrRead?> read(String mediaKey) async {
    final row = await (_db.select(
      _db.mediaQrScanCache,
    )..where((t) => t.mediaKey.equals(mediaKey))).getSingleOrNull();
    return row == null ? null : CachedQrRead(row.qrPayload);
  }

  /// Records that [mediaKey] holds [payload] — null for no label.
  Future<void> write(String mediaKey, String? payload) async {
    await _db
        .into(_db.mediaQrScanCache)
        .insertOnConflictUpdate(
          MediaQrScanCacheCompanion.insert(
            mediaKey: mediaKey,
            qrPayload: Value(payload),
            scannedAt: _clock.nowMs(),
          ),
        );
  }
}
