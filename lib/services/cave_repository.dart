import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

class CaveRepository {
  final AppDatabase _database;

  CaveRepository(this._database);

  Future<List<Cave>> getCaves() async {
    try {
      return await _database.select(_database.caves).get();
    } catch (e) {
      print('[CaveRepository] Failed to load caves: $e');
      rethrow;
    }
  }

  Future<int> addCave(String title, {int? surfaceAreaId, String? description}) async {
    try {
      final companion = CavesCompanion(
        title: Value(title),
        surfaceAreaId: Value(surfaceAreaId),
        description: Value(description),
      );
      return await _database.into(_database.caves).insert(companion);
    } catch (e) {
      print('[CaveRepository] Failed to add cave: $e');
      rethrow;
    }
  }

  Future<void> updateCave(int id, String title, {int? surfaceAreaId, String? description}) async {
    try {
      await (_database.update(_database.caves)..where((c) => c.id.equals(id))).write(
        CavesCompanion(
          title: Value(title),
          surfaceAreaId: Value(surfaceAreaId),
          description: Value(description),
        ),
      );
    } catch (e) {
      print('[CaveRepository] Failed to update cave: $e');
      rethrow;
    }
  }

  Future<void> deleteCave(int id) async {
    try {
      await (_database.delete(_database.caves)..where((c) => c.id.equals(id))).go();
    } catch (e) {
      print('[CaveRepository] Failed to delete cave: $e');
      rethrow;
    }
  }

  Future<List<CaveArea>> getCaveAreas(int caveId) async {
    try {
      return await (_database.select(_database.caveAreas)..where((ca) => ca.caveId.equals(caveId))).get();
    } catch (e) {
      print('[CaveRepository] Failed to load cave areas: $e');
      rethrow;
    }
  }
}