import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:speleoloc/services/silexgis/auth/pkce.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_tokens.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/clock.dart';

/// Where a refresh token is kept between runs.
///
/// One implementation puts it in the platform keystore; tests use an in-memory
/// one. The refresh token is the whole credential — 45 days of access to the
/// club's registry — so it never goes in the SQLite database, which a plaintext
/// export would carry off.
abstract class SilexgisRefreshTokenStore {
  Future<String?> read(String profileUuid);
  Future<void> write(String profileUuid, String refreshToken);
  Future<void> delete(String profileUuid);
}

/// Signs a device in to one installation and keeps its credential fresh.
///
/// The flow is the in-app one: the application collects the password itself,
/// posts it to the login endpoint for a session cookie, then drives the
/// authorization request and the token exchange. That is the right shape while
/// accounts live in SilexGIS; an installation that authenticates only against
/// an external provider needs the system browser instead, which is client-side
/// work the server is already registered for.
class SilexgisAuthService implements SilexgisTokenSource {
  SilexgisAuthService({
    required Uri baseUri,
    required String profileUuid,
    required SilexgisRefreshTokenStore store,
    http.Client? client,
    Clock clock = const SystemClock(),
    Duration timeout = const Duration(seconds: 30),
  }) : _baseUri = baseUri,
       _profileUuid = profileUuid,
       _store = store,
       _client = client ?? http.Client(),
       _clock = clock,
       _timeout = timeout;

  /// The registered loopback callback.
  ///
  /// Nothing binds this port: the in-app flow drives the `302` itself and
  /// reads the code out of the `Location` header, so no socket ever listens
  /// here. The registered redirect entry carries no port and the port is
  /// excluded from matching, but the value must still be byte-identical
  /// between the authorization request and the token exchange.
  static const String redirectUri = 'http://127.0.0.1:54321/callback';

  final Uri _baseUri;
  final String _profileUuid;
  final SilexgisRefreshTokenStore _store;
  final http.Client _client;
  final Clock _clock;
  final Duration _timeout;
  final _log = AppLogger.of('SilexgisAuthService');

  SilexgisTokens? _tokens;

  /// Refreshes are serialised against each other. Each one redeems the token
  /// presented and issues a new one; presenting a redeemed token outside the
  /// short retry window is read as evidence that a copy of it is loose and
  /// revokes the whole chain — including the successor this client is holding.
  Future<bool>? _refreshInFlight;

  bool get isSignedIn => _tokens != null;

  Uri _uri(String path) {
    final prefix = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    return _baseUri.replace(path: '$prefix$path');
  }

  // ---------------------------------------------------------------- signing in

  /// Password sign-in, end to end: cookie, authorization code, token exchange.
  ///
  /// Throws [SilexgisAuthException] with `auth.mfa_required` and a
  /// [TwoFactorChallenge] attached when the account has two-factor sign-in on;
  /// call [sendTwoFactorCode] if the method needs one sent, then call this
  /// again with [twoFactorCode].
  Future<SilexgisTokens> signIn({
    required String email,
    required String password,
    String? twoFactorCode,
    String? twoFactorCookie,
  }) async {
    final session = await _passwordLogin(
      email: email,
      password: password,
      twoFactorCode: twoFactorCode,
      twoFactorCookie: twoFactorCookie,
    );
    final pkce = PkcePair.generate();
    final state = _newState();
    final code = await _authorize(session: session, pkce: pkce, state: state);
    final tokens = await _exchange(code: code, verifier: pkce.verifier);

    if (!tokens.hasOfflineAccess) {
      // The exchange succeeded and looks healthy; it simply has no refresh
      // token. Read the granted scope rather than debugging this later.
      _log.warning(
        'No refresh token was granted (scope: ${tokens.grantedScopes.join(' ')})',
      );
    }
    await _adopt(tokens);
    return tokens;
  }

  /// Asks for a code that has to be *sent*. `authenticator` needs nothing and
  /// is answered `auth.mfa_method_not_delivered`.
  Future<void> sendTwoFactorCode(
    TwoFactorChallenge challenge,
    String method,
  ) async {
    final response = await _post(
      _uri(SilexgisContract.twoFactorSendPath),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Cookie': challenge.cookie,
      },
      body: jsonEncode(<String, Object?>{'method': method}),
    );
    if (response.statusCode != 200) {
      throw _authFailure(response);
    }
  }

  /// Restores a session from the stored refresh token. Returns false when
  /// there is none, or when it is beyond renewal and the caver has to type
  /// their password again — which is never a reason to discard or re-download
  /// anything, because the local database is the source of truth regardless.
  Future<bool> restore() async {
    if (_tokens != null) return true;
    final stored = await _store.read(_profileUuid);
    if (stored == null || stored.isEmpty) return false;
    return _redeem(stored);
  }

  Future<void> signOut() async {
    _tokens = null;
    await _store.delete(_profileUuid);
  }

  // ------------------------------------------------------- SilexgisTokenSource

  @override
  Future<String?> accessToken() async {
    final tokens = _tokens;
    if (tokens == null) return null;
    if (tokens.isExpired(_clock.now())) {
      if (!await refresh()) return null;
      return _tokens?.accessToken;
    }
    return tokens.accessToken;
  }

  @override
  Future<bool> refresh() {
    // One refresh at a time, and callers that arrive during one await its
    // answer rather than presenting the same token a second time.
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    final stored = _tokens?.refreshToken ?? await _store.read(_profileUuid);
    if (stored == null || stored.isEmpty) return false;
    return _redeem(stored);
  }

  Future<bool> _redeem(String refreshToken) async {
    try {
      final tokens = await _tokenEndpoint(<String, String>{
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': SilexgisContract.clientId,
      });
      await _adopt(tokens);
      return true;
    } on SilexgisAuthException catch (e) {
      // `invalid_grant` here is spent, expired, replayed — or the account's
      // password was changed or reset, which revokes every token that account
      // holds on every device. All of them mean: ask for a password.
      _log.info('Refresh refused (${e.code}); a password sign-in is needed');
      _tokens = null;
      await _store.delete(_profileUuid);
      return false;
    } on SilexgisTransportException {
      // The credential may still be good; the network was not. Leave the
      // stored token alone so the next run can try again.
      rethrow;
    }
  }

  /// Stores the new pair **before** anything else uses it. The refresh token
  /// in an answer is a new one and the old is spent, so discarding the
  /// response after reading the access token out of it leaves the client
  /// holding a token that has already been redeemed.
  Future<void> _adopt(SilexgisTokens tokens) async {
    _tokens = tokens;
    final refreshToken = tokens.refreshToken;
    if (refreshToken != null) {
      await _store.write(_profileUuid, refreshToken);
    }
  }

  // ------------------------------------------------------------------ the flow

  /// Step 1. The authorization endpoint consumes a session cookie and this is
  /// the only thing that produces one.
  Future<String> _passwordLogin({
    required String email,
    required String password,
    String? twoFactorCode,
    String? twoFactorCookie,
  }) async {
    final response = await _post(
      _uri(SilexgisContract.loginPath),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Cookie': ?twoFactorCookie,
      },
      body: jsonEncode(<String, Object?>{
        'email': email,
        'password': password,
        'twoFactorCode': ?twoFactorCode,
      }),
    );
    if (response.statusCode != 200) throw _authFailure(response);

    final cookie = _sessionCookie(response, 'silexgis.session');
    if (cookie == null) {
      throw const SilexgisAuthException(
        'The server signed in without issuing a session cookie',
        action: SilexgisAction.stop,
      );
    }
    return cookie;
  }

  /// Step 2. The code exists only in the `Location` header and the response
  /// has no body, so the redirect is driven by hand: a client that followed it
  /// would hand the code to whatever answered the callback address, or to
  /// nothing, and would never see the header.
  Future<String> _authorize({
    required String session,
    required PkcePair pkce,
    required String state,
  }) async {
    final request =
        http.Request(
            'GET',
            _uri(SilexgisContract.authorizePath).replace(
              queryParameters: <String, String>{
                'client_id': SilexgisContract.clientId,
                'redirect_uri': redirectUri,
                'response_type': 'code',
                'scope': SilexgisContract.scopes.join(' '),
                'code_challenge': pkce.challenge,
                'code_challenge_method': 'S256',
                'state': state,
              },
            ),
          )
          ..headers['Cookie'] = session
          ..followRedirects = false;

    final response = await _send(request);
    if (response.statusCode != 302) {
      throw _authFailure(response);
    }
    final location = response.headers['location'];
    if (location == null) {
      throw const SilexgisAuthException(
        'The authorization request answered without a redirect',
        action: SilexgisAction.stop,
      );
    }

    final target = Uri.parse(location);
    // Not an error status: a client that checks only the status code parses
    // the sign-in page's own address as a callback and finds no code in it.
    if (target.path.contains('/login')) {
      throw const SilexgisAuthException(
        'The session was not accepted; sign in again',
        code: SilexgisAuthCodes.invalidCredentials,
        action: SilexgisAction.reAuth,
      );
    }
    final error = target.queryParameters['error'];
    if (error != null) {
      throw SilexgisAuthException(
        target.queryParameters['error_description'] ?? error,
        code: error,
      );
    }
    if (target.queryParameters['state'] != state) {
      throw const SilexgisAuthException(
        'The authorization answer did not carry back the state that was sent',
        action: SilexgisAction.stop,
      );
    }
    final code = target.queryParameters['code'];
    if (code == null) {
      throw const SilexgisAuthException(
        'The authorization answer carried no code',
        action: SilexgisAction.stop,
      );
    }
    return code;
  }

  /// Step 3. `redirect_uri` must be byte-identical to the one sent at step 2,
  /// port included.
  Future<SilexgisTokens> _exchange({
    required String code,
    required String verifier,
  }) => _tokenEndpoint(<String, String>{
    'grant_type': 'authorization_code',
    'code': code,
    'redirect_uri': redirectUri,
    'client_id': SilexgisContract.clientId,
    'code_verifier': verifier,
  });

  /// The one route on this server that is form-encoded rather than JSON, and
  /// the one that answers `error`/`error_description` rather than a problem
  /// document. A JSON body here is refused outright.
  Future<SilexgisTokens> _tokenEndpoint(Map<String, String> form) async {
    final response = await _post(
      _uri(SilexgisContract.tokenPath),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: form.entries
          .map(
            (e) =>
                '${Uri.encodeQueryComponent(e.key)}='
                '${Uri.encodeQueryComponent(e.value)}',
          )
          .join('&'),
    );
    final body = _decodeObject(response);
    if (response.statusCode != 200) {
      final error = body?['error'] as String?;
      throw SilexgisAuthException(
        // Shown verbatim: an administrator can turn on confirmed-email
        // enforcement at any time and refreshes then start failing for an
        // account that had been working, with no client-side symptom and
        // nothing the client can do. Inventing a diagnosis leaves the
        // resulting support call with nothing to go on.
        (body?['error_description'] as String?) ??
            error ??
            'The token endpoint refused the request',
        code: error,
        status: response.statusCode,
        action: SilexgisAction.reAuth,
      );
    }
    if (body == null) {
      throw const SilexgisAuthException('The token endpoint answered no body');
    }
    return SilexgisTokens.fromJson(body, _clock.now());
  }

  // ----------------------------------------------------------------- plumbing

  Future<http.Response> _post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) {
    final request = http.Request('POST', uri)
      ..followRedirects = false
      ..body = body;
    request.headers.addAll(headers);
    return _send(request);
  }

  Future<http.Response> _send(http.Request request) async {
    try {
      return await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(_timeout);
    } on Object catch (e, st) {
      throw SilexgisTransportException(
        'Could not reach the server',
        cause: e,
        stackTrace: st,
      );
    }
  }

  Map<String, Object?>? _decodeObject(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map ? Map<String, Object?>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  /// Turns a refusal from the login or two-factor routes into a typed failure,
  /// carrying the two-factor challenge when that is what it is.
  SilexgisAuthException _authFailure(http.Response response) {
    final body = _decodeObject(response);
    final code = body?['code'] as String?;
    final detail =
        (body?['detail'] as String?) ??
        (body?['title'] as String?) ??
        'Sign-in failed';

    if (code == SilexgisAuthCodes.mfaRequired) {
      final cookie = _sessionCookie(response, 'Identity.TwoFactorUserId');
      return TwoFactorRequiredException(
        detail,
        challenge: TwoFactorChallenge(
          methods: (body?['methods'] as List? ?? const <Object?>[])
              .whereType<String>()
              .toList(growable: false),
          preferredMethod: body?['preferredMethod'] as String?,
          recoveryAccepted: body?['recoveryAccepted'] as bool? ?? true,
          cookie: cookie ?? '',
        ),
      );
    }
    return SilexgisAuthException(
      detail,
      code: code,
      status: response.statusCode,
      action: response.statusCode == 429
          ? SilexgisAction.retry
          : SilexgisAction.surfaceToUser,
    );
  }

  /// Reads one named cookie out of the `Set-Cookie` headers.
  ///
  /// `package:http` folds repeated headers into one comma-joined value, and a
  /// cookie's own attributes contain commas of their own (`Expires=Mon, 01 …`),
  /// so this splits on the cookie name rather than on separators.
  static String? _sessionCookie(http.Response response, String name) {
    final raw = response.headers['set-cookie'];
    if (raw == null) return null;
    final start = raw.indexOf('$name=');
    if (start < 0) return null;
    final end = raw.indexOf(';', start);
    return end < 0 ? raw.substring(start) : raw.substring(start, end);
  }

  /// Checked against what comes back before the code is used. Random rather
  /// than derived from anything, because a predictable state is not a guard.
  String _newState() {
    final rng = Random.secure();
    return base64Url
        .encode(List<int>.generate(12, (_) => rng.nextInt(256)))
        .replaceAll('=', '');
  }

  void close() => _client.close();
}

/// The account has two-factor sign-in on. Carries what it can currently use
/// and the half-finished sign-in's cookie.
class TwoFactorRequiredException extends SilexgisAuthException {
  const TwoFactorRequiredException(super.message, {required this.challenge})
    : super(
        code: SilexgisAuthCodes.mfaRequired,
        status: 401,
        action: SilexgisAction.surfaceToUser,
      );

  final TwoFactorChallenge challenge;
}
