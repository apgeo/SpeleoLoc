import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/place_code/place_code_service.dart';
import 'package:speleoloc/services/place_code/strategies/global_hierarchical_strategy.dart';

/// Outcome of a range pre-generation request.
enum RangeCodeStatus {
  /// Codes were generated (see [RangeCodeResult.places]).
  ok,

  /// The active place-code strategy is not the hierarchical one, so an
  /// index range does not map to structured codes.
  unsupportedStrategy,

  /// Country / organization dataset codes are unset; no code can be composed.
  missingDatasetConfig,

  /// Cave-place range only: the cave has no `cave_local_index` yet.
  missingCaveIndex,

  /// Every index in the range already corresponds to a recorded cave/place.
  empty,
}

/// Result of a range pre-generation request. [places] are transient
/// [CavePlace] rows (never persisted) carrying the computed PCI + QCRI,
/// ready to hand to the QR viewer.
class RangeCodeResult {
  final RangeCodeStatus status;
  final List<CavePlace> places;

  /// How many indices in the requested range were skipped because a
  /// matching cave/place already exists.
  final int skipped;

  const RangeCodeResult(this.status, {this.places = const [], this.skipped = 0});
}

/// Builds QR-ready codes for a *range* of not-yet-recorded entries:
/// main-entrance codes for cave local indices in a surface area, and place
/// codes for a cave. Purely composes codes via the active hierarchical
/// strategy — it never writes to the database.
class RangeCodeGenerator {
  final AppDatabase _db;
  final PlaceCodeService _placeCodeService;

  RangeCodeGenerator(this._db, this._placeCodeService);

  /// Suggested upper bound on how many codes a single request should
  /// produce. Enforced by the input dialog before either method is called;
  /// exposed here so the UI and the service agree on one number.
  static const int maxRangeSize = 500;

  /// Compose main-entrance codes for cave local indices in [start]..[end]
  /// (inclusive) within [area] that have no recorded cave yet.
  Future<RangeCodeResult> generateAreaEntranceCodes({
    required SurfaceArea area,
    required int start,
    required int end,
  }) async {
    final strategy = await _placeCodeService.activeStrategy();
    if (strategy is! GlobalHierarchicalStrategy) {
      return const RangeCodeResult(RangeCodeStatus.unsupportedStrategy);
    }
    if (!strategy.isDatasetConfigured) {
      return const RangeCodeResult(RangeCodeStatus.missingDatasetConfig);
    }

    final areaSegment = strategy.areaSegmentForArea(area);

    // Which cave local indices are already taken in this area segment.
    // Uses the area *segment* (not the uuid) to match the strategy's own
    // allocation bucket: two areas sharing a general_area_identifier share
    // the code space.
    final caves = await _db.select(_db.caves).get();
    final areas = await _db.select(_db.surfaceAreas).get();
    final areaByUuid = {for (final a in areas) a.uuid: a};
    final used = <int>{};
    for (final cave in caves) {
      final raw = cave.caveLocalIndex;
      if (raw == null || raw.isEmpty) continue;
      final n = int.tryParse(raw);
      if (n == null) continue;
      final caveArea = cave.surfaceAreaUuid == null
          ? null
          : areaByUuid[cave.surfaceAreaUuid];
      if (strategy.areaSegmentForArea(caveArea) != areaSegment) continue;
      used.add(n);
    }

    final places = <CavePlace>[];
    var skipped = 0;
    for (var index = start; index <= end; index++) {
      if (used.contains(index)) {
        skipped++;
        continue;
      }
      final pci = strategy.composeMainEntrancePci(
        areaSegment: areaSegment,
        caveLocalIndex: index,
      );
      final placeUuid = Uuid.v7();
      final qcri = await _placeCodeService.computeQcri(
        pci,
        cavePlaceUuid: placeUuid,
        isEntrance: true,
      );
      places.add(
        CavePlace(
          uuid: placeUuid,
          title: pci,
          caveUuid: Uuid.zero,
          placeCodeIdentifier: pci,
          qrCodeResourceIdentifier: qcri,
          isEntrance: 1,
          isMainEntrance: 1,
        ),
      );
    }

    return RangeCodeResult(
      places.isEmpty ? RangeCodeStatus.empty : RangeCodeStatus.ok,
      places: places,
      skipped: skipped,
    );
  }

  /// Compose place codes for place indices in [start]..[end] (inclusive)
  /// under [cave] that have no recorded cave place yet. The reserved
  /// main-entrance index is always skipped.
  Future<RangeCodeResult> generateCavePlaceCodes({
    required Cave cave,
    required int start,
    required int end,
  }) async {
    final strategy = await _placeCodeService.activeStrategy();
    if (strategy is! GlobalHierarchicalStrategy) {
      return const RangeCodeResult(RangeCodeStatus.unsupportedStrategy);
    }
    if (!strategy.isDatasetConfigured) {
      return const RangeCodeResult(RangeCodeStatus.missingDatasetConfig);
    }
    final caveLocal = cave.caveLocalIndex;
    if (caveLocal == null || caveLocal.isEmpty) {
      return const RangeCodeResult(RangeCodeStatus.missingCaveIndex);
    }

    SurfaceArea? area;
    if (cave.surfaceAreaUuid != null) {
      area =
          await (_db.select(_db.surfaceAreas)
                ..where((a) => a.uuid.equalsValue(cave.surfaceAreaUuid!))
                ..limit(1))
              .getSingleOrNull();
    }
    final areaSegment = strategy.areaSegmentForArea(area);

    final existing = await (_db.select(
      _db.cavePlaces,
    )..where((cp) => cp.caveUuid.equalsValue(cave.uuid))).get();
    final existingPcis = <String>{
      for (final p in existing)
        if (p.placeCodeIdentifier != null) p.placeCodeIdentifier!,
    };
    final reserved = strategy.reservedPlaceIndex;

    final places = <CavePlace>[];
    var skipped = 0;
    for (var index = start; index <= end; index++) {
      if (index == reserved) {
        skipped++;
        continue;
      }
      final pci = strategy.composePlacePci(
        areaSegment: areaSegment,
        caveLocalIndex: caveLocal,
        placeLocalIndex: index,
      );
      if (existingPcis.contains(pci)) {
        skipped++;
        continue;
      }
      final placeUuid = Uuid.v7();
      final qcri = await _placeCodeService.computeQcri(
        pci,
        cavePlaceUuid: placeUuid,
        isEntrance: false,
      );
      places.add(
        CavePlace(
          uuid: placeUuid,
          title: pci,
          caveUuid: cave.uuid,
          placeCodeIdentifier: pci,
          qrCodeResourceIdentifier: qcri,
          isEntrance: 0,
          isMainEntrance: 0,
        ),
      );
    }

    return RangeCodeResult(
      places.isEmpty ? RangeCodeStatus.empty : RangeCodeStatus.ok,
      places: places,
      skipped: skipped,
    );
  }
}
