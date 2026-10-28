import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/network/network_kind_probe.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_files_network_gate.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';

/// "Only over Wi-Fi": files go on Wi-Fi or a cable; elsewhere the caver is
/// asked, and an answer they ask to keep becomes the setting.
void main() {
  late AppDatabase db;
  late SilexgisProfileRepository profiles;

  const base = SilexgisProfile(
    profileUuid: 'p-1',
    displayName: 'Invented club',
    baseUrl: 'https://club.example.org',
  );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    profiles = SilexgisProfileRepository(
      ConfigurationRepository(db),
      InMemoryRefreshTokenStore(),
      SilexgisLocalStateRepository(db),
    );
    await profiles.save(base);
  });
  tearDown(() => db.close());

  Future<bool> mayGo(
    SilexgisProfile profile,
    NetworkKind kind, {
    _Decider? decider,
  }) => SilexgisFilesNetworkGate(
    profile: profile,
    profiles: profiles,
    probe: _Probe(kind),
    decider: decider,
  ).mayFilesGo(files: 2, bytes: 3 * 1024 * 1024);

  test('a new profile sends files and keeps them for Wi-Fi, asking', () {
    expect(base.sendsFiles, isTrue);
    expect(base.filesOnlyOverWifi, isTrue);
    expect(base.asksBeforeMobileData, isTrue);
    // And so does one stored before these settings existed.
    final older = SilexgisProfile.fromJson(<String, Object?>{
      'profileUuid': 'p-0',
      'displayName': 'Older',
      'baseUrl': 'https://club.example.org',
    });
    expect(older.sendsFiles, isTrue);
    expect(older.filesOnlyOverWifi, isTrue);
  });

  group('the rule', () {
    test('files go on Wi-Fi and on a cable, without asking', () {
      for (final kind in <NetworkKind>[
        NetworkKind.wifi,
        NetworkKind.ethernet,
      ]) {
        expect(silexgisFilesVerdict(base, kind), SilexgisFilesVerdict.send);
      }
    });

    test('elsewhere the caver is asked — also when nothing could be told', () {
      for (final kind in <NetworkKind>[
        NetworkKind.mobile,
        NetworkKind.unknown,
        NetworkKind.none,
      ]) {
        expect(silexgisFilesVerdict(base, kind), SilexgisFilesVerdict.ask);
      }
    });

    test('or files wait, when the caver chose not to be asked', () {
      expect(
        silexgisFilesVerdict(
          base.copyWith(asksBeforeMobileData: false),
          NetworkKind.mobile,
        ),
        SilexgisFilesVerdict.wait,
      );
    });

    test('without "only over Wi-Fi", files go anywhere', () {
      expect(
        silexgisFilesVerdict(
          base.copyWith(filesOnlyOverWifi: false),
          NetworkKind.mobile,
        ),
        SilexgisFilesVerdict.send,
      );
    });
  });

  group('asking', () {
    test('on Wi-Fi nobody is asked', () async {
      final decider = _Decider(null);
      expect(await mayGo(base, NetworkKind.wifi, decider: decider), isTrue);
      expect(decider.asked, 0);
    });

    test('on mobile data the answer decides, once', () async {
      final yes = _Decider(const SilexgisMobileDataAnswer(send: true));
      expect(await mayGo(base, NetworkKind.mobile, decider: yes), isTrue);
      expect(yes.asked, 1);
      expect(yes.files, 2);
      expect(yes.bytes, 3 * 1024 * 1024);

      final no = _Decider(const SilexgisMobileDataAnswer(send: false));
      expect(await mayGo(base, NetworkKind.mobile, decider: no), isFalse);
      // Nothing was asked to be kept.
      expect(await profiles.find('p-1'), isA<SilexgisProfile>());
      expect((await profiles.find('p-1'))!.filesOnlyOverWifi, isTrue);
      expect((await profiles.find('p-1'))!.asksBeforeMobileData, isTrue);
    });

    test('"send", remembered, turns "only over Wi-Fi" off', () async {
      final decider = _Decider(
        const SilexgisMobileDataAnswer(send: true, remember: true),
      );
      expect(await mayGo(base, NetworkKind.mobile, decider: decider), isTrue);
      expect((await profiles.find('p-1'))!.filesOnlyOverWifi, isFalse);
    });

    test('"wait", remembered, stops the asking', () async {
      final decider = _Decider(
        const SilexgisMobileDataAnswer(send: false, remember: true),
      );
      expect(await mayGo(base, NetworkKind.mobile, decider: decider), isFalse);
      final kept = (await profiles.find('p-1'))!;
      expect(kept.filesOnlyOverWifi, isTrue);
      expect(kept.asksBeforeMobileData, isFalse);
    });

    test('remembering keeps the profile\'s other settings', () async {
      await profiles.save(base.copyWith(uploadsNewRoots: true));
      await mayGo(
        base,
        NetworkKind.mobile,
        decider: _Decider(
          const SilexgisMobileDataAnswer(send: true, remember: true),
        ),
      );
      expect((await profiles.find('p-1'))!.uploadsNewRoots, isTrue);
    });

    test('with nobody to ask, files wait', () async {
      expect(await mayGo(base, NetworkKind.mobile), isFalse);
      // The screen was gone by the time the question came.
      expect(
        await mayGo(base, NetworkKind.mobile, decider: _Decider(null)),
        isFalse,
      );
    });

    test('when not to be asked, nobody is', () async {
      final decider = _Decider(const SilexgisMobileDataAnswer(send: true));
      expect(
        await mayGo(
          base.copyWith(asksBeforeMobileData: false),
          NetworkKind.mobile,
          decider: decider,
        ),
        isFalse,
      );
      expect(decider.asked, 0);
    });
  });
}

class _Probe implements NetworkKindProbe {
  const _Probe(this.kind);
  final NetworkKind kind;

  @override
  Future<NetworkKind> current() async => kind;
}

class _Decider implements SilexgisMobileDataDecider {
  _Decider(this.answer);
  final SilexgisMobileDataAnswer? answer;
  int asked = 0;
  int? files;
  int? bytes;

  @override
  Future<SilexgisMobileDataAnswer?> askToSendOverMobileData({
    required int files,
    required int bytes,
  }) async {
    asked++;
    this.files = files;
    this.bytes = bytes;
    return answer;
  }
}
