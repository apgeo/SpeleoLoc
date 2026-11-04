import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';

/// What removing one row here, for a server tombstone, would take with it.
class SilexgisTombstoneScan {
  const SilexgisTombstoneScan({
    required this.rows,
    required this.holdsUnsentWork,
  });

  /// The row named and the rows inside it that the removal takes: their
  /// revisions and held entries go with them.
  final List<Uuid> rows;

  /// Something in it is work the server has not answered for.
  final bool holdsUnsentWork;
}

/// Tells whether a server tombstone may remove a row here without taking the
/// caver's unsent work with it.
///
/// A removal on the server takes the row's whole containment subtree, and so
/// does the removal here — a cave goes with its places, areas, trips, maps
/// and beacon registrations. What the server never had from this device is
/// not the server's to remove: a place surveyed here and never sent, an edit
/// not yet answered, a row waiting on a reviewer or on the caver's answer to a
/// conflict, a trip or map never uploaded, a beacon registration no server
/// holds. Any of those keeps the row, and the caver decides.
///
/// The row named counts only by what this device sent or holds back: one with
/// no revision here is one this device never exchanged, and the server's word
/// on it stands.
class SilexgisTombstoneGuard {
  SilexgisTombstoneGuard(
    this._db, {
    required Map<Uuid, StoredRevision> agreed,
    required Set<Uuid> held,
  }) : _agreed = agreed,
       _held = held;

  final AppDatabase _db;

  /// What the two sides last agreed each row said, for every table the sync
  /// keeps revisions of.
  final Map<Uuid, StoredRevision> _agreed;

  /// Rows held for a reviewer or for the caver, in any upload section.
  final Set<Uuid> _held;

  Future<SilexgisTombstoneScan> scan(String table, Uuid uuid) async {
    final named = await _stamped(table, 'uuid', uuid);
    final inside = <_Stamped>[];
    var beacons = 0;
    switch (table) {
      case 'cave_places':
        beacons = await _activeBeacons('cave_place_uuid', uuid);
      case 'cave_areas':
        inside.addAll(await _stamped('cave_places', 'cave_area_uuid', uuid));
        beacons = await _activeBeaconsInArea(uuid);
      case 'caves':
        inside.addAll(await _caveContents(uuid));
        beacons = await _activeBeacons('cave_uuid', uuid);
      case 'surface_areas':
        for (final cave in await _stamped('caves', 'surface_area_uuid', uuid)) {
          inside
            ..add(cave)
            ..addAll(await _caveContents(cave.uuid));
          beacons += await _activeBeacons('cave_uuid', cave.uuid);
        }
    }
    return SilexgisTombstoneScan(
      rows: <Uuid>[
        for (final row in <_Stamped>[...named, ...inside]) row.uuid,
      ],
      holdsUnsentWork:
          beacons > 0 ||
          named.any(_editedSinceAgreed) ||
          inside.any(_neverAgreed),
    );
  }

  /// Held back, or exchanged and edited since.
  bool _editedSinceAgreed(_Stamped row) {
    if (_held.contains(row.uuid)) return true;
    final agreed = _agreed[row.uuid];
    return agreed != null && !agreed.agreesWith(row.updatedAt);
  }

  /// Held back, or not as the server last had it — including never sent.
  bool _neverAgreed(_Stamped row) =>
      _held.contains(row.uuid) ||
      !(_agreed[row.uuid]?.agreesWith(row.updatedAt) ?? false);

  Future<List<_Stamped>> _caveContents(Uuid cave) async => <_Stamped>[
    ...await _stamped('cave_places', 'cave_uuid', cave),
    ...await _stamped('cave_areas', 'cave_uuid', cave),
    ...await _stamped('cave_trips', 'cave_uuid', cave, live: true),
    ...await _stamped('raster_maps', 'cave_uuid', cave, live: true),
  ];

  /// The rows of [table] whose [column] is [value]. [live] leaves out rows
  /// already removed softly.
  Future<List<_Stamped>> _stamped(
    String table,
    String column,
    Uuid value, {
    bool live = false,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT uuid, updated_at FROM $table WHERE $column = ?'
          '${live ? ' AND deleted_at IS NULL' : ''}',
          variables: <Variable<Object>>[Variable<Uint8List>(value.bytes)],
        )
        .get();
    return <_Stamped>[
      for (final row in rows)
        _Stamped(
          Uuid.fromBytes(row.read<Uint8List>('uuid')),
          row.readNullable<int>('updated_at'),
        ),
    ];
  }

  Future<int> _activeBeacons(String column, Uuid value) async {
    final rows = await _db
        .customSelect(
          'SELECT 1 FROM cave_place_beacons '
          'WHERE $column = ? AND deleted_at IS NULL',
          variables: <Variable<Object>>[Variable<Uint8List>(value.bytes)],
        )
        .get();
    return rows.length;
  }

  Future<int> _activeBeaconsInArea(Uuid area) async {
    final rows = await _db
        .customSelect(
          'SELECT 1 FROM cave_place_beacons b '
          'JOIN cave_places p ON p.uuid = b.cave_place_uuid '
          'WHERE p.cave_area_uuid = ? AND b.deleted_at IS NULL',
          variables: <Variable<Object>>[Variable<Uint8List>(area.bytes)],
        )
        .get();
    return rows.length;
  }
}

class _Stamped {
  const _Stamped(this.uuid, this.updatedAt);

  final Uuid uuid;
  final int? updatedAt;
}
