import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_stream.dart';
import 'package:speleoloc/services/silexgis/model/sync_trips.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_paged_stream_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_applier.dart';

/// What reading the trips stream did.
class SilexgisTripsReport {
  const SilexgisTripsReport({
    required this.pages,
    required this.restarted,
    this.applied = const SilexgisTripsApplied(),
  });

  final int pages;
  final bool restarted;
  final SilexgisTripsApplied applied;
}

/// Reads the trip recordings, with their scans, on the trips stream's own
/// cursor. Run after the features, so a recording finds its cave and a scan
/// its place.
class SilexgisTripsRunner {
  SilexgisTripsRunner({
    required SilexgisSyncApi api,
    required SilexgisLocalStateRepository localState,
    required SilexgisTripApplier applier,
    required String profileUuid,
  }) : _api = api,
       _localState = localState,
       _applier = applier,
       _profileUuid = profileUuid;

  final SilexgisSyncApi _api;
  final SilexgisLocalStateRepository _localState;
  final SilexgisTripApplier _applier;
  final String _profileUuid;

  static const int preferredPageSize = 100;

  Future<SilexgisTripsReport> run(
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
      stream: SyncStream.trips,
    );

    var applied = const SilexgisTripsApplied();
    final read = await SilexgisPagedStreamRunner<SyncTripsPage>(
      name: 'trips',
      cursors: cursors,
      fetch: (cursor) => _api.trips(
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

    return SilexgisTripsReport(
      pages: read.pages,
      restarted: read.restarted,
      applied: applied,
    );
  }
}
