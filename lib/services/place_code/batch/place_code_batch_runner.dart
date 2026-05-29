import 'package:drift/drift.dart' show Value;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/place_code/batch/place_code_overwrite_policy.dart';
import 'package:speleoloc/services/place_code/place_code_service.dart';
import 'package:speleoloc/services/place_code/place_code_strategy.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/clock.dart';
import 'package:speleoloc/utils/uuid.dart';

/// Scope of a single batch run. See §5.4 of
/// `docs/features/place-code-identifiers.md`.
sealed class PlaceCodeBatchScope {
  const PlaceCodeBatchScope();
}

/// All cave places in the dataset.
class GlobalScope extends PlaceCodeBatchScope {
  const GlobalScope();
}

/// All cave places whose cave belongs to [surfaceAreaUuid].
class PerAreaScope extends PlaceCodeBatchScope {
  final Uuid surfaceAreaUuid;
  const PerAreaScope(this.surfaceAreaUuid);
}

/// All cave places belonging to [caveUuid].
class PerCaveScope extends PlaceCodeBatchScope {
  final Uuid caveUuid;
  const PerCaveScope(this.caveUuid);
}

/// Callback the runner invokes when the overwrite policy needs a
/// human decision for a specific (cave place, field) pair.
///
/// The UI layer typically displays a dialog and returns one of
/// [OverwriteDecision]. Tests inject a stub.
typedef OverwritePromptCallback = Future<OverwriteDecision> Function({
  required Uuid cavePlaceUuid,
  required OverwriteField field,
  required String? existing,
  required String computed,
});

/// Progress callback called after each place is processed.
/// [current] is the 1-based index of the processed place;
/// [total] is the total number of places in the scope.
typedef BatchProgressCallback = void Function(int current, int total);

/// Allows the caller to request an early stop of an in-progress batch.
///
/// The runner checks [isCancelled] before processing each cave place.
/// Call [cancel] from a "Stop" button to signal cancellation.
class BatchCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  /// Request the batch to stop after the current place finishes.
  void cancel() => _cancelled = true;
}

/// One entry in the batch summary's skip/refuse breakdown.
class PlaceCodeBatchIssue {
  final Uuid cavePlaceUuid;
  final String reason;
  const PlaceCodeBatchIssue(this.cavePlaceUuid, this.reason);
}

/// Cave info entry used in Strategy-1 fallback reports.
class FallbackCaveInfo {
  final Uuid caveUuid;
  final String caveName;

  /// Number of cave places in this cave that triggered the fallback.
  final int placeCount;

  const FallbackCaveInfo({
    required this.caveUuid,
    required this.caveName,
    required this.placeCount,
  });
}

/// Aggregate result of a batch run.
class PlaceCodeBatchSummary {
  /// Number of cave places where at least one of PCI/QCRI was written.
  final int updated;

  /// Distinct number of caves that had at least one place updated.
  final int cavesUpdated;

  /// Number of places where the PCI was overwritten (had a non-null,
  /// non-empty value before the batch).
  final int overwritten;

  /// Total batch processing time in milliseconds.
  final int durationMs;

  /// Cave places skipped by the strategy itself (e.g. missing cave
  /// record) with the recorded reason.
  final List<PlaceCodeBatchIssue> skipped;

  /// Cave places where the user chose to keep an existing value.
  final List<PlaceCodeBatchIssue> refused;

  /// True when the run stopped early because the user picked
  /// "Cancel batch" on some prompt, pressed Stop, or the strategy
  /// returned an Abort.
  final bool cancelled;

  /// Aborts surfaced by strategies (e.g. missing dataset config).
  /// Listed separately from [skipped] because they typically stop the
  /// whole run.
  final List<PlaceCodeBatchIssue> aborted;

  /// Strategy-1: caves/places where the area segment was filled with
  /// zeros because the cave has no surface area.
  final List<FallbackCaveInfo> noSurfaceAreaFallbacks;

  /// Strategy-1: caves/places where the area segment was filled with
  /// nines because the surface area has no `general_area_identifier`.
  final List<FallbackCaveInfo> noIdentifierFallbacks;

  const PlaceCodeBatchSummary({
    required this.updated,
    required this.cavesUpdated,
    required this.overwritten,
    required this.durationMs,
    required this.skipped,
    required this.refused,
    required this.cancelled,
    required this.aborted,
    this.noSurfaceAreaFallbacks = const [],
    this.noIdentifierFallbacks = const [],
  });
}

/// Runs PCI + QCRI generation over a [PlaceCodeBatchScope].
///
/// Responsibilities:
/// - Resolve the scope to a list of cave places.
/// - For each: call [PlaceCodeService.generatePci], compute QCRI, and
///   decide PCI vs. QCRI writes through [PlaceCodeOverwritePolicy].
/// - When the policy raises [OverwriteAction.prompt], invoke the
///   injected [OverwritePromptCallback] and feed the answer back to
///   the policy.
/// - Write surviving values via [PlaceCodeService.applyPciToCompanion]
///   + [ICavePlaceRepository.updateCavePlace] so change-log entries
///   fire for both columns in one transaction.
class PlaceCodeBatchRunner {
  final AppDatabase _db;
  final PlaceCodeService _service;
  final ICavePlaceRepository _repository;
  final Clock _clock;

  PlaceCodeBatchRunner(this._db, this._service, this._repository, {Clock clock = const SystemClock()}) : _clock = clock;

  Future<PlaceCodeBatchSummary> run({
    required PlaceCodeBatchScope scope,
    required OverwritePromptCallback onPrompt,
    BatchProgressCallback? onProgress,
    BatchCancellationToken? cancellationToken,
  }) async {
    final policy = PlaceCodeOverwritePolicy();
    var updated = 0;
    var overwritten = 0;
    final skipped = <PlaceCodeBatchIssue>[];
    final refused = <PlaceCodeBatchIssue>[];
    final aborted = <PlaceCodeBatchIssue>[];
    final updatedCaves = <Uuid>{};

    // Strategy-1 fallback tracking: caveUuid → placeCount
    final noSurfaceAreaMap = <Uuid, int>{};
    final noIdentifierMap = <Uuid, int>{};

    final stopwatch = Stopwatch()..start();
    final places = await _loadScope(scope);
    final total = places.length;

    for (var i = 0; i < total; i++) {
      final place = places[i];
      final isCancelled =
          policy.isCancelled || (cancellationToken?.isCancelled ?? false);
      if (isCancelled) break;

      final result = await _service.generatePci(
        caveUuid: place.caveUuid,
        cavePlaceUuid: place.uuid,
        isMainEntrance: place.isMainEntrance == 1,
      );

      String? resultPci;
      switch (result) {
        case PlaceCodeGenerationSkipped(:final reason):
          skipped.add(PlaceCodeBatchIssue(place.uuid, reason.name));
          onProgress?.call(i + 1, total);
          continue;
        case PlaceCodeGenerationAborted(:final reason):
          aborted.add(PlaceCodeBatchIssue(place.uuid, reason.name));
          stopwatch.stop();
          // Aborts indicate a dataset-level config problem; stop.
          return PlaceCodeBatchSummary(
            updated: updated,
            cavesUpdated: updatedCaves.length,
            overwritten: overwritten,
            durationMs: stopwatch.elapsedMilliseconds,
            skipped: skipped,
            refused: refused,
            cancelled: true,
            aborted: aborted,
            noSurfaceAreaFallbacks:
                await _buildFallbackList(noSurfaceAreaMap),
            noIdentifierFallbacks:
                await _buildFallbackList(noIdentifierMap),
          );
        case PlaceCodeGenerationOk(:final pci):
          resultPci = pci;
        case PlaceCodeGenerationFallback(:final pci, :final fallback):
          resultPci = pci;
          final caveUuid = place.caveUuid;
          if (fallback == FallbackReason.noSurfaceArea) {
            noSurfaceAreaMap[caveUuid] =
                (noSurfaceAreaMap[caveUuid] ?? 0) + 1;
          } else {
            noIdentifierMap[caveUuid] =
                (noIdentifierMap[caveUuid] ?? 0) + 1;
          }
      }

      final resolvedPci = resultPci;
      final newQcri = await _service.computeQcri(
        resolvedPci,
        cavePlaceUuid: place.uuid,
        isEntrance: place.isEntrance == 1,
      );

      // ----- decide PCI -----
      var writePci = false;
      final pciAction = policy.decide(
        field: OverwriteField.pci,
        existing: place.placeCodeIdentifier,
        computed: resolvedPci,
      );
      switch (pciAction) {
        case OverwriteAction.write:
          writePci = true;
        case OverwriteAction.skip:
          // No-op (either equal to existing, or kept-all earlier).
          break;
        case OverwriteAction.cancel:
          break;
        case OverwriteAction.prompt:
          final decision = await onPrompt(
            cavePlaceUuid: place.uuid,
            field: OverwriteField.pci,
            existing: place.placeCodeIdentifier,
            computed: resolvedPci,
          );
          final after = policy.recordDecision(
            field: OverwriteField.pci,
            decision: decision,
          );
          if (after == OverwriteAction.write) {
            writePci = true;
          } else if (after == OverwriteAction.cancel) {
            refused.add(
              PlaceCodeBatchIssue(place.uuid, 'cancelled_at_pci_prompt'),
            );
            break;
          } else {
            refused.add(PlaceCodeBatchIssue(place.uuid, 'pci_kept'));
          }
      }
      if (policy.isCancelled || (cancellationToken?.isCancelled ?? false)) {
        break;
      }

      // ----- decide QCRI -----
      var writeQcri = false;
      final qcriAction = policy.decide(
        field: OverwriteField.qcri,
        existing: place.qrCodeResourceIdentifier,
        computed: newQcri,
      );
      switch (qcriAction) {
        case OverwriteAction.write:
          writeQcri = true;
        case OverwriteAction.skip:
          break;
        case OverwriteAction.cancel:
          break;
        case OverwriteAction.prompt:
          final decision = await onPrompt(
            cavePlaceUuid: place.uuid,
            field: OverwriteField.qcri,
            existing: place.qrCodeResourceIdentifier,
            computed: newQcri,
          );
          final after = policy.recordDecision(
            field: OverwriteField.qcri,
            decision: decision,
          );
          if (after == OverwriteAction.write) {
            writeQcri = true;
          } else if (after == OverwriteAction.cancel) {
            refused.add(
              PlaceCodeBatchIssue(place.uuid, 'cancelled_at_qcri_prompt'),
            );
            break;
          } else {
            refused.add(PlaceCodeBatchIssue(place.uuid, 'qcri_kept'));
          }
      }
      if (policy.isCancelled || (cancellationToken?.isCancelled ?? false)) {
        break;
      }

      if (!writePci && !writeQcri) {
        onProgress?.call(i + 1, total);
        continue;
      }

      // Track overwrite: PCI had a non-empty value before this batch.
      if (writePci) {
        final prev = place.placeCodeIdentifier;
        if (prev != null && prev.isNotEmpty) overwritten++;
      }

      // Single update carrying both fields when needed.
      var patch = CavePlacesCompanion(
        updatedAt: Value(_clock.nowMs()),
      );
      if (writePci) {
        patch = patch.copyWith(placeCodeIdentifier: Value(resolvedPci));
      }
      if (writeQcri) {
        patch = patch.copyWith(qrCodeResourceIdentifier: Value(newQcri));
      }
      await _repository.updateCavePlace(place.uuid, patch);
      updated++;
      updatedCaves.add(place.caveUuid);
      onProgress?.call(i + 1, total);
    }

    stopwatch.stop();
    return PlaceCodeBatchSummary(
      updated: updated,
      cavesUpdated: updatedCaves.length,
      overwritten: overwritten,
      durationMs: stopwatch.elapsedMilliseconds,
      skipped: skipped,
      refused: refused,
      cancelled:
          policy.isCancelled || (cancellationToken?.isCancelled ?? false),
      aborted: aborted,
      noSurfaceAreaFallbacks: await _buildFallbackList(noSurfaceAreaMap),
      noIdentifierFallbacks: await _buildFallbackList(noIdentifierMap),
    );
  }

  /// Converts a caveUuid→placeCount map into a list of [FallbackCaveInfo],
  /// looking up cave names from the database.
  Future<List<FallbackCaveInfo>> _buildFallbackList(
    Map<Uuid, int> map,
  ) async {
    if (map.isEmpty) return const [];
    final result = <FallbackCaveInfo>[];
    for (final entry in map.entries) {
      final cave = await (_db.select(_db.caves)
            ..where((c) => c.uuid.equalsValue(entry.key))
            ..limit(1))
          .getSingleOrNull();
      result.add(FallbackCaveInfo(
        caveUuid: entry.key,
          caveName: cave?.title ?? entry.key.toString(),
        placeCount: entry.value,
      ));
    }
    return result;
  }

  Future<List<CavePlace>> _loadScope(PlaceCodeBatchScope scope) async {
    switch (scope) {
      case GlobalScope():
        return _db.select(_db.cavePlaces).get();
      case PerCaveScope(:final caveUuid):
        return (_db.select(_db.cavePlaces)
              ..where((cp) => cp.caveUuid.equalsValue(caveUuid)))
            .get();
      case PerAreaScope(:final surfaceAreaUuid):
        // Cave places whose cave's surface_area_uuid matches.
        final caves = await (_db.select(_db.caves)
              ..where((c) => c.surfaceAreaUuid.equalsValue(surfaceAreaUuid)))
            .get();
        if (caves.isEmpty) return const [];
        final ids = caves.map((c) => c.uuid).toList();
        return (_db.select(_db.cavePlaces)
              ..where((cp) => cp.caveUuid.isInValues(ids)))
            .get();
    }
  }
}
