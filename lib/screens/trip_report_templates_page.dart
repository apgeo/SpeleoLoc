import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/trip_report_export_service.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Screen for managing trip report document templates.
///
/// Users can:
///   - View the list of stored templates
///   - Add new templates (ODF/DOCX) from the device
///   - Delete templates with confirmation
class TripReportTemplatesPage extends StatefulWidget {
  const TripReportTemplatesPage({super.key});

  @override
  State<TripReportTemplatesPage> createState() =>
      _TripReportTemplatesPageState();
}

class _TripReportTemplatesPageState extends State<TripReportTemplatesPage> {
  List<TripReportTemplate> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final templates = await appDatabase.getTripReportTemplates();
    if (mounted) {
      setState(() {
        _templates = templates;
        _loading = false;
      });
    }
  }

  Future<void> _addTemplate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['odt', 'docx'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final pickedFile = File(result.files.single.path!);
    final service = TripReportExportService.instance;
    final format = service.detectFormat(pickedFile.path);
    if (format == null) {
      if (mounted) {
        SnackBarService.showWarning(LocServ.inst.t('template_unsupported_format'));
      }
      return;
    }

    // Ask for a title
    final titleController = TextEditingController(
      text: pickedFile.uri.pathSegments.last.replaceAll(RegExp(r'\.(odt|docx)$'), ''),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('template_add_title')),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: LocServ.inst.t('template_name'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('ok')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final title = titleController.text.trim();
    if (title.isEmpty) return;

    try {
      final storedFileName = await service.storeTemplateFile(pickedFile);
      await appDatabase.insertTripReportTemplate(
        title: title,
        fileName: storedFileName,
        fileSize: pickedFile.lengthSync(),
        format: format,
      );
      await _load();
      if (mounted) {
        SnackBarService.showSuccess(LocServ.inst.t('template_added'));
      }
    } catch (e) {
      if (mounted) SnackBarService.showError(e);
    }
  }

  Future<void> _deleteTemplate(TripReportTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(LocServ.inst.t('template_delete_confirm', {'name': template.title})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('yes')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await TripReportExportService.instance.deleteTemplateFile(template.fileName);
      await appDatabase.deleteTripReportTemplate(template.uuid);
      await _load();
      if (mounted) {
        SnackBarService.showSuccess(LocServ.inst.t('template_deleted'));
      }
    } catch (e) {
      if (mounted) SnackBarService.showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocServ.inst.t('template_manage_title')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTemplate,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      LocServ.inst.t('template_none'),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final t = _templates[index];
                    return ListTile(
                      leading: Icon(
                        t.format == 'odt' ? Icons.description : Icons.article,
                        color: t.format == 'odt' ? Colors.blue : Colors.indigo,
                      ),
                      title: Text(t.title),
                      subtitle: Text(
                        '${t.format.toUpperCase()} · ${_formatFileSize(t.fileSize)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTemplate(t),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
