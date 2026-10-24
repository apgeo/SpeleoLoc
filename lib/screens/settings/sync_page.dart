import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/storage/saf_storage_service.dart';
import 'package:speleoloc/services/sync/sync_archive_service.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/sync_conflict_dialog.dart';

/// Import-time conflict resolution strategy picked by the user.
enum _ConflictMode {
  /// Silent last-writer-wins keyed on `updated_at`.
  auto,

  /// Prompt on every overwrite that actually changes user-visible fields.
  manual,
}

/// UI for the archive-based device-to-device sync.
///
/// Produces a row-level sync archive with last-writer-wins merge semantics
/// on import. Users can optionally switch to manual conflict resolution to
/// review each would-be overwrite before it is applied.
class SyncPage extends ConsumerStatefulWidget {
  const SyncPage({super.key, this.embedded = false});

  /// When `true`, the page renders only its body (no `Scaffold`, no
  /// `AppBar`, no end-drawer), so it can be embedded as a tab inside
  /// another page (e.g. the combined sync dashboard).
  final bool embedded;

  @override
  ConsumerState<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends ConsumerState<SyncPage>
    with AppBarMenuMixin<SyncPage> {
  bool _busy = false;
  bool _includeDocumentationFiles = true;
  bool _includeRasterMaps = true;
  _ConflictMode _conflictMode = _ConflictMode.auto;
  String? _lastMessage;

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody(context);
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('sync_title')),
        actions: [buildAppBarMenuButton()],
      ),
      body: _buildBody(context),
    );
  }

  /// The page body, exposed so the combined sync dashboard can host it
  /// inside a `TabBarView` without the surrounding `Scaffold`/`AppBar`.
  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          LocServ.inst.t('sync_description'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),

        // ---- Export --------------------------------------------------
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
          onChanged: _busy
              ? null
              : (v) => setState(() => _includeRasterMaps = v),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: Text(LocServ.inst.t('sync_export')),
          onPressed: _busy ? null : _export,
        ),
        const Divider(height: 32),

        // ---- Import --------------------------------------------------
        Text(
          LocServ.inst.t('sync_conflict_mode_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        RadioGroup<_ConflictMode>(
          groupValue: _conflictMode,
          onChanged: (v) {
            if (_busy || v == null) return;
            setState(() => _conflictMode = v);
          },
          child: Column(
            children: [
              RadioListTile<_ConflictMode>(
                title: Text(LocServ.inst.t('sync_conflict_mode_auto')),
                subtitle: Text(LocServ.inst.t('sync_conflict_mode_auto_desc')),
                value: _ConflictMode.auto,
                enabled: !_busy,
              ),
              RadioListTile<_ConflictMode>(
                title: Text(LocServ.inst.t('sync_conflict_mode_manual')),
                subtitle: Text(
                  LocServ.inst.t('sync_conflict_mode_manual_desc'),
                ),
                value: _ConflictMode.manual,
                enabled: !_busy,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
    );
  }

  // ---------------------------------------------------------------------------
  //  Export
  // ---------------------------------------------------------------------------

  Future<void> _export() async {
    String outputDir;
    if (Platform.isAndroid) {
      // Scoped storage: write to the app cache first, then hand the archive
      // to a user-picked destination via the system create-document dialog
      // (the dialog carries the write grant — no storage permission needed).
      outputDir = (await getTemporaryDirectory()).path;
    } else {
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: LocServ.inst.t('sync_select_export_folder'),
      );
      if (dir == null) return;
      outputDir = dir;
    }
    if (!mounted) return;

    setState(() {
      _busy = true;
      _lastMessage = null;
    });
    try {
      final service = ref.read(syncArchiveServiceProvider);
      final file = await service.exportToZip(
        outputDir,
        includeDocumentationFiles: _includeDocumentationFiles,
        includeRasterMaps: _includeRasterMaps,
      );
      String? shownLocation = file.path;
      if (Platform.isAndroid) {
        try {
          // Null when the user cancels the save dialog.
          shownLocation = await const SafStorageService().saveDocument(
            fileName: file.uri.pathSegments.last,
            mimeType: 'application/zip',
            sourcePath: file.path,
          );
        } finally {
          if (await file.exists()) await file.delete();
        }
      }
      if (!mounted) return;
      setState(() {
        _lastMessage = shownLocation == null
            ? null
            : '${LocServ.inst.t('sync_export_success')}: $shownLocation';
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

  // ---------------------------------------------------------------------------
  //  Import
  // ---------------------------------------------------------------------------

  Future<void> _import() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      dialogTitle: LocServ.inst.t('sync_select_archive'),
    );
    final path = picked?.files.single.path;
    if (path == null) return;

    if (!mounted) return;
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
    if (confirm != true || !mounted) return;

    setState(() {
      _busy = true;
      _lastMessage = null;
    });

    try {
      final service = ref.read(syncArchiveServiceProvider);
      final report = await service.importFromZip(
        path,
        conflictResolver: _conflictMode == _ConflictMode.manual
            ? promptingConflictResolver(context)
            : null,
      );
      if (!mounted) return;
      setState(() {
        _lastMessage =
            '${LocServ.inst.t('sync_import_success')}: '
            '+${report.rowsInserted} / ~${report.rowsUpdated} / '
            '-${report.deletesApplied} '
            '(${report.changeLogMerged} ${LocServ.inst.t('change_log')}, '
            '${report.filesCopied} ${LocServ.inst.t('files')})';
      });
    } on SyncImportCancelledException {
      if (!mounted) return;
      setState(() {
        _lastMessage = LocServ.inst.t('sync_import_cancelled');
      });
    } on SyncArchiveSchemaMismatchException catch (e) {
      if (!mounted) return;
      setState(() {
        _lastMessage =
            '${LocServ.inst.t('sync_import_failed')}: '
            '${_formatSchemaMismatch(e)}';
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

  /// Builds a user-facing message for a schema-mismatch error. When the
  /// archive is *newer*, instructs the user to update; when *older*, reports
  /// the schema gap so they know to re-export from the source device.
  String _formatSchemaMismatch(SyncArchiveSchemaMismatchException e) {
    final ver = e.archiveAppVersion ?? '?';
    final build = e.archiveAppBuildNumber == null
        ? ''
        : '+${e.archiveAppBuildNumber}';
    if (e.tooNew) {
      return LocServ.inst.t('sync_import_archive_too_new', {
        'version': '$ver$build',
        'archiveSchema': '${e.archiveSchemaVersion}',
        'localSchema': '${e.localSchemaVersion}',
      });
    }
    return LocServ.inst.t('sync_import_archive_too_old', {
      'archiveSchema': '${e.archiveSchemaVersion}',
      'localSchema': '${e.localSchemaVersion}',
    });
  }
}
