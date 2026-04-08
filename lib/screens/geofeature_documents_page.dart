import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/documents/editors/camera_capture_page.dart';
import 'package:speleoloc/screens/documents/editors/image_editor_page.dart';
import 'package:speleoloc/screens/documents/editors/rich_text_editor_page.dart';
import 'package:speleoloc/screens/documents/editors/sound_recorder_page.dart';
import 'package:speleoloc/screens/documents/viewers/documentation_file_viewer.dart';
import 'package:speleoloc/screens/documents/editors/text_document_editor_page.dart';
import 'package:speleoloc/services/document_format_registry.dart';
import 'package:speleoloc/services/documents_controller.dart';
import 'package:speleoloc/screens/general_data/edit_documentation_file_page.dart';
import 'package:speleoloc/utils/file_utils.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/document_thumbnail_widgets.dart';

// ---------------------------------------------------------------------------
//  Enums
// ---------------------------------------------------------------------------

/// Available display modes for the documents list.
///
///  * [list]             – flat list
///  * [listByCategory]   – list grouped by category headers
///  * [grid]             – flat grid preview
///  * [gridByCategory]   – grid grouped by category headers
///  * [gridHorizontal]   – categories with horizontally-scrollable grids
enum DocViewMode { list, listByCategory, grid, gridByCategory, gridHorizontal }

/// Fields by which documents can be sorted.
enum DocSortField { title, type, size, date }

// ---------------------------------------------------------------------------
//  GeofeatureDocumentsPage
// ---------------------------------------------------------------------------

/// Displays all documentation files linked to a geofeature (cave place,
/// cave, or cave area), with switchable view modes (flat list,
/// list-by-category, grid, grid-by-category, horizontal-grid-by-category),
/// a pinned search/filter bar, and sort controls.
///
/// The source of documents is described by [DocumentsSource], making this
/// page generic and reusable across different geofeature types.
class GeofeatureDocumentsPage extends StatefulWidget {
  const GeofeatureDocumentsPage({
    super.key,
    required this.source,
  });

  final DocumentsSource source;

  @override
  State<GeofeatureDocumentsPage> createState() =>
      _GeofeatureDocumentsPageState();
}

class _GeofeatureDocumentsPageState extends State<GeofeatureDocumentsPage>
    with AppBarMenuMixin<GeofeatureDocumentsPage> {
  // Data
  late final DocumentsController _controller;
  List<DocumentationFile> _filteredDocs = [];
  bool _isLoading = true;
  String? _docsDir;

  // View state
  DocViewMode _viewMode = DocViewMode.list;
  DocSortField _sortField = DocSortField.title;
  bool _sortAscending = true;
  int _horizontalGridRows = 2;
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _collapsedCategories = {};

  // -----------------------------------------------------------------------
  //  Lifecycle
  // -----------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _controller = DocumentsController(widget.source);
    _searchCtrl.addListener(_applyFilter);
    _init();
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _docsDir = dir.path;
    await _loadDocuments();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  //  Data loading & filtering
  // -----------------------------------------------------------------------

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      await _controller.loadDocuments();
    } catch (e) {
      debugPrint('[GeofeatureDocumentsPage] Error loading documents: $e');
    }
    _applyFilter();
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase().trim();
    final allDocs = _controller.documents;

    var docs = query.isEmpty
        ? List<DocumentationFile>.from(allDocs)
        : allDocs
            .where((d) =>
                d.title.toLowerCase().contains(query) ||
                d.fileName.toLowerCase().contains(query) ||
                (d.description?.toLowerCase().contains(query) ?? false))
            .toList();

    // Sort
    docs.sort((a, b) {
      final int cmp = switch (_sortField) {
        DocSortField.title =>
          a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        DocSortField.type => a.fileType.compareTo(b.fileType),
        DocSortField.size => a.fileSize.compareTo(b.fileSize),
        DocSortField.date => (a.createdAt ?? 0).compareTo(b.createdAt ?? 0),
      };
      return _sortAscending ? cmp : -cmp;
    });

    _filteredDocs = docs;
    if (mounted) setState(() {});
  }

  /// Groups [_filteredDocs] by `fileType`, sorted alphabetically by key.
  Map<String, List<DocumentationFile>> _groupByCategory() {
    final map = <String, List<DocumentationFile>>{};
    for (final doc in _filteredDocs) {
      map.putIfAbsent(doc.fileType, () => []).add(doc);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  // -----------------------------------------------------------------------
  //  Helpers
  // -----------------------------------------------------------------------

  File? _resolveDocFile(DocumentationFile doc) {
    if (_docsDir == null || doc.fileName.isEmpty) return null;
    final file = File('$_docsDir/${doc.fileName}');
    return file.existsSync() ? file : null;
  }

  String _categoryLabel(String fileType) => switch (fileType) {
        'photo' => LocServ.inst.t('doc_type_photo'),
        'video' => LocServ.inst.t('doc_type_video'),
        'audio' => LocServ.inst.t('doc_type_audio'),
        'text_document' => LocServ.inst.t('doc_type_text'),
        'web_link' => LocServ.inst.t('doc_type_web_link'),
        _ => LocServ.inst.t('doc_type_other'),
      };

  static IconData _categoryIcon(String fileType) => switch (fileType) {
        'photo' => Icons.photo,
        'video' => Icons.videocam,
        'audio' => Icons.audiotrack,
        'text_document' => Icons.description,
        'web_link' => Icons.link,
        _ => Icons.insert_drive_file,
      };

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // -----------------------------------------------------------------------
  //  Navigation
  // -----------------------------------------------------------------------

  Future<void> _openDocument(DocumentationFile doc) async {
    if (doc.fileName.isEmpty) return;
    final file = await getDocumentsFile(doc.fileName);
    if (file == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocServ.inst.t('image_not_found'))),
        );
      }
      return;
    }
    if (!mounted) return;

    final registry = DocumentFormatRegistry.instance;
    final handler = registry.handlerForDoc(doc);

    // Prefer editor; fall back to viewer with edit FAB.
    Widget? page;
    if (handler?.buildEditor != null && widget.source.geofeatureLink != null) {
      final link = widget.source.geofeatureLink!;
      page = handler!.buildEditor!(
        cavePlaceId: link.type == GeofeatureType.cavePlace ? link.geofeatureId : null,
        caveId: link.type == GeofeatureType.cave ? link.geofeatureId : null,
        caveAreaId: link.type == GeofeatureType.caveArea ? link.geofeatureId : null,
        existingDoc: doc,
      );
    } else if (handler?.buildViewer != null) {
      page = handler!.buildEditableViewer(
        file: file,
        doc: doc,
        geofeatureLink: widget.source.geofeatureLink,
      );
    }

    if (page != null) {
      _navigateAndRefresh(page);
    } else {
      // Fallback: open with the generic viewer.
      _navigateAndRefresh(DocumentationFileViewer(file: file, doc: doc));
    }
  }

  // -----------------------------------------------------------------------
  //  Thumbnail widgets
  // -----------------------------------------------------------------------

  /// Small (48×48) thumbnail used in list / category modes.
  Widget _buildSmallThumbnail(DocumentationFile doc) {
    final registry = DocumentFormatRegistry.instance;
    final file = _resolveDocFile(doc);
    return registry.buildThumbnail(
      context: context,
      doc: doc,
      resolvedFile: file,
      size: DocumentThumbnailSize.small,
      fallbackBuilder: (icon) => DocumentThumbnailWidgets.iconTile(
        context: context,
        icon: icon,
        size: DocumentThumbnailSize.small,
      ),
    );
  }

  /// Expanding thumbnail used in grid mode (fills available space).
  Widget _buildLargeThumbnail(DocumentationFile doc) {
    final registry = DocumentFormatRegistry.instance;
    final file = _resolveDocFile(doc);
    return registry.buildThumbnail(
      context: context,
      doc: doc,
      resolvedFile: file,
      size: DocumentThumbnailSize.large,
      fallbackBuilder: (icon) => DocumentThumbnailWidgets.iconTile(
        context: context,
        icon: icon,
        size: DocumentThumbnailSize.large,
      ),
    );
  }

  // -----------------------------------------------------------------------
  //  Item widgets
  // -----------------------------------------------------------------------

  Widget _buildListItem(DocumentationFile doc) {
    return GestureDetector(
      onLongPressStart: (details) =>
          _showDocumentContextMenu(context, details.globalPosition, doc),
      child: ListTile(
        leading: _buildSmallThumbnail(doc),
        title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_categoryLabel(doc.fileType)}  \u2022  ${_formatSize(doc.fileSize)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => _openDocument(doc),
      ),
    );
  }

  Widget _buildGridItem(DocumentationFile doc) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDocument(doc),
        onLongPress: () {},  // handled by GestureDetector below
        child: GestureDetector(
          onLongPressStart: (details) =>
              _showDocumentContextMenu(context, details.globalPosition, doc),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildLargeThumbnail(doc)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                doc.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  //  Toolbar actions
  // -----------------------------------------------------------------------

  Widget _menuItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }

  /// Handle "Create New" dropdown selection.
  void _onCreateNew(String type) {
    final link = widget.source.geofeatureLink;
    if (link == null) return;
    final cavePlaceId = link.type == GeofeatureType.cavePlace ? link.geofeatureId : null;
    final caveId = link.type == GeofeatureType.cave ? link.geofeatureId : null;
    final caveAreaId = link.type == GeofeatureType.caveArea ? link.geofeatureId : null;

    switch (type) {
      case 'text':
        _navigateAndRefresh(
          TextDocumentEditorPage(
            cavePlaceId: cavePlaceId,
            caveId: caveId,
            caveAreaId: caveAreaId,
          ),
        );
        break;
      case 'rich_text':
        _navigateAndRefresh(
          RichTextEditorPage(
            cavePlaceId: cavePlaceId,
            caveId: caveId,
            caveAreaId: caveAreaId,
          ),
        );
        break;
      case 'image_edit':
        _navigateAndRefresh(
          ImageEditorPage(
            cavePlaceId: cavePlaceId,
            caveId: caveId,
            caveAreaId: caveAreaId,
          ),
        );
        break;
      case 'camera':
        _navigateAndRefresh(
          CameraCapturePage(
            cavePlaceId: cavePlaceId,
            caveId: caveId,
            caveAreaId: caveAreaId,
          ),
        );
        break;
      case 'audio':
        _navigateAndRefresh(
          SoundRecorderPage(
            cavePlaceId: cavePlaceId,
            caveId: caveId,
            caveAreaId: caveAreaId,
          ),
        );
        break;
    }
  }

  /// Handle "Add from existing file" dropdown selection.
  void _onAddFromFile(String type) {
    final link = widget.source.geofeatureLink;
    if (link == null) return;
    _navigateAndRefresh(
      EditDocumentationFilePage(
        cavePlaceId: link.type == GeofeatureType.cavePlace ? link.geofeatureId : null,
        caveId: link.type == GeofeatureType.cave ? link.geofeatureId : null,
        caveAreaId: link.type == GeofeatureType.caveArea ? link.geofeatureId : null,
      ),
    );
  }

  /// Open a document explicitly in viewer mode.
  Future<void> _openDocumentForViewing(DocumentationFile doc) async {
    if (doc.fileName.isEmpty) return;
    final file = await getDocumentsFile(doc.fileName);
    if (file == null || !mounted) return;

    final handler = DocumentFormatRegistry.instance.handlerForDoc(doc);
    final page = handler?.buildEditableViewer(
          file: file,
          doc: doc,
          geofeatureLink: widget.source.geofeatureLink,
        ) ??
        DocumentationFileViewer(file: file, doc: doc);
    _navigateAndRefresh(page);
  }

  /// Open a document explicitly in editor mode.
  Future<void> _openDocumentForEditing(DocumentationFile doc) async {
    if (doc.fileName.isEmpty) return;
    final handler = DocumentFormatRegistry.instance.handlerForDoc(doc);
    if (handler?.buildEditor == null) return;

    final link = widget.source.geofeatureLink;
    final editor = handler!.buildEditor!(
      cavePlaceId:
          link?.type == GeofeatureType.cavePlace ? link!.geofeatureId : null,
      caveId: link?.type == GeofeatureType.cave ? link!.geofeatureId : null,
      caveAreaId:
          link?.type == GeofeatureType.caveArea ? link!.geofeatureId : null,
      existingDoc: doc,
    );
    _navigateAndRefresh(editor);
  }

  /// Shows a context menu for the given document with View / Edit options.
  void _showDocumentContextMenu(
      BuildContext context, Offset position, DocumentationFile doc) {
    final handler = DocumentFormatRegistry.instance.handlerForDoc(doc);
    final hasViewer = handler?.hasViewer ?? false;
    final hasEditor = handler?.hasEditor ?? false;

    if (!hasViewer && !hasEditor) {
      // No actions available — just open as usual.
      _openDocument(doc);
      return;
    }

    final items = <PopupMenuEntry<String>>[
      if (hasViewer)
        PopupMenuItem(
          value: 'view',
          child: Row(children: [
            const Icon(Icons.visibility, size: 20),
            const SizedBox(width: 10),
            Text(LocServ.inst.t('open_viewer')),
          ]),
        ),
      if (hasEditor)
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            const Icon(Icons.edit, size: 20),
            const SizedBox(width: 10),
            Text(LocServ.inst.t('edit')),
          ]),
        ),
    ];

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx, position.dy),
      items: items,
    ).then((value) {
      if (value == 'view') {
        _openDocumentForViewing(doc);
      } else if (value == 'edit') {
        _openDocumentForEditing(doc);
      }
    });
  }

  /// Push a page and reload the document list when it returns `true`.
  /// Also evicts cached file images so edited thumbnails refresh.
  Future<void> _navigateAndRefresh(Widget page) async {
    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (result == true) {
      imageCache.clear();
      imageCache.clearLiveImages();
      await _loadDocuments();
    }
  }

  // -----------------------------------------------------------------------
  //  Sliver builders
  // -----------------------------------------------------------------------

  List<Widget> _buildContentSlivers() {
    if (_filteredDocs.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(child: Text(LocServ.inst.t('no_documents'))),
        ),
      ];
    }

    return switch (_viewMode) {
      DocViewMode.list            => [_buildListSliver()],
      DocViewMode.listByCategory  => _buildListByCategorySlivers(),
      DocViewMode.grid            => [_buildGridSliver()],
      DocViewMode.gridByCategory  => _buildGridByCategorySlivers(),
      DocViewMode.gridHorizontal  => _buildHorizontalGridSlivers(),
    };
  }

  List<Widget> _buildListByCategorySlivers() {
    final groups = _groupByCategory();
    final slivers = <Widget>[];

    for (final entry in groups.entries) {
      final category = entry.key;
      final docs = entry.value;
      final collapsed = _collapsedCategories.contains(category);

      // --- category header ---
      slivers.add(SliverToBoxAdapter(
        child: _CategoryHeader(
          icon: _categoryIcon(category),
          label: '${_categoryLabel(category)} (${docs.length})',
          collapsed: collapsed,
          onTap: () => setState(() {
            collapsed
                ? _collapsedCategories.remove(category)
                : _collapsedCategories.add(category);
          }),
        ),
      ));

      // --- items (visible only when expanded) ---
      if (!collapsed) {
        slivers.add(SliverList.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) => _buildListItem(docs[i]),
        ));
      }
    }

    return slivers;
  }

  Widget _buildListSliver() {
    return SliverList.separated(
      itemCount: _filteredDocs.length,
      itemBuilder: (_, i) => _buildListItem(_filteredDocs[i]),
      separatorBuilder: (_, __) => const Divider(height: 1),
    );
  }

  Widget _buildGridSliver() {
    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: _filteredDocs.length,
        itemBuilder: (_, i) => _buildGridItem(_filteredDocs[i]),
      ),
    );
  }

  /// Grid view grouped by category — each category has a header followed
  /// by a grid section.
  List<Widget> _buildGridByCategorySlivers() {
    final groups = _groupByCategory();
    final slivers = <Widget>[];

    for (final entry in groups.entries) {
      final category = entry.key;
      final docs = entry.value;
      final collapsed = _collapsedCategories.contains(category);

      slivers.add(SliverToBoxAdapter(
        child: _CategoryHeader(
          icon: _categoryIcon(category),
          label: '${_categoryLabel(category)} (${docs.length})',
          collapsed: collapsed,
          onTap: () => setState(() {
            collapsed
                ? _collapsedCategories.remove(category)
                : _collapsedCategories.add(category);
          }),
        ),
      ));

      if (!collapsed) {
        slivers.add(SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: docs.length,
            itemBuilder: (_, i) => _buildGridItem(docs[i]),
          ),
        ));
      }
    }

    return slivers;
  }

  /// Horizontal-scroll grid grouped by category. Each category shows a
  /// header and a horizontally-scrollable grid with [_horizontalGridRows]
  /// rows of cards.
  List<Widget> _buildHorizontalGridSlivers() {
    final groups = _groupByCategory();
    final slivers = <Widget>[];

    const double itemWidth = 150;
    const double itemSpacing = 8;
    final double itemHeight = itemWidth / 0.8; // matches childAspectRatio 0.8
    final double totalHeight =
        itemHeight * _horizontalGridRows +
        itemSpacing * (_horizontalGridRows - 1) +
        16; // vertical padding

    for (final entry in groups.entries) {
      final category = entry.key;
      final docs = entry.value;
      final collapsed = _collapsedCategories.contains(category);

      slivers.add(SliverToBoxAdapter(
        child: _CategoryHeader(
          icon: _categoryIcon(category),
          label: '${_categoryLabel(category)} (${docs.length})',
          collapsed: collapsed,
          onTap: () => setState(() {
            collapsed
                ? _collapsedCategories.remove(category)
                : _collapsedCategories.add(category);
          }),
        ),
      ));

      if (!collapsed) {
        slivers.add(SliverToBoxAdapter(
          child: SizedBox(
            height: totalHeight,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _horizontalGridRows,
                mainAxisSpacing: itemSpacing,
                crossAxisSpacing: itemSpacing,
                childAspectRatio: 0.8,
              ),
              itemCount: docs.length,
              itemBuilder: (_, i) => _buildGridItem(docs[i]),
            ),
          ),
        ));
      }
    }

    return slivers;
  }

  // -----------------------------------------------------------------------
  //  build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.source.geofeatureTitle),
            if (widget.source.parentTitle != null)
              Text(
                widget.source.parentTitle!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          if (widget.source.geofeatureLink != null) ...[
          // ---- Create New dropdown ----
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: LocServ.inst.t('create_new'),
            onSelected: _onCreateNew,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'text',
                child: _menuItem(Icons.text_snippet, LocServ.inst.t('new_text_document')),
              ),
              PopupMenuItem(
                value: 'rich_text',
                child: _menuItem(Icons.text_format, LocServ.inst.t('new_rich_text')),
              ),
              PopupMenuItem(
                value: 'image_edit',
                child: _menuItem(Icons.image, LocServ.inst.t('new_image_edit')),
              ),
              PopupMenuItem(
                value: 'camera',
                child: _menuItem(Icons.camera_alt, LocServ.inst.t('new_photo')),
              ),
              PopupMenuItem(
                value: 'audio',
                child: _menuItem(Icons.mic, LocServ.inst.t('new_audio_recording')),
              ),
            ],
          ),
          // ---- Add from existing file dropdown ----
          PopupMenuButton<String>(
            icon: const Icon(Icons.attach_file),
            tooltip: LocServ.inst.t('add_from_file'),
            onSelected: _onAddFromFile,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'text',
                child: _menuItem(Icons.text_snippet, LocServ.inst.t('doc_type_text')),
              ),
              PopupMenuItem(
                value: 'image',
                child: _menuItem(Icons.image, LocServ.inst.t('doc_type_photo')),
              ),
              PopupMenuItem(
                value: 'audio',
                child: _menuItem(Icons.audiotrack, LocServ.inst.t('doc_type_audio')),
              ),
            ],
          ),
          ],
          buildAppBarMenuButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              key: PageStorageKey<DocViewMode>(_viewMode),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ControlsHeaderDelegate(
                    viewMode: _viewMode,
                    sortField: _sortField,
                    sortAscending: _sortAscending,
                    horizontalGridRows: _horizontalGridRows,
                    searchController: _searchCtrl,
                    onViewModeChanged: (m) =>
                        setState(() => _viewMode = m),
                    onSortChanged: (f, asc) {
                      _sortField = f;
                      _sortAscending = asc;
                      _applyFilter();
                    },
                    onHorizontalGridRowsChanged: (rows) =>
                        setState(() => _horizontalGridRows = rows),
                  ),
                ),
                ..._buildContentSlivers(),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
//  _CategoryHeader  (used inside "by-category" mode slivers)
// ---------------------------------------------------------------------------

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.icon,
    required this.label,
    required this.collapsed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              collapsed ? Icons.expand_more : Icons.expand_less,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  _ControlsHeaderDelegate  (pinned sliver for view-mode + search + sort)
// ---------------------------------------------------------------------------

class _ControlsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ControlsHeaderDelegate({
    required this.viewMode,
    required this.sortField,
    required this.sortAscending,
    required this.horizontalGridRows,
    required this.searchController,
    required this.onViewModeChanged,
    required this.onSortChanged,
    required this.onHorizontalGridRowsChanged,
  });

  final DocViewMode viewMode;
  final DocSortField sortField;
  final bool sortAscending;
  final int horizontalGridRows;
  final TextEditingController searchController;
  final ValueChanged<DocViewMode> onViewModeChanged;
  final void Function(DocSortField field, bool ascending) onSortChanged;
  final ValueChanged<int> onHorizontalGridRowsChanged;

  /// Extra height for the rows selector shown in gridHorizontal mode.
  bool get _showRowSelector => viewMode == DocViewMode.gridHorizontal;
  static const double _kBaseHeight = 110;
  static const double _kRowSelectorHeight = 36;
  double get _kHeight =>
      _kBaseHeight + (_showRowSelector ? _kRowSelectorHeight : 0);

  @override
  double get maxExtent => _kHeight;

  @override
  double get minExtent => _kHeight;

  /// Always rebuild so that the search-field clear button reacts to text
  /// changes (the parent calls setState on every keystroke via the listener).
  @override
  bool shouldRebuild(covariant _ControlsHeaderDelegate old) => true;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent || shrinkOffset > 0 ? 2 : 0,
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: _kHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            // --- Row 1: view-mode selector + sort button ---
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<DocViewMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: DocViewMode.list,
                        icon: const Icon(Icons.list, size: 18),
                        tooltip: LocServ.inst.t('view_list'),
                      ),
                      ButtonSegment(
                        value: DocViewMode.listByCategory,
                        icon: const Icon(Icons.format_list_bulleted, size: 18),
                        tooltip: LocServ.inst.t('view_list_by_category'),
                      ),
                      ButtonSegment(
                        value: DocViewMode.grid,
                        icon: const Icon(Icons.grid_view, size: 18),
                        tooltip: LocServ.inst.t('view_grid'),
                      ),
                      ButtonSegment(
                        value: DocViewMode.gridByCategory,
                        icon: const Icon(Icons.dashboard, size: 18),
                        tooltip: LocServ.inst.t('view_grid_by_category'),
                      ),
                      ButtonSegment(
                        value: DocViewMode.gridHorizontal,
                        icon: const Icon(Icons.view_carousel, size: 18),
                        tooltip: LocServ.inst.t('view_grid_horizontal'),
                      ),
                    ],
                    selected: {viewMode},
                    onSelectionChanged: (s) {
                      if (s.isEmpty) return;
                      onViewModeChanged(s.first);
                    },
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<DocSortField>(
                  icon: const Icon(Icons.sort, size: 22),
                  tooltip: LocServ.inst.t('sort_by'),
                  onSelected: (field) {
                    onSortChanged(
                      field,
                      field == sortField ? !sortAscending : true,
                    );
                  },
                  itemBuilder: (_) => DocSortField.values.map((f) {
                    final label = switch (f) {
                      DocSortField.title => LocServ.inst.t('title'),
                      DocSortField.type => LocServ.inst.t('doc_sort_type'),
                      DocSortField.size => LocServ.inst.t('file_size'),
                      DocSortField.date => LocServ.inst.t('doc_sort_date'),
                    };
                    return PopupMenuItem(
                      value: f,
                      child: Row(
                        children: [
                          if (f == sortField)
                            Icon(
                              sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                            )
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
              const SizedBox(height: 6),
              // --- Row 2: search field ---
              SizedBox(
                height: 36,
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: LocServ.inst.t('search_documents'),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: searchController.clear,
                            padding: EdgeInsets.zero,
                          )
                        : null,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              // --- Row 3 (optional): horizontal-grid rows selector ---
              if (_showRowSelector) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      LocServ.inst.t('rows'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: WidgetStatePropertyAll(
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                      ),
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1', style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: 2, label: Text('2', style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: 3, label: Text('3', style: TextStyle(fontSize: 12))),
                      ],
                      selected: {horizontalGridRows},
                      onSelectionChanged: (s) {
                        if (s.isEmpty) return;
                        onHorizontalGridRowsChanged(s.first);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
