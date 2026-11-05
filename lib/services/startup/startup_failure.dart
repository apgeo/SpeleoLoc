import 'dart:io';

import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:speleoloc/data/source/database/database_file_version.dart';
import 'package:speleoloc/services/database_swap/database_file_validator.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// What kind of failure stopped the app from starting, for a message the
/// caver can act on.
enum StartupFailureKind {
  /// The database was written by a newer app; updating the app opens it.
  databaseTooNew,

  /// The database file does not open or read, most likely damaged.
  databaseUnreadable,

  /// The app's files could not be read or written; often a full disk.
  storage,

  /// Anything else.
  unknown,
}

StartupFailureKind classifyStartupFailure(Object error) {
  final cause = error is DriftRemoteException ? error.remoteCause : error;
  return switch (cause) {
    DatabaseTooNewException() => StartupFailureKind.databaseTooNew,
    SqliteException() ||
    InvalidDatabaseFileException() => StartupFailureKind.databaseUnreadable,
    FileSystemException() => StartupFailureKind.storage,
    _ => StartupFailureKind.unknown,
  };
}
