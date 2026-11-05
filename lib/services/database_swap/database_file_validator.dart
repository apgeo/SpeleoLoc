import 'dart:io';
import 'dart:isolate';

import 'package:speleoloc/data/source/database/database_file_version.dart';
import 'package:sqlite3/sqlite3.dart' show OpenMode, SqliteException, sqlite3;

/// Why a file was refused as a replacement for the live database.
enum InvalidDatabaseFileReason {
  /// The file is not an SQLite database at all.
  notADatabase,

  /// An SQLite database, but not one this app wrote.
  notThisApp,

  /// An SQLite database of this app whose pages are damaged.
  damaged,
}

/// Thrown for a file that cannot replace the live database.
class InvalidDatabaseFileException implements Exception {
  const InvalidDatabaseFileException(this.reason, [this.detail]);

  final InvalidDatabaseFileReason reason;

  /// What SQLite said, for the log.
  final String? detail;

  @override
  String toString() =>
      'InvalidDatabaseFileException: ${reason.name}'
      '${detail == null ? '' : ' ($detail)'}';
}

/// Checks [file] before it may replace the live database: it opens as SQLite,
/// holds this app's tables, is not stamped newer than [supportedVersion], and
/// passes SQLite's integrity check. Throws [InvalidDatabaseFileException] or
/// [DatabaseTooNewException]; returns normally when the file is fit.
///
/// Read-only and outside drift, which would start upgrading the file on open.
/// Runs on a separate isolate: the integrity check reads every page, which
/// takes seconds on a large database and would freeze the progress dialog.
Future<void> validateDatabaseFile(File file, {required int supportedVersion}) {
  final path = file.path;
  return Isolate.run(() => _validate(path, supportedVersion));
}

/// SQLITE_CORRUPT: a header SQLite recognises over pages it cannot read.
const int _sqliteCorrupt = 11;

void _validate(String path, int supportedVersion) {
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    final int version;
    final bool hasCoreTable;
    try {
      version = db.userVersion;
      hasCoreTable = db
          .select(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'caves'",
          )
          .isNotEmpty;
    } on SqliteException catch (e) {
      throw InvalidDatabaseFileException(
        e.resultCode == _sqliteCorrupt
            ? InvalidDatabaseFileReason.damaged
            : InvalidDatabaseFileReason.notADatabase,
        e.message,
      );
    }
    if (version > supportedVersion) {
      throw DatabaseTooNewException(
        fileVersion: version,
        supportedVersion: supportedVersion,
      );
    }
    if (!hasCoreTable) {
      throw const InvalidDatabaseFileException(
        InvalidDatabaseFileReason.notThisApp,
      );
    }
    final List<String> problems;
    try {
      problems = [
        for (final row in db.select('PRAGMA integrity_check'))
          '${row.values.first}',
      ];
    } on SqliteException catch (e) {
      throw InvalidDatabaseFileException(
        InvalidDatabaseFileReason.damaged,
        e.message,
      );
    }
    if (problems.length != 1 || problems.single != 'ok') {
      throw InvalidDatabaseFileException(
        InvalidDatabaseFileReason.damaged,
        problems.take(3).join('; '),
      );
    }
  } finally {
    db.close();
  }
}
