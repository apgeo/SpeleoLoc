import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/geo_json_geometry.dart';
import 'package:speleoloc/services/silexgis/model/sync_feature_row.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';

/// The flat, top-level, prefixed keys a device's identifiers travel under.
///
/// There is no nested `speleoloc` object and one must never be introduced: the
/// web interface renders a typed property bag as form fields and skips
/// anything that is not a primitive, so a nested bag would be stored,
/// validated, synced, and never once shown to the caver who asked to see these
/// codes.
class SpeleolocPropertyKeys {
  const SpeleolocPropertyKeys._();

  static const String pci = 'speleolocPci';
  static const String qcri = 'speleolocQcri';
  static const String caveLocalIndex = 'speleolocCaveLocalIndex';
  static const String generalAreaIdentifier = 'speleolocGeneralAreaIdentifier';
  static const String depthInCave = 'speleolocDepthInCave';
  static const String schemaVersion = 'speleolocSchemaVersion';
}

/// The device's own row-shape version, carried in every property document it
/// writes.
///
/// Deliberately not the local database's schema version: that moves for
/// reasons this document knows nothing about — a new beacon column, a new
/// index — and every such move would rewrite the property document of every
/// row and push the lot back up. This moves only when the shape of what the
/// device puts in a property document changes.
const int kSpeleolocPropertySchemaVersion = 1;

/// The stable code a cave is created under.
///
/// SpeleoLoc has no cave-type concept, so every cave it creates lands as the
/// installation's generic `cave`. The field is read only on a create and is
/// inert afterwards, so somebody correcting the type in the browser is never
/// overwritten by the next upload.
const String kDefaultCaveTypeCode = 'cave';

/// The stable code an entrance is created under, for the same reason.
const String kDefaultEntranceTypeCode = 'natural';

/// The feature type codes this application's own rows map onto.
class SilexgisFeatureTypes {
  const SilexgisFeatureTypes._();

  static const String cavePlace = 'cave_place';
  static const String caveArea = 'cave_area';
  static const String surfaceArea = 'surface_area';
}

/// A cave place plus the two identifiers its property document borrows from
/// rows above it.
///
/// Both are denormalised on purpose. A place's code is assembled from the
/// cave's local index and its area's segment, and the property document is
/// where the caver is shown them; carrying them here keeps that visible on the
/// row somebody actually looks at.
class CavePlaceUpload {
  const CavePlaceUpload({
    required this.place,
    this.caveLocalIndex,
    this.generalAreaIdentifier,
  });

  final CavePlace place;

  /// `caves.cave_local_index` of the cave this place is in.
  final String? caveLocalIndex;

  /// `surface_areas.general_area_identifier` of the cave's surface area.
  final String? generalAreaIdentifier;
}

/// Translates between this application's rows and the wire.
///
/// Pure: it reads no database and writes none, so both directions are testable
/// against the recorded traffic without a harness. Deciding which local row a
/// mapped feature merges into, and writing it, is the applier's job.
class SilexgisFeatureMapper {
  const SilexgisFeatureMapper();

  // ------------------------------------------------------------------ upward

  /// A cave.
  ///
  /// **No geometry, ever.** A cave's own map point is not a field: it is a copy
  /// of its main entrance's, kept in step by the server. A cave that arrives
  /// carrying a point is stored without it rather than refused, so sending one
  /// would be a silent no-op that looks like it worked.
  SyncUploadRow caveRow(
    Cave cave, {
    required String? baseRevision,
    String? parentSurfaceAreaId,
  }) => SyncUploadRow(
    id: cave.uuid.toString(),
    kind: SyncUploadKind.cave,
    baseRevision: baseRevision,
    parentId: parentSurfaceAreaId,
    name: cave.title,
    description: cave.description,
    caveTypeCode: kDefaultCaveTypeCode,
    // A cave's kind carries no schema, so the closed key set does not reach it
    // and these are stored unread. They are still the right place for them:
    // the property document is where a device's own identifiers and codes
    // live, and a local index is exactly that. None of it is locating.
    properties: _properties(<String, Object?>{
      SpeleolocPropertyKeys.caveLocalIndex: cave.caveLocalIndex,
    }),
    clientUpdatedAt: _clientStamp(cave.updatedAt ?? cave.createdAt),
  );

  /// A named surface area. Needs no container, and is what a selection is
  /// rooted in and what a device's general-area segment is allocated from.
  SyncUploadRow surfaceAreaRow(
    SurfaceArea area, {
    required String? baseRevision,
  }) => SyncUploadRow(
    id: area.uuid.toString(),
    kind: SyncUploadKind.generic,
    baseRevision: baseRevision,
    name: area.title,
    description: area.description,
    featureTypeCode: SilexgisFeatureTypes.surfaceArea,
    // Its identifier is one segment of every place code allocated beneath it,
    // so it has to survive a round trip byte for byte or devices re-reading
    // the area renumber their places.
    properties: _properties(<String, Object?>{
      SpeleolocPropertyKeys.generalAreaIdentifier: area.generalAreaIdentifier,
    }),
    clientUpdatedAt: _clientStamp(area.updatedAt ?? area.createdAt),
  );

  /// An area inside a cave. Refused outright without a container, on creation
  /// and on update alike: a row with no ancestors inherits from nothing, so a
  /// rootless one would hand its exact in-cave position — which is the cave's
  /// position — to every caller who can see it at all.
  SyncUploadRow caveAreaRow(
    CaveArea area, {
    required String? baseRevision,
    required String parentCaveId,
  }) => SyncUploadRow(
    id: area.uuid.toString(),
    kind: SyncUploadKind.generic,
    baseRevision: baseRevision,
    parentId: parentCaveId,
    name: area.title,
    description: area.description,
    featureTypeCode: SilexgisFeatureTypes.caveArea,
    clientUpdatedAt: _clientStamp(area.updatedAt ?? area.createdAt),
  );

  /// A cave place, which becomes an entrance or a place inside the cave
  /// depending on the row's own `is_entrance` flag.
  ///
  /// The container is the cave area when the place names one, and the cave
  /// itself otherwise — containment is the only structure the server derives
  /// anything from, protection in particular.
  SyncUploadRow cavePlaceRow(
    CavePlaceUpload upload, {
    required String? baseRevision,
    required String parentId,
  }) {
    final place = upload.place;
    final isEntrance = place.isEntrance != 0;
    final latitude = place.latitude;
    final longitude = place.longitude;

    return SyncUploadRow(
      id: place.uuid.toString(),
      kind: isEntrance ? SyncUploadKind.caveEntrance : SyncUploadKind.generic,
      baseRevision: baseRevision,
      parentId: parentId,
      name: place.title,
      description: place.description,
      featureTypeCode: isEntrance ? null : SilexgisFeatureTypes.cavePlace,
      entranceTypeCode: isEntrance ? kDefaultEntranceTypeCode : null,
      isMain: isEntrance && place.isMainEntrance != 0,
      geometry: latitude == null || longitude == null
          ? null
          : GeoJsonGeometry.point(latitude: latitude, longitude: longitude),
      // Kept on an entrance only, where the server stores it; on a generic
      // kind it is accepted and discarded. Sending it regardless costs nothing
      // and stops being a loss if that is ever fixed.
      altitude: place.altitude,
      properties: _properties(<String, Object?>{
        SpeleolocPropertyKeys.pci: place.placeCodeIdentifier,
        SpeleolocPropertyKeys.qcri: place.qrCodeResourceIdentifier,
        SpeleolocPropertyKeys.caveLocalIndex: upload.caveLocalIndex,
        SpeleolocPropertyKeys.generalAreaIdentifier:
            upload.generalAreaIdentifier,
        SpeleolocPropertyKeys.depthInCave: place.depthInCave,
      }),
      clientUpdatedAt: _clientStamp(place.updatedAt ?? place.createdAt),
    );
  }

  /// A row going away. Arbitrated on its revision exactly as an edit is, and
  /// carrying nothing else.
  SyncUploadRow deleteRow({
    required Uuid entityUuid,
    required SyncUploadKind kind,
    required String baseRevision,
  }) => SyncUploadRow.delete(
    id: entityUuid.toString(),
    kind: kind,
    baseRevision: baseRevision,
  );

  // ---------------------------------------------------------------- downward

  /// Reads a downloaded row into whichever local shape it belongs to.
  ///
  /// A kind or a type code this build has never heard of yields
  /// [UnmappedFeature] rather than an error: an installation's taxonomy grows
  /// without a contract change, and a selection carries everything under its
  /// roots, of every kind — a surveyed centerline included.
  MappedFeature read(SyncFeatureRow row) {
    switch (row.kind) {
      case SilexgisKinds.cave:
        return MappedCave(
          row: row,
          title: row.name,
          description: row.description,
          caveLocalIndex: _string(
            row.properties[SpeleolocPropertyKeys.caveLocalIndex],
          ),
        );

      case SilexgisKinds.caveEntrance:
        return _readPlace(row, isEntrance: true);

      case SilexgisKinds.generic:
        switch (row.featureTypeCode) {
          case SilexgisFeatureTypes.cavePlace:
            return _readPlace(row, isEntrance: false);
          case SilexgisFeatureTypes.caveArea:
            return MappedCaveArea(
              row: row,
              title: row.name,
              description: row.description,
            );
          case SilexgisFeatureTypes.surfaceArea:
            return MappedSurfaceArea(
              row: row,
              title: row.name,
              description: row.description,
              generalAreaIdentifier: _string(
                row.properties[SpeleolocPropertyKeys.generalAreaIdentifier],
              ),
            );
        }
    }
    return UnmappedFeature(row: row);
  }

  MappedCavePlace _readPlace(SyncFeatureRow row, {required bool isEntrance}) {
    final geometry = row.geometry;
    return MappedCavePlace(
      row: row,
      title: row.name,
      description: row.description,
      isEntrance: isEntrance,
      latitude: geometry?.latitude,
      longitude: geometry?.longitude,
      // The wire row has no altitude member. A point's third ordinate is the
      // only place one comes back, and only on an entrance.
      altitude: geometry?.altitude,
      placeCodeIdentifier: _string(row.properties[SpeleolocPropertyKeys.pci]),
      qrCodeResourceIdentifier: _string(
        row.properties[SpeleolocPropertyKeys.qcri],
      ),
      depthInCave: _number(row.properties[SpeleolocPropertyKeys.depthInCave]),
    );
  }

  // ---------------------------------------------------------------- plumbing

  /// Drops absent values and stamps the device's row-shape version.
  ///
  /// **Nothing locating may be added to this.** The document is emitted
  /// verbatim to every reader that can see the row, with no protection filter
  /// anywhere on its path — including a reader for whom the geometry was just
  /// withheld. On `cave_place` and `surface_area` an undeclared key is refused;
  /// on every other kind here there is no schema, so a coordinate would be
  /// accepted silently and published. The rule is this client's alone.
  Map<String, Object?> _properties(Map<String, Object?> values) =>
      <String, Object?>{
        for (final entry in values.entries)
          if (entry.value != null) entry.key: entry.value,
        SpeleolocPropertyKeys.schemaVersion: kSpeleolocPropertySchemaVersion,
      };

  /// The device's belief about when it last wrote the row, as provenance. It
  /// never decides which write the server keeps — a phone's clock is
  /// unsynchronised, resettable by whoever holds it and routinely wrong by
  /// hours.
  String? _clientStamp(int? epochMs) => epochMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          epochMs,
          isUtc: true,
        ).toIso8601String();

  static String? _string(Object? value) => value is String ? value : null;
  static double? _number(Object? value) =>
      value is num ? value.toDouble() : null;
}

/// A downloaded row, read into the local shape it belongs to.
sealed class MappedFeature {
  const MappedFeature({required this.row});

  final SyncFeatureRow row;

  /// The identifier, which is the same on both sides.
  Uuid? get uuid => Uuid.tryParse(row.id);

  /// The container this row hangs under, or null when the caller may read none
  /// of its parents — which is not the same as having none.
  Uuid? get parentUuid => Uuid.tryParse(row.primaryParent?.parentId ?? '');
}

class MappedCave extends MappedFeature {
  const MappedCave({
    required super.row,
    required this.title,
    required this.description,
    required this.caveLocalIndex,
  });

  final String? title;
  final String? description;
  final String? caveLocalIndex;
}

class MappedCavePlace extends MappedFeature {
  const MappedCavePlace({
    required super.row,
    required this.title,
    required this.description,
    required this.isEntrance,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.placeCodeIdentifier,
    required this.qrCodeResourceIdentifier,
    required this.depthInCave,
  });

  final String? title;
  final String? description;
  final bool isEntrance;

  /// **There is no main-entrance flag here.** A downloaded row carries no
  /// `isMain`: what encodes it on the server is that a cave's own map point is
  /// a copy of its main entrance's, and the row does not restate that. So the
  /// device keeps whatever it decided locally rather than inferring an answer
  /// by comparing coordinates, which would be re-deriving a rule from what the
  /// server happens to do.
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final String? placeCodeIdentifier;
  final String? qrCodeResourceIdentifier;
  final double? depthInCave;
}

class MappedCaveArea extends MappedFeature {
  const MappedCaveArea({
    required super.row,
    required this.title,
    required this.description,
  });

  final String? title;
  final String? description;
}

class MappedSurfaceArea extends MappedFeature {
  const MappedSurfaceArea({
    required super.row,
    required this.title,
    required this.description,
    required this.generalAreaIdentifier,
  });

  final String? title;
  final String? description;
  final String? generalAreaIdentifier;
}

/// A row of a kind or type code this build does not model.
///
/// Stored nowhere and dropped, which is safe **only** because this client
/// never derives deletions from what the server holds: a tombstone goes up
/// only for a row the local change log says was deleted here. A client that
/// diffed the server's rows against its own would delete every one of these on
/// its next upload.
class UnmappedFeature extends MappedFeature {
  const UnmappedFeature({required super.row});

  String get kind => row.kind;
  String? get featureTypeCode => row.featureTypeCode;
}
