import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/scanner_page.dart';
import 'package:speleoloc/screens/settings/settings_general_page.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/qr_code_lookup_service.dart';
import 'package:speleoloc/services/qr_scan_service.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// What to do when a QR code matches places in multiple caves.
enum QrAmbiguityPolicy {
  /// Show a disambiguation dialog letting the user pick (default).
  dialog,

  /// Silently open the match from the last-opened cave (or the first
  /// match if none of them is from the last-opened cave).
  preferLastOpenCave,
}

/// Source that initiated a scan/lookup. Used to read the appropriate
/// ambiguity policy from settings.
enum QrLookupSource {
  /// Scan via the camera scanner or from app menus (settings key:
  /// [qrScanAmbiguityPolicyKey]).
  scan,

  /// Lookup initiated by a deep link (sp://...) (settings key:
  /// [deepLinkAmbiguityPolicyKey]).
  deepLink,
}

/// Load the configured [QrAmbiguityPolicy] for the given [source].
Future<QrAmbiguityPolicy> loadQrAmbiguityPolicy(QrLookupSource source) async {
  final key = source == QrLookupSource.scan
      ? qrScanAmbiguityPolicyKey
      : deepLinkAmbiguityPolicyKey;
  final raw = await SettingsHelper.loadStringConfig(key, ambiguityPolicyDialog);
  return raw == ambiguityPolicyPreferLastCave
      ? QrAmbiguityPolicy.preferLastOpenCave
      : QrAmbiguityPolicy.dialog;
}

/// Canonical handler for QR code lookups across the app.
///
/// Single entry point for: camera scans (HomePage, AppBarMenu,
/// CavePlacesListPage), manual text input dialogs, and deep links.
/// Centralises payload preprocessing, ambiguity resolution, entrance
/// detection (start/stop trip prompts), trip-point recording, and
/// navigation to the matching place.
class QrCodeLookupHandler {
  final QrCodeLookupService _service;

  QrCodeLookupHandler(this._service);

  /// Default-configured handler using the global [appDatabase].
  factory QrCodeLookupHandler.defaultInstance() =>
      QrCodeLookupHandler(QrCodeLookupService(appDatabase));

  /// Process [rawCode] end-to-end: preprocess payload, lookup, resolve
  /// ambiguity, handle entrance prompts, record trip point, navigate.
  ///
  /// * [currentCaveId] — when provided, the lookup is scoped to that cave
  ///   (no cross-cave matches possible, so no disambiguation dialog).
  /// * [ambiguityPolicy] — applied only when [currentCaveId] is null and
  ///   multiple matches are found.
  /// * [preprocessPayload] — when true (default), [rawCode] is run through
  ///   [qrScanService.process] (idempotent for already-processed codes,
  ///   strips URLs / sp:// prefixes).
  ///
  /// Returns the [CavePlace] that was opened, or `null` if no match was
  /// found or the user cancelled.
  Future<CavePlace?> handleScannedCode(
    BuildContext context,
    String rawCode, {
    Uuid? currentCaveId,
    QrAmbiguityPolicy ambiguityPolicy = QrAmbiguityPolicy.dialog,
    bool preprocessPayload = true,
  }) async {
    String code = rawCode.trim();
    if (preprocessPayload && code.isNotEmpty) {
      code = qrScanService
          .process(code, config: await QrScanConfig.load())
          .qcri;
    }
    if (code.isEmpty) {
      SnackBarService.showWarning(
          '${LocServ.inst.t('invalid_qr_code_detail')}: \'$rawCode\'');
      return null;
    }

    final results = await _service.lookup(code, currentCaveId: currentCaveId);

    if (results.isEmpty) {
      SnackBarService.showWarning(
          '${LocServ.inst.t('cave_place_not_found')}: \'$rawCode\'');
      return null;
    }

    QrLookupResult selected;
    if (results.length == 1 || currentCaveId != null) {
      // Single match, or cave-scoped lookup (cannot be ambiguous across caves).
      selected = results.first;
    } else if (ambiguityPolicy == QrAmbiguityPolicy.preferLastOpenCave) {
      selected = await _pickByLastOpenCave(results);
    } else {
      if (!context.mounted) return null;
      final choice = await _showDisambiguationDialog(context, results);
      if (choice == null) return null;
      selected = choice;
    }

    if (!context.mounted) return null;

    final cavePlace = selected.cavePlace;
    final isEntrance =
        cavePlace.isEntrance == 1 || cavePlace.isMainEntrance == 1;

    if (isEntrance) {
      await _handleEntranceScan(context, cavePlace);
    } else {
      // Record a trip point when there is an active trip for this place's cave.
      final activeTripCaveId = await caveTripService.getActiveTripCaveId();
      if (activeTripCaveId == cavePlace.caveUuid) {
        await caveTripService.recordPoint(
          cavePlace.uuid,
          placeTitle: cavePlace.title,
        );
        SnackBarService.showSuccess(LocServ.inst.t('trip_point_added'));
      }
    }

    if (!context.mounted) return cavePlace;

    // Find the best raster map to open: first in sort order that has a
    // definition for this cave place.  If none found, fall back to CavePlacePage.
    final allMaps = await rasterMapRepository.getRasterMaps(cavePlace.caveUuid);
    Uuid? bestMapUuid;
    if (allMaps.isNotEmpty) {
      final sortOption = await RasterMapSortOption.load();
      final sortedMaps = sortOption.apply(allMaps, []);
      for (final rm in sortedMaps) {
        final def =
            await definitionRepository.findDefinition(cavePlace.uuid, rm.uuid);
        if (def != null) {
          bestMapUuid = rm.uuid;
          break;
        }
      }
    }

    if (!context.mounted) return cavePlace;

    if (bestMapUuid != null) {
      await Navigator.pushNamed(
        context,
        cavePlaceViewRoute,
        arguments: {
          'caveUuid': cavePlace.caveUuid,
          'cavePlaceUuid': cavePlace.uuid,
          'initialRasterMapUuid': bestMapUuid,
        },
      );
    } else {
      SnackBarService.showWarning(
          LocServ.inst.t('no_map_definition_for_place'));
      await Navigator.pushNamed(
        context,
        cavePlaceRoute,
        arguments: {
          'caveUuid': cavePlace.caveUuid,
          'cavePlaceUuid': cavePlace.uuid,
        },
      );
    }

    if (context.mounted) {
      SnackBarService.showSuccess(
          '${LocServ.inst.t('cave_place_identified')}: "${cavePlace.title}"');
    }

    return cavePlace;
  }

  // ---------------------------------------------------------------------------
  // Disambiguation
  // ---------------------------------------------------------------------------

  Future<QrLookupResult> _pickByLastOpenCave(
      List<QrLookupResult> results) async {
    final lastCaveId = await _getLastOpenCaveId();
    if (lastCaveId != null) {
      for (final r in results) {
        if (r.cavePlace.caveUuid == lastCaveId) return r;
      }
    }
    return results.first;
  }

  Future<Uuid?> _getLastOpenCaveId() async {
    final raw = await SettingsHelper.loadStringConfig(lastOpenCaveKey);
    if (raw.isEmpty) return null;
    try {
      return Uuid.parse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<QrLookupResult?> _showDisambiguationDialog(
    BuildContext context,
    List<QrLookupResult> results,
  ) {
    return showDialog<QrLookupResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('multiple_qr_matches')),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LocServ.inst.t('multiple_qr_matches_explanation')),
                const SizedBox(height: 8),
                ...List.generate(results.length, (i) {
                  final r = results[i];
                  final tile = ListTile(
                    title: Text(r.cavePlace.title),
                    subtitle: Text(r.caveTitle),
                    leading: const Icon(Icons.place),
                    onTap: () => Navigator.pop(ctx, r),
                  );
                  return i == 0
                      ? tile
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [const Divider(height: 1), tile],
                        );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsGeneralPage(),
                ),
              );
            },
            child: Text(LocServ.inst.t('open_settings')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocServ.inst.t('cancel')),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Entrance handling
  // ---------------------------------------------------------------------------

  /// Entrance scan flow: depending on whether a trip is active and for which
  /// cave, prompt the user to start a new trip, stop the current one, or
  /// switch to a trip in the scanned entrance's cave.
  Future<void> _handleEntranceScan(
    BuildContext context,
    CavePlace cavePlace,
  ) async {
    final activeTripCaveId = await caveTripService.getActiveTripCaveId();
    if (!context.mounted) return;

    if (activeTripCaveId == null) {
      // No active trip — offer to start one (entering cave).
      final start = await _confirm(
        context,
        title: LocServ.inst.t('trip_start'),
        message: LocServ.inst.t('scan_entrance_start_trip'),
      );
      if (start == true && context.mounted) {
        await _startTripForCave(context, cavePlace.caveUuid);
      }
    } else if (activeTripCaveId == cavePlace.caveUuid) {
      // Trip running for THIS cave — offer to stop (exiting).
      final stop = await _confirm(
        context,
        title: LocServ.inst.t('trip_stop'),
        message: LocServ.inst.t('scan_entrance_exit_cave'),
      );
      if (stop == true && context.mounted) {
        await _performStopTrip();
      } else if (context.mounted) {
        // Still in cave — record the entrance scan as a trip point.
        await caveTripService.recordPoint(
          cavePlace.uuid,
          placeTitle: cavePlace.title,
        );
        SnackBarService.showSuccess(LocServ.inst.t('trip_point_added'));
      }
    } else {
      // Trip running for a DIFFERENT cave — offer to stop it first.
      final otherCave = await caveRepository.findById(activeTripCaveId);
      final otherCaveTitle =
          otherCave?.title ?? activeTripCaveId.toString();
      if (!context.mounted) return;

      final stopOther = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(LocServ.inst.t('confirm')),
          content: Text(LocServ.inst.t(
            'scan_entrance_stop_other_trip',
            {'cave': otherCaveTitle},
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(LocServ.inst.t('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(LocServ.inst.t('yes')),
            ),
          ],
        ),
      );
      if (stopOther == true && context.mounted) {
        await _performStopTrip();
        if (context.mounted) {
          final start = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(LocServ.inst.t('trip_start')),
              content:
                  Text(LocServ.inst.t('scan_entrance_start_after_stop')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(LocServ.inst.t('cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(LocServ.inst.t('yes')),
                ),
              ],
            ),
          );
          if (start == true && context.mounted) {
            await _startTripForCave(context, cavePlace.caveUuid);
          }
        }
      }
    }
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('yes')),
          ),
        ],
      ),
    );
  }

  Future<void> _startTripForCave(BuildContext context, Uuid caveUuid) async {
    final cave = await caveRepository.findById(caveUuid);
    final defaultTitle =
        '${cave?.title ?? ''} ${dateFormat.format(DateTime.now())}';
    final existingTitles = await caveTripRepository.getCaveTripTitles(caveUuid);
    final suggestedTitle =
        CaveTripService.uniqueTripTitle(defaultTitle, existingTitles);

    if (!context.mounted) return;
    final controller = TextEditingController(text: suggestedTitle);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('trip_name_dialog_title')),
        content: TextField(
          controller: controller,
          decoration:
              InputDecoration(labelText: LocServ.inst.t('trip_title_hint')),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('ok')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final title = controller.text.trim().isNotEmpty
          ? controller.text.trim()
          : suggestedTitle;
      await caveTripService.startTrip(caveUuid, title);
    }
  }

  Future<void> _performStopTrip() async {
    await caveTripService.stopTrip();
    SnackBarService.showSuccess(LocServ.inst.t('trip_stopped'));
  }

  // ---------------------------------------------------------------------------
  // Static convenience entry points
  // ---------------------------------------------------------------------------

  /// Canonical entry point for "scan QR" actions.
  ///
  /// Checks camera permission, opens the scanner, then runs the full lookup
  /// flow via [handleScannedCode]. The ambiguity policy is read from
  /// [qrScanAmbiguityPolicyKey].
  ///
  /// [currentCaveId] scopes the lookup to a single cave when the caller has
  /// that context (e.g. CavePlacesListPage).
  static Future<CavePlace?> openAndHandle(
    BuildContext context, {
    Uuid? currentCaveId,
  }) async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!context.mounted) return null;

    if (status.isGranted) {
      String? scannedCode;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => ScannerPage(onScan: (code) {
            scannedCode = code;
          }),
        ),
      );
      if (scannedCode != null && context.mounted) {
        final policy = await loadQrAmbiguityPolicy(QrLookupSource.scan);
        if (!context.mounted) return null;
        return QrCodeLookupHandler.defaultInstance().handleScannedCode(
          context,
          scannedCode!,
          currentCaveId: currentCaveId,
          ambiguityPolicy: policy,
          // ScannerPage already runs qrScanService.process on the code it
          // delivers, but the handler's process step is idempotent.
          preprocessPayload: false,
        );
      }
    } else if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(LocServ.inst.t('permission_required')),
            content: Text(LocServ.inst.t('camera_permission_required')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(LocServ.inst.t('cancel')),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.of(ctx).pop();
                },
                child: Text(LocServ.inst.t('open_settings')),
              ),
            ],
          ),
        );
      }
    } else {
      if (context.mounted) {
        SnackBarService.showWarning(
            LocServ.inst.t('camera_permission_denied'));
      }
    }
    return null;
  }

  /// Canonical entry point for the "manual QR input" dialog used by
  /// HomePage and CavePlacesListPage when the user long-presses the scan
  /// button.
  ///
  /// Shows a text-input dialog, then runs the full lookup flow with
  /// payload preprocessing enabled.
  static Future<CavePlace?> manualInputAndHandle(
    BuildContext context, {
    Uuid? currentCaveId,
  }) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('manual_qr_search')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: LocServ.inst.t('qr_code_identifier'),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocServ.inst.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child:
                Text(LocServ.inst.t('search_place_by_qr_code_by_identifier')),
          ),
        ],
      ),
    );
    if (confirmed == null || confirmed.isEmpty || !context.mounted) {
      return null;
    }
    final policy = await loadQrAmbiguityPolicy(QrLookupSource.scan);
    if (!context.mounted) return null;
    return QrCodeLookupHandler.defaultInstance().handleScannedCode(
      context,
      confirmed,
      currentCaveId: currentCaveId,
      ambiguityPolicy: policy,
    );
  }
}
