import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// A local row's name and stamp, as a decision needs them.
class SilexgisLocalRow {
  const SilexgisLocalRow({this.title, this.updatedAt});

  final String? title;
  final int? updatedAt;
}

/// Reads the name and stamp of one row of a table a resolver names.
///
/// Table names reach the SQL only from [tables], which the caller fixes in
/// code — never from stored text.
class SilexgisLocalRowLookup {
  const SilexgisLocalRowLookup(this._db, {required this.tables});

  final AppDatabase _db;
  final Set<String> tables;

  /// The row of [table] with [uuid], or null when there is none — or when
  /// [table] is not one of [tables].
  Future<SilexgisLocalRow?> read(String table, Uuid uuid) async {
    if (!tables.contains(table)) return null;
    final rows = await _db
        .customSelect(
          'SELECT title, updated_at FROM $table WHERE uuid = ? LIMIT 1',
          variables: <Variable<Object>>[Variable<Uint8List>(uuid.bytes)],
        )
        .get();
    if (rows.isEmpty) return null;
    final row = rows.single;
    return SilexgisLocalRow(
      title: row.read<String?>('title'),
      updatedAt: row.read<int?>('updated_at'),
    );
  }
}
