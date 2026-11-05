import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speleoloc/services/qr_scan_service.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.onScan});

  /// Called with the processed payload (deep link prefix stripped, etc.).
  /// Use [ScannerPage.raw] to receive the original payload instead.
  final void Function(String) onScan;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with AppBarMenuMixin<ScannerPage>, ProductTourMixin<ScannerPage> {
  @override
  String get tourId => 'scanner';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(
      keyId: 'camera',
      titleLocKey: 'tour_scanner_camera_title',
      bodyLocKey: 'tour_scanner_camera_body',
    ),
    TourStepDef(
      keyId: 'torch',
      titleLocKey: 'tour_scanner_torch_title',
      bodyLocKey: 'tour_scanner_torch_body',
    ),
    TourStepDef(
      keyId: 'menu',
      titleLocKey: 'tour_scanner_menu_title',
      bodyLocKey: 'tour_scanner_menu_body',
    ),
  ];

  final MobileScannerController _controller = MobileScannerController();
  QrScanConfig _scanConfig = const QrScanConfig();

  /// Frames already being analysed when the camera is stopped still report a
  /// detection; only the first one may hand over a code and close the page.
  bool _handled = false;
  // Using global appDatabase instance

  @override
  void initState() {
    super.initState();
    QrScanConfig.load().then((cfg) {
      if (mounted) setState(() => _scanConfig = cfg);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    // Once the page is leaving (back gesture, menu navigation) a late frame
    // must neither report a code nor pop, which would close the page beneath.
    if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
    final code = capture.barcodes.firstOrNull?.rawValue ?? '';
    if (code.isEmpty) return;
    _handled = true;
    unawaited(_controller.stop());
    final processed = qrScanService.process(code, config: _scanConfig).qcri;
    widget.onScan(processed);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop || _handled) return;
        _handled = true;
        unawaited(_controller.stop());
      },
      child: Scaffold(
        key: appMenuScaffoldKey,
        endDrawer: buildAppMenuEndDrawer(),
        appBar: AppBar(
          title: Text(LocServ.inst.t('scan_qr')),
          actions: [
            IconButton(
              key: tourKeys['torch'],
              icon: const Icon(Icons.flash_on),
              onPressed: () => _controller.toggleTorch(),
            ),
            KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
          ],
        ),
        body: KeyedSubtree(
          key: tourKeys['camera'],
          child: MobileScanner(controller: _controller, onDetect: _onDetect),
        ),
      ),
    );
  }
}
