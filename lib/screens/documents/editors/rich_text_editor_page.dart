import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/documentation_file_helper.dart';
import 'package:speleoloc/utils/file_utils.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// Rich-text editor powered by `flutter_quill`.
///
/// Documents are stored as JSON (Quill Delta format) with a `.qldoc` extension.
///
/// * **Edit mode** (`existingDoc != null`): loads the existing `.qldoc` file,
///   parses its Delta JSON, and overwrites on save.
/// * **Create mode**: starts with an empty document.
class RichTextEditorPage extends StatefulWidget {
  const RichTextEditorPage({
    super.key,
    this.cavePlaceUuid,
    this.caveUuid,
    this.caveAreaUuid,
    this.existingDoc,
  });

  final Uuid? cavePlaceUuid;
  final Uuid? caveUuid;
  final Uuid? caveAreaUuid;
  final DocumentationFile? existingDoc;

  @override
  State<RichTextEditorPage> createState() => _RichTextEditorPageState();
}

class _RichTextEditorPageState extends State<RichTextEditorPage>
    with AppBarMenuMixin<RichTextEditorPage>, ProductTourMixin<RichTextEditorPage> {
  @override
  String get tourId => 'rich_text_editor';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'title_field', titleLocKey: 'tour_rich_text_editor_title_field_title', bodyLocKey: 'tour_rich_text_editor_title_field_body'),
    TourStepDef(keyId: 'quill', titleLocKey: 'tour_rich_text_editor_quill_title', bodyLocKey: 'tour_rich_text_editor_quill_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_rich_text_editor_menu_title', bodyLocKey: 'tour_rich_text_editor_menu_body'),
  ];

  final _titleCtrl = TextEditingController();
  late QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;
  bool _isLoading = false;

  /// Snapshot of title and delta JSON captured after initial load.
  /// Used to detect unsaved modifications.
  String _initialTitle = '';
  String? _initialDeltaJson;

  bool get _isEditing => widget.existingDoc != null;

  bool get _isModified {
    if (_titleCtrl.text.trim() != _initialTitle) return true;
    final currentJson =
        jsonEncode(_quillController.document.toDelta().toJson());
    return currentJson != _initialDeltaJson;
  }

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();

    if (_isEditing) {
      _titleCtrl.text = widget.existingDoc!.title;
      _loadExistingContent();
    } else {
      // Capture initial empty-document snapshot for dirty detection.
      _initialTitle = '';
      _initialDeltaJson =
          jsonEncode(_quillController.document.toDelta().toJson());
    }
  }

  Future<void> _loadExistingContent() async {
    setState(() => _isLoading = true);
    try {
      final file = await getDocumentsFile(widget.existingDoc!.fileName);
      if (file != null) {
        final jsonStr = await file.readAsString();
        final deltaJson = jsonDecode(jsonStr) as List;
        _quillController.document = Document.fromJson(deltaJson);
      }
    } catch (e) {
      debugPrint('[RichTextEditorPage] Error loading file: $e');
    }
    if (mounted) {
      // Capture initial snapshot now that the document is loaded.
      _initialTitle = widget.existingDoc!.title;
      _initialDeltaJson =
          jsonEncode(_quillController.document.toDelta().toJson());
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Called when the user tries to navigate back. If there are unsaved
  /// modifications, prompts the user to save, discard, or cancel.
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

    setState(() => _isSaving = true);

    try {
      final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());

      if (_isEditing) {
        // ---- UPDATE ----
        final doc = widget.existingDoc!;
        final saved = await DocumentationFileHelper.overwriteText(
          relativePath: doc.fileName,
          content: deltaJson,
        );
        await DocumentationFileHelper.updateRecord(
          id: doc.uuid,
          title: title,
          description: doc.description,
          savedFile: saved,
        );
      } else {
        // ---- CREATE ----
        final sanitised = title
            .replaceAll(RegExp(r'[^\w\s\-.]'), '_')
            .replaceAll(RegExp(r'\s+'), '_');
        final baseName = '$sanitised.qldoc';

        final saved = await DocumentationFileHelper.saveText(
          baseName: baseName,
          content: deltaJson,
        );

        final parentLink = await appDatabase.getDocumentationParentLink(
          cavePlaceUuid: widget.cavePlaceUuid,
          caveUuid: widget.caveUuid,
          caveAreaUuid: widget.caveAreaUuid,
        );

        await DocumentationFileHelper.insertRecord(
          title: title,
          savedFile: saved,
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
              ? LocServ.inst.t('edit_rich_text')
              : LocServ.inst.t('new_rich_text'),
        ),
        actions: [
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
                  // ---- Title field ----
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

                  // ---- Quill toolbar ----
                  QuillSimpleToolbar(
                    controller: _quillController,
                    config: const QuillSimpleToolbarConfig(),
                  ),
                  const Divider(height: 1),

                  // ---- Quill editor ----
                  Expanded(
                    key: tourKeys['quill'],
                    child: QuillEditor(
                      controller: _quillController,
                      focusNode: _editorFocusNode,
                      scrollController: _scrollController,
                      config: const QuillEditorConfig(
                        padding: EdgeInsets.all(8),
                        placeholder: 'Start writing...',
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
