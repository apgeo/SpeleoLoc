import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/utils/cave_place_qr_generator.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/qr_generation_defaults.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Full-featured QR code preview dialog for a [CavePlace].
///
/// Renders the QR image using [QrImageRenderer] with the current generation
/// settings and displays it in a properly sized, zoomable dialog.
class CavePlaceQrPreviewDialog extends StatefulWidget {
  final CavePlace cavePlace;
  /// When set, overrides [cavePlace.placeQrCodeIdentifier] for the preview.
  /// Use this to preview unsaved changes before the user hits save.
  final int? qrIdentifierOverride;

  const CavePlaceQrPreviewDialog({super.key, required this.cavePlace, this.qrIdentifierOverride});

  @override
  State<CavePlaceQrPreviewDialog> createState() =>
      _CavePlaceQrPreviewDialogState();

  /// Show the QR preview dialog for [cavePlace].
  /// [qrIdentifierOverride] lets callers preview a QR number that has not
  /// been saved yet (e.g. an unsaved value in the form field).
  /// Does nothing if there is no QR identifier to render.
  static void show(BuildContext context, CavePlace cavePlace, {int? qrIdentifierOverride}) {
    final effectiveQr = qrIdentifierOverride ?? cavePlace.placeQrCodeIdentifier;
    if (effectiveQr == null) return;
    showDialog(
      context: context,
      builder: (_) => CavePlaceQrPreviewDialog(
        cavePlace: cavePlace,
        qrIdentifierOverride: qrIdentifierOverride,
      ),
    );
  }
}

class _CavePlaceQrPreviewDialogState extends State<CavePlaceQrPreviewDialog> {
  GenerationPreferences? _prefs;
  bool _loading = true;
  String? _error;
  bool _exporting = false;
  final _qrRepaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final cfg = await SettingsHelper.loadJsonConfig(
        qrGenerationConfigKey,
        () => <String, dynamic>{},
      );
      final prefs = GenerationPreferences(
        includeTitle: cfg['includeTitle'] ?? true,
        qrSizePx: cfg['qrSizePx'] ?? QrGenerationDefaults.qrSizePx,
        imagePaddingPx: cfg['imagePaddingPx'] ?? QrGenerationDefaults.imagePaddingPx,
        labelFontSize: (cfg['labelFontSize'] is num)
            ? (cfg['labelFontSize'] as num).toDouble()
            : QrGenerationDefaults.labelFontSize,
        qrBgColor: cfg['qrBgColor'] ?? QrGenerationDefaults.qrBgColor,
        qrFgColor: cfg['qrFgColor'] ?? QrGenerationDefaults.qrFgColor,
        qrErrorCorrectionLevel: cfg['qrErrorCorrectionLevel'] ??
            QrGenerationDefaults.errorCorrectionLevel,            
      );
      if (mounted) {
        setState(() {
          _prefs = prefs;
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

  int _ecLevel(String level) {
    switch (level.toUpperCase()) {
      case 'L': return QrErrorCorrectLevel.L;
      case 'Q': return QrErrorCorrectLevel.Q;
      case 'H': return QrErrorCorrectLevel.H;
      default:   return QrErrorCorrectLevel.M;
    }
  }

  Widget _buildQrContent(int qrId) {
    final prefs = _prefs!;
    final padding = prefs.imagePaddingPx.toDouble();
    return RepaintBoundary(
      key: _qrRepaintKey,
      child: Container(
        color: Color(prefs.qrBgColor),
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: QrImageView(
                data: '$qrId',
                version: QrVersions.auto,
                gapless: true,
                errorCorrectionLevel: _ecLevel(prefs.qrErrorCorrectionLevel),
                backgroundColor: Color(prefs.qrBgColor),
                // the small individual modules/boxes in the qr code image used for encoding data
                dataModuleStyle: QrDataModuleStyle(
                  color: Color(prefs.qrFgColor),
                  dataModuleShape: QrDataModuleShape.square,
                ),
                // the big modules/boxes in the qr code image corners used for orientation detection by scanners
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(prefs.qrFgColor),
                ),
              ),
            ),
            if (prefs.includeTitle && widget.cavePlace.title.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.cavePlace.title,
                style: TextStyle(
                  fontSize: prefs.labelFontSize,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Returns the best available "Pictures" directory for the current platform.
  Future<Directory> _resolvePicturesDirectory() async {
    try {
      if (Platform.isAndroid) {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          final parts = ext.path.split('/');
          final androidIdx = parts.indexOf('Android');
          if (androidIdx > 0) {
            final root = parts.sublist(0, androidIdx).join('/');
            final dir = Directory('$root/Pictures');
            if (!await dir.exists()) await dir.create(recursive: true);
            return dir;
          }
        }
      } else if (!Platform.isIOS) {
        final homeKey = Platform.isWindows ? 'USERPROFILE' : 'HOME';
        final home = Platform.environment[homeKey];
        if (home != null) {
          final sep = Platform.isWindows ? r'\' : '/';
          final dir = Directory('$home${sep}Pictures');
          if (await dir.exists()) return dir;
        }
        final downloads = await getDownloadsDirectory();
        if (downloads != null) return downloads;
      }
    } catch (_) {}
    return getApplicationDocumentsDirectory();
  }

  Future<void> _exportImage(BuildContext context) async {
    final effectiveId = widget.qrIdentifierOverride ?? widget.cavePlace.placeQrCodeIdentifier;
    if (effectiveId == null || _prefs == null || _exporting) return;

    // Capture the live rendered widget — this is correct by definition since
    // it is exactly what the user sees, and avoids the off-screen canvas
    // sizing issues that plague QrPainter-based rendering.
    setState(() => _exporting = true);
    Uint8List bytes;
    try {
      final boundary = _qrRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('QR widget is not rendered yet');
      // pixelRatio: 3 gives ~1200 px for a typical 400 px logical QR, matching
      // the quality of a direct high-DPI render.
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('Failed to encode QR image to PNG');
      bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    } catch (e) {
      if (mounted) {
        setState(() => _exporting = false);
        SnackBarService.showError(e);
      }
      return;
    }
    if (mounted) setState(() => _exporting = false);
    if (!context.mounted) return;

    final placeName = widget.cavePlace.title.replaceAll(RegExp(r'[^\w\-]'), '_');
    final fileName = 'qr_$placeName.png';
    final picturesDir = await _resolvePicturesDirectory();
    if (!context.mounted) return;

    // Ask the user where to save.
    final saveToCustom = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('export')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fileName, style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(LocServ.inst.t('export_to_pictures')),
              subtitle: Text(
                picturesDir.path,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              onTap: () => Navigator.pop(ctx, false),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_open),
              title: Text(LocServ.inst.t('export_choose_location')),
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocServ.inst.t('cancel')),
          ),
        ],
      ),
    );

    if (saveToCustom == null || !context.mounted) return;

    try {
      if (saveToCustom) {
        if (Platform.isAndroid || Platform.isIOS) {
          final dir = await FilePicker.platform.getDirectoryPath(
            dialogTitle: LocServ.inst.t('choose_folder_save_files'),
          );
          if (dir == null || !context.mounted) return;
          final file = File('$dir/$fileName');
          await file.writeAsBytes(bytes);
          if (context.mounted) {
            SnackBarService.showSuccess('${LocServ.inst.t('files_saved')}: ${file.path}');
          }
        } else {
          final output = await FilePicker.platform.saveFile(
            dialogTitle: LocServ.inst.t('export'),
            fileName: fileName,
            bytes: bytes,
          );
          if (output == null || !context.mounted) return;
          await File(output).writeAsBytes(bytes);
          if (context.mounted) {
            SnackBarService.showSuccess('${LocServ.inst.t('files_saved')}: $output');
          }
        }
      } else {
        final file = File('${picturesDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        if (context.mounted) {
          SnackBarService.showSuccess('${LocServ.inst.t('files_saved')}: ${file.path}');
        }
      }
    } catch (e) {
      if (context.mounted) SnackBarService.showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveId = widget.qrIdentifierOverride ?? widget.cavePlace.placeQrCodeIdentifier;
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
            // QR content area
            if (_loading)
              const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    '${LocServ.inst.t('error')}: $_error',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (effectiveId != null)
              _buildQrContent(effectiveId)
            else
              SizedBox(
                height: 200,
                child: Center(child: Text(LocServ.inst.t('no_qr_code_defined'))),
              ),
            const SizedBox(height: 4),
            // QR code number label
            if (effectiveId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '#$effectiveId',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
              ),
            // Bottom action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _exporting
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.download),
                        tooltip: LocServ.inst.t('export'),
                        onPressed: (_prefs != null && effectiveId != null)
                            ? () => _exportImage(context)
                            : null,
                      ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(LocServ.inst.t('close')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

