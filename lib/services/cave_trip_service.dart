import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/constants.dart';

class CaveTripService {
  CaveTripService._();
  static final CaveTripService instance = CaveTripService._();

  final ValueNotifier<int?> activeTripIdNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<bool> isPausedNotifier = ValueNotifier<bool>(false);

  static final _logTimeFmt = DateFormat('yyyy/MM/dd HH:mm:ss');

  String _logLine(String message) =>
      '[${_logTimeFmt.format(DateTime.now())}] $message';

  Future<void> initActiveTrip() async {
    try {
      final row = await (appDatabase.select(appDatabase.configurations)
            ..where((c) => c.title.equals(activeTripConfigKey)))
          .getSingleOrNull();
      final id = int.tryParse(row?.value ?? '');
      if (id != null) {
        final trip = await appDatabase.getActiveTrip();
        activeTripIdNotifier.value = (trip?.id == id) ? id : null;
        if (trip?.id != id) await _clearConfig();
      }
    } catch (_) {}
  }

  Future<int> startTrip(int caveId, String title) async {
    isPausedNotifier.value = false;
    final tripId = await appDatabase.insertCaveTrip(
      caveId: caveId,
      title: title,
      startedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _saveConfig(tripId);
    activeTripIdNotifier.value = tripId;
    await _append(_logLine('Trip started: "$title"'), tripId);
    return tripId;
  }

  Future<void> stopTrip() async {
    final id = activeTripIdNotifier.value;
    if (id != null) {
      await _append(_logLine('Trip ended'), id);
      await appDatabase.endCaveTrip(id);
    }
    await _clearConfig();
    activeTripIdNotifier.value = null;
    isPausedNotifier.value = false;
  }

  void pauseTrip() {
    if (activeTripIdNotifier.value == null) return;
    isPausedNotifier.value = true;
    _append(_logLine('Trip paused'), activeTripIdNotifier.value!);
  }

  void resumeTrip() {
    if (activeTripIdNotifier.value == null) return;
    isPausedNotifier.value = false;
    _append(_logLine('Trip resumed'), activeTripIdNotifier.value!);
  }

  Future<void> recordPoint(int cavePlaceId, {String? placeTitle}) async {
    final id = activeTripIdNotifier.value;
    if (id == null || isPausedNotifier.value) return;
    try {
      await appDatabase.insertTripPoint(tripId: id, cavePlaceId: cavePlaceId);
      final label = placeTitle != null ? '"$placeTitle"' : 'place #$cavePlaceId';
      await _append(_logLine('QR scanned: $label'), id);
    } catch (_) {}
  }

  Future<void> linkDocument(int docId, {String? documentTitle, String? textContent}) async {
    final id = activeTripIdNotifier.value;
    if (id == null || isPausedNotifier.value) return;
    try {
      await appDatabase.linkDocumentToTrip(docId, id);
      final label = documentTitle != null ? '"$documentTitle"' : 'doc #$docId';
      final sb = StringBuffer(_logLine('Document added: $label'));
      if (textContent != null && textContent.trim().isNotEmpty) {
        sb.write('\n');
        for (final line in textContent.split('\n')) {
          sb.write('  $line\n');
        }
      }
      await _append(sb.toString().trimRight(), id);
    } catch (_) {}
  }

  Future<CaveTrip?> getActiveTrip() => appDatabase.getActiveTrip();

  Future<int?> getActiveTripCaveId() async {
    final trip = await getActiveTrip();
    return trip?.caveId;
  }

  Future<void> _append(String line, int tripId) async {
    try {
      await appDatabase.appendToTripLog(tripId, line);
    } catch (_) {}
  }

  Future<void> _saveConfig(int tripId) async {
    await appDatabase.into(appDatabase.configurations).insertOnConflictUpdate(
      ConfigurationsCompanion.insert(
        title: activeTripConfigKey,
        value: Value(tripId.toString()),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> _clearConfig() async {
    await (appDatabase.delete(appDatabase.configurations)
          ..where((c) => c.title.equals(activeTripConfigKey)))
        .go();
  }
}

final caveTripService = CaveTripService.instance;
