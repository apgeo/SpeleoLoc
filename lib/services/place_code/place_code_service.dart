import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/place_code/place_code_strategy.dart';
import 'package:speleoloc/services/place_code/qcri_hasher.dart';
import 'package:speleoloc/services/place_code/strategies/global_hierarchical_strategy.dart';
import 'package:speleoloc/services/place_code/strategies/per_area_sequential_strategy.dart';
import 'package:speleoloc/services/place_code/strategies/per_cave_sequential_strategy.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/uuid.dart';

/// QCRI generation mode.
enum QcriMode {
  /// `QCRI = PCI` on every write. Default in fresh datasets.
  mirror,

  /// `QCRI = base36(sha256(salt || pci))[:length]`. See [QcriHasher].
  hash,
}

/// Computed PCI + QCRI pair returned from generation entry points.
class PlaceCodePair {
  final String pci;
  final String qcri;
  const PlaceCodePair({required this.pci, required this.qcri});
}

/// Single chokepoint for PCI/QCRI generation, validation and lookup.
///
/// Loads the active strategy id and per-strategy config from the
/// `configurations` table on each call. The service does **not**
/// persist the computed pair to `cave_places` — callers (typically
/// `CavePlaceRepository`) are responsible for writing through the
/// repository so change-log entries are emitted correctly.
class PlaceCodeService {
  final AppDatabase _db;
  final QcriHasher _hasher;

  PlaceCodeService(this._db, {QcriHasher? hasher})
      : _hasher = hasher ?? const QcriHasher();

  // ----- Active strategy -----

  Future<String> _readActiveStrategyId() async {
    return await _readConfig(ConfigKey.placeCodeStrategy) ??
        GlobalHierarchicalStrategy.strategyId;
  }

  Future<Map<String, dynamic>> _readStrategyConfigBlob() async {
    final raw = await _readConfig(ConfigKey.placeCodeStrategyConfig);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e, st) {
      log.warning('strategy config blob corrupt; using empty config', e, st);
    }
    return const {};
  }

  Future<QcriMode> _readQcriMode() async {
    final raw =
        (await _readConfig(ConfigKey.qcriMode))?.toLowerCase() ?? 'mirror';
    return raw == 'hash' ? QcriMode.hash : QcriMode.mirror;
  }

  Future<int> _readQcriLength() async {
    final raw = await _readConfig(ConfigKey.qcriHashConfig);
    if (raw == null || raw.isEmpty) return 8;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['length'] is num) {
        final n = (decoded['length'] as num).toInt();
        if (n >= QcriHasher.minLength && n <= QcriHasher.maxLength) {
          return n;
        }
      }
    } catch (e, st) {
      log.warning('QCRI hash-config length read failed; using default 8',
          e, st);
    }
    return 8;
  }

  /// When true and the current mode is [QcriMode.mirror], cave places that
  /// are entrances (any `is_entrance = 1`) will use hash behaviour
  /// (QCRI = hash(PCI)) instead of mirroring. Stored under
  /// `qcri_hash_config`.`entrance_hash`.
  Future<bool> _readEntranceHashInMirrorMode() async {
    final raw = await _readConfig(ConfigKey.qcriHashConfig);
    if (raw == null || raw.isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['entrance_hash'] is bool) {
        return decoded['entrance_hash'] as bool;
      }
    } catch (e, st) {
      log.warning('QCRI entrance_hash flag read failed; assuming false',
          e, st);
    }
    return false;
  }

  /// Reads the optional user-defined salt string from `qcri_hash_config`.
  /// Returns an empty string when not set.
  Future<String> _readQcriSalt() async {
    final raw = await _readConfig(ConfigKey.qcriHashConfig);
    if (raw == null || raw.isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['salt'] is String) {
        return (decoded['salt'] as String).trim();
      }
    } catch (e, st) {
      log.warning('QCRI salt read failed; using empty salt', e, st);
    }
    return '';
  }

  Future<String?> _readConfig(String key) async {
    final row = await (_db.select(_db.configurations)
          ..where((c) => c.title.equals(key))
          ..limit(1))
        .getSingleOrNull();
    return row?.value;
  }

  /// Returns true when the current QCRI mode is [QcriMode.mirror]
  /// (i.e. QCRI is an exact copy of the PCI).
  Future<bool> isMirrorMode() async =>
      (await _readQcriMode()) == QcriMode.mirror;

  /// Resolves the active [PlaceCodeStrategy] instance from saved
  /// configuration. Strategies are constructed fresh on every call —
  /// they are stateless w.r.t. the database connection.
  Future<PlaceCodeStrategy> activeStrategy() async {
    final id = await _readActiveStrategyId();
    final blob = await _readStrategyConfigBlob();
    final strategyConfig =
        (blob[id] is Map) ? Map<String, dynamic>.from(blob[id] as Map) : const <String, dynamic>{};
    return _build(id, strategyConfig);
  }

  PlaceCodeStrategy _build(String id, Map<String, dynamic> config) {
    switch (id) {
      case PerCaveSequentialStrategy.strategyId:
        return PerCaveSequentialStrategy(_db, config);
      case PerAreaSequentialStrategy.strategyId:
        return PerAreaSequentialStrategy(_db, config);
      case GlobalHierarchicalStrategy.strategyId:
      default:
        return GlobalHierarchicalStrategy(_db, config);
    }
  }

  // ----- PCI/QCRI generation -----

  /// Computes the QCRI for [pci] under the current mode.
  ///
  /// In `hash` mode, retries with `length+1` (up to
  /// [QcriHasher.maxLength]) when the candidate already exists for a
  /// different cave place. Returns the PCI itself in `mirror` mode.
  ///
  /// When [isEntrance] is true and the active hash configuration has
  /// `entrance_hash: true`, the QCRI is hashed even in mirror mode.
  /// When [isEntrance] is null, the entrance flag is looked up
  /// from the database for [cavePlaceUuid] (falls back to false if no
  /// row exists yet — typical for new cave places).
  Future<String> computeQcri(
    String pci, {
    required Uuid cavePlaceUuid,
    bool? isEntrance,
  }) async {
    final mode = await _readQcriMode();
    if (mode == QcriMode.mirror) {
      final useHashForEntrance = await _readEntranceHashInMirrorMode();
      if (useHashForEntrance) {
        final entrance = isEntrance ?? await _isCavePlaceEntrance(cavePlaceUuid);
        if (entrance) {
          // Fall through to hash computation below.
        } else {
          return pci;
        }
      } else {
        return pci;
      }
    }
    var length = await _readQcriLength();
    final userSalt = await _readQcriSalt();
    while (length <= QcriHasher.maxLength) {
      final candidate = _hasher.hash(pci, length: length, userSalt: userSalt.isEmpty ? null : userSalt);
      final taken = await _qcriTakenExceptSelf(candidate, cavePlaceUuid);
      if (!taken) return candidate;
      length++;
    }
    // Fall back to the maximum-length hash even if it collides; the
    // caller will see the duplicate and can decide.
    return _hasher.hash(pci, length: QcriHasher.maxLength, userSalt: userSalt.isEmpty ? null : userSalt);
  }

  Future<bool> _isCavePlaceEntrance(Uuid cavePlaceUuid) async {
    final row = await (_db.select(_db.cavePlaces)
          ..where((cp) => cp.uuid.equalsValue(cavePlaceUuid))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return false;
    return row.isEntrance == 1;
  }

  Future<bool> _qcriTakenExceptSelf(String qcri, Uuid cavePlaceUuid) async {
    final dup = await (_db.select(_db.cavePlaces)
          ..where((cp) => cp.qrCodeResourceIdentifier.equals(qcri)))
        .get();
    return dup.any((row) => row.uuid != cavePlaceUuid);
  }

  /// Generate a (PCI, QCRI) pair for a single cave place.
  ///
  /// On strategy-level skip / abort, the surrounding result type
  /// surfaces the reason; the caller (batch runner or UI) decides
  /// what to do next.
  Future<PlaceCodeGenerationResult> generatePci({
    required Uuid caveUuid,
    required Uuid cavePlaceUuid,
    required bool isMainEntrance,
  }) async {
    final strategy = await activeStrategy();
    return strategy.generate(
      caveUuid: caveUuid,
      cavePlaceUuid: cavePlaceUuid,
      isMainEntrance: isMainEntrance,
    );
  }

  /// Convenience: generate PCI and immediately compute the matching
  /// QCRI. Returns null when generation was skipped or aborted; the
  /// detailed reason is available via [generatePci].
  ///
  /// [PlaceCodeGenerationFallback] is treated the same as
  /// [PlaceCodeGenerationOk] here — the PCI is valid and usable, just
  /// generated with a placeholder area segment.
  Future<PlaceCodePair?> generatePair({
    required Uuid caveUuid,
    required Uuid cavePlaceUuid,
    required bool isMainEntrance,
  }) async {
    final result = await generatePci(
      caveUuid: caveUuid,
      cavePlaceUuid: cavePlaceUuid,
      isMainEntrance: isMainEntrance,
    );
    final String? pci = switch (result) {
      PlaceCodeGenerationOk r => r.pci,
      PlaceCodeGenerationFallback r => r.pci,
      _ => null,
    };
    if (pci == null) return null;
    final qcri = await computeQcri(pci, cavePlaceUuid: cavePlaceUuid);
    return PlaceCodePair(pci: pci, qcri: qcri);
  }

  /// Validate a user-entered PCI against the active strategy.
  Future<String?> validate(
    String pci, {
    required Uuid cavePlaceUuid,
    required Uuid caveUuid,
  }) async {
    final strategy = await activeStrategy();
    return strategy.validate(
      pci,
      cavePlaceUuid: cavePlaceUuid,
      caveUuid: caveUuid,
    );
  }

  // ----- Write integration (Phase 3) -----

  /// Returns a copy of [companion] with [CavePlaces.qrCodeResourceIdentifier]
  /// recomputed whenever [CavePlaces.placeCodeIdentifier] is being set.
  ///
  /// Rules:
  /// - PCI absent → companion is returned unchanged.
  /// - PCI explicitly null/empty → QCRI is also cleared to null.
  /// - PCI non-empty → QCRI is computed via [computeQcri] under the
  ///   current [QcriMode].
  ///
  /// This is the single chokepoint every PCI write must pass through;
  /// callers hand the result to `CavePlaceRepository.addCavePlaceFromCompanion`
  /// or `CavePlaceRepository.updateCavePlace` so change-log entries
  /// fire for both columns in one transaction.
  Future<CavePlacesCompanion> applyPciToCompanion(
    CavePlacesCompanion companion, {
    required Uuid cavePlaceUuid,
  }) async {
    if (!companion.placeCodeIdentifier.present) return companion;
    final pci = companion.placeCodeIdentifier.value;
    if (pci == null || pci.isEmpty) {
      return companion.copyWith(
        qrCodeResourceIdentifier: const Value<String?>(null),
      );
    }
    final isEntrance = companion.isEntrance.present
        ? (companion.isEntrance.value == 1)
        : null;
    final qcri = await computeQcri(
      pci,
      cavePlaceUuid: cavePlaceUuid,
      isEntrance: isEntrance,
    );
    return companion.copyWith(qrCodeResourceIdentifier: Value(qcri));
  }
}
