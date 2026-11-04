import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// The HTTP client for online map tiles, trusting what [context] trusts.
///
/// The context comes from assets, which load asynchronously, while tile
/// providers need a client at once; requests wait for it here. A context
/// that fails to load leaves the system's trust alone rather than no map.
class TileHttpClient extends http.BaseClient {
  TileHttpClient(Future<SecurityContext> context)
    : _inner = context.then(
        (c) => IOClient(HttpClient(context: c)),
        onError: (Object e, StackTrace st) {
          _log.warning(
            'Map tile certificates did not load; using system roots only',
            e,
            st,
          );
          return http.Client();
        },
      );

  static final _log = AppLogger.of('TileHttpClient');

  final Future<http.Client> _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      (await _inner).send(request);

  @override
  void close() {
    unawaited(_inner.then((client) => client.close()));
  }
}
