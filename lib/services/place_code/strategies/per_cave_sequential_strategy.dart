import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/place_code/place_code_strategy.dart';
import 'package:speleoloc/utils/uuid.dart';

/// Strategy 2: per-cave sequential integer PCIs, stored as text.
///
/// Within a single cave, PCIs are integers starting at `start_at`,
/// incrementing by `step`. Numbers are zero-padded to
/// `zero_pad_width` digits ("4" → "0004" with width 4, "4" with
/// width 0). Storage is always TEXT so a future strategy can use
/// alphanumerics without a schema change.
class PerCaveSequentialStrategy extends PlaceCodeStrategy {
  static const String strategyId = 'per_cave_sequential';

  /// Config keys.
  static const String kStartAt = 'start_at';
  static const String kStep = 'step';
  static const String kZeroPadWidth = 'zero_pad_width';
  static const String kMainEntranceFirst = 'main_entrance_first';

  final AppDatabase _db;
  final Map<String, dynamic> _config;

  PerCaveSequentialStrategy(this._db, this._config);

  @override
  String get id => strategyId;

  @override
  String get displayNameKey => 'place_code_strategy_per_cave_sequential';

  @override
  String get shortDescriptionKey =>
      'place_code_strategy_per_cave_sequential_short';

  @override
  String get longDescriptionKey =>
      'place_code_strategy_per_cave_sequential_long';

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

  @override
  Future<String?> validate(
    String pci, {
    required Uuid cavePlaceUuid,
    required Uuid caveUuid,
  }) async {
    final n = int.tryParse(pci);
    if (n == null) {
      return 'place_code_error_must_be_integer';
    }
    if (n < _startAt) {
      return 'place_code_error_below_start_at';
    }
    // Uniqueness within the cave.
    final dup = await (_db.select(_db.cavePlaces)
          ..where((cp) =>
              cp.caveUuid.equalsValue(caveUuid) &
              cp.uuid.equalsValue(cavePlaceUuid).not() &
              cp.placeCodeIdentifier.equals(pci)))
        .get();
    if (dup.isNotEmpty) {
      return 'place_code_error_duplicate_in_cave';
    }
    return null;
  }

  @override
  Future<PlaceCodeGenerationResult> generate({
    required Uuid caveUuid,
    required Uuid cavePlaceUuid,
    required bool isMainEntrance,
  }) async {
    if (isMainEntrance && _mainEntranceFirst) {
      // Reserve the start value for the main entrance if free.
      final candidate = _format(_startAt);
      final taken = await _isTakenInCave(caveUuid, cavePlaceUuid, candidate);
      if (!taken) return PlaceCodeGenerationResult.ok(candidate);
    }

    // Gather existing numeric codes in this cave (excluding ourselves).
    final rows = await (_db.select(_db.cavePlaces)
          ..where((cp) =>
              cp.caveUuid.equalsValue(caveUuid) &
              cp.uuid.equalsValue(cavePlaceUuid).not()))
        .get();
    final used = <int>{};
    for (final row in rows) {
      final v = row.placeCodeIdentifier;
      if (v == null) continue;
      final n = int.tryParse(v);
      if (n != null) used.add(n);
    }
    var next = _startAt;
    while (used.contains(next)) {
      next += _step;
    }
    return PlaceCodeGenerationResult.ok(_format(next));
  }

  Future<bool> _isTakenInCave(
    Uuid caveUuid,
    Uuid cavePlaceUuid,
    String pci,
  ) async {
    final dup = await (_db.select(_db.cavePlaces)
          ..where((cp) =>
              cp.caveUuid.equalsValue(caveUuid) &
              cp.uuid.equalsValue(cavePlaceUuid).not() &
              cp.placeCodeIdentifier.equals(pci)))
        .get();
    return dup.isNotEmpty;
  }
}
