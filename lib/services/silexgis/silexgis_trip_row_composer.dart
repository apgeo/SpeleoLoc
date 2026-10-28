import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_trips.dart';

/// Turns a local recording or scan into the item that goes up.
///
/// The author is the row's own: a user of this device, or nobody. A recording
/// read from another phone keeps its foreign key null and the installation's
/// author in local-only state, so its edit names no author and the one the
/// installation holds stands.
class SilexgisTripRowComposer {
  const SilexgisTripRowComposer();

  SyncUploadTripRecording recording(CaveTrip trip, {String? baseRevision}) =>
      SyncUploadTripRecording(
        id: trip.uuid.toString(),
        baseRevision: baseRevision,
        caveId: trip.caveUuid.toString(),
        title: trip.title,
        description: trip.description,
        log: trip.log,
        startedAt: iso(trip.tripStartedAt),
        endedAt: trip.tripEndedAt == null ? null : iso(trip.tripEndedAt!),
        createdByDeviceUserId: trip.createdByUserUuid?.toString(),
        clientUpdatedAt: switch (trip.updatedAt ?? trip.createdAt) {
          final int ms => iso(ms),
          null => null,
        },
      );

  SyncUploadTripPoint scan(CaveTripPoint point, {String? baseRevision}) =>
      SyncUploadTripPoint(
        id: point.uuid.toString(),
        recordingId: point.caveTripUuid.toString(),
        baseRevision: baseRevision,
        placeId: point.cavePlaceUuid?.toString(),
        scannedAt: iso(point.scannedAt),
        notes: point.notes,
        createdByDeviceUserId: point.createdByUserUuid?.toString(),
      );

  /// A local epoch-millisecond stamp as the wire states a moment.
  static String iso(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();
}
