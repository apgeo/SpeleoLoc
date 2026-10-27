import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// What arrived, measured on the device.
class SilexgisFetchedFile {
  const SilexgisFetchedFile({
    required this.length,
    required this.sha256,
    this.announcedLength,
    this.contentType,
  });

  final int length;

  /// Lower-case hex, over the whole file however many requests it took.
  final String sha256;

  /// The length the server said the whole file has, when it said one.
  final int? announcedLength;
  final String? contentType;
}

/// The address has expired, or never opened: ask the server for a new one.
/// The content route never says which.
class SilexgisAddressExpired implements Exception {
  const SilexgisAddressExpired();
}

/// Fetches a file from a signed address into a local file.
///
/// The address is relative to the installation and its token is the whole
/// credential, so no bearer token goes with it. A file is fetched with HTTP
/// `Range` from where the local file ends: a large original survives a poor
/// connection, a dropped run and an expired address, since the next address
/// for the same file resumes into the same local file.
class SilexgisFileFetcher {
  SilexgisFileFetcher({
    required Uri baseUri,
    http.Client? client,
    this.maxResumes = 5,
    Duration idleTimeout = const Duration(seconds: 60),
  }) : _baseUri = baseUri,
       _client = client ?? http.Client(),
       _idleTimeout = idleTimeout;

  final Uri _baseUri;
  final http.Client _client;
  final Duration _idleTimeout;

  /// How many times one fetch picks up after the connection dropped.
  final int maxResumes;
  final _log = AppLogger.of('SilexgisFileFetcher');

  /// The absolute address of [url]. A base address may carry a path prefix of
  /// its own — an installation behind a reverse proxy — and the two are
  /// joined rather than the address replacing it.
  Uri resolve(String url) {
    final parsed = Uri.parse(url);
    if (parsed.hasScheme) return parsed;
    final prefix = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    return _baseUri.replace(
      path: '$prefix${parsed.path}',
      query: parsed.hasQuery ? parsed.query : null,
    );
  }

  /// Fetches [url] into [target], resuming from whatever [target] already
  /// holds when [resumable].
  ///
  /// Throws [SilexgisAddressExpired] on a `404`, keeping what arrived; any
  /// other failure is a [SilexgisTransportException].
  Future<SilexgisFetchedFile> fetch(
    String url,
    File target, {
    bool resumable = true,
  }) async {
    if (!resumable && await target.exists()) await target.delete();
    await target.parent.create(recursive: true);

    var resumes = 0;
    int? announced;
    String? contentType;
    while (true) {
      final have = await target.exists() ? await target.length() : 0;
      final request = http.Request('GET', resolve(url));
      if (have > 0) request.headers['Range'] = 'bytes=$have-';

      final http.StreamedResponse response;
      try {
        response = await _client.send(request).timeout(_idleTimeout);
      } on Object catch (e, st) {
        if (resumable && resumes < maxResumes) {
          resumes++;
          continue;
        }
        throw SilexgisTransportException(
          'Could not reach the server for a file',
          cause: e,
          stackTrace: st,
        );
      }

      final status = response.statusCode;
      contentType = response.headers['content-type'] ?? contentType;
      if (status == 404) {
        await response.stream.drain<void>();
        throw const SilexgisAddressExpired();
      }
      if (status == 416 && have > 0) {
        // Nothing past what is here: either it is all here, or the file
        // behind the address changed and what is here is of no use.
        await response.stream.drain<void>();
        final total = _totalOf(response.headers['content-range']);
        if (total == have) {
          announced = total;
          break;
        }
        await target.delete();
        continue;
      }

      final IOSink sink;
      if (status == 206 && have > 0) {
        final range = response.headers['content-range'];
        if (_startOf(range) != have) {
          // Not the piece asked for; start over rather than splice.
          await response.stream.drain<void>();
          await target.delete();
          continue;
        }
        announced = _totalOf(range) ?? announced;
        sink = target.openWrite(mode: FileMode.append);
      } else if (status == 200) {
        // The whole file, whatever was asked: a server is free to ignore a
        // range.
        announced = response.contentLength;
        sink = target.openWrite();
      } else {
        await response.stream.drain<void>();
        throw SilexgisTransportException(
          'The server answered $status for a file',
          status: status,
        );
      }

      try {
        await sink.addStream(response.stream.timeout(_idleTimeout));
        await sink.flush();
        await sink.close();
        break;
      } on Object catch (e, st) {
        await sink.close().catchError((Object _) {});
        if (resumable && resumes < maxResumes) {
          resumes++;
          _log.info('a file fetch dropped; resuming ($resumes/$maxResumes)');
          continue;
        }
        throw SilexgisTransportException(
          'The connection dropped while fetching a file',
          cause: e,
          stackTrace: st,
        );
      }
    }

    final length = await target.length();
    final digest = await sha256.bind(target.openRead()).first;
    return SilexgisFetchedFile(
      length: length,
      sha256: digest.toString(),
      announcedLength: announced,
      contentType: contentType,
    );
  }

  /// `bytes 100-199/2000` → 100.
  static int? _startOf(String? contentRange) {
    final match = RegExp(r'bytes (\d+)-').firstMatch(contentRange ?? '');
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// `bytes 100-199/2000` or `bytes */2000` → 2000.
  static int? _totalOf(String? contentRange) {
    final match = RegExp(r'/(\d+)$').firstMatch(contentRange ?? '');
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  void close() => _client.close();
}
