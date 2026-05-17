import 'package:speleoloc/utils/uuid.dart';

/// Outcome of a single PCI generation attempt.
///
/// Strategies return this from [PlaceCodeStrategy.generate] so callers
/// (batch runners, UI) can distinguish "successfully assigned" from
/// "this cave/place cannot be coded under the current configuration".
sealed class PlaceCodeGenerationResult {
  const PlaceCodeGenerationResult();

  /// Code was generated successfully.
  const factory PlaceCodeGenerationResult.ok(String pci) =
      PlaceCodeGenerationOk;

  /// The place/cave was deliberately skipped (e.g. missing area code,
  /// missing surface area). The batch runner should continue with the
  /// next place; UI should surface [reason].
  const factory PlaceCodeGenerationResult.skipped(
    PlaceCodeSkipReason reason,
  ) = PlaceCodeGenerationSkipped;

  /// The whole batch must abort (e.g. dataset-wide config missing).
  /// UI typically opens the settings page.
  const factory PlaceCodeGenerationResult.aborted(
    PlaceCodeAbortReason reason,
  ) = PlaceCodeGenerationAborted;

  /// Code was generated with a placeholder area segment (zeros / nines).
  /// This is treated as a successful generation for write purposes but
  /// is flagged for the batch summary.
  const factory PlaceCodeGenerationResult.fallback(
    String pci,
    FallbackReason fallback,
  ) = PlaceCodeGenerationFallback;
}

class PlaceCodeGenerationOk extends PlaceCodeGenerationResult {
  final String pci;
  const PlaceCodeGenerationOk(this.pci);
}

class PlaceCodeGenerationSkipped extends PlaceCodeGenerationResult {
  final PlaceCodeSkipReason reason;
  const PlaceCodeGenerationSkipped(this.reason);
}

class PlaceCodeGenerationAborted extends PlaceCodeGenerationResult {
  final PlaceCodeAbortReason reason;
  const PlaceCodeGenerationAborted(this.reason);
}

/// PCI was generated but used a fallback placeholder in place of an
/// unknown or missing area segment (Strategy 1 only).
///
/// The PCI is valid and can be written; the [fallback] field indicates
/// which data was missing so the batch runner can surface it in stats.
class PlaceCodeGenerationFallback extends PlaceCodeGenerationResult {
  final String pci;
  final FallbackReason fallback;
  const PlaceCodeGenerationFallback(this.pci, this.fallback);
}

/// Why the area segment of a generated PCI was filled with a
/// placeholder instead of a real `general_area_identifier` value.
enum FallbackReason {
  /// Cave has no surface area — zeros used for area segment.
  noSurfaceArea,

  /// Surface area exists but has no `general_area_identifier` — nines
  /// used for area segment.
  noIdentifier,
}

/// Reasons a single cave/place was skipped during batch generation.
enum PlaceCodeSkipReason {
  /// Cave record is missing (internal error / data integrity issue).
  caveMissing,

  /// Cave has no surface area assignment (Strategy 1 / 3).
  caveMissingSurfaceArea,

  /// The surface area exists but has no `general_area_identifier`
  /// (Strategy 1).
  surfaceAreaMissingIdentifier,
}

/// Reasons the entire batch must abort.
enum PlaceCodeAbortReason {
  /// Dataset-level config (e.g. country/org code under Strategy 1) is
  /// empty. UI should open the settings page.
  missingDatasetConfig,
}

/// Pluggable algorithm that allocates and validates PCIs.
///
/// Strategies are pure functions of (config, current database state) →
/// new code. They never write to the database themselves; the caller
/// (typically [PlaceCodeService]) is responsible for persisting the
/// result through [CavePlaceRepository].
abstract class PlaceCodeStrategy {
  /// Stable identifier persisted in
  /// `configurations.place_code_strategy`.
  String get id;

  /// i18n key for the user-facing strategy name.
  String get displayNameKey;

  /// i18n key for the short inline description.
  String get shortDescriptionKey;

  /// i18n key for the long description shown in a modal.
  String get longDescriptionKey;

  /// Default config values used when no
  /// `place_code_strategy_config[<id>]` blob has been saved yet.
  Map<String, dynamic> get defaultConfig;

  /// Validate a user-entered PCI for [cavePlaceUuid].
  ///
  /// Returns null if the value is acceptable, or an i18n key (or
  /// already-localized message — convention TBD per call site) of the
  /// rejection reason.
  Future<String?> validate(
    String pci, {
    required Uuid cavePlaceUuid,
    required Uuid caveUuid,
  });

  /// Generate the next PCI for a place in [caveUuid].
  Future<PlaceCodeGenerationResult> generate({
    required Uuid caveUuid,
    required Uuid cavePlaceUuid,
    required bool isMainEntrance,
  });

  /// Optional input mask applied as the user types into the PCI
  /// field. Default is identity.
  String formatInput(String raw) => raw;
}

/// Looks up the active [PlaceCodeStrategy] by id.
///
/// Strategies register themselves at construction time. The registry
/// is intentionally a flat list — order doesn't matter; lookups are
/// by [PlaceCodeStrategy.id].
class PlaceCodeStrategyRegistry {
  final Map<String, PlaceCodeStrategy> _byId;

  PlaceCodeStrategyRegistry(List<PlaceCodeStrategy> strategies)
      : _byId = {for (final s in strategies) s.id: s};

  /// Returns the strategy for [id], or null if unknown.
  PlaceCodeStrategy? byId(String id) => _byId[id];

  /// All registered strategies, in registration order.
  Iterable<PlaceCodeStrategy> get all => _byId.values;
}
