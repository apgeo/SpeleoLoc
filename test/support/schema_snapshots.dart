import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

/// The schema of every version the app can be upgraded from, as drift created
/// it on a fresh install of that version: `drift_schemas/schema_vN.sql`, one
/// CREATE statement per table, index and trigger, in creation order.
///
/// A database at an old version is built from these and invented rows, so a
/// migration test needs neither a file from a real phone nor the old app.
const String schemaSnapshotDir = 'drift_schemas';

/// Set to 1 to have the schema tests write the current version's snapshot
/// instead of comparing against it, after a change to the schema.
const String writeSchemaSnapshotVariable = 'SPELEOLOC_WRITE_SCHEMA_SNAPSHOT';

File schemaSnapshotFile(int version) =>
    File(p.join(schemaSnapshotDir, 'schema_v$version.sql'));

/// The versions there is a snapshot of, ascending.
List<int> schemaSnapshotVersions() {
  final pattern = RegExp(r'^schema_v(\d+)\.sql$');
  return [
    for (final f in Directory(schemaSnapshotDir).listSync().whereType<File>())
      if (pattern.firstMatch(p.basename(f.path)) case final m?)
        int.parse(m.group(1)!),
  ]..sort();
}

/// Creates [path] holding the schema of [version], runs [seed] on it, then
/// stamps it [version], as the app at that version would have left it.
File createDatabaseAtVersion(
  String path,
  int version, {
  void Function(Database d)? seed,
}) {
  final d = sqlite3.open(path);
  try {
    d.execute(schemaSnapshotFile(version).readAsStringSync());
    seed?.call(d);
    d.userVersion = version;
  } finally {
    d.close();
  }
  return File(path);
}

/// Opens [f] through [AppDatabase], which runs the upgrade, and closes it.
Future<void> openThroughApp(File f) async {
  final db = AppDatabase.forTesting(NativeDatabase(f));
  try {
    await db.customSelect('SELECT 1').get();
  } finally {
    await db.close();
  }
}

/// The schema of [f] in the snapshot format, without its header comment.
String schemaSql(File f) {
  final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
  try {
    final rows = d.select(
      'SELECT sql FROM sqlite_master WHERE sql IS NOT NULL '
      "AND name NOT LIKE 'sqlite_%' ORDER BY rowid",
    );
    return [for (final r in rows) '${r['sql']};\n'].join('\n');
  } finally {
    d.close();
  }
}

/// [sql] without comment lines and blank lines.
String withoutComments(String sql) => sql
    .split('\n')
    .where((l) => l.trim().isNotEmpty && !l.startsWith('--'))
    .join('\n');

/// `PRAGMA foreign_key_check` of [f], one line per violation.
List<String> foreignKeyViolations(File f) {
  final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
  try {
    return [
      for (final r in d.select('PRAGMA foreign_key_check'))
        '${r['table']} row ${r['rowid']} -> ${r['parent']}',
    ];
  } finally {
    d.close();
  }
}

int userVersionOf(File f) {
  final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
  try {
    return d.userVersion;
  } finally {
    d.close();
  }
}
