import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_download_page.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/model/sync_people.dart';
import 'package:speleoloc/services/silexgis/model/sync_rasters.dart';
import 'package:speleoloc/services/silexgis/model/sync_review.dart';
import 'package:speleoloc/services/silexgis/model/sync_set.dart';
import 'package:speleoloc/services/silexgis/model/sync_trips.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';

/// The sync routes, typed.
///
/// Every one is bearer-only: no sync route joins the anonymous allow-list, and
/// no capability token ever appears in a sync payload.
class SilexgisSyncApi {
  const SilexgisSyncApi(this._http);

  final SilexgisHttp _http;

  /// Ask this first, on every run: which parts are served is worked out per
  /// request. It is also the cheapest place to discover that a stored
  /// credential has lapsed.
  Future<SilexgisCapabilities> capabilities() async =>
      SilexgisCapabilities.fromJson(
        await _http.getJson(SilexgisContract.capabilitiesPath),
      );

  /// The sets this account owns. A set somebody else owns is reported exactly
  /// like one that does not exist, so this route cannot be used to count other
  /// people's devices.
  Future<List<SyncSet>> listSets() async {
    final items = await _http.getJsonList(SilexgisContract.setsPath);
    return items
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

  /// One page of the decisions on rows this account's phones sent while it
  /// was under review, oldest first, on the reviews stream's own cursor.
  Future<SyncReviewsPage> reviews(
    String setId, {
    String? cursor,
    int? pageSize,
  }) async => SyncReviewsPage.fromJson(
    await _http.getJson(
      SilexgisContract.reviewsPath(setId),
      query: <String, String>{
        'cursor': ?cursor,
        if (pageSize != null) 'pageSize': '$pageSize',
      },
    ),
  );

  /// One page of the photo and document catalogue, on the documents stream's
  /// own cursor. Metadata only: no file comes with it.
  Future<SyncDocumentsPage> documents(
    String setId, {
    String? cursor,
    int? pageSize,
  }) async => SyncDocumentsPage.fromJson(
    await _http.getJson(
      SilexgisContract.documentsPath(setId),
      query: <String, String>{
        'cursor': ?cursor,
        if (pageSize != null) 'pageSize': '$pageSize',
      },
    ),
  );

  /// One page of the trip recordings, with their scans, on the trips stream's
  /// own cursor.
  Future<SyncTripsPage> trips(
    String setId, {
    String? cursor,
    int? pageSize,
  }) async => SyncTripsPage.fromJson(
    await _http.getJson(
      SilexgisContract.tripsPath(setId),
      query: <String, String>{
        'cursor': ?cursor,
        if (pageSize != null) 'pageSize': '$pageSize',
      },
    ),
  );

  /// One page of the raster maps, with their pins, on the rasters stream's
  /// own cursor.
  Future<SyncRastersPage> rasters(
    String setId, {
    String? cursor,
    int? pageSize,
  }) async => SyncRastersPage.fromJson(
    await _http.getJson(
      SilexgisContract.rastersPath(setId),
      query: <String, String>{
        'cursor': ?cursor,
        if (pageSize != null) 'pageSize': '$pageSize',
      },
    ),
  );

  /// Addresses for between 1 and [SyncFileLinksAnswer.maxItems] files. Every
  /// item is decided again against the account's rights now; a refused item
  /// rides the `200` beside the addresses given.
  Future<SyncFileLinksAnswer> fileLinks(
    List<SyncFileLinkRequest> items,
  ) async => SyncFileLinksAnswer.fromJson(
    await _http.postJson(SilexgisContract.fileLinksPath, <String, Object?>{
      'items': <Map<String, Object?>>[for (final item in items) item.toJson()],
    }),
  );

  /// The people directory: the cavers a phone user may be said to be, and the
  /// current link of every phone user this account has sent. Answered
  /// `409 sync.feature_disabled` while the installation has it switched off,
  /// and `403 access.forbidden` to an account that may not be told who people
  /// are; neither is a reason to retry.
  Future<SyncPeopleDirectory> people() async => SyncPeopleDirectory.fromJson(
    await _http.getJson(SilexgisContract.peoplePath),
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
