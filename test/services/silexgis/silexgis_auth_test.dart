import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_registry.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_tokens.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/utils/clock.dart';

import 'scripted_client.dart';

/// The sign-in flow, and the traps `03-auth.md` names — none of which are
/// visible in the served description, because it documents the JSON surface
/// and not the OAuth endpoints.
void main() {
  const profile = 'profile-1';
  final base = Uri.parse('https://club.example.org');
  final clock = FakeClock(DateTime.utc(2026, 9, 1, 12));

  ScriptedResponse loginOk() => ScriptedResponse.json(
    path: SilexgisContract.loginPath,
    json: <String, Object?>{
      'userId': '01a04471-869b-7d2e-8ed2-b1982a7e7d35',
      'email': 'someone@example.org',
    },
    headers: <String, String>{
      'set-cookie':
          'silexgis.session=CfDJ8NvV1s5Y…; expires=Mon, 01 Sep 2026 '
          '13:00:00 GMT; path=/; httponly; samesite=lax',
    },
  );

  /// The real server carries the caller's own `state` back, so the scripted
  /// one does too unless a test deliberately breaks it.
  ScriptedResponse authorizeOk({String? state}) => ScriptedResponse(
    path: SilexgisContract.authorizePath,
    status: 302,
    headersFor: (request) => <String, String>{
      'location':
          '${SilexgisAuthService.redirectUri}?code=THE-CODE'
          '&state=${state ?? request.url.queryParameters['state']}'
          '&iss=http%3A%2F%2Flocalhost%2F',
    },
  );

  ScriptedResponse tokenOk({
    String access = 'access-1',
    String? refresh = 'refresh-1',
    String scope = 'openid profile email roles offline_access',
    int expiresIn = 900,
  }) => ScriptedResponse.json(
    path: SilexgisContract.tokenPath,
    json: <String, Object?>{
      'access_token': access,
      'token_type': 'Bearer',
      'expires_in': expiresIn,
      'scope': scope,
      'id_token': 'id-1',
      'refresh_token': ?refresh,
    },
  );

  SilexgisAuthService build(
    http.Client client, {
    SilexgisRefreshTokenStore? store,
  }) => SilexgisAuthService(
    baseUri: base,
    profileUuid: profile,
    store: store ?? InMemoryRefreshTokenStore(),
    client: client,
    clock: clock,
    refreshRetryPause: Duration.zero,
  );

  ScriptedClient signInScript({
    ScriptedResponse? login,
    ScriptedResponse? token,
  }) => ScriptedClient(<ScriptedResponse>[
    login ?? loginOk(),
    authorizeOk(),
    token ?? tokenOk(),
  ]);

  test(
    'signs in and stores the refresh token before anything uses it',
    () async {
      final store = InMemoryRefreshTokenStore();
      final client = signInScript();
      final tokens = await build(
        client,
        store: store,
      ).signIn(email: 'someone@example.org', password: 'secret');

      expect(tokens.accessToken, 'access-1');
      expect(tokens.hasOfflineAccess, isTrue);
      expect(await store.read(profile), 'refresh-1');
      expect(tokens.expiresAt, clock.now().add(const Duration(seconds: 900)));
    },
  );

  test('asks for offline_access, without which there is no refresh token', () {
    // The exchange without it succeeds, returns an access token, and looks
    // entirely healthy — it simply has no refresh_token field, and a client
    // that never asked would send the caver back to a password prompt every
    // fifteen minutes.
    expect(SilexgisContract.scopes, contains('offline_access'));
  });

  test('notices when the server granted less than was asked for', () async {
    final client = signInScript(
      token: tokenOk(refresh: null, scope: 'openid profile email roles'),
    );
    final tokens = await build(
      client,
    ).signIn(email: 'a@b.c', password: 'secret');

    // The scope in the answer is the server's statement of what was actually
    // granted. Comparing it to what was asked for is how a client notices this
    // rather than debugging it.
    expect(tokens.hasOfflineAccess, isFalse);
    expect(tokens.grantedScopes, isNot(contains('offline_access')));
  });

  test(
    'drives the redirect by hand and reads the code from the header',
    () async {
      final client = signInScript();
      await build(client).signIn(email: 'a@b.c', password: 'secret');

      final authorize = client.sent.firstWhere(
        (r) => r.url.path == SilexgisContract.authorizePath,
      );
      expect(authorize.headers['Cookie'], startsWith('silexgis.session='));
      // Only the cookie, not its attributes: `expires=Mon, 01 Sep …` carries a
      // comma of its own, which is why the header is split on the cookie name.
      expect(authorize.headers['Cookie'], isNot(contains(';')));
      expect(authorize.url.queryParameters['code_challenge_method'], 'S256');
      expect(authorize.url.queryParameters['client_id'], 'silexgis-speleoloc');
    },
  );

  test('the token endpoint is form-encoded, not JSON', () async {
    // Every other route on this server takes JSON. This one refuses it
    // outright, and answers error/error_description rather than a problem
    // document.
    final client = signInScript();
    await build(client).signIn(email: 'a@b.c', password: 'secret');

    final exchange = client.sent.firstWhere(
      (r) => r.url.path == SilexgisContract.tokenPath,
    );
    expect(
      exchange.headers['Content-Type'],
      'application/x-www-form-urlencoded',
    );
    expect(exchange.formBody['grant_type'], 'authorization_code');
    expect(exchange.formBody['code'], 'THE-CODE');
    expect(exchange.formBody.containsKey('client_secret'), isFalse);
    // Byte-identical to the one sent at the authorization request, port
    // included.
    final authorize = client.sent.firstWhere(
      (r) => r.url.path == SilexgisContract.authorizePath,
    );
    expect(
      exchange.formBody['redirect_uri'],
      authorize.url.queryParameters['redirect_uri'],
    );
  });

  test(
    'proves the code with the verifier the challenge was made from',
    () async {
      final client = signInScript();
      await build(client).signIn(email: 'a@b.c', password: 'secret');

      final challenge = client.sent
          .firstWhere((r) => r.url.path == SilexgisContract.authorizePath)
          .url
          .queryParameters['code_challenge'];
      final verifier = client.sent
          .firstWhere((r) => r.url.path == SilexgisContract.tokenPath)
          .formBody['code_verifier'];
      expect(verifier, hasLength(greaterThanOrEqualTo(43)));
      // The pair actually corresponds. A challenge derived from some other
      // verifier passes the authorization request and is refused at exchange,
      // which is a failure a test that only checked presence would miss.
      expect(_s256(verifier!), challenge);
    },
  );

  group('two-factor', () {
    ScriptedResponse mfaRequired() => ScriptedResponse(
      path: SilexgisContract.loginPath,
      status: 401,
      body:
          '{"title":"Unauthorized","status":401,'
          '"detail":"A two-factor code is required.",'
          '"methods":["authenticator","email"],'
          '"preferredMethod":"authenticator","recoveryAccepted":true,'
          '"code":"auth.mfa_required"}',
      headers: const <String, String>{
        'content-type': 'application/problem+json',
        'set-cookie': 'Identity.TwoFactorUserId=CfDJ8Nv…; path=/; httponly',
      },
    );

    test('carries the methods, the preferred one, and the cookie', () async {
      final client = ScriptedClient(<ScriptedResponse>[mfaRequired()]);
      await expectLater(
        build(client).signIn(email: 'a@b.c', password: 'secret'),
        throwsA(
          isA<TwoFactorRequiredException>()
              .having((e) => e.isTwoFactorRequired, 'isTwoFactorRequired', true)
              .having((e) => e.challenge.methods, 'methods', <String>[
                'authenticator',
                'email',
              ])
              .having(
                (e) => e.challenge.preferredMethod,
                'preferredMethod',
                'authenticator',
              )
              .having(
                (e) => e.challenge.cookie,
                'cookie',
                'Identity.TwoFactorUserId=CfDJ8Nv…',
              ),
        ),
      );
    });

    test('always offers the recovery path', () async {
      // recoveryAccepted is always true, and a client that offers only the
      // listed methods can strand somebody: every method can be taken away by
      // a person other than the one signing in.
      final client = ScriptedClient(<ScriptedResponse>[mfaRequired()]);
      try {
        await build(client).signIn(email: 'a@b.c', password: 'secret');
        fail('expected a two-factor challenge');
      } on TwoFactorRequiredException catch (e) {
        expect(e.challenge.recoveryAccepted, isTrue);
        expect(
          TwoFactorChallenge.asRecoveryCode('AB12-CD34'),
          'recovery:AB12-CD34',
        );
      }
    });

    test(
      'a sent code is asked for with the half-finished cookie and no account',
      () async {
        final client = ScriptedClient(<ScriptedResponse>[
          ScriptedResponse.json(
            path: SilexgisContract.twoFactorSendPath,
            json: <String, Object?>{
              'method': 'email',
              'destination': 's•••@example.org',
              'expiresMinutes': 10,
            },
          ),
        ]);
        await build(client).sendTwoFactorCode(
          const TwoFactorChallenge(
            methods: <String>['email'],
            preferredMethod: 'email',
            recoveryAccepted: true,
            cookie: 'Identity.TwoFactorUserId=abc',
          ),
          'email',
        );

        final sent = client.sent.single;
        expect(sent.headers['Cookie'], 'Identity.TwoFactorUserId=abc');
        // Naming an account here would let the call be used to discover
        // addresses, or to send mail to somebody else's.
        expect(sent.jsonBody, <String, Object?>{'method': 'email'});
      },
    );

    test(
      'retrying the login with the code completes the ordinary flow',
      () async {
        final client = signInScript();
        await build(client).signIn(
          email: 'a@b.c',
          password: 'secret',
          twoFactorCode: '136778',
          twoFactorCookie: 'Identity.TwoFactorUserId=abc',
        );
        final login = client.sent.first;
        expect(login.jsonBody['twoFactorCode'], '136778');
        expect(login.headers['Cookie'], 'Identity.TwoFactorUserId=abc');
      },
    );
  });

  group('refreshing', () {
    test('stores the new pair, because the old one is spent', () async {
      final store = InMemoryRefreshTokenStore();
      await store.write(profile, 'refresh-1');
      final client = ScriptedClient(<ScriptedResponse>[
        tokenOk(access: 'access-2', refresh: 'refresh-2'),
      ]);
      final auth = build(client, store: store);

      expect(await auth.restore(), isTrue);
      expect(await store.read(profile), 'refresh-2');
      expect(await auth.accessToken(), 'access-2');
      expect(client.sent.single.formBody['grant_type'], 'refresh_token');
      expect(client.sent.single.formBody['refresh_token'], 'refresh-1');
    });

    test('presents the token once however many callers ask at once', () async {
      // Presenting a redeemed refresh token outside the retry window is read
      // as evidence that a copy is loose and revokes the whole chain — the
      // successor this client is holding included.
      final store = InMemoryRefreshTokenStore();
      await store.write(profile, 'refresh-1');
      final client = ScriptedClient(<ScriptedResponse>[
        tokenOk(access: 'access-2', refresh: 'refresh-2'),
      ]);
      final auth = build(client, store: store);

      final answers = await Future.wait(<Future<bool>>[
        auth.refresh(),
        auth.refresh(),
        auth.refresh(),
      ]);
      expect(answers, everyElement(isTrue));
      expect(client.sent, hasLength(1));
    });

    test(
      'an invalid_grant means ask for a password, and drops the token',
      () async {
        final store = InMemoryRefreshTokenStore();
        await store.write(profile, 'refresh-1');
        final client = ScriptedClient(<ScriptedResponse>[
          ScriptedResponse.json(
            path: SilexgisContract.tokenPath,
            status: 400,
            json: <String, Object?>{
              'error': 'invalid_grant',
              'error_description':
                  'The specified refresh token is no longer valid.',
            },
          ),
        ]);
        final auth = build(client, store: store);

        expect(await auth.restore(), isFalse);
        // Spent, expired, replayed — or the account's password was changed,
        // which revokes every token that account holds on every device.
        expect(await store.read(profile), isNull);
        expect(auth.isSignedIn, isFalse);
      },
    );

    ScriptedResponse locked() => ScriptedResponse.json(
      path: SilexgisContract.tokenPath,
      status: 400,
      json: <String, Object?>{
        'error': 'invalid_grant',
        'error_description': 'The account is locked.',
      },
    );

    test('a locked account keeps its tokens and says to try later', () async {
      final store = InMemoryRefreshTokenStore();
      await store.write(profile, 'refresh-1');
      final client = ScriptedClient(<ScriptedResponse>[
        locked(),
        tokenOk(access: 'access-2', refresh: 'refresh-2'),
      ]);
      final auth = build(client, store: store);

      await expectLater(
        auth.restore(),
        throwsA(
          isA<SilexgisAccountLockedException>()
              .having((e) => e.code, 'code', 'invalid_grant')
              .having((e) => e.action, 'action', SilexgisAction.retry)
              .having((e) => e.message, 'message', contains('locked')),
        ),
      );
      // A lock revokes nothing, so nothing is thrown away and no password
      // is asked for.
      expect(await store.read(profile), 'refresh-1');

      // Once the lock lifts, the same token works again.
      expect(await auth.restore(), isTrue);
      expect(client.sent.last.formBody['refresh_token'], 'refresh-1');
      expect(await store.read(profile), 'refresh-2');
    });

    test(
      'a lock met mid-request is not mistaken for a lapsed session',
      () async {
        final store = InMemoryRefreshTokenStore();
        await store.write(profile, 'refresh-1');
        final client = ScriptedClient(<ScriptedResponse>[
          tokenOk(access: 'access-2', refresh: 'refresh-2'),
          ScriptedResponse.problem(
            path: SilexgisContract.capabilitiesPath,
            status: 401,
          ),
          locked(),
        ]);
        final auth = build(client, store: store);
        await auth.restore();

        await expectLater(
          SilexgisSyncApi(
            SilexgisHttp(baseUri: base, tokens: auth, client: client),
          ).capabilities(),
          throwsA(isA<SilexgisAccountLockedException>()),
        );
        expect(await store.read(profile), 'refresh-2');
      },
    );

    test('a network failure leaves the stored credential alone', () async {
      final store = InMemoryRefreshTokenStore();
      await store.write(profile, 'refresh-1');
      // Nothing scripted: the client throws, which the service reads as
      // transport rather than as a refusal.
      final auth = build(ScriptedClient(<ScriptedResponse>[]), store: store);

      await expectLater(
        auth.refresh(),
        throwsA(isA<SilexgisTransportException>()),
      );
      expect(await store.read(profile), 'refresh-1');
    });

    group('an answer that is not the server refusing the token', () {
      // A server restart ends no session, and what stands in front of the
      // server while it restarts answers in its own words. Only the token
      // endpoint's own refusal says anything about the token.
      final answers = <String, ScriptedResponse Function()>{
        'a 503 page from a proxy': () => ScriptedResponse(
          path: SilexgisContract.tokenPath,
          status: 503,
          body: '<html><body>Service Unavailable</body></html>',
          headers: const <String, String>{'content-type': 'text/html'},
        ),
        'a 502 with no body': () =>
            ScriptedResponse(path: SilexgisContract.tokenPath, status: 502),
        'a 429': () =>
            ScriptedResponse(path: SilexgisContract.tokenPath, status: 429),
        'a redirect': () => ScriptedResponse(
          path: SilexgisContract.tokenPath,
          status: 301,
          headers: const <String, String>{
            'location': 'https://elsewhere.example.test/connect/token',
          },
        ),
        'a 404 page that is not the token endpoint\'s': () => ScriptedResponse(
          path: SilexgisContract.tokenPath,
          status: 404,
          body: '<html>Not Found</html>',
        ),
        'a 200 that is not JSON': () => ScriptedResponse(
          path: SilexgisContract.tokenPath,
          status: 200,
          body: '<html>Sign in to the hotel Wi-Fi</html>',
        ),
        'a 200 with no access token in it': () => ScriptedResponse.json(
          path: SilexgisContract.tokenPath,
          json: <String, Object?>{'token_type': 'Bearer'},
        ),
      };

      for (final entry in answers.entries) {
        test('${entry.key} keeps the sign-in, to try again later', () async {
          final store = InMemoryRefreshTokenStore();
          await store.write(profile, 'refresh-1');
          final client = ScriptedClient(<ScriptedResponse>[entry.value()]);
          final auth = build(client, store: store);

          await expectLater(
            auth.restore(),
            throwsA(
              isA<SilexgisTransportException>().having(
                (e) => e.action,
                'action',
                SilexgisAction.retry,
              ),
            ),
          );
          expect(await store.read(profile), 'refresh-1');
          // The server answered, so this is no lost answer to repeat at once.
          expect(client.sent, hasLength(1));
        });
      }

      test('a malformed-request refusal keeps the token', () async {
        // The server read the request and found it malformed; it said
        // nothing about the token, which is still the caver's.
        final store = InMemoryRefreshTokenStore();
        await store.write(profile, 'refresh-1');
        final client = ScriptedClient(<ScriptedResponse>[
          ScriptedResponse.json(
            path: SilexgisContract.tokenPath,
            status: 400,
            json: <String, Object?>{
              'error': 'invalid_request',
              'error_description': 'The mandatory parameter is missing.',
            },
          ),
        ]);

        await expectLater(
          build(client, store: store).restore(),
          throwsA(
            isA<SilexgisAuthException>()
                .having((e) => e.code, 'code', 'invalid_request')
                .having(
                  (e) => e.message,
                  'message',
                  'The mandatory parameter is missing.',
                ),
          ),
        );
        expect(await store.read(profile), 'refresh-1');
      });
    });

    group('a refresh whose answer was lost', () {
      // The server may have redeemed the token before the answer was lost.
      // It accepts the spent token again for about thirty seconds so that a
      // client can repeat the same request; presented later, the spent token
      // revokes the whole chain.
      test('is repeated at once with the same token', () async {
        final store = InMemoryRefreshTokenStore();
        await store.write(profile, 'refresh-1');
        final client = _LosesAnswers(
          ScriptedClient(<ScriptedResponse>[
            tokenOk(access: 'access-2', refresh: 'refresh-2'),
          ]),
          lose: 1,
        );
        final auth = build(client, store: store);

        expect(await auth.restore(), isTrue);
        expect(client.presented, <String>['refresh-1', 'refresh-1']);
        expect(await store.read(profile), 'refresh-2');
        expect(await auth.accessToken(), 'access-2');
      });

      test('is cut short when it stalls, rather than waiting the window '
          'out', () async {
        final store = InMemoryRefreshTokenStore();
        await store.write(profile, 'refresh-1');
        final client = _LosesAnswers(
          ScriptedClient(<ScriptedResponse>[
            tokenOk(access: 'access-2', refresh: 'refresh-2'),
          ]),
          lose: 1,
          stall: true,
        );
        final auth = SilexgisAuthService(
          baseUri: base,
          profileUuid: profile,
          store: store,
          client: client,
          clock: clock,
          // The ordinary timeout would let a stalled refresh use up the
          // server's whole window before the repeat is sent.
          timeout: const Duration(hours: 1),
          refreshTimeout: const Duration(milliseconds: 50),
          refreshRetryPause: Duration.zero,
        );

        expect(await auth.restore(), isTrue);
        expect(client.presented, <String>['refresh-1', 'refresh-1']);
        expect(await store.read(profile), 'refresh-2');
      });

      test(
        'is given up on after a few prompt tries, keeping the token',
        () async {
          final store = InMemoryRefreshTokenStore();
          await store.write(profile, 'refresh-1');
          final client = _LosesAnswers(
            ScriptedClient(<ScriptedResponse>[]),
            lose: 10,
          );

          await expectLater(
            build(client, store: store).restore(),
            throwsA(isA<SilexgisTransportException>()),
          );
          expect(client.presented, hasLength(3));
          expect(client.presented.toSet(), <String>{'refresh-1'});
          expect(await store.read(profile), 'refresh-1');
        },
      );
    });

    test('presents the stored successor when another client of this profile '
        'already redeemed the token it holds', () async {
      addTearDown(() => clock.set(DateTime.utc(2026, 9, 1, 12)));
      final store = InMemoryRefreshTokenStore();
      await store.write(profile, 'refresh-1');
      final runClient = ScriptedClient(<ScriptedResponse>[
        tokenOk(access: 'access-2', refresh: 'refresh-2'),
        tokenOk(access: 'access-4', refresh: 'refresh-4'),
      ]);
      final fetchClient = ScriptedClient(<ScriptedResponse>[
        tokenOk(access: 'access-3', refresh: 'refresh-3'),
      ]);
      final run = build(runClient, store: store);
      final fetch = build(fetchClient, store: store);

      expect(await run.restore(), isTrue);
      // A model fetch while the run goes on redeems refresh-2.
      expect(await fetch.restore(), isTrue);
      expect(fetchClient.sent.single.formBody['refresh_token'], 'refresh-2');

      clock.advance(const Duration(minutes: 15));
      expect(await run.accessToken(), 'access-4');
      // refresh-2 is spent; presenting it again would revoke the chain.
      expect(runClient.sent.last.formBody['refresh_token'], 'refresh-3');
      expect(await store.read(profile), 'refresh-4');
    });

    test('renews an access token before it lapses mid-request', () async {
      final store = InMemoryRefreshTokenStore();
      await store.write(profile, 'refresh-1');
      final client = ScriptedClient(<ScriptedResponse>[
        tokenOk(access: 'access-2', refresh: 'refresh-2', expiresIn: 900),
        tokenOk(access: 'access-3', refresh: 'refresh-3', expiresIn: 900),
      ]);
      final auth = build(client, store: store);
      await auth.restore();

      expect(await auth.accessToken(), 'access-2');
      clock.advance(const Duration(minutes: 14, seconds: 30));
      expect(await auth.accessToken(), 'access-3');
      clock.set(DateTime.utc(2026, 9, 1, 12));
    });
  });

  test(
    'an authorization redirect back to the sign-in page is not a callback',
    () async {
      // Not an error status: a client that checks only the status code parses
      // the sign-in page's own address as a callback and finds no code in it.
      final client = ScriptedClient(<ScriptedResponse>[
        loginOk(),
        ScriptedResponse(
          path: SilexgisContract.authorizePath,
          status: 302,
          headers: const <String, String>{
            'location': 'https://club.example.org/login?returnUrl=%2Fconnect',
          },
        ),
      ]);
      await expectLater(
        build(client).signIn(email: 'a@b.c', password: 'secret'),
        throwsA(
          isA<SilexgisAuthException>().having(
            (e) => e.action,
            'action',
            SilexgisAction.reAuth,
          ),
        ),
      );
    },
  );

  test('a state that does not come back is refused', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      loginOk(),
      authorizeOk(state: 'not-the-state-that-was-sent'),
    ]);
    await expectLater(
      build(client).signIn(email: 'a@b.c', password: 'secret'),
      throwsA(isA<SilexgisAuthException>()),
    );
  });

  test('wrong credentials surface the server\'s own reason', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      ScriptedResponse.problem(
        path: SilexgisContract.loginPath,
        status: 401,
        code: SilexgisAuthCodes.invalidCredentials,
        detail: 'That email and password do not match.',
      ),
    ]);
    await expectLater(
      build(client).signIn(email: 'a@b.c', password: 'wrong'),
      throwsA(
        isA<SilexgisAuthException>()
            .having((e) => e.code, 'code', SilexgisAuthCodes.invalidCredentials)
            .having(
              (e) => e.message,
              'message',
              'That email and password do not match.',
            )
            .having((e) => e.action, 'action', SilexgisAction.surfaceToUser),
      ),
    );
  });

  test('a rate-limited sign-in backs off rather than surfacing', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      ScriptedResponse.problem(
        path: SilexgisContract.loginPath,
        status: 429,
        title: 'Too Many Requests',
      ),
    ]);
    await expectLater(
      build(client).signIn(email: 'a@b.c', password: 'secret'),
      throwsA(
        isA<SilexgisAuthException>().having(
          (e) => e.action,
          'action',
          SilexgisAction.retry,
        ),
      ),
    );
  });

  group('one sign-in per profile', () {
    const club = SilexgisProfile(
      profileUuid: profile,
      displayName: 'Invented club',
      baseUrl: 'https://club.example.org',
    );

    SilexgisAuthRegistry registryOn(
      SilexgisRefreshTokenStore store,
      http.Client client,
    ) => SilexgisAuthRegistry(
      store: store,
      newClient: () => client,
      clock: clock,
    );

    test(
      'every caller of a profile gets the same sign-in, which refreshes once',
      () async {
        final store = InMemoryRefreshTokenStore();
        await store.write(profile, 'refresh-1');
        final client = ScriptedClient(<ScriptedResponse>[
          tokenOk(access: 'access-2', refresh: 'refresh-2'),
        ]);
        final registry = registryOn(store, client);

        // A run, and a model fetch while it goes on.
        final run = registry.forProfile(club);
        final fetch = registry.forProfile(club);
        expect(identical(run, fetch), isTrue);
        final answers = await Future.wait(<Future<bool>>[
          run.restore(),
          fetch.restore(),
        ]);
        expect(answers, everyElement(isTrue));
        expect(client.sent, hasLength(1));
        expect(await store.read(profile), 'refresh-2');
      },
    );

    test('the same server written another way keeps its sign-in', () {
      final registry = registryOn(
        InMemoryRefreshTokenStore(),
        ScriptedClient(<ScriptedResponse>[]),
      );
      final first = registry.forProfile(club);
      expect(
        registry.forProfile(
          club.copyWith(baseUrl: 'https://club.example.org/'),
        ),
        same(first),
      );
      expect(
        registry.forProfile(club.copyWith(baseUrl: 'https://test.example.org')),
        isNot(same(first)),
      );
    });

    group('a refresh still on its way', () {
      late AppDatabase db;
      setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
      tearDown(() => db.close());

      test('stores nothing once the server was forgotten', () async {
        final store = InMemoryRefreshTokenStore();
        final client = _HoldsRefresh(
          ScriptedClient(<ScriptedResponse>[
            tokenOk(access: 'access-2', refresh: 'refresh-2'),
          ]),
        );
        final registry = registryOn(store, client);
        final profiles = SilexgisProfileRepository(
          ConfigurationRepository(db),
          store,
          SilexgisLocalStateRepository(db),
          signIns: registry,
        );
        await profiles.save(club);
        await store.write(profile, 'refresh-1');

        final auth = registry.forProfile(club);
        final refreshing = auth.restore();
        await client.requested;
        await profiles.delete(profile);
        client.release();

        expect(await refreshing, isFalse);
        // A live 45-day credential under a profile nothing refers to any
        // more, which nothing would ever delete.
        expect(await store.read(profile), isNull);
        expect(await auth.accessToken(), isNull);
        expect(await profiles.list(), isEmpty);
      });

      test('stores nothing once the sign-in was removed elsewhere', () async {
        // A replaced database drops the sign-in straight from the keystore.
        final store = InMemoryRefreshTokenStore();
        await store.write(profile, 'refresh-1');
        final client = _HoldsRefresh(
          ScriptedClient(<ScriptedResponse>[
            tokenOk(access: 'access-2', refresh: 'refresh-2'),
          ]),
        );
        final auth = build(client, store: store);

        final refreshing = auth.restore();
        await client.requested;
        await store.delete(profile);
        client.release();

        expect(await refreshing, isFalse);
        expect(await store.read(profile), isNull);
        expect(await auth.accessToken(), isNull);
      });

      test('does not undo a sign-in made meanwhile', () async {
        final store = InMemoryRefreshTokenStore();
        await store.write(profile, 'refresh-1');
        final client = _HoldsRefresh(
          ScriptedClient(<ScriptedResponse>[
            loginOk(),
            authorizeOk(),
            tokenOk(access: 'access-new', refresh: 'refresh-new'),
            tokenOk(access: 'access-2', refresh: 'refresh-2'),
          ]),
        );
        final auth = registryOn(store, client).forProfile(club);

        final refreshing = auth.restore();
        await client.requested;
        await auth.signIn(email: 'someone@example.org', password: 'secret');
        client.release();

        expect(await refreshing, isTrue);
        expect(await store.read(profile), 'refresh-new');
        expect(await auth.accessToken(), 'access-new');
      });
    });
  });

  group('a plain http address to another machine', () {
    SilexgisAuthService cleartext(
      ScriptedClient client,
      SilexgisRefreshTokenStore store,
    ) => SilexgisAuthService(
      baseUri: Uri.parse('http://club.example.org'),
      profileUuid: profile,
      store: store,
      client: client,
      clock: clock,
    );

    test('never carries the password', () async {
      final client = signInScript();
      await expectLater(
        cleartext(
          client,
          InMemoryRefreshTokenStore(),
        ).signIn(email: 'someone@example.org', password: 'secret'),
        throwsA(isA<SilexgisInsecureAddressException>()),
      );
      expect(client.sent, isEmpty);
    });

    test('never carries the stored refresh token, and keeps it', () async {
      final store = InMemoryRefreshTokenStore();
      await store.write(profile, 'refresh-1');
      final client = ScriptedClient(<ScriptedResponse>[tokenOk()]);
      await expectLater(
        cleartext(client, store).restore(),
        throwsA(isA<SilexgisInsecureAddressException>()),
      );
      expect(client.sent, isEmpty);
      // Not spent and not refused, so not the caver's to lose: once the
      // address is corrected it is dropped with the rest of that binding.
      expect(await store.read(profile), 'refresh-1');
    });
  });
}

/// The S256 derivation, spelled out here rather than reused from the source,
/// so the test checks the pair against the specification instead of trusting
/// the implementation to agree with itself.
String _s256(String verifier) => base64Url
    .encode(sha256.convert(ascii.encode(verifier)).bytes)
    .replaceAll('=', '');

/// Holds the first refresh back until [release], so a test can act while it
/// is on its way.
class _HoldsRefresh extends http.BaseClient {
  _HoldsRefresh(this._inner);

  final ScriptedClient _inner;
  final Completer<void> _requested = Completer<void>();
  final Completer<void> _released = Completer<void>();

  Future<void> get requested => _requested.future;
  void release() => _released.complete();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_requested.isCompleted &&
        request is http.Request &&
        request.url.path == SilexgisContract.tokenPath &&
        Uri.splitQueryString(request.body)['grant_type'] == 'refresh_token') {
      _requested.complete();
      await _released.future;
    }
    return _inner.send(request);
  }
}

/// Loses the answer to the first [lose] refreshes, as a dropped connection
/// does after the server already acted on the request, and records each
/// refresh token presented.
class _LosesAnswers extends http.BaseClient {
  _LosesAnswers(this._inner, {required int lose, this.stall = false})
    : _toLose = lose;

  final ScriptedClient _inner;
  int _toLose;

  /// Never answers a lost request, rather than failing it at once.
  final bool stall;
  final List<String> presented = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.Request &&
        request.url.path == SilexgisContract.tokenPath) {
      final form = Uri.splitQueryString(request.body);
      if (form['grant_type'] == 'refresh_token') {
        presented.add(form['refresh_token'] ?? '');
        if (_toLose > 0) {
          _toLose--;
          if (stall) return Completer<http.StreamedResponse>().future;
          throw const SocketException('Connection reset by peer');
        }
      }
    }
    return _inner.send(request);
  }
}
