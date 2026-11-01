import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:speleoloc/services/cave_model/caveview_assets.dart';
import 'package:speleoloc/services/cave_model/survey_model_format.dart';

/// Reads one bundled asset by its key, or answers null when the app bundles
/// no asset of that name.
typedef AssetBytesLoader = Future<ByteData?> Function(String key);

/// Serves the 3D viewer's page, the vendored CaveView build and one survey
/// file to the WebView, on a loopback port, while the viewer screen is open.
///
/// A page opened from a file URL cannot read the survey: CaveView fetches it
/// with XMLHttpRequest, and WKWebView refuses requests from one local file to
/// another. Served over http from 127.0.0.1, page and survey share an origin.
///
/// Other apps on the device can reach a loopback port too, so every path
/// starts with a random token and anything else is answered 404; only what
/// this screen shows is served, read-only, and the server stops with it.
class ModelViewerAssetServer {
  ModelViewerAssetServer({
    required AssetBytesLoader loadAsset,
    required File modelFile,
    required SurveyModelFormat format,
    Random? random,
  }) : _loadAsset = loadAsset,
       _modelFile = modelFile,
       _modelName = 'model.${format.extension}',
       _token = _newToken(random ?? Random.secure());

  final AssetBytesLoader _loadAsset;
  final File _modelFile;
  final String _modelName;
  final String _token;
  HttpServer? _server;
  final _media = <String, File>{};

  static String _newToken(Random random) => List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  /// Starts serving and returns the address of the host page.
  Future<Uri> start({required String language}) async {
    final server = _server ??= await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    server.listen((request) => unawaited(_answer(request)));
    return Uri(
      scheme: 'http',
      host: server.address.address,
      port: server.port,
      path: '/$_token/host/index.html',
      queryParameters: {'model': _modelName, 'lang': language},
    );
  }

  /// Serves [file] — a photo shown on a station — and returns its address
  /// relative to the host page. Only files offered here are served.
  String serveMedia(File file) {
    final dot = file.path.lastIndexOf('.');
    final ext = dot < 0 ? '' : file.path.substring(dot + 1).toLowerCase();
    final name = 'm${_media.length}${ext.isEmpty ? '' : '.$ext'}';
    _media[name] = file;
    return '../media/$name';
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  // A segment of a served path: no `..`, no hidden files, nothing a bundled
  // asset key would not contain.
  static final _segment = RegExp(r'^[A-Za-z0-9_-][A-Za-z0-9_.-]*$');

  static const _types = {
    'html': 'text/html; charset=utf-8',
    'js': 'text/javascript; charset=utf-8',
    'css': 'text/css; charset=utf-8',
    'json': 'application/json',
    'svg': 'image/svg+xml',
  };

  Future<void> _answer(HttpRequest request) async {
    try {
      await _respond(request);
      await request.response.close();
    } on IOException {
      // The WebView went away mid-answer; there is nobody left to answer.
    }
  }

  Future<void> _respond(HttpRequest request) async {
    final response = request.response;
    if (request.method != 'GET' && request.method != 'HEAD') {
      response.statusCode = HttpStatus.methodNotAllowed;
      return;
    }
    final segments = request.uri.pathSegments;
    if (segments.length < 3 ||
        segments.first != _token ||
        !segments.skip(1).every(_segment.hasMatch)) {
      response.statusCode = HttpStatus.notFound;
      return;
    }
    final area = segments[1];
    final rest = segments.skip(2).join('/');
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    if (area == 'model' && rest == _modelName) {
      await _sendFile(request, _modelFile, ContentType.binary);
    } else if (area == 'media' && _media.containsKey(rest)) {
      await _sendFile(request, _media[rest]!, _imageType(rest));
    } else if (area == 'host') {
      await _sendAsset(request, '${CaveViewAssets.hostDir}/$rest');
    } else if (area == 'caveview') {
      await _sendAsset(request, '${CaveViewAssets.buildDir}/$rest');
    } else {
      response.statusCode = HttpStatus.notFound;
    }
  }

  static ContentType _imageType(String name) =>
      switch (name.substring(name.lastIndexOf('.') + 1)) {
        'png' => ContentType('image', 'png'),
        'webp' => ContentType('image', 'webp'),
        'gif' => ContentType('image', 'gif'),
        _ => ContentType('image', 'jpeg'),
      };

  Future<void> _sendFile(
    HttpRequest request,
    File file,
    ContentType type,
  ) async {
    final response = request.response;
    if (!await file.exists()) {
      response.statusCode = HttpStatus.notFound;
      return;
    }
    response.headers.contentType = type;
    response.contentLength = await file.length();
    if (request.method == 'GET') await response.addStream(file.openRead());
  }

  Future<void> _sendAsset(HttpRequest request, String key) async {
    final response = request.response;
    final data = await _loadAsset(key);
    if (data == null) {
      response.statusCode = HttpStatus.notFound;
      return;
    }
    final dot = key.lastIndexOf('.');
    final type = _types[key.substring(dot + 1)];
    if (type != null) response.headers.set(HttpHeaders.contentTypeHeader, type);
    response.contentLength = data.lengthInBytes;
    if (request.method == 'GET') {
      response.add(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }
  }
}
