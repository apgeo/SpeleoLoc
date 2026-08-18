import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/cave_document_directory_matcher.dart';
import 'package:speleoloc/services/cave_document_import_service.dart';
import 'package:speleoloc/services/storage/document_import_source.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// One reviewable row: a subdirectory of the chosen import folder and the cave
/// it will be attached to (auto-matched, user-overridable).
class _DirRow {
  _DirRow({
    required this.directory,
    required this.name,
    required this.fileCount,
    required this.selectedCaveUuid,
    required this.method,
  });

  final ImportDirectory directory;
  final String name;
  final int fileCount;

  /// `null` means "skip this directory".
  Uuid? selectedCaveUuid;
  CaveDirMatchMethod method;
}

/// Bulk-imports documents into caves from a chosen directory whose immediate
/// subdirectories each hold the files for one cave.
///
/// Launched from the HomePage toolbar with the caves currently in scope (all
/// visible, or the checked ones). Subdirectories are auto-matched to caves by
/// title or by a leading `<areaCode>-<caveCode>` token; anything unmatched is
/// left for the user to assign (or skip) before importing.
class CaveDocumentImportPage extends ConsumerStatefulWidget {
  const CaveDocumentImportPage({super.key, required this.caves});

  /// The caves in scope for this import (already filtered/selected upstream).
  final List<Cave> caves;

  @override
  ConsumerState<CaveDocumentImportPage> createState() =>
      _CaveDocumentImportPageState();
}

class _CaveDocumentImportPageState
    extends ConsumerState<CaveDocumentImportPage> {
  final _log = AppLogger.of('CaveDocumentImportPage');
  late final CaveDocumentImportService _service;
  late final List<Cave> _sortedCaves;

  bool _scanning = true;
  bool _importing = false;
  ImportRoot? _root;
  List<_DirRow> _rows = [];

  final ValueNotifier<int> _progress = ValueNotifier<int>(0);
  int _progressTotal = 0;

  @override
  void initState() {
    super.initState();
    _service = CaveDocumentImportService(
      ref.read(documentationRepositoryProvider),
      ref.read(changeLoggerProvider),
    );
    _sortedCaves = [...widget.caves]
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickAndScan());
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  //  Directory selection + matching
  // -----------------------------------------------------------------------

  Future<void> _pickAndScan() async {
    // The picker itself carries the read grant on Android (SAF), so no
    // storage permission request is needed before scanning.
    final ImportRoot? root;
    try {
      root = await const DocumentImportSourcePicker().pick(
        dialogTitle: LocServ.inst.t('import_docs_select_dir'),
      );
    } catch (e, st) {
      // A failing root listing (flaky DocumentsProvider, access denied)
      // must not strand the page on the scanning spinner.
      _log.warning('Failed to open import directory', e, st);
      if (!mounted) return;
      SnackBarService.showError('${LocServ.inst.t('error')}: $e');
      Navigator.pop(context);
      return;
    }
    if (!mounted) return;
    if (root == null) {
      Navigator.pop(context);
      return;
    }
    await _scan(root);
  }

  Future<void> _scan(ImportRoot root) async {
    setState(() {
      _root = root;
      _scanning = true;
    });

    try {
      final candidates = await _buildCandidates();
      final rows = <_DirRow>[];
      for (final dir in root.directories) {
        final name = dir.name;
        final fileCount = (await dir.listFiles()).length;
        final match = CaveDocumentDirectoryMatcher.match(name, candidates);
        rows.add(
          _DirRow(
            directory: dir,
            name: name,
            fileCount: fileCount,
            selectedCaveUuid: match.caveUuid,
            method: match.method,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _scanning = false;
      });
    } catch (e, st) {
      _log.warning('Failed to scan import directory', e, st);
      if (!mounted) return;
      setState(() => _scanning = false);
      SnackBarService.showError('${LocServ.inst.t('error')}: $e');
    }
  }

  /// Builds the match candidates: each scoped cave with its area code
  /// (`surface_areas.general_area_identifier`) and cave code
  /// (`caves.cave_local_index`).
  Future<List<CaveMatchCandidate>> _buildCandidates() async {
    final areas = await ref.read(caveRepositoryProvider).getSurfaceAreas();
    final areaCodeByUuid = {
      for (final a in areas) a.uuid: a.generalAreaIdentifier,
    };
    return [
      for (final c in widget.caves)
        CaveMatchCandidate(
          caveUuid: c.uuid,
          title: c.title,
          areaCode: c.surfaceAreaUuid != null
              ? areaCodeByUuid[c.surfaceAreaUuid]
              : null,
          caveCode: c.caveLocalIndex,
        ),
    ];
  }

  // -----------------------------------------------------------------------
  //  Import
  // -----------------------------------------------------------------------

  List<_DirRow> get _selectableRows =>
      _rows.where((r) => r.selectedCaveUuid != null && r.fileCount > 0).toList();

  /// Subdirectories were found but none of them shows any file — on Android
  /// this is the storage-permission symptom, so the page offers remedies
  /// instead of just sitting fully disabled.
  bool get _allRowsEmpty =>
      _rows.isNotEmpty && _rows.every((r) => r.fileCount == 0);

  Future<void> _runImport() async {
    if (_importing) return;
    final rows = _selectableRows;
    if (rows.isEmpty) {
      SnackBarService.showWarning(LocServ.inst.t('import_docs_no_selection'));
      return;
    }

    // Flip the guard before the first await: it disarms the Run button and
    // PopScope, so the re-list below cannot race a second run or outlive a
    // popped route.
    _progress.value = 0;
    _progressTotal = 0;
    setState(() => _importing = true);

    // Re-list each directory now so the progress total reflects the files
    // actually imported — the scan-time counts can be stale if the folder
    // changed between the review and pressing Run.
    final work = [
      for (final row in rows)
        (row: row, files: await row.directory.listFiles()),
    ];
    if (!mounted) return;
    setState(() {
      _progressTotal = work.fold(0, (sum, w) => sum + w.files.length);
    });

    var imported = 0;
    var skipped = 0;
    var failed = 0;
    var cavesTouched = 0;

    // SAF sources materialize into per-row temp directories, removed after
    // the run so the copies never outlive the import.
    final tempRoot = Directory(
      '${(await getTemporaryDirectory()).path}'
      '${Platform.pathSeparator}bulk_import',
    );
    try {
      for (final (index, w) in work.indexed) {
        final rowTempDir = Directory(
          '${tempRoot.path}${Platform.pathSeparator}$index',
        );
        await rowTempDir.create(recursive: true);
        final files = <File>[];
        for (final f in w.files) {
          try {
            files.add(await f.materialize(rowTempDir));
          } catch (e, st) {
            _log.warning('Could not read ${f.name}', e, st);
            failed++;
            if (mounted) _progress.value++;
          }
        }
        final outcome = await _service.importFilesToGeofeature(
          link: DocumentationGeofeatureLink(
            type: GeofeatureType.cave,
            geofeatureUuid: w.row.selectedCaveUuid!,
          ),
          files: files,
          compressImages: true,
          // The progress callback fires from an async loop; never touch the
          // notifier once the route (and _progress) has been disposed.
          onFileDone: () {
            if (mounted) _progress.value++;
          },
        );
        imported += outcome.imported;
        skipped += outcome.skippedDuplicates;
        failed += outcome.failed;
        if (outcome.imported > 0) cavesTouched++;
      }
    } catch (e, st) {
      // An unexpected failure must release _importing — PopScope would
      // otherwise trap the user on the importing view forever.
      _log.warning('Bulk import aborted', e, st);
      if (mounted) {
        setState(() => _importing = false);
        SnackBarService.showError('${LocServ.inst.t('error')}: $e');
      }
      return;
    } finally {
      try {
        if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
      } catch (e, st) {
        _log.fine('Could not remove bulk-import temp dir', e, st);
      }
    }

    if (!mounted) return;
    setState(() => _importing = false);
    await _showSummary(
      imported: imported,
      skipped: skipped,
      failed: failed,
      cavesTouched: cavesTouched,
    );
    if (mounted) Navigator.pop(context, imported > 0);
  }

  Future<void> _showSummary({
    required int imported,
    required int skipped,
    required int failed,
    required int cavesTouched,
  }) {
    final loc = LocServ.inst;
    String line(String key, int count) =>
        loc.t(key).replaceAll('{count}', '$count');
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('import_docs_summary_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(line('import_docs_summary_imported', imported)),
            Text(line('import_docs_summary_caves', cavesTouched)),
            Text(line('import_docs_summary_skipped', skipped)),
            if (failed > 0) Text(line('import_docs_summary_failed', failed)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.t('ok')),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  //  Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Block back-navigation while an import is running so the route (and the
    // _progress notifier the import writes to) can't be torn down mid-flight.
    return PopScope(
      canPop: !_importing,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(LocServ.inst.t('import_cave_documents')),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_scanning) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_importing) {
      return _buildImportingView();
    }
    if (_rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocServ.inst.t('import_docs_no_subdirs'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickAndScan,
                icon: const Icon(Icons.folder_open),
                label: Text(LocServ.inst.t('import_docs_select_dir_button')),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        if (_root != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.folder, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _root!.name,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (_allRowsEmpty) _buildZeroFilesBanner(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _rows.length,
            itemBuilder: (_, i) => _buildRow(_rows[i]),
          ),
        ),
        _buildActionBar(),
      ],
    );
  }

  /// Warning banner shown when subdirectories were found but every one of
  /// them scanned as empty — with actions to fix the usual (permission)
  /// cause and rescan.
  Widget _buildZeroFilesBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, size: 20, color: Colors.orange[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LocServ.inst.t('import_docs_zero_files_hint'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _root == null ? null : () => _scan(_root!),
                  child: Text(LocServ.inst.t('import_docs_rescan')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ValueListenableBuilder<int>(
          valueListenable: _progress,
          builder: (_, done, __) {
            final total = _progressTotal;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: total > 0 ? done / total : null,
                ),
                const SizedBox(height: 16),
                Text('${LocServ.inst.t('import_docs_importing')} $done / $total'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(_DirRow row) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _MethodChip(method: row.method),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              LocServ.inst
                  .t('import_docs_files_count')
                  .replaceAll('{count}', '${row.fileCount}'),
              style: TextStyle(
                fontSize: 12,
                // 0 files disables the row — make the reason visible.
                color: row.fileCount == 0
                    ? Colors.orange[800]
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<Uuid?>(
              initialValue: row.selectedCaveUuid,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              items: [
                DropdownMenuItem<Uuid?>(
                  value: null,
                  child: Text(
                    LocServ.inst.t('import_docs_skip_option'),
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                ..._sortedCaves.map(
                  (c) => DropdownMenuItem<Uuid?>(
                    value: c.uuid,
                    // Append the cave's local index so two caves that share a
                    // title (unique only within a surface area) are still
                    // distinguishable in the picker.
                    child: Text(
                      (c.caveLocalIndex != null && c.caveLocalIndex!.isNotEmpty)
                          ? '${c.title}  [${c.caveLocalIndex}]'
                          : c.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: row.fileCount == 0
                  ? null
                  : (v) => setState(() {
                      row.selectedCaveUuid = v;
                      row.method = v == null
                          ? CaveDirMatchMethod.unmatched
                          : CaveDirMatchMethod.manual;
                    }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    final selectable = _selectableRows;
    final fileTotal = selectable.fold<int>(0, (sum, r) => sum + r.fileCount);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                LocServ.inst
                    .t('import_docs_summary_pending')
                    .replaceAll('{files}', '$fileTotal')
                    .replaceAll('{caves}', '${selectable.length}'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: selectable.isEmpty ? null : _runImport,
              icon: const Icon(Icons.drive_folder_upload),
              label: Text(LocServ.inst.t('import_docs_run')),
            ),
          ],
        ),
      ),
    );
  }

}

/// Small badge showing how a directory was matched to its cave.
class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.method});

  final CaveDirMatchMethod method;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (method) {
      CaveDirMatchMethod.title => (
        LocServ.inst.t('import_docs_match_by_title'),
        Colors.green,
      ),
      CaveDirMatchMethod.code => (
        LocServ.inst.t('import_docs_match_by_code'),
        Colors.blue,
      ),
      CaveDirMatchMethod.manual => (
        LocServ.inst.t('import_docs_match_manual'),
        Colors.orange,
      ),
      CaveDirMatchMethod.unmatched => (
        LocServ.inst.t('import_docs_unmatched'),
        Colors.grey,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
