import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// An upgrade that stops part-way — the app killed, a step throwing — must
/// leave a file the next open can still upgrade. A kill cannot be staged in
/// a test, so each case builds the file such an interruption leaves and
/// opens it through [AppDatabase]. Every database is made here; the values
/// are invented.
void main() {
  late Directory tmp;
  late int latest;

  setUpAll(() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    latest = db.schemaVersion;
    await db.close();
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('interrupted_upgrade_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  /// A database file at the current schema, made through drift.
  Future<File> freshFile(String name) async {
    final f = File(p.join(tmp.path, name));
    final db = AppDatabase.forTesting(NativeDatabase(f));
    await db.customSelect('SELECT 1').get();
    await db.close();
    return f;
  }

  /// A stand-in for a v7 database: the current schema without the column
  /// the v7 to v8 step adds, stamped 7, so the whole ladder runs from there.
  Future<File> v7File(String name, [void Function(Database d)? seed]) async {
    final f = await freshFile(name);
    _raw(f, (d) {
      d.execute(
        'ALTER TABLE documentation_files_to_geofeatures DROP COLUMN created_at',
      );
      seed?.call(d);
      d.execute('PRAGMA user_version = 7');
    });
    return f;
  }

  group('a step that fails part-way through the ladder', () {
    test('leaves the file as it was, and the next open upgrades it', () async {
      // The trigger makes the v8 to v9 step fail after the v7 to v8 step has
      // already added its column and recreated two tables.
      final f = await v7File('failing_step.sqlite', (d) {
        d.execute(
          'CREATE TRIGGER invented_failure BEFORE INSERT ON configurations '
          "BEGIN SELECT RAISE(ABORT, 'invented failure'); END",
        );
      });

      expect(await _tryOpen(f), isNotNull);
      expect(_userVersion(f), 7);
      expect(
        _columns(f, 'documentation_files_to_geofeatures'),
        isNot(contains('created_at')),
        reason: 'the steps before the failure must be rolled back with it',
      );

      _raw(f, (d) => d.execute('DROP TRIGGER invented_failure'));
      expect(await _tryOpen(f), isNull);
      expect(_userVersion(f), latest);
      expect(
        _columns(f, 'documentation_files_to_geofeatures'),
        contains('created_at'),
      );
    });
  });
}

/// Opens [f] through [AppDatabase] and returns the error, or null when the
/// open succeeded.
Future<Object?> _tryOpen(File f) async {
  final db = AppDatabase.forTesting(NativeDatabase(f));
  try {
    await db.customSelect('SELECT 1').get();
    return null;
  } catch (e) {
    return e;
  } finally {
    await db.close();
  }
}

void _raw(File f, void Function(Database d) body) {
  final d = sqlite3.open(f.path);
  try {
    body(d);
  } finally {
    d.close();
  }
}

int _userVersion(File f) {
  final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
  try {
    return d.userVersion;
  } finally {
    d.close();
  }
}

Set<String> _columns(File f, String table) {
  final d = sqlite3.open(f.path, mode: OpenMode.readOnly);
  try {
    return {
      for (final r in d.select('PRAGMA table_info($table)'))
        r['name'] as String,
    };
  } finally {
    d.close();
  }
}
