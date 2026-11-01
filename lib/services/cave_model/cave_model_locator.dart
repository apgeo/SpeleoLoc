import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/current_survey_models.dart';
import 'package:speleoloc/services/repository_interfaces.dart';

/// The model a cave opens in 3D, with the place's mapping in it when the
/// screen was opened for a place.
class ModelToOpen {
  const ModelToOpen(this.model, {this.mapping});

  final DocumentationFile model;
  final CavePlaceModelStation? mapping;
}

/// Finds a cave's survey models and the one to open.
class CaveModelLocator {
  CaveModelLocator(
    this._documents,
    this._defaults,
    this._mappings,
    this._places, {
    CurrentSurveyModels server = const NoServerSurveyModels(),
  }) : _server = server;

  final IDocumentationRepository _documents;
  final ICavePlaceRepository _places;
  final ICaveDefaultModelRepository _defaults;
  final IPlaceStationMappingRepository _mappings;
  final CurrentSurveyModels _server;

  static const fileType = 'survey_model';

  /// The models attached to the cave: the caver's default first, then one a
  /// server marks as the cave's current line plot, then the rest newest
  /// first.
  Future<List<DocumentationFile>> modelsOf(Uuid caveUuid) async {
    final attached = (await _documents.getDocumentationFiles(
      parentLink: DocumentationGeofeatureLink(
        type: GeofeatureType.cave,
        geofeatureUuid: caveUuid,
      ),
    )).where((d) => d.fileType == fileType).toList();
    attached.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    final current = await _server.currentModelDocuments(caveUuid);
    final atCurrent = attached.indexWhere((d) => current.contains(d.uuid));
    if (atCurrent > 0) attached.insert(0, attached.removeAt(atCurrent));
    final chosen = await _defaults.defaultModelOf(caveUuid);
    final at = attached.indexWhere((d) => d.uuid == chosen);
    if (at > 0) attached.insert(0, attached.removeAt(at));
    return attached;
  }

  /// The cave a model document hangs on, directly or through one of its
  /// places, or null.
  Future<Uuid?> caveOf(DocumentationFile model) async {
    Uuid? viaPlace;
    for (final link in await _documents.geofeatureLinksOf(model.uuid)) {
      if (link.type == GeofeatureType.cave) return link.geofeatureUuid;
      if (link.type == GeofeatureType.cavePlace) {
        viaPlace ??= (await _places.findById(link.geofeatureUuid))?.caveUuid;
      }
    }
    return viaPlace;
  }

  /// The model to open for the cave, or null when it has none. For a place,
  /// the first model in [modelsOf] order that maps it; when none does, the
  /// first model, where the caver can map it.
  Future<ModelToOpen?> modelToOpen(Uuid caveUuid, {Uuid? cavePlaceUuid}) async {
    final models = await modelsOf(caveUuid);
    if (models.isEmpty) return null;
    if (cavePlaceUuid != null) {
      final mappings = {
        for (final m in await _mappings.mappingsForPlace(cavePlaceUuid))
          m.documentationFileUuid: m,
      };
      for (final model in models) {
        final mapping = mappings[model.uuid];
        if (mapping != null) return ModelToOpen(model, mapping: mapping);
      }
    }
    return ModelToOpen(models.first);
  }
}
