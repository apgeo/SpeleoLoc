import 'package:drift/drift.dart';

/// Very old data stored some of these timestamps in seconds; everything
/// written since uses milliseconds. Left as they are, such values lose every
/// newest-wins comparison and show dates in 1970.
const Set<String> legacyTimestampColumns = {
  'created_at',
  'updated_at',
  'deleted_at',
  'changed_at',
  'scanned_at',
  'trip_started_at',
  'trip_ended_at',
};

/// A millisecond timestamp below this would fall before 1973, so a smaller
/// non-zero value can only be seconds.
const int _secondsCeiling = 100000000000;

/// Returns [value] in milliseconds, converting a legacy value in seconds.
int? timestampToMillis(int? value) =>
    value != null && value > 0 && value < _secondsCeiling
    ? value * 1000
    : value;

/// Rewrites every legacy seconds value of [legacyTimestampColumns] in [db]
/// to milliseconds. Only such values change, so running it again does
/// nothing. Done in place rather than as a schema migration: a schema bump
/// would make devices not yet updated refuse this device's sync archives.
/// Nothing is change-logged, so it does not by itself cause an upload.
///
/// Columns are taken from the file itself, not from the declared schema: a
/// database brought up from an old version need not have every declared
/// column.
Future<void> normalizeLegacyTimestamps(GeneratedDatabase db) async {
  for (final table in db.allTables) {
    final present = await db
        .customSelect('PRAGMA table_info(${table.actualTableName})')
        .get();
    for (final row in present) {
      final c = row.read<String>('name');
      if (!legacyTimestampColumns.contains(c)) continue;
      await db.customStatement(
        'UPDATE ${table.actualTableName} SET $c = $c * 1000 '
        'WHERE $c > 0 AND $c < $_secondsCeiling',
      );
    }
  }
}
