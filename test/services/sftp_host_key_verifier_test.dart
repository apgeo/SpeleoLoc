import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/sync/ftp/ftp_host_key_store.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport.dart';
import 'package:speleoloc/services/sync/ftp/sftp_host_key.dart';
import 'package:speleoloc/services/sync/ftp/sftp_host_key_verifier.dart';

class _MemoryHostKeyStore implements FtpHostKeyStore {
  final Map<String, SftpHostKey> keys = {};
  Object? readError;

  @override
  Future<SftpHostKey?> read(String profileUuid) async {
    final error = readError;
    if (error != null) throw error;
    return keys[profileUuid];
  }

  @override
  Future<void> write(String profileUuid, SftpHostKey hostKey) async {
    keys[profileUuid] = hostKey;
  }

  @override
  Future<void> forget(String profileUuid) async {
    keys.remove(profileUuid);
  }
}

const _profile = FtpProfile(
  profileUuid: 'profile-1',
  displayName: 'Test Server',
  protocol: FtpProtocol.sftp,
  host: 'sftp.example.test',
  port: null,
  username: 'caver',
  remoteFolder: '/sync/',
);

const _keyA = 'SHA256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _keyB = 'SHA256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

/// dartssh2 hands the fingerprint over as UTF-8 bytes of `SHA256:<base64>`.
Uint8List _fp(String text) => Uint8List.fromList(utf8.encode(text));

final _t0 = DateTime.utc(2026, 1, 2, 3, 4, 5);

SftpHostKeyVerifier _verifier(
  _MemoryHostKeyStore store, {
  FtpProfile profile = _profile,
  SftpHostKeyFirstUseConfirm? confirm,
}) => SftpHostKeyVerifier(
  profile: profile,
  store: store,
  confirmFirstUse: confirm,
  now: () => _t0,
);

void main() {
  test('first connection records the presented key and connects', () async {
    final store = _MemoryHostKeyStore();
    final verifier = _verifier(store);

    expect(await verifier.verify('ssh-ed25519', _fp(_keyA)), isTrue);

    final recorded = store.keys['profile-1']!;
    expect(recorded.fingerprint, _keyA);
    expect(recorded.keyType, 'ssh-ed25519');
    expect(recorded.endpoint, 'sftp.example.test:22');
    expect(recorded.recordedAt, _t0);
    expect(verifier.rejection, isNull);
  });

  test('the recorded key presented again connects', () async {
    final store = _MemoryHostKeyStore();
    await _verifier(store).verify('ssh-ed25519', _fp(_keyA));

    final verifier = _verifier(store);
    expect(await verifier.verify('ssh-ed25519', _fp(_keyA)), isTrue);
    expect(verifier.rejection, isNull);
  });

  test('a changed key is refused, naming the expected and received '
      'fingerprints and how to reset', () async {
    final store = _MemoryHostKeyStore();
    await _verifier(store).verify('ssh-ed25519', _fp(_keyA));

    final verifier = _verifier(store);
    expect(await verifier.verify('ssh-ed25519', _fp(_keyB)), isFalse);

    final rejection = verifier.rejection;
    expect(rejection, isA<FtpHostKeyMismatchException>());
    final mismatch = rejection! as FtpHostKeyMismatchException;
    expect(mismatch.expected.fingerprint, _keyA);
    expect(mismatch.received.fingerprint, _keyB);
    expect(mismatch.message, contains(_keyA));
    expect(mismatch.message, contains(_keyB));
    expect(mismatch.message, contains('Forget host key'));
    // The trusted key is left as it was.
    expect(store.keys['profile-1']!.fingerprint, _keyA);
  });

  test('a changed key is refused even when a prompt is available', () async {
    final store = _MemoryHostKeyStore();
    await _verifier(store).verify('ssh-ed25519', _fp(_keyA));
    var asked = false;

    final verifier = _verifier(store, confirm: (_, _, _) async => asked = true);
    expect(await verifier.verify('ssh-ed25519', _fp(_keyB)), isFalse);
    expect(asked, isFalse);
    expect(verifier.rejection, isA<FtpHostKeyMismatchException>());
  });

  test(
    'forgetting the key lets the next connection record a new one',
    () async {
      final store = _MemoryHostKeyStore();
      await _verifier(store).verify('ssh-ed25519', _fp(_keyA));
      await store.forget('profile-1');

      expect(await _verifier(store).verify('ssh-ed25519', _fp(_keyB)), isTrue);
      expect(store.keys['profile-1']!.fingerprint, _keyB);
    },
  );

  test(
    'the same key under another RSA algorithm name still connects',
    () async {
      final store = _MemoryHostKeyStore();
      await _verifier(store).verify('rsa-sha2-512', _fp(_keyA));

      expect(await _verifier(store).verify('rsa-sha2-256', _fp(_keyA)), isTrue);
    },
  );

  group('with a first-use prompt', () {
    test('asks before recording, and records once trusted', () async {
      final store = _MemoryHostKeyStore();
      SftpHostKey? shown;
      SftpHostKey? previousShown;
      final verifier = _verifier(
        store,
        confirm: (_, presented, previous) async {
          shown = presented;
          previousShown = previous;
          return true;
        },
      );

      expect(await verifier.verify('ssh-ed25519', _fp(_keyA)), isTrue);
      expect(shown!.display, 'ssh-ed25519 $_keyA');
      expect(previousShown, isNull);
      expect(store.keys['profile-1']!.fingerprint, _keyA);
    });

    test('declining refuses the connection and records nothing', () async {
      final store = _MemoryHostKeyStore();
      final verifier = _verifier(store, confirm: (_, _, _) async => false);

      expect(await verifier.verify('ssh-ed25519', _fp(_keyA)), isFalse);
      expect(verifier.rejection, isA<FtpHostKeyNotTrustedException>());
      expect(store.keys, isEmpty);
    });

    test(
      'after the host was edited, asks again and replaces the record',
      () async {
        final store = _MemoryHostKeyStore();
        await _verifier(store).verify('ssh-ed25519', _fp(_keyA));
        final moved = _profile.copyWith(host: 'new.example.test');
        SftpHostKey? previousShown;

        final verifier = _verifier(
          store,
          profile: moved,
          confirm: (_, _, previous) async {
            previousShown = previous;
            return true;
          },
        );
        expect(await verifier.verify('ssh-ed25519', _fp(_keyB)), isTrue);
        expect(previousShown!.endpoint, 'sftp.example.test:22');
        expect(store.keys['profile-1']!.endpoint, 'new.example.test:22');
        expect(store.keys['profile-1']!.fingerprint, _keyB);
      },
    );
  });

  test(
    'a host changed without a prompt (e.g. by an import) is refused',
    () async {
      final store = _MemoryHostKeyStore();
      await _verifier(store).verify('ssh-ed25519', _fp(_keyA));
      final moved = _profile.copyWith(host: 'elsewhere.example.test');

      final verifier = _verifier(store, profile: moved);
      expect(await verifier.verify('ssh-ed25519', _fp(_keyB)), isFalse);
      expect(verifier.rejection, isA<FtpHostKeyMismatchException>());
      expect(store.keys['profile-1']!.fingerprint, _keyA);
    },
  );

  test('an unreadable record refuses instead of trusting anew', () async {
    final store = _MemoryHostKeyStore()
      ..readError = Exception('keystore locked');
    final verifier = _verifier(store);

    expect(await verifier.verify('ssh-ed25519', _fp(_keyA)), isFalse);
    expect(verifier.rejection, isA<FtpTransportException>());
    expect(store.keys, isEmpty);
  });
}
