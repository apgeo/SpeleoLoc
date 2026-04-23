import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/geofeature_documents_page.dart';
import 'package:speleoloc/services/documents_controller.dart';
import 'package:speleoloc/utils/localization.dart';

/// Page that lists documentation files.
///
/// When [cavePlaceUuid], [caveUuid], or [caveAreaUuid] is provided the page shows
/// documents for that specific geofeature.  When none is provided it shows
/// **all** documents from every cave (using [DocumentsSource.all]).
///
/// Internally this builds a [GeofeatureDocumentsPage] so all display logic
/// is shared.
class DocumentationFilesPage extends StatefulWidget {
  const DocumentationFilesPage({super.key, this.cavePlaceUuid, this.caveUuid, this.caveAreaUuid});

  final Uuid? cavePlaceUuid;
  final Uuid? caveUuid;
  final Uuid? caveAreaUuid;

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
    final hasFilter = widget.cavePlaceUuid != null ||
        widget.caveUuid != null ||
        widget.caveAreaUuid != null;

    if (!hasFilter) {
      // Show all documents from every cave.
      _source = DocumentsSource.all(
        geofeatureTitle: LocServ.inst.t('documentation_files'),
      );
    } else {
      // Resolve the title for the specific geofeature.
      String title = '';
      String? parentTitle;

      if (widget.cavePlaceUuid != null) {
        final cp = await (appDatabase.select(appDatabase.cavePlaces)
              ..where((t) => t.uuid.equalsValue(widget.cavePlaceUuid!)))
            .getSingleOrNull();
        title = cp?.title ?? '';
        // Try to get cave title as parent.
        if (cp != null) {
          final c = await (appDatabase.select(appDatabase.caves)
                ..where((t) => t.uuid.equalsValue(cp.caveUuid)))
              .getSingleOrNull();
          parentTitle = c?.title;
        }
        _source = DocumentsSource.cavePlace(
          cavePlaceUuid: widget.cavePlaceUuid!,
          cavePlaceTitle: title,
          caveTitle: parentTitle,
        );
      } else if (widget.caveUuid != null) {
        final c = await (appDatabase.select(appDatabase.caves)
              ..where((t) => t.uuid.equalsValue(widget.caveUuid!)))
            .getSingleOrNull();
        title = c?.title ?? '';
        _source = DocumentsSource.cave(
          caveUuid: widget.caveUuid!,
          caveTitle: title,
        );
      } else if (widget.caveAreaUuid != null) {
        final a = await (appDatabase.select(appDatabase.caveAreas)
              ..where((t) => t.uuid.equalsValue(widget.caveAreaUuid!)))
            .getSingleOrNull();
        title = a?.title ?? '';
        _source = DocumentsSource.caveArea(
          caveAreaUuid: widget.caveAreaUuid!,
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
