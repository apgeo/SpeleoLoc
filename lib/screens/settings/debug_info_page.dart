import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/localization.dart';

class DebugInfoPage extends StatefulWidget {
  const DebugInfoPage({super.key});

  @override
  State<DebugInfoPage> createState() => _DebugInfoPageState();
}

class _DebugInfoPageState extends State<DebugInfoPage> {
  String? _dbPath;
  String? _dataDir;
  List<Configuration> _configs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dir = await getApplicationDocumentsDirectory();
    final configs =
        await appDatabase.select(appDatabase.configurations).get();
    if (!mounted) return;
    setState(() {
      _dataDir = dir.path;
      _dbPath = p.join(dir.path, 'speleo_loc.sqlite');
      _configs = configs;
      _loading = false;
    });
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await _load();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocServ.inst.t('debug_info_copied')),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _editConfig(Configuration config) async {
    final controller = TextEditingController(text: config.value ?? '');
    final saved = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(config.title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: LocServ.inst.t('debug_info_config_value'),
            border: const OutlineInputBorder(),
          ),
          maxLines: null,
          keyboardType: TextInputType.multiline,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocServ.inst.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(LocServ.inst.t('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null || !mounted) return;
    await appDatabase.update(appDatabase.configurations).replace(
          Configuration(
            id: config.id,
            title: config.title,
            value: saved.isEmpty ? null : saved,
            createdAt: config.createdAt,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    await _reload();
  }

  Future<void> _addConfig() async {
    final titleCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('debug_info_add_config')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: LocServ.inst.t('debug_info_config_key'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              decoration: InputDecoration(
                labelText: LocServ.inst.t('debug_info_config_value'),
                border: const OutlineInputBorder(),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('save')),
          ),
        ],
      ),
    );
    titleCtrl.dispose();
    valueCtrl.dispose();
    if (saved != true || titleCtrl.text.trim().isEmpty || !mounted) return;
    await appDatabase.into(appDatabase.configurations).insert(
          ConfigurationsCompanion.insert(
            title: titleCtrl.text.trim(),
            value: drift.Value(
                valueCtrl.text.isEmpty ? null : valueCtrl.text),
          ),
        );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocServ.inst.t('debug_info_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: LocServ.inst.t('debug_info_refresh'),
            onPressed: _reload,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addConfig,
        tooltip: LocServ.inst.t('debug_info_add_config'),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InfoCard(
                  label: LocServ.inst.t('debug_info_data_dir'),
                  value: _dataDir ?? '',
                  onCopy: () => _copyToClipboard(_dataDir ?? ''),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  label: LocServ.inst.t('debug_info_db_path'),
                  value: _dbPath ?? '',
                  onCopy: () => _copyToClipboard(_dbPath ?? ''),
                  extra: _dbPath != null
                      ? Text(
                          File(_dbPath!).existsSync()
                              ? LocServ.inst.t('debug_info_file_exists')
                              : LocServ.inst.t('debug_info_file_missing'),
                          style: TextStyle(
                            fontSize: 12,
                            color: File(_dbPath!).existsSync()
                                ? Colors.green
                                : Colors.red,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  LocServ.inst.t('debug_info_configurations'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_configs.isEmpty)
                  const Center(child: Text('—'))
                else
                  ..._configs.map(
                    (cfg) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          cfg.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          cfg.value ?? '(null)',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              tooltip: LocServ.inst.t('debug_info_copy_value'),
                              onPressed: () =>
                                  _copyToClipboard(cfg.value ?? ''),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: LocServ.inst.t('debug_info_edit_value'),
                              onPressed: () => _editConfig(cfg),
                            ),
                          ],
                        ),
                        onTap: () => _editConfig(cfg),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  final Widget? extra;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.onCopy,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: LocServ.inst.t('debug_info_copy_value'),
                  onPressed: onCopy,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            if (extra != null) ...[
              const SizedBox(height: 4),
              extra!,
            ],
          ],
        ),
      ),
    );
  }
}
