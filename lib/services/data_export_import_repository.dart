import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/constants.dart';

/// Data access layer for export/import operations.
///
/// All raw database queries (attach, read, insert, update, conflict detection)
/// are isolated here, keeping business logic in [DataArchiveService].
class DataExportImportRepository {
  final AppDatabase _db;

  DataExportImportRepository(this._db);

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
    final now = DateTime.now().millisecondsSinceEpoch;
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

  // ---------------------------------------------------------------------------
  //  Attached database operations (for merge import)
  // ---------------------------------------------------------------------------

  Future<void> attachImportedDb(String path) async {
    // Normalize Windows back-slashes for SQLite.
    final safePath = path.replaceAll('\\', '/');
    await _db.customStatement("ATTACH DATABASE '$safePath' AS imported");
  }

  Future<void> detachImportedDb() async {
    await _db.customStatement('DETACH DATABASE imported');
  }

  /// Read every row from [tableName] in the attached *imported* database.
  Future<List<Map<String, dynamic>>> getImportedTableRows(
      String tableName) async {
    final rows =
        await _db.customSelect('SELECT * FROM imported.$tableName').get();
    return rows.map((r) => r.data).toList();
  }

  // ---------------------------------------------------------------------------
  //  Conflict detection
  // ---------------------------------------------------------------------------

  /// Checks each unique-constraint group in [uniqueConstraints] against the
  /// local database.  Returns the first matching row, or `null`.
  Future<Map<String, dynamic>?> findConflict(
    String tableName,
    List<List<String>> uniqueConstraints,
    Map<String, dynamic> row,
  ) async {
    for (final constraint in uniqueConstraints) {
      final conditions = <String>[];
      final args = <Variable<Object>>[];
      bool hasNull = false;

      for (final col in constraint) {
        final val = row[col];
        if (val == null) {
          // SQLite treats NULLs as distinct in UNIQUE → no conflict possible.
          hasNull = true;
          break;
        }
        conditions.add('"$col" = ?');
        args.add(_toVar(val));
      }

      if (hasNull || conditions.isEmpty) continue;

      final result = await _db
          .customSelect(
            'SELECT * FROM "$tableName" WHERE ${conditions.join(' AND ')} LIMIT 1',
            variables: args,
          )
          .getSingleOrNull();

      if (result != null) return result.data;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  //  Row manipulation
  // ---------------------------------------------------------------------------

  /// Insert a row into [tableName] and return the new auto-generated id.
  Future<int> insertRow(
    String tableName,
    List<String> columns,
    Map<String, dynamic> values,
  ) async {
    final cols = columns.where((c) => values.containsKey(c)).toList();
    if (cols.isEmpty) return -1;

    final placeholders = cols.map((_) => '?').join(', ');
    final args = cols.map((c) => values[c]).toList();
    final quotedCols = cols.map((c) => '"$c"').join(', ');

    await _db.customStatement(
      'INSERT INTO "$tableName" ($quotedCols) VALUES ($placeholders)',
      args,
    );

    final result =
        await _db.customSelect('SELECT last_insert_rowid() AS id').getSingle();
    return result.read<int>('id');
  }

  /// Overwrite non-id columns of the row with the given [id].
  Future<void> updateRow(
    String tableName,
    int id,
    List<String> columns,
    Map<String, dynamic> values,
  ) async {
    final setClauses = <String>[];
    final args = <dynamic>[];

    for (final col in columns) {
      if (values.containsKey(col)) {
        setClauses.add('"$col" = ?');
        args.add(values[col]);
      }
    }
    if (setClauses.isEmpty) return;

    args.add(id);
    await _db.customStatement(
      'UPDATE "$tableName" SET ${setClauses.join(', ')} WHERE id = ?',
      args,
    );
  }

  /// Whether the local database already contains meaningful data.
  Future<bool> hasData() async {
    final row =
        await _db.customSelect('SELECT COUNT(*) AS cnt FROM caves').getSingle();
    return row.read<int>('cnt') > 0;
  }

  // ---------------------------------------------------------------------------
  //  Helpers
  // ---------------------------------------------------------------------------

  static Variable<Object> _toVar(dynamic val) {
    if (val is int) return Variable.withInt(val);
    if (val is String) return Variable.withString(val);
    if (val is double) return Variable.withReal(val);
    if (val is bool) return Variable.withBool(val);
    return Variable(val as Object);
  }
}
