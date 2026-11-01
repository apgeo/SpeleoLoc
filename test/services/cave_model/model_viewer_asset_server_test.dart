import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/cave_model/caveview_assets.dart';
import 'package:speleoloc/services/cave_model/model_viewer_asset_server.dart';
import 'package:speleoloc/services/cave_model/survey_model_format.dart';

void main() {
  late Directory dir;
  late File model;
  late ModelViewerAssetServer server;
  late Uri page;
  late String token;
  final client = HttpClient();

  final assets = {
    '${CaveViewAssets.hostDir}/index.html': '<html></html>',
    '${CaveViewAssets.hostDir}/bridge.js': '// bridge',
    '${CaveViewAssets.buildDir}/js/CaveView2.min.js': '// viewer',
  };

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('model_server_test');
    model = File('${dir.path}/doc_1_survey')
      ..writeAsBytesSync(List.generate(5000, (i) => i % 251));
    server = ModelViewerAssetServer(
      loadAsset: (key) async {
        final text = assets[key];
        return text == null
            ? null
            : ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
      },
      modelFile: model,
      format: SurveyModelFormat.lox,
      random: Random(7),
    );
    page = await server.start(language: 'ro');
    token = page.pathSegments.first;
  });

  tearDown(() async {
    await server.stop();
    await dir.delete(recursive: true);
  });

  Future<(int, List<int>, String?)> get(
    Uri uri, {
    String method = 'GET',
  }) async {
    final request = await client.openUrl(method, uri);
    final response = await request.close();
    final body = await response.fold<List<int>>([], (all, b) => all..addAll(b));
    return (response.statusCode, body, response.headers.contentType?.mimeType);
  }

  Uri at(String path) => page.replace(path: path, query: '');

  test('the page address is on loopback and names the model and language', () {
    expect(page.host, '127.0.0.1');
    expect(page.path, '/$token/host/index.html');
    expect(token, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(page.queryParameters, {'model': 'model.lox', 'lang': 'ro'});
  });

  test(
    'serves the host page and the vendored build with their types',
    () async {
      final (status, body, type) = await get(page);
      expect(status, 200);
      expect(type, 'text/html');
      expect(utf8.decode(body), '<html></html>');

      final (jsStatus, _, jsType) = await get(
        at('/$token/caveview/js/CaveView2.min.js'),
      );
      expect(jsStatus, 200);
      expect(jsType, 'text/javascript');
    },
  );

  test('streams the model under the name its format needs', () async {
    final (status, body, type) = await get(at('/$token/model/model.lox'));
    expect(status, 200);
    expect(type, 'application/octet-stream');
    expect(body, model.readAsBytesSync());
  });

  test('answers nothing without the token', () async {
    final wrong = '0' * 32;
    expect((await get(at('/$wrong/host/index.html'))).$1, 404);
    expect((await get(at('/host/index.html'))).$1, 404);
    expect((await get(at('/'))).$1, 404);
  });

  test('answers nothing outside what the screen shows', () async {
    expect((await get(at('/$token/model/model.3d'))).$1, 404);
    expect((await get(at('/$token/model/doc_1_survey'))).$1, 404);
    expect((await get(at('/$token/host/missing.js'))).$1, 404);
    expect((await get(at('/$token/other/index.html'))).$1, 404);
    expect((await get(at('/$token/host/%2E%2E/%2E%2E/pubspec.yaml'))).$1, 404);
    expect((await get(at('/$token/host/.hidden'))).$1, 404);
  });

  test('serves only the photos it was given', () async {
    final photo = File('${dir.path}/doc_2_lake.JPG')
      ..writeAsBytesSync([1, 2, 3]);
    final relative = server.serveMedia(photo);
    expect(relative, '../media/m0.jpg');
    final (status, body, type) = await get(at('/$token/media/m0.jpg'));
    expect(status, 200);
    expect(type, 'image/jpeg');
    expect(body, [1, 2, 3]);
    expect((await get(at('/$token/media/m1.jpg'))).$1, 404);
  });

  test('is read-only', () async {
    expect((await get(page, method: 'POST')).$1, 405);
    expect((await get(page, method: 'PUT')).$1, 405);
  });

  test('stops listening when stopped', () async {
    await server.stop();
    await expectLater(get(page), throwsA(isA<SocketException>()));
  });
}
