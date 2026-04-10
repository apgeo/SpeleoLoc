import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.onScan});

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
    TourStepDef(keyId: 'camera', titleLocKey: 'tour_scanner_camera_title', bodyLocKey: 'tour_scanner_camera_body'),
    TourStepDef(keyId: 'torch', titleLocKey: 'tour_scanner_torch_title', bodyLocKey: 'tour_scanner_torch_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_scanner_menu_title', bodyLocKey: 'tour_scanner_menu_body'),
  ];

  final MobileScannerController _controller = MobileScannerController();
  // Using global appDatabase instance
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // initDatabase();
    
    return Scaffold(
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
        child: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final code = barcodes.first.rawValue ?? '';
            if (code.isNotEmpty) {
              _controller.stop();
              widget.onScan(code);
              if (mounted) Navigator.pop(context);
            }
          }
        },
      ),
      ),
    );
  }
}