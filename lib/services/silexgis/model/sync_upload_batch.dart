import 'package:speleoloc/services/silexgis/model/geo_json_geometry.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';

/// The `kind` values an upload may carry.
///
/// A closed set, unlike the kind of a downloaded row: anything else is
/// answered `rejected` / `sync.kind_unsupported`. A `centerline` exists in the
/// field's type and is deliberately not carried by this contract.
enum SyncUploadKind {
  cave('cave'),
  caveEntrance('caveEntrance'),
  generic('generic');

  const SyncUploadKind(this.wireName);
  final String wireName;
}

/// How a position was obtained. Sent beside the geometry, and dropped with it
/// when the caller may not set this row's position.
enum PositionQuality {
  unknown('unknown'),
  gps('gps'),
  map('map'),
  estimated('estimated');

  const PositionQuality(this.wireName);
  final String wireName;
}

/// One row going up.
///
/// **Every row carries [name], [description] and [properties] whether or not
/// they changed**, and that is a deliberate departure from the partial write
/// the protocol describes. Two reasons, one of them a defect this server has
/// today (see `found-defects.md`): omitting a text field clears it. The other
/// is that sending them is sound regardless — the row states the
/// [baseRevision] the device last read, so a server that has moved on refuses
/// the row rather than taking the device's older text. It is a compare-and-set
/// on the fields the device owns, not a blind overwrite.
class SyncUploadRow {
  const SyncUploadRow({
    required this.id,
    required this.kind,
    required this.baseRevision,
    this.deleted = false,
    this.parentId,
    this.name,
    this.description,
    this.featureTypeCode,
    this.caveTypeCode,
    this.entranceTypeCode,
    this.isMain = false,
    this.geometry,
    this.altitude,
    this.positionQuality,
    this.properties = const <String, Object?>{},
    this.clientUpdatedAt,
  });

  /// A tombstone going up. Arbitrated on [baseRevision] exactly as an edit is,
  /// and carrying nothing else: the row is being removed, so none of its
  /// content is a statement worth making.
  const SyncUploadRow.delete({
    required this.id,
    required this.kind,
    required this.baseRevision,
  }) : deleted = true,
       parentId = null,
       name = null,
       description = null,
       featureTypeCode = null,
       caveTypeCode = null,
       entranceTypeCode = null,
       isMain = false,
       geometry = null,
       altitude = null,
       positionQuality = null,
       properties = const <String, Object?>{},
       clientUpdatedAt = null;

  /// The device's own identifier, adopted verbatim. Never re-key a row: an
  /// identifier already in use by a row this account may not read is answered
  /// `sync.id_conflict`, and re-keying is what a translation table is, which
  /// this contract exists without.
  final String id;

  final SyncUploadKind kind;

  /// The `updatedAt` the device last saw for this row, or null for a new row.
  /// The only thing arbitrated on — never the device's own clock.
  final String? baseRevision;

  final bool deleted;

  /// The container. A request, not a declaration: the server makes the edge,
  /// and it is read only when the row is **new**. On an existing row it is
  /// inert, so a row sent with a different container comes back `updated`
  /// while the edge stays where it was.
  final String? parentId;

  /// At most 255 characters.
  final String? name;
  final String? description;

  /// The kind, by its stable code, never by a numeric id. Read only on a
  /// create.
  final String? featureTypeCode;
  final String? caveTypeCode;
  final String? entranceTypeCode;

  /// For an entrance: whether it is the cave's main one, which is what the
  /// cave's own map point follows.
  final bool isMain;

  final GeoJsonGeometry? geometry;
  final double? altitude;
  final PositionQuality? positionQuality;

  /// The device's own identifiers and codes. **No coordinate may ever go in
  /// here**: the document is handed to every reader of the row with no
  /// protection filter anywhere on its path, and for every kind on this
  /// channel except `cave_place` and `surface_area` there is no schema to
  /// refuse one either.
  final Map<String, Object?> properties;

  /// When the device believes it last wrote the row. Stored as provenance and
  /// never consulted in the arbitration.
  final String? clientUpdatedAt;

  bool get isNew => baseRevision == null;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'kind': kind.wireName,
      'baseRevision': baseRevision,
      'deleted': deleted,
      'isMain': isMain,
    };
    if (deleted) return json;

    json['name'] = name;
    json['description'] = description;
    json['properties'] = properties;

    // Read only on a create, and inert on an update — so sent only where the
    // server will look at them, rather than sent everywhere and ignored.
    if (isNew) {
      if (parentId != null) json['parentId'] = parentId;
      if (featureTypeCode != null) json['featureTypeCode'] = featureTypeCode;
      if (caveTypeCode != null) json['caveTypeCode'] = caveTypeCode;
      if (entranceTypeCode != null) json['entranceTypeCode'] = entranceTypeCode;
    }

    // Absent means "leave the stored position alone", which is what a device
    // with no fix of its own wants: it has nothing to assert, and a null here
    // would not clear one anyway.
    if (geometry != null) json['geometry'] = geometry!.toJson();
    if (altitude != null) json['altitude'] = altitude;
    if (positionQuality != null) {
      json['positionQuality'] = positionQuality!.wireName;
    }
    if (clientUpdatedAt != null) json['clientUpdatedAt'] = clientUpdatedAt;
    return json;
  }
}

/// One upload attempt.
class SyncUploadBatch {
  const SyncUploadBatch({required this.batchId, required this.rows});

  /// Minted by the device, per **attempt**. Sending the same one again returns
  /// the first answer and writes nothing, which is what makes a resend safe
  /// when the answer was lost on the way back. Never reuse one for different
  /// rows, and never mint a new one for a resend of the same rows — a batch
  /// split for `uploadRowsMax` is several attempts and gets an identifier
  /// each.
  final String batchId;

  /// Applied in the order given, so a container may be created earlier in the
  /// same batch than the row that hangs under it. A row may appear only once;
  /// a batch naming one twice is refused whole.
  final List<SyncUploadRow> rows;

  Map<String, Object?> toJson() => <String, Object?>{
    'batchId': batchId,
    'contractVersion': SilexgisContract.version,
    'rows': rows.map((r) => r.toJson()).toList(growable: false),
  };
}
