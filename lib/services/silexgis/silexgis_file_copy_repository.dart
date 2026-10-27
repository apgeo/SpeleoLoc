import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/clock.dart';

/// What a documentation file on this device is a copy of.
enum SilexgisHeldAs {
  /// The caver's own file, made or picked on a device.
  own('own'),

  /// The server's stored file, byte for byte.
  original('original'),

  /// The whole picture, rewritten by the server without its location data.
  locationFree('locationFree'),

  /// A picture the server drew of the file, at one of its fixed sizes.
  rendition('rendition');

  const SilexgisHeldAs(this.wireName);
  final String wireName;

  /// Copies that are not the file itself. They stay on the device that fetched
  /// them: another device gets the real file from the server, or nothing.
  static const Set<SilexgisHeldAs> serverOnlyCopies = <SilexgisHeldAs>{
    locationFree,
    rendition,
  };

  static SilexgisHeldAs? tryParse(String? wireName) {
    for (final value in SilexgisHeldAs.values) {
      if (value.wireName == wireName) return value;
    }
    return null;
  }
}

/// Where a copy came from.
enum SilexgisCopyOrigin {
  device('device'),
  archive('archive'),
  server('server');

  const SilexgisCopyOrigin(this.wireName);
  final String wireName;

  static SilexgisCopyOrigin? tryParse(String? wireName) {
    for (final value in SilexgisCopyOrigin.values) {
      if (value.wireName == wireName) return value;
    }
    return null;
  }
}

/// One file's entry in the register.
class SilexgisFileCopyEntry {
  const SilexgisFileCopyEntry({
    required this.documentUuid,
    required this.heldAs,
    required this.origin,
    this.versionId,
    this.rendition,
  });

  final Uuid documentUuid;
  final SilexgisHeldAs heldAs;
  final SilexgisCopyOrigin origin;

  /// The server revision of the bytes this copy was made from.
  final String? versionId;

  /// The picture's size, for a [SilexgisHeldAs.rendition].
  final int? rendition;
}

/// The register of documentation files that are copies the server handed
/// down, and of what each is.
///
/// A file with no entry is the caver's own. The register is about the files on
/// this device, not about any one installation, so it outlives a profile.
class SilexgisFileCopyRepository {
  SilexgisFileCopyRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  Future<void> register(SilexgisFileCopyEntry copy) => _db
      .into(_db.silexgisFileCopy)
      .insertOnConflictUpdate(
        SilexgisFileCopyCompanion.insert(
          documentUuid: copy.documentUuid,
          versionId: Value(copy.versionId),
          heldAs: copy.heldAs.wireName,
          rendition: Value(copy.rendition),
          origin: copy.origin.wireName,
          recordedAt: Value(_clock.nowMs()),
        ),
      );

  /// The documentation files that are server copies other than the file
  /// itself — see [SilexgisHeldAs.serverOnlyCopies]. They stay out of
  /// device-to-device archives, with their links and their change history.
  Future<Set<Uuid>> serverOnlyCopies() async {
    final rows =
        await (_db.select(_db.silexgisFileCopy)..where(
              (t) => t.heldAs.isIn(
                SilexgisHeldAs.serverOnlyCopies.map((h) => h.wireName),
              ),
            ))
            .get();
    return <Uuid>{for (final row in rows) row.documentUuid};
  }

  /// Re-registers each server copy that an archive has just replaced.
  ///
  /// [archiveFiles] is the archive's documentation files, as identifier to
  /// stored file name. Archives never carry a copy without location or a
  /// drawn picture, so a row that now names the archive's file holds what a
  /// device made or picked: it is recorded as such, keeping the server
  /// revision this device last knew for the document. A copy the archive did
  /// not replace keeps its entry. Returns how many entries changed.
  Future<int> adoptArchiveFiles(Map<Uuid, String> archiveFiles) async {
    if (archiveFiles.isEmpty) return 0;
    var adopted = 0;
    for (final id in await serverOnlyCopies()) {
      final archived = archiveFiles[id];
      if (archived == null) continue;
      final row = await (_db.select(
        _db.documentationFiles,
      )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();
      if (row == null || row.fileName != archived) continue;
      final entry = await read(id);
      await register(
        SilexgisFileCopyEntry(
          documentUuid: id,
          heldAs: SilexgisHeldAs.own,
          origin: SilexgisCopyOrigin.archive,
          versionId: entry?.versionId,
        ),
      );
      adopted++;
    }
    return adopted;
  }

  /// The entry for [documentUuid], or null for the caver's own file.
  Future<SilexgisFileCopyEntry?> read(Uuid documentUuid) async {
    final row =
        await (_db.select(_db.silexgisFileCopy)
              ..where((t) => t.documentUuid.equalsValue(documentUuid)))
            .getSingleOrNull();
    if (row == null) return null;
    final heldAs = SilexgisHeldAs.tryParse(row.heldAs);
    final origin = SilexgisCopyOrigin.tryParse(row.origin);
    if (heldAs == null || origin == null) return null;
    return SilexgisFileCopyEntry(
      documentUuid: row.documentUuid,
      heldAs: heldAs,
      origin: origin,
      versionId: row.versionId,
      rendition: row.rendition,
    );
  }
}
