import 'package:flutter/material.dart';
import 'package:speleo_loc/utils/constants.dart';
import 'package:speleo_loc/utils/localization.dart';
import 'package:speleo_loc/screens/settings/settings_helper.dart';

/// QR code generation settings subpage: sizes, colors, error correction, etc.
class SettingsQrGenerationPage extends StatefulWidget {
  const SettingsQrGenerationPage({super.key});

  @override
  State<SettingsQrGenerationPage> createState() =>
      _SettingsQrGenerationPageState();
}

class _SettingsQrGenerationPageState extends State<SettingsQrGenerationPage> {
  Map<String, dynamic>? _cfg;
  String _qrOutputKind = 'pdf';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await SettingsHelper.loadJsonConfig(
        qrGenerationConfigKey, _defaultQrConfig);
    final outputKind =
        await SettingsHelper.loadStringConfig('qr_output_kind', 'pdf');
    if (mounted) {
      setState(() {
        _cfg = cfg;
        _qrOutputKind = outputKind;
      });
    }
  }

  Future<void> _saveConfig(Map<String, dynamic> cfg) async {
    await SettingsHelper.saveJsonConfig(qrGenerationConfigKey, cfg);
  }

  Future<void> _saveOutputKind(String v) async {
    await SettingsHelper.saveStringConfig('qr_output_kind', v);
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
      appBar: AppBar(
        title: Text(LocServ.inst.t('settings_qr_generation')),
      ),
      body: ListView(
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
                child: TextFormField(
                  initialValue: cfg['qrBgColor']
                      .toRadixString(16)
                      .toUpperCase()
                      .replaceAll('0X', '0x'),
                  decoration: InputDecoration(
                      labelText: LocServ.inst.t('qr_bg_color')),
                  onChanged: (v) async {
                    try {
                      cfg['qrBgColor'] = int.parse(v);
                    } catch (_) {}
                    await _saveConfig(cfg);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: cfg['qrFgColor']
                      .toRadixString(16)
                      .toUpperCase()
                      .replaceAll('0X', '0x'),
                  decoration: InputDecoration(
                      labelText: LocServ.inst.t('qr_fg_color')),
                  onChanged: (v) async {
                    try {
                      cfg['qrFgColor'] = int.parse(v);
                    } catch (_) {}
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
          ),
        ],
      ),
    );
  }
}
