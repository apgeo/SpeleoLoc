import 'dart:io';

import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/widgets/editable_document_viewer.dart';
import 'package:speleoloc/screens/documents/editors/camera_capture_page.dart';
import 'package:speleoloc/screens/documents/editors/image_editor_page.dart';
import 'package:speleoloc/screens/documents/editors/rich_text_editor_page.dart';
import 'package:speleoloc/screens/documents/editors/sound_recorder_page.dart';
import 'package:speleoloc/screens/documents/editors/text_document_editor_page.dart';
import 'package:speleoloc/screens/documents/viewers/documentation_file_viewer.dart';
import 'package:speleoloc/screens/documents/viewers/sound_file_viewer.dart';
import 'package:speleoloc/widgets/document_thumbnail_widgets.dart';

typedef DocumentThumbnailBuilder = Widget Function({
  required BuildContext context,
  required DocumentationFile doc,
  required File? resolvedFile,
  required DocumentThumbnailSize size,
});

// ---------------------------------------------------------------------------
//  DocumentFormatHandler — descriptor for one format group
// ---------------------------------------------------------------------------

/// Describes how the application handles a particular document format (or
/// group of formats sharing the same extensions).
///
/// Each handler declares:
///   * which file extensions it handles
///   * an optional **editor** factory (create / edit)
///   * an optional **viewer** factory (read-only preview)
///
/// At least one of [buildEditor] or [buildViewer] must be non-null.
class DocumentFormatHandler {
  const DocumentFormatHandler({
    required this.formatId,
    required this.label,
    required this.icon,
    required this.extensions,
    this.buildEditor,
    this.buildViewer,
    this.buildThumbnail,
  });

  /// Unique identifier for this format, e.g. `'text'`, `'image'`, `'pdf'`.
  final String formatId;

  /// Human-readable label shown in menus.
  final String label;

  /// Icon shown in menus and lists.
  final IconData icon;

  /// File-name extensions this handler covers (lower-case, no dot).
  final Set<String> extensions;

  /// Factory that returns an editor widget. Receives geofeature parent ids for
  /// new-file creation, and an optional [DocumentationFile] for editing an
  /// existing record. Returns a [Widget] that pops with `true` on success.
  final Widget Function({
    int? cavePlaceId,
    int? caveId,
    int? caveAreaId,
    DocumentationFile? existingDoc,
  })? buildEditor;

  /// Factory that returns a viewer widget. Receives the resolved [File] on
  /// disk and the DB record.
  final Widget Function({
    required File file,
    required DocumentationFile doc,
  })? buildViewer;

  /// Strategy for rendering thumbnails in list/grid modes.
  ///
  /// When null, UI falls back to generic icon placeholders.
  final DocumentThumbnailBuilder? buildThumbnail;

  bool get hasEditor => buildEditor != null;
  bool get hasViewer => buildViewer != null;

  /// Build an editor widget for a [DocumentationGeofeatureLink], unwrapping
  /// the (caveId / cavePlaceId / caveAreaId) fields from the link.
  /// Returns `null` when no editor is registered or [link] is null.
  Widget? buildEditorForLink({
    DocumentationGeofeatureLink? link,
    DocumentationFile? existingDoc,
  }) {
    if (buildEditor == null) return null;
    final cavePlaceId =
        link?.type == GeofeatureType.cavePlace ? link!.geofeatureId : null;
    final caveId =
        link?.type == GeofeatureType.cave ? link!.geofeatureId : null;
    final caveAreaId =
        link?.type == GeofeatureType.caveArea ? link!.geofeatureId : null;
    return buildEditor!(
      cavePlaceId: cavePlaceId,
      caveId: caveId,
      caveAreaId: caveAreaId,
      existingDoc: existingDoc,
    );
  }

  /// Builds a viewer widget wrapped with a floating edit button when an editor
  /// is available for this format. Returns `null` when no viewer is registered.
  Widget? buildEditableViewer({
    required File file,
    required DocumentationFile doc,
    DocumentationGeofeatureLink? geofeatureLink,
  }) {
    if (buildViewer == null) return null;
    final viewer = buildViewer!(file: file, doc: doc);
    if (!hasEditor) return viewer;
    return EditableDocumentViewer(
      doc: doc,
      file: file,
      geofeatureLink: geofeatureLink,
      child: viewer,
    );
  }
}

// ---------------------------------------------------------------------------
//  DocumentFormatRegistry — singleton registry
// ---------------------------------------------------------------------------

/// Central registry that maps file extensions to [DocumentFormatHandler]s.
///
/// Use [handlerForExtension] or [handlerForDoc] to look up the best handler
/// for a given file / document record.  The first handler whose
/// [DocumentFormatHandler.extensions] contains the extension wins,
/// so registration order matters when extensions overlap.
class DocumentFormatRegistry {
  DocumentFormatRegistry._();

  static final DocumentFormatRegistry instance = DocumentFormatRegistry._();

  final List<DocumentFormatHandler> _handlers = [];

  /// All registered handlers (read-only).
  List<DocumentFormatHandler> get handlers =>
      List.unmodifiable(_handlers);

  /// Register a new format handler.
  void register(DocumentFormatHandler handler) {
    _handlers.add(handler);
  }

  /// Look up handler by file extension (lower-case, no dot).
  DocumentFormatHandler? handlerForExtension(String ext) {
    final lower = ext.toLowerCase();
    for (final h in _handlers) {
      if (h.extensions.contains(lower)) return h;
    }
    return null;
  }

  /// Look up handler by inspecting a [DocumentationFile.fileName].
  DocumentFormatHandler? handlerForDoc(DocumentationFile doc) {
    final dot = doc.fileName.lastIndexOf('.');
    if (dot < 0) return null;
    return handlerForExtension(doc.fileName.substring(dot + 1));
  }

  /// Look up handler by its [formatId].
  DocumentFormatHandler? handlerById(String formatId) {
    for (final h in _handlers) {
      if (h.formatId == formatId) return h;
    }
    return null;
  }

  /// Returns all handlers that have an editor factory.
  List<DocumentFormatHandler> get editableFormats =>
      _handlers.where((h) => h.hasEditor).toList();

  /// Returns all handlers that have a viewer factory.
  List<DocumentFormatHandler> get viewableFormats =>
      _handlers.where((h) => h.hasViewer).toList();

  /// Resolves the best widget to open [doc] on disk at [file]:
  /// editor (when available and a [link] is provided) → editable viewer →
  /// null (caller should fall back to a generic viewer).
  Widget? buildBestOpener({
    required File file,
    required DocumentationFile doc,
    DocumentationGeofeatureLink? link,
  }) {
    final handler = handlerForDoc(doc);
    if (handler == null) return null;
    if (handler.hasEditor && link != null) {
      return handler.buildEditorForLink(link: link, existingDoc: doc);
    }
    return handler.buildEditableViewer(
      file: file,
      doc: doc,
      geofeatureLink: link,
    );
  }

  /// Builds a thumbnail widget for a document using the registered strategy.
  Widget buildThumbnail({
    required BuildContext context,
    required DocumentationFile doc,
    required File? resolvedFile,
    required DocumentThumbnailSize size,
    required Widget Function(IconData icon) fallbackBuilder,
  }) {
    final handler = handlerForDoc(doc);
    final builder = handler?.buildThumbnail;
    if (builder != null) {
      return builder(
        context: context,
        doc: doc,
        resolvedFile: resolvedFile,
        size: size,
      );
    }
    return fallbackBuilder(handler?.icon ?? Icons.insert_drive_file);
  }
}

Widget _textThumb({
  required BuildContext context,
  required DocumentationFile doc,
  required File? resolvedFile,
  required DocumentThumbnailSize size,
}) {
  return DocumentThumbnailWidgets.textSnippetTile(
    context: context,
    file: resolvedFile,
    fileName: doc.fileName,
    size: size,
    cornerIcon: Icons.description,
  );
}

Widget _imageThumb({
  required BuildContext context,
  required DocumentationFile doc,
  required File? resolvedFile,
  required DocumentThumbnailSize size,
}) {
  if (resolvedFile != null && resolvedFile.existsSync()) {
    return DocumentThumbnailWidgets.imageTile(file: resolvedFile, size: size);
  }
  return DocumentThumbnailWidgets.iconTile(
    context: context,
    icon: Icons.broken_image,
    size: size,
  );
}

DocumentThumbnailBuilder _iconThumb(
  IconData icon, {
  Color? tint,
}) {
  return ({
    required BuildContext context,
    required DocumentationFile doc,
    required File? resolvedFile,
    required DocumentThumbnailSize size,
  }) {
    final dot = doc.fileName.lastIndexOf('.');
    final ext = dot >= 0 ? doc.fileName.substring(dot + 1) : null;
    return DocumentThumbnailWidgets.iconTile(
      context: context,
      icon: icon,
      size: size,
      tint: tint,
      extLabel: ext,
    );
  };
}

// ---------------------------------------------------------------------------
//  Bootstrap — call once at app startup (e.g. in main.dart)
// ---------------------------------------------------------------------------

/// Registers all built-in format handlers.  Call early (before the first
/// [DocumentFormatRegistry.instance] lookup that expects data).
void registerBuiltInDocumentFormats() {
  final reg = DocumentFormatRegistry.instance;

  // ---- Plain text ---- (editor + viewer)
  reg.register(DocumentFormatHandler(
    formatId: 'text',
    label: 'Text document',
    icon: Icons.text_snippet,
    extensions: {'txt', 'md', 'csv', 'rtf'},
    buildEditor: ({cavePlaceId, caveId, caveAreaId, existingDoc}) =>
        TextDocumentEditorPage(
      cavePlaceId: cavePlaceId,
      caveId: caveId,
      caveAreaId: caveAreaId,
      existingDoc: existingDoc,
    ),
    buildViewer: ({required file, required doc}) =>
        DocumentationFileViewer(file: file, doc: doc),
    buildThumbnail: _textThumb,
  ));

  // ---- Image ---- (editor via pro_image_editor + viewer)
  reg.register(DocumentFormatHandler(
    formatId: 'image',
    label: 'Image',
    icon: Icons.image,
    extensions: {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'heic'},
    buildEditor: ({cavePlaceId, caveId, caveAreaId, existingDoc}) =>
        ImageEditorPage(
      cavePlaceId: cavePlaceId,
      caveId: caveId,
      caveAreaId: caveAreaId,
      existingDoc: existingDoc,
    ),
    buildViewer: ({required file, required doc}) =>
        DocumentationFileViewer(file: file, doc: doc),
    buildThumbnail: _imageThumb,
  ));

  // ---- Camera capture ---- (create-only via image_picker)
  reg.register(DocumentFormatHandler(
    formatId: 'camera',
    label: 'Take photo',
    icon: Icons.camera_alt,
    extensions: {},  // no file-extension mapping; creation-only
    buildEditor: ({cavePlaceId, caveId, caveAreaId, existingDoc}) =>
        CameraCapturePage(
      cavePlaceId: cavePlaceId,
      caveId: caveId,
      caveAreaId: caveAreaId,
    ),
  ));

  // ---- Rich text ---- (editor via flutter_quill + viewer)
  reg.register(DocumentFormatHandler(
    formatId: 'rich_text',
    label: 'Rich text',
    icon: Icons.text_format,
    extensions: {'qldoc'},
    buildEditor: ({cavePlaceId, caveId, caveAreaId, existingDoc}) =>
        RichTextEditorPage(
      cavePlaceId: cavePlaceId,
      caveId: caveId,
      caveAreaId: caveAreaId,
      existingDoc: existingDoc,
    ),
    buildViewer: ({required file, required doc}) =>
        DocumentationFileViewer(file: file, doc: doc),
    buildThumbnail: _textThumb,
  ));

  // ---- PDF ---- (viewer only)
  reg.register(DocumentFormatHandler(
    formatId: 'pdf',
    label: 'PDF',
    icon: Icons.picture_as_pdf,
    extensions: {'pdf'},
    buildViewer: ({required file, required doc}) =>
        DocumentationFileViewer(file: file, doc: doc),
    buildThumbnail: _iconThumb(Icons.picture_as_pdf, tint: Colors.red),
  ));

  // ---- Audio ---- (editor via flutter_sound + audio_waveforms)
  reg.register(DocumentFormatHandler(
    formatId: 'audio',
    label: 'Audio',
    icon: Icons.audiotrack,
    extensions: {'mp3', 'wav', 'ogg', 'm4a', 'flac'},
    buildEditor: ({cavePlaceId, caveId, caveAreaId, existingDoc}) =>
        SoundRecorderPage(
      cavePlaceId: cavePlaceId,
      caveId: caveId,
      caveAreaId: caveAreaId,
      existingDoc: existingDoc,
    ),
    buildViewer: ({required file, required doc}) =>
        SoundFileViewer(file: file, doc: doc),
    buildThumbnail: _iconThumb(Icons.audiotrack, tint: Colors.teal),
  ));

  // ---- Video ---- (no editor or viewer yet)
  reg.register(DocumentFormatHandler(
    formatId: 'video',
    label: 'Video',
    icon: Icons.videocam,
    extensions: {'mp4', 'mov', 'avi', 'mkv', 'webm'},
    buildThumbnail: _iconThumb(Icons.videocam, tint: Colors.deepOrange),
  ));

  // ---- Office docs (doc/docx/odt) ---- (viewer = generic fallback)
  reg.register(DocumentFormatHandler(
    formatId: 'office',
    label: 'Office document',
    icon: Icons.description,
    extensions: {'doc', 'docx', 'odt'},
    buildViewer: ({required file, required doc}) =>
        DocumentationFileViewer(file: file, doc: doc),
    buildThumbnail: _iconThumb(Icons.description, tint: Colors.indigo),
  ));
}
