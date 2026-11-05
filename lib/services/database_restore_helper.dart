import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/test_database_loader.dart';
import 'package:speleoloc/services/device_preferences_carry_over.dart';
import 'package:speleoloc/services/database_swap/live_database_swap.dart';
import 'package:speleoloc/services/user_identity/user_handover.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/contained_path.dart';
import 'package:restart_app/restart_app.dart';

/// Reusable helper for database reinitialize / restore operations.
///
/// Extracted from [SettingsDatabasePage] so that other screens
/// (e.g. the home page's test-data prompt) can reuse the same logic.
class DatabaseRestoreHelper {
  DatabaseRestoreHelper._();

  /// Replaces the live database with an empty one, or with the bundled test
  /// database when [populateTestData] is true, through [swap]: a failure at
  /// any step puts the previous database back.
  ///
  /// The test database is read before anything is touched and
  /// [TestDatabaseUnavailableException] thrown when this build lacks it.
  static Future<void> reinitializeDatabase({
    required bool populateTestData,
    required LiveDatabaseSwap swap,
    Future<List<int>?> Function() loadTestDatabaseBytes =
        TestDatabaseLoader.loadDatabaseBytes,
    Future<void> Function(AppDatabase db) copyTestResources =
        TestDatabaseLoader.copyResourceFiles,
  }) async {
    swap.ensureNoSyncRunning();
    Directory? seedDir;
    File? seed;
    if (populateTestData) {
      final bytes = await loadTestDatabaseBytes();
      if (bytes == null) throw const TestDatabaseUnavailableException();
      seedDir = await Directory.systemTemp.createTemp('speleo_loc_test_db_');
      seed = File(p.join(seedDir.path, databaseFileName));
      await seed.writeAsBytes(bytes, flush: true);
    }
    try {
      final userHandover = await UserHandoverStore(appDatabase).capture();
      final devicePreferences = await DevicePreferencesCarryOver.capture(
        appDatabase,
      );
      await swap.replaceWith(
        seed,
        afterOpen: (db) async {
          logMigrationIfAny(
            source: populateTestData
                ? 'test-database-restore'
                : 'empty-database-reinitialize',
          );
          if (populateTestData) await copyTestResources(db);
          await UserHandoverStore(db).handOver(userHandover);
          await devicePreferences.applyTo(db);
        },
      );
    } finally {
      try {
        await seedDir?.delete(recursive: true);
      } catch (e, st) {
        AppLogger.of(
          'DatabaseRestoreHelper',
        ).fine('test database copy cleanup failed', e, st);
      }
    }
  }

  /// Restarts the application via the restart_app plugin.
  static Future<void> restartApplication() async {
    await Restart.restartApp(
      notificationTitle: 'Restarting App',
      notificationBody: 'Please tap here to open the app again.',
    );
  }

  static void logMigrationIfAny({required String source}) {
    final event = DatabaseMigrationMonitor.consumeLatest();
    if (event == null) return;
    if (event.toVersion <= event.fromVersion) return;
    AppLogger.of('DatabaseRestoreHelper').info(
      'Migration detected after $source: '
      'v${event.fromVersion} -> v${event.toVersion} at ${event.timestamp.toIso8601String()}',
    );
  }
}
