import 'package:speleoloc/data/source/database/database_file_version.dart';
import 'package:speleoloc/data/source/database/test_database_loader.dart';
import 'package:speleoloc/services/database_swap/database_file_validator.dart';
import 'package:speleoloc/services/database_swap/live_database_swap.dart';
import 'package:speleoloc/utils/localization.dart';

/// What to tell the user when a picked database file or archive could not
/// replace the live database.
String databaseFileErrorText(Object error) => switch (error) {
  DatabaseTooNewException() => LocServ.inst.t('database_file_too_new', {
    'file': '${error.fileVersion}',
    'app': '${error.supportedVersion}',
  }),
  InvalidDatabaseFileException(
    reason: InvalidDatabaseFileReason.notADatabase,
  ) =>
    LocServ.inst.t('database_file_not_a_database'),
  InvalidDatabaseFileException(reason: InvalidDatabaseFileReason.notThisApp) =>
    LocServ.inst.t('database_file_not_this_app'),
  InvalidDatabaseFileException(reason: InvalidDatabaseFileReason.damaged) =>
    LocServ.inst.t('database_file_damaged'),
  SyncRunActiveException() => LocServ.inst.t('database_swap_sync_running'),
  TestDatabaseUnavailableException() => LocServ.inst.t(
    'test_database_not_bundled',
  ),
  _ => '$error',
};
