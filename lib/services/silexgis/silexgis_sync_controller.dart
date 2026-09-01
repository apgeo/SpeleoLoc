import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_applier.dart';
import 'package:speleoloc/services/silexgis/silexgis_download_runner.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Builds the per-installation pieces of a run.
///
/// Injected so a test can drive a whole run against a scripted server without
/// a socket, and so the controller itself never learns how a sign-in works.
typedef SilexgisSessionBuilder =
    SilexgisSession Function(SilexgisProfile profile);

/// One installation's client, assembled.
class SilexgisSession {
  const SilexgisSession({required this.auth, required this.api});

  final SilexgisAuthService auth;
  final SilexgisSyncApi api;
}

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
    required ChangeLogger logger,
    required ICaveRepository caves,
    required ICavePlaceRepository places,
    required SilexgisRefreshTokenStore tokens,
    SilexgisSessionBuilder? sessionBuilder,
  }) : _db = db,
       _profiles = profiles,
       _localState = localState,
       _logger = logger,
       _caves = caves,
       _places = places,
       _tokens = tokens,
       _sessionBuilder = sessionBuilder;

  final AppDatabase _db;
  final SilexgisProfileRepository _profiles;
  final SilexgisLocalStateRepository _localState;
  final ChangeLogger _logger;
  final ICaveRepository _caves;
  final ICavePlaceRepository _places;
  final SilexgisRefreshTokenStore _tokens;
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
  Future<void> syncDefault({bool fromBeginning = false}) async {
    if (isRunning) return _inFlight?.future;
    final profile = await _profiles.getDefaultProfile();
    if (profile == null) {
      // Not a failure. A server profile is exactly as optional as an FTP one.
      _log.info('no SilexGIS profile is configured; nothing to do');
      _emit(const SilexgisSyncProgress.idle());
      return;
    }
    return sync(profile, fromBeginning: fromBeginning);
  }

  Future<void> sync(
    SilexgisProfile profile, {
    bool fromBeginning = false,
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
      await _run(profile, setId, fromBeginning: fromBeginning);
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
  }) async {
    final session = (_sessionBuilder ?? _defaultSession)(profile);

    _emit(
      _progress.copyWith(
        phase: SilexgisSyncPhase.authenticating,
        message: 'Signing in to ${profile.displayName}',
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
      caves: _caves,
      places: _places,
      profileUuid: profile.profileUuid,
    );

    if (capabilities.servesDownload) {
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
    }

    if (capabilities.servesUpload) {
      _emit(_progress.copyWith(phase: SilexgisSyncPhase.uploading));
      final report = await SilexgisUploadRunner(
        api: session.api,
        builder: SilexgisUploadBuilder(
          db: _db,
          localState: _localState,
          profileUuid: profile.profileUuid,
        ),
        localState: _localState,
        profileUuid: profile.profileUuid,
      ).run(setId, capabilities: capabilities);

      _emit(_progress.copyWith(rowsSent: report.written, upload: report));
    }

    _emit(
      _progress.copyWith(
        phase: SilexgisSyncPhase.completed,
        message: _summary(),
      ),
    );
  }

  SilexgisSession _defaultSession(SilexgisProfile profile) {
    final auth = SilexgisAuthService(
      baseUri: profile.baseUri,
      profileUuid: profile.profileUuid,
      store: _tokens,
    );
    return SilexgisSession(
      auth: auth,
      api: SilexgisSyncApi(
        SilexgisHttp(baseUri: profile.baseUri, tokens: auth),
      ),
    );
  }

  String _summary() {
    final parts = <String>[
      if (_progress.rowsApplied > 0) '${_progress.rowsApplied} received',
      if (_progress.rowsDeleted > 0) '${_progress.rowsDeleted} removed',
      if (_progress.rowsSent > 0) '${_progress.rowsSent} sent',
    ];
    if (parts.isEmpty) return 'Already level with the server.';
    return parts.join(', ');
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
