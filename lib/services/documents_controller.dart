import 'package:flutter/foundation.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

// ---------------------------------------------------------------------------
//  DocumentsSource — describes where documents come from
// ---------------------------------------------------------------------------

/// Immutable descriptor that identifies the geofeature whose documentation
/// files should be displayed or managed.
///
/// Pass an instance of this class to the documents-list page instead of raw
/// IDs so that the page is source-agnostic and works equally well with
/// cave places, caves, and cave areas.
class DocumentsSource {
  const DocumentsSource({
    required this.geofeatureLink,
    required this.geofeatureTitle,
    this.parentTitle,
  });

  /// The link that identifies the geofeature (type + id).
  /// When `null`, the source represents *all* documents (no filter).
  final DocumentationGeofeatureLink? geofeatureLink;

  /// Display title of the geofeature (e.g. cave place name, cave name, …).
  final String geofeatureTitle;

  /// Optional parent context shown as a subtitle (e.g. the cave name when
  /// displaying documents of a cave place, or the cave area title).
  final String? parentTitle;

  /// Convenience — the geofeature type (null when showing all documents).
  GeofeatureType? get type => geofeatureLink?.type;

  /// Convenience — the geofeature id (null when showing all documents).
  Uuid? get geofeatureUuid => geofeatureLink?.geofeatureUuid;

  /// Whether this source represents all documents (no geofeature filter).
  bool get isAll => geofeatureLink == null;

  /// All documents across every geofeature.
  const DocumentsSource.all({
    required this.geofeatureTitle,
  })  : geofeatureLink = null,
        parentTitle = null;

  // Typed constructors for the three supported sources -----------------------

  /// Documents belonging to a **cave place**.
  factory DocumentsSource.cavePlace({
    required Uuid cavePlaceUuid,
    required String cavePlaceTitle,
    String? caveTitle,
  }) {
    return DocumentsSource(
      geofeatureLink: DocumentationGeofeatureLink(
        type: GeofeatureType.cavePlace,
        geofeatureUuid: cavePlaceUuid,
      ),
      geofeatureTitle: cavePlaceTitle,
      parentTitle: caveTitle,
    );
  }

  /// Documents belonging to a **cave**.
  factory DocumentsSource.cave({
    required Uuid caveUuid,
    required String caveTitle,
  }) {
    return DocumentsSource(
      geofeatureLink: DocumentationGeofeatureLink(
        type: GeofeatureType.cave,
        geofeatureUuid: caveUuid,
      ),
      geofeatureTitle: caveTitle,
    );
  }

  /// Documents belonging to a **cave area**.
  factory DocumentsSource.caveArea({
    required Uuid caveAreaUuid,
    required String caveAreaTitle,
    String? caveTitle,
  }) {
    return DocumentsSource(
      geofeatureLink: DocumentationGeofeatureLink(
        type: GeofeatureType.caveArea,
        geofeatureUuid: caveAreaUuid,
      ),
      geofeatureTitle: caveAreaTitle,
      parentTitle: caveTitle,
    );
  }
}

// ---------------------------------------------------------------------------
//  DocumentsController — loads & caches documents for a given source
// ---------------------------------------------------------------------------

/// A lightweight controller that loads [DocumentationFile] records from the
/// database for a given [DocumentsSource].
///
/// The controller is intentionally separated from the widget so that the page
/// stays source-agnostic.
class DocumentsController extends ChangeNotifier {
  DocumentsController(this.source);

  final DocumentsSource source;

  List<DocumentationFile> _documents = [];
  List<DocumentationFile> get documents => _documents;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Loads (or reloads) the document list from the database.
  Future<void> loadDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _documents = await appDatabase.getDocumentationFiles(
        parentLink: source.geofeatureLink,
      );
    } catch (e) {
      _documents = [];
      _error = e.toString();
      debugPrint('[DocumentsController] Error loading documents: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
