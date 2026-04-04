import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:speleo_loc/data/source/database/app_database.dart';
import 'package:speleo_loc/utils/documentation_file_helper.dart';
import 'package:speleo_loc/utils/file_utils.dart';
import 'package:speleo_loc/utils/localization.dart';

/// Full-featured image editor powered by `pro_image_editor`.
///
/// * **Edit mode** (`existingDoc != null`): loads the existing image and
///   overwrites it on save.
/// * **Create mode**: expects [initialFile] (e.g. from file-picker or camera)
///   so the user can annotate / crop before the first save.
class ImageEditorPage extends StatefulWidget {
  const ImageEditorPage({
    super.key,
    this.cavePlaceId,
    this.caveId,
    this.caveAreaId,
    this.existingDoc,
    this.initialFile,
  });

  final int? cavePlaceId;
  final int? caveId;
  final int? caveAreaId;

  /// Non-null when editing an already-persisted image.
  final DocumentationFile? existingDoc;

  /// Non-null for new images that have not been saved yet (e.g. just picked
  /// from gallery or captured from camera).
  final File? initialFile;

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  bool _isEditing = false;
  bool _isLoading = true;
  Uint8List? _imageBytes;

  bool get _isEditMode => widget.existingDoc != null;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      if (_isEditMode) {
        final file = await getDocumentsFile(widget.existingDoc!.fileName);
        if (file != null) {
          _imageBytes = await file.readAsBytes();
        }
      } else if (widget.initialFile != null) {
        _imageBytes = await widget.initialFile!.readAsBytes();
      }
    } catch (e) {
      debugPrint('[ImageEditorPage] Error loading image: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onImageEditingComplete(Uint8List editedBytes) async {
    if (_isEditing) return;
    setState(() => _isEditing = true);

    try {
      if (_isEditMode) {
        // ---- UPDATE existing image ----
        final doc = widget.existingDoc!;
        final saved = await DocumentationFileHelper.overwriteBytes(
          relativePath: doc.fileName,
          bytes: editedBytes,
        );
        await DocumentationFileHelper.updateRecord(
          id: doc.id,
          title: doc.title,
          description: doc.description,
          savedFile: saved,
        );
      } else {
        // ---- CREATE new image ----
        final baseName = 'image_${DateTime.now().millisecondsSinceEpoch}.png';
        final saved = await DocumentationFileHelper.saveBytes(
          baseName: baseName,
          bytes: editedBytes,
        );

        final parentLink = await appDatabase.getDocumentationParentLink(
          cavePlaceId: widget.cavePlaceId,
          caveId: widget.caveId,
          caveAreaId: widget.caveAreaId,
        );

        await DocumentationFileHelper.insertRecord(
          title: baseName,
          savedFile: saved,
          fileType: 'photo',
          parentLink: parentLink,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditMode
                ? LocServ.inst.t('edit_image')
                : LocServ.inst.t('new_image_edit'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_imageBytes == null || _imageBytes!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(LocServ.inst.t('edit_image')),
        ),
        body: Center(
          child: Text(LocServ.inst.t('image_not_found')),
        ),
      );
    }

    return ProImageEditor.memory(
      _imageBytes!,
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (bytes) async {
          await _onImageEditingComplete(bytes);
        },
        onCloseEditor: () {
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }
}
