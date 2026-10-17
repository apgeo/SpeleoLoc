import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/documents/document_format_registry.dart';
import 'package:speleoloc/screens/documents/viewers/documentation_file_viewer.dart';
import 'package:speleoloc/screens/documents/viewers/image_gallery_viewer_page.dart';
import 'package:speleoloc/utils/file_utils.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/document_thumbnail_widgets.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// The pictures bound to one track point — what the media import attached
/// to the stop it created — opened from that point's row on the trip
/// screen.
///
/// Read-only on purpose: the same files are attached to the cave place too,
/// and that is where they are edited, renamed or removed.
class TripPointPicturesSheet extends StatelessWidget {
  const TripPointPicturesSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.docs,
  });

  final String title;
  final String subtitle;
  final List<DocumentationFile> docs;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<DocumentationFile> docs,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          TripPointPicturesSheet(title: title, subtitle: subtitle, docs: docs),
    );
  }

  static bool _isImage(DocumentationFile doc) =>
      DocumentFormatRegistry.instance.handlerForDoc(doc)?.formatId == 'image';

  Future<void> _open(BuildContext context, DocumentationFile doc) async {
    final navigator = Navigator.of(context);
    if (_isImage(doc)) {
      // Swipes through this point's pictures only, in the order shown.
      final images = docs.where(_isImage).toList();
      final dir = await getApplicationDocumentsDirectory();
      await navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => ImageGalleryViewerPage(
            images: images,
            initialIndex: images.indexWhere((d) => d.uuid == doc.uuid),
            docsDir: dir.path,
          ),
        ),
      );
      return;
    }
    final file = await getDocumentsFile(doc.fileName);
    if (file == null) {
      SnackBarService.showWarning(LocServ.inst.t('image_not_found'));
      return;
    }
    final page =
        DocumentFormatRegistry.instance.buildBestOpener(file: file, doc: doc) ??
        DocumentationFileViewer(file: file, doc: doc);
    await navigator.push<void>(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(subtitle),
          ),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 140,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: docs.length,
              itemBuilder: (context, i) => _Tile(
                doc: docs[i],
                isImage: _isImage(docs[i]),
                onTap: () => unawaited(_open(context, docs[i])),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.doc, required this.isImage, required this.onTap});

  final DocumentationFile doc;
  final bool isImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final handler = DocumentFormatRegistry.instance.handlerForDoc(doc);
    final icon = DocumentThumbnailWidgets.iconTile(
      context: context,
      icon: handler?.icon ?? Icons.insert_drive_file_outlined,
      size: DocumentThumbnailSize.large,
    );
    return Semantics(
      button: true,
      label: doc.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isImage
              ? FutureBuilder<File?>(
                  future: getDocumentsFile(doc.fileName),
                  builder: (context, snap) {
                    final file = snap.data;
                    if (file == null) return icon;
                    return DocumentThumbnailWidgets.imageTile(
                      file: file,
                      size: DocumentThumbnailSize.large,
                    );
                  },
                )
              : icon,
        ),
      ),
    );
  }
}
