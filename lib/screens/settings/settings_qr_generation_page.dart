import 'package:flutter/material.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// QR code generation settings subpage: sizes, colors, error correction, label template, etc.
class SettingsQrGenerationPage extends StatefulWidget {
  const SettingsQrGenerationPage({super.key});

  @override
  State<SettingsQrGenerationPage> createState() =>
      _SettingsQrGenerationPageState();
}

class _SettingsQrGenerationPageState extends State<SettingsQrGenerationPage>
    with AppBarMenuMixin<SettingsQrGenerationPage>, ProductTourMixin<SettingsQrGenerationPage> {
  @override
  String get tourId => 'settings_qr_gen';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'list', titleLocKey: 'tour_settings_qr_gen_list_title', bodyLocKey: 'tour_settings_qr_gen_list_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_settings_qr_gen_menu_title', bodyLocKey: 'tour_settings_qr_gen_menu_body'),
  ];

  Map<String, dynamic>? _cfg;
  Map<String, dynamic>? _pdfCfg;
  String _qrOutputKind = 'pdf';
  late TextEditingController _templateController;
  final FocusNode _templateFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _templateController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _templateController.dispose();
    _templateFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cfg = await SettingsHelper.loadJsonConfig(
        qrGenerationConfigKey, _defaultQrConfig);
    final pdfCfg = await SettingsHelper.loadJsonConfig(
        pdfOutputConfigKey, _defaultPdfConfig);
    final outputKind =
        await SettingsHelper.loadStringConfig('qr_output_kind', 'pdf');
    if (mounted) {
      setState(() {
        _cfg = cfg;
        _pdfCfg = pdfCfg;
        _qrOutputKind = outputKind;
        _templateController.text = pdfCfg['labelTemplate'] ?? defaultLabelTemplate;
      });
    }
  }

  Future<void> _saveConfig(Map<String, dynamic> cfg) async {
    await SettingsHelper.saveJsonConfig(qrGenerationConfigKey, cfg);
  }

  Future<void> _savePdfConfig(Map<String, dynamic> cfg) async {
    await SettingsHelper.saveJsonConfig(pdfOutputConfigKey, cfg);
  }

  Future<void> _saveOutputKind(String v) async {
    await SettingsHelper.saveStringConfig('qr_output_kind', v);
  }

  static Map<String, dynamic> _defaultPdfConfig() {
    return {
      'gridColumns': 4,
      'gridRows': 5,
      'labelTemplate': defaultLabelTemplate,
    };
  }

  void _insertVariable(String variable) {
    final text = _templateController.text;
    final sel = _templateController.selection;
    final cursor = sel.isValid ? sel.baseOffset : text.length;
    final before = text.substring(0, cursor);
    final after = text.substring(cursor);
    final newText = '$before$variable$after';
    _templateController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + variable.length),
    );
    _templateFocusNode.requestFocus();
    final cfg = _pdfCfg;
    if (cfg != null) {
      cfg['labelTemplate'] = newText;
      _savePdfConfig(cfg);
    }
  }

  // -----------------------------------------------------------------------
  //  Color picker helpers
  // -----------------------------------------------------------------------

  /// Shows a simple RGB color-picker dialog and returns the chosen [Color],
  /// or `null` if the user cancelled.
  Future<Color?> _showColorPickerDialog(Color initial) {
    double r = initial.red.toDouble();
    double g = initial.green.toDouble();
    double b = initial.blue.toDouble();
    return showDialog<Color>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final picked = Color.fromARGB(255, r.round(), g.round(), b.round());
          return AlertDialog(
            title: Text(LocServ.inst.t('pick_color')),
            content: SizedBox(
              width: 260,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Preview swatch
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: picked,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // R slider
                  Row(children: [
                    const SizedBox(width: 12, child: Text('R', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                    Expanded(
                      child: Slider(
                        value: r,
                        min: 0,
                        max: 255,
                        activeColor: Colors.red,
                        onChanged: (v) => setS(() => r = v),
                      ),
                    ),
                    SizedBox(width: 32, child: Text(r.round().toString(), textAlign: TextAlign.end)),
                  ]),
                  // G slider
                  Row(children: [
                    const SizedBox(width: 12, child: Text('G', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                    Expanded(
                      child: Slider(
                        value: g,
                        min: 0,
                        max: 255,
                        activeColor: Colors.green,
                        onChanged: (v) => setS(() => g = v),
                      ),
                    ),
                    SizedBox(width: 32, child: Text(g.round().toString(), textAlign: TextAlign.end)),
                  ]),
                  // B slider
                  Row(children: [
                    const SizedBox(width: 12, child: Text('B', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                    Expanded(
                      child: Slider(
                        value: b,
                        min: 0,
                        max: 255,
                        activeColor: Colors.blue,
                        onChanged: (v) => setS(() => b = v),
                      ),
                    ),
                    SizedBox(width: 32, child: Text(b.round().toString(), textAlign: TextAlign.end)),
                  ]),
                  const SizedBox(height: 4),
                  // Hex preview
                  Text(
                    '#${picked.value.toRadixString(16).toUpperCase().padLeft(8, '0')}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(LocServ.inst.t('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, picked),
                child: Text(LocServ.inst.t('ok')),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds a color field row: a [TextFormField] for hex input plus a small
  /// colored swatch button that opens [_showColorPickerDialog].
  Widget _colorField({
    required String labelKey,
    required int colorValue,
    required void Function(int newValue) onChanged,
  }) {
    final color = Color(colorValue);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextFormField(
            key: ValueKey(colorValue),
            initialValue: colorValue
                .toRadixString(16)
                .toUpperCase()
                .replaceAll('0X', '0x'),
            decoration:
                InputDecoration(labelText: LocServ.inst.t(labelKey)),
            onChanged: (v) {
              try {
                onChanged(int.parse(v.startsWith('0x') ? v : '0x$v'));
              } catch (_) {}
            },
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: LocServ.inst.t('pick_color'),
          child: InkWell(
            onTap: () async {
              final picked = await _showColorPickerDialog(color);
              if (picked != null && mounted) {
                onChanged(picked.value);
                setState(() {});
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _variableChip(String variable, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: GestureDetector(
              onTap: variable.startsWith('@') || variable == '\\n'
                  ? () => _insertVariable(variable)
                  : null,
              child: Text(variable,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description,
                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic> _defaultQrConfig() {
    return {
      'imagePaddingPx': 24,
      'labelFontSize': 18.0,
      'labelFontFamily': 'Helvetica',
      'qrBgColor': 0xFFFFFFFF,
      'qrFgColor': 0xFF000000,
      'exportImagesAsZip': true,
      'dpi': 300,
      'includeTitle': true,
      'imageFormat': 'png',
      'qrSizePx': 400,
      'qrErrorCorrectionLevel': 'M',
      'pdfQrPaddingH': 2.0,
      'pdfQrPaddingV': 2.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    if (cfg == null) {
      return Scaffold(
        appBar: AppBar(title: Text(LocServ.inst.t('settings_qr_generation'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('settings_qr_generation')),
        actions: [KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton())],
      ),
      body: ListView(
        key: tourKeys['list'],
        padding: const EdgeInsets.all(16),
        children: [
          // QR output kind
          Row(
            children: [
              Text(LocServ.inst.t('qr_output')),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _qrOutputKind,
                items: [
                  DropdownMenuItem(
                      value: 'pdf', child: Text(LocServ.inst.t('pdf'))),
                  DropdownMenuItem(
                      value: 'images', child: Text(LocServ.inst.t('images'))),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  await _saveOutputKind(v);
                  if (mounted) setState(() => _qrOutputKind = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(LocServ.inst.t('qr_settings_title'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: cfg['qrSizePx'].toString(),
                  decoration: InputDecoration(
                      labelText: LocServ.inst.t('qr_size_px')),
                  keyboardType: TextInputType.number,
                  onChanged: (v) async {
                    cfg['qrSizePx'] = int.tryParse(v) ?? cfg['qrSizePx'];
                    await _saveConfig(cfg);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: cfg['imagePaddingPx'].toString(),
                  decoration: InputDecoration(
                      labelText: LocServ.inst.t('qr_image_padding_px')),
                  keyboardType: TextInputType.number,
                  onChanged: (v) async {
                    cfg['imagePaddingPx'] =
                        int.tryParse(v) ?? cfg['imagePaddingPx'];
                    await _saveConfig(cfg);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: cfg['labelFontSize'].toString(),
                  decoration: InputDecoration(
                      labelText: LocServ.inst.t('label_font_size')),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) async {
                    cfg['labelFontSize'] =
                        double.tryParse(v) ?? cfg['labelFontSize'];
                    await _saveConfig(cfg);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: cfg['labelFontFamily'].toString(),
                  decoration: InputDecoration(
                      labelText: LocServ.inst.t('label_font_family')),
                  onChanged: (v) async {
                    cfg['labelFontFamily'] = v;
                    await _saveConfig(cfg);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _colorField(
                  labelKey: 'qr_bg_color',
                  colorValue: cfg['qrBgColor'] as int,
                  onChanged: (v) async {
                    cfg['qrBgColor'] = v;
                    await _saveConfig(cfg);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _colorField(
                  labelKey: 'qr_fg_color',
                  colorValue: cfg['qrFgColor'] as int,
                  onChanged: (v) async {
                    cfg['qrFgColor'] = v;
                    await _saveConfig(cfg);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: cfg['dpi'].toString(),
                  decoration: InputDecoration(
                      labelText: LocServ.inst.t('dpi_quality')),
                  keyboardType: TextInputType.number,
                  onChanged: (v) async {
                    cfg['dpi'] = int.tryParse(v) ?? cfg['dpi'];
                    await _saveConfig(cfg);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: (cfg['qrErrorCorrectionLevel'] ?? 'M').toString(),
                  items: const [
                    DropdownMenuItem(value: 'L', child: Text('L')),
                    DropdownMenuItem(value: 'M', child: Text('M')),
                    DropdownMenuItem(value: 'Q', child: Text('Q')),
                    DropdownMenuItem(value: 'H', child: Text('H')),
                  ],
                  onChanged: (v) async {
                    cfg['qrErrorCorrectionLevel'] =
                        v ?? cfg['qrErrorCorrectionLevel'];
                    await _saveConfig(cfg);
                    if (mounted) setState(() {});
                  },
                  decoration: InputDecoration(
                      labelText: LocServ.inst.t('error_correction')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(LocServ.inst.t('export_images_zip')),
            value: cfg['exportImagesAsZip'] ?? true,
            onChanged: (v) async {
              cfg['exportImagesAsZip'] = v;
              await _saveConfig(cfg);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 8),
          Text(LocServ.inst.t('pdf_qr_padding'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: (cfg['pdfQrPaddingH'] ?? 2.0).toString(),
                  decoration: InputDecoration(
                      labelText: LocServ.inst.t('pdf_qr_padding_h')),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) async {
                    cfg['pdfQrPaddingH'] =
                        double.tryParse(v) ?? cfg['pdfQrPaddingH'];
                    await _saveConfig(cfg);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: (cfg['pdfQrPaddingV'] ?? 2.0).toString(),
                  decoration: InputDecoration(
                      labelText: LocServ.inst.t('pdf_qr_padding_v')),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) async {
                    cfg['pdfQrPaddingV'] =
                        double.tryParse(v) ?? cfg['pdfQrPaddingV'];
                    await _saveConfig(cfg);
                  },
                ),
              ),
            ],
          ),          const SizedBox(height: 24),
          // QR Label template section (stored in PDF output config)
          Text(LocServ.inst.t('qr_label_template'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_pdfCfg != null)
            TextFormField(
              controller: _templateController,
              focusNode: _templateFocusNode,
              decoration: InputDecoration(
                labelText: LocServ.inst.t('qr_label_template'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              minLines: 2,
              onChanged: (v) async {
                _pdfCfg!['labelTemplate'] = v;
                await _savePdfConfig(_pdfCfg!);
              },
            ),
          const SizedBox(height: 12),
          // Available variables
          Text(LocServ.inst.t('available_variables'),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          _variableChip('@place_title', LocServ.inst.t('var_place_title')),
          _variableChip('@description', LocServ.inst.t('var_description')),
          _variableChip('@cave_title', LocServ.inst.t('var_cave_title')),
          _variableChip('@area_title', LocServ.inst.t('var_area_title')),
          _variableChip('@place_qr_code_identifier',
              LocServ.inst.t('var_place_qr_code_identifier')),
          _variableChip('@depth', LocServ.inst.t('var_depth')),
          const Divider(height: 16),
          _variableChip('\\n', LocServ.inst.t('var_newline')),
          const Divider(height: 16),
          Text(LocServ.inst.t('template_formatting_help'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          _variableChip('#fz<number>', LocServ.inst.t('var_font_size_help')),
          _variableChip('#fc<color>', LocServ.inst.t('var_font_color_help')),
          const SizedBox(height: 8),
          Text(
            LocServ.inst.t('template_example'),
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),        ],
      ),
    );
  }
}
