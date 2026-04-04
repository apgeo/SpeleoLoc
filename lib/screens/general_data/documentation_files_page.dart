import 'package:flutter/material.dart';
import 'package:speleo_loc/data/source/database/app_database.dart';
import 'package:speleo_loc/screens/geofeature_documents_page.dart';
import 'package:speleo_loc/services/documents_controller.dart';
import 'package:speleo_loc/utils/localization.dart';

/// Page that lists documentation files.
///
/// When [cavePlaceId], [caveId], or [caveAreaId] is provided the page shows
/// documents for that specific geofeature.  When none is provided it shows
/// **all** documents from every cave (using [DocumentsSource.all]).
///
/// Internally this builds a [GeofeatureDocumentsPage] so all display logic
/// is shared.
class DocumentationFilesPage extends StatefulWidget {
  const DocumentationFilesPage({super.key, this.cavePlaceId, this.caveId, this.caveAreaId});

  final int? cavePlaceId;
  final int? caveId;
  final int? caveAreaId;

  @override
  State<DocumentationFilesPage> createState() => _DocumentationFilesPageState();
}

class _DocumentationFilesPageState extends State<DocumentationFilesPage> {
  DocumentsSource? _source;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolveSource();
  }

  Future<void> _resolveSource() async {
    final hasFilter = widget.cavePlaceId != null ||
        widget.caveId != null ||
        widget.caveAreaId != null;

    if (!hasFilter) {
      // Show all documents from every cave.
      _source = DocumentsSource.all(
        geofeatureTitle: LocServ.inst.t('documentation_files'),
      );
    } else {
      // Resolve the title for the specific geofeature.
      String title = '';
      String? parentTitle;

      if (widget.cavePlaceId != null) {
        final cp = await (appDatabase.select(appDatabase.cavePlaces)
              ..where((t) => t.id.equals(widget.cavePlaceId!)))
            .getSingleOrNull();
        title = cp?.title ?? '';
        // Try to get cave title as parent.
        if (cp != null) {
          final c = await (appDatabase.select(appDatabase.caves)
                ..where((t) => t.id.equals(cp.caveId)))
              .getSingleOrNull();
          parentTitle = c?.title;
        }
        _source = DocumentsSource.cavePlace(
          cavePlaceId: widget.cavePlaceId!,
          cavePlaceTitle: title,
          caveTitle: parentTitle,
        );
      } else if (widget.caveId != null) {
        final c = await (appDatabase.select(appDatabase.caves)
              ..where((t) => t.id.equals(widget.caveId!)))
            .getSingleOrNull();
        title = c?.title ?? '';
        _source = DocumentsSource.cave(
          caveId: widget.caveId!,
          caveTitle: title,
        );
      } else if (widget.caveAreaId != null) {
        final a = await (appDatabase.select(appDatabase.caveAreas)
              ..where((t) => t.id.equals(widget.caveAreaId!)))
            .getSingleOrNull();
        title = a?.title ?? '';
        _source = DocumentsSource.caveArea(
          caveAreaId: widget.caveAreaId!,
          caveAreaTitle: title,
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _source == null) {
      return Scaffold(
        appBar: AppBar(title: Text(LocServ.inst.t('documentation_files'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return GeofeatureDocumentsPage(source: _source!);
  }
}
