import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/data_archive_service.dart';
import 'package:speleoloc/services/data_export_import_repository.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Fetches a test-data archive (zip exported by [DataArchiveService]) from a
/// remote `http(s)` URL, a local filesystem path, or a build-embedded asset
/// path, and imports it via [DataArchiveService.importArchiveReplace] (full
/// replace).
///
/// The archive is expected to be a `DataArchiveService` zip even if the file
/// (or URL) carries no `.zip` extension.
class TestArchiveImportService {
  TestArchiveImportService._();

  static final _log = AppLogger.of('TestArchiveImportService');

  /// Returns `true` if [urlOrPath] looks like a remote URL we should download.
  static bool isRemoteUrl(String urlOrPath) {
    final lower = urlOrPath.trim().toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  /// Resolves [urlOrPath] to archive bytes, in order:
  ///  1. `http(s)://` → download over the network.
  ///  2. an existing file on disk → read it directly (e.g. an absolute
  ///     dev-machine path supplied via `--dart-define-from-file` for the
  ///     "local archive" run workflow; requires the run target to be able to
  ///     reach that path, e.g. the desktop build / the dev machine).
  ///  3. otherwise → treat it as a bundled asset key ([rootBundle]).
  ///
  /// Throws on network/asset failure with a descriptive message.
  static Future<Uint8List> fetchArchiveBytes(String urlOrPath) async {
    final value = urlOrPath.trim();
    if (value.isEmpty) {
      throw Exception('test_archive_url is not configured');
    }

    if (isRemoteUrl(value)) {
      _log.info('Downloading test archive from $value');
      final uri = Uri.parse(value);
      final client = HttpClient();
      try {
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
            'HTTP ${response.statusCode} ${response.reasonPhrase} '
            'while downloading $value',
          );
        }
        final builder = BytesBuilder(copy: false);
        await for (final chunk in response) {
          builder.add(chunk);
        }
        final bytes = builder.takeBytes();
        _log.info('Downloaded ${bytes.length} bytes');
        return bytes;
      } finally {
        client.close(force: true);
      }
    }

    // A local filesystem path (e.g. an absolute dev-machine path supplied via
    // --dart-define-from-file for the "local archive" run workflow). When the
    // file exists on disk, read it directly so it loads without being bundled
    // as an asset. Works on any run target that can reach the path (desktop
    // build / dev machine); on a mobile device an absolute host path won't
    // exist, so it falls through to the asset lookup below.
    final localFile = File(value);
    if (await localFile.exists()) {
      _log.info('Loading test archive from local file "$value"');
      return localFile.readAsBytes();
    }

    // Otherwise treat as a bundled asset key (e.g. assets/test_archive/foo.zip).
    _log.info('Loading test archive from bundled asset "$value"');
    final ByteData data = await rootBundle.load(value);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Downloads/loads the archive, writes it to a temp file, and imports it
  /// using [DataArchiveService.importArchiveReplace]. Caller is responsible
  /// for restarting the app afterwards (same contract as the export-import
  /// page replace flow).
  static Future<void> importFrom({
    required String urlOrPath,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Downloading test archive...');
    final bytes = await fetchArchiveBytes(urlOrPath);

    onProgress?.call('Preparing archive...');
    final tempDir = await getTemporaryDirectory();
    // .zip extension is irrelevant to ZipDecoder but harmless to use.
    final tempFile = File(p.join(tempDir.path, 'test_archive_download.zip'));
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    await tempFile.writeAsBytes(bytes, flush: true);

    try {
      final service = DataArchiveService(
        DataExportImportRepository(appDatabase),
      );
      await service.importArchiveReplace(
        zipPath: tempFile.path,
        onProgress: onProgress,
      );
    } finally {
      try {
        if (await tempFile.exists()) await tempFile.delete();
      } catch (e, st) {
        AppLogger.of(
          'TestArchiveImport',
        ).fine('Temp archive cleanup failed', e, st);
      }
    }
  }
}
