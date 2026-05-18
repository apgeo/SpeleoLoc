import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// A full-screen image viewer with pinch-to-zoom and pan support.
///
/// Push this route via [FullScreenImageViewer.show] or navigate to it directly.
class FullScreenImageViewer extends StatelessWidget {
  const FullScreenImageViewer({
    super.key,
    required this.imageFile,
    this.title,
  });

  final File imageFile;

  /// Optional title shown in the AppBar. When null the AppBar title is empty.
  final String? title;

  /// Convenience helper that pushes a full-screen route for [imageFile].
  static Future<void> show(
    BuildContext context,
    File imageFile, {
    String? title,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullScreenImageViewer(
          imageFile: imageFile,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: title != null ? Text(title!, style: const TextStyle(color: Colors.white)) : null,
      ),
      body: PhotoView(
        imageProvider: FileImage(imageFile),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 5.0,
        initialScale: PhotoViewComputedScale.contained,
        enableRotation: false,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
        ),
      ),
    );
  }
}
