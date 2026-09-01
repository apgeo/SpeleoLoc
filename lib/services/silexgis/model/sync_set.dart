/// The audience an uploaded row is stored with.
enum SyncVisibility {
  private('private'),
  cavingGroup('cavingGroup'),
  authenticated('authenticated'),
  public('public');

  const SyncVisibility(this.wireName);
  final String wireName;

  static SyncVisibility fromWire(String? wireName) {
    for (final value in SyncVisibility.values) {
      if (value.wireName == wireName) return value;
    }
    return SyncVisibility.private;
  }
}

/// What a device carries: a named selection of **root features**, plus the
/// settings its code generation depends on.
///
/// A set names roots, not rows. Whatever is contained in a named root is in
/// the set, including anything added under it later, so there is no list of
/// synced objects to keep up to date on either side.
class SyncSet {
  const SyncSet({
    required this.id,
    required this.name,
    required this.revision,
    required this.rootFeatureIds,
    required this.settings,
    this.cavingGroupId,
    this.uploadVisibility = SyncVisibility.private,
  });

  final String id;
  final String name;

  /// A counter, not a timestamp. Compare it to the revision last seen to find
  /// out whether the settings document has gone stale — and note that a moved
  /// revision also retires every download cursor issued before it.
  final int revision;

  final List<String> rootFeatureIds;

  /// The device's own code-generation configuration. The server stores and
  /// returns it verbatim and forms no opinion about what any of it means.
  final Map<String, Object?> settings;

  /// The caving group rows uploaded through this set are bound to.
  ///
  /// **A set with none cannot be uploaded through** by an account that does
  /// not otherwise hold a create right: every row comes back
  /// `access.create_forbidden`. That is not in the contract documents and is
  /// recorded in `docs/integrations/silexgis/found-defects.md`; until it is,
  /// a caver who means to upload has to choose a group.
  final String? cavingGroupId;

  final SyncVisibility uploadVisibility;

  static SyncSet fromJson(Map<String, Object?> json) => SyncSet(
    id: json['id']! as String,
    name: json['name'] as String? ?? '',
    revision: (json['revision'] as num?)?.toInt() ?? 0,
    rootFeatureIds: (json['rootFeatureIds'] as List? ?? const <Object?>[])
        .whereType<String>()
        .toList(growable: false),
    settings: json['settings'] is Map
        ? Map<String, Object?>.from(json['settings']! as Map)
        : const <String, Object?>{},
    cavingGroupId: json['cavingGroupId'] as String?,
    uploadVisibility: SyncVisibility.fromWire(
      json['uploadVisibility'] as String?,
    ),
  );

  /// The body that would rewrite this set unchanged, ready to be adjusted.
  /// Carries the revision this copy was read at, which is what the write is
  /// arbitrated on.
  SyncSetWrite toWrite() => SyncSetWrite(
    name: name,
    cavingGroupId: cavingGroupId,
    uploadVisibility: uploadVisibility,
    rootFeatureIds: rootFeatureIds,
    settings: settings,
    baseRevision: revision,
  );
}

/// The body of a set create or replace. A replace rewrites the whole document,
/// so it always carries [baseRevision].
class SyncSetWrite {
  const SyncSetWrite({
    required this.name,
    required this.rootFeatureIds,
    required this.settings,
    this.cavingGroupId,
    this.uploadVisibility = SyncVisibility.private,
    this.baseRevision,
  });

  final String name;
  final List<String> rootFeatureIds;
  final Map<String, Object?> settings;
  final String? cavingGroupId;
  final SyncVisibility uploadVisibility;

  /// The revision the caller last read. Null on a create; required on a
  /// replace, which is refused `sync.set_revision_required` without it.
  final int? baseRevision;

  SyncSetWrite copyWith({
    String? name,
    List<String>? rootFeatureIds,
    Map<String, Object?>? settings,
    String? cavingGroupId,
    SyncVisibility? uploadVisibility,
  }) => SyncSetWrite(
    name: name ?? this.name,
    rootFeatureIds: rootFeatureIds ?? this.rootFeatureIds,
    settings: settings ?? this.settings,
    cavingGroupId: cavingGroupId ?? this.cavingGroupId,
    uploadVisibility: uploadVisibility ?? this.uploadVisibility,
    baseRevision: baseRevision,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'cavingGroupId': cavingGroupId,
    'uploadVisibility': uploadVisibility.wireName,
    'rootFeatureIds': rootFeatureIds,
    'settings': settings,
    if (baseRevision != null) 'baseRevision': baseRevision,
  };
}
