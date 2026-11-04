import 'package:speleoloc/data/source/database/database_file_version.dart';
import 'package:speleoloc/utils/localization.dart';

/// What to tell the user when a picked database file or archive could not
/// replace the live database.
String databaseFileErrorText(Object error) => error is DatabaseTooNewException
    ? LocServ.inst.t('database_file_too_new', {
        'file': '${error.fileVersion}',
        'app': '${error.supportedVersion}',
      })
    : '$error';
