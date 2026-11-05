import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';

// The pieces of a delete that reach beyond the deleted row. Sync carries a
// deletion row by row, through the change log, so every row a cascade removes
// is logged as a delete and every row it detaches as an edit. A row removed
// here without a tombstone would stay on peers, still pointing at a parent
// they no longer have. Each helper runs inside the caller's transaction,
// before the parent row goes.

/// Removes [trips] together with the points recorded on them and the
/// documents linked to either.
Future<void> deleteTripsWithChildren(
  AppDatabase db,
  ChangeLogger logger,
  List<CaveTrip> trips,
) async {
  if (trips.isEmpty) return;
  final tripIds = <Uuid>[for (final t in trips) t.uuid];
  final points = await (db.select(
    db.caveTripPoints,
  )..where((p) => p.caveTripUuid.isInValues(tripIds))).get();
  final pointIds = <Uuid>[for (final p in points) p.uuid];
  final tripLinks = await (db.select(
    db.documentationFilesToCaveTrips,
  )..where((l) => l.caveTripUuid.isInValues(tripIds))).get();
  final pointLinks = pointIds.isEmpty
      ? const <DocumentationFilesToCaveTripPoint>[]
      : await (db.select(
          db.documentationFilesToCaveTripPoints,
        )..where((l) => l.caveTripPointUuid.isInValues(pointIds))).get();

  // The links reference the points and the trips, and the points the trips.
  if (pointIds.isNotEmpty) {
    await (db.delete(
      db.documentationFilesToCaveTripPoints,
    )..where((l) => l.caveTripPointUuid.isInValues(pointIds))).go();
  }
  await (db.delete(
    db.documentationFilesToCaveTrips,
  )..where((l) => l.caveTripUuid.isInValues(tripIds))).go();
  await (db.delete(
    db.caveTripPoints,
  )..where((p) => p.caveTripUuid.isInValues(tripIds))).go();
  await (db.delete(
    db.caveTrips,
  )..where((t) => t.uuid.isInValues(tripIds))).go();

  for (final t in trips) {
    await logger.logDelete(
      'cave_trips',
      t.uuid,
      oldValues: {'title': t.title, 'cave_uuid': t.caveUuid},
    );
  }
  for (final p in points) {
    await logger.logDelete(
      'cave_trip_points',
      p.uuid,
      oldValues: {
        'cave_trip_uuid': p.caveTripUuid,
        'cave_place_uuid': p.cavePlaceUuid,
      },
    );
  }
  for (final l in tripLinks) {
    await logger.logDelete(
      'documentation_files_to_cave_trips',
      l.uuid,
      oldValues: {
        'documentation_file_uuid': l.documentationFileUuid,
        'cave_trip_uuid': l.caveTripUuid,
      },
    );
  }
  for (final l in pointLinks) {
    await logger.logDelete(
      'documentation_files_to_cave_trip_points',
      l.uuid,
      oldValues: {
        'documentation_file_uuid': l.documentationFileUuid,
        'cave_trip_point_uuid': l.caveTripPointUuid,
      },
    );
  }
}

/// Detaches the trip points recorded at [placeUuids]: the visit still
/// happened, so a point outlives its place. Each point is stamped and logged
/// as an edit, so peers detach the same points rather than keep them
/// pointing at a place they no longer have.
Future<void> detachTripPointsFromPlaces(
  AppDatabase db,
  ChangeLogger logger, {
  required List<Uuid> placeUuids,
  required int now,
  required Uuid? author,
}) async {
  if (placeUuids.isEmpty) return;
  final points = await (db.select(
    db.caveTripPoints,
  )..where((p) => p.cavePlaceUuid.isInValues(placeUuids))).get();
  for (final p in points) {
    await (db.update(
      db.caveTripPoints,
    )..where((t) => t.uuid.equalsValue(p.uuid))).write(
      CaveTripPointsCompanion(
        cavePlaceUuid: const Value(null),
        updatedAt: Value(now),
        lastModifiedByUserUuid: Value(author),
      ),
    );
    await logger.logUpdate(
      'cave_trip_points',
      p.uuid,
      oldValues: {'cave_place_uuid': p.cavePlaceUuid},
      newValues: {'cave_place_uuid': null},
    );
  }
}

/// Removes the pins of [placeUuids] on any map, and every pin on [mapUuids].
Future<void> deletePlaceMapDefinitions(
  AppDatabase db,
  ChangeLogger logger, {
  List<Uuid> placeUuids = const <Uuid>[],
  List<Uuid> mapUuids = const <Uuid>[],
}) async {
  if (placeUuids.isEmpty && mapUuids.isEmpty) return;
  Expression<bool> filter(CavePlaceToRasterMapDefinitions d) => [
    if (placeUuids.isNotEmpty) d.cavePlaceUuid.isInValues(placeUuids),
    if (mapUuids.isNotEmpty) d.rasterMapUuid.isInValues(mapUuids),
  ].reduce((a, b) => a | b);
  final pins = await (db.select(
    db.cavePlaceToRasterMapDefinitions,
  )..where(filter)).get();
  await (db.delete(db.cavePlaceToRasterMapDefinitions)..where(filter)).go();
  for (final pin in pins) {
    await logger.logDelete(
      'cave_place_to_raster_map_definitions',
      pin.uuid,
      oldValues: {
        'cave_place_uuid': pin.cavePlaceUuid,
        'raster_map_uuid': pin.rasterMapUuid,
        'x_coordinate': pin.xCoordinate,
        'y_coordinate': pin.yCoordinate,
      },
    );
  }
}

/// Removes the documents' links to the [ids] of one kind of feature. These
/// links name their feature without a foreign key, so nothing else would
/// remove them, here or on a peer.
Future<void> deleteGeofeatureLinks(
  AppDatabase db,
  ChangeLogger logger,
  GeofeatureType type,
  List<Uuid> ids,
) async {
  if (ids.isEmpty) return;
  Expression<bool> filter(DocumentationFilesToGeofeatures g) =>
      g.geofeatureType.equals(type.dbValue) & g.geofeatureUuid.isInValues(ids);
  final links = await (db.select(
    db.documentationFilesToGeofeatures,
  )..where(filter)).get();
  await (db.delete(db.documentationFilesToGeofeatures)..where(filter)).go();
  for (final l in links) {
    await logger.logDelete(
      'documentation_files_to_geofeatures',
      l.uuid,
      oldValues: {
        'documentation_file_uuid': l.documentationFileUuid,
        'geofeature_uuid': l.geofeatureUuid,
        'geofeature_type': l.geofeatureType,
      },
    );
  }
}
