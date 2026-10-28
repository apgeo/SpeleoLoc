import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_rasters.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_paged_stream_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_picture_fetcher.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';

/// What reading the rasters stream did.
class SilexgisRastersReport {
  const SilexgisRastersReport({
    required this.pages,
    required this.restarted,
    this.applied = const SilexgisRastersApplied(),
    this.pictures = const SilexgisMapPicturesReport(),
  });

  final int pages;
  final bool restarted;
  final SilexgisRastersApplied applied;
  final SilexgisMapPicturesReport pictures;
}

/// Reads the raster maps, with their pins, on the rasters stream's own
/// cursor, then fetches the pictures the maps still lack. Run after the
/// features, so a map finds its cave and a pin its place, and after the
/// documents catalogue, which says what each picture is.
class SilexgisRastersRunner {
  SilexgisRastersRunner({
    required SilexgisSyncApi api,
    required SilexgisLocalStateRepository localState,
    required SilexgisRasterApplier applier,
    required String profileUuid,
    SilexgisRasterPictureFetcher? pictures,
  }) : _api = api,
       _localState = localState,
       _applier = applier,
       _profileUuid = profileUuid,
       _pictures = pictures;

  final SilexgisSyncApi _api;
  final SilexgisLocalStateRepository _localState;
  final SilexgisRasterApplier _applier;
  final String _profileUuid;

  /// Null when the installation hands out no files this run: the maps are
  /// read, and their pictures wait for a run that may fetch them.
  final SilexgisRasterPictureFetcher? _pictures;

  static const int preferredPageSize = 100;

  Future<SilexgisRastersReport> run(
    String setId, {
    required SilexgisCapabilities capabilities,
    bool fromBeginning = false,
  }) async {
    final pageSize = capabilities.pageSizeMax < preferredPageSize
        ? capabilities.pageSizeMax
        : preferredPageSize;
    final cursors = SilexgisStreamCursorStore(
      localState: _localState,
      profileUuid: _profileUuid,
      setId: setId,
      stream: SyncStream.rasters,
    );

    var applied = const SilexgisRastersApplied();
    final read = await SilexgisPagedStreamRunner<SyncRastersPage>(
      name: 'rasters',
      cursors: cursors,
      fetch: (cursor) => _api.rasters(
        setId,
        cursor: cursor,
        pageSize: pageSize > 0 ? pageSize : null,
      ),
      apply: (page) async {
        applied = applied.plus(
          await _applier.applyPage(page, afterwards: () => cursors.write(page)),
        );
      },
    ).run(fromBeginning: fromBeginning);

    return SilexgisRastersReport(
      pages: read.pages,
      restarted: read.restarted,
      applied: applied,
      pictures:
          await _pictures?.fetchPending() ?? const SilexgisMapPicturesReport(),
    );
  }
}
