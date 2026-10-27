import 'dart:convert';
import 'dart:io';

// What the live tests need from the development server beyond the sync routes:
// identifiers that differ per installation, read the way a person would find
// them. Shared by every live test file; none of it is part of the contract.

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
