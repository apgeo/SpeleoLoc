import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/utils/cave_place_qr_generator.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';

/// Dialog that renders and displays the QR code image for a given [CavePlace].
///
/// Uses [QrImageRenderer] with the current generation settings from the
/// database to produce the preview.
class CavePlaceQrPreviewDialog extends StatefulWidget {
  final CavePlace cavePlace;

  const CavePlaceQrPreviewDialog({super.key, required this.cavePlace});

  @override
  State<CavePlaceQrPreviewDialog> createState() =>
      _CavePlaceQrPreviewDialogState();

  /// Show the QR preview dialog for [cavePlace].
  /// Does nothing if the place has no QR code identifier.
  static void show(BuildContext context, CavePlace cavePlace) {
    if (cavePlace.placeQrCodeIdentifier == null) return;
    showDialog(
      context: context,
      builder: (_) => CavePlaceQrPreviewDialog(cavePlace: cavePlace),
    );
  }
}

class _CavePlaceQrPreviewDialogState extends State<CavePlaceQrPreviewDialog> {
  Uint8List? _imageBytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _renderQr();
  }

  Future<void> _renderQr() async {
    try {
      final cfg = await SettingsHelper.loadJsonConfig(
        qrGenerationConfigKey,
        () => <String, dynamic>{},
      );

      final prefs = GenerationPreferences(
        includeTitle: cfg['includeTitle'] ?? true,
        qrSizePx: cfg['qrSizePx'] ?? 400,
        imagePaddingPx: cfg['imagePaddingPx'] ?? 24,
        labelFontSize: (cfg['labelFontSize'] is num)
            ? (cfg['labelFontSize'] as num).toDouble()
            : 18.0,
        qrBgColor: cfg['qrBgColor'] ?? 0xFFFFFFFF,
        qrFgColor: cfg['qrFgColor'] ?? 0xFF000000,
        qrErrorCorrectionLevel: cfg['qrErrorCorrectionLevel'] ?? 'M',
      );

      final bytes = await QrImageRenderer.render(widget.cavePlace, prefs);

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocServ.inst.t('qr_code_preview')),
      content: _loading
          ? const SizedBox(
              width: 200,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? Text('${LocServ.inst.t('error')}: $_error')
              : _imageBytes != null
                  ? InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                    )
                  : Text(LocServ.inst.t('no_qr_code_defined')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocServ.inst.t('close')),
        ),
      ],
    );
  }
}
