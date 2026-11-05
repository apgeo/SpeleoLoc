import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/data/source/database/database_file_version.dart';

/// A database file written by a newer version of the app is refused, and
/// keeps the version it is stamped with. Every database is made here.
void main() {
  late Directory tmp;
  late int latest;

  setUpAll(() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    latest = db.schemaVersion;
    await db.close();
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('database_file_version_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  /// A database at the current schema, then stamped [version].
  Future<File> fileAt(int version) async {
    final f = File(p.join(tmp.path, 'v$version.sqlite'));
    final db = AppDatabase.forTesting(NativeDatabase(f));
    await db.customSelect('SELECT 1').get();
    await db.close();
    final raw = sqlite3.open(f.path);
    try {
      raw.userVersion = version;
    } finally {
      raw.close();
    }
    return f;
  }

  test('opening a newer file fails and leaves its stamp alone', () async {
    final f = await fileAt(latest + 1);

    for (var attempt = 0; attempt < 2; attempt++) {
      final db = AppDatabase.forTesting(NativeDatabase(f));
      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(
          isA<DatabaseTooNewException>()
              .having((e) => e.fileVersion, 'fileVersion', latest + 1)
              .having((e) => e.supportedVersion, 'supportedVersion', latest),
        ),
      );
      await db.close();
    }

    expect(readDatabaseFileVersion(f), latest + 1);
  });

  test('the check before a file replaces the database refuses only a newer '
      'one', () async {
    final older = await fileAt(latest - 1);
    final same = await fileAt(latest);
    final newer = await fileAt(latest + 1);

    ensureDatabaseFileNotNewer(older, supportedVersion: latest);
    ensureDatabaseFileNotNewer(same, supportedVersion: latest);
    expect(
      () => ensureDatabaseFileNotNewer(newer, supportedVersion: latest),
      throwsA(isA<DatabaseTooNewException>()),
    );
    expect(readDatabaseFileVersion(older), latest - 1);
  });
}
