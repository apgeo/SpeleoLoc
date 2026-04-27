import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/dialogs/confirm_dialog.dart';
import 'package:speleoloc/services/data_archive_service.dart';
import 'package:speleoloc/services/data_export_import_repository.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/database_restore_helper.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// Full data export / import page.
///
/// Export: bundles the database + documentation files + raster-map images into
/// a zip archive.  Import: replace everything, or merge with conflict
/// resolution.
class DataExportImportPage extends StatefulWidget {
  const DataExportImportPage({super.key});

  @override
  State<DataExportImportPage> createState() => _DataExportImportPageState();
}

class _DataExportImportPageState extends State<DataExportImportPage>
    with AppBarMenuMixin<DataExportImportPage>, ProductTourMixin<DataExportImportPage> {
  @override
  String get tourId => 'data_export';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'list', titleLocKey: 'tour_data_export_list_title', bodyLocKey: 'tour_data_export_list_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_data_export_menu_title', bodyLocKey: 'tour_data_export_menu_body'),
  ];

  bool _includeDocFiles = true;
  bool _includeRasterMaps = true;
  bool _diffExport = false;
  bool _includeFtpPasswords = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('data_export_import')),
        actions: [KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton())],
      ),
      body: ListView(
        key: tourKeys['list'],
        padding: const EdgeInsets.all(16),
        children: [
          // -- Export section --
          Text(
            LocServ.inst.t('export_settings'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            title: Text(LocServ.inst.t('include_documentation_files')),
            value: _includeDocFiles,
            onChanged: (v) => setState(() => _includeDocFiles = v),
          ),
          SwitchListTile(
            title: Text(LocServ.inst.t('include_raster_maps')),
            value: _includeRasterMaps,
            onChanged: (v) => setState(() => _includeRasterMaps = v),
          ),
          SwitchListTile(
            title: Text(LocServ.inst.t('diff_export')),
            subtitle: Text(LocServ.inst.t('diff_export_desc')),
            value: _diffExport,
            onChanged: (v) => setState(() => _diffExport = v),
          ),
          if (exportFtpPasswordsEnabled)
            SwitchListTile(
              title: Text(LocServ.inst.t('export_ftp_passwords')),
              subtitle: Text(LocServ.inst.t('export_ftp_passwords_desc')),
              value: _includeFtpPasswords,
              onChanged: (v) => setState(() => _includeFtpPasswords = v),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.archive_outlined),
            label: Text(LocServ.inst.t('export_full_archive')),
            onPressed: () => _export(context),
          ),
          const Divider(height: 32),

          // -- Import section --
          Text(
            LocServ.inst.t('import_section'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.unarchive_outlined),
            label: Text(LocServ.inst.t('import_archive')),
            onPressed: () => _import(context),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  //  EXPORT
  // ===========================================================================

  Future<void> _export(BuildContext context) async {
    // Pick output directory.
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: LocServ.inst.t('select_folder_save_archive'),
    );
    if (dir == null) return;

    if (!context.mounted) return;

    final progressKey = GlobalKey<_ProgressDialogState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(key: progressKey),
    );

    try {
      final service =
          DataArchiveService(DataExportImportRepository(appDatabase));
      final outputPath = await service.exportArchive(
        settings: ExportSettings(
          includeDocumentationFiles: _includeDocFiles,
          includeRasterMaps: _includeRasterMaps,
          diffOnly: _diffExport,
          includeFtpPasswords: _includeFtpPasswords,
        ),
        outputDir: dir,
        onProgress: (msg) => progressKey.currentState?.updateMessage(msg),
        profileRepository: _includeFtpPasswords
            ? FtpProfileRepository(appDatabase)
            : null,
      );

      if (context.mounted) {
        Navigator.pop(context); // close progress
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${LocServ.inst.t('export_success')}: $outputPath')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocServ.inst.t('export_failed')}: $e')),
        );
      }
    }
  }

  // ===========================================================================
  //  IMPORT
  // ===========================================================================

  Future<void> _import(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (result == null || result.files.single.path == null) return;
    final zipPath = result.files.single.path!;

    if (!context.mounted) return;

    // Determine import mode.
    final repo = DataExportImportRepository(appDatabase);
    final hasData = await repo.hasData();
    if (!context.mounted) return;

    ImportMode mode;
    if (hasData) {
      final selected = await showDialog<ImportMode>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(LocServ.inst.t('import_mode_title')),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, ImportMode.replace),
              child: ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: Text(LocServ.inst.t('import_mode_replace')),
                subtitle: Text(LocServ.inst.t('import_mode_replace_desc')),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, ImportMode.merge),
              child: ListTile(
                leading: const Icon(Icons.merge),
                title: Text(LocServ.inst.t('import_mode_merge')),
                subtitle: Text(LocServ.inst.t('import_mode_merge_desc')),
              ),
            ),
          ],
        ),
      );
      if (selected == null) return;
      mode = selected;
    } else {
      mode = ImportMode.replace;
    }

    if (!context.mounted) return;

    if (mode == ImportMode.replace) {
      await _importReplace(context, zipPath);
    } else {
      await _importMerge(context, zipPath);
    }
  }

  // ---------------------------------------------------------------------------
  //  Replace import
  // ---------------------------------------------------------------------------

  Future<void> _importReplace(BuildContext context, String zipPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          ConfirmDialog(text: LocServ.inst.t('confirm_replace_import')),
    );
    if (confirmed != true || !context.mounted) return;

    final progressKey = GlobalKey<_ProgressDialogState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(key: progressKey),
    );

    try {
      final service =
          DataArchiveService(DataExportImportRepository(appDatabase));
      await service.importArchiveReplace(
        zipPath: zipPath,
        onProgress: (msg) => progressKey.currentState?.updateMessage(msg),
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocServ.inst.t('import_success'))),
        );
      }

      await DatabaseRestoreHelper.restartApplication();
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${LocServ.inst.t('import_failed')}: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  //  Merge import
  // ---------------------------------------------------------------------------

  Future<void> _importMerge(BuildContext context, String zipPath) async {
    final progressKey = GlobalKey<_ProgressDialogState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(key: progressKey),
    );

    final batchState = _BatchResolverState();

    Future<ConflictAction?> resolver(ImportConflict conflict) async {
      if (batchState.cancelled) return null;
      if (batchState.batchAction != null) return batchState.batchAction;

      if (!context.mounted) return null;

      final result = await showDialog<_ConflictDialogResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ConflictResolutionDialog(conflict: conflict),
      );

      if (result == null || result.cancelled) {
        batchState.cancelled = true;
        return null;
      }

      if (result.applyToAll) batchState.batchAction = result.action;
      return result.action;
    }

    try {
      final service =
          DataArchiveService(DataExportImportRepository(appDatabase));
      final importResult = await service.importArchiveMerge(
        zipPath: zipPath,
        conflictResolver: resolver,
        onProgress: (msg) => progressKey.currentState?.updateMessage(msg),
      );

      if (context.mounted) {
        Navigator.pop(context); // close progress
        _showImportResult(context, importResult);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        if (batchState.cancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocServ.inst.t('import_cancelled'))),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('${LocServ.inst.t('import_failed')}: $e')),
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  //  Import result dialog
  // ---------------------------------------------------------------------------

  void _showImportResult(BuildContext context, ImportResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('import_result_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _resultRow(LocServ.inst.t('import_records_imported'),
                  result.recordsImported),
              _resultRow(LocServ.inst.t('import_records_skipped'),
                  result.recordsSkipped),
              _resultRow(LocServ.inst.t('import_records_overwritten'),
                  result.recordsOverwritten),
              _resultRow(
                  LocServ.inst.t('import_files_copied'), result.filesCopied),
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(LocServ.inst.t('import_warnings'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...result.warnings.take(10).map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(w,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.orange)),
                    )),
                if (result.warnings.length > 10)
                  Text(
                      '... ${LocServ.inst.t('and')} ${result.warnings.length - 10} ${LocServ.inst.t('more')}',
                      style: const TextStyle(fontSize: 11)),
              ],
            ],
          ),
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

  Widget _resultRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(count.toString())],
      ),
    );
  }
}

// =============================================================================
//  Progress dialog (stateful – message updated externally via GlobalKey)
// =============================================================================

class _ProgressDialog extends StatefulWidget {
  const _ProgressDialog({super.key});
  @override
  _ProgressDialogState createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  String _message = '';

  void updateMessage(String message) {
    if (mounted) setState(() => _message = message);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_message),
        ],
      ),
    );
  }
}

// =============================================================================
//  Conflict resolution dialog
// =============================================================================

class _BatchResolverState {
  ConflictAction? batchAction;
  bool cancelled = false;
}

class _ConflictDialogResult {
  final ConflictAction action;
  final bool applyToAll;
  final bool cancelled;

  _ConflictDialogResult({
    required this.action,
    this.applyToAll = false,
  }) : cancelled = false;

  _ConflictDialogResult.cancel()
      : action = ConflictAction.skip,
        applyToAll = false,
        cancelled = true;
}

class _ConflictResolutionDialog extends StatelessWidget {
  final ImportConflict conflict;

  const _ConflictResolutionDialog({required this.conflict});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocServ.inst
          .t('conflict_in', {'table': conflict.humanTableName})),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${LocServ.inst.t('conflict_columns')}: ${conflict.conflictingColumns.join(', ')}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(LocServ.inst.t('conflict_existing'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              _RecordCard(record: conflict.existingRecord),
              const SizedBox(height: 8),
              Text(LocServ.inst.t('conflict_imported'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              _RecordCard(record: conflict.importedRecord),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
              context, _ConflictDialogResult(action: ConflictAction.skip)),
          child: Text(LocServ.inst.t('skip')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context,
              _ConflictDialogResult(action: ConflictAction.overwrite)),
          child: Text(LocServ.inst.t('overwrite')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
              context,
              _ConflictDialogResult(
                  action: ConflictAction.skip, applyToAll: true)),
          child: Text(LocServ.inst.t('skip_all')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
              context,
              _ConflictDialogResult(
                  action: ConflictAction.overwrite, applyToAll: true)),
          child: Text(LocServ.inst.t('overwrite_all')),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, _ConflictDialogResult.cancel()),
          child: Text(
            LocServ.inst.t('cancel_import'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    // Show key fields compactly, skipping metadata.
    final entries = record.entries
        .where((e) =>
            e.key != 'id' &&
            e.key != 'created_at' &&
            e.key != 'updated_at' &&
            e.key != 'deleted_at' &&
            e.value != null)
        .take(8)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries
              .map((e) => Text('${e.key}: ${e.value}',
                  style: const TextStyle(fontSize: 12)))
              .toList(),
        ),
      ),
    );
  }
}
