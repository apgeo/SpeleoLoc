import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
// fix import as bellow
// import 'package:speleoloc/screens/general_data/raster_map_form.dart';
import 'raster_map_form.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/icon_action_button.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/full_screen_image_viewer.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

class RasterMapsPage extends StatefulWidget {
  const RasterMapsPage({super.key, required this.caveUuid});

  final Uuid caveUuid;

  @override
  State<RasterMapsPage> createState() => _RasterMapsPageState();
}

class _RasterMapsPageState extends State<RasterMapsPage>
    with AppBarMenuMixin<RasterMapsPage>, ProductTourMixin<RasterMapsPage> {
  @override
  String get tourId => 'raster_maps';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'add', titleLocKey: 'tour_raster_maps_add_title', bodyLocKey: 'tour_raster_maps_add_body'),
    TourStepDef(keyId: 'list', titleLocKey: 'tour_raster_maps_list_title', bodyLocKey: 'tour_raster_maps_list_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_raster_maps_menu_title', bodyLocKey: 'tour_raster_maps_menu_body'),
  ];

  List<RasterMap> _rasterMaps = [];

  bool _changed = false;
  bool _reorderMode = false;

  @override
  void initState() {
    super.initState();
    _loadRasterMaps();
  }

  void _loadRasterMaps() async {
    _rasterMaps = await rasterMapRepository.getRasterMaps(widget.caveUuid);
    if (mounted) setState(() {});
  }

  void _deleteRasterMap(Uuid id) async {
    await rasterMapRepository.deleteRasterMap(id);
    _changed = true;
    _loadRasterMaps();
    if (mounted) {
      SnackBarService.showSuccess(LocServ.inst.t('raster_map_deleted'));
    }
  }

  Future<void> _forceDeleteRasterMap(Uuid id) async {
    await definitionRepository.deleteAllDefinitionsForRasterMap(id);
    await rasterMapRepository.deleteRasterMap(id);
    _changed = true;
    _loadRasterMaps();
    if (mounted) {
      SnackBarService.showSuccess(LocServ.inst.t('raster_map_deleted'));
    }
  }

  Future<void> _confirmDeleteRasterMap(Uuid id) async {
    final loc = LocServ.inst;
    final count = await definitionRepository.countDefinitionsForRasterMap(id);
    if (!mounted) return;
    if (count > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(loc.t('confirm')),
          content: Text(
            loc.t('raster_map_has_definitions').replaceAll('{count}', '$count'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.t('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(loc.t('delete')),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        _forceDeleteRasterMap(id);
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(loc.t('confirm')),
          content: Text('${loc.t('delete')}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.t('cancel'))),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(loc.t('yes'))),
          ],
        ),
      );
      if (confirmed == true) {
        _deleteRasterMap(id);
      }
    }
  }
Future<String> _getFullImagePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  void _viewImage(RasterMap rm) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/${rm.fileName}';
    final file = File(filePath);
    if (!await file.exists()) {
      if (!mounted) return;
      _editRasterMap(rm);
      return;
    }
    if (!mounted) return;
    await FullScreenImageViewer.show(context, file, title: rm.title);
  }

  void _editRasterMap(RasterMap rm) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RasterMapForm(caveUuid: widget.caveUuid, rasterMap: rm)),
    );
    if (result == true) {
      _changed = true;
      _loadRasterMaps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('raster_maps')),
        actions: [
          IconButton(
            key: tourKeys['add'],
            icon: const Icon(Icons.add),
            tooltip: LocServ.inst.t('add_raster_map'),
            onPressed: _reorderMode ? null : () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RasterMapForm(caveUuid: widget.caveUuid)),
              );
              if (result == true) {
                _changed = true;
                _loadRasterMaps();
              }
            },
          ),
          KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Compact toolbar ──────────────────────────────────────────
          Material(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  Text(
                    _reorderMode
                        ? LocServ.inst.t('reorder_maps_hint')
                        : '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.sort,
                      color: _reorderMode
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    tooltip: _reorderMode
                        ? LocServ.inst.t('reorder_maps_done')
                        : LocServ.inst.t('reorder_maps'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _reorderMode = !_reorderMode),
                  ),
                ],
              ),
            ),
          ),
          // ── List ─────────────────────────────────────────────────────
          Expanded(
            child: _reorderMode ? _buildReorderableList() : _buildNormalList(),
          ),
        ],
      ),
      )
    );
  }

  Widget _buildNormalList() {
    return SingleChildScrollView(
      key: tourKeys['list'],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._rasterMaps.map((rm) => Column(
              children: [
                ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: FutureBuilder<String>(
                      future: _getFullImagePath(rm.fileName),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.file(
                            File(snapshot.data!),
                            fit: BoxFit.cover,
                          );
                        } else {
                          return const Icon(Icons.image);
                        }
                      },
                    ),
                  ),
                  title: Text(rm.title),
                  onTap: () => _viewImage(rm),
                  hoverColor: Colors.grey[200],
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconActionButton(
                        onPressed: () => _editRasterMap(rm),
                        icon: Icons.edit,
                        tooltip: LocServ.inst.t('edit_raster_map'),
                      ),
                      const SizedBox(width: 8),
                      IconActionButton(
                        onPressed: () => _confirmDeleteRasterMap(rm.uuid),
                        icon: Icons.delete,
                        tooltip: LocServ.inst.t('delete_raster_map'),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[300]),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableList() {
    return ReorderableListView.builder(
      key: tourKeys['list'],
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _rasterMaps.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;
        setState(() {
          final item = _rasterMaps.removeAt(oldIndex);
          _rasterMaps.insert(newIndex, item);
        });
        _changed = true;
        await rasterMapRepository.updateRasterMapOrder(
          _rasterMaps.map((rm) => rm.uuid).toList(),
        );
      },
      itemBuilder: (context, index) {
        final rm = _rasterMaps[index];
        return ReorderableDragStartListener(
          key: ValueKey(rm.uuid),
          index: index,
          child: Column(
            children: [
              ListTile(
                leading: SizedBox(
                  width: 50,
                  height: 50,
                  child: FutureBuilder<String>(
                    future: _getFullImagePath(rm.fileName),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.file(File(snapshot.data!), fit: BoxFit.cover);
                      } else {
                        return const Icon(Icons.image);
                      }
                    },
                  ),
                ),
                title: Text(rm.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    const Icon(Icons.drag_handle, color: Colors.grey),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[300]),
            ],
          ),
        );
      },
    );
  }
}