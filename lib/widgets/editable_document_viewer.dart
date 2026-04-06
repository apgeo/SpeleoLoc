import 'dart:io';

import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/document_format_registry.dart';
import 'package:speleoloc/utils/localization.dart';

/// A wrapper that adds a floating "edit" button to any document viewer widget.
///
/// The edit button only appears when the document's format has a registered
/// editor ([DocumentFormatHandler.hasEditor]).
///
/// **Usage in the registry:**
/// ```dart
/// buildViewer: ({required file, required doc}) =>
///     EditableDocumentViewer(
///       doc: doc,
///       file: file,
///       child: MyActualViewer(file: file, doc: doc),
///     ),
/// ```
class EditableDocumentViewer extends StatelessWidget {
  const EditableDocumentViewer({
    super.key,
    required this.doc,
    required this.file,
    required this.child,
    this.geofeatureLink,
  });

  final DocumentationFile doc;
  final File file;

  /// The actual viewer widget (must be a full-page [Scaffold]).
  final Widget child;

  /// Optional geofeature link used when opening the editor. When `null` the
  /// editor is opened in pure edit mode (no parent ids).
  final DocumentationGeofeatureLink? geofeatureLink;

  @override
  Widget build(BuildContext context) {
    final handler = DocumentFormatRegistry.instance.handlerForDoc(doc);
    final hasEditor = handler?.hasEditor ?? false;

    if (!hasEditor) return child;

    return Stack(
      children: [
        child,
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'editableDocViewer_${doc.id}',
            tooltip: LocServ.inst.t('edit'),
            onPressed: () => _openEditor(context, handler!),
            child: const Icon(Icons.edit),
          ),
        ),
      ],
    );
  }

  void _openEditor(BuildContext context, DocumentFormatHandler handler) {
    final link = geofeatureLink;
    final editor = handler.buildEditor!(
      cavePlaceId:
          link?.type == GeofeatureType.cavePlace ? link!.geofeatureId : null,
      caveId: link?.type == GeofeatureType.cave ? link!.geofeatureId : null,
      caveAreaId:
          link?.type == GeofeatureType.caveArea ? link!.geofeatureId : null,
      existingDoc: doc,
    );

    Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => editor),
    ).then((result) {
      if (result == true && context.mounted) {
        // Pop the viewer too so the list refreshes.
        Navigator.pop(context, true);
      }
    });
  }
}
