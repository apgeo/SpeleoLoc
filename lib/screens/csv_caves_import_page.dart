import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/csv_import_page.dart';
import 'package:speleoloc/services/csv_cave_importer.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// User decision for one existing cave whose fields differ from the CSV.
enum _CaveUpdateChoice { update, skip, updateAll, skipAll }

/// Screen for importing caves from CSV files.
///
/// Uses [CSVImportPage] to handle file selection and column mapping,
/// then processes the resulting data to import caves with deduplication.
class CSVCavesImportPage extends ConsumerStatefulWidget {
  /// Maximum number of duplicate matches to preview (default 5).
  final int maxPreviewDuplicates;

  const CSVCavesImportPage({super.key, this.maxPreviewDuplicates = 5});

  @override
  ConsumerState<CSVCavesImportPage> createState() => _CSVCavesImportPageState();
}

class _CSVCavesImportPageState extends ConsumerState<CSVCavesImportPage> {
  late final CSVCaveImporter _importer;
  bool _isProcessing = false;
  bool _hasNavigated = false;

  List<CSVColumnDefinition> get _columnDefinitions => [
    CSVColumnDefinition(
      key: 'cave_name',
      label: LocServ.inst.t('csv_field_cave_name'),
      required: true,
    ),
    CSVColumnDefinition(
      key: 'description',
      label: LocServ.inst.t('csv_field_description'),
    ),
    CSVColumnDefinition(
      key: 'cave_local_index',
      label: LocServ.inst.t('cave_local_index'),
    ),
    CSVColumnDefinition(
      key: 'surface_area',
      label: LocServ.inst.t('csv_field_surface_area'),
    ),
    CSVColumnDefinition(
      key: 'general_area_identifier',
      label: LocServ.inst.t('general_area_identifier'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _importer = CSVCaveImporter(
      ref.read(appDatabaseProvider),
      ref.read(currentUserServiceProvider),
      ref.read(cavePlaceRepositoryProvider),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToCSVImport());
  }

  Future<void> _navigateToCSVImport() async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    final result = await Navigator.push<CSVImportResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CSVImportPage(
          title: LocServ.inst.t('csv_import_caves'),
          columnDefinitions: _columnDefinitions,
        ),
      ),
    );

    if (!mounted) return;

    if (result == null) {
      Navigator.pop(context);
      return;
    }

    await _processImport(result);
  }

  Future<void> _processImport(CSVImportResult csvResult) async {
    setState(() => _isProcessing = true);

    try {
      // Auto-add entrance cave place if setting is enabled (default: true)
      final autoAdd =
          await ref
              .read(configurationRepositoryProvider)
              .readString(autoAddEntrancePlaceKey) ??
          'true';

      final config = CSVCavesImportConfig(
        caveNameColumn: csvResult.columnMappings['cave_name'],
        descriptionColumn: csvResult.columnMappings['description'],
        caveLocalIndexColumn: csvResult.columnMappings['cave_local_index'],
        surfaceAreaColumn: csvResult.columnMappings['surface_area'],
        generalAreaIdentifierColumn:
            csvResult.columnMappings['general_area_identifier'],
        entrancePlaceTitle: autoAdd == 'true'
            ? LocServ.inst.t('entrance')
            : null,
        maxPreviewDuplicates: widget.maxPreviewDuplicates,
      );

      final rows = _importer.parseRows(csvResult.rawData, config);

      if (rows.isEmpty) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        _showMessage(LocServ.inst.t('csv_no_valid_rows'));
        Navigator.pop(context);
        return;
      }

      // Step 1: Check existing caves
      final existing = await _importer.findExistingCaves(rows, config);
      if (existing.totalCount > 0) {
        if (!mounted) return;
        final proceed = await _showExistingCavesDialog(
          existing.matches,
          existing.totalCount,
        );
        if (proceed != true) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          Navigator.pop(context);
          return;
        }
      }

      // Step 2: Ask, per matched cave with differing fields, whether to
      // update it (decided before the import transaction starts).
      final candidates = await _importer.planCaveUpdates(rows, config);
      final approved = <int>{};
      bool? applyToAll;
      for (var i = 0; i < candidates.length; i++) {
        bool update;
        if (applyToAll != null) {
          update = applyToAll;
        } else {
          if (!mounted) return;
          final choice = await _showCaveUpdateDialog(
            candidates[i],
            i + 1,
            candidates.length,
          );
          switch (choice) {
            case _CaveUpdateChoice.updateAll:
              applyToAll = update = true;
            case _CaveUpdateChoice.skipAll:
              applyToAll = update = false;
            case _CaveUpdateChoice.update:
              update = true;
            case _CaveUpdateChoice.skip:
            case null:
              update = false;
          }
        }
        if (update) approved.add(candidates[i].rowIndex);
      }

      // Step 3: Import
      final importResult = await _importer.importRows(
        rows,
        config,
        updateCandidates: candidates,
        approvedUpdates: approved,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);
      // Step 4: Show results
      await _showImportResultDialog(importResult);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showMessage('${LocServ.inst.t('error')}: $e');
      Navigator.pop(context);
    }
  }

  void _showMessage(String message) {
    SnackBarService.showInfo(message);
  }

  /// Show dialog listing existing matching caves, ask user to proceed.
  Future<bool?> _showExistingCavesDialog(
    List<CaveExistingMatch> matches,
    int totalCount,
  ) async {
    final previewCount = matches.length > widget.maxPreviewDuplicates
        ? widget.maxPreviewDuplicates
        : matches.length;
    final preview = matches.take(previewCount).toList();

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('csv_existing_combinations')),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${LocServ.inst.t('csv_found_existing')}: $totalCount',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...preview.map(
                (m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• ${m.caveName}${m.surfaceArea != null ? ' (${m.surfaceArea})' : ''}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              if (totalCount > previewCount)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... ${LocServ.inst.t('and')} ${totalCount - previewCount} ${LocServ.inst.t('more')}',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(LocServ.inst.t('csv_continue_import_question')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocServ.inst.t('yes')),
          ),
        ],
      ),
    );
  }

  String _fieldLabel(CSVCaveField field) => switch (field) {
    CSVCaveField.description => LocServ.inst.t('csv_field_description'),
    CSVCaveField.caveLocalIndex => LocServ.inst.t('cave_local_index'),
    CSVCaveField.surfaceArea => LocServ.inst.t('csv_field_surface_area'),
  };

  /// Ask whether to apply the differing CSV values to one existing cave.
  Future<_CaveUpdateChoice?> _showCaveUpdateDialog(
    CSVCaveUpdateCandidate candidate,
    int position,
    int total,
  ) {
    return showDialog<_CaveUpdateChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          '${LocServ.inst.t('csv_update_existing_cave')} ($position/$total)',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidate.caveLocalIndex != null
                    ? '${candidate.caveTitle} (${candidate.caveLocalIndex})'
                    : candidate.caveTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...candidate.changes.map(
                (change) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${_fieldLabel(change.field)}: '
                    '${change.oldValue ?? '—'} → ${change.newValue ?? '—'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _CaveUpdateChoice.skipAll),
            child: Text(LocServ.inst.t('csv_skip_all')),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _CaveUpdateChoice.updateAll),
            child: Text(LocServ.inst.t('csv_update_all')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _CaveUpdateChoice.skip),
            child: Text(LocServ.inst.t('csv_skip')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _CaveUpdateChoice.update),
            child: Text(LocServ.inst.t('csv_update')),
          ),
        ],
      ),
    );
  }

  /// Show the import result summary.
  Future<void> _showImportResultDialog(CSVCaveImportResult result) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('csv_import_complete')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${LocServ.inst.t('csv_caves_created')}: ${result.cavesCreated}',
            ),
            Text(
              '${LocServ.inst.t('csv_caves_updated')}: ${result.cavesUpdated}',
            ),
            Text(
              '${LocServ.inst.t('csv_surface_areas_created')}: ${result.surfaceAreasCreated}',
            ),
            Text(
              '${LocServ.inst.t('csv_caves_skipped')}: ${result.skippedDuplicates}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocServ.inst.t('ok')),
          ),
        ],
      ),
    );

    // Return true to signal that data was changed
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(LocServ.inst.t('csv_import_caves')),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink(),
    );
  }
}
