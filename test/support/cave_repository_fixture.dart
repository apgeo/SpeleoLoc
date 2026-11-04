import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_repository.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/user_repository.dart';

/// A [CaveRepository] over [db] that stamps and logs its writes as the app
/// does, for tests of code that writes caves through it.
Future<CaveRepository> buildCaveRepository(AppDatabase db) async {
  late ChangeLogger logger;
  final currentUser = CurrentUserService(
    db,
    UserRepository(db, () => logger),
    ConfigurationRepository(db),
  );
  await currentUser.initialize();
  logger = ChangeLogger(db, currentUser);
  return CaveRepository(db, currentUser, logger);
}
