import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/trip_log_method.dart';
import 'package:speleoloc/services/trip_log_renderer.dart';
import 'package:speleoloc/utils/constants.dart';

class CaveTripService {
  CaveTripService._();
  static final CaveTripService instance = CaveTripService._();

  final ValueNotifier<Uuid?> activeTripIdNotifier = ValueNotifier<Uuid?>(null);
  final ValueNotifier<bool> isPausedNotifier = ValueNotifier<bool>(false);

  Future<void> initActiveTrip() async {
    try {
      final row = await (appDatabase.select(appDatabase.configurations)
            ..where((c) => c.title.equals(activeTripConfigKey)))
          .getSingleOrNull();
      final parsed = Uuid.tryParse(row?.value);
      if (parsed != null) {
        final trip = await appDatabase.getActiveTrip();
        activeTripIdNotifier.value = (trip?.uuid == parsed) ? parsed : null;
        if (trip?.uuid != parsed) await _clearConfig();
      }
    } catch (_) {}
  }

  Future<Uuid> startTrip(Uuid caveUuid, String title) async {
    isPausedNotifier.value = false;
    final author = await currentUserService.currentOrSystem();
    final tripUuid = await appDatabase.insertCaveTrip(
      caveUuid: caveUuid,
      title: title,
      startedAt: DateTime.now().millisecondsSinceEpoch,
      authorUuid: author,
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
    await appDatabase.restartCaveTrip(tripUuid, authorUuid: author);
    await _saveConfig(tripUuid);
    activeTripIdNotifier.value = tripUuid;
    await _regenerateLog(tripUuid);
  }

  Future<void> stopTrip() async {
    final id = activeTripIdNotifier.value;
    if (id != null) {
      final author = await currentUserService.currentOrSystem();
      await appDatabase.endCaveTrip(id, authorUuid: author);
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
      await appDatabase.insertTripPoint(
          tripUuid: id, cavePlaceUuid: cavePlaceUuid, authorUuid: author);
      await _appendForNewEvent(id);
    } catch (_) {}
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
      await appDatabase.linkDocumentToTrip(docUuid, id, authorUuid: author);
      await _appendForNewEvent(id);
    } catch (_) {}
  }

  Future<CaveTrip?> getActiveTrip() => appDatabase.getActiveTrip();

  Future<Uuid?> getActiveTripCaveId() async {
    final trip = await getActiveTrip();
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
      final events = await TripLogRenderer.instance.loadEvents(tripUuid);
      final rendered = TripLogRenderer.instance.render(events, method);
      await appDatabase.updateTripLog(tripUuid, rendered);
    } catch (_) {}
  }

  /// Appends the rendered text for the most recently added event to
  /// `cave_trips.log`, preserving any free-form text the user has typed.
  /// Computed as the suffix difference between rendering all events and
  /// rendering all-but-the-last event with the active method.
  Future<void> _appendForNewEvent(Uuid tripUuid) async {
    try {
      final method = await currentUserService.getTripLogMethod();
      final eventsAfter =
          await TripLogRenderer.instance.loadEvents(tripUuid);
      if (eventsAfter.isEmpty) return;
      final eventsBefore =
          eventsAfter.sublist(0, eventsAfter.length - 1);
      final before =
          TripLogRenderer.instance.render(eventsBefore, method);
      final after = TripLogRenderer.instance.render(eventsAfter, method);
      if (!after.startsWith(before)) {
        // Renderings diverge in shape (e.g. method-dependent grouping at
        // the boundary). Fall back to full regeneration.
        await appDatabase.updateTripLog(tripUuid, after);
        return;
      }
      final delta = after.substring(before.length);
      if (delta.isEmpty) return;
      final trip = await (appDatabase.select(appDatabase.caveTrips)
            ..where((t) => t.uuid.equalsValue(tripUuid)))
          .getSingleOrNull();
      final current = trip?.log ?? '';
      // If the existing log already ends with this exact delta (e.g. the
      // user appended nothing since the previous event), avoid double-
      // appending. Otherwise append.
      if (current.isEmpty) {
        await appDatabase.updateTripLog(tripUuid, after);
      } else {
        await appDatabase.updateTripLog(tripUuid, current + delta);
      }
    } catch (_) {}
  }

  /// Public hook called by the trip log page after the user picks a new
  /// method. Persists the choice and rewrites the log.
  Future<void> regenerateLogWithMethod(
      Uuid tripUuid, TripLogMethod method) async {
    await currentUserService.setTripLogMethod(method);
    await _regenerateLog(tripUuid);
  }

  Future<void> _saveConfig(Uuid tripUuid) async {
    await appDatabase.into(appDatabase.configurations).insertOnConflictUpdate(
          ConfigurationsCompanion.insert(
            title: activeTripConfigKey,
            value: Value(tripUuid.toString()),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  Future<void> _clearConfig() async {
    await (appDatabase.delete(appDatabase.configurations)
          ..where((c) => c.title.equals(activeTripConfigKey)))
        .go();
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

final caveTripService = CaveTripService.instance;
