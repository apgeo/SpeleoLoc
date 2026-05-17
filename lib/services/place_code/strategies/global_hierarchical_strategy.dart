import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/place_code/place_code_strategy.dart';
import 'package:speleoloc/utils/uuid.dart';

/// Strategy 1 — Global hierarchical PCI (the default).
///
/// PCI shape (segments concatenated, separator optional):
///
///   <country><sep><organization><sep><general_area_identifier>
///     <sep><cave_local_index><sep><cave_place_local_index>
///
/// Segment widths and the country / organization codes come from
/// [defaultConfig] / the saved strategy config. The area segment width
/// is taken from [kAreaIdentifierWidth] when a fallback is needed
/// (cave missing surface area or surface area missing identifier).
///
/// Allocation rules (see docs/features/place-code-identifiers.md §4.2):
///
/// * `cave_local_index` is the smallest unused
///   `cave_local_index_width`-digit string within
///   `<country><org><area>`. Persisted to `caves.cave_local_index` as a
///   side effect of [generate].
/// * `cave_place_local_index` is the smallest unused
///   `cave_place_local_index_width`-digit string within
///   `<country><org><area><cave_local_index>`. Not persisted as a
///   separate column — only as part of the PCI.
/// * If `is_main_entrance` is true and the reserved
///   `main_entrance_suffix` is free, it is used for the place suffix.
/// * If `country_code` or `organization_code` is empty, the entire
///   batch aborts with [PlaceCodeAbortReason.missingDatasetConfig].
/// * If a cave has no surface area, the area segment is filled with
///   zeros (0) of [kAreaIdentifierWidth] length; the result is returned
///   as [PlaceCodeGenerationFallback] with [FallbackReason.noSurfaceArea].
/// * If the surface area has no `general_area_identifier`, the area
///   segment is filled with nines (9) of [kAreaIdentifierWidth] length;
///   the result is [PlaceCodeGenerationFallback] with
///   [FallbackReason.noIdentifier].
class GlobalHierarchicalStrategy extends PlaceCodeStrategy {
  static const String strategyId = 'global_hierarchical';

  // Config keys (mirror docs §4.2).
  static const String kCountryCode = 'country_code';
  static const String kCountryCodeWidth = 'country_code_width';
  static const String kOrganizationCode = 'organization_code';
  static const String kOrganizationCodeWidth = 'organization_code_width';
  static const String kAreaIdentifierWidth = 'area_identifier_width';
  static const String kCaveLocalIndexWidth = 'cave_local_index_width';
  static const String kCavePlaceLocalIndexWidth =
      'cave_place_local_index_width';
  static const String kAllowNonDigit = 'allow_non_digit';
  static const String kMainEntranceSuffix = 'main_entrance_suffix';
  static const String kSegmentSeparator = 'segment_separator';

  final AppDatabase _db;
  final Map<String, dynamic> _config;

  GlobalHierarchicalStrategy(this._db, this._config);

  @override
  String get id => strategyId;

  @override
  String get displayNameKey => 'place_code_strategy_global_hierarchical';

  @override
  String get shortDescriptionKey =>
      'place_code_strategy_global_hierarchical_short';

  @override
  String get longDescriptionKey =>
      'place_code_strategy_global_hierarchical_long';

  @override
  Map<String, dynamic> get defaultConfig => const {
        kCountryCode: '',
        kCountryCodeWidth: 3,
        kOrganizationCode: '',
        kOrganizationCodeWidth: 3,
        kAreaIdentifierWidth: 3,
        kCaveLocalIndexWidth: 3,
        kCavePlaceLocalIndexWidth: 4,
        kAllowNonDigit: false,
        kMainEntranceSuffix: '0001',
        kSegmentSeparator: '',
      };

  String get _country => (_config[kCountryCode] as String?) ?? '';
  String get _org => (_config[kOrganizationCode] as String?) ?? '';
  int get _areaIdentifierWidth =>
      (_config[kAreaIdentifierWidth] as num?)?.toInt() ?? 3;
  int get _caveLocalIndexWidth =>
      (_config[kCaveLocalIndexWidth] as num?)?.toInt() ?? 3;
  int get _cavePlaceLocalIndexWidth =>
      (_config[kCavePlaceLocalIndexWidth] as num?)?.toInt() ?? 4;
  bool get _allowNonDigit => (_config[kAllowNonDigit] as bool?) ?? false;
  String get _mainEntranceSuffix =>
      (_config[kMainEntranceSuffix] as String?) ?? '0001';
  String get _sep => (_config[kSegmentSeparator] as String?) ?? '';

  // ----- Generation -----

  @override
  Future<PlaceCodeGenerationResult> generate({
    required Uuid caveUuid,
    required Uuid cavePlaceUuid,
    required bool isMainEntrance,
  }) async {
    if (_country.isEmpty || _org.isEmpty) {
      return const PlaceCodeGenerationResult.aborted(
        PlaceCodeAbortReason.missingDatasetConfig,
      );
    }

    final cave = await (_db.select(_db.caves)
          ..where((c) => c.uuid.equalsValue(caveUuid))
          ..limit(1))
        .getSingleOrNull();
    if (cave == null) {
      return const PlaceCodeGenerationResult.skipped(
        PlaceCodeSkipReason.caveMissing,
      );
    }

    // Determine the area segment; fall back to zeros / nines when data
    // is missing rather than skipping the cave/place entirely.
    FallbackReason? fallback;
    final String areaSegment;
    if (cave.surfaceAreaUuid == null) {
      areaSegment = '0' * _areaIdentifierWidth;
      fallback = FallbackReason.noSurfaceArea;
    } else {
      final area = await (_db.select(_db.surfaceAreas)
            ..where((a) => a.uuid.equalsValue(cave.surfaceAreaUuid!))
            ..limit(1))
          .getSingleOrNull();
      final identifier = area?.generalAreaIdentifier;
      if (identifier == null || identifier.isEmpty) {
        areaSegment = '9' * _areaIdentifierWidth;
        fallback = FallbackReason.noIdentifier;
      } else {
        areaSegment = identifier;
      }
    }

    // Reuse the cave_local_index if already set; otherwise allocate one.
    var caveLocal = cave.caveLocalIndex;
    if (caveLocal == null || caveLocal.isEmpty) {
      caveLocal = await _allocateCaveLocalIndex(
        baseline: _country + _sep + _org + _sep + areaSegment,
        currentCaveUuid: caveUuid,
      );
      // Persist the allocation so subsequent generations are stable.
      // (Direct write here — callers of PlaceCodeService should not be
      // expected to know about this side effect. The change_log is not
      // emitted from this layer; the integration step in Phase 3 wires
      // it through the repository if needed.)
      await (_db.update(_db.caves)
            ..where((c) => c.uuid.equalsValue(caveUuid)))
          .write(CavesCompanion(caveLocalIndex: Value(caveLocal)));
    }

    final baseline =
        _country + _sep + _org + _sep + areaSegment + _sep + caveLocal;

    // Main entrance suffix reservation.
    if (isMainEntrance && _mainEntranceSuffix.isNotEmpty) {
      final candidate = baseline + _sep + _mainEntranceSuffix;
      final taken = await _pciExistsExceptSelf(candidate, cavePlaceUuid);
      if (!taken) {
        return fallback != null
            ? PlaceCodeGenerationResult.fallback(candidate, fallback)
            : PlaceCodeGenerationResult.ok(candidate);
      }
    }

    final placeLocal = await _allocateCavePlaceLocalIndex(
      baseline: baseline,
      currentCavePlaceUuid: cavePlaceUuid,
    );
    final pci = baseline + _sep + placeLocal;
    return fallback != null
        ? PlaceCodeGenerationResult.fallback(pci, fallback)
        : PlaceCodeGenerationResult.ok(pci);
  }

  // ----- Validation -----

  @override
  Future<String?> validate(
    String pci, {
    required Uuid cavePlaceUuid,
    required Uuid caveUuid,
  }) async {
    if (pci.isEmpty) return 'place_code_error_empty';

    final parsed = _tryParse(pci);
    if (parsed == null) return 'place_code_error_layout_mismatch';

    if (!_allowNonDigit) {
      for (final seg in parsed.segments) {
        if (seg.contains(RegExp(r'[^0-9]'))) {
          return 'place_code_error_must_be_digits';
        }
      }
    }

    // Baseline match check (warning-level in §4.2; we return a soft
    // i18n key the caller can render as a non-blocking warning).
    final cave = await (_db.select(_db.caves)
          ..where((c) => c.uuid.equalsValue(caveUuid))
          ..limit(1))
        .getSingleOrNull();
    if (cave != null && cave.surfaceAreaUuid != null) {
      final area = await (_db.select(_db.surfaceAreas)
            ..where((a) => a.uuid.equalsValue(cave.surfaceAreaUuid!))
            ..limit(1))
          .getSingleOrNull();
      final areaSegment = area?.generalAreaIdentifier ?? '';
      final expectedBaseline =
          _country + _org + areaSegment + (cave.caveLocalIndex ?? '');
      final actualBaseline =
          parsed.country + parsed.organization + parsed.area + parsed.caveLocal;
      if (expectedBaseline.isNotEmpty &&
          expectedBaseline != actualBaseline) {
        // Caller may treat as warning-with-override (§4.2 Q-S1a).
        return 'place_code_warning_baseline_mismatch';
      }
    }

    // Global uniqueness.
    final dup = await _pciExistsExceptSelf(pci, cavePlaceUuid);
    if (dup) return 'place_code_error_not_unique';
    return null;
  }

  // ----- Helpers -----

  Future<String> _allocateCaveLocalIndex({
    required String baseline,
    required Uuid currentCaveUuid,
  }) async {
    // Collect used cave_local_index values within
    // <country><org><area>. We rely on caves.cave_local_index for the
    // canonical record; PCIs in cave_places are not consulted because
    // they may not exist yet.
    final caves = await _db.select(_db.caves).get();
    final used = <int>{};
    for (final c in caves) {
      if (c.uuid == currentCaveUuid) continue;
      final v = c.caveLocalIndex;
      if (v == null || v.isEmpty) continue;
      final n = int.tryParse(v);
      if (n != null) used.add(n);
    }
    var next = 1;
    while (used.contains(next)) {
      next++;
    }
    return next.toString().padLeft(_caveLocalIndexWidth, '0');
  }

  Future<String> _allocateCavePlaceLocalIndex({
    required String baseline,
    required Uuid currentCavePlaceUuid,
  }) async {
    // Find existing PCIs sharing this baseline; pull out the suffix
    // and collect the integer values.
    final width = _cavePlaceLocalIndexWidth;
    final allPlaces = await _db.select(_db.cavePlaces).get();
    final used = <int>{};
    for (final cp in allPlaces) {
      if (cp.uuid == currentCavePlaceUuid) continue;
      final v = cp.placeCodeIdentifier;
      if (v == null || v.isEmpty) continue;
      if (!v.startsWith(baseline)) continue;
      var suffix = v.substring(baseline.length);
      if (_sep.isNotEmpty && suffix.startsWith(_sep)) {
        suffix = suffix.substring(_sep.length);
      }
      // Only treat fixed-width numeric suffixes as "used".
      if (suffix.length != width) continue;
      final n = int.tryParse(suffix);
      if (n != null) used.add(n);
    }
    final reserved = int.tryParse(_mainEntranceSuffix);
    var next = 1;
    while (used.contains(next) || next == reserved) {
      next++;
    }
    return next.toString().padLeft(width, '0');
  }

  Future<bool> _pciExistsExceptSelf(String pci, Uuid cavePlaceUuid) async {
    final dup = await (_db.select(_db.cavePlaces)
          ..where((cp) =>
              cp.uuid.equalsValue(cavePlaceUuid).not() &
              cp.placeCodeIdentifier.equals(pci)))
        .get();
    return dup.isNotEmpty;
  }

  _ParsedPci? _tryParse(String pci) {
    final countryW = (_config[kCountryCodeWidth] as num?)?.toInt() ?? 3;
    final orgW =
        (_config[kOrganizationCodeWidth] as num?)?.toInt() ?? 3;
    final caveW = _caveLocalIndexWidth;
    final placeW = _cavePlaceLocalIndexWidth;
    final sep = _sep;

    if (sep.isEmpty) {
      // The area width is variable. We can only recover it if the rest
      // of the segments add up.
      final fixedHead = countryW + orgW;
      final fixedTail = caveW + placeW;
      if (pci.length <= fixedHead + fixedTail) return null;
      final areaLen = pci.length - fixedHead - fixedTail;
      try {
        return _ParsedPci(
          country: pci.substring(0, countryW),
          organization: pci.substring(countryW, countryW + orgW),
          area: pci.substring(fixedHead, fixedHead + areaLen),
          caveLocal: pci.substring(
              fixedHead + areaLen, fixedHead + areaLen + caveW),
          placeLocal: pci.substring(fixedHead + areaLen + caveW),
        );
      } catch (_) {
        return null;
      }
    }
    final parts = pci.split(sep);
    if (parts.length != 5) return null;
    return _ParsedPci(
      country: parts[0],
      organization: parts[1],
      area: parts[2],
      caveLocal: parts[3],
      placeLocal: parts[4],
    );
  }
}

class _ParsedPci {
  final String country;
  final String organization;
  final String area;
  final String caveLocal;
  final String placeLocal;
  const _ParsedPci({
    required this.country,
    required this.organization,
    required this.area,
    required this.caveLocal,
    required this.placeLocal,
  });
  List<String> get segments => [country, organization, area, caveLocal, placeLocal];
}
