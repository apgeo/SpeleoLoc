import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_missing_item_rule.dart';
import 'package:speleoloc/services/silexgis/silexgis_picture_frame.dart';

/// The local tables the raster sections come from.
abstract final class SilexgisRasterTables {
  static const String maps = 'raster_maps';
  static const String pins = 'cave_place_to_raster_map_definitions';
}

/// What this device knows about one raster map or pin on one installation,
/// beyond its revision.
class SilexgisRasterState implements SilexgisItemHistory {
  const SilexgisRasterState({
    required this.entityUuid,
    required this.mapUuid,
    this.isPin = false,
    this.received = false,
    this.sent = false,
    this.documentId,
    this.pictureVersion,
    this.pictureSha256,
    this.areaId,
    this.pictureFrame = const SilexgisPictureFrame(),
    this.fetchedMirrored,
    this.fetchedTurn,
  });

  final Uuid entityUuid;

  /// The map itself, or the pin's map.
  final Uuid mapUuid;
  final bool isPin;

  @override
  final bool received;

  @override
  final bool sent;

  /// The installation's document holding the map's picture.
  final Uuid? documentId;

  /// The catalogue's revision of the picture this device holds, when known.
  final String? pictureVersion;

  /// The hash of the local picture that stands for the installation's
  /// current one. Null while the picture is still to fetch.
  final String? pictureSha256;

  /// An area the installation names that this device does not hold.
  final Uuid? areaId;

  /// What the installation says of a map's picture as it stores it.
  final SilexgisPictureFrame pictureFrame;

  /// The flip and turn the held picture was fetched under; null where the
  /// installation had not said, and for a picture this device sent.
  final bool? fetchedMirrored;
  final int? fetchedTurn;
}

/// The device's local-only record of the raster maps and pins an
/// installation holds — see the `silexgis_raster_entry` table.
class SilexgisRasterStateRepository {
  SilexgisRasterStateRepository(this._db);

  final AppDatabase _db;

  /// Every entry of one installation, by map or pin. Read once per run.
  Future<Map<Uuid, SilexgisRasterState>> readAll(String profileUuid) async {
    final rows = await (_db.select(
      _db.silexgisRasterEntry,
    )..where((t) => t.profileUuid.equals(profileUuid))).get();
    return <Uuid, SilexgisRasterState>{
      for (final row in rows) row.entityUuid: _read(row),
    };
  }

  /// Records that this device sent these rows. A map whose picture went with
  /// it names the hash of what was sent, which is now the installation's
  /// current picture; its catalogue revision is not known until read.
  Future<void> recordSent(
    String profileUuid,
    Iterable<SilexgisRasterState> entries,
  ) async {
    if (entries.isEmpty) return;
    await _db.batch((batch) {
      for (final entry in entries) {
        final picture = entry.pictureSha256;
        batch.insert(
          _db.silexgisRasterEntry,
          SilexgisRasterEntryCompanion.insert(
            profileUuid: profileUuid,
            entityUuid: entry.entityUuid,
            mapUuid: entry.mapUuid,
            isPin: Value(entry.isPin),
            sent: const Value(true),
            pictureSha256: Value(picture),
          ),
          onConflict: DoUpdate(
            (_) => picture == null
                ? const SilexgisRasterEntryCompanion(sent: Value(true))
                : SilexgisRasterEntryCompanion(
                    sent: const Value(true),
                    pictureSha256: Value(picture),
                    pictureVersion: const Value(null),
                  ),
          ),
        );
      }
    });
  }

  /// Records a row the installation handed down: [SilexgisRasterState.received]
  /// when this device first met it there, the picture's document with what
  /// the installation says of it, and an area it does not hold. A row already
  /// recorded keeps whether it was received or sent, and which picture it
  /// holds.
  Future<void> recordDownloaded(
    String profileUuid,
    SilexgisRasterState entry,
  ) async {
    final frame = entry.pictureFrame;
    await _db
        .into(_db.silexgisRasterEntry)
        .insert(
          SilexgisRasterEntryCompanion.insert(
            profileUuid: profileUuid,
            entityUuid: entry.entityUuid,
            mapUuid: entry.mapUuid,
            isPin: Value(entry.isPin),
            received: Value(entry.received),
            documentId: Value(entry.documentId),
            areaId: Value(entry.areaId),
          ).copyWith(
            pictureWidth: Value(frame.width),
            pictureHeight: Value(frame.height),
            pictureMirrored: Value(frame.mirrored),
            pictureTurn: Value(frame.turn),
          ),
          onConflict: DoUpdate(
            (_) => SilexgisRasterEntryCompanion(
              documentId: Value(entry.documentId),
              areaId: Value(entry.areaId),
              pictureWidth: Value(frame.width),
              pictureHeight: Value(frame.height),
              pictureMirrored: Value(frame.mirrored),
              pictureTurn: Value(frame.turn),
            ),
          ),
        );
  }

  /// Records which local picture stands for the installation's: the bytes
  /// fetched for [mapUuid], or the catalogue revision of bytes it sent.
  ///
  /// [fetchedUnder] is the frame the map had when the bytes were fetched —
  /// only its flip and turn are kept. It is left out when no bytes were
  /// fetched, so what an earlier fetch recorded stays.
  Future<void> recordPicture(
    String profileUuid,
    Uuid mapUuid, {
    required String sha256,
    String? version,
    SilexgisPictureFrame? fetchedUnder,
  }) async {
    await (_db.update(_db.silexgisRasterEntry)..where(
          (t) =>
              t.profileUuid.equals(profileUuid) &
              t.entityUuid.equalsValue(mapUuid),
        ))
        .write(
          SilexgisRasterEntryCompanion(
            pictureSha256: Value(sha256),
            pictureVersion: Value(version),
            fetchedMirrored: fetchedUnder == null
                ? const Value.absent()
                : Value(fetchedUnder.mirrored),
            fetchedTurn: fetchedUnder == null
                ? const Value.absent()
                : Value(fetchedUnder.turn),
          ),
        );
  }

  /// The pins recorded on [mapUuid].
  Future<Set<Uuid>> pinsOf(String profileUuid, Uuid mapUuid) async {
    final rows =
        await (_db.select(_db.silexgisRasterEntry)..where(
              (t) =>
                  t.profileUuid.equals(profileUuid) &
                  t.mapUuid.equalsValue(mapUuid) &
                  t.isPin.equals(true),
            ))
            .get();
    return <Uuid>{for (final row in rows) row.entityUuid};
  }

  /// The installation no longer holds these rows.
  Future<void> forget(String profileUuid, Iterable<Uuid> entityUuids) async {
    if (entityUuids.isEmpty) return;
    await (_db.delete(_db.silexgisRasterEntry)..where(
          (t) =>
              t.profileUuid.equals(profileUuid) &
              t.entityUuid.isIn(entityUuids.map((u) => u.bytes)),
        ))
        .go();
  }

  static SilexgisRasterState _read(SilexgisRasterEntryData row) =>
      SilexgisRasterState(
        entityUuid: row.entityUuid,
        mapUuid: row.mapUuid,
        isPin: row.isPin,
        received: row.received,
        sent: row.sent,
        documentId: row.documentId,
        pictureVersion: row.pictureVersion,
        pictureSha256: row.pictureSha256,
        areaId: row.areaId,
        pictureFrame: SilexgisPictureFrame(
          width: row.pictureWidth,
          height: row.pictureHeight,
          mirrored: row.pictureMirrored,
          turn: row.pictureTurn,
        ),
        fetchedMirrored: row.fetchedMirrored,
        fetchedTurn: row.fetchedTurn,
      );
}
