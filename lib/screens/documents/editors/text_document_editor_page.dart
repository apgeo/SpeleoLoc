import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';
import 'package:speleoloc/utils/file_utils.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// A simple plain-text editor that creates a new documentation file record.
///
/// The user provides a title and types (or pastes) text content. On save the
/// text is written to a `.txt` file inside the documentation storage folder
/// and a corresponding DB record is inserted, optionally linked to a
/// geofeature parent.
class TextDocumentEditorPage extends StatefulWidget {
  const TextDocumentEditorPage({
    super.key,
    this.cavePlaceUuid,
    this.caveUuid,
    this.caveAreaUuid,
    this.existingDoc,
  });

  final Uuid? cavePlaceUuid;
  final Uuid? caveUuid;
  final Uuid? caveAreaUuid;

  /// When non-null the editor opens in *edit* mode: it loads the existing file
  /// content and on save overwrites the record instead of inserting a new one.
  final DocumentationFile? existingDoc;

  @override
  State<TextDocumentEditorPage> createState() => _TextDocumentEditorPageState();
}

class _TextDocumentEditorPageState extends State<TextDocumentEditorPage>
    with AppBarMenuMixin<TextDocumentEditorPage>, ProductTourMixin<TextDocumentEditorPage> {
  @override
  String get tourId => 'text_document_editor';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'title_field', titleLocKey: 'tour_text_doc_editor_title_field_title', bodyLocKey: 'tour_text_doc_editor_title_field_body'),
    TourStepDef(keyId: 'content', titleLocKey: 'tour_text_doc_editor_content_title', bodyLocKey: 'tour_text_doc_editor_content_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_text_doc_editor_menu_title', bodyLocKey: 'tour_text_doc_editor_menu_body'),
  ];

  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = false;

  /// Snapshots captured after initial load for dirty-state detection.
  String _initialTitle = '';
  String _initialContent = '';

  bool get _isEditing => widget.existingDoc != null;

  bool get _isModified =>
      _titleCtrl.text.trim() != _initialTitle ||
      _contentCtrl.text != _initialContent;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleCtrl.text = widget.existingDoc!.title;
      _loadExistingContent();
    } else {
      _initialTitle = '';
      _initialContent = '';
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
    if (mounted) {
      _initialTitle = widget.existingDoc!.title;
      _initialContent = _contentCtrl.text;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  /// Returns `true` if navigation should proceed.
  Future<bool> _onWillPop() async {
    if (!_isModified) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('unsaved_changes')),
        content: Text(LocServ.inst.t('unsaved_changes_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: Text(LocServ.inst.t('discard')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: Text(LocServ.inst.t('save')),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _save();
      return false; // _save() already pops on success
    }
    return result == 'discard';
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
          id: existingDoc.uuid,
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
          cavePlaceUuid: widget.cavePlaceUuid,
          caveUuid: widget.caveUuid,
          caveAreaUuid: widget.caveAreaUuid,
        );

        await DocumentationFileHelper.insertRecord(
          title: title,
          description: null,
          savedFile: savedFile,
          fileType: 'text_document',
          parentLink: parentLink,
          textContent: content,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _onWillPop()) {
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
          KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    key: tourKeys['title_field'],
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: LocServ.inst.t('title'),
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    key: tourKeys['content'],
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
      ),
    );
  }
}
