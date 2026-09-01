import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_set.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';

/// The eight sync routes, typed.
///
/// Every one is bearer-only: no sync route joins the anonymous allow-list, and
/// no capability token ever appears in a sync payload.
class SilexgisSyncApi {
  const SilexgisSyncApi(this._http);

  final SilexgisHttp _http;

  /// Ask this first, once per server, and keep the answer. It is also the
  /// cheapest place to discover that a stored credential has lapsed.
  Future<SilexgisCapabilities> capabilities() async =>
      SilexgisCapabilities.fromJson(
        await _http.getJson(SilexgisContract.capabilitiesPath),
      );

  /// The sets this account owns. A set somebody else owns is reported exactly
  /// like one that does not exist, so this route cannot be used to count other
  /// people's devices.
  Future<List<SyncSet>> listSets() async {
    final body = await _http.getJson(SilexgisContract.setsPath);
    final items = body['items'] ?? body['sets'];
    return (items as List? ?? const <Object?>[])
        .whereType<Map>()
        .map((e) => SyncSet.fromJson(Map<String, Object?>.from(e)))
        .toList(growable: false);
  }

  Future<SyncSet> getSet(String setId) async =>
      SyncSet.fromJson(await _http.getJson(SilexgisContract.setPath(setId)));

  Future<SyncSet> createSet(SyncSetWrite write) async => SyncSet.fromJson(
    await _http.postJson(SilexgisContract.setsPath, write.toJson()),
  );

  /// Replaces the whole document — the selection and the settings together —
  /// arbitrated on the revision the caller last read. Sending none is refused
  /// `sync.set_revision_required`; sending a stale one, `sync.set_conflict`.
  ///
  /// A successful write moves `setRevision`, which retires every download
  /// cursor issued before it.
  Future<SyncSet> replaceSet(String setId, SyncSetWrite write) async =>
      SyncSet.fromJson(
        await _http.putJson(SilexgisContract.setPath(setId), write.toJson()),
      );

  Future<void> deleteSet(String setId) =>
      _http.delete(SilexgisContract.setPath(setId));

  /// One page. [cursor] is the whole of the device's position — the server
  /// keeps nothing between requests — and is opaque: store it, send it back,
  /// never parse it.
  ///
  /// Omitting [pageSize] asks for the installation's own default, which is
  /// announced nowhere; a device that needs to know its page size names one. A
  /// named size above the announced ceiling is clamped silently, so count the
  /// rows rather than assuming you got what you asked for.
  Future<SyncDownloadPage> download(
    String setId, {
    String? cursor,
    int? pageSize,
  }) async => SyncDownloadPage.fromJson(
    await _http.getJson(
      SilexgisContract.downloadPath(setId),
      query: <String, String>{
        'cursor': ?cursor,
        if (pageSize != null) 'pageSize': '$pageSize',
      },
    ),
  );

  /// Sends one attempt. The same `batchId` sent again returns the first answer
  /// and writes nothing, which is what makes a resend safe when the answer was
  /// lost on the way back.
  ///
  /// A row's verdict rides the `200` this returns; only a whole-batch refusal
  /// throws, and it carries no per-row results at all.
  Future<SyncUploadResult> upload(String setId, SyncUploadBatch batch) async =>
      SyncUploadResult.fromJson(
        await _http.postJson(
          SilexgisContract.uploadPath(setId),
          batch.toJson(),
        ),
      );
}
