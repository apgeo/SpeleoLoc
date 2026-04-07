import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';
import 'package:speleoloc/utils/file_utils.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

/// A simple plain-text editor that creates a new documentation file record.
///
/// The user provides a title and types (or pastes) text content. On save the
/// text is written to a `.txt` file inside the documentation storage folder
/// and a corresponding DB record is inserted, optionally linked to a
/// geofeature parent.
class TextDocumentEditorPage extends StatefulWidget {
  const TextDocumentEditorPage({
    super.key,
    this.cavePlaceId,
    this.caveId,
    this.caveAreaId,
    this.existingDoc,
  });

  final int? cavePlaceId;
  final int? caveId;
  final int? caveAreaId;

  /// When non-null the editor opens in *edit* mode: it loads the existing file
  /// content and on save overwrites the record instead of inserting a new one.
  final DocumentationFile? existingDoc;

  @override
  State<TextDocumentEditorPage> createState() => _TextDocumentEditorPageState();
}

class _TextDocumentEditorPageState extends State<TextDocumentEditorPage>
    with AppBarMenuMixin<TextDocumentEditorPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = false;

  bool get _isEditing => widget.existingDoc != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleCtrl.text = widget.existingDoc!.title;
      _loadExistingContent();
    }
  }

  Future<void> _loadExistingContent() async {
    setState(() => _isLoading = true);
    try {
      final file = await getDocumentsFile(widget.existingDoc!.fileName);
      if (file != null) {
        _contentCtrl.text = await file.readAsString();
      }
    } catch (e) {
      debugPrint('[TextDocumentEditorPage] Error loading file: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocServ.inst.t('title_required'))),
      );
      return;
    }

    final content = _contentCtrl.text;
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocServ.inst.t('text_content_required'))),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        // ---- UPDATE existing file & record ----
        final existingDoc = widget.existingDoc!;
        final savedFile = await DocumentationFileHelper.overwriteText(
          relativePath: existingDoc.fileName,
          content: content,
        );

        await DocumentationFileHelper.updateRecord(
          id: existingDoc.id,
          title: title,
          description: existingDoc.description,
          savedFile: savedFile,
        );
      } else {
        // ---- CREATE new file & record ----
        final sanitised = title
            .replaceAll(RegExp(r'[^\w\s\-.]'), '_')
            .replaceAll(RegExp(r'\s+'), '_');
        final baseName = '$sanitised.txt';

        final savedFile = await DocumentationFileHelper.saveText(
          baseName: baseName,
          content: content,
        );

        // Check for duplicates
        final dupes = await DocumentationFileHelper.findDuplicates(
          fileSize: savedFile.fileSize,
          fileHash: savedFile.fileHash,
        );
        if (dupes.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Similar file(s) already present (size+hash match).'),
            ),
          );
        }

        final parentLink = await appDatabase.getDocumentationParentLink(
          cavePlaceId: widget.cavePlaceId,
          caveId: widget.caveId,
          caveAreaId: widget.caveAreaId,
        );

        await DocumentationFileHelper.insertRecord(
          title: title,
          description: null,
          savedFile: savedFile,
          fileType: 'text_document',
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(
          _isEditing
              ? LocServ.inst.t('edit_text_document')
              : LocServ.inst.t('new_text_document'),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: LocServ.inst.t('save'),
              onPressed: _save,
            ),
          buildAppBarMenuButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: LocServ.inst.t('title'),
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _contentCtrl,
                      decoration: InputDecoration(
                        hintText: LocServ.inst.t('text_content_hint'),
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
