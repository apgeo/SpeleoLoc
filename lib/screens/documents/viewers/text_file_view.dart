import 'package:flutter/material.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/text_file_preview.dart';

/// Shows a plain-text or CSV file, read once and asynchronously, and only
/// its beginning when it is large.
class TextFileView extends StatefulWidget {
  const TextFileView({super.key, required this.path});

  final String path;

  @override
  State<TextFileView> createState() => _TextFileViewState();
}

class _TextFileViewState extends State<TextFileView> {
  late final Future<TextFilePreview> _preview = _load();

  Future<TextFilePreview> _load() async {
    try {
      return await TextFilePreview.load(widget.path);
    } catch (e, st) {
      AppLogger.of(
        'TextFileView',
      ).warning('Failed to read ${widget.path}', e, st);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TextFilePreview>(
      future: _preview,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(LocServ.inst.t('text_file_preview_failed')),
          );
        }
        final preview = snapshot.data;
        if (preview == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (preview.truncated)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      LocServ.inst.t('text_file_preview_truncated', {
                        'shown': '${preview.shownBytes ~/ 1024}',
                        'total': '${(preview.totalBytes / 1024).ceil()}',
                      }),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                SelectableText(preview.text),
              ],
            ),
          ),
        );
      },
    );
  }
}
