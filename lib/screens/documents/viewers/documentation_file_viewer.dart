import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:pdfx/pdfx.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

/// Lightweight viewer that handles common file types inline (images, text)
/// and embeds PDF rendering for `.pdf` files using `pdfx`.
class DocumentationFileViewer extends StatefulWidget {
  const DocumentationFileViewer({super.key, required this.file, required this.doc});

  final File file;
  final DocumentationFile doc;

  @override
  State<DocumentationFileViewer> createState() => _DocumentationFileViewerState();
}

class _DocumentationFileViewerState extends State<DocumentationFileViewer>
    with AppBarMenuMixin<DocumentationFileViewer> {
  PdfControllerPinch? _pdfController;

  @override
  void initState() {
    super.initState();
    final name = widget.file.path.split(Platform.pathSeparator).last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (ext == 'pdf') {
      try {
        _pdfController = PdfControllerPinch(document: PdfDocument.openFile(widget.file.path));
      } catch (_) {
        _pdfController = null;
      }
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.file.path.split(Platform.pathSeparator).last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';

    Widget body;
    if (['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'].contains(ext)) {
      body = Center(child: Image.file(widget.file));
    } else if (['txt', 'csv', 'rtf'].contains(ext)) {
      final txt = widget.file.readAsStringSync();
      body = Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(child: SelectableText(txt)),
      );
    } else if (ext == 'pdf') {
      if (_pdfController == null) {
        body = Center(child: Text(LocServ.inst.t('pdf')));
      } else {
        body = PdfViewPinch(
          controller: _pdfController!,
          scrollDirection: Axis.vertical,
          onDocumentLoaded: (doc) {},
        );
      }
    } else {
      body = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.insert_drive_file, size: 64),
          const SizedBox(height: 12),
          Text(ext.isEmpty ? LocServ.inst.t('none') : ext.toUpperCase()),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () async {
            final tmp = await _writeTempFile(name, await widget.file.readAsBytes());
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to: $tmp')));
          }, child: Text(LocServ.inst.t('save'))),
        ]),
      );
    }

    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(widget.doc.title),
        actions: [buildAppBarMenuButton()],
      ),
      body: body,
    );
  }

  Future<String> _writeTempFile(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/$name');
    await out.writeAsBytes(bytes, flush: true);
    return out.path;
  }
}
