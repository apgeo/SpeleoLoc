/// The map types the `raster_maps` CHECK constraint accepts.
const Set<String> rasterMapTypes = {
  'plane view',
  'projected profile',
  'extended profile',
  'other',
};

/// [value] when the `raster_maps` CHECK constraint accepts it, else `other`.
///
/// Schemas before v8 had no such constraint and their imports wrote the type
/// as they found it, so copying their maps into the current table as they
/// are would abort the whole upgrade over one map, on every launch.
String rasterMapTypeOrOther(Object? value) =>
    value is String && rasterMapTypes.contains(value) ? value : 'other';
