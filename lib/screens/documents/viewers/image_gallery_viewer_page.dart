import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// Full-screen, swipeable image gallery for a list of image [DocumentationFile]s.
///
/// Opened when the user taps an image in the documents list: it shows the
/// tapped image and lets them swipe left/right through the other images in the
/// same (already filtered/sorted) list, each with pinch-to-zoom and pan. This
/// is a read-only viewer — editing stays on the list's long-press menu.
class ImageGalleryViewerPage extends StatefulWidget {
  const ImageGalleryViewerPage({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.docsDir,
  });

  /// Image documents to page through, in display order.
  final List<DocumentationFile> images;

  /// Index (into [images]) of the image to show first.
  final int initialIndex;

  /// Absolute path of the app documents directory; [DocumentationFile.fileName]
  /// is stored relative to it.
  final String docsDir;

  @override
  State<ImageGalleryViewerPage> createState() => _ImageGalleryViewerPageState();
}

class _ImageGalleryViewerPageState extends State<ImageGalleryViewerPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.images.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  File _fileFor(DocumentationFile doc) =>
      File('${widget.docsDir}/${doc.fileName}');

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
        ),
      );
    }
    final current = widget.images[_index];
    final title = current.title.isNotEmpty ? current.title : current.fileName;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_index + 1} / ${widget.images.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      body: PhotoViewGallery.builder(
        pageController: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        builder: (context, index) {
          final doc = widget.images[index];
          final file = _fileFor(doc);
          if (!file.existsSync()) {
            return PhotoViewGalleryPageOptions.customChild(
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
              ),
            );
          }
          return PhotoViewGalleryPageOptions(
            imageProvider: FileImage(file),
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 5.0,
            initialScale: PhotoViewComputedScale.contained,
          );
        },
      ),
    );
  }
}
