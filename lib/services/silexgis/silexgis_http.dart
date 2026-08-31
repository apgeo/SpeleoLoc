import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Supplies the bearer token for one installation, and renews it.
///
/// Kept to these two members on purpose: the transport needs a credential and
/// a way to replace a lapsed one, and nothing else about how a sign-in works.
abstract class SilexgisTokenSource {
  /// The current access token, or null when the device is not signed in.
  Future<String?> accessToken();

  /// Renews the access token. Returns false when the credential is beyond
  /// renewal and the caver has to sign in again.
  ///
  /// Refreshes roll: each one redeems the token presented and issues a new
  /// one, and presenting a redeemed token outside a short retry window revokes
  /// the whole chain. Implementations serialise this against themselves.
  Future<bool> refresh();
}

/// One installation's HTTP surface: a base address, a credential, and the
/// rules that turn a response into either a decoded body or a typed failure.
///
/// It knows nothing about sync routes — see `SilexgisSyncApi` for those.
class SilexgisHttp {
  SilexgisHttp({
    required Uri baseUri,
    required SilexgisTokenSource tokens,
    http.Client? client,
    Duration timeout = const Duration(seconds: 30),
  }) : _baseUri = baseUri,
       _tokens = tokens,
       _client = client ?? http.Client(),
       _timeout = timeout;

  final Uri _baseUri;
  final SilexgisTokenSource _tokens;
  final http.Client _client;
  final Duration _timeout;
  final _log = AppLogger.of('SilexgisHttp');

  /// Builds an absolute address for a route path. A base address may carry a
  /// path prefix of its own — an installation behind a reverse proxy — so the
  /// two are joined rather than the route replacing the base.
  Uri resolve(String path, [Map<String, String>? query]) {
    final prefix = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    final base = _baseUri.replace(path: '$prefix$path');
    return query == null || query.isEmpty
        ? base
        : base.replace(queryParameters: query);
  }

  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, String>? query,
  }) => _send(() => http.Request('GET', resolve(path, query)));

  Future<Map<String, Object?>> postJson(
    String path,
    Object? body, {
    Map<String, String>? query,
  }) => _send(() {
    final request = http.Request('POST', resolve(path, query));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return request;
  });

  Future<Map<String, Object?>> putJson(String path, Object? body) => _send(() {
    final request = http.Request('PUT', resolve(path))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);
    return request;
  });

  Future<void> delete(String path) async {
    await _send(() => http.Request('DELETE', resolve(path)));
  }

  /// Sends [build], and on a `401` refreshes the credential and sends it once
  /// more.
  ///
  /// Once, and never in a loop: if the refresh also fails the caver has to
  /// sign in again, and a device that kept retrying would stop syncing within
  /// the access token's fifteen minutes with nothing in the log but retries.
  Future<Map<String, Object?>> _send(http.Request Function() build) async {
    var response = await _sendOnce(build);
    if (response.statusCode == 401) {
      _log.info('401 — refreshing the credential and retrying once');
      if (!await _tokens.refresh()) {
        throw SilexgisProblemException(
          const SilexgisProblem(status: 401, title: 'Unauthorized'),
        );
      }
      response = await _sendOnce(build);
    }
    return _decode(response);
  }

  Future<http.Response> _sendOnce(http.Request Function() build) async {
    final request = build();
    final token = await _tokens.accessToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    // The API does not redirect. Following one would send the credential to
    // whatever answered instead, so a redirect is a transport failure here.
    request.followRedirects = false;
    try {
      // The timeout covers reading the body as well as opening the connection:
      // a page is either received whole or not at all, and a stall part-way
      // through one is the same failure as never connecting.
      return await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(_timeout);
    } on SilexgisException {
      rethrow;
    } on Object catch (e, st) {
      throw SilexgisTransportException(
        'Could not reach the server',
        cause: e,
        stackTrace: st,
      );
    }
  }

  Map<String, Object?> _decode(http.Response response) {
    final status = response.statusCode;
    if (status >= 300 && status < 400) {
      throw SilexgisTransportException(
        'The server redirected a request the API never redirects',
        status: status,
      );
    }

    Object? body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        body = response.body;
      }
    }

    if (status >= 400) {
      final problem = SilexgisProblem.tryParse(status, body);
      // A `4xx` or `5xx` whose body is not a problem document came from a
      // proxy, a captive portal or a load balancer rather than from this API —
      // a transport failure, not a server verdict. The rule deliberately never
      // reaches a 401, which tryParse synthesises rather than refusing.
      if (problem == null) {
        throw SilexgisTransportException(
          'The server answered $status with a body this API never sends',
          status: status,
        );
      }
      throw SilexgisProblemException(problem);
    }

    if (body == null) return const <String, Object?>{};
    if (body is Map) return Map<String, Object?>.from(body);
    throw SilexgisTransportException(
      'Expected a JSON object and got ${body.runtimeType}',
      status: status,
    );
  }

  void close() => _client.close();
}
