import 'package:flutter/material.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// PDF output settings: grid layout (rows/columns per page).
class SettingsPdfOutputPage extends StatefulWidget {
  const SettingsPdfOutputPage({super.key});

  @override
  State<SettingsPdfOutputPage> createState() => _SettingsPdfOutputPageState();
}

class _SettingsPdfOutputPageState extends State<SettingsPdfOutputPage>
    with AppBarMenuMixin<SettingsPdfOutputPage>, ProductTourMixin<SettingsPdfOutputPage> {
  @override
  String get tourId => 'settings_pdf';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'list', titleLocKey: 'tour_settings_pdf_list_title', bodyLocKey: 'tour_settings_pdf_list_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_settings_pdf_menu_title', bodyLocKey: 'tour_settings_pdf_menu_body'),
  ];

  Map<String, dynamic>? _cfg;
  late TextEditingController _columnsController;
  late TextEditingController _rowsController;

  @override
  void initState() {
    super.initState();
    _columnsController = TextEditingController();
    _rowsController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
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
        _columnsController.text = (cfg['gridColumns'] ?? 4).toString();
        _rowsController.text = (cfg['gridRows'] ?? 5).toString();
      });
    }
  }

  static Map<String, dynamic> _defaultPdfConfig() {
    return {
      'gridColumns': 4,
      'gridRows': 5,
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
        actions: [KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton())],
      ),
      body: ListView(
        key: tourKeys['list'],
        padding: const EdgeInsets.all(16),
        children: [
          // Grid layout section
          Text(LocServ.inst.t('pdf_grid_layout'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildStepperRow(cfg),
        ],
      ),
    );
  }

  Widget _buildStepperRow(Map<String, dynamic> cfg) {
    return Row(
      children: [
        Expanded(
          child: _buildStepperField(
            controller: _columnsController,
            label: LocServ.inst.t('pdf_grid_columns'),
            min: 1,
            max: 10,
            configKey: 'gridColumns',
            cfg: cfg,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStepperField(
            controller: _rowsController,
            label: LocServ.inst.t('pdf_grid_rows'),
            min: 1,
            max: 20,
            configKey: 'gridRows',
            cfg: cfg,
          ),
        ),
      ],
    );
  }

  Widget _buildStepperField({
    required TextEditingController controller,
    required String label,
    required int min,
    required int max,
    required String configKey,
    required Map<String, dynamic> cfg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                final cur = int.tryParse(controller.text) ?? min;
                final next = (cur - 1).clamp(min, max);
                controller.text = next.toString();
                cfg[configKey] = next;
                _saveConfig(cfg);
                setState(() {});
              },
            ),
            SizedBox(
              width: 40,
              child: TextFormField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final val = (int.tryParse(v) ?? min).clamp(min, max);
                  cfg[configKey] = val;
                  _saveConfig(cfg);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                final cur = int.tryParse(controller.text) ?? min;
                final next = (cur + 1).clamp(min, max);
                controller.text = next.toString();
                cfg[configKey] = next;
                _saveConfig(cfg);
                setState(() {});
              },
            ),
          ],
        ),
      ],
    );
  }

}
