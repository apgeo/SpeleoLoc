import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/app_bootstrap.dart';
import 'package:speleoloc/data/source/database/database_file_version.dart';
import 'package:speleoloc/screens/startup/startup_failure_app.dart';
import 'package:speleoloc/services/startup/startup_failure.dart';
import 'package:speleoloc/services/startup/startup_recovery.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// A start that fails shows a screen to recover from, never the splash for
/// good. Start-up is injected; nothing here opens a real database.
void main() {
  late _FakeRecovery recovery;
  late List<Widget> shown;
  late int prepared;

  String t(String key) => LocServ.inst.t(key);

  setUpAll(() async {
    await LocServ.inst.setLocale('en');
    await LocServ.inst.load();
  });

  setUp(() {
    recovery = _FakeRecovery();
    shown = [];
    prepared = 0;
  });

  /// Starts the app with [steps] answering each attempt in turn: an error
  /// to throw, or null to succeed.
  Future<void> boot(WidgetTester tester, List<Object?> steps) async {
    var attempt = 0;
    await startApp(
      start: () async {
        final outcome = steps[attempt++];
        if (outcome != null) throw outcome;
      },
      prepareRetry: () async => prepared++,
      app: () => const MaterialApp(home: Text('the real app')),
      recovery: recovery,
      run: shown.add,
    );
    await tester.pumpWidget(shown.last);
  }

  /// Pumps whatever the bootstrap ran last, once a tap made it run again.
  Future<void> showLatest(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pumpWidget(shown.last);
    await tester.pumpAndSettle();
  }

  testWidgets('a start that works shows the app', (tester) async {
    await boot(tester, [null]);

    expect(find.text('the real app'), findsOneWidget);
  });

  testWidgets('a database from a newer app asks for an update and offers no '
      'reset', (tester) async {
    await boot(tester, [
      const DatabaseTooNewException(fileVersion: 99, supportedVersion: 37),
    ]);

    expect(shown.single, isA<StartupFailureApp>());
    expect(find.text(t('startup_failed_title')), findsOneWidget);
    expect(find.text(t('startup_failed_database_too_new')), findsOneWidget);
    expect(find.text(t('startup_export_database')), findsOneWidget);
    expect(find.text(t('startup_retry')), findsOneWidget);
    expect(find.text(t('startup_reset_app_data')), findsNothing);
  });

  testWidgets('a full disk says so', (tester) async {
    await boot(tester, [const FileSystemException('invented: no space')]);

    expect(find.text(t('startup_failed_storage')), findsOneWidget);
    expect(find.text(t('startup_reset_app_data')), findsOneWidget);
  });

  testWidgets('Export saves the database file', (tester) async {
    await boot(tester, [
      SqliteException(
        extendedResultCode: 26,
        message: 'invented: not a database',
      ),
    ]);
    expect(find.text(t('startup_failed_database_unreadable')), findsOneWidget);

    await tester.tap(find.text(t('startup_export_database')));
    await tester.pumpAndSettle();

    expect(recovery.exports, 1);
    expect(find.textContaining('/invented/export.sqlite'), findsOneWidget);
  });

  testWidgets('Retry that fails again shows the new error, and one that works '
      'shows the app', (tester) async {
    await boot(tester, [
      const FileSystemException('invented: no space'),
      const DatabaseTooNewException(fileVersion: 99, supportedVersion: 37),
      null,
    ]);

    await tester.tap(find.text(t('startup_retry')));
    await tester.pumpAndSettle();
    expect(prepared, 1);
    expect(find.text(t('startup_failed_database_too_new')), findsOneWidget);

    await tester.tap(find.text(t('startup_retry')));
    await showLatest(tester);
    expect(prepared, 2);
    expect(find.text('the real app'), findsOneWidget);
  });

  testWidgets('Reset asks first; cancelling deletes nothing', (tester) async {
    await boot(tester, [const FileSystemException('invented: no space')]);

    await tester.tap(find.text(t('startup_reset_app_data')));
    await tester.pumpAndSettle();
    expect(find.text(t('startup_reset_confirm')), findsOneWidget);

    await tester.tap(find.text(t('cancel')));
    await tester.pumpAndSettle();
    expect(recovery.resets, 0);
    expect(find.text(t('startup_reset_confirm')), findsNothing);
  });

  testWidgets('Reset offers an export first, then deletes and starts again', (
    tester,
  ) async {
    await boot(tester, [const FileSystemException('invented: no space'), null]);

    await tester.tap(find.text(t('startup_reset_app_data')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t('startup_reset_export_first')));
    await tester.pumpAndSettle();
    expect(recovery.exports, 1);
    expect(recovery.resets, 0);
    // Asked again once the copy is saved.
    expect(find.text(t('startup_reset_confirm')), findsOneWidget);

    await tester.tap(find.text(t('startup_reset_delete')));
    await showLatest(tester);
    expect(recovery.resets, 1);
    expect(find.text('the real app'), findsOneWidget);
  });

  test('a damaged database is told apart from an unknown failure', () {
    expect(
      classifyStartupFailure(
        SqliteException(extendedResultCode: 11, message: 'invented: malformed'),
      ),
      StartupFailureKind.databaseUnreadable,
    );
    expect(
      classifyStartupFailure(StateError('invented')),
      StartupFailureKind.unknown,
    );
  });
}

class _FakeRecovery implements StartupRecovery {
  int exports = 0;
  int resets = 0;

  @override
  Future<String?> exportDatabase() async {
    exports++;
    return '/invented/export.sqlite';
  }

  @override
  Future<void> resetAppData() async => resets++;
}
