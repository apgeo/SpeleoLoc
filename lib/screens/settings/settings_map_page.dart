import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
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
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final registry = ref.read(mbTilesRegistryProvider);
    final (configJson, dir, files) = await (
      ref.read(configurationRepositoryProvider).readJson(
        mapMbtilesConfigKey,
        defaults: () => <String, dynamic>{},
      ),
      registry.ensureDirectory(),
      registry.scan(),
    ).wait;
    _config = MapMbTilesConfig.fromJson(configJson);
    _folderPath = dir.path;
    _files = files;
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _saveConfig(MapMbTilesConfig config) async {
    setState(() => _config = config);
    await ref
        .read(configurationRepositoryProvider)
        .writeJson(mapMbtilesConfigKey, config.toJson());
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    _files = await ref.read(mbTilesRegistryProvider).scan();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  /// Browses for a `.mbtiles` file via the system document picker and copies
  /// it into the scan folder. `FileType.any` (rather than an extension
  /// filter) keeps `.mbtiles` selectable on Android, whose picker may not
  /// know that MIME type; the extension is validated on import instead. The
  /// picker grants per-file access, so no storage permission is requested.
  Future<void> _importMbTiles() async {
    final FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(allowMultiple: false);
    } catch (e) {
      SnackBarService.showError(
        '${LocServ.inst.t('map_mbtiles_import_failed')}: $e',
      );
      return;
    }
    final sourcePath = picked?.files.single.path;
    if (sourcePath == null) return; // cancelled, or no accessible path
    await _copyIntoFolder(sourcePath, overwrite: false);
  }

  Future<void> _copyIntoFolder(
    String sourcePath, {
    required bool overwrite,
  }) async {
    final loc = LocServ.inst;
    setState(() => _importing = true);
    try {
      final descriptor = await ref
          .read(mbTilesRegistryProvider)
          .importFromPath(sourcePath, overwrite: overwrite);
      if (!mounted) return;
      // A valid but vector (pbf) file imports fine; warn since the map can
      // only render raster tiles (it is still listed, flagged unsupported).
      if (descriptor.metadata.isRaster) {
        SnackBarService.showSuccess(
          loc
              .t('map_mbtiles_import_success')
              .replaceAll('{name}', descriptor.fileName),
        );
      } else {
        SnackBarService.showWarning(
          loc
              .t('map_mbtiles_import_vector_warning')
              .replaceAll('{name}', descriptor.fileName),
        );
      }
      await _refresh();
    } on MbTilesImportException catch (e) {
      if (!mounted) return;
      switch (e.error) {
        case MbTilesImportError.wrongExtension:
          SnackBarService.showError(loc.t('map_mbtiles_import_wrong_type'));
        case MbTilesImportError.notReadable:
          SnackBarService.showError(loc.t('map_mbtiles_import_unreadable'));
        case MbTilesImportError.alreadyExists:
          await _confirmAndOverwrite(sourcePath, e.fileName ?? '');
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError('${loc.t('map_mbtiles_import_failed')}: $e');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _confirmAndOverwrite(String sourcePath, String fileName) async {
    final loc = LocServ.inst;
    final overwrite = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('map_mbtiles_import_exists_title')),
        content: Text(
          loc
              .t('map_mbtiles_import_exists_message')
              .replaceAll('{name}', fileName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.t('map_mbtiles_import_overwrite')),
          ),
        ],
      ),
    );
    if (overwrite == true) {
      await _copyIntoFolder(sourcePath, overwrite: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('settings_map')),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: loc.t('map_mbtiles_import'),
            onPressed: (_loading || _importing) ? null : _importMbTiles,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.t('map_mbtiles_refresh'),
            onPressed: (_loading || _importing) ? null : _refresh,
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
                ListTile(
                  leading: _importing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_upload),
                  title: Text(loc.t('map_mbtiles_import')),
                  subtitle: Text(loc.t('map_mbtiles_import_desc')),
                  onTap: (_loading || _importing) ? null : _importMbTiles,
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
