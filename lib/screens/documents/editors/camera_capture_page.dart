import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/documents/editors/image_editor_page.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';
import 'package:speleoloc/utils/image_compression_settings.dart';
import 'package:speleoloc/utils/image_compressor.dart';
import 'package:speleoloc/utils/localization.dart';

/// Captures a photo using [ImagePicker] (camera) and then optionally opens the
/// [ImageEditorPage] for annotation / cropping before saving.
///
/// If the device has no camera the user sees a friendly message and can fall
/// back to picking from the gallery.
class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({
    super.key,
    this.cavePlaceId,
    this.caveId,
    this.caveAreaId,
  });

  final int? cavePlaceId;
  final int? caveId;
  final int? caveAreaId;

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  File? _capturedFile;

  @override
  void initState() {
    super.initState();
    // Launch camera immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) => _takePhoto());
  }

  Future<void> _takePhoto() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (xFile == null) {
        // User cancelled the camera.
        if (mounted) Navigator.pop(context);
        return;
      }
      setState(() => _capturedFile = File(xFile.path));
    } catch (e) {
      debugPrint('[CameraCapturePage] Camera error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocServ.inst.t('camera_error'))),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final xFile = await _picker.pickImage(source: ImageSource.gallery);
      if (xFile == null) return;
      setState(() => _capturedFile = File(xFile.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _saveDirectly() async {
    if (_capturedFile == null || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      // Apply image compression if enabled in settings.
      final compressionSettings = await ImageCompressionSettings.load();
      await ImageCompressor.compressFile(_capturedFile!, compressionSettings);

      final saved = await DocumentationFileHelper.saveExternalFile(_capturedFile!);
      final parentLink = await appDatabase.getDocumentationParentLink(
        cavePlaceId: widget.cavePlaceId,
        caveId: widget.caveId,
        caveAreaId: widget.caveAreaId,
      );
      await DocumentationFileHelper.insertRecord(
        title: 'Photo ${DateTime.now().toIso8601String().substring(0, 19)}',
        savedFile: saved,
        fileType: 'photo',
        parentLink: parentLink,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openInEditor() async {
    if (_capturedFile == null) return;
    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageEditorPage(
          cavePlaceId: widget.cavePlaceId,
          caveId: widget.caveId,
          caveAreaId: widget.caveAreaId,
          initialFile: _capturedFile,
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocServ.inst.t('new_photo')),
        actions: [
          if (_capturedFile != null && !_isSaving)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: LocServ.inst.t('edit_in_editor'),
              onPressed: _openInEditor,
            ),
          if (_capturedFile != null && !_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: LocServ.inst.t('save'),
              onPressed: _saveDirectly,
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _capturedFile == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(LocServ.inst.t('waiting_for_camera')),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(LocServ.inst.t('take_photo')),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: Text(LocServ.inst.t('pick_from_gallery')),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    child: Image.file(
                      _capturedFile!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(LocServ.inst.t('retake')),
                      ),
                      FilledButton.icon(
                        onPressed: _openInEditor,
                        icon: const Icon(Icons.edit),
                        label: Text(LocServ.inst.t('edit_in_editor')),
                      ),
                      FilledButton.icon(
                        onPressed: _saveDirectly,
                        icon: const Icon(Icons.save),
                        label: Text(LocServ.inst.t('save')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
