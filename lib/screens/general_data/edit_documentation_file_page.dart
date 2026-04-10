import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';
import 'package:speleoloc/utils/image_compression_settings.dart';
import 'package:speleoloc/utils/image_compressor.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:drift/drift.dart' as drift;
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

class EditDocumentationFilePage extends StatefulWidget {
  const EditDocumentationFilePage({super.key, this.documentationFile, this.cavePlaceId, this.caveId, this.caveAreaId});

  final DocumentationFile? documentationFile;
  final int? cavePlaceId;
  final int? caveId;
  final int? caveAreaId;

  @override
  State<EditDocumentationFilePage> createState() => _EditDocumentationFilePageState();
}

class _EditDocumentationFilePageState extends State<EditDocumentationFilePage>
    with AppBarMenuMixin<EditDocumentationFilePage>, ProductTourMixin<EditDocumentationFilePage> {
  @override
  String get tourId => 'edit_doc_file';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'title_field', titleLocKey: 'tour_edit_doc_file_title_field_title', bodyLocKey: 'tour_edit_doc_file_title_field_body'),
    TourStepDef(keyId: 'file_picker', titleLocKey: 'tour_edit_doc_file_file_picker_title', bodyLocKey: 'tour_edit_doc_file_file_picker_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_edit_doc_file_menu_title', bodyLocKey: 'tour_edit_doc_file_menu_body'),
  ];

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  File? _pickedFile;
  String? _storedFileName;
  int? _fileSize;
  String? _fileHash;

  @override
  void initState() {
    super.initState();
    if (widget.documentationFile != null) {
      _titleCtrl.text = widget.documentationFile!.title;
      _descCtrl.text = widget.documentationFile!.description ?? '';
      _storedFileName = widget.documentationFile!.fileName;
      _fileSize = widget.documentationFile!.fileSize;
      _fileHash = widget.documentationFile!.fileHash;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (res == null || res.files.isEmpty) return;
    final pf = res.files.first;
    final fileBytes = pf.bytes ?? await File(pf.path!).readAsBytes();
    setState(() {
      _pickedFile = File(pf.path!);
      _fileSize = pf.size;
      _fileHash = DocumentationFileHelper.computeSha256(fileBytes);
    });

    // optional: compare with DB entries (only if we have size+hash)
    if (_fileSize != null && _fileHash != null) {
      final matches = await DocumentationFileHelper.findDuplicates(
        fileSize: _fileSize!,
        fileHash: _fileHash!,
      );
      if (matches.isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Similar file(s) already present (size+hash match).')));
      }
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.isEmpty ? null : _titleCtrl.text;
    final description = _descCtrl.text.isEmpty ? null : _descCtrl.text;

    String? fileNameToStore = _storedFileName;
    if (_pickedFile != null) {
      // Compress images before saving if compression is enabled.
      final detectedType =
          DocumentationFileHelper.detectFileType(_pickedFile!.path);
      if (detectedType == 'photo') {
        final cs = await ImageCompressionSettings.load();
        await ImageCompressor.compressFile(_pickedFile!, cs);
      }

      final info = await DocumentationFileHelper.saveExternalFile(_pickedFile!);
      fileNameToStore = info.relativePath;
      _fileSize = info.fileSize;
      _fileHash = info.fileHash;
    }

    if (widget.documentationFile != null) {
      final updated = widget.documentationFile!.copyWith(
        title: title,
        description: drift.Value(description),
        fileName: fileNameToStore,
        fileSize: _fileSize,
        fileHash: drift.Value(_fileHash),
      );
      await appDatabase.update(appDatabase.documentationFiles).replace(updated);
      if (mounted) Navigator.pop(context, true);
      return;
    }

    // Validation: require a file name for new records
    if (fileNameToStore == null || fileNameToStore.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocServ.inst.t('please_select_file'))));
      return;
    }

    final parentLink = await appDatabase.getDocumentationParentLink(
      cavePlaceId: widget.cavePlaceId,
      caveId: widget.caveId,
      caveAreaId: widget.caveAreaId,
    );

    // Insert new (use insert ctor which expects plain values for required fields)
    final companion = DocumentationFilesCompanion.insert(
      title: title ?? '',
      fileName: fileNameToStore,
      fileSize: _fileSize ?? 0,
      fileType: DocumentationFileHelper.detectFileType(fileNameToStore),
    );

    // optional fields set via copyWith on companion
    final withOptional = companion.copyWith(
      description: drift.Value(description),
      fileSize: drift.Value(_fileSize ?? 0),
      fileHash: drift.Value(_fileHash),
      createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
    );

    try {
      await appDatabase.insertDocumentationFile(
        companion: withOptional,
        parentLink: parentLink,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.documentationFile != null;
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(editing ? LocServ.inst.t('edit') : '${LocServ.inst.t('add')} ${LocServ.inst.t('documentation_files')}'),
        actions: [KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton())],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextFormField(key: tourKeys['title_field'], controller: _titleCtrl, decoration: InputDecoration(labelText: LocServ.inst.t('title'))),
            const SizedBox(height: 8),
            TextFormField(controller: _descCtrl, decoration: InputDecoration(labelText: LocServ.inst.t('description'))),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(key: tourKeys['file_picker'], onPressed: _pick, icon: const Icon(Icons.attach_file), label: Text(LocServ.inst.t('select_file'))),
                const SizedBox(width: 12),
                if (_pickedFile != null) Flexible(child: Text(_pickedFile!.path.split(Platform.pathSeparator).last)),
                if (_pickedFile == null && _storedFileName != null) Flexible(child: Text(_storedFileName!)),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [Text('${LocServ.inst.t('file_size')}: ${_fileSize ?? '-'}'), const SizedBox(width: 16), Text('hash: ${_fileHash ?? '-'}')]),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: Text(LocServ.inst.t('save'))),
          ],
        ),
      ),
    );
  }
}
