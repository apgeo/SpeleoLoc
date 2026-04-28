import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Repository for the `users` table.
///
/// Users are syncable across devices; `username` is the natural key. On
/// sync, two user rows that share the same `username` are auto-merged
/// (see sync-v2 design notes).
abstract class IUserRepository {
  Future<List<User>> getUsers();
  Stream<List<User>> watchUsers();
  Future<User?> findByUuid(Uuid uuid);
  Future<User?> findByUsername(String username);
  Future<Uuid> addUser({
    required String username,
    String? firstName,
    String? lastName,
    String? details,
    Uuid? authorUserUuid,
  });
  Future<void> updateUser(
    Uuid uuid, {
    required String username,
    String? firstName,
    String? lastName,
    String? details,
    required Uuid authorUserUuid,
  });
  Future<void> softDeleteUser(Uuid uuid, {required Uuid authorUserUuid});
}

class UserRepository implements IUserRepository {
  final AppDatabase _database;
  // Lazy resolver to break the construction cycle:
  // UserRepository → ChangeLogger → CurrentUserService → UserRepository.
  // The logger is resolved on first write, after all providers have
  // been built.
  final ChangeLogger Function() _logger;
  final _log = AppLogger.of('UserRepository');

  UserRepository(this._database, this._logger);

  @override
  Future<List<User>> getUsers() async {
    try {
      final q = _database.select(_database.users)
        ..where((u) => u.deletedAt.isNull());
      return await q.get();
    } catch (e, st) {
      _log.severe('Failed to load users', e, st);
      throw DbException('Failed to load users', cause: e, stackTrace: st);
    }
  }

  @override
  Stream<List<User>> watchUsers() {
    return (_database.select(_database.users)
          ..where((u) => u.deletedAt.isNull()))
        .watch();
  }

  @override
  Future<User?> findByUuid(Uuid uuid) async {
    final q = _database.select(_database.users)
      ..where((u) => u.uuid.equalsValue(uuid))
      ..limit(1);
    return (await q.get()).firstOrNull;
  }

  @override
  Future<User?> findByUsername(String username) async {
    final q = _database.select(_database.users)
      ..where((u) => u.username.equals(username))
      ..limit(1);
    return (await q.get()).firstOrNull;
  }

  @override
  Future<Uuid> addUser({
    required String username,
    String? firstName,
    String? lastName,
    String? details,
    Uuid? authorUserUuid,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final newUuid = Uuid.v7();
      // Self-authored if authorUserUuid is null (first-ever user).
      final author = authorUserUuid ?? newUuid;
      await _database.into(_database.users).insert(
            UsersCompanion.insert(
              uuid: newUuid,
              username: username,
              firstName: Value(firstName),
              lastName: Value(lastName),
              details: Value(details),
              createdAt: Value(now),
              updatedAt: Value(now),
              createdByUserUuid: Value(author),
              lastModifiedByUserUuid: Value(author),
            ),
          );
      // Skip change-logging for self-authored bootstrap inserts (authorUserUuid
      // == null), i.e. the "system" user created on first launch.  Calling
      // _logger() at that point triggers a Riverpod CircularDependencyError:
      //   UserRepository → ChangeLogger → CurrentUserService → UserRepository.
      if (authorUserUuid != null) {
        await _logger().logInsert('users', newUuid);
      }
      return newUuid;
    } catch (e, st) {
      _log.severe('Failed to add user', e, st);
      throw DbException('Failed to add user', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> updateUser(
    Uuid uuid, {
    required String username,
    String? firstName,
    String? lastName,
    String? details,
    required Uuid authorUserUuid,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final old = await findByUuid(uuid);
      await (_database.update(_database.users)
            ..where((u) => u.uuid.equalsValue(uuid)))
          .write(UsersCompanion(
        username: Value(username),
        firstName: Value(firstName),
        lastName: Value(lastName),
        details: Value(details),
        updatedAt: Value(now),
        lastModifiedByUserUuid: Value(authorUserUuid),
      ));
      if (old != null) {
        await _logger().logUpdate(
          'users',
          uuid,
          oldValues: {
            'username': old.username,
            'first_name': old.firstName,
            'last_name': old.lastName,
            'details': old.details,
          },
          newValues: {
            'username': username,
            'first_name': firstName,
            'last_name': lastName,
            'details': details,
          },
        );
      }
    } catch (e, st) {
      _log.severe('Failed to update user', e, st);
      throw DbException('Failed to update user', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> softDeleteUser(Uuid uuid,
      {required Uuid authorUserUuid}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final old = await findByUuid(uuid);
    await (_database.update(_database.users)
          ..where((u) => u.uuid.equalsValue(uuid)))
        .write(UsersCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
      lastModifiedByUserUuid: Value(authorUserUuid),
    ));
    if (old != null) {
      await _logger().logDelete(
        'users',
        uuid,
        oldValues: {
          'username': old.username,
          'first_name': old.firstName,
          'last_name': old.lastName,
          'details': old.details,
        },
      );
    }
  }
}
