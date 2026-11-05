import 'dart:io';
import 'dart:typed_data';

import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

/// Database files for the tests of whatever replaces the live database.
/// Every value in them is invented.

/// An app database at the current schema holding `invented_key` = [marker].
Future<File> appDatabaseFile(String path, {String marker = 'incoming'}) async {
  final file = File(path);
  final db = AppDatabase.file(file);
  await ConfigurationRepository(db).writeString('invented_key', marker);
  await db.close();
  return file;
}

/// An SQLite database some other program wrote: none of this app's tables.
File foreignSqliteFile(String path) {
  final raw = sqlite3.open(path);
  try {
    raw.execute('CREATE TABLE invented_notes (body TEXT)');
    raw.execute("INSERT INTO invented_notes VALUES ('not a cave')");
  } finally {
    raw.close();
  }
  return File(path);
}

/// An app database whose header is intact but whose later pages are
/// overwritten, so it opens and reports its version but fails SQLite's
/// integrity check.
Future<File> damagedAppDatabaseFile(String path) async {
  final file = await appDatabaseFile(path);
  final raw = sqlite3.open(path);
  try {
    raw.execute('CREATE TABLE invented_filler (body TEXT)');
    final filler = 'x' * 900;
    for (var i = 0; i < 200; i++) {
      raw.execute('INSERT INTO invented_filler VALUES (?)', ['$i$filler']);
    }
  } finally {
    raw.close();
  }
  final bytes = await file.readAsBytes();
  const pageSize = 4096;
  final damaged = Uint8List.fromList(bytes);
  for (var i = pageSize * 2; i < bytes.length - pageSize; i++) {
    damaged[i] = 0xA5;
  }
  await file.writeAsBytes(damaged, flush: true);
  return file;
}
