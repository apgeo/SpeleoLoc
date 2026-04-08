import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/constants.dart';

class CaveTripService {
  CaveTripService._();
  static final CaveTripService instance = CaveTripService._();

  final ValueNotifier<int?> activeTripIdNotifier = ValueNotifier<int?>(null);

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
    final tripId = await appDatabase.insertCaveTrip(
      caveId: caveId,
      title: title,
      startedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _saveConfig(tripId);
    activeTripIdNotifier.value = tripId;
    return tripId;
  }

  Future<void> stopTrip() async {
    final id = activeTripIdNotifier.value;
    if (id != null) {
      await appDatabase.endCaveTrip(id);
    }
    await _clearConfig();
    activeTripIdNotifier.value = null;
  }

  Future<void> recordPoint(int cavePlaceId) async {
    final id = activeTripIdNotifier.value;
    if (id == null) return;
    try {
      await appDatabase.insertTripPoint(tripId: id, cavePlaceId: cavePlaceId);
    } catch (_) {}
  }

  Future<void> linkDocument(int docId) async {
    final id = activeTripIdNotifier.value;
    if (id == null) return;
    try {
      await appDatabase.linkDocumentToTrip(docId, id);
    } catch (_) {}
  }

  Future<CaveTrip?> getActiveTrip() => appDatabase.getActiveTrip();

  Future<int?> getActiveTripCaveId() async {
    final trip = await getActiveTrip();
    return trip?.caveId;
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
