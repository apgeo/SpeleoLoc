import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/raster_map_place_selector.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/raster_map_place_point_editor.dart';

/// Renders the "Raster maps" tab content for a single [RasterMap] in
/// [CavePlacePage]. Owns its own image-path and definitions caches so the
/// parent page doesn't have to juggle per-raster-map state.
///
/// The widget:
///   1. Resolves the on-disk path of [rasterMap]'s image file.
///   2. Loads the list of cave-place-to-raster-map definitions.
///   3. Displays either a plain [Image] (default) or the interactive
///      [RasterMapPlacePointEditor] depending on [useInteractiveEditor].
///   4. Offers an edit-location button that opens
///      [RasterMapPlaceSelectorPage] for the given [cavePlaceId].
///
/// When [cavePlaceId] is `null` the caller is responsible for saving the
/// cave-place first; [onSaveRequired] is invoked and must return the newly
/// created cave-place id (or `null` to abort).
class CavePlaceMapTab extends StatefulWidget {
  const CavePlaceMapTab({
    super.key,
    required this.caveId,
    required this.cavePlaceId,
    required this.rasterMap,
    required this.onSaveRequired,
    this.useInteractiveEditor = false,
  });

  final int caveId;
  final int? cavePlaceId;
  final RasterMap rasterMap;

  /// Called when the user taps "define place" while no cave-place exists yet.
  /// Must return the id of the newly saved cave-place, or `null` to abort.
  final Future<int?> Function() onSaveRequired;

  /// Toggle: show the interactive [RasterMapPlacePointEditor] (readonly)
  /// instead of a plain [Image] in the tab body.
  final bool useInteractiveEditor;

  @override
  State<CavePlaceMapTab> createState() => _CavePlaceMapTabState();
}

class _CavePlaceMapTabState extends State<CavePlaceMapTab> {
  Future<String>? _imagePathFuture;
  Future<List<CavePlaceWithDefinition>>? _definitionsFuture;

  static final _log = AppLogger.of('CavePlaceMapTab');

  @override
  void initState() {
    super.initState();
    _imagePathFuture = _resolveImagePath(widget.rasterMap.fileName);
    _definitionsFuture = _loadDefinitions();
  }

  @override
  void didUpdateWidget(covariant CavePlaceMapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rasterMap.id != widget.rasterMap.id ||
        oldWidget.rasterMap.fileName != widget.rasterMap.fileName) {
      _imagePathFuture = _resolveImagePath(widget.rasterMap.fileName);
      _definitionsFuture = _loadDefinitions();
    }
  }

  Future<String> _resolveImagePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  Future<List<CavePlaceWithDefinition>> _loadDefinitions() {
    return appDatabase.getCavePlacesWithDefinitionsForRasterMap(
      widget.caveId,
      widget.rasterMap.id,
    );
  }

  void _invalidateDefinitions() {
    if (!mounted) return;
    setState(() {
      _definitionsFuture = _loadDefinitions();
    });
  }

  Future<void> _definePlace() async {
    final rm = widget.rasterMap;
    _log.fine('_definePlace rasterMapId=${rm.id}');

    var cavePlaceId = widget.cavePlaceId;
    if (cavePlaceId == null) {
      cavePlaceId = await widget.onSaveRequired();
      if (cavePlaceId == null) return;
    }

    _log.fine(
      'Opening place selector for cavePlaceId=$cavePlaceId rasterMapId=${rm.id}',
    );
    final existing = await appDatabase.getDefinition(cavePlaceId, rm.id);
    final cavePlacesWithDefs = await appDatabase
        .getCavePlacesWithDefinitionsForRasterMap(widget.caveId, rm.id);

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RasterMapPlaceSelectorPage(
          // Force rebuild when cavePlaceId or rasterMap changes.
          key: ValueKey(
            'place_selector_widget_${cavePlaceId}_${rm.id}_${Random().nextInt(100000000)}',
          ),
          rasterMap: rm,
          cavePlaceId: cavePlaceId!,
          cavePlacesWithDefinitions: cavePlacesWithDefs,
          existingDefinition: existing,
        ),
      ),
    );

    _invalidateDefinitions();
  }

  Widget _buildImage() {
    return FutureBuilder<String>(
      future: _imagePathFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(LocServ.inst.t('error')));
        }
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final file = File(snapshot.data!);
        if (!file.existsSync()) {
          return Text(LocServ.inst.t('image_not_found'));
        }
        return FutureBuilder<List<CavePlaceWithDefinition>>(
          future: _definitionsFuture,
          builder: (context, defsSnap) {
            if (!defsSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final defs = defsSnap.data!;
            if (widget.useInteractiveEditor) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox(
                  height: 300,
                  child: RasterMapPlacePointEditor(
                    controller: RasterMapPlacePointEditorController(
                      showLegend: false,
                      showZoomControls: false,
                      gestureZoomEnabled: false,
                    ),
                    imageFile: file,
                    cavePlacesWithDefinitions: defs,
                    isReadonly: true,
                    debugUi: false,
                  ),
                ),
              );
            }
            // Legacy rendering: plain Image widget.
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _definePlace,
                child: _buildImage(),
              ),
              Positioned(
                left: 4,
                top: 4,
                child: Opacity(
                  opacity: 0.65,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _definePlace,
                      icon: const Icon(
                        Icons.edit_location_alt,
                        color: Colors.white,
                      ),
                      tooltip: LocServ.inst.t('define_place_on_map'),
                      iconSize: 20,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
