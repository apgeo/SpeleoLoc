import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/network/network_kind_probe.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_linker.dart';
import 'package:speleoloc/services/silexgis/silexgis_documents_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_staged_upload_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_stager.dart';
import 'package:speleoloc/services/silexgis/silexgis_files_network_gate.dart';
import 'package:speleoloc/services/silexgis/silexgis_documents_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_run.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_planner.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_links_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_document_updater.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_reader.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_people_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_review_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_link_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_session.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/app_logger.dart';

export 'package:speleoloc/services/silexgis/silexgis_session.dart'
    show SilexgisSession, SilexgisSessionBuilder;

/// Runs one sync against the configured server, and reports what happened.
///
/// **Nothing here is on any path the application needs.** With no profile
/// configured the controller is idle and every caller sees exactly what it
/// sees today; the local database stays the sole source of truth for the
/// running app whether a server exists or not.
class SilexgisSyncController extends ChangeNotifier {
  SilexgisSyncController({
    required AppDatabase db,
    required SilexgisProfileRepository profiles,
    required SilexgisLocalStateRepository localState,
    required SilexgisHeldRowRepository heldRows,
    required SilexgisPeopleRepository people,
    required SilexgisDocumentCatalogueRepository catalogue,
    required ChangeLogger logger,
    required ICaveRepository caves,
    required ICavePlaceRepository places,
    required SilexgisRefreshTokenStore tokens,
    SilexgisFileCopyRepository? copies,
    SilexgisServerLinkRepository? serverLinks,
    SilexgisStagedUploadRepository? staged,
    Future<Directory> Function() documentsDir =
        getApplicationDocumentsDirectory,
    NetworkKindProbe? networkProbe,
    SilexgisSessionBuilder? sessionBuilder,
  }) : _db = db,
       _profiles = profiles,
       _localState = localState,
       _heldRows = heldRows,
       _people = people,
       _catalogue = catalogue,
       _logger = logger,
       _caves = caves,
       _places = places,
       _tokens = tokens,
       _copies = copies ?? SilexgisFileCopyRepository(db),
       _serverLinks = serverLinks ?? SilexgisServerLinkRepository(db),
       _staged = staged ?? SilexgisStagedUploadRepository(db),
       _documentsDir = documentsDir,
       _networkProbe = networkProbe ?? const _UnknownNetwork(),
       _sessionBuilder = sessionBuilder;

  final AppDatabase _db;
  final SilexgisProfileRepository _profiles;
  final SilexgisLocalStateRepository _localState;
  final SilexgisHeldRowRepository _heldRows;
  final SilexgisPeopleRepository _people;
  final SilexgisDocumentCatalogueRepository _catalogue;
  final ChangeLogger _logger;
  final ICaveRepository _caves;
  final ICavePlaceRepository _places;
  final SilexgisRefreshTokenStore _tokens;
  final SilexgisFileCopyRepository _copies;
  final SilexgisServerLinkRepository _serverLinks;
  final SilexgisStagedUploadRepository _staged;

  /// The folder documentation files are stored relative to.
  final Future<Directory> Function() _documentsDir;

  /// Which network the run is on, for the profile's "only over Wi-Fi".
  final NetworkKindProbe _networkProbe;
  final SilexgisSessionBuilder? _sessionBuilder;
  final _log = AppLogger.of('SilexgisSyncController');

  SilexgisSyncProgress _progress = const SilexgisSyncProgress.idle();
  SilexgisSyncProgress get progress => _progress;
  bool get isRunning => _progress.isRunning;

  Completer<void>? _inFlight;

  /// Runs the default profile, if there is one.
  ///
  /// Safe to call while a run is in flight: the call is ignored and the
  /// existing run's completion is returned.
  ///
  /// [fromBeginning] drops the resume position first. A full read is always
  /// correct, and it is the only thing that picks up a row which became
  /// readable — being granted the right to place a cave writes nothing to that
  /// cave's row, so no incremental read will ever carry it.
  ///
  /// [decider] is asked, at most once, whether files may go over mobile data
  /// when the profile keeps them for Wi-Fi. Without one they wait.
  Future<void> syncDefault({
    bool fromBeginning = false,
    SilexgisMobileDataDecider? decider,
  }) async {
    if (isRunning) return _inFlight?.future;
    final profile = await _profiles.getDefaultProfile();
    if (profile == null) {
      // Not a failure. A server profile is exactly as optional as an FTP one.
      _log.info('no SilexGIS profile is configured; nothing to do');
      _emit(const SilexgisSyncProgress.idle());
      return;
    }
    return sync(profile, fromBeginning: fromBeginning, decider: decider);
  }

  Future<void> sync(
    SilexgisProfile profile, {
    bool fromBeginning = false,
    SilexgisMobileDataDecider? decider,
  }) async {
    if (isRunning) return _inFlight?.future;
    final setId = profile.syncSetId;
    if (setId == null || setId.isEmpty) {
      _fail(
        'Choose which caves this device carries before syncing.',
        action: SilexgisAction.surfaceToUser,
      );
      return;
    }

    final completer = _inFlight = Completer<void>();
    try {
      await _run(
        profile,
        setId,
        fromBeginning: fromBeginning,
        decider: decider,
      );
    } on SilexgisException catch (e) {
      _fail(e.message, action: e.action, code: _codeOf(e));
    } on Object catch (e, st) {
      _log.severe('the sync run failed', e, st);
      _fail('$e', action: SilexgisAction.retry);
    } finally {
      _inFlight = null;
      completer.complete();
    }
    return completer.future;
  }

  Future<void> _run(
    SilexgisProfile profile,
    String setId, {
    required bool fromBeginning,
    SilexgisMobileDataDecider? decider,
  }) async {
    final session = (_sessionBuilder ?? _defaultSession)(profile);

    _emit(
      _progress.copyWith(
        phase: SilexgisSyncPhase.authenticating,
        message: 'Signing in to ${profile.displayName}',
        unavailable: const <SilexgisUnavailablePart>[],
      ),
    );
    if (!await session.auth.restore()) {
      // A lapsed session is a reason to ask for a password, never a reason to
      // discard or re-download anything: the local database is the source of
      // truth for everything this device holds.
      _fail(
        'Sign in to ${profile.displayName} again.',
        action: SilexgisAction.reAuth,
      );
      return;
    }

    _emit(_progress.copyWith(phase: SilexgisSyncPhase.askingCapabilities));
    final capabilities = await session.api.capabilities();
    if (!capabilities.speaksOurContract) {
      _fail(
        'This installation speaks version ${capabilities.contractVersion} of '
        'the sync protocol and this application speaks '
        '${SilexgisContract.version}. One of them needs updating.',
        action: SilexgisAction.stop,
        code: SilexgisCodes.contractUnsupported,
      );
      return;
    }

    final applier = SilexgisDownloadApplier(
      db: _db,
      logger: _logger,
      localState: _localState,
      heldRows: _heldRows,
      caves: _caves,
      places: _places,
      profileUuid: profile.profileUuid,
    );

    // The write goes first, and the order matters twice over. A row the caver
    // removed here is gone from this database, so a read that ran first would
    // simply put it back — the removal would be undone by the very run meant
    // to carry it. And an edit that loses a conflict is answered with the
    // server's own row while the device still holds its own version, which is
    // what lets the caver see both.
    //
    // So any whole refusal of the write stops the run, rather than only the
    // write: a read after an unsent removal would undo it.
    if (capabilities.servesUpload) {
      _emit(_progress.copyWith(phase: SilexgisSyncPhase.uploading));
      final documents = SilexgisDocumentUploadRun();
      final SilexgisUploadReport report;
      try {
        report = await SilexgisUploadRunner(
          api: session.api,
          builder: SilexgisUploadBuilder(
            db: _db,
            localState: _localState,
            heldRows: _heldRows,
            profileUuid: profile.profileUuid,
            uploadsNewRoots: profile.uploadsNewRoots,
          ),
          localState: _localState,
          heldRows: _heldRows,
          profileUuid: profile.profileUuid,
          parts: <SilexgisUploadPart>[
            if (capabilities.servesPeople)
              SilexgisPeopleUploadPart(
                db: _db,
                people: _people,
                profileUuid: profile.profileUuid,
              ),
            if (capabilities.servesDocumentUpload && profile.sendsFiles)
              ..._documentParts(profile, session, documents, decider),
          ],
        ).run(setId, capabilities: capabilities);
      } on SilexgisProblemException catch (e) {
        if (e.code != SilexgisCodes.clientUpdateRequired) rethrow;
        _fail(
          'Uploads from this account wait for a reviewer on '
          '${profile.displayName}, and this version of the app cannot send '
          'them for review. Update the app to sync. Nothing was sent, and '
          'nothing on this device was changed.',
          action: SilexgisAction.stop,
          code: e.code,
        );
        return;
      }

      _emit(
        _progress.copyWith(
          rowsSent: report.written,
          upload: report,
          files: documents.files,
        ),
      );
    }

    if (capabilities.servesDownload) {
      await _readPart('the caves and places', () async {
        _emit(_progress.copyWith(phase: SilexgisSyncPhase.downloading));
        final report = await SilexgisDownloadRunner(
          api: session.api,
          applier: applier,
          localState: _localState,
          profileUuid: profile.profileUuid,
        ).run(setId, capabilities: capabilities, fromBeginning: fromBeginning);

        _emit(
          _progress.copyWith(
            pagesRead: report.pages,
            rowsApplied: report.applied.inserted + report.applied.updated,
            rowsDeleted: report.applied.deleted,
            download: report,
          ),
        );
      });
    }

    if (capabilities.servesPeople) {
      await _readPart(
        'the people directory',
        () => SilexgisPeopleReader(
          db: _db,
          api: session.api,
          people: _people,
          profileUuid: profile.profileUuid,
        ).run(),
        offCodes: SilexgisPeopleReader.offCodes,
      );
    } else {
      // Not offered this run, so no caver is offered a choice from it.
      await _people.clearDirectory(profile.profileUuid);
    }

    if (capabilities.servesDocuments) {
      await _readPart('the photo and document catalogue', () async {
        await SilexgisDocumentsRunner(
          db: _db,
          api: session.api,
          localState: _localState,
          catalogue: _catalogue,
          heldDocuments: SilexgisHeldDocumentUpdater(
            db: _db,
            logger: _logger,
            localState: _localState,
            profileUuid: profile.profileUuid,
          ),
          linker: SilexgisDocumentLinker(
            db: _db,
            logger: _logger,
            catalogue: _catalogue,
            copies: _copies,
            serverLinks: _serverLinks,
            profileUuid: profile.profileUuid,
          ),
          profileUuid: profile.profileUuid,
        ).run(setId, capabilities: capabilities, fromBeginning: fromBeginning);
      });
    } else {
      // Not offered this run, so nothing is offered to fetch from it.
      await _catalogue.clear(profile.profileUuid);
    }

    // Last, so that an accepted revision lands on rows already here.
    if (capabilities.servesReviews) {
      await _readPart('the review decisions', () async {
        await SilexgisReviewRunner(
          db: _db,
          api: session.api,
          localState: _localState,
          heldRows: _heldRows,
          profileUuid: profile.profileUuid,
        ).run(setId, capabilities: capabilities, fromBeginning: fromBeginning);
      });
    }

    final reviews = await _heldRows.counts(profile.profileUuid);
    _emit(
      _progress.copyWith(
        phase: SilexgisSyncPhase.completed,
        reviews: reviews,
        message: _summary(reviews),
      ),
    );
  }

  /// The two document sections, sharing one plan: `documents` first, so a
  /// link waits with a document whose bytes wait.
  List<SilexgisUploadPart> _documentParts(
    SilexgisProfile profile,
    SilexgisSession session,
    SilexgisDocumentUploadRun run,
    SilexgisMobileDataDecider? decider,
  ) => <SilexgisUploadPart>[
    SilexgisDocumentsUploadPart(
      planner: SilexgisDocumentUploadPlanner(
        db: _db,
        localState: _localState,
        heldRows: _heldRows,
        copies: _copies,
        staged: _staged,
        catalogue: _catalogue,
        serverLinks: _serverLinks,
        profileUuid: profile.profileUuid,
      ),
      run: run,
      stager: SilexgisFileStager(
        api: session.transfers,
        staged: _staged,
        profileUuid: profile.profileUuid,
      ),
      gate: SilexgisFilesNetworkGate(
        profile: profile,
        profiles: _profiles,
        probe: _networkProbe,
        decider: decider,
      ),
      staged: _staged,
      localState: _localState,
      heldRows: _heldRows,
      baseDir: _documentsDir,
      profileUuid: profile.profileUuid,
    ),
    SilexgisDocumentLinksUploadPart(
      run: run,
      serverLinks: _serverLinks,
      heldRows: _heldRows,
      profileUuid: profile.profileUuid,
    ),
  ];

  /// Runs one read part of a run.
  ///
  /// A part the installation answers as switched off stops on its own and the
  /// run goes on with the rest: `features` is worked out per request, so a
  /// part named at the start of a run can be gone by the time it is read. The
  /// next run asks the capabilities again.
  Future<void> _readPart(
    String part,
    Future<void> Function() read, {
    Set<String> offCodes = const <String>{SilexgisCodes.featureDisabled},
  }) async {
    try {
      await read();
    } on SilexgisProblemException catch (e) {
      if (!offCodes.contains(e.code)) rethrow;
      _log.info('$part is switched off on this installation (${e.code})');
      _emit(
        _progress.copyWith(
          unavailable: <SilexgisUnavailablePart>[
            ..._progress.unavailable,
            SilexgisUnavailablePart(part: part, detail: e.problem.detail),
          ],
        ),
      );
    }
  }

  SilexgisSession _defaultSession(SilexgisProfile profile) =>
      SilexgisSession.signedIn(profile, _tokens);

  String _summary(SilexgisReviewCounts reviews) {
    final parts = <String>[
      if (_progress.rowsApplied > 0) '${_progress.rowsApplied} received',
      if (_progress.rowsDeleted > 0) '${_progress.rowsDeleted} removed',
      if (_progress.rowsSent > 0) '${_progress.rowsSent} sent',
      if (reviews.waiting > 0) '${reviews.waiting} waiting for review',
    ];
    final summary = parts.isEmpty
        ? 'Already level with the server.'
        : parts.join(', ');
    if (_progress.unavailable.isEmpty) return summary;
    final off = _progress.unavailable.map((u) => u.part).join(', ');
    return '$summary The server does not offer $off at the moment.';
  }

  static String? _codeOf(SilexgisException e) => switch (e) {
    SilexgisProblemException() => e.code,
    SilexgisAuthException() => e.code,
    _ => null,
  };

  void _fail(String message, {required SilexgisAction action, String? code}) {
    _emit(
      _progress.copyWith(
        phase: SilexgisSyncPhase.failed,
        message: message,
        action: action,
        code: code,
      ),
    );
  }

  void _emit(SilexgisSyncProgress progress) {
    _progress = progress;
    notifyListeners();
  }
}

/// A network nothing could be asked about: treated as one that may cost.
class _UnknownNetwork implements NetworkKindProbe {
  const _UnknownNetwork();

  @override
  Future<NetworkKind> current() async => NetworkKind.unknown;
}
