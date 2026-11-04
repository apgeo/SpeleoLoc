import 'package:http/http.dart' as http;
import 'package:speleoloc/services/map/tile_http_client.dart';
import 'package:speleoloc/services/map/tile_security_context.dart';

/// One keep-alive client for every online tile request, cached or not.
///
/// Shared rather than per provider: providers are rebuilt with the layer
/// stack on each map rebuild, so a per-instance client would leak sockets,
/// and TileLayer may dispose a provider while its tiles are still loading.
final http.Client mapTileHttpClient = TileHttpClient(
  TileSecurityContext.load(),
);
