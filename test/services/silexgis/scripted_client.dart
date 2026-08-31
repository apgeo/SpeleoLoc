import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// One recorded request the test can assert about after the fact.
class SentRequest {
  SentRequest(this.method, this.url, this.headers, this.body);

  final String method;
  final Uri url;
  final Map<String, String> headers;
  final String body;

  Map<String, Object?> get jsonBody => jsonDecode(body) as Map<String, Object?>;

  /// The `application/x-www-form-urlencoded` body, decoded.
  Map<String, String> get formBody => Uri.splitQueryString(body);
}

/// An `http.Client` that answers from a script instead of a network.
///
/// Each entry is matched on the request's path, in order, and consumed. A
/// request with no entry left for it fails the test loudly rather than
/// returning something plausible.
class ScriptedClient extends http.BaseClient {
  ScriptedClient(this._script);

  final List<ScriptedResponse> _script;
  final List<SentRequest> sent = <SentRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? request.body : '';
    sent.add(SentRequest(request.method, request.url, request.headers, body));

    final index = _script.indexWhere((r) => r.matches(request));
    if (index < 0) {
      throw StateError(
        'No scripted response for ${request.method} ${request.url.path}'
        '${request.url.hasQuery ? '?${request.url.query}' : ''}',
      );
    }
    final scripted = _script.removeAt(index);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(scripted.body)),
      scripted.status,
      headers: scripted.headersFor?.call(request) ?? scripted.headers,
      request: request,
    );
  }

  bool get isExhausted => _script.isEmpty;
}

class ScriptedResponse {
  ScriptedResponse({
    required this.path,
    required this.status,
    this.body = '',
    this.headers = const <String, String>{},
    this.headersFor,
  });

  ScriptedResponse.json({
    required this.path,
    this.status = 200,
    required Object? json,
    Map<String, String> headers = const <String, String>{},
  }) : body = jsonEncode(json),
       headersFor = null,
       headers = <String, String>{
         'content-type': 'application/json',
         ...headers,
       };

  ScriptedResponse.problem({
    required this.path,
    required this.status,
    String? code,
    String? title,
    String? detail,
  }) : body = jsonEncode(<String, Object?>{
         'status': status,
         'title': ?title,
         'code': ?code,
         'detail': ?detail,
         'traceId': '00-0000000000000000000000000000-0000000000000000-00',
       }),
       headersFor = null,
       headers = const <String, String>{
         'content-type': 'application/problem+json',
       };

  final String path;
  final int status;
  final String body;
  final Map<String, String> headers;

  /// Builds the response headers from the request, for the one exchange whose
  /// answer echoes something it was sent — the authorization redirect, which
  /// carries the caller's own `state` back.
  final Map<String, String> Function(http.BaseRequest request)? headersFor;

  bool matches(http.BaseRequest request) => request.url.path == path;
}
