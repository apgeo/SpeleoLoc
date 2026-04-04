import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speleo_loc/data/source/database/app_database.dart';
import 'package:speleo_loc/services/csv_cave_place_importer.dart';
import 'package:speleo_loc/utils/localization.dart';

/// Screen for importing cave place data from CSV files.
///
/// Pass [caveId] for single-cave import mode, or omit/null for multiple-cave mode.
class CSVCavePlaceImportPage extends StatefulWidget {
  /// If non-null, import is scoped to this single cave.
  final int? caveId;

  /// Maximum number of duplicate matches to preview (default 5).
  final int maxPreviewDuplicates;

  const CSVCavePlaceImportPage({
    super.key,
    this.caveId,
    this.maxPreviewDuplicates = 5,
  });

  @override
  State<CSVCavePlaceImportPage> createState() => _CSVCavePlaceImportPageState();
}

class _CSVCavePlaceImportPageState extends State<CSVCavePlaceImportPage> {
  final CSVCavePlaceImporter _importer = CSVCavePlaceImporter(appDatabase);

  // CSV data
  String? _filePath;
  List<List<dynamic>>? _csvData;
  List<String> _headers = [];

  // Column mappings (null = "none" / not imported)
  int? _caveNameColumnIndex;
  int? _cavePlaceNameColumnIndex;
  int? _qrCodeColumnIndex;
  int? _caveAreaColumnIndex;

  // State
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isMultipleCaveMode => widget.caveId == null;

  /// Build the import config from current selections.
  CSVImportConfig _buildConfig() {
    return CSVImportConfig(
      caveId: widget.caveId,
      caveNameColumn: _isMultipleCaveMode ? _caveNameColumnIndex : null,
      cavePlaceNameColumn: _cavePlaceNameColumnIndex,
      qrCodeColumn: _qrCodeColumnIndex,
      caveAreaColumn: _isMultipleCaveMode ? _caveAreaColumnIndex : null,
      maxPreviewDuplicates: widget.maxPreviewDuplicates,
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );
      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final file = File(path);
      final content = await file.readAsString(encoding: utf8);
      final csvData = _importer.parseCSV(content);

      if (csvData.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = LocServ.inst.t('csv_file_empty');
        });
        return;
      }

      final headers = _importer.getHeaders(csvData);

      setState(() {
        _filePath = path;
        _csvData = csvData;
        _headers = headers;
        _caveNameColumnIndex = null;
        _cavePlaceNameColumnIndex = null;
        _qrCodeColumnIndex = null;
        _caveAreaColumnIndex = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '${LocServ.inst.t('error')}: $e';
      });
    }
  }

  Future<void> _startImport() async {
    if (_csvData == null) return;

    // Validate that at least cave place name column is mapped
    if (_cavePlaceNameColumnIndex == null) {
      _showMessage(LocServ.inst.t('csv_place_name_required'));
      return;
    }

    // In multiple cave mode, cave name column is required
    if (_isMultipleCaveMode && _caveNameColumnIndex == null) {
      _showMessage(LocServ.inst.t('csv_cave_name_required'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = _buildConfig();
      final rows = _importer.parseRows(_csvData!, config);

      if (rows.isEmpty) {
        setState(() => _isLoading = false);
        _showMessage(LocServ.inst.t('csv_no_valid_rows'));
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
          setState(() => _isLoading = false);
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
          // User cancelled
          setState(() => _isLoading = false);
          return;
        }
        overwriteQr = result;
      }

      // Step 3: Import
      final importResult = await _importer.importRows(rows, config, overwriteQr: overwriteQr);

      setState(() => _isLoading = false);

      if (!mounted) return;
      // Step 4: Show results
      await _showImportResultDialog(importResult);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '${LocServ.inst.t('error')}: $e';
      });
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
    List<ExistingMatch> matches,
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
  Future<bool?> _showQrConflictDialog(List<ExistingMatch> conflicts) async {
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
  Future<void> _showImportResultDialog(CSVImportResult result) async {
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

  /// Build the dropdown items for column selection, including a "None" option.
  List<DropdownMenuItem<int?>> _buildColumnDropdownItems() {
    return [
      DropdownMenuItem<int?>(
        value: null,
        child: Text(LocServ.inst.t('none')),
      ),
      ..._headers.asMap().entries.map(
            (e) => DropdownMenuItem<int?>(
              value: e.key,
              child: Text(e.value),
            ),
          ),
    ];
  }

  Widget _buildMappingRow(String label, int? currentValue, ValueChanged<int?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int?>(
              initialValue: currentValue,
              items: _buildColumnDropdownItems(),
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isMultipleCaveMode
        ? LocServ.inst.t('csv_import_multiple')
        : LocServ.inst.t('csv_import_single');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File selection section
                  Text(
                    LocServ.inst.t('csv_file_requirements'),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.file_open),
                        label: Text(LocServ.inst.t('csv_select_file')),
                      ),
                      if (_filePath != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _filePath!.split(Platform.pathSeparator).last,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],

                  // Column mappings section (visible after file is loaded)
                  if (_csvData != null && _headers.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      LocServ.inst.t('csv_column_mappings'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${LocServ.inst.t('csv_rows_found')}: ${_csvData!.length - 1}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),

                    // Cave name mapping (only in multiple cave mode)
                    if (_isMultipleCaveMode)
                      _buildMappingRow(
                        LocServ.inst.t('csv_field_cave_name'),
                        _caveNameColumnIndex,
                        (v) => setState(() => _caveNameColumnIndex = v),
                      ),

                    // Cave place name mapping
                    _buildMappingRow(
                      LocServ.inst.t('csv_field_place_name'),
                      _cavePlaceNameColumnIndex,
                      (v) => setState(() => _cavePlaceNameColumnIndex = v),
                    ),

                    // QR code mapping
                    _buildMappingRow(
                      LocServ.inst.t('csv_field_qr_code'),
                      _qrCodeColumnIndex,
                      (v) => setState(() => _qrCodeColumnIndex = v),
                    ),

                    // Cave area mapping (only in multiple cave mode)
                    if (_isMultipleCaveMode)
                      _buildMappingRow(
                        LocServ.inst.t('csv_field_cave_area'),
                        _caveAreaColumnIndex,
                        (v) => setState(() => _caveAreaColumnIndex = v),
                      ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Import button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _startImport,
                        icon: const Icon(Icons.download),
                        label: Text(LocServ.inst.t('csv_start_import')),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        ),
                      ),
                    ),

                    // Data preview
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      LocServ.inst.t('csv_data_preview'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDataPreview(),
                  ],
                ],
              ),
            ),
    );
  }

  /// Build a small scrollable preview table of the CSV data.
  Widget _buildDataPreview() {
    if (_csvData == null || _csvData!.isEmpty) return const SizedBox.shrink();

    final previewRows = _csvData!.take(11).toList(); // header + up to 10 rows
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        columns: _headers
            .map((h) => DataColumn(
                  label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ))
            .toList(),
        rows: previewRows.skip(1).map((row) {
          return DataRow(
            cells: List.generate(_headers.length, (i) {
              final value = i < row.length ? row[i].toString() : '';
              return DataCell(Text(value, style: const TextStyle(fontSize: 12)));
            }),
          );
        }).toList(),
      ),
    );
  }
}
