import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// Definition of a single CSV column that can be mapped by the user.
class CSVColumnDefinition {
  /// Unique key used in [CSVImportResult.columnMappings].
  final String key;

  /// Display label shown in the column mapping UI.
  final String label;

  /// Whether the user must map this column before importing.
  final bool required;

  const CSVColumnDefinition({
    required this.key,
    required this.label,
    this.required = false,
  });
}

/// Result returned by [CSVImportPage] when the user clicks Import.
class CSVImportResult {
  /// The column definitions that were passed to [CSVImportPage].
  final List<CSVColumnDefinition> definitions;

  /// CSV header names extracted from the first row.
  final List<String> headers;

  /// All raw CSV data including the header row.
  final List<List<dynamic>> rawData;

  /// Map of definition key → selected CSV column index (null if not mapped).
  final Map<String, int?> columnMappings;

  CSVImportResult({
    required this.definitions,
    required this.headers,
    required this.rawData,
    required this.columnMappings,
  });

  /// Get data rows (excluding header) as a list of maps keyed by definition key.
  List<Map<String, String?>> getRows() {
    if (rawData.length < 2) return [];
    return rawData.skip(1).map((row) {
      final map = <String, String?>{};
      for (final def in definitions) {
        final idx = columnMappings[def.key];
        if (idx != null && idx < row.length) {
          final val = row[idx].toString().trim();
          map[def.key] = val.isEmpty ? null : val;
        } else {
          map[def.key] = null;
        }
      }
      return map;
    }).toList();
  }
}

/// Generic CSV import page that handles file selection, column mapping,
/// and data preview.
///
/// Pass a list of [CSVColumnDefinition]s describing the columns to map.
/// When the user clicks Import, the page pops with a [CSVImportResult].
class CSVImportPage extends StatefulWidget {
  /// The page title displayed in the app bar.
  final String title;

  /// Column definitions that the user maps to CSV columns.
  final List<CSVColumnDefinition> columnDefinitions;

  const CSVImportPage({
    super.key,
    required this.title,
    required this.columnDefinitions,
  });

  @override
  State<CSVImportPage> createState() => _CSVImportPageState();
}

class _CSVImportPageState extends State<CSVImportPage>
    with AppBarMenuMixin<CSVImportPage>, ProductTourMixin<CSVImportPage> {
  @override
  String get tourId => 'csv_import';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'file_picker', titleLocKey: 'tour_csv_import_file_picker_title', bodyLocKey: 'tour_csv_import_file_picker_body'),
    TourStepDef(keyId: 'column_mapping', titleLocKey: 'tour_csv_import_column_mapping_title', bodyLocKey: 'tour_csv_import_column_mapping_body'),
    TourStepDef(keyId: 'preview', titleLocKey: 'tour_csv_import_preview_title', bodyLocKey: 'tour_csv_import_preview_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_csv_import_menu_title', bodyLocKey: 'tour_csv_import_menu_body'),
  ];

  // CSV data
  String? _filePath;
  List<List<dynamic>>? _csvData;
  List<String> _headers = [];

  // Column mappings keyed by definition key
  final Map<String, int?> _columnMappings = {};

  // State
  bool _isLoading = false;
  String? _errorMessage;

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
      final csvData = _parseCSV(content);

      if (csvData.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = LocServ.inst.t('csv_file_empty');
        });
        return;
      }

      final headers = _getHeaders(csvData);

      setState(() {
        _filePath = path;
        _csvData = csvData;
        _headers = headers;
        _columnMappings.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '${LocServ.inst.t('error')}: $e';
      });
    }
  }

  List<List<dynamic>> _parseCSV(String csvContent) {
    final converter = const CsvToListConverter(eol: '\n', shouldParseNumbers: false);
    final normalized = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return converter.convert(normalized);
  }

  List<String> _getHeaders(List<List<dynamic>> csvData) {
    if (csvData.isEmpty) return [];
    return csvData.first.map((e) => e.toString().trim()).toList();
  }

  void _startImport() {
    if (_csvData == null) return;

    // Validate required columns
    for (final def in widget.columnDefinitions) {
      if (def.required && _columnMappings[def.key] == null) {
        _showMessage('${def.label} ${LocServ.inst.t('csv_column_required')}');
        return;
      }
    }

    final result = CSVImportResult(
      definitions: widget.columnDefinitions,
      headers: _headers,
      rawData: _csvData!,
      columnMappings: Map.from(_columnMappings),
    );

    Navigator.pop(context, result);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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

  Widget _buildMappingRow(CSVColumnDefinition def) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              def.required ? '${def.label} *' : def.label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int?>(
              initialValue: _columnMappings[def.key],
              items: _buildColumnDropdownItems(),
              onChanged: (v) => setState(() => _columnMappings[def.key] = v),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton())],
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
                    key: tourKeys['file_picker'],
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
                      key: tourKeys['column_mapping'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${LocServ.inst.t('csv_rows_found')}: ${_csvData!.length - 1}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),

                    // Dynamic column mapping rows from definitions
                    ...widget.columnDefinitions.map(_buildMappingRow),

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
                      key: tourKeys['preview'],
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
}
