import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_fetcher.dart';

/// A signed file address carries its own token, which is the whole credential
/// for that file, so it is held to the same rule as the API itself.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('silexgis_fetch_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('opens nothing over plain http to another machine', () async {
    final requested = <Uri>[];
    final client = MockClient((request) async {
      requested.add(request.url);
      return http.Response('bytes', 200);
    });
    final fetcher = SilexgisFileFetcher(
      baseUri: Uri.parse('http://club.example.org'),
      client: client,
    );

    await expectLater(
      fetcher.fetch(
        '/api/v1/sync/files/content?token=signed',
        File('${dir.path}/photo.jpg'),
      ),
      throwsA(isA<SilexgisInsecureAddressException>()),
    );
    expect(requested, isEmpty);
  });

  test('opens nothing at an absolute http address the server hands back, '
      'even from an https installation', () async {
    final requested = <Uri>[];
    final client = MockClient((request) async {
      requested.add(request.url);
      return http.Response('bytes', 200);
    });
    final fetcher = SilexgisFileFetcher(
      baseUri: Uri.parse('https://club.example.org'),
      client: client,
    );

    await expectLater(
      fetcher.fetch(
        'http://files.example.org/content?token=signed',
        File('${dir.path}/photo.jpg'),
      ),
      throwsA(isA<SilexgisInsecureAddressException>()),
    );
    expect(requested, isEmpty);
  });
}
