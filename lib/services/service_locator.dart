import 'package:speleo_loc/data/source/database/app_database.dart';
import 'package:speleo_loc/services/cave_repository.dart';
import 'package:speleo_loc/services/cave_place_repository.dart';
import 'package:speleo_loc/services/raster_map_repository.dart';
import 'package:speleo_loc/services/definition_repository.dart';

// Global repository instances (can be replaced with a DI container later)
final caveRepository = CaveRepository(appDatabase);
final cavePlaceRepository = CavePlaceRepository(appDatabase);
final rasterMapRepository = RasterMapRepository(appDatabase);
final definitionRepository = DefinitionRepository(appDatabase);

/// Session-level preferences that persist for the lifetime of the app process.
class SessionPrefs {
  SessionPrefs._();
  static final SessionPrefs instance = SessionPrefs._();

  /// User has confirmed auto-save when switching map/place.
  /// Resets on app restart.
  bool autoSaveConfirmed = false;

  void reset() {
    autoSaveConfirmed = false;
  }
}