import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speleoloc/utils/localization.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.onScan});

  final void Function(String) onScan;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  // Using global appDatabase instance
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // void initDatabase() async {
  //   // database = AppDatabase();

  //     await database
  //         .into(database.caves)
  //         .insert(
  //           CavesCompanion.insert(
  //             title: 'P. Comana',
  //             // areaTitle: Value('Persani')
  //           ),
  //         );
  //     List<Cave> allItems = await database.select(database.caves).get();

  //     await database.close();

  //      // _controller.
  //     print('caves in database: $allItems');
  // }  
  
  @override
  Widget build(BuildContext context) {
    // initDatabase();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(LocServ.inst.t('scan_qr')),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: MobileScanner(
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
    );
  }
}