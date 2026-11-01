import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/screens/cave_model/cave_model_viewer_page.dart';

/// A survey model opened from its document: shown with the cave it hangs on,
/// so its places can be mapped, once that cave is known.
class CaveModelDocumentPage extends ConsumerWidget {
  const CaveModelDocumentPage({
    super.key,
    required this.file,
    required this.doc,
  });

  final File file;
  final DocumentationFile doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<Uuid?>(
    future: ref.read(caveModelLocatorProvider).caveOf(doc),
    builder: (context, cave) => cave.connectionState != ConnectionState.done
        ? const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          )
        : CaveModelViewerPage(
            file: file,
            title: doc.title,
            model: doc,
            caveUuid: cave.data,
          ),
  );
}
