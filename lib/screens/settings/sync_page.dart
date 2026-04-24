import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

/// UI for the archive-based device-to-device sync.
///
/// Unlike `DataExportImportPage` (which ships the whole SQLite file +
/// assets as a backup/restore), this page produces a **row-level** sync
/// archive with last-writer-wins merge semantics on import.
class SyncPage extends ConsumerStatefulWidget {
  const SyncPage({super.key});

  @override
  ConsumerState<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends ConsumerState<SyncPage>
    with AppBarMenuMixin<SyncPage> {
  bool _busy = false;
  bool _includeDocumentationFiles = true;
  bool _includeRasterMaps = true;
  String? _lastMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('sync_title')),
        actions: [buildAppBarMenuButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            LocServ.inst.t('sync_description'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            LocServ.inst.t('export_settings'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: Text(LocServ.inst.t('include_documentation_files')),
            value: _includeDocumentationFiles,
            onChanged: _busy
                ? null
                : (v) => setState(() => _includeDocumentationFiles = v),
          ),
          SwitchListTile(
            title: Text(LocServ.inst.t('include_raster_maps')),
            value: _includeRasterMaps,
            onChanged:
                _busy ? null : (v) => setState(() => _includeRasterMaps = v),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: Text(LocServ.inst.t('sync_export')),
            onPressed: _busy ? null : _export,
          ),
          const Divider(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: Text(LocServ.inst.t('sync_import')),
            onPressed: _busy ? null : _import,
          ),
          const SizedBox(height: 24),
          if (_busy) const LinearProgressIndicator(),
          if (_lastMessage != null) ...[
            const SizedBox(height: 12),
            Text(_lastMessage!),
          ],
        ],
      ),
    );
  }

  Future<void> _export() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: LocServ.inst.t('sync_select_export_folder'),
    );
    if (dir == null) return;

    setState(() {
      _busy = true;
      _lastMessage = null;
    });
    try {
      final service = ref.read(syncArchiveServiceProvider);
      final file = await service.exportToZip(
        dir,
        includeDocumentationFiles: _includeDocumentationFiles,
        includeRasterMaps: _includeRasterMaps,
      );
      if (!mounted) return;
      setState(() {
        _lastMessage = '${LocServ.inst.t('sync_export_success')}: ${file.path}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastMessage = '${LocServ.inst.t('sync_export_failed')}: $e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      dialogTitle: LocServ.inst.t('sync_select_archive'),
    );
    final path = picked?.files.single.path;
    if (path == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('sync_import_confirm_title')),
        content: Text(LocServ.inst.t('sync_import_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('sync_import')),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _busy = true;
      _lastMessage = null;
    });
    try {
      final service = ref.read(syncArchiveServiceProvider);
      final SyncImportReport report = await service.importFromZip(path);
      if (!mounted) return;
      setState(() {
        _lastMessage =
            '${LocServ.inst.t('sync_import_success')}: '
            '+${report.rowsInserted} / ~${report.rowsUpdated} / '
            '-${report.deletesApplied} '
            '(${report.changeLogMerged} ${LocServ.inst.t('change_log')}, '
            '${report.filesCopied} ${LocServ.inst.t('files')})';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastMessage = '${LocServ.inst.t('sync_import_failed')}: $e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
