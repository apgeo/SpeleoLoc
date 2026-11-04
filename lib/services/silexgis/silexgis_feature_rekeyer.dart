import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';
import 'package:speleoloc/utils/clock.dart';

/// One feature row inside a subtree, with its stamp.
class SilexgisSubtreeRow {
  const SilexgisSubtreeRow(this.table, this.uuid, this.updatedAt);

  final String table;
  final Uuid uuid;
  final int? updatedAt;
}

/// Gives a feature row the installation removed, and everything it contained,
/// new identifiers, so that they can go up again as new rows.
///
/// The installation keeps a removed row's identifier as its tombstone: a row
/// sent under it again is refused, and the contract has a row sent again as
/// new go under a new identifier. A removal there takes the row's whole
/// containment subtree, so every row inside gets a new identifier too — a
/// surface area its caves, a cave its areas and places, an area its places.
///
/// Everything here that names those rows follows them: the places, areas and
/// caves inside, trips, raster maps and their points, beacon registrations,
/// 3D model stations and document links. Each row that changes is stamped
/// now and the change is logged — the old identifiers as removed, the new as
/// added — so a device sharing archives with this one swaps them the same
/// way instead of keeping both. What this device knew of the old identifiers
/// on the installation goes: their revisions, held entries and recorded
/// document links.
class SilexgisFeatureRekeyer {
  SilexgisFeatureRekeyer({
    required AppDatabase db,
    required ChangeLogger logger,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisServerLinkRepository serverLinks,
    Clock clock = const SystemClock(),
  }) : _db = db,
       _logger = logger,
       _localState = localState,
       _heldRows = heldRows,
       _serverLinks = serverLinks,
       _clock = clock;

  final AppDatabase _db;
  final ChangeLogger _logger;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisServerLinkRepository _serverLinks;
  final Clock _clock;

  /// Every column that names a row of each feature table.
  static const Map<String, List<(String, String)>> _references =
      <String, List<(String, String)>>{
        'surface_areas': <(String, String)>[
          ('caves', 'surface_area_uuid'),
          ('documentation_files_to_geofeatures', 'geofeature_uuid'),
        ],
        'caves': <(String, String)>[
          ('cave_areas', 'cave_uuid'),
          ('cave_entrances', 'cave_uuid'),
          ('cave_places', 'cave_uuid'),
          ('raster_maps', 'cave_uuid'),
          ('cave_trips', 'cave_uuid'),
          ('cave_place_model_stations', 'cave_uuid'),
          ('cave_default_survey_models', 'cave_uuid'),
          ('cave_place_beacons', 'cave_uuid'),
          ('documentation_files_to_geofeatures', 'geofeature_uuid'),
        ],
        'cave_areas': <(String, String)>[
          ('cave_places', 'cave_area_uuid'),
          ('raster_maps', 'cave_area_uuid'),
          ('documentation_files_to_geofeatures', 'geofeature_uuid'),
        ],
        'cave_places': <(String, String)>[
          ('cave_place_to_raster_map_definitions', 'cave_place_uuid'),
          ('cave_trip_points', 'cave_place_uuid'),
          ('cave_place_model_stations', 'cave_place_uuid'),
          ('cave_place_beacons', 'cave_place_uuid'),
          ('documentation_files_to_geofeatures', 'geofeature_uuid'),
        ],
      };

  /// The row named and every feature row inside it, the row named first.
  Future<List<SilexgisSubtreeRow>> subtree(String table, Uuid uuid) async {
    final named = await _rows(table, 'uuid', uuid);
    if (named.isEmpty) return const <SilexgisSubtreeRow>[];
    final inside = <SilexgisSubtreeRow>[];
    switch (table) {
      case 'surface_areas':
        for (final cave in await _rows('caves', 'surface_area_uuid', uuid)) {
          inside
            ..add(cave)
            ..addAll(await _caveContents(cave.uuid));
        }
      case 'caves':
        inside.addAll(await _caveContents(uuid));
      case 'cave_areas':
        inside.addAll(await _rows('cave_places', 'cave_area_uuid', uuid));
    }
    return <SilexgisSubtreeRow>[...named, ...inside];
  }

  /// Gives [uuid] of [table] and its subtree new identifiers. Returns the old
  /// identifier of each row with its new one; empty when the row is gone.
  Future<Map<Uuid, Uuid>> rekey(
    String profileUuid,
    String table,
    Uuid uuid,
  ) async {
    final rows = await subtree(table, uuid);
    if (rows.isEmpty) return const <Uuid, Uuid>{};
    final renamed = <Uuid, Uuid>{for (final row in rows) row.uuid: Uuid.v7()};
    final now = _clock.nowMs();

    await _db.transaction(() async {
      // Rows and the rows naming them change in turn; the check waits for
      // the end, when every name agrees again.
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');
      final titles = <Uuid, String?>{
        for (final row in rows) row.uuid: await _title(row.table, row.uuid),
      };

      for (final row in rows) {
        final fresh = renamed[row.uuid]!;
        for (final (other, column) in _references[row.table]!) {
          for (final named in await _uuidsWhere(other, column, row.uuid)) {
            // A row inside the subtree is logged as removed and added below.
            if (renamed.containsKey(named)) continue;
            await _logger.logUpdate(
              other,
              named,
              oldValues: <String, Object?>{column: row.uuid.toString()},
              newValues: <String, Object?>{column: fresh.toString()},
            );
          }
          await _db.customStatement(
            'UPDATE $other SET $column = ?, updated_at = ? WHERE $column = ?',
            <Object?>[fresh.bytes, now, row.uuid.bytes],
          );
        }
      }
      for (final row in rows) {
        final fresh = renamed[row.uuid]!;
        await _db.customStatement(
          'UPDATE ${row.table} SET uuid = ?, updated_at = ? WHERE uuid = ?',
          <Object?>[fresh.bytes, now, row.uuid.bytes],
        );
        await _logger.logDelete(
          row.table,
          row.uuid,
          oldValues: <String, Object?>{'title': titles[row.uuid]},
        );
        await _logger.logInsert(row.table, fresh);
      }
    });

    final old = renamed.keys.toList(growable: false);
    await _localState.forgetRevisions(profileUuid, old);
    await _heldRows.clear(profileUuid, SyncUploadSection.rows, old);
    await _serverLinks.forgetTargets(profileUuid, old);
    return renamed;
  }

  Future<List<SilexgisSubtreeRow>> _caveContents(Uuid cave) async =>
      <SilexgisSubtreeRow>[
        ...await _rows('cave_areas', 'cave_uuid', cave),
        ...await _rows('cave_places', 'cave_uuid', cave),
      ];

  Future<List<SilexgisSubtreeRow>> _rows(
    String table,
    String column,
    Uuid value,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT uuid, updated_at FROM $table WHERE $column = ?',
          variables: <Variable<Object>>[Variable<Uint8List>(value.bytes)],
        )
        .get();
    return <SilexgisSubtreeRow>[
      for (final row in rows)
        SilexgisSubtreeRow(
          table,
          Uuid.fromBytes(row.read<Uint8List>('uuid')),
          row.readNullable<int>('updated_at'),
        ),
    ];
  }

  Future<List<Uuid>> _uuidsWhere(
    String table,
    String column,
    Uuid value,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT uuid FROM $table WHERE $column = ?',
          variables: <Variable<Object>>[Variable<Uint8List>(value.bytes)],
        )
        .get();
    return <Uuid>[
      for (final row in rows) Uuid.fromBytes(row.read<Uint8List>('uuid')),
    ];
  }

  Future<String?> _title(String table, Uuid uuid) async {
    final row = await _db
        .customSelect(
          'SELECT title FROM $table WHERE uuid = ?',
          variables: <Variable<Object>>[Variable<Uint8List>(uuid.bytes)],
        )
        .getSingleOrNull();
    return row?.readNullable<String>('title');
  }
}
