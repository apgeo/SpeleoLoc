import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/utils/clock.dart';

import '../../support/fake_silexgis_server.dart';
import '../../support/silexgis_test_device.dart';

/// Two phones and one installation: what one phone writes reaches the other
/// through the server, and only what the server's rules let through.
void main() {
  final clock = FakeClock(DateTime.utc(2026, 11, 1, 9));
  final uploadPath = SilexgisContract.uploadPath('set-1');

  late FakeSilexgisServer server;
  late SilexgisTestDevice a;
  late SilexgisTestDevice b;

  // Two phones are two databases in one process, which is the point here.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    clock.set(DateTime.utc(2026, 11, 1, 9));
    server = FakeSilexgisServer(clock: clock);
    a = await SilexgisTestDevice.create(server, clock: clock);
    b = await SilexgisTestDevice.create(server, clock: clock);
  });
  tearDown(() async {
    await a.dispose();
    await b.dispose();
  });

  /// Lets a later edit carry a later stamp.
  void later() => clock.advance(const Duration(minutes: 1));

  Future<void> syncOk(SilexgisTestDevice device) async {
    await device.sync();
    expect(
      device.controller.progress.phase,
      SilexgisSyncPhase.completed,
      reason: device.controller.progress.message,
    );
  }

  Future<CavePlace?> placeOn(SilexgisTestDevice device, Uuid id) =>
      (device.db.select(
        device.db.cavePlaces,
      )..where((t) => t.uuid.equalsValue(id))).getSingleOrNull();

  Future<Uuid> placeIn(SilexgisTestDevice device, Uuid cave) async {
    await device.places.addCavePlace(cave, 'Invented sump');
    return (await device.db.select(device.db.cavePlaces).get()).single.uuid;
  }

  int uploads() => server.requests.where((r) => r.path == uploadPath).length;

  group('rows', () {
    test('a cave and a place made on one phone reach the other', () async {
      final cave = await a.caves.addCave('Invented cave');
      final place = await placeIn(a, cave);

      await syncOk(a);
      expect(server.liveFeatures, hasLength(2));
      await syncOk(b);

      final caves = await b.db.select(b.db.caves).get();
      expect(caves.single.uuid, cave);
      expect(caves.single.title, 'Invented cave');
      expect((await placeOn(b, place))?.title, 'Invented sump');
      // Applying the server's rows is not an edit here, so nothing goes back.
      final before = uploads();
      await syncOk(b);
      expect(uploads(), before);
    });

    test('an edit on the second phone comes back to the first', () async {
      final cave = await a.caves.addCave('Invented cave');
      final place = await placeIn(a, cave);
      await syncOk(a);
      await syncOk(b);

      later();
      await b.places.updateCavePlace(
        place,
        const CavePlacesCompanion(title: Value('Invented sump, lower')),
      );
      await syncOk(b);
      await syncOk(a);

      expect((await placeOn(a, place))?.title, 'Invented sump, lower');
      expect(server.feature(place.toString())?['name'], 'Invented sump, lower');
    });

    test('a cave inside a new surface area arrives inside it', () async {
      // Each row names its parent, and the server applies them in order: the
      // area has to go before the cave that names it.
      final area = await a.caves.addSurfaceArea(
        title: 'Invented massif',
        generalAreaIdentifier: 'IM',
      );
      final cave = await a.caves.addCave(
        'Invented cave',
        surfaceAreaUuid: area,
      );

      await syncOk(a);
      expect(server.feature(cave.toString()), isNotNull);
      await syncOk(b);

      final onB = await b.db.select(b.db.caves).getSingle();
      expect(onB.surfaceAreaUuid, area);
    });

    test('two phones editing one place: the later one is told, and keeps '
        'its own version', () async {
      final cave = await a.caves.addCave('Invented cave');
      final place = await placeIn(a, cave);
      await syncOk(a);
      await syncOk(b);

      later();
      await a.places.updateCavePlace(
        place,
        const CavePlacesCompanion(title: Value('Named on A')),
      );
      await b.places.updateCavePlace(
        place,
        const CavePlacesCompanion(title: Value('Named on B')),
      );
      await syncOk(a);
      await syncOk(b);

      expect(server.feature(place.toString())?['name'], 'Named on A');
      expect((await placeOn(b, place))?.title, 'Named on B');
      final held = await b.heldRows.readAll(b.profile.profileUuid);
      expect(held.single.entityUuid, place);
      expect(held.single.isConflict, isTrue);
    });

    test('a place removed on one phone is removed on the other', () async {
      final cave = await a.caves.addCave('Invented cave');
      final place = await placeIn(a, cave);
      await syncOk(a);
      await syncOk(b);

      await a.places.deleteCavePlace(place);
      await syncOk(a);
      expect(server.isDeleted(place.toString()), isTrue);
      await syncOk(b);

      expect(await placeOn(b, place), isNull);
      expect(await b.db.select(b.db.caves).get(), hasLength(1));
    });

    test('a cave removed on one phone takes its places on the other', () async {
      final cave = await a.caves.addCave('Invented cave');
      final place = await placeIn(a, cave);
      await syncOk(a);
      await syncOk(b);

      await a.caves.deleteCave(cave);
      await syncOk(a);
      await syncOk(b);

      expect(await b.db.select(b.db.caves).get(), isEmpty);
      expect(await placeOn(b, place), isNull);
    });
  });

  group('a lost answer', () {
    test('to an upload is answered from the first attempt, not applied '
        'twice', () async {
      final cave = await a.caves.addCave('Invented cave');
      server.loseNextAnswer(uploadPath);

      await a.sync();
      expect(a.controller.progress.phase, SilexgisSyncPhase.failed);
      // The server did act on it.
      expect(server.feature(cave.toString()), isNotNull);

      await syncOk(a);
      final sent = server.requests.where((r) => r.path == uploadPath).toList();
      expect(sent, hasLength(2));
      expect(sent[1].jsonBody['batchId'], sent[0].jsonBody['batchId']);
      expect(server.liveFeatures, hasLength(1));
      // The revision the lost answer carried is stored all the same, so the
      // cave is not sent again.
      final revisions = await a.localState.readRevisions(a.profile.profileUuid);
      expect(revisions[cave]?.revision, server.feature('$cave')?['updatedAt']);
      final before = uploads();
      await syncOk(a);
      expect(uploads(), before);
    });

    test(
      'to a refresh is repeated at once, and the sign-in lives on',
      () async {
        final signedInWith = await a.tokens.read(a.profile.profileUuid);
        server.loseNextAnswer(SilexgisContract.tokenPath);

        await syncOk(a);

        expect(server.refreshesPresented, <String?>[
          signedInWith,
          signedInWith,
        ]);
        final successor = await a.tokens.read(a.profile.profileUuid);
        expect(successor, isNot(signedInWith));
        expect(server.isRevoked(successor!), isFalse);
      },
    );
  });

  group('one sign-in, two clients of it', () {
    // A long sync and a model fetch started meanwhile each hold a client of
    // the same profile. Each rotation spends the token it presented.
    test('each presents the newest token, so the chain is never '
        'revoked', () async {
      final store = InMemoryRefreshTokenStore();
      await store.write('p-x', server.signIn());
      SilexgisAuthService client() => SilexgisAuthService(
        baseUri: Uri.parse('https://club.example.test'),
        profileUuid: 'p-x',
        store: store,
        client: server.client(),
        clock: clock,
        refreshRetryPause: Duration.zero,
      );
      final run = client();
      final fetch = client();

      expect(await run.restore(), isTrue);
      expect(await fetch.restore(), isTrue);
      clock.advance(const Duration(minutes: 15));
      expect(await run.accessToken(), isNotNull);

      final presented = server.refreshesPresented;
      expect(presented.toSet(), hasLength(presented.length));
      expect(server.isRevoked((await store.read('p-x'))!), isFalse);
    });

    test('a spent token presented after the grace window revokes the '
        'chain', () async {
      // The control for the case above: the rule it depends on is real.
      final first = server.signIn();
      final store = InMemoryRefreshTokenStore();
      await store.write('p-x', first);
      final auth = SilexgisAuthService(
        baseUri: Uri.parse('https://club.example.test'),
        profileUuid: 'p-x',
        store: store,
        client: server.client(),
        clock: clock,
        refreshRetryPause: Duration.zero,
      );
      expect(await auth.restore(), isTrue);

      clock.advance(const Duration(minutes: 1));
      final replay = InMemoryRefreshTokenStore();
      await replay.write('p-x', first);
      final stale = SilexgisAuthService(
        baseUri: Uri.parse('https://club.example.test'),
        profileUuid: 'p-x',
        store: replay,
        client: server.client(),
        clock: clock,
        refreshRetryPause: Duration.zero,
      );
      expect(await stale.restore(), isFalse);
      expect(server.isRevoked((await store.read('p-x'))!), isTrue);
    });
  });
}
