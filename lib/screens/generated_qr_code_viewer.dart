import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/cave_place_qr_generator.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/screens/settings/settings_pdf_output_page.dart';
import 'package:speleoloc/screens/settings/settings_qr_generation_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:pdfx/pdfx.dart';

/// Viewer screen for generated QR code PDFs.
///
/// Loads configuration, generates the PDF internally, and displays it inline.
/// Provides toolbar buttons to regenerate, open QR settings, and open PDF
/// output settings.
class GeneratedQRCodeViewer extends StatefulWidget {
  final int? caveId;
  final List<CavePlace>? cavePlaces;

  const GeneratedQRCodeViewer({super.key, this.caveId, this.cavePlaces})
      : assert(
          (caveId == null) != (cavePlaces == null),
          'Provide exactly one of caveId or cavePlaces, not both or neither.',
        );

  @override
  State<GeneratedQRCodeViewer> createState() => _GeneratedQRCodeViewerState();
}

class _GeneratedQRCodeViewerState extends State<GeneratedQRCodeViewer>
    with AppBarMenuMixin<GeneratedQRCodeViewer> {
  GenerationResult? _result;
  bool _isGenerating = false;
  String? _error;
  PdfControllerPinch? _pdfController;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    // Dispose previous PDF controller
    _pdfController?.dispose();
    _pdfController = null;

    try {
      // Load cave (only if caveId is provided)
      final cave = widget.caveId != null
          ? await (appDatabase.select(appDatabase.caves)
                ..where((c) => c.id.equals(widget.caveId!)))
              .getSingleOrNull()
          : null;

      // Load output kind preference
      final pref = await (appDatabase.select(appDatabase.configurations)
            ..where((c) => c.title.equals('qr_output_kind')))
          .getSingleOrNull();
      final asPdf = (pref?.value ?? 'pdf') == 'pdf';

      // Load full QR generation config (JSON)
      final configRow = await (appDatabase.select(appDatabase.configurations)
            ..where((c) => c.title.equals(qrGenerationConfigKey)))
          .getSingleOrNull();
      Map<String, dynamic> cfg = {};
      if (configRow != null) {
        try {
          cfg = jsonDecode(configRow.value ?? '{}');
        } catch (_) {
          cfg = {};
        }
      }

      // Load PDF output config (grid, template)
      final pdfCfgRow = await (appDatabase.select(appDatabase.configurations)
            ..where((c) => c.title.equals(pdfOutputConfigKey)))
          .getSingleOrNull();
      Map<String, dynamic> pdfCfg = {};
      if (pdfCfgRow != null) {
        try {
          pdfCfg = jsonDecode(pdfCfgRow.value ?? '{}');
        } catch (_) {
          pdfCfg = {};
        }
      }

      // Get cave places
      final cavePlaces = widget.cavePlaces ??
          await (appDatabase.select(appDatabase.cavePlaces)
                ..where((cp) => cp.caveId.equals(widget.caveId!)))
              .get();

      // Build generation preferences from config
      final genPrefs = GenerationPreferences(
        asPdf: asPdf,
        includeTitle: cfg['includeTitle'] ?? true,
        dpi: cfg['dpi'] ?? 300,
        backgroundColor: cfg['backgroundColor'] ?? 0xFFFFFFFF,
        imageFormat: cfg['imageFormat'] ?? 'png',
        qrSizePx: cfg['qrSizePx'] ?? 400,
        imagePaddingPx: cfg['imagePaddingPx'] ?? 24,
        labelFontSize: (cfg['labelFontSize'] is num)
            ? (cfg['labelFontSize'] as num).toDouble()
            : (cfg['labelFontSize'] ?? 18.0),
        labelFontFamily: cfg['labelFontFamily'] ?? 'Helvetica',
        qrBgColor: cfg['qrBgColor'] ?? 0xFFFFFFFF,
        qrFgColor: cfg['qrFgColor'] ?? 0xFF000000,
        exportImagesAsZip: cfg['exportImagesAsZip'] ?? true,
        qrErrorCorrectionLevel: cfg['qrErrorCorrectionLevel'] ?? 'M',
        pdfGridColumns: pdfCfg['gridColumns'] ?? 4,
        pdfGridRows: pdfCfg['gridRows'] ?? 5,
        labelTemplate: pdfCfg['labelTemplate'] ?? defaultLabelTemplate,
        pdfQrPaddingH: (cfg['pdfQrPaddingH'] is num)
            ? (cfg['pdfQrPaddingH'] as num).toDouble()
            : 2.0,
        pdfQrPaddingV: (cfg['pdfQrPaddingV'] is num)
            ? (cfg['pdfQrPaddingV'] as num).toDouble()
            : 2.0,
        caveTitle: cave?.title,
        areaTitle: null,
      );

      final generator = CavePlaceQRCodePDFGenerator();
      final result = await generator.generate(
        cavePlaces,
        genPrefs,
        returnZip: true,
      );

      if (!mounted) return;

      // Set up inline PDF viewer if there's a PDF file
      final pdfFile = result.files
          .where((f) => f.mimeType == 'application/pdf')
          .firstOrNull;
      if (pdfFile != null) {
        final tmpPath = await _writeTempFile(pdfFile.name, pdfFile.bytes);
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openFile(tmpPath),
        );
      }

      setState(() {
        _result = result;
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('generated_qr_codes')),
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.save_alt),
              tooltip: LocServ.inst.t('save'),
              onPressed: () => _exportResult(context),
            ),
          buildAppBarMenuButton(),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: LocServ.inst.t('regenerate_pdf'),
                  onPressed: _isGenerating ? null : _generate,
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  tooltip: LocServ.inst.t('settings_qr_generation_settings'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsQrGenerationPage()),
                    );
                    if (autoRefreshQrAfterSettings && mounted) _generate();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: LocServ.inst.t('settings_pdf_output_settings'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsPdfOutputPage()),
                    );
                    if (autoRefreshQrAfterSettings && mounted) _generate();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content area
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isGenerating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(LocServ.inst.t('generating_pdf')),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${LocServ.inst.t('error')}: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_result == null) {
      return Center(child: Text(LocServ.inst.t('no_generated_files')));
    }

    // Show inline PDF if available
    if (_pdfController != null) {
      return PdfViewPinch(
        controller: _pdfController!,
        scrollDirection: Axis.vertical,
      );
    }

    return Center(child: Text(LocServ.inst.t('no_generated_files')));
  }

  // ignore: unused_element
  Future<void> _viewPdfInApp(BuildContext context, GeneratedFile f) async {
    try {
      final tmpPath = await _writeTempFile(f.name, f.bytes);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _InAppPdfViewer(filePath: tmpPath, title: f.name),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${LocServ.inst.t('error')}: $e')),
        );
      }
    }
  }

  Future<void> _exportResult(BuildContext context) async {
    final result = _result;
    if (result == null) return;

    try {
      // Prefer ZIP if available (images mode)
      if (result.zipBytes != null) {
        await _saveFileWithBytes(context, 'qr_codes.zip', result.zipBytes!);
        return;
      }

      // Single PDF or individual files
      if (result.files.length == 1) {
        final single = result.files.first;
        await _saveFileWithBytes(context, single.name, single.bytes);
        return;
      }

      // Multiple files without zip: save to directory (desktop only)
      if (Platform.isAndroid || Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final subDir = Directory('${dir.path}/qr_export');
        if (!subDir.existsSync()) subDir.createSync(recursive: true);
        for (final f in result.files) {
          await File('${subDir.path}/${f.name}').writeAsBytes(f.bytes);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${LocServ.inst.t('files_saved')}: ${subDir.path}')),
          );
        }
      } else {
        final dir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: LocServ.inst.t('choose_folder_save_files'),
        );
        if (dir == null) return;
        for (final f in result.files) {
          await File('$dir/${f.name}').writeAsBytes(f.bytes);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocServ.inst.t('files_saved'))),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${LocServ.inst.t('error')}: $e')),
        );
      }
    }
  }

  Future<void> _saveFileWithBytes(
    BuildContext context,
    String fileName,
    Uint8List bytes,
  ) async {
    final output = await FilePicker.platform.saveFile(
      dialogTitle: LocServ.inst.t('save'),
      fileName: fileName,
      bytes: bytes,
    );
    if (output != null && context.mounted) {
      if (!Platform.isAndroid && !Platform.isIOS) {
        await File(output).writeAsBytes(bytes);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${LocServ.inst.t('files_saved')}: $output')),
        );
      }
    }
  }

  Future<String> _writeTempFile(String name, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$name';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }
}

/// In-app PDF viewer using the pdfx package (same rendering as documentation files).
class _InAppPdfViewer extends StatefulWidget {
  final String filePath;
  final String title;

  const _InAppPdfViewer({required this.filePath, required this.title});

  @override
  State<_InAppPdfViewer> createState() => _InAppPdfViewerState();
}

class _InAppPdfViewerState extends State<_InAppPdfViewer> {
  PdfControllerPinch? _pdfController;

  @override
  void initState() {
    super.initState();
    try {
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.filePath),
      );
    } catch (_) {
      _pdfController = null;
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _pdfController == null
          ? Center(child: Text(LocServ.inst.t('error')))
          : PdfViewPinch(
              controller: _pdfController!,
              scrollDirection: Axis.vertical,
            ),
    );
  }
}
