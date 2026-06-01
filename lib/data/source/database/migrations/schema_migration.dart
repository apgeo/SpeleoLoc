import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// A single schema migration step. Migrations are registered in
/// [schemaMigrations] in ascending order of [toVersion]. During
/// [AppDatabase.migration]'s `onUpgrade`, the engine iterates the list
/// and applies each migration for which [shouldApply] returns true,
/// **using the original `from` value throughout** (each migration
/// observes the same starting version, identical to the pre-refactor
/// chained `if (from < N)` ladder).
abstract class SchemaMigration {
  const SchemaMigration();

  /// The schema version this migration produces.
  int get toVersion;

  /// Default activation rule: `from < toVersion`.
  ///
  /// Some migrations (notably v7→v8) override this to gate on a single
  /// `from` value to preserve the pre-refactor semantics where the
  /// legacy v6→v7 path runs `migrator.createAll()` and therefore must
  /// not re-execute subsequent table-recreation migrations.
  bool shouldApply(int from) => from < toVersion;

  Future<void> apply(AppDatabase db, Migrator migrator);
}

/// Helper for the "SQLite cannot ALTER constraint, so recreate the
/// table and copy rows back" idiom used in v7→v8, v11→v12, v12→v13,
/// v13→v14. Captures the source rows, drops + creates the table using
/// the current Drift schema, and lets the caller reinsert each row
/// with whatever column projection the migration requires.
class TableRecreator {
  const TableRecreator._();

  static Future<void> recreate({
    required AppDatabase db,
    required Migrator migrator,
    required TableInfo table,
    String? selectSql,
    required Future<void> Function(Map<String, Object?> row) reinsert,
  }) async {
    final rows = await db
        .customSelect(selectSql ?? 'SELECT * FROM ${table.actualTableName}')
        .get();
    // Wrap the drop + create + per-row reinsert in a single transaction:
    // without this each customStatement/customInsert auto-commits, causing
    // one fsync per row (on Windows + large fixtures that turns a quick
    // recreate into a multi-minute hang).
    // `defer_foreign_keys` is transaction-scoped and lets us DROP a table
    // referenced by FKs from other tables (the FK targets get re-populated
    // before COMMIT, satisfying the deferred check).
    await db.transaction(() async {
      await db.customStatement('PRAGMA defer_foreign_keys = ON');
      await migrator.drop(table);
      await migrator.create(table);
      for (final row in rows) {
        await reinsert(row.data);
      }
    });
  }
}
