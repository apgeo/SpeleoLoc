import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/user_identity/user_handover.dart';
import 'package:speleoloc/services/user_repository.dart';

/// Outcome of [CurrentUserResolver.resolve].
sealed class UserResolution {
  const UserResolution();
}

class UserResolved extends UserResolution {
  const UserResolved(this.user);
  final User user;
}

enum UserChoiceReason {
  /// Nobody real has been chosen on this device yet.
  firstRun,

  /// The dataset was replaced and the user selected before is not in it.
  previousUserMissing,

  /// The selected user was deleted, usually by a sync from another device.
  currentUserDeleted,
}

class UserChoiceNeeded extends UserResolution {
  const UserChoiceNeeded(this.reason, {this.previousUsername, this.bringOver});
  final UserChoiceReason reason;
  final String? previousUsername;

  /// The previous user, when they can be re-created in this dataset. Null
  /// when their UUID or username is already held by a deleted row.
  final UserHandover? bringOver;
}

/// Decides who is using the app, and records the choice when it has to be
/// asked.
///
/// A user carried over a dataset replace is kept when the new data holds the
/// same UUID or, failing that, the same username (the natural key sync
/// merges users on). Deleted users and the automatic `system` user never
/// count as a match.
class CurrentUserResolver {
  CurrentUserResolver(this._users, this._currentUser, this._handovers);

  final IUserRepository _users;
  final CurrentUserService _currentUser;
  final UserHandoverStore _handovers;

  Future<UserResolution> resolve() async {
    await _currentUser.initialize();
    final handover = await _handovers.read();
    if (handover != null) return _resolveHandover(handover);

    final id = _currentUser.currentUserUuid.value;
    final user = id == null ? null : await _users.findByUuid(id);
    if (user == null || _isSystem(user)) {
      return const UserChoiceNeeded(UserChoiceReason.firstRun);
    }
    if (user.deletedAt != null) {
      return UserChoiceNeeded(
        UserChoiceReason.currentUserDeleted,
        previousUsername: user.username,
      );
    }
    return UserResolved(user);
  }

  Future<UserResolution> _resolveHandover(UserHandover handover) async {
    final byUuid = await _users.findByUuid(handover.uuid);
    final byUsername = await _users.findByUsername(handover.username);
    final match = _isChoosable(byUuid)
        ? byUuid!
        : _isChoosable(byUsername)
        ? byUsername!
        : null;
    if (match != null) {
      await choose(match.uuid);
      return UserResolved(match);
    }
    return UserChoiceNeeded(
      UserChoiceReason.previousUserMissing,
      previousUsername: handover.username,
      bringOver: byUuid == null && byUsername == null ? handover : null,
    );
  }

  /// Users that can be offered as "this is me".
  Stream<List<User>> watchChoosableUsers() => _users.watchUsers().map(
    (users) => users.where(_isChoosable).toList(growable: false),
  );

  /// Whether [username] is held by any row, deleted ones included: the
  /// column is unique across both.
  Future<bool> isUsernameTaken(String username) async =>
      await _users.findByUsername(username) != null;

  Future<void> choose(Uuid uuid) async {
    await _currentUser.setCurrentUser(uuid);
    await _handovers.clear();
  }

  Future<void> createAndChoose({
    required String username,
    String? firstName,
    String? lastName,
    String? details,
  }) => _insertAndChoose(
    Uuid.v7(),
    username: username,
    firstName: firstName,
    lastName: lastName,
    details: details,
  );

  /// Re-creates the previous user under their own UUID, so rows they write
  /// here and on other devices stay attributed to one person.
  Future<void> bringOver(UserHandover handover) => _insertAndChoose(
    handover.uuid,
    username: handover.username,
    firstName: handover.firstName,
    lastName: handover.lastName,
    details: handover.details,
  );

  Future<void> _insertAndChoose(
    Uuid uuid, {
    required String username,
    String? firstName,
    String? lastName,
    String? details,
  }) async {
    // Selected before the insert so its change-log row is attributed to the
    // new user rather than to nobody.
    final previous = _currentUser.currentUserUuid.value;
    await _currentUser.setCurrentUser(uuid);
    try {
      await _users.addUser(
        uuid: uuid,
        username: username,
        firstName: firstName,
        lastName: lastName,
        details: details,
        authorUserUuid: uuid,
      );
    } catch (_) {
      if (previous == null) {
        await _currentUser.clearCurrentUser();
      } else {
        await _currentUser.setCurrentUser(previous);
      }
      rethrow;
    }
    await _handovers.clear();
  }

  static bool _isSystem(User user) =>
      user.username == CurrentUserService.systemUsername;

  static bool _isChoosable(User? user) =>
      user != null && user.deletedAt == null && !_isSystem(user);
}
