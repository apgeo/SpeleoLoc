import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/database_file_version.dart';
import 'package:speleoloc/data/source/database/migrations/migrations.dart';
import 'package:speleoloc/data/source/database/migrations/schema_migration.dart';

/// Brings a database stamped [from] up to [to] by applying every step of
/// [schemaMigrations] that [SchemaMigration.shouldApply] selects.
///
/// The steps and the new `user_version` are written in one transaction.
/// Drift wraps nothing and stamps the version only after `beforeOpen` has
/// run too, so an upgrade cut short by a kill or a throwing step used to
/// leave a half-upgraded file still stamped [from], and the next open re-ran
/// steps that cannot run twice. Cut short now, the file stays exactly as it
/// was and the next open starts over.
///
/// Foreign keys are off for the whole run, set before the transaction
/// because the pragma does nothing inside one: steps drop and recreate
/// tables other tables point at, and `beforeOpen` turns the checks back on.
///
/// Drift calls this for a file stamped above [to] as well; such a file comes
/// from a newer app and is refused with [DatabaseTooNewException] before
/// anything is written, so drift does not stamp it down.
Future<void> upgradeSchema(
  AppDatabase db,
  Migrator migrator, {
  required int from,
  required int to,
}) async {
  if (from > to) {
    throw DatabaseTooNewException(fileVersion: from, supportedVersion: to);
  }
  await db.customStatement('PRAGMA foreign_keys = OFF');
  await db.transaction(() async {
    for (final m in schemaMigrations) {
      if (m.shouldApply(from)) {
        await m.apply(db, migrator);
      }
    }
    await db.customStatement('PRAGMA user_version = $to');
  });
}
