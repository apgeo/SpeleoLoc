import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/clock.dart';
import 'package:speleoloc/utils/constants.dart';

/// Data access layer for export/import operations.
///
/// Raw database queries for export and the import prompts are isolated here,
/// keeping business logic in [DataArchiveService].
class DataExportImportRepository {
  final AppDatabase _db;
  final Clock _clock;

  DataExportImportRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  // ---------------------------------------------------------------------------
  //  Export queries
  // ---------------------------------------------------------------------------

  /// Returns relative file paths from [documentation_files].
  Future<List<String>> getDocumentationFilePaths({
    List<int>? caveIds,
    int? afterTimestamp,
  }) async {
    final conditions = <String>['deleted_at IS NULL'];
    final args = <Variable<Object>>[];

    if (afterTimestamp != null) {
      conditions.add('(created_at > ? OR created_at IS NULL)');
      args.add(Variable.withInt(afterTimestamp));
    }

    final query =
        'SELECT DISTINCT file_name FROM documentation_files WHERE ${conditions.join(' AND ')}';
    final rows = await _db.customSelect(query, variables: args).get();
    return rows.map((r) => r.read<String>('file_name')).toList();
  }

  /// Returns relative file paths from [raster_maps].
  Future<List<String>> getRasterMapFilePaths({
    List<int>? caveIds,
    int? afterTimestamp,
  }) async {
    final conditions = <String>['deleted_at IS NULL'];
    final args = <Variable<Object>>[];

    if (afterTimestamp != null) {
      conditions.add('(created_at > ? OR created_at IS NULL)');
      args.add(Variable.withInt(afterTimestamp));
    }

    final query =
        'SELECT DISTINCT file_name FROM raster_maps WHERE ${conditions.join(' AND ')}';
    final rows = await _db.customSelect(query, variables: args).get();
    return rows.map((r) => r.read<String>('file_name')).toList();
  }

  // ---------------------------------------------------------------------------
  //  Export timestamp tracking
  // ---------------------------------------------------------------------------

  Future<int?> getLastExportTimestamp() async {
    final row = await _db
        .customSelect(
          'SELECT value FROM configurations WHERE title = ?',
          variables: [Variable.withString(lastExportTimestampKey)],
        )
        .getSingleOrNull();
    if (row != null) {
      final val = row.readNullable<String>('value');
      if (val != null) return int.tryParse(val);
    }
    return null;
  }

  Future<void> setLastExportTimestamp(int timestamp) async {
    final now = _clock.nowMs();
    final existing = await _db
        .customSelect(
          'SELECT id FROM configurations WHERE title = ?',
          variables: [Variable.withString(lastExportTimestampKey)],
        )
        .getSingleOrNull();

    if (existing != null) {
      await _db.customStatement(
        'UPDATE configurations SET value = ?, updated_at = ? WHERE title = ?',
        [timestamp.toString(), now, lastExportTimestampKey],
      );
    } else {
      await _db.customStatement(
        'INSERT INTO configurations (title, value, created_at, updated_at) VALUES (?, ?, ?, ?)',
        [lastExportTimestampKey, timestamp.toString(), now, now],
      );
    }
  }

  /// Whether the local database already contains meaningful data.
  Future<bool> hasData() async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS cnt FROM caves')
        .getSingle();
    return row.read<int>('cnt') > 0;
  }

  /// Returns `true` when any caves, raster maps, or documentation files exist.
  ///
  /// Used by the export/import page to determine whether to show a
  /// replace-import confirmation prompt.
  Future<bool> hasAnyData() async {
    for (final table in const ['caves', 'raster_maps', 'documentation_files']) {
      final row = await _db
          .customSelect(
            'SELECT COUNT(*) AS cnt FROM $table WHERE deleted_at IS NULL',
          )
          .getSingle();
      if (row.read<int>('cnt') > 0) return true;
    }
    return false;
  }
}
