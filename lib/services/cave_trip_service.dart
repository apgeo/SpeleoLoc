import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';

class CaveTripService {
  CaveTripService._();
  static final CaveTripService instance = CaveTripService._();

  final ValueNotifier<Uuid?> activeTripIdNotifier = ValueNotifier<Uuid?>(null);
  final ValueNotifier<bool> isPausedNotifier = ValueNotifier<bool>(false);

  static final _logTimeFmt = DateFormat('yyyy/MM/dd HH:mm:ss');

  String _logLine(String message) =>
      '[${_logTimeFmt.format(DateTime.now())}] $message';

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
    await _append(
        _logLine(LocServ.inst.t('trip_log_started', {'title': title})),
        tripUuid);
    return tripUuid;
  }

  Future<void> stopTrip() async {
    final id = activeTripIdNotifier.value;
    if (id != null) {
      await _append(_logLine(LocServ.inst.t('trip_log_ended')), id);
      final author = await currentUserService.currentOrSystem();
      await appDatabase.endCaveTrip(id, authorUuid: author);
    }
    await _clearConfig();
    activeTripIdNotifier.value = null;
    isPausedNotifier.value = false;
  }

  void pauseTrip() {
    if (activeTripIdNotifier.value == null) return;
    isPausedNotifier.value = true;
    _append(_logLine(LocServ.inst.t('trip_log_paused')),
        activeTripIdNotifier.value!);
  }

  void resumeTrip() {
    if (activeTripIdNotifier.value == null) return;
    isPausedNotifier.value = false;
    _append(_logLine(LocServ.inst.t('trip_log_resumed')),
        activeTripIdNotifier.value!);
  }

  Future<void> recordPoint(Uuid cavePlaceUuid, {String? placeTitle}) async {
    final id = activeTripIdNotifier.value;
    if (id == null || isPausedNotifier.value) return;
    try {
      final author = await currentUserService.currentOrSystem();
      await appDatabase.insertTripPoint(
          tripUuid: id, cavePlaceUuid: cavePlaceUuid, authorUuid: author);
      final label =
          placeTitle != null ? '"$placeTitle"' : 'place $cavePlaceUuid';
      await _append(
          _logLine(LocServ.inst.t('trip_log_qr_scanned', {'label': label})),
          id);
    } catch (_) {}
  }

  Future<void> linkDocument(Uuid docUuid,
      {String? documentTitle, String? textContent}) async {
    final id = activeTripIdNotifier.value;
    if (id == null || isPausedNotifier.value) return;
    try {
      final author = await currentUserService.currentOrSystem();
      await appDatabase.linkDocumentToTrip(docUuid, id, authorUuid: author);
      final label =
          documentTitle != null ? '"$documentTitle"' : 'doc $docUuid';
      final sb = StringBuffer(_logLine(
          LocServ.inst.t('trip_log_document_added', {'label': label})));
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

  Future<Uuid?> getActiveTripCaveId() async {
    final trip = await getActiveTrip();
    return trip?.caveUuid;
  }

  Future<void> _append(String line, Uuid tripUuid) async {
    try {
      await appDatabase.appendToTripLog(tripUuid, line);
    } catch (_) {}
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
