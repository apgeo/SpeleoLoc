import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/utils/cave_place_qr_generator.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/qr_generation_defaults.dart';

/// Full-featured QR code preview dialog for a [CavePlace].
///
/// Renders the QR image using [QrImageRenderer] with the current generation
/// settings and displays it in a properly sized, zoomable dialog.
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
        qrSizePx: cfg['qrSizePx'] ?? QrGenerationDefaults.qrSizePx,
        imagePaddingPx:
            cfg['imagePaddingPx'] ?? QrGenerationDefaults.imagePaddingPx,
        labelFontSize: (cfg['labelFontSize'] is num)
            ? (cfg['labelFontSize'] as num).toDouble()
            : QrGenerationDefaults.labelFontSize,
        qrBgColor: cfg['qrBgColor'] ?? QrGenerationDefaults.qrBgColor,
        qrFgColor: cfg['qrFgColor'] ?? QrGenerationDefaults.qrFgColor,
        qrErrorCorrectionLevel: cfg['qrErrorCorrectionLevel'] ??
            QrGenerationDefaults.errorCorrectionLevel,
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
    final screenSize = MediaQuery.of(context).size;
    final dialogSize = screenSize.shortestSide * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.cavePlace.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // QR image area
            SizedBox(
              width: dialogSize,
              height: dialogSize,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            '${LocServ.inst.t('error')}: $_error',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _imageBytes != null
                          ? InteractiveViewer(
                              minScale: 0.8,
                              maxScale: 6.0,
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.contain,
                                width: dialogSize,
                                height: dialogSize,
                              ),
                            )
                          : Center(
                              child: Text(LocServ.inst.t('no_qr_code_defined')),
                            ),
            ),
            const SizedBox(height: 4),
            // QR code number label
            if (widget.cavePlace.placeQrCodeIdentifier != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '#${widget.cavePlace.placeQrCodeIdentifier}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
              ),
            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocServ.inst.t('close')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

