/// How one MBTiles file participates in the surface map's layer stack.
enum MbTilesRole {
  /// Selectable in the base-layer picker alongside the online sources.
  base,

  /// Toggleable overlay drawn on top of the selected base layer.
  overlay,
}

/// Persisted MBTiles configuration (one JSON blob in `configurations`):
/// whether the `mbtiles/` folder is auto-scanned, plus the per-file role.
class MapMbTilesConfig {
  /// When false the folder is not scanned and no MBTiles layers appear.
  final bool autoLoad;

  /// File name (not full path — the folder can move across installs) →
  /// role. Files without an entry default to [MbTilesRole.overlay].
  final Map<String, MbTilesRole> roles;

  const MapMbTilesConfig({this.autoLoad = true, this.roles = const {}});

  MbTilesRole roleOf(String fileName) =>
      roles[fileName] ?? MbTilesRole.overlay;

  MapMbTilesConfig copyWith({
    bool? autoLoad,
    Map<String, MbTilesRole>? roles,
  }) => MapMbTilesConfig(
    autoLoad: autoLoad ?? this.autoLoad,
    roles: roles ?? this.roles,
  );

  MapMbTilesConfig withRole(String fileName, MbTilesRole role) =>
      copyWith(roles: {...roles, fileName: role});

  factory MapMbTilesConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MapMbTilesConfig();
    final rawRoles = json['roles'];
    final roles = <String, MbTilesRole>{};
    if (rawRoles is Map) {
      for (final entry in rawRoles.entries) {
        roles[entry.key as String] = entry.value == 'base'
            ? MbTilesRole.base
            : MbTilesRole.overlay;
      }
    }
    return MapMbTilesConfig(
      autoLoad: json['autoLoad'] != false,
      roles: roles,
    );
  }

  Map<String, dynamic> toJson() => {
    'autoLoad': autoLoad,
    'roles': {
      for (final entry in roles.entries)
        entry.key: entry.value == MbTilesRole.base ? 'base' : 'overlay',
    },
  };
}
