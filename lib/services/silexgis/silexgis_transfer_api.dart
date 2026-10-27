import 'package:speleoloc/services/silexgis/model/sync_file_transfer.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';

/// The installation's resumable transfer routes, as a phone uses them: to
/// stage a file's bytes ahead of the upload that names them.
///
/// They are the server's ordinary file routes, not sync routes, and are kept
/// apart from `SilexgisSyncApi` for that reason.
class SilexgisTransferApi {
  const SilexgisTransferApi(this._http);

  final SilexgisHttp _http;

  /// A piece is megabytes, so it is given longer than a page of rows.
  static const Duration pieceTimeout = Duration(minutes: 5);

  Future<SilexgisFilesConfig> config() async => SilexgisFilesConfig.fromJson(
    await _http.getJson(SilexgisContract.filesConfigPath),
  );

  /// Opens a transfer for staged bytes. It has no destination of its own —
  /// where the file ends up is the upload's to say — so none is named.
  Future<SilexgisTransfer> open({
    required String fileName,
    required int sizeBytes,
  }) async => SilexgisTransfer.fromJson(
    await _http.postJson(SilexgisContract.fileUploadsPath, <String, Object?>{
      'fileName': fileName,
      'sizeBytes': sizeBytes,
      'stageForSync': true,
    }),
  );

  /// How far [transferId] got, and whether its bytes are still staged.
  Future<SilexgisTransfer> status(String transferId) async =>
      SilexgisTransfer.fromJson(
        await _http.getJson(SilexgisContract.fileUploadPath(transferId)),
      );

  /// Sends one piece at [offset]. A piece the server already holds is
  /// answered as if it had just arrived, so a piece whose answer was lost can
  /// simply be sent again.
  Future<SilexgisTransfer> sendPiece(
    String transferId, {
    required int offset,
    required List<int> bytes,
  }) async => SilexgisTransfer.fromJson(
    await _http.putBytes(
      SilexgisContract.fileUploadPath(transferId),
      bytes,
      query: <String, String>{'offset': '$offset'},
      timeout: pieceTimeout,
    ),
  );

  /// Completes the transfer. Completing again answers the same thing and does
  /// not move the expiry, so a lost answer costs one request.
  Future<SilexgisStagedBytes> complete(String transferId) async =>
      SilexgisStagedBytes.fromJson(
        await _http.postJson(
          SilexgisContract.fileUploadCompletePath(transferId),
          null,
        ),
      );

  /// Withdraws a transfer and its bytes, which stop counting against the
  /// account's room.
  Future<void> withdraw(String transferId) =>
      _http.delete(SilexgisContract.fileUploadPath(transferId));
}
