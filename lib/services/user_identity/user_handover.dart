import 'dart:convert';

import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';

/// The user who was selected before the whole database was replaced.
///
/// Carries the full details, not just the UUID, so the user can be
/// re-created in a dataset that does not contain them.
class UserHandover {
  const UserHandover({
    required this.uuid,
    required this.username,
    this.firstName,
    this.lastName,
    this.details,
  });

  factory UserHandover.fromUser(User user) => UserHandover(
    uuid: user.uuid,
    username: user.username,
    firstName: user.firstName,
    lastName: user.lastName,
    details: user.details,
  );

  /// A malformed value reads as no handover at all: the user is then simply
  /// asked who they are.
  static UserHandover? tryParse(String? text) {
    if (text == null || text.isEmpty) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final map = decoded;
    String? field(String key) {
      final value = map[key];
      return value is String ? value : null;
    }

    final uuid = Uuid.tryParse(field('uuid'));
    final username = field('username');
    if (uuid == null || username == null || username.isEmpty) return null;
    return UserHandover(
      uuid: uuid,
      username: username,
      firstName: field('first_name'),
      lastName: field('last_name'),
      details: field('details'),
    );
  }

  final Uuid uuid;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? details;

  String toJsonString() => jsonEncode({
    'uuid': uuid.toString(),
    'username': username,
    'first_name': firstName,
    'last_name': lastName,
    'details': details,
  });
}

/// Moves the current user across a replace of the whole database file.
///
/// A replaced database brings the `current_user_uuid` of whoever exported
/// it, which says nothing about who holds this device. So every replace path
/// [capture]s the user from the old database before closing it and
/// [handOver]s it to the new one after reopening; the choice of user is then
/// settled on the next start.
class UserHandoverStore {
  UserHandoverStore(AppDatabase db)
    : _db = db,
      _configs = ConfigurationRepository(db);

  final AppDatabase _db;
  final IConfigurationRepository _configs;

  /// The selected user, or the one still waiting from an earlier replace
  /// that was never settled. Null when nobody real was selected.
  Future<UserHandover?> capture() async {
    final id = Uuid.tryParse(
      await _configs.readString(ConfigKey.currentUserUuid),
    );
    if (id != null) {
      final user = await (_db.select(
        _db.users,
      )..where((u) => u.uuid.equalsValue(id))).getSingleOrNull();
      if (user != null &&
          user.deletedAt == null &&
          user.username != CurrentUserService.systemUsername) {
        return UserHandover.fromUser(user);
      }
    }
    return read();
  }

  /// Drops the selection the new database arrived with and records
  /// [handover] in its place.
  Future<void> handOver(UserHandover? handover) async {
    await _configs.delete(ConfigKey.currentUserUuid);
    if (handover == null) {
      await clear();
    } else {
      await _configs.writeString(
        ConfigKey.pendingUserHandover,
        handover.toJsonString(),
      );
    }
  }

  Future<UserHandover?> read() async => UserHandover.tryParse(
    await _configs.readString(ConfigKey.pendingUserHandover),
  );

  Future<void> clear() => _configs.delete(ConfigKey.pendingUserHandover);
}
