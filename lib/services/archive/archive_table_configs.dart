/// Table-import configuration for [DataArchiveService].
///
/// Describes every table that participates in import/export along with its
/// column list, unique constraints, and foreign-key relationships. The
/// ordering of [tableConfigs] is significant and respects foreign-key
/// dependencies so a straight top-to-bottom insert succeeds.
///
/// Extracted during Phase 2.4 of the refactoring.
library;

import 'package:speleoloc/utils/constants.dart';

class TableCfg {
  final String name;
  final String humanName;
  final List<String> columns; // all columns except 'id'
  final List<List<String>> uniqueConstraints;
  final Map<String, String> foreignKeys; // column → referenced table

  const TableCfg({
    required this.name,
    required this.humanName,
    required this.columns,
    this.uniqueConstraints = const [],
    this.foreignKeys = const {},
  });
}

const List<TableCfg> tableConfigs = [
  TableCfg(
    name: 'surface_areas',
    humanName: 'Surface Areas',
    columns: [
      'title', 'description', 'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['title']
    ],
  ),
  TableCfg(
    name: 'surface_places',
    humanName: 'Surface Places',
    columns: [
      'title', 'description', 'type', 'surface_place_qr_code_identifier',
      'latitude', 'longitude', 'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['title'] // best-effort match by title
    ],
  ),
  TableCfg(
    name: 'caves',
    humanName: 'Caves',
    columns: [
      'title', 'description', 'surface_area_id', 'created_at', 'updated_at',
      'deleted_at'
    ],
    uniqueConstraints: [
      ['title', 'surface_area_id']
    ],
    foreignKeys: {'surface_area_id': 'surface_areas'},
  ),
  TableCfg(
    name: 'cave_areas',
    humanName: 'Cave Areas',
    columns: [
      'title', 'description', 'cave_id', 'created_at', 'updated_at',
      'deleted_at'
    ],
    uniqueConstraints: [
      ['title', 'cave_id']
    ],
    foreignKeys: {'cave_id': 'caves'},
  ),
  TableCfg(
    name: 'cave_entrances',
    humanName: 'Cave Entrances',
    columns: [
      'cave_id', 'surface_place_id', 'is_main_entrance', 'title',
      'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['cave_id', 'title']
    ],
    foreignKeys: {'cave_id': 'caves', 'surface_place_id': 'surface_places'},
  ),
  TableCfg(
    name: 'cave_places',
    humanName: 'Cave Places',
    columns: [
      'title', 'description', 'cave_id', 'place_qr_code_identifier',
      'cave_area_id', 'latitude', 'longitude', 'altitude', 'depth_in_cave',
      'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['title', 'cave_id', 'cave_area_id']
    ],
    foreignKeys: {'cave_id': 'caves', 'cave_area_id': 'cave_areas'},
  ),
  TableCfg(
    name: 'raster_maps',
    humanName: 'Raster Maps',
    columns: [
      'title', 'map_type', 'file_name', 'cave_id', 'cave_area_id',
      'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['title', 'map_type', 'cave_id'],
      ['file_name', 'map_type', 'cave_id'],
    ],
    foreignKeys: {'cave_id': 'caves', 'cave_area_id': 'cave_areas'},
  ),
  TableCfg(
    name: 'cave_place_to_raster_map_definitions',
    humanName: 'Map Point Definitions',
    columns: [
      'x_coordinate', 'y_coordinate', 'cave_place_id', 'raster_map_id',
      'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['cave_place_id', 'raster_map_id']
    ],
    foreignKeys: {
      'cave_place_id': 'cave_places',
      'raster_map_id': 'raster_maps',
    },
  ),
  TableCfg(
    name: 'documentation_files',
    humanName: 'Documentation Files',
    columns: [
      'title', 'description', 'file_name', 'file_size', 'file_hash',
      'file_type', 'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['title', 'file_name', 'file_size', 'file_hash']
    ],
  ),
  TableCfg(
    name: 'documentation_files_to_geofeatures',
    humanName: 'Document Links',
    columns: [
      'geofeature_id', 'geofeature_type', 'documentation_file_id',
      'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['geofeature_id', 'geofeature_type', 'documentation_file_id']
    ],
    foreignKeys: {'documentation_file_id': 'documentation_files'},
    // geofeature_id FK depends on geofeature_type – handled specially.
  ),
  TableCfg(
    name: 'configurations',
    humanName: 'Configurations',
    columns: ['title', 'value', 'created_at', 'updated_at'],
    uniqueConstraints: [
      ['title']
    ],
  ),
  TableCfg(
    name: 'cave_trips',
    humanName: 'Cave Trips',
    columns: [
      'cave_id', 'title', 'description', 'trip_started_at', 'trip_ended_at',
      'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [],
    foreignKeys: {'cave_id': 'caves'},
  ),
  TableCfg(
    name: 'cave_trip_points',
    humanName: 'Cave Trip Points',
    columns: [
      'cave_trip_id', 'cave_place_id', 'scanned_at', 'notes',
      'created_at', 'updated_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['cave_trip_id', 'cave_place_id', 'scanned_at']
    ],
    foreignKeys: {'cave_trip_id': 'cave_trips', 'cave_place_id': 'cave_places'},
  ),
  TableCfg(
    name: 'documentation_files_to_cave_trips',
    humanName: 'Document-Trip Links',
    columns: [
      'documentation_file_id', 'cave_trip_id', 'created_at', 'deleted_at'
    ],
    uniqueConstraints: [
      ['documentation_file_id', 'cave_trip_id']
    ],
    foreignKeys: {
      'documentation_file_id': 'documentation_files',
      'cave_trip_id': 'cave_trips',
    },
  ),
];

/// Configuration keys that should *not* be imported (device-local settings).
const Set<String> skipConfigKeys = {
  lastOpenCaveKey,
  lastExportTimestampKey,
  activeTripConfigKey,
};

/// Maps geofeature_type DB value to the table name used for id-remapping.
String? geofeatureTypeToTable(String type) {
  switch (type) {
    case 'cave':
      return 'caves';
    case 'cave_place':
      return 'cave_places';
    case 'cave_area':
      return 'cave_areas';
    default:
      return null;
  }
}
