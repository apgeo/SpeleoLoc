import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/test_database_loader.dart';
import 'package:restart_app/restart_app.dart';

/// Reusable helper for database reinitialize / restore operations.
///
/// Extracted from [SettingsDatabasePage] so that other screens
/// (e.g. the home page's test-data prompt) can reuse the same logic.
class DatabaseRestoreHelper {
  DatabaseRestoreHelper._();

  /// Closes the current database, deletes the file, and creates a fresh one.
  ///
  /// If [populateTestData] is true the new database is seeded via
  /// [TestDatabaseLoader]; otherwise an empty [AppDatabase] is created.
  ///
  /// Returns `true` on success, `false` on failure.
  static Future<bool> reinitializeDatabase({
    required bool populateTestData,
  }) async {
    await appDatabase.close();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/speleo_loc.sqlite');
    if (await file.exists()) {
      await file.delete();
    }

    if (populateTestData) {
      final newDb = await TestDatabaseLoader.loadTestDatabase();
      appDatabase = newDb;
      logMigrationIfAny(source: 'test-database-restore');
    } else {
      final newDb = AppDatabase();
      appDatabase = newDb;
      logMigrationIfAny(source: 'empty-database-reinitialize');
    }
    return true;
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
    debugPrint(
      '[DatabaseRestore] Migration detected after $source: '
      'v${event.fromVersion} -> v${event.toVersion} at ${event.timestamp.toIso8601String()}',
    );
  }
}
