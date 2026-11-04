import 'dart:io';

import 'package:sqlite3/sqlite3.dart' show OpenMode, sqlite3;

/// Thrown for a database file written by a newer version of the app: its
/// schema holds tables or columns this version does not know.
///
/// Such a file is never opened through the app's database. Drift would
/// otherwise stamp it down to this version's number, which destroys the one
/// record that it is newer, and the newer version's next upgrade would then
/// re-run steps over data they have already converted.
class DatabaseTooNewException implements Exception {
  const DatabaseTooNewException({
    required this.fileVersion,
    required this.supportedVersion,
  });

  /// The schema version the file is stamped with.
  final int fileVersion;

  /// The newest schema version this app opens.
  final int supportedVersion;

  @override
  String toString() =>
      'DatabaseTooNewException: the database is at schema version '
      '$fileVersion, newer than this app supports ($supportedVersion). '
      'Update the app to open it.';
}

/// Reads the schema version [file] is stamped with, read-only and outside
/// drift, which would start upgrading the file on open.
int readDatabaseFileVersion(File file) {
  final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    return db.userVersion;
  } finally {
    db.close();
  }
}

/// Throws [DatabaseTooNewException] when [file] was written by an app whose
/// schema is newer than [supportedVersion]. Called before a file replaces
/// the live database, so a refused file costs nothing.
void ensureDatabaseFileNotNewer(File file, {required int supportedVersion}) {
  final fileVersion = readDatabaseFileVersion(file);
  if (fileVersion > supportedVersion) {
    throw DatabaseTooNewException(
      fileVersion: fileVersion,
      supportedVersion: supportedVersion,
    );
  }
}
