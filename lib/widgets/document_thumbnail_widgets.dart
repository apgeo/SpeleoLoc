import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

enum DocumentThumbnailSize { small, large }

/// Shared helper widgets for document thumbnails.
class DocumentThumbnailWidgets {
  const DocumentThumbnailWidgets._();

  static Widget iconTile({
    required BuildContext context,
    required IconData icon,
    required DocumentThumbnailSize size,
    Color? tint,
    String? extLabel,
  }) {
    final isSmall = size == DocumentThumbnailSize.small;
    final baseColor = tint ?? Theme.of(context).colorScheme.primary;

    if (isSmall) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, size: 22, color: baseColor)),
            if (extLabel != null)
              Positioned(
                right: 3,
                bottom: 3,
                child: _extChip(extLabel),
              ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Icon(icon, size: 42, color: baseColor)),
        ),
        if (extLabel != null)
          Positioned(
            right: 6,
            bottom: 6,
            child: _extChip(extLabel),
          ),
      ],
    );
  }

  static Widget imageTile({
    required File file,
    required DocumentThumbnailSize size,
  }) {
    final isSmall = size == DocumentThumbnailSize.small;
    if (isSmall) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          file,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          cacheWidth: 96,
        ),
      );
    }

    return Image.file(file, fit: BoxFit.cover, cacheWidth: 300);
  }

  static Widget textSnippetTile({
    required BuildContext context,
    required File? file,
    required String fileName,
    required DocumentThumbnailSize size,
    required IconData cornerIcon,
  }) {
    final isSmall = size == DocumentThumbnailSize.small;
    final radius = isSmall ? 4.0 : 8.0;

    Widget content = FutureBuilder<String>(
      future: _readPreviewText(file, fileName),
      builder: (context, snapshot) {
        final text = (snapshot.data ?? '').trim();
        final lines = text.isEmpty ? '...' : text;
        return Text(
          lines,
          maxLines: isSmall ? 4 : 7,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isSmall ? 7.5 : 10.5,
            height: 1.15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        );
      },
    );

    if (isSmall) {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        child: content,
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 26, 8),
        child: content,
      );
    }

    Widget tile = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: content),
            Positioned(
              top: isSmall ? 2 : 5,
              right: isSmall ? 2 : 5,
              child: Icon(cornerIcon, size: isSmall ? 10 : 14),
            ),
          ],
        ),
      ),
    );

    if (isSmall) {
      tile = SizedBox(
        width: 48,
        height: 48,
        child: tile,
      );
    }

    return tile;
  }

  static Widget _extChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 7, color: Colors.white),
      ),
    );
  }

  static Future<String> _readPreviewText(File? file, String fileName) async {
    if (file == null || !await file.exists()) return '';
    try {
      final bytes = await file.openRead(0, 4096).fold<List<int>>(
        <int>[],
        (all, chunk) {
          all.addAll(chunk);
          return all;
        },
      );
      var raw = utf8.decode(bytes, allowMalformed: true);
      if (fileName.toLowerCase().endsWith('.rtf')) {
        raw = _stripRtf(raw);
      }
      return raw
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
    } catch (_) {
      return '';
    }
  }

  static String _stripRtf(String input) {
    var text = input;
    text = text.replaceAll(RegExp(r'\\par[d]?'), '\n');
    text = text.replaceAll(RegExp(r'\\[a-zA-Z]+-?\d* ?'), '');
    text = text.replaceAll(RegExp(r"\\'[0-9a-fA-F]{2}"), '');
    text = text.replaceAll(RegExp(r'[{}]'), '');
    return text;
  }
}
