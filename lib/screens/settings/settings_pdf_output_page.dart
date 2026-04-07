import 'package:flutter/material.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

/// PDF output settings: grid layout (rows/columns), QR label template.
class SettingsPdfOutputPage extends StatefulWidget {
  const SettingsPdfOutputPage({super.key});

  @override
  State<SettingsPdfOutputPage> createState() => _SettingsPdfOutputPageState();
}

class _SettingsPdfOutputPageState extends State<SettingsPdfOutputPage>
    with AppBarMenuMixin<SettingsPdfOutputPage> {
  Map<String, dynamic>? _cfg;
  late TextEditingController _templateController;
  late TextEditingController _columnsController;
  late TextEditingController _rowsController;

  @override
  void initState() {
    super.initState();
    _templateController = TextEditingController();
    _columnsController = TextEditingController();
    _rowsController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _templateController.dispose();
    _columnsController.dispose();
    _rowsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cfg = await SettingsHelper.loadJsonConfig(
        pdfOutputConfigKey, _defaultPdfConfig);

    if (mounted) {
      setState(() {
        _cfg = cfg;
        _templateController.text = cfg['labelTemplate'] ?? defaultLabelTemplate;
        _columnsController.text = (cfg['gridColumns'] ?? 4).toString();
        _rowsController.text = (cfg['gridRows'] ?? 5).toString();
      });
    }
  }

  static Map<String, dynamic> _defaultPdfConfig() {
    return {
      'gridColumns': 4,
      'gridRows': 5,
      'labelTemplate': defaultLabelTemplate,
    };
  }

  Future<void> _saveConfig(Map<String, dynamic> cfg) async {
    await SettingsHelper.saveJsonConfig(pdfOutputConfigKey, cfg);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    if (cfg == null) {
      return Scaffold(
        appBar: AppBar(title: Text(LocServ.inst.t('settings_pdf_output'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('settings_pdf_output')),
        actions: [buildAppBarMenuButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Grid layout section
          Text(LocServ.inst.t('pdf_grid_layout'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _columnsController,
                  decoration: InputDecoration(
                      labelText: LocServ.inst.t('pdf_grid_columns')),
                  keyboardType: TextInputType.number,
                  onChanged: (v) async {
                    cfg['gridColumns'] = int.tryParse(v) ?? 4;
                    await _saveConfig(cfg);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _rowsController,
                  decoration: InputDecoration(
                      labelText: LocServ.inst.t('pdf_grid_rows')),
                  keyboardType: TextInputType.number,
                  onChanged: (v) async {
                    cfg['gridRows'] = int.tryParse(v) ?? 5;
                    await _saveConfig(cfg);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // QR Label template section
          Text(LocServ.inst.t('qr_label_template'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _templateController,
            decoration: InputDecoration(
              labelText: LocServ.inst.t('qr_label_template'),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            minLines: 2,
            onChanged: (v) async {
              cfg['labelTemplate'] = v;
              await _saveConfig(cfg);
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
          ),
        ],
      ),
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
            child: Text(variable,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
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
}
