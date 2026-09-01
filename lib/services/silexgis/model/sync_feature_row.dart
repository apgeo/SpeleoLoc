import 'package:speleoloc/services/silexgis/model/geo_json_geometry.dart';

/// `kind` values this build recognises on a downloaded row.
///
/// The field is **not** a closed set: an unrecognised value is a row to store
/// and ignore, never an error, because an installation's taxonomy grows
/// without a contract change. That is why [SyncFeatureRow.kind] stays a
/// string and these are constants rather than an enum.
class SilexgisKinds {
  const SilexgisKinds._();

  static const String cave = 'cave';
  static const String caveEntrance = 'caveEntrance';
  static const String centerline = 'centerline';
  static const String generic = 'generic';
}

/// One containment edge above a row.
class FeatureParent {
  const FeatureParent({required this.parentId, required this.isPrimary});

  final String parentId;
  final bool isPrimary;

  static FeatureParent fromJson(Map<String, Object?> json) => FeatureParent(
    parentId: json['parentId']! as String,
    isPrimary: json['isPrimary'] as bool? ?? false,
  );
}

/// A feature row as the download and the conflict echo deliver it.
///
/// The wire row is the whole row: kind-specific columns are deliberately not
/// folded into it, so a device never receives a field whose protection was
/// decided for a different channel.
class SyncFeatureRow {
  const SyncFeatureRow({
    required this.id,
    required this.kind,
    required this.updatedAt,
    this.featureTypeCode,
    this.category,
    this.name,
    this.description,
    this.geometry,
    this.properties = const <String, Object?>{},
    this.propertiesSchemaVersion,
    this.locationProtected = false,
    this.protectedEffective = false,
    this.visibility,
    this.parents = const <FeatureParent>[],
    this.createdAt,
    this.clientUpdatedAt,
  });

  /// The row's identity on the server, stable for its lifetime, and the same
  /// identifier the device minted for a row it created.
  final String id;

  /// One of [SilexgisKinds], or something this build has never heard of.
  final String kind;

  /// The kind's stable code — `cave_place`, `cave_area`, `surface_area` and
  /// others. Not a closed list, and never resolved by a numeric id: ids belong
  /// to whichever installation seeded the table.
  final String? featureTypeCode;

  final String? category;
  final String? name;
  final String? description;

  /// Exact or absent. A row whose exact position this caller may not see is
  /// absent from the payload entirely — there is no approximate stand-in on
  /// this channel — so a null here means "no position recorded", not
  /// "position withheld".
  final GeoJsonGeometry? geometry;

  /// The property document, verbatim. Where the device's own identifiers live,
  /// and where a coordinate must never go: it is emitted to every reader of
  /// the row with no protection filter anywhere on its path.
  final Map<String, Object?> properties;

  final int? propertiesSchemaVersion;

  /// Whether this row is itself a protection root.
  final bool locationProtected;

  /// Whether the position this row carries is guarded at all — by this row or
  /// by anything containing it. **This is the field to branch on.**
  final bool protectedEffective;

  final String? visibility;

  /// The containment edges above the row, restricted to parents this caller
  /// may read — so not necessarily a complete ancestry, and never a source to
  /// derive protection from. Use [protectedEffective] for that.
  final List<FeatureParent> parents;

  final String? createdAt;

  /// This row's revision on the server, and the value to send back as
  /// `baseRevision` when writing it.
  ///
  /// Kept as the string the server sent rather than a parsed instant: it is
  /// compared for equality against what the server holds, and a parse-and-
  /// reformat round trip is a way to lose that equality for no gain.
  final String updatedAt;

  /// The moment a device believed it last wrote the row, by that device's own
  /// clock. Provenance, never a revision — null on every row the web interface
  /// wrote. It never decides which write the server keeps.
  final String? clientUpdatedAt;

  static SyncFeatureRow fromJson(Map<String, Object?> json) => SyncFeatureRow(
    id: json['id']! as String,
    kind: json['kind'] as String? ?? '',
    featureTypeCode: json['featureTypeCode'] as String?,
    category: json['category'] as String?,
    name: json['name'] as String?,
    description: json['description'] as String?,
    geometry: GeoJsonGeometry.fromJson(json['geometry']),
    properties: json['properties'] is Map
        ? Map<String, Object?>.from(json['properties']! as Map)
        : const <String, Object?>{},
    propertiesSchemaVersion: (json['propertiesSchemaVersion'] as num?)?.toInt(),
    locationProtected: json['locationProtected'] as bool? ?? false,
    protectedEffective: json['protectedEffective'] as bool? ?? false,
    visibility: json['visibility'] as String?,
    parents: (json['parents'] as List? ?? const <Object?>[])
        .whereType<Map>()
        .map((e) => FeatureParent.fromJson(Map<String, Object?>.from(e)))
        .toList(growable: false),
    createdAt: json['createdAt'] as String?,
    updatedAt: json['updatedAt']! as String,
    clientUpdatedAt: json['clientUpdatedAt'] as String?,
  );

  /// The primary containment edge, or null when the caller may read none of
  /// this row's parents.
  FeatureParent? get primaryParent {
    for (final parent in parents) {
      if (parent.isPrimary) return parent;
    }
    return null;
  }
}
