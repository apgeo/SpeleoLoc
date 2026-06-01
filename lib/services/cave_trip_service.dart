import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/trip_log_method.dart';
import 'package:speleoloc/services/trip_log_renderer.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/clock.dart';
import 'package:speleoloc/utils/constants.dart';

class CaveTripService {
  CaveTripService(this._db, {Clock clock = const SystemClock()})
      : _clock = clock,
        _renderer = TripLogRenderer(_db);

  final AppDatabase _db;
  final Clock _clock;
  final TripLogRenderer _renderer;

  final ValueNotifier<Uuid?> activeTripIdNotifier = ValueNotifier<Uuid?>(null);
  final ValueNotifier<bool> isPausedNotifier = ValueNotifier<bool>(false);

  Future<void> initActiveTrip() async {
    try {
      final row = await (_db.select(_db.configurations)
            ..where((c) => c.title.equals(activeTripConfigKey)))
          .getSingleOrNull();
      final parsed = Uuid.tryParse(row?.value);
      if (parsed != null) {
        // Look up the specific trip stored in config to verify it is still
        // unended.  Using getActiveTrip() (most-recent-unended) was wrong:
        // a different orphaned trip could satisfy that query while the config
        // trip has already been ended, or vice-versa.
        final trip = await (_db.select(_db.caveTrips)
              ..where(
                  (t) => t.uuid.equalsValue(parsed) & t.tripEndedAt.isNull()))
            .getSingleOrNull();
        activeTripIdNotifier.value = trip != null ? parsed : null;
        if (trip == null) await _clearConfig();
      }
    } catch (e, st) {
      log.warning('initActiveTrip failed; leaving active trip unset', e, st);
    }
  }

  Future<Uuid> startTrip(Uuid caveUuid, String title) async {
    isPausedNotifier.value = false;
    final author = await currentUserService.currentOrSystem();
    final tripUuid = await _db.insertCaveTrip(
      caveUuid: caveUuid,
      title: title,
      startedAt: _clock.nowMs(),
      authorUuid: author,
      deviceUuid: currentUserService.deviceUuid.value,
    );
    await _saveConfig(tripUuid);
    activeTripIdNotifier.value = tripUuid;
    await _regenerateLog(tripUuid);
    return tripUuid;
  }

  /// Reactivates an already-ended trip in-place (updates its row instead of
  /// inserting a new one). The title is unchanged.
  Future<void> restartTrip(Uuid tripUuid) async {
    isPausedNotifier.value = false;
    final author = await currentUserService.currentOrSystem();
    await _db.restartCaveTrip(tripUuid, authorUuid: author);
    await _saveConfig(tripUuid);
    activeTripIdNotifier.value = tripUuid;
    await _regenerateLog(tripUuid);
  }

  Future<void> stopTrip() async {
    final id = activeTripIdNotifier.value;
    if (id != null) {
      final author = await currentUserService.currentOrSystem();
      await _db.endCaveTrip(id, authorUuid: author);
      await _appendForNewEvent(id);
    }
    await _clearConfig();
    activeTripIdNotifier.value = null;
    isPausedNotifier.value = false;
  }

  /// Pause/resume are purely in-memory: while paused, [recordPoint] is
  /// suppressed. Pauses are not persisted and do not appear in the
  /// regenerated trip log.
  Future<void> pauseTrip() async {
    final id = activeTripIdNotifier.value;
    if (id == null || isPausedNotifier.value) return;
    isPausedNotifier.value = true;
  }

  Future<void> resumeTrip() async {
    final id = activeTripIdNotifier.value;
    if (id == null || !isPausedNotifier.value) return;
    isPausedNotifier.value = false;
  }

  Future<void> recordPoint(Uuid cavePlaceUuid, {String? placeTitle}) async {
    final id = activeTripIdNotifier.value;
    if (id == null || isPausedNotifier.value) return;
    try {
      final author = await currentUserService.currentOrSystem();
      await _db.insertTripPoint(
          tripUuid: id, cavePlaceUuid: cavePlaceUuid, authorUuid: author);
      await _appendForNewEvent(id);
    } catch (e, st) {
      log.warning('recordPoint failed (cavePlace=$cavePlaceUuid)', e, st);
    }
  }

  /// `textContent` is accepted for backwards compatibility with callers but
  /// is no longer written into the trip log — the renderer cannot recover
  /// it on subsequent re-renders. Document text is preserved in the
  /// `documentation_files` table (file content on disk) and is reachable
  /// from the document itself.
  Future<void> linkDocument(Uuid docUuid,
      {String? documentTitle, String? textContent}) async {
    final id = activeTripIdNotifier.value;
    if (id == null || isPausedNotifier.value) return;
    try {
      final author = await currentUserService.currentOrSystem();
      await _db.linkDocumentToTrip(docUuid, id, authorUuid: author);
      await _appendForNewEvent(id);
    } catch (e, st) {
      log.warning('linkDocument failed (doc=$docUuid)', e, st);
    }
  }

  Future<CaveTrip?> getActiveTrip() => _db.getActiveTrip();

  /// Returns the cave UUID of the currently tracked active trip, or [null]
  /// when no trip is active.  Uses [activeTripIdNotifier] as the single source
  /// of truth — consistent with what the UI displays — rather than a raw
  /// "any unended trip" DB query which can return orphaned rows.
  Future<Uuid?> getActiveTripCaveId() async {
    final id = activeTripIdNotifier.value;
    if (id == null) return null;
    final trip = await (_db.select(_db.caveTrips)
          ..where((t) => t.uuid.equalsValue(id)))
        .getSingleOrNull();
    return trip?.caveUuid;
  }

  /// Re-renders the full trip log for [tripUuid] using the user's active
  /// generation method and overwrites `cave_trips.log`. Called only on
  /// structural changes (start, restart) and on explicit method switch.
  /// Failures are swallowed to avoid breaking the event handler that
  /// triggered the regeneration.
  Future<void> _regenerateLog(Uuid tripUuid) async {
    try {
      final method = await currentUserService.getTripLogMethod();
      final events = await _renderer.loadEvents(tripUuid);
      final rendered = _renderer.render(events, method);
      await _db.updateTripLog(tripUuid, rendered);
    } catch (e, st) {
      log.warning('regenerateLog failed (trip=$tripUuid)', e, st);
    }
  }

  /// Appends the rendered text for the most recently added event to
  /// `cave_trips.log`, preserving any free-form text the user has typed.
  ///
  /// PR 11c: uses `TripLogRenderer.renderTailDelta` to render only the
  /// last event's line (O(1) for raw/classic, O(N) bounded counting for
  /// journal). Previous implementation rendered all N events twice
  /// (before + after) per call, giving O(N²) over the trip's lifetime.
  /// Narrative method still requires a full regen because its paragraph
  /// grouping can't be performed from the tail alone.
  Future<void> _appendForNewEvent(Uuid tripUuid) async {
    try {
      final method = await currentUserService.getTripLogMethod();
      final events = await _renderer.loadEvents(tripUuid);
      if (events.isEmpty) return;

      final delta = _renderer.renderTailDelta(events, method);
      if (delta == null) {
        // Method (narrative) does not support incremental rendering.
        final full = _renderer.render(events, method);
        await _db.updateTripLog(tripUuid, full);
        return;
      }

      final trip = await (_db.select(_db.caveTrips)
            ..where((t) => t.uuid.equalsValue(tripUuid)))
          .getSingleOrNull();
      final current = trip?.log ?? '';
      if (current.isEmpty) {
        // First event — write the delta as-is (no leading separator).
        await _db.updateTripLog(tripUuid, delta);
      } else if (current.endsWith(delta)) {
        // Already appended (e.g. retry / duplicate call) — no-op.
        return;
      } else {
        await _db.updateTripLog(tripUuid, '$current\n$delta');
      }
    } catch (e, st) {
      log.warning('appendForNewEvent failed (trip=$tripUuid)', e, st);
    }
  }

  /// Public hook called by the trip log page after the user picks a new
  /// method. Persists the choice and rewrites the log.
  Future<void> regenerateLogWithMethod(
      Uuid tripUuid, TripLogMethod method) async {
    await currentUserService.setTripLogMethod(method);
    await _regenerateLog(tripUuid);
  }

  Future<void> _saveConfig(Uuid tripUuid) {
    return rootContainer
        .read(configurationRepositoryProvider)
        .writeString(activeTripConfigKey, tripUuid.toString());
  }

  Future<void> _clearConfig() {
    return rootContainer
        .read(configurationRepositoryProvider)
        .delete(activeTripConfigKey);
  }

  static final _suffixRe = RegExp(r'\s+\[\d+\]$');

  static String uniqueTripTitle(String proposed, List<String> existingTitles) {
    final titles = existingTitles.toSet();
    if (!titles.contains(proposed)) return proposed;
    final base = proposed.replaceAll(_suffixRe, '');
    for (int i = 2;; i++) {
      final candidate = '$base [$i]';
      if (!titles.contains(candidate)) return candidate;
    }
  }
}
