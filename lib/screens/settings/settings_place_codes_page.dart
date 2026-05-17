import 'package:flutter/material.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/place_code/qcri_hasher.dart';
import 'package:speleoloc/services/place_code/batch/place_code_batch_runner.dart';
import 'package:speleoloc/services/place_code/strategies/global_hierarchical_strategy.dart';
import 'package:speleoloc/services/place_code/strategies/per_area_sequential_strategy.dart';
import 'package:speleoloc/services/place_code/strategies/per_cave_sequential_strategy.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/place_code_batch_ui.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// Settings sub-page for Place Code Identifier (PCI) and
/// QR Code Resource Identifier (QCRI) configuration.
class SettingsPlaceCodesPage extends StatefulWidget {
  const SettingsPlaceCodesPage({super.key});

  @override
  State<SettingsPlaceCodesPage> createState() => _SettingsPlaceCodesPageState();
}

class _SettingsPlaceCodesPageState extends State<SettingsPlaceCodesPage>
    with
        AppBarMenuMixin<SettingsPlaceCodesPage>,
        ProductTourMixin<SettingsPlaceCodesPage> {
  @override
  String get tourId => 'settings_place_codes';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [];

  bool _loading = true;
  String _strategyId = GlobalHierarchicalStrategy.strategyId;
  Map<String, dynamic> _strategyConfigs = {};
  String _qcriMode = 'mirror';
  int _qcriLength = 8;
  bool _qcriEntranceHash = false;
  String _qcriSalt = '';
  late final TextEditingController _saltController;

  static const _strategies = [
    GlobalHierarchicalStrategy.strategyId,
    PerCaveSequentialStrategy.strategyId,
    PerAreaSequentialStrategy.strategyId,
  ];

  @override
  void initState() {
    super.initState();
    _saltController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _saltController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final strategy = await SettingsHelper.loadStringConfig(
        ConfigKey.placeCodeStrategy, GlobalHierarchicalStrategy.strategyId);
    final blob = await SettingsHelper.loadJsonConfig(
        ConfigKey.placeCodeStrategyConfig, () => <String, dynamic>{});
    final mode =
        await SettingsHelper.loadStringConfig(ConfigKey.qcriMode, 'mirror');
    final hashCfg = await SettingsHelper.loadJsonConfig(
        ConfigKey.qcriHashConfig, () => <String, dynamic>{'length': 8});
    if (!mounted) return;
    setState(() {
      _strategyId =
          _strategies.contains(strategy) ? strategy : _strategies.first;
      _strategyConfigs = Map<String, dynamic>.from(blob);
      _qcriMode = mode == 'hash' ? 'hash' : 'mirror';
      final n = (hashCfg['length'] is num)
          ? (hashCfg['length'] as num).toInt()
          : 8;
      _qcriLength = n.clamp(QcriHasher.minLength, QcriHasher.maxLength);
      _qcriEntranceHash = (hashCfg['entrance_hash'] is bool)
          ? hashCfg['entrance_hash'] as bool
          : false;
      _qcriSalt = (hashCfg['salt'] is String) ? (hashCfg['salt'] as String) : '';
      _saltController.text = _qcriSalt;
      _loading = false;
    });
  }

  Map<String, dynamic> _currentStrategyConfig() {
    final v = _strategyConfigs[_strategyId];
    if (v is Map) return Map<String, dynamic>.from(v);
    return _defaultStrategyConfig(_strategyId);
  }

  Map<String, dynamic> _defaultStrategyConfig(String id) {
    switch (id) {
      case PerCaveSequentialStrategy.strategyId:
      case PerAreaSequentialStrategy.strategyId:
        return {
          'start_at': 1,
          'step': 1,
          'zero_pad_width': 3,
          'main_entrance_first': false,
        };
      case GlobalHierarchicalStrategy.strategyId:
      default:
        return {
          'country_code': '',
          'organization_code': '',
          'general_area_identifier_width': 3,
          'cave_local_index_width': 3,
          'cave_place_local_index_width': 3,
          'main_entrance_suffix': '0',
          'segment_separator': '',
          'allow_non_digit': false,
        };
    }
  }

  Future<void> _saveStrategyId(String id) async {
    await SettingsHelper.saveStringConfig(
      ConfigKey.placeCodeStrategy,
      id,
      isSynced: true,
    );
    setState(() => _strategyId = id);
  }

  Future<void> _saveStrategyConfigField(String key, dynamic value) async {
    final cfg = _currentStrategyConfig();
    cfg[key] = value;
    final blob = Map<String, dynamic>.from(_strategyConfigs);
    blob[_strategyId] = cfg;
    await SettingsHelper.saveJsonConfig(
      ConfigKey.placeCodeStrategyConfig,
      blob,
      isSynced: true,
    );
    setState(() => _strategyConfigs = blob);
  }

  Future<void> _saveQcriMode(String mode) async {
    await SettingsHelper.saveStringConfig(
      ConfigKey.qcriMode,
      mode,
      isSynced: true,
    );
    setState(() => _qcriMode = mode);
  }

  Future<void> _saveQcriLength(int length) async {
    await SettingsHelper.saveJsonConfig(
      ConfigKey.qcriHashConfig,
      {'length': length, 'entrance_hash': _qcriEntranceHash, 'salt': _qcriSalt},
      isSynced: true,
    );
    setState(() => _qcriLength = length);
  }

  Future<void> _saveQcriEntranceHash(bool v) async {
    await SettingsHelper.saveJsonConfig(
      ConfigKey.qcriHashConfig,
      {'length': _qcriLength, 'entrance_hash': v, 'salt': _qcriSalt},
      isSynced: true,
    );
    setState(() => _qcriEntranceHash = v);
  }

  Future<void> _saveQcriSalt(String salt) async {
    await SettingsHelper.saveJsonConfig(
      ConfigKey.qcriHashConfig,
      {'length': _qcriLength, 'entrance_hash': _qcriEntranceHash, 'salt': salt},
      isSynced: true,
    );
    setState(() => _qcriSalt = salt);
  }

  void _showStrategyInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('place_code_strategy_$_strategyId')),
        content: SingleChildScrollView(
          child: Text(
              LocServ.inst.t('place_code_strategy_${_strategyId}_long')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocServ.inst.t('ok')),
          ),
        ],
      ),
    );
  }

  Widget _strategyForm() {
    final cfg = _currentStrategyConfig();
    switch (_strategyId) {
      case PerCaveSequentialStrategy.strategyId:
      case PerAreaSequentialStrategy.strategyId:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _intField('start_at', cfg['start_at'] ?? 1),
            _intField('step', cfg['step'] ?? 1),
            _intField('zero_pad_width', cfg['zero_pad_width'] ?? 3),
            SwitchListTile(
              title: Text(LocServ.inst.t('main_entrance_first')),
              value: cfg['main_entrance_first'] == true,
              onChanged: (v) =>
                  _saveStrategyConfigField('main_entrance_first', v),
            ),
          ],
        );
      case GlobalHierarchicalStrategy.strategyId:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stringField('country_code', cfg['country_code'] ?? ''),
            _stringField('organization_code', cfg['organization_code'] ?? ''),
            _intField('general_area_identifier_width',
                cfg['general_area_identifier_width'] ?? 3),
            _intField('cave_local_index_width',
                cfg['cave_local_index_width'] ?? 3),
            _intField('cave_place_local_index_width',
                cfg['cave_place_local_index_width'] ?? 3),
            _stringField('main_entrance_suffix',
                cfg['main_entrance_suffix'] ?? '0'),
            _stringField(
                'segment_separator', cfg['segment_separator'] ?? ''),
            SwitchListTile(
              title: Text(LocServ.inst.t('allow_non_digit')),
              value: cfg['allow_non_digit'] == true,
              onChanged: (v) =>
                  _saveStrategyConfigField('allow_non_digit', v),
            ),
          ],
        );
    }
  }

  Widget _stringField(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(labelText: LocServ.inst.t(key)),
        onChanged: (v) => _saveStrategyConfigField(key, v),
      ),
    );
  }

  Widget _intField(String key, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        initialValue: value.toString(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: LocServ.inst.t(key)),
        onChanged: (v) {
          final parsed = int.tryParse(v.trim());
          if (parsed != null) _saveStrategyConfigField(key, parsed);
        },
      ),
    );
  }

  String _qcriPreview() {
    const sample = '040150001001';
    if (_qcriMode == 'hash' ||
        (_qcriMode == 'mirror' && _qcriEntranceHash)) {
      final hasher = const QcriHasher();
      try {
        return hasher.hash(sample, length: _qcriLength,
            userSalt: _qcriSalt.isEmpty ? null : _qcriSalt);
      } catch (_) {
        return sample;
      }
    }
    return sample;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(LocServ.inst.t('settings_place_codes'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        key: appMenuScaffoldKey,
        endDrawer: buildAppMenuEndDrawer(),
        appBar: AppBar(
          title: Text(LocServ.inst.t('settings_place_codes')),
          actions: [buildAppBarMenuButton()],
          bottom: TabBar(
            tabs: [
              Tab(text: LocServ.inst.t('place_code_tab_strategy')),
              Tab(text: LocServ.inst.t('place_code_tab_qcri')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStrategyTab(context),
            _buildQcriTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(LocServ.inst.t('place_code_strategy'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _strategyId,
          items: _strategies
              .map((id) => DropdownMenuItem<String>(
                    value: id,
                    child: Text(LocServ.inst.t('place_code_strategy_$id')),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) _saveStrategyId(v);
          },
        ),
        const SizedBox(height: 8),
        Text(
          LocServ.inst.t('place_code_strategy_${_strategyId}_short'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _showStrategyInfo,
            icon: const Icon(Icons.info_outline, size: 18),
            label: Text(LocServ.inst.t('place_code_strategy_more_info')),
          ),
        ),
        const Divider(height: 24),
        Text(LocServ.inst.t('place_code_strategy_rules'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _strategyForm(),
        const Divider(height: 24),
        ElevatedButton.icon(
          onPressed: () => PlaceCodeBatchUi.run(
            context,
            scope: const GlobalScope(),
            confirmTitle: LocServ.inst.t('generate_codes_dataset'),
            confirmBody:
                LocServ.inst.t('generate_codes_confirm_dataset'),
          ),
          icon: const Icon(Icons.auto_awesome),
          label: Text(LocServ.inst.t('generate_codes_dataset')),
        ),
      ],
    );
  }

  Widget _buildQcriTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(LocServ.inst.t('qcri_mode'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _qcriMode,
          items: [
            DropdownMenuItem(
              value: 'mirror',
              child: Text(LocServ.inst.t('qcri_mode_mirror')),
            ),
            DropdownMenuItem(
              value: 'hash',
              child: Text(LocServ.inst.t('qcri_mode_hash')),
            ),
          ],
          onChanged: (v) {
            if (v != null) _saveQcriMode(v);
          },
        ),
        if (_qcriMode == 'hash') ...[
          const SizedBox(height: 8),
          Text(
            '${LocServ.inst.t('qcri_hash_length')}: $_qcriLength',
          ),
          Slider(
            min: QcriHasher.minLength.toDouble(),
            max: QcriHasher.maxLength.toDouble(),
            divisions: QcriHasher.maxLength - QcriHasher.minLength,
            value: _qcriLength.toDouble(),
            label: _qcriLength.toString(),
            onChanged: (v) => setState(() => _qcriLength = v.round()),
            onChangeEnd: (v) => _saveQcriLength(v.round()),
          ),
        ],
        if (_qcriMode == 'mirror') ...[
          SwitchListTile(
            title: Text(LocServ.inst.t('qcri_entrance_hash_in_mirror_mode')),
            subtitle: Text(
                LocServ.inst.t('qcri_entrance_hash_in_mirror_mode_help')),
            value: _qcriEntranceHash,
            onChanged: _saveQcriEntranceHash,
          ),
          if (_qcriEntranceHash) ...[
            const SizedBox(height: 8),
            Text(
              '${LocServ.inst.t('qcri_hash_length')}: $_qcriLength',
            ),
            Slider(
              min: QcriHasher.minLength.toDouble(),
              max: QcriHasher.maxLength.toDouble(),
              divisions: QcriHasher.maxLength - QcriHasher.minLength,
              value: _qcriLength.toDouble(),
              label: _qcriLength.toString(),
              onChanged: (v) => setState(() => _qcriLength = v.round()),
              onChangeEnd: (v) => _saveQcriLength(v.round()),
            ),
          ],
        ],
        if (_qcriMode == 'hash' ||
            (_qcriMode == 'mirror' && _qcriEntranceHash)) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _saltController,
            decoration: InputDecoration(
              labelText: LocServ.inst.t('qcri_hash_salt'),
              helperText: LocServ.inst.t('qcri_hash_salt_help'),
              helperMaxLines: 3,
            ),
            onChanged: (v) => setState(() => _qcriSalt = v),
            onEditingComplete: () => _saveQcriSalt(_saltController.text.trim()),
            onTapOutside: (_) => _saveQcriSalt(_saltController.text.trim()),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          LocServ.inst
              .t('qcri_hash_example')
              .replaceAll('{pci}', '040150001001')
              .replaceAll('{qcri}', _qcriPreview()),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Divider(height: 24),
        OutlinedButton.icon(
          onPressed: () => PlaceCodeBatchUi.run(
            context,
            scope: const GlobalScope(),
            confirmTitle: LocServ.inst.t('recompute_all_qcris'),
            confirmBody: LocServ.inst.t('recompute_all_qcris_confirm'),
          ),
          icon: const Icon(Icons.refresh),
          label: Text(LocServ.inst.t('recompute_all_qcris')),
        ),
      ],
    );
  }
}
