import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_controller.dart';
import 'package:speleoloc/screens/scanner_page.dart';
import 'package:speleoloc/services/place_code/place_code_service.dart';
import 'package:speleoloc/services/place_code/place_code_strategy.dart';
import 'package:speleoloc/services/qr_scan_service.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/cave_place_qr_preview_dialog.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Encapsulates all QR-scan and place-code-generation interactions for
/// `CavePlacePage`.
///
/// The controller is created in [State.initState] and disposed in
/// [State.dispose]. It owns a [Timer] (for long-press detection) and a
/// [TextEditingController] (for manual QR entry) so the host state no
/// longer needs to declare them directly.
///
/// The [rebuild] callback wraps the host page's `setState` — pass `setState`
/// from `_CavePlacePageState` directly. [setQrEditable] and [setQcriEditable]
/// are called **inside** that callback so that field mutations and flag flips
/// happen atomically in one rebuild.
class CavePlaceQrController {
  CavePlaceQrController({
    required State<StatefulWidget> state,
    required CavePlaceFormController form,
    required ICavePlaceRepository cavePlaceRepository,
    required PlaceCodeService placeCodeService,
    required Uuid caveUuid,
    required Uuid? Function() cavePlaceId,
    required CavePlace? Function() cavePlace,
    required void Function(void Function()) rebuild,
    required void Function(bool) setQrEditable,
    required void Function(bool) setQcriEditable,
  })  : _state = state,
        _form = form,
        _cavePlaceRepository = cavePlaceRepository,
        _placeCodeService = placeCodeService,
        _caveUuid = caveUuid,
        _cavePlaceId = cavePlaceId,
        _cavePlace = cavePlace,
        _rebuild = rebuild,
        _setQrEditable = setQrEditable,
        _setQcriEditable = setQcriEditable;

  final State<StatefulWidget> _state;
  final CavePlaceFormController _form;
  final ICavePlaceRepository _cavePlaceRepository;
  final PlaceCodeService _placeCodeService;
  final Uuid _caveUuid;
  final Uuid? Function() _cavePlaceId;
  final CavePlace? Function() _cavePlace;

  /// Wraps the host state's `setState`. Use this for any mutation that
  /// requires a widget rebuild.
  final void Function(void Function()) _rebuild;

  /// Assigns the `_qrEditable` flag in the host state (called inside [_rebuild]).
  final void Function(bool) _setQrEditable;

  /// Assigns the `_qcriEditable` flag in the host state (called inside [_rebuild]).
  final void Function(bool) _setQcriEditable;

  Timer? _longPressTimer;
  final TextEditingController manualInputController = TextEditingController();

  bool get _mounted => _state.mounted;
  BuildContext get _context => _state.context;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void dispose() {
    _longPressTimer?.cancel();
    manualInputController.dispose();
  }

  // ── Scanner ───────────────────────────────────────────────────────────────

  void openScanner() async {
    await Navigator.push(
      _context,
      MaterialPageRoute(builder: (_) => ScannerPage(onScan: onQrScanned)),
    );
  }

  void startLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: 2500), () {
      if (_mounted) _showManualInputDialog();
    });
  }

  void cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  Future<void> _showManualInputDialog() async {
    manualInputController.clear();
    final confirmed = await showDialog<String>(
      context: _context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('manual_qr_search')),
        content: TextField(
          controller: manualInputController,
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
            onPressed: () =>
                Navigator.pop(ctx, manualInputController.text.trim()),
            child: Text(
                LocServ.inst.t('search_place_by_qr_code_by_identifier')),
          ),
        ],
      ),
    );
    if (confirmed != null && confirmed.isNotEmpty && _mounted) {
      final processed = qrScanService
          .process(confirmed, config: await QrScanConfig.load())
          .qcri;
      if (processed.isNotEmpty) onQrScanned(processed);
    }
  }

  // ── QR scanned callback ───────────────────────────────────────────────────

  void onQrScanned(String code) async {
    final qr = code.trim();
    if (qr.isEmpty) {
      if (!_mounted) return;
      SnackBarService.showWarning(LocServ.inst.t('invalid_qr_code'));
      return;
    }
    final currentQcriValue = _form.qcri.text.trim();

    if (currentQcriValue == qr) {
      if (!_mounted) return;
      SnackBarService.showWarning(LocServ.inst.t('qr_code_already_present'));
      return;
    }

    _rebuild(() => _form.markQcriTouched());

    final qcriDups = await _cavePlaceRepository.findByQrCodeResourceIdentifier(
      qr,
      excludeUuid: _cavePlaceId(),
    );
    final existing = qcriDups.isEmpty ? null : qcriDups.first;

    if (existing != null) {
      if (!_mounted) return;
      SnackBarService.showWarning(
        'QR code ${LocServ.inst.t('already_used_for')}: "${existing.title}"',
      );
      return;
    }

    if (currentQcriValue.isNotEmpty && currentQcriValue != qr) {
      if (!_mounted) return;
      final shouldReplace = await showDialog<bool>(
        context: _context,
        builder: (ctx) => AlertDialog(
          title: Text(LocServ.inst.t('replace_qr_code')),
          content: Text(LocServ.inst.t('existing_qr_code_will_be_replaced')),
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
      if (shouldReplace != true) return;
    }

    if (!_mounted) return;
    _rebuild(() {
      _setQcriEditable(true);
      _form.qcri.text = qr;
    });

    final mirror = await _placeCodeService.isMirrorMode();
    if (mirror && _mounted && _form.qr.text.trim().isEmpty) {
      final pciDups = await _cavePlaceRepository.findByPlaceCodeIdentifier(
        qr,
        excludeUuid: _cavePlaceId(),
      );
      final pciDup = pciDups.isEmpty ? null : pciDups.first;
      if (pciDup != null) {
        if (_mounted) {
          SnackBarService.showWarning(
            '${LocServ.inst.t('place_code_identifier')} '
            '${LocServ.inst.t('already_used_for')}: "${pciDup.title}"',
          );
        }
      } else if (_mounted) {
        _rebuild(() {
          _setQrEditable(true);
          _form.qr.text = qr;
        });
      }
    }

    if (!_mounted || _cavePlace() == null) return;
    CavePlaceQrPreviewDialog.show(
      _context,
      _cavePlace()!,
      qrIdentifierOverride: qr,
    );
  }

  // ── Auto-generate ─────────────────────────────────────────────────────────

  Future<void> autoGeneratePci() async {
    final effectiveUuid = _cavePlaceId() ?? Uuid.v7();
    try {
      final result = await _placeCodeService.generatePci(
        caveUuid: _caveUuid,
        cavePlaceUuid: effectiveUuid,
        isMainEntrance: _form.isEntrance && _form.isMainEntrance,
      );
      if (!_mounted) return;
      final String? pci = switch (result) {
        PlaceCodeGenerationOk r => r.pci,
        PlaceCodeGenerationFallback r => r.pci,
        PlaceCodeGenerationAborted r
            when r.reason == PlaceCodeAbortReason.missingDatasetConfig =>
          null,
        _ => null,
      };
      if (pci == null) {
        final isMissingConfig = result is PlaceCodeGenerationAborted &&
            result.reason == PlaceCodeAbortReason.missingDatasetConfig;
        SnackBarService.showWarning(
          isMissingConfig
              ? LocServ.inst.t('place_code_error_missing_dataset_config')
              : LocServ.inst.t('place_code_error_generic'),
        );
        return;
      }
      _rebuild(() {
        _form.qr.text = pci;
        _form.markPciTouched();
      });
    } catch (e, st) {
      AppLogger.of('CavePlaceQrController')
          .severe('PCI auto-generate failed', e, st);
      if (!_mounted) return;
      SnackBarService.showError(e.toString());
    }
  }

  Future<void> autoGenerateQcri() async {
    final pci = _form.qr.text.trim();
    if (pci.isEmpty) {
      SnackBarService.showWarning(
          LocServ.inst.t('place_code_identifier_required'));
      return;
    }
    final effectiveUuid = _cavePlaceId() ?? Uuid.v7();
    try {
      final qcri = await _placeCodeService.computeQcri(
        pci,
        cavePlaceUuid: effectiveUuid,
        isEntrance: _form.isEntrance,
      );
      if (!_mounted) return;
      _rebuild(() {
        _form.qcri.text = qcri;
        _form.markQcriTouched();
      });
    } catch (e, st) {
      AppLogger.of('CavePlaceQrController')
          .severe('QCRI auto-generate failed', e, st);
      if (!_mounted) return;
      SnackBarService.showError(e.toString());
    }
  }
}
