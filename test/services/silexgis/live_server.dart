import 'dart:convert';
import 'dart:io';

// What the live tests need from the development server beyond the sync routes:
// identifiers that differ per installation, read the way a person would find
// them. Shared by every live test file; none of it is part of the contract.

/// Why the live tests do not run in this environment, or null when they may.
///
/// They sign in with the development server's published accounts and write
/// rows into it, so they run only when asked for by name.
String? liveSkipReason(Map<String, String> env) =>
    env['SPELEO_LOC_SILEXGIS_LIVE'] == '1'
    ? null
    : 'set SPELEO_LOC_SILEXGIS_LIVE=1 to run against a development server';

/// The development server's address: `SPELEO_LOC_SILEXGIS_URL`, or the port
/// the script that starts it prints.
///
/// The tests sign in with a well-known password and create and remove rows,
/// which belongs on a server on this machine and nowhere else. An address on
/// another machine is refused unless `SPELEO_LOC_SILEXGIS_REMOTE=1` says that
/// it, too, is a disposable development server.
Uri liveBaseUri(Map<String, String> env) {
  final uri = Uri.parse(
    env['SPELEO_LOC_SILEXGIS_URL'] ?? 'http://127.0.0.1:5205',
  );
  final loopback = <String>{'127.0.0.1', '::1', '[::1]', 'localhost'};
  if (!loopback.contains(uri.host) &&
      env['SPELEO_LOC_SILEXGIS_REMOTE'] != '1') {
    throw ArgumentError.value(
      uri.toString(),
      'SPELEO_LOC_SILEXGIS_URL',
      'is not on this machine; set SPELEO_LOC_SILEXGIS_REMOTE=1 if it is a '
          'disposable development server',
    );
  }
  return uri;
}

/// The demonstration caves' feature ids — all six, or those named in [names] —
/// read from the ordinary cave list.
///
/// That route is not part of this contract and the client has no reason to
/// call it; the test does, because a sync set names roots by identifier and
/// the seeded identifiers differ per installation.
///
/// It is also the route that shows the withhold rule bounds this channel and
/// not the server: `Avenul Demo Protejat` comes back from here with a
/// grid-snapped point and `approximateLocation: true`, and is absent from the
/// sync download altogether.
Future<List<String>> demoCaveFeatureIds(
  Uri baseUri,
  String? token, {
  Set<String> names = demoCaveNames,
}) async {
  final http = HttpClient();
  try {
    final request = await http.getUrl(
      baseUri.replace(
        path: '/api/v1/caves',
        queryParameters: {'pageSize': '50'},
      ),
    );
    request.headers.set('Authorization', 'Bearer $token');
    final response = await request.close();
    final body = await response.transform(const Utf8Decoder()).join();
    final decoded = jsonDecode(body);
    final items = decoded is Map ? decoded['items'] as List : decoded as List;
    return items
        .cast<Map<String, Object?>>()
        // Only the seeded demonstration caves. A development database that has
        // been written into by hand holds other caves as well, and the row
        // counts below are statements about the demo dataset.
        .where((c) => names.contains(c['name']))
        .map((c) => c['id'] as String?)
        .whereType<String>()
        .toList(growable: false);
  } finally {
    http.close();
  }
}

/// The caving group both development accounts belong to.
///
/// A sync set has to name one before an account that owns nothing may create
/// any row through it — which no document says, and which
/// `docs/integrations/silexgis/found-defects.md` records.
Future<String> demoCavingGroupId(Uri baseUri, String? token) async {
  final http = HttpClient();
  try {
    final request = await http.getUrl(
      baseUri.replace(path: '/api/v1/caving-groups'),
    );
    request.headers.set('Authorization', 'Bearer $token');
    final response = await request.close();
    final body = await response.transform(const Utf8Decoder()).join();
    final decoded = jsonDecode(body);
    final items = decoded is Map ? decoded['items'] as List : decoded as List;
    return (items.first as Map<String, Object?>)['id']! as String;
  } finally {
    http.close();
  }
}

/// The demonstration dataset, by name. Six caves, of which one is protected
/// and one is visible only through the caving group.
const Set<String> demoCaveNames = <String>{
  'Peștera Demo Mare',
  'Avenul Demo Protejat',
  'Peștera Demo Mică',
  'Peștera Demo Ursului',
  'Avenul Demo Vântului',
  'Peștera Demo Izvorului',
};

/// Decides one held row as a reviewer would in the browser.
///
/// The review routes are not part of this contract and the client never calls
/// them; the test stands in for the person who decides. [adminToken] is the
/// administrator's, since only a reviewer may decide.
Future<void> decideReview(
  Uri baseUri,
  String? adminToken,
  String reviewId, {
  required bool accept,
  String? note,
}) async {
  final http = HttpClient();
  try {
    final request = await http.postUrl(
      baseUri.replace(
        path: '/api/v1/review/items/$reviewId/${accept ? 'accept' : 'reject'}',
      ),
    );
    request.headers
      ..set('Authorization', 'Bearer $adminToken')
      ..contentType = ContentType.json;
    request.write(jsonEncode(<String, Object?>{'note': ?note}));
    final response = await request.close();
    final body = await response.transform(const Utf8Decoder()).join();
    if (response.statusCode >= 300) {
      throw HttpException('review $reviewId: ${response.statusCode} $body');
    }
  } finally {
    http.close();
  }
}
