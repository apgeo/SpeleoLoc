import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';

import 'scripted_client.dart';

/// A token source that counts refreshes, so the tests can assert that the
/// transport asks for one exactly once and never loops.
class _FakeTokens implements SilexgisTokenSource {
  _FakeTokens({this.refreshSucceeds = true});

  String? token = 'first-token';

  bool refreshSucceeds;
  int refreshes = 0;

  @override
  Future<String?> accessToken() async => token;

  @override
  Future<bool> refresh() async {
    refreshes++;
    if (!refreshSucceeds) return false;
    token = 'second-token';
    return true;
  }
}

void main() {
  final base = Uri.parse('https://club.example.org');

  SilexgisHttp build(ScriptedClient client, SilexgisTokenSource tokens) =>
      SilexgisHttp(baseUri: base, tokens: tokens, client: client);

  test('carries the bearer token and asks for JSON', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      ScriptedResponse.json(
        path: SilexgisContract.capabilitiesPath,
        json: <String, Object?>{'contractVersion': 1},
      ),
    ]);
    await build(
      client,
      _FakeTokens(),
    ).getJson(SilexgisContract.capabilitiesPath);

    expect(client.sent.single.headers['Authorization'], 'Bearer first-token');
    expect(client.sent.single.headers['Accept'], 'application/json');
  });

  test('joins a base address that carries a path prefix of its own', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      ScriptedResponse.json(
        path: '/silexgis${SilexgisContract.capabilitiesPath}',
        json: const <String, Object?>{},
      ),
    ]);
    final http = SilexgisHttp(
      baseUri: Uri.parse('https://club.example.org/silexgis/'),
      tokens: _FakeTokens(),
      client: client,
    );
    await http.getJson(SilexgisContract.capabilitiesPath);
    expect(
      client.sent.single.url.path,
      '/silexgis${SilexgisContract.capabilitiesPath}',
    );
  });

  group('a 401', () {
    test('refreshes the credential and sends the request once more', () async {
      final tokens = _FakeTokens();
      final client = ScriptedClient(<ScriptedResponse>[
        ScriptedResponse.problem(
          path: SilexgisContract.capabilitiesPath,
          status: 401,
          title: 'Unauthorized',
        ),
        ScriptedResponse.json(
          path: SilexgisContract.capabilitiesPath,
          json: <String, Object?>{'contractVersion': 1},
        ),
      ]);

      final body = await build(
        client,
        tokens,
      ).getJson(SilexgisContract.capabilitiesPath);

      expect(body['contractVersion'], 1);
      expect(tokens.refreshes, 1);
      expect(client.sent, hasLength(2));
      expect(client.sent.last.headers['Authorization'], 'Bearer second-token');
    });

    test('gives up rather than looping when the refresh fails too', () async {
      final tokens = _FakeTokens(refreshSucceeds: false);
      final client = ScriptedClient(<ScriptedResponse>[
        ScriptedResponse.problem(
          path: SilexgisContract.capabilitiesPath,
          status: 401,
          title: 'Unauthorized',
        ),
      ]);

      await expectLater(
        build(client, tokens).getJson(SilexgisContract.capabilitiesPath),
        throwsA(
          isA<SilexgisProblemException>()
              .having((e) => e.status, 'status', 401)
              .having((e) => e.action, 'action', SilexgisAction.reAuth),
        ),
      );
      expect(tokens.refreshes, 1);
      expect(client.sent, hasLength(1));
    });

    test('is never mistaken for a transport failure', () async {
      // A captive portal answering HTML on the way to the API. The rule that
      // treats an unparseable 4xx as transport must not reach a 401, or an
      // expired token is retried for ever instead of refreshed.
      final tokens = _FakeTokens(refreshSucceeds: false);
      final client = ScriptedClient(<ScriptedResponse>[
        ScriptedResponse(
          path: SilexgisContract.capabilitiesPath,
          status: 401,
          body: '<html>Please sign in to the wifi</html>',
        ),
      ]);

      await expectLater(
        build(client, tokens).getJson(SilexgisContract.capabilitiesPath),
        throwsA(isA<SilexgisProblemException>()),
      );
      expect(tokens.refreshes, 1);
    });
  });

  test('a problem document becomes a typed refusal', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      ScriptedResponse.problem(
        path: SilexgisContract.downloadPath('s'),
        status: 409,
        code: SilexgisCodes.cursorStale,
        detail: 'The selection changed after that resume position was issued.',
      ),
    ]);

    await expectLater(
      build(client, _FakeTokens()).getJson(SilexgisContract.downloadPath('s')),
      throwsA(
        isA<SilexgisProblemException>()
            .having((e) => e.code, 'code', SilexgisCodes.cursorStale)
            .having((e) => e.action, 'action', SilexgisAction.applyAndResubmit),
      ),
    );
  });

  test(
    'an HTML 502 from something in front of the server is transport',
    () async {
      final client = ScriptedClient(<ScriptedResponse>[
        ScriptedResponse(
          path: SilexgisContract.capabilitiesPath,
          status: 502,
          body: '<html><h1>502 Bad Gateway</h1></html>',
        ),
      ]);

      await expectLater(
        build(client, _FakeTokens()).getJson(SilexgisContract.capabilitiesPath),
        throwsA(
          isA<SilexgisTransportException>()
              .having((e) => e.status, 'status', 502)
              .having((e) => e.action, 'action', SilexgisAction.retry),
        ),
      );
    },
  );

  test('a redirect is never followed on a sync route', () async {
    // The API does not redirect. Following one would hand the bearer token to
    // whatever answered instead.
    final client = ScriptedClient(<ScriptedResponse>[
      ScriptedResponse(
        path: SilexgisContract.capabilitiesPath,
        status: 302,
        headers: const <String, String>{'location': 'https://elsewhere/'},
      ),
    ]);

    await expectLater(
      build(client, _FakeTokens()).getJson(SilexgisContract.capabilitiesPath),
      throwsA(isA<SilexgisTransportException>()),
    );
    expect(client.sent, hasLength(1));
  });

  test('a download names its cursor and page size in the query', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      ScriptedResponse.json(
        path: SilexgisContract.downloadPath('set-1'),
        json: const <String, Object?>{'features': <Object?>[]},
      ),
    ]);
    await build(client, _FakeTokens()).getJson(
      SilexgisContract.downloadPath('set-1'),
      query: <String, String>{'cursor': 'MXwxNjM4', 'pageSize': '100'},
    );
    expect(client.sent.single.url.queryParameters, <String, String>{
      'cursor': 'MXwxNjM4',
      'pageSize': '100',
    });
  });
}
