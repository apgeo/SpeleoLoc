import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/place_code/place_code_strategy.dart';
import 'package:speleoloc/utils/uuid.dart';

/// Strategy 3: per-area sequential integer PCIs, stored as text.
///
/// Same shape as [PerCaveSequentialStrategy], but uniqueness is scoped
/// to the surface area (all caves that share `surface_area_uuid`).
/// Caves with no surface area are *skipped* in batch generation and
/// rejected outright in single-place generation.
class PerAreaSequentialStrategy extends PlaceCodeStrategy {
  static const String strategyId = 'per_area_sequential';

  static const String kStartAt = 'start_at';
  static const String kStep = 'step';
  static const String kZeroPadWidth = 'zero_pad_width';
  static const String kMainEntranceFirst = 'main_entrance_first';

  final AppDatabase _db;
  final Map<String, dynamic> _config;

  PerAreaSequentialStrategy(this._db, this._config);

  @override
  String get id => strategyId;

  @override
  String get displayNameKey => 'place_code_strategy_per_area_sequential';

  @override
  String get shortDescriptionKey =>
      'place_code_strategy_per_area_sequential_short';

  @override
  String get longDescriptionKey =>
      'place_code_strategy_per_area_sequential_long';

  @override
  Map<String, dynamic> get defaultConfig => const {
        kStartAt: 1,
        kStep: 1,
        kZeroPadWidth: 0,
        kMainEntranceFirst: true,
      };

  int get _startAt => (_config[kStartAt] as num?)?.toInt() ?? 1;
  int get _step => (_config[kStep] as num?)?.toInt() ?? 1;
  int get _zeroPadWidth => (_config[kZeroPadWidth] as num?)?.toInt() ?? 0;
  bool get _mainEntranceFirst =>
      (_config[kMainEntranceFirst] as bool?) ?? true;

  String _format(int n) =>
      _zeroPadWidth > 0 ? n.toString().padLeft(_zeroPadWidth, '0') : n.toString();

  Future<Uuid?> _surfaceAreaOf(Uuid caveUuid) async {
    final cave = await (_db.select(_db.caves)
          ..where((c) => c.uuid.equalsValue(caveUuid))
          ..limit(1))
        .getSingleOrNull();
    return cave?.surfaceAreaUuid;
  }

  Future<Set<Uuid>> _caveUuidsInArea(Uuid surfaceAreaUuid) async {
    final caves = await (_db.select(_db.caves)
          ..where((c) => c.surfaceAreaUuid.equalsValue(surfaceAreaUuid)))
        .get();
    return caves.map((c) => c.uuid).toSet();
  }

  @override
  Future<String?> validate(
    String pci, {
    required Uuid cavePlaceUuid,
    required Uuid caveUuid,
  }) async {
    final n = int.tryParse(pci);
    if (n == null) return 'place_code_error_must_be_integer';
    if (n < _startAt) return 'place_code_error_below_start_at';

    final areaUuid = await _surfaceAreaOf(caveUuid);
    if (areaUuid == null) {
      return 'place_code_error_cave_missing_surface_area';
    }

    final caveUuids = await _caveUuidsInArea(areaUuid);
    final dup = await (_db.select(_db.cavePlaces)
          ..where((cp) =>
              cp.uuid.equalsValue(cavePlaceUuid).not() &
              cp.placeCodeIdentifier.equals(pci)))
        .get();
    final hit = dup.where((cp) => caveUuids.contains(cp.caveUuid));
    if (hit.isNotEmpty) {
      return 'place_code_error_duplicate_in_area';
    }
    return null;
  }

  @override
  Future<PlaceCodeGenerationResult> generate({
    required Uuid caveUuid,
    required Uuid cavePlaceUuid,
    required bool isMainEntrance,
  }) async {
    final areaUuid = await _surfaceAreaOf(caveUuid);
    if (areaUuid == null) {
      return const PlaceCodeGenerationResult.skipped(
        PlaceCodeSkipReason.caveMissingSurfaceArea,
      );
    }
    final caveUuids = await _caveUuidsInArea(areaUuid);

    final used = <int>{};
    final rows = await (_db.select(_db.cavePlaces)
          ..where((cp) => cp.uuid.equalsValue(cavePlaceUuid).not()))
        .get();
    for (final row in rows) {
      if (!caveUuids.contains(row.caveUuid)) continue;
      final v = row.placeCodeIdentifier;
      if (v == null) continue;
      final n = int.tryParse(v);
      if (n != null) used.add(n);
    }

    if (isMainEntrance && _mainEntranceFirst && !used.contains(_startAt)) {
      return PlaceCodeGenerationResult.ok(_format(_startAt));
    }
    var next = _startAt;
    while (used.contains(next)) {
      next += _step;
    }
    return PlaceCodeGenerationResult.ok(_format(next));
  }
}
