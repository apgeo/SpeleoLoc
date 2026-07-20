import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/services/map/map_mbtiles_config.dart';
import 'package:speleoloc/services/map/mbtiles_registry.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Surface-map settings: MBTiles auto-load toggle, the app-managed folder
/// the files are read from, and the per-file base/overlay role.
class SettingsMapPage extends ConsumerStatefulWidget {
  const SettingsMapPage({super.key});

  @override
  ConsumerState<SettingsMapPage> createState() => _SettingsMapPageState();
}

class _SettingsMapPageState extends ConsumerState<SettingsMapPage> {
  MapMbTilesConfig _config = const MapMbTilesConfig();
  List<MbTilesDescriptor> _files = [];
  String _folderPath = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final registry = ref.read(mbTilesRegistryProvider);
    _config = MapMbTilesConfig.fromJson(
      await SettingsHelper.loadJsonConfig(
        mapMbtilesConfigKey,
        () => <String, dynamic>{},
      ),
    );
    _folderPath = (await registry.ensureDirectory()).path;
    _files = await registry.scan();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _saveConfig(MapMbTilesConfig config) async {
    setState(() => _config = config);
    await SettingsHelper.saveJsonConfig(mapMbtilesConfigKey, config.toJson());
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    _files = await ref.read(mbTilesRegistryProvider).scan();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('settings_map')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.t('map_mbtiles_refresh'),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(loc.t('map_mbtiles_auto_load')),
                  subtitle: Text(loc.t('map_mbtiles_auto_load_desc')),
                  value: _config.autoLoad,
                  onChanged: (v) =>
                      unawaited(_saveConfig(_config.copyWith(autoLoad: v))),
                ),
                ListTile(
                  title: Text(loc.t('map_mbtiles_folder')),
                  subtitle: Text(_folderPath),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: loc.t('map_mbtiles_folder_copy'),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _folderPath),
                      );
                      SnackBarService.showInfo(
                        loc.t('map_mbtiles_folder_copied'),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    loc.t('map_mbtiles_folder_desc'),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    loc.t('map_mbtiles_files'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (_files.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      loc.t('map_mbtiles_none_found'),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                for (final file in _files) _buildFileTile(file),
              ],
            ),
    );
  }

  Widget _buildFileTile(MbTilesDescriptor file) {
    final loc = LocServ.inst;
    final meta = file.metadata;
    final zoomInfo = (meta.minZoom != null || meta.maxZoom != null)
        ? ' · z${meta.minZoom ?? '?'}–${meta.maxZoom ?? '?'}'
        : '';
    return ListTile(
      leading: Icon(
        meta.isRaster ? Icons.layers : Icons.block,
        color: meta.isRaster ? null : Colors.red[300],
      ),
      title: Text(file.displayName, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        meta.isRaster
            ? '${file.fileName} · ${meta.format}$zoomInfo'
            : '${file.fileName} · ${loc.t('map_mbtiles_unsupported_format')}',
      ),
      trailing: meta.isRaster
          ? DropdownButton<MbTilesRole>(
              value: _config.roleOf(file.fileName),
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(
                  value: MbTilesRole.base,
                  child: Text(loc.t('map_mbtiles_role_base')),
                ),
                DropdownMenuItem(
                  value: MbTilesRole.overlay,
                  child: Text(loc.t('map_mbtiles_role_overlay')),
                ),
              ],
              onChanged: (role) {
                if (role != null) {
                  unawaited(
                    _saveConfig(_config.withRole(file.fileName, role)),
                  );
                }
              },
            )
          : null,
    );
  }
}
