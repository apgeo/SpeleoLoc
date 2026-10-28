import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_rasters.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_run.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_sending_gate.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_stager.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_row_composer.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_raster_upload_answers.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// The `rasterMaps` section: the raster maps this run creates, edits or
/// removes.
///
/// A map goes up by the rule the feature rows follow: when its cave is on the
/// installation or goes in the same run. One the installation holds goes again
/// only once it changed here, and one held for a reviewer only once the caver
/// edits it again.
///
/// **A picture goes only when it is the caver's.** A new map brings its
/// picture's bytes, staged first; an edit brings them only when the local
/// picture is not the one that stands for the installation's — the bytes this
/// device fetched or sent. So a picture handed down without its location data
/// is never sent back as if it were new. Bytes go only while the caver lets
/// files go ([filesAllowed]) and the network gate agrees; a map that needs
/// them and may not have them waits whole, and its pins with it.
class SilexgisRasterMapsUploadPart implements SilexgisUploadPart {
  SilexgisRasterMapsUploadPart({
    required AppDatabase db,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisRasterStateRepository rasters,
    required SilexgisRasterUploadAnswers answers,
    required SilexgisFileStager stager,
    required SilexgisFileSendingGate gate,
    required Future<Directory> Function() baseDir,
    required String profileUuid,
    required bool filesAllowed,
    SilexgisRasterRowComposer composer = const SilexgisRasterRowComposer(),
  }) : _db = db,
       _localState = localState,
       _heldRows = heldRows,
       _rasters = rasters,
       _answers = answers,
       _stager = stager,
       _gate = gate,
       _baseDir = baseDir,
       _profileUuid = profileUuid,
       _filesAllowed = filesAllowed,
       _composer = composer;

  final AppDatabase _db;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisRasterStateRepository _rasters;
  final SilexgisRasterUploadAnswers _answers;
  final SilexgisFileStager _stager;
  final SilexgisFileSendingGate _gate;
  final Future<Directory> Function() _baseDir;
  final String _profileUuid;
  final bool _filesAllowed;
  final SilexgisRasterRowComposer _composer;
  final _log = AppLogger.of('SilexgisRasterMapsUploadPart');

  final Map<String, SilexgisPlannedRasterItem> _planned =
      <String, SilexgisPlannedRasterItem>{};
  final Map<String, SilexgisStageRequest> _requests =
      <String, SilexgisStageRequest>{};

  /// What became of the pictures this run meant to send.
  SilexgisFilesReport get files => _files;
  SilexgisFilesReport _files = const SilexgisFilesReport();

  @override
  SyncUploadSection get section => SyncUploadSection.rasterMaps;

  @override
  Future<List<SyncUploadItem>> build(SilexgisUploadContext context) async {
    final revisions = await _localState.readRevisions(_profileUuid);
    final held = await _heldRows.readSection(_profileUuid, section);
    final states = await _rasters.readAll(_profileUuid);
    final caves = <Uuid>{
      for (final e in revisions.entries)
        if (e.value.entityTable == 'caves') e.key,
      ...context.rowsSent,
    };

    final due = <_DueMap>[];
    final present = <Uuid>{};
    var missing = 0;
    Directory? base;
    for (final map in await _db.select(_db.rasterMaps).get()) {
      present.add(map.uuid);
      final stored = _mapRevision(revisions[map.uuid]);
      if (stored == null && !caves.contains(map.caveUuid)) continue;
      if (stored != null && stored.agreesWith(map.updatedAt)) continue;
      if (held[map.uuid]?.stillAsSent(map.updatedAt) ?? false) continue;

      base ??= await _baseDir();
      final file = File('${base.path}/${map.fileName}');
      final state = states[map.uuid];
      if (!await file.exists()) {
        if (stored == null) {
          // A new map is its picture; without one there is nothing to send.
          _log.warning('a map picture to send is no longer on this device');
          missing++;
          continue;
        }
        // Still to fetch, or gone: the installation's picture stands.
        due.add(
          _DueMap(
            map,
            stored,
            state,
            SilexgisRasterPicture(sha256: state?.pictureSha256),
          ),
        );
        continue;
      }
      final picture = SilexgisRasterPicture(
        sha256: (await sha256.bind(file.openRead()).first).toString(),
        sizeBytes: await file.length(),
      );
      final ownBytes = stored == null || picture.sha256 != state?.pictureSha256;
      if (ownBytes) {
        _requests[map.uuid.toString()] = SilexgisStageRequest(
          documentUuid: map.uuid,
          file: file,
          fileName: SilexgisRasterRowComposer.fileNameOf(map.fileName),
          sha256: picture.sha256!,
          sizeBytes: picture.sizeBytes!,
        );
      }
      due.add(_DueMap(map, stored, state, picture, sendsBytes: ownBytes));
    }

    final kept = <Uuid>{};
    final needBytes = due.where((d) => d.sendsBytes).toList();
    var waiting = 0;
    if (needBytes.isNotEmpty &&
        (!_filesAllowed ||
            !await _gate.mayFilesGo(
              files: needBytes.length,
              bytes: needBytes.fold(
                0,
                (sum, d) => sum + (d.picture.sizeBytes ?? 0),
              ),
            ))) {
      if (_filesAllowed) waiting = needBytes.length;
      kept.addAll(needBytes.map((d) => d.map.uuid));
      needBytes.clear();
    }

    final transfers = <Uuid, String>{};
    var stagedCount = 0;
    var quota = 0;
    var tooLarge = 0;
    var typeRefused = 0;
    var failed = 0;
    for (final pending in needBytes) {
      final result = await _stager.stage(
        _requests[pending.map.uuid.toString()]!,
      );
      switch (result.outcome) {
        case SilexgisStageOutcome.staged:
          stagedCount++;
          transfers[pending.map.uuid] = result.transferId!;
          continue;
        case SilexgisStageOutcome.quotaExceeded:
          quota++;
        case SilexgisStageOutcome.tooLarge:
          tooLarge++;
        case SilexgisStageOutcome.typeRefused:
          typeRefused++;
        case SilexgisStageOutcome.forbidden:
        case SilexgisStageOutcome.hashMismatch:
        case SilexgisStageOutcome.interrupted:
          failed++;
      }
      kept.add(pending.map.uuid);
    }
    _files = SilexgisFilesReport(
      staged: stagedCount,
      waitingForNetwork: waiting,
      quotaExceeded: quota,
      tooLarge: tooLarge,
      typeRefused: typeRefused,
      missing: missing,
      failed: failed,
    );

    final items = <SyncUploadItem>[];
    for (final pending in due) {
      final map = pending.map;
      if (kept.contains(map.uuid)) continue;
      final transferId = transfers[map.uuid];
      final item = _composer.map(
        map,
        picture: pending.picture,
        baseRevision: pending.stored?.revision,
        stagedUploadId: transferId,
        areaId: pending.state?.areaId,
      );
      _planned[item.id] = SilexgisPlannedRasterItem(
        id: map.uuid,
        mapId: map.uuid,
        isPin: false,
        localUpdatedAt: map.updatedAt,
        pictureSha256: transferId == null ? null : pending.picture.sha256,
        transferId: transferId,
      );
      context.rasterMapsSent.add(map.uuid);
      items.add(item);
    }

    for (final entry in revisions.entries) {
      final stored = _mapRevision(entry.value);
      if (stored == null || present.contains(entry.key)) continue;
      // A removal is never edited again, so a held one waits for its decision.
      if (held[entry.key]?.isDelete ?? false) continue;
      final item = SyncUploadRasterMap.delete(
        id: entry.key.toString(),
        baseRevision: stored.revision,
      );
      _planned[item.id] = SilexgisPlannedRasterItem(
        id: entry.key,
        mapId: entry.key,
        isPin: false,
        isDelete: true,
      );
      items.add(item);
    }
    return items;
  }

  @override
  Future<SilexgisPartAnswers> apply(
    List<SyncUploadItem> sent,
    List<SyncRowResult> answers, {
    required bool resent,
  }) async {
    final byId = <String, SyncUploadRasterMap>{
      for (final item in sent.whereType<SyncUploadRasterMap>()) item.id: item,
    };
    final resend = <SyncUploadItem>[];
    final rest = <SyncRowResult>[];
    for (final answer in answers) {
      final item = byId[answer.id];
      final bytesLost =
          answer.status == SyncRowStatus.rejected &&
          (answer.code == SilexgisCodes.fileBytesMissing ||
              answer.code == SilexgisCodes.fileHashMismatch);
      if (!resent && bytesLost && item != null) {
        final again = await _restage(item);
        if (again != null) {
          resend.add(again);
          continue;
        }
      }
      rest.add(answer);
    }
    final stored = await _answers.apply(section, _planned, rest);
    return SilexgisPartAnswers(
      refusals: stored.refusals,
      resend: resend,
      held: stored.held,
    );
  }

  /// The map again, naming freshly staged bytes, or null when they could not
  /// be staged or the map brought none.
  Future<SyncUploadRasterMap?> _restage(SyncUploadRasterMap item) async {
    final request = _requests[item.id];
    final planned = _planned[item.id];
    if (request == null || planned == null) return null;
    await _stager.forget(request.documentUuid);
    final result = await _stager.stage(request);
    if (!result.isStaged) return null;
    _planned[item.id] = planned.withTransfer(result.transferId!);
    return item.withStagedUpload(result.transferId!);
  }

  static StoredRevision? _mapRevision(StoredRevision? stored) =>
      stored?.entityTable == SilexgisRasterTables.maps ? stored : null;
}

/// A map due to go up, before its bytes are decided.
class _DueMap {
  const _DueMap(
    this.map,
    this.stored,
    this.state,
    this.picture, {
    this.sendsBytes = false,
  });

  final RasterMap map;
  final StoredRevision? stored;
  final SilexgisRasterState? state;
  final SilexgisRasterPicture picture;

  /// The local picture is the caver's, not the installation's.
  final bool sendsBytes;
}
