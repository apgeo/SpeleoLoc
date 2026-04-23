import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/csv_import_page.dart';
import 'package:speleoloc/services/csv_cave_place_importer.dart';
import 'package:speleoloc/utils/localization.dart';

/// Screen for importing cave place data from CSV files.
///
/// Uses [CSVImportPage] to handle file selection and column mapping,
/// then processes the resulting data to import cave places.
///
/// Pass [caveUuid] for single-cave import mode, or omit/null for multiple-cave mode.
class CSVCavePlacesImportPage extends StatefulWidget {
  /// If non-null, import is scoped to this single cave.
  final Uuid? caveUuid;

  /// Maximum number of duplicate matches to preview (default 5).
  final int maxPreviewDuplicates;

  const CSVCavePlacesImportPage({
    super.key,
    this.caveUuid,
    this.maxPreviewDuplicates = 5,
  });

  @override
  State<CSVCavePlacesImportPage> createState() => _CSVCavePlacesImportPageState();
}

class _CSVCavePlacesImportPageState extends State<CSVCavePlacesImportPage> {
  final CSVCavePlaceImporter _importer = CSVCavePlaceImporter(appDatabase);
  bool _isProcessing = false;
  bool _hasNavigated = false;

  bool get _isMultipleCaveMode => widget.caveUuid == null;

  List<CSVColumnDefinition> get _columnDefinitions => [
        if (_isMultipleCaveMode)
          CSVColumnDefinition(
            key: 'cave_name',
            label: LocServ.inst.t('csv_field_cave_name'),
            required: true,
          ),
        CSVColumnDefinition(
          key: 'place_name',
          label: LocServ.inst.t('csv_field_place_name'),
          required: true,
        ),
        CSVColumnDefinition(
          key: 'qr_code',
          label: LocServ.inst.t('csv_field_qr_code'),
        ),
        if (_isMultipleCaveMode)
          CSVColumnDefinition(
            key: 'cave_area',
            label: LocServ.inst.t('csv_field_cave_area'),
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

    final title = _isMultipleCaveMode
        ? LocServ.inst.t('csv_import_multiple')
        : LocServ.inst.t('csv_import_single');

    final result = await Navigator.push<CSVImportResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CSVImportPage(
          title: title,
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
      final config = CSVCavePlacesImportConfig(
        caveUuid: widget.caveUuid,
        caveNameColumn: _isMultipleCaveMode ? csvResult.columnMappings['cave_name'] : null,
        cavePlaceNameColumn: csvResult.columnMappings['place_name'],
        qrCodeColumn: csvResult.columnMappings['qr_code'],
        caveAreaColumn: _isMultipleCaveMode ? csvResult.columnMappings['cave_area'] : null,
        maxPreviewDuplicates: widget.maxPreviewDuplicates,
      );

      final rows = _importer.parseRows(csvResult.rawData, config);

      if (rows.isEmpty) {
        setState(() => _isProcessing = false);
        _showMessage(LocServ.inst.t('csv_no_valid_rows'));
        if (mounted) Navigator.pop(context);
        return;
      }

      // Step 1: Check existing combinations
      final existing = await _importer.findExistingCombinations(rows, config);
      if (existing.totalCount > 0) {
        if (!mounted) return;
        final proceed = await _showExistingCombinationsDialog(
          existing.matches,
          existing.totalCount,
        );
        if (proceed != true) {
          setState(() => _isProcessing = false);
          if (mounted) Navigator.pop(context);
          return;
        }
      }

      // Step 2: Check QR code conflicts
      bool overwriteQr = false;
      final qrConflicts = await _importer.findQrCodeConflicts(rows, config);
      if (qrConflicts.isNotEmpty) {
        if (!mounted) return;
        final result = await _showQrConflictDialog(qrConflicts);
        if (result == null) {
          setState(() => _isProcessing = false);
          if (mounted) Navigator.pop(context);
          return;
        }
        overwriteQr = result;
      }

      // Step 3: Import
      final importResult = await _importer.importRows(rows, config, overwriteQr: overwriteQr);

      setState(() => _isProcessing = false);

      if (!mounted) return;
      // Step 4: Show results
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

  /// Show dialog listing existing matching combinations, ask user to proceed.
  Future<bool?> _showExistingCombinationsDialog(
    List<CavePlaceExistingMatch> matches,
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
                      _isMultipleCaveMode
                          ? '• ${m.caveName} / ${m.caveArea ?? "-"} / ${m.cavePlaceName}'
                          : '• ${m.cavePlaceName}${m.existingQrCode != null ? " (QR: ${m.existingQrCode})" : ""}',
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

  /// Show dialog about QR code conflicts. Returns true if user wants to overwrite,
  /// false to skip QR updates, null if cancelled.
  Future<bool?> _showQrConflictDialog(List<CavePlaceExistingMatch> conflicts) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('csv_qr_conflicts')),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${LocServ.inst.t('csv_qr_conflict_count')}: ${conflicts.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...conflicts.take(widget.maxPreviewDuplicates).map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• QR ${c.existingQrCode} → ${c.cavePlaceName} (${c.caveName})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  )),
              if (conflicts.length > widget.maxPreviewDuplicates)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... ${LocServ.inst.t('and')} ${conflicts.length - widget.maxPreviewDuplicates} ${LocServ.inst.t('more')}',
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 12),
              Text(LocServ.inst.t('csv_overwrite_qr_question')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocServ.inst.t('csv_skip_qr')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocServ.inst.t('csv_overwrite_qr')),
          ),
        ],
      ),
    );
  }

  /// Show the import result summary.
  Future<void> _showImportResultDialog(CSVCavePlaceImportResult result) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('csv_import_complete')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isMultipleCaveMode)
              Text('${LocServ.inst.t('csv_caves_created')}: ${result.cavesCreated}'),
            Text('${LocServ.inst.t('csv_cave_areas_created')}: ${result.caveAreasCreated}'),
            Text('${LocServ.inst.t('csv_cave_places_created')}: ${result.cavePlacesCreated}'),
            Text('${LocServ.inst.t('csv_qr_codes_updated')}: ${result.qrCodesUpdated}'),
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
        title: Text(
          _isMultipleCaveMode
              ? LocServ.inst.t('csv_import_multiple')
              : LocServ.inst.t('csv_import_single'),
        ),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink(),
    );
  }
}
