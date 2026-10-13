import 'dart:io';

import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_document_import_service.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// One decided media item: which place it was taken at and when.
class TripMediaCommit {
  const TripMediaCommit({
    required this.item,
    required this.cavePlaceUuid,
    required this.at,
    this.file,
  });

  final TripMediaItem item;
  final Uuid cavePlaceUuid;
  final DateTime at;

  /// The item's bytes, already materialised by the caller. Null means "add
  /// the track point but do not store the media".
  final File? file;
}

/// Counts and warnings from one application of a media import.
class TripMediaImportOutcome {
  int pointsAdded = 0;
  int pointsDuplicate = 0;
  int pointsFailed = 0;
  int pointsDeleted = 0;
  int filesImported = 0;
  int filesDuplicate = 0;
  int filesFailed = 0;
  bool tripWindowChanged = false;

  final List<String> warnings = [];
}

/// Turns the decisions made on the trip-media screen into trip points,
/// stored documents and the links between them.
///
/// UI-free: the screen resolves places, times and files and decides which
/// conflicts to accept; this applies the result. Ordering is the part that
/// matters — superseded points go before new ones so a replacement at the
/// same place and moment does not collide with the row it replaces, and the
/// trip window moves last so the regenerated log reflects the final shape.
class TripMediaImportService {
  TripMediaImportService(
    this._db,
    this._tripService,
    this._docImport,
    this._logger,
    this._currentUser,
  );

  final AppDatabase _db;
  final CaveTripService _tripService;
  final CaveDocumentImportService _docImport;
  final ChangeLogger _logger;
  final CurrentUserService _currentUser;
  final _log = AppLogger.of('TripMediaImportService');

  /// Applies [commits] to [tripUuid].
  ///
  /// [deletePointUuids] are pre-existing points the user agreed to drop.
  /// [newTripStart] / [newTripEnd] move the trip's window when the user
  /// accepted the entrance-marker proposals. [onProgress] fires once per
  /// processed commit so a 200-item run can show where it is.
  Future<TripMediaImportOutcome> apply({
    required Uuid tripUuid,
    required List<TripMediaCommit> commits,
    required bool importFiles,
    required bool compressImages,
    List<Uuid> deletePointUuids = const [],
    DateTime? newTripStart,
    DateTime? newTripEnd,
    void Function(int done, int total)? onProgress,
  }) async {
    final outcome = TripMediaImportOutcome();

    for (final uuid in deletePointUuids) {
      try {
        await _tripService.deletePoint(uuid);
        outcome.pointsDeleted++;
      } catch (e, st) {
        _log.warning('could not delete superseded point $uuid', e, st);
        outcome.warnings.add('point_delete_failed');
      }
    }

    // Point uuid per commit, keyed by the item id, so the file pass can bind
    // each stored document to the point its picture produced.
    final pointByItem = <String, Uuid>{};
    var done = 0;
    for (final commit in commits) {
      try {
        final pointUuid = await _tripService.addPointAt(
          tripUuid: tripUuid,
          cavePlaceUuid: commit.cavePlaceUuid,
          at: commit.at,
        );
        pointByItem[commit.item.id] = pointUuid;
        outcome.pointsAdded++;
      } on DuplicateEntryException {
        // The trip already records this place at this exact moment — the
        // point the user wanted is already there, so this is a no-op, not a
        // failure. The picture still gets bound to the existing point.
        final existing = await _findPointAt(
          tripUuid,
          commit.cavePlaceUuid,
          commit.at,
        );
        if (existing != null) pointByItem[commit.item.id] = existing;
        outcome.pointsDuplicate++;
      } catch (e, st) {
        _log.warning('could not add point for ${commit.item.id}', e, st);
        outcome.pointsFailed++;
      } finally {
        onProgress?.call(++done, commits.length);
      }
    }

    if (importFiles) {
      await _importFiles(commits, pointByItem, compressImages, outcome);
    }

    if (newTripStart != null || newTripEnd != null) {
      try {
        await _tripService.updateTripWindow(
          tripUuid,
          startedAt: newTripStart,
          endedAt: newTripEnd,
        );
        outcome.tripWindowChanged = true;
      } catch (e, st) {
        _log.warning('could not move the trip window', e, st);
        outcome.warnings.add('trip_window_failed');
      }
    }

    return outcome;
  }

  /// Stores the media and links it to both its cave place and its track
  /// point. Grouped per place so the importer's duplicate check runs once
  /// per place rather than once per file.
  Future<void> _importFiles(
    List<TripMediaCommit> commits,
    Map<String, Uuid> pointByItem,
    bool compressImages,
    TripMediaImportOutcome outcome,
  ) async {
    final byPlace = <Uuid, List<TripMediaCommit>>{};
    for (final c in commits) {
      if (c.file == null) continue;
      byPlace.putIfAbsent(c.cavePlaceUuid, () => []).add(c);
    }

    for (final entry in byPlace.entries) {
      final group = entry.value;
      final CaveDirImportOutcome result;
      try {
        result = await _docImport.importFilesToGeofeature(
          link: DocumentationGeofeatureLink(
            type: GeofeatureType.cavePlace,
            geofeatureUuid: entry.key,
          ),
          files: [for (final c in group) c.file!],
          compressImages: compressImages,
        );
      } catch (e, st) {
        _log.warning('media import failed for place ${entry.key}', e, st);
        outcome.filesFailed += group.length;
        outcome.warnings.add('media_import_failed');
        continue;
      }

      outcome.filesImported += result.imported;
      outcome.filesDuplicate += result.skippedDuplicates;
      outcome.filesFailed += result.failed;

      final commitByPath = {for (final c in group) c.file!.path: c};
      for (final file in result.files) {
        final docUuid = file.documentUuid;
        final commit = commitByPath[file.sourcePath];
        if (docUuid == null || commit == null) continue;
        final pointUuid = pointByItem[commit.item.id];
        if (pointUuid == null) continue;
        await _bindToPoint(docUuid, pointUuid);
      }
    }
  }

  Future<void> _bindToPoint(Uuid docUuid, Uuid pointUuid) async {
    try {
      final author = await _currentUser.currentOrSystem();
      final existing = await _db.getTripPointDocumentLinks(pointUuid);
      final already = existing.any((l) => l.documentationFileUuid == docUuid);
      final linkUuid = await _db.linkDocumentToTripPoint(
        docUuid,
        pointUuid,
        authorUuid: author,
      );
      // linkDocumentToTripPoint is an upsert, so only a link that did not
      // exist gets a change-log entry; logging an unchanged row would put a
      // phantom insert in front of the sync upload gate.
      if (!already) {
        await _logger.logInsert(
          'documentation_files_to_cave_trip_points',
          linkUuid,
        );
      }
    } catch (e, st) {
      _log.warning('could not bind doc $docUuid to point $pointUuid', e, st);
    }
  }

  Future<Uuid?> _findPointAt(Uuid tripUuid, Uuid placeUuid, DateTime at) async {
    final points = await _db.getTripPoints(tripUuid);
    for (final p in points) {
      if (p.cavePlaceUuid == placeUuid &&
          p.scannedAt == at.millisecondsSinceEpoch) {
        return p.uuid;
      }
    }
    return null;
  }
}
