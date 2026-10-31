import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/user_identity/current_user_resolver.dart';
import 'package:speleoloc/services/user_identity/user_handover.dart';
import 'package:speleoloc/services/user_repository.dart';

/// One device's view of a database: what the providers build in the app.
class _Device {
  _Device(this.db) {
    late ChangeLogger logger;
    users = UserRepository(db, () => logger);
    current = CurrentUserService(db, users, ConfigurationRepository(db));
    logger = ChangeLogger(db, current);
    handovers = UserHandoverStore(db);
    resolver = CurrentUserResolver(users, current, handovers);
  }

  final AppDatabase db;
  late final UserRepository users;
  late final CurrentUserService current;
  late final UserHandoverStore handovers;
  late final CurrentUserResolver resolver;

  Future<Uuid> addUser(String username) =>
      users.addUser(username: username, firstName: 'First $username');

  Future<void> softDelete(Uuid uuid) =>
      (db.update(db.users)..where((u) => u.uuid.equalsValue(uuid))).write(
        UsersCompanion(deletedAt: Value(DateTime.now().millisecondsSinceEpoch)),
      );
}

void main() {
  final opened = <AppDatabase>[];
  _Device device() {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    opened.add(db);
    return _Device(db);
  }

  tearDown(() async {
    for (final db in opened) {
      await db.close();
    }
    opened.clear();
  });

  /// Simulates a replace: capture on [before], hand over into [after] (whose
  /// configurations may name the archive author's user), and read [after]
  /// as a freshly started app would.
  Future<_Device> replace(_Device before, _Device after) async {
    await before.current.initialize();
    final handover = await before.handovers.capture();
    await after.handovers.handOver(handover);
    return _Device(after.db);
  }

  group('without a replace', () {
    test('a fresh install asks who is using the app', () async {
      final r = await device().resolver.resolve();
      expect(r, isA<UserChoiceNeeded>());
      expect((r as UserChoiceNeeded).reason, UserChoiceReason.firstRun);
    });

    test('the automatic system user is not an identity', () async {
      final d = device();
      await d.current.initialize();
      await d.current.currentOrSystem();
      final r = await d.resolver.resolve();
      expect((r as UserChoiceNeeded).reason, UserChoiceReason.firstRun);
    });

    test('a chosen user is kept without asking', () async {
      final d = device();
      final id = await d.addUser('alice');
      await d.current.initialize();
      await d.current.setCurrentUser(id);
      final r = await d.resolver.resolve();
      expect((r as UserResolved).user.uuid, id);
    });

    test('a deleted current user is reported by name', () async {
      final d = device();
      final id = await d.addUser('alice');
      await d.current.initialize();
      await d.current.setCurrentUser(id);
      await d.softDelete(id);
      final r = await d.resolver.resolve() as UserChoiceNeeded;
      expect(r.reason, UserChoiceReason.currentUserDeleted);
      expect(r.previousUsername, 'alice');
      expect(r.bringOver, isNull);
    });
  });

  group('after a replace', () {
    test('keeps the user found under the same uuid', () async {
      final before = device();
      final id = await before.addUser('alice');
      await before.current.initialize();
      await before.current.setCurrentUser(id);

      final after = device();
      await after.users.addUser(uuid: id, username: 'alice-renamed');
      final author = await after.addUser('archive-author');
      await ConfigurationRepository(
        after.db,
      ).writeString(ConfigKey.currentUserUuid, author.toString());

      final started = await replace(before, after);
      final r = await started.resolver.resolve() as UserResolved;
      expect(r.user.uuid, id);
      expect(await started.handovers.read(), isNull);
      expect(
        await ConfigurationRepository(
          after.db,
        ).readString(ConfigKey.currentUserUuid),
        id.toString(),
      );
    });

    test('falls back to the same username under another uuid', () async {
      final before = device();
      final id = await before.addUser('alice');
      await before.current.initialize();
      await before.current.setCurrentUser(id);

      final after = device();
      final otherId = await after.addUser('alice');

      final started = await replace(before, after);
      final r = await started.resolver.resolve() as UserResolved;
      expect(r.user.uuid, otherId);
    });

    test('never adopts the archive author as the current user', () async {
      final before = device();
      final after = device();
      final author = await after.addUser('archive-author');
      await ConfigurationRepository(
        after.db,
      ).writeString(ConfigKey.currentUserUuid, author.toString());

      final started = await replace(before, after);
      final r = await started.resolver.resolve() as UserChoiceNeeded;
      expect(r.reason, UserChoiceReason.firstRun);
    });

    test('asks, and offers to bring the user over, when missing', () async {
      final before = device();
      final id = await before.addUser('alice');
      await before.current.initialize();
      await before.current.setCurrentUser(id);

      final after = device();
      await after.addUser('bob');

      final started = await replace(before, after);
      final r = await started.resolver.resolve() as UserChoiceNeeded;
      expect(r.reason, UserChoiceReason.previousUserMissing);
      expect(r.previousUsername, 'alice');
      expect(r.bringOver?.uuid, id);

      await started.resolver.bringOver(r.bringOver!);
      final user = await started.users.findByUuid(id);
      expect(user?.username, 'alice');
      expect(user?.firstName, 'First alice');
      expect(started.current.currentUserUuid.value, id);
      expect(await started.handovers.read(), isNull);
      final again = _Device(after.db);
      expect(await again.resolver.resolve(), isA<UserResolved>());
    });

    test('a deleted match does not count, and blocks bringing over', () async {
      final before = device();
      final id = await before.addUser('alice');
      await before.current.initialize();
      await before.current.setCurrentUser(id);

      final after = device();
      final deleted = await after.users.addUser(uuid: id, username: 'alice');
      await after.softDelete(deleted);

      final started = await replace(before, after);
      final r = await started.resolver.resolve() as UserChoiceNeeded;
      expect(r.reason, UserChoiceReason.previousUserMissing);
      expect(r.bringOver, isNull);
    });

    test('an unsettled handover survives a second replace', () async {
      final first = device();
      final id = await first.addUser('alice');
      await first.current.initialize();
      await first.current.setCurrentUser(id);

      final second = await replace(first, device());
      final third = device();
      await third.users.addUser(uuid: id, username: 'alice');
      final started = await replace(second, third);
      expect(
        ((await started.resolver.resolve()) as UserResolved).user.uuid,
        id,
      );
    });
  });

  group('choosing', () {
    test('creating a user selects it and logs the insert', () async {
      final d = device();
      await d.current.initialize();
      await d.resolver.createAndChoose(username: 'carol', lastName: 'C');
      final id = d.current.currentUserUuid.value!;
      expect((await d.users.findByUuid(id))?.username, 'carol');
      final log = await d.db.select(d.db.changeLog).get();
      expect(log.single.changedByUserUuid, id);
    });

    test('a failed create leaves the previous user selected', () async {
      final d = device();
      final keep = await d.addUser('dave');
      await d.current.initialize();
      await d.current.setCurrentUser(keep);
      await expectLater(
        d.resolver.createAndChoose(username: 'dave'),
        throwsA(anything),
      );
      expect(d.current.currentUserUuid.value, keep);
    });

    test('the system user and deleted users are not offered', () async {
      final d = device();
      await d.current.initialize();
      await d.current.currentOrSystem();
      await d.addUser('erin');
      await d.softDelete(await d.addUser('gone'));
      final users = await d.resolver.watchChoosableUsers().first;
      expect(users.map((u) => u.username), ['erin']);
    });
  });

  group('UserHandover.tryParse', () {
    test('rejects malformed values', () {
      expect(UserHandover.tryParse(null), isNull);
      expect(UserHandover.tryParse('not json'), isNull);
      expect(UserHandover.tryParse('[1]'), isNull);
      expect(UserHandover.tryParse('{"uuid": 3, "username": "x"}'), isNull);
    });

    test('round-trips', () {
      final h = UserHandover(uuid: Uuid.v7(), username: 'alice', lastName: 'A');
      final back = UserHandover.tryParse(h.toJsonString())!;
      expect(back.uuid, h.uuid);
      expect(back.username, 'alice');
      expect(back.lastName, 'A');
      expect(back.firstName, isNull);
    });
  });
}
