import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/csv_import_page.dart';
import 'package:speleoloc/services/csv_cave_importer.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';

/// Screen for importing caves from CSV files.
///
/// Uses [CSVImportPage] to handle file selection and column mapping,
/// then processes the resulting data to import caves with deduplication.
class CSVCavesImportPage extends StatefulWidget {
  /// Maximum number of duplicate matches to preview (default 5).
  final int maxPreviewDuplicates;

  const CSVCavesImportPage({
    super.key,
    this.maxPreviewDuplicates = 5,
  });

  @override
  State<CSVCavesImportPage> createState() => _CSVCavesImportPageState();
}

class _CSVCavesImportPageState extends State<CSVCavesImportPage> {
  final CSVCaveImporter _importer =
      CSVCaveImporter(appDatabase, currentUserService);
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
          key: 'surface_area',
          label: LocServ.inst.t('csv_field_surface_area'),
        ),
      ];

  @override
  void initState() {
    super.initState();
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
      final config = CSVCavesImportConfig(
        caveNameColumn: csvResult.columnMappings['cave_name'],
        descriptionColumn: csvResult.columnMappings['description'],
        surfaceAreaColumn: csvResult.columnMappings['surface_area'],
        maxPreviewDuplicates: widget.maxPreviewDuplicates,
      );

      final rows = _importer.parseRows(csvResult.rawData, config);

      if (rows.isEmpty) {
        setState(() => _isProcessing = false);
        _showMessage(LocServ.inst.t('csv_no_valid_rows'));
        if (mounted) Navigator.pop(context);
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
          setState(() => _isProcessing = false);
          if (mounted) Navigator.pop(context);
          return;
        }
      }

      // Step 2: Import
      final importResult = await _importer.importRows(rows, config);

      setState(() => _isProcessing = false);

      if (!mounted) return;
      // Step 3: Show results
      await _showImportResultDialog(importResult);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showMessage('${LocServ.inst.t('error')}: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Show dialog listing existing matching caves, ask user to proceed.
  Future<bool?> _showExistingCavesDialog(
    List<CaveExistingMatch> matches,
    int totalCount,
  ) async {
    final previewCount =
        matches.length > widget.maxPreviewDuplicates ? widget.maxPreviewDuplicates : matches.length;
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
              ...preview.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${m.caveName}${m.surfaceArea != null ? ' (${m.surfaceArea})' : ''}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  )),
              if (totalCount > previewCount)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... ${LocServ.inst.t('and')} ${totalCount - previewCount} ${LocServ.inst.t('more')}',
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
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
            Text('${LocServ.inst.t('csv_caves_created')}: ${result.cavesCreated}'),
            Text('${LocServ.inst.t('csv_surface_areas_created')}: ${result.surfaceAreasCreated}'),
            Text('${LocServ.inst.t('csv_caves_skipped')}: ${result.skippedDuplicates}'),
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
