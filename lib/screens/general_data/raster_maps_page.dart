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
import 'package:speleoloc/widgets/product_tour.dart';

class RasterMapsPage extends StatefulWidget {
  const RasterMapsPage({super.key, required this.caveId});

  final int caveId;

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

  @override
  void initState() {
    super.initState();
    _loadRasterMaps();
  }

  void _loadRasterMaps() async {
    _rasterMaps = await rasterMapRepository.getRasterMaps(widget.caveId);
    if (mounted) setState(() {});
  }

  void _deleteRasterMap(int id) async {
    await rasterMapRepository.deleteRasterMap(id);
    _changed = true;
    _loadRasterMaps();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocServ.inst.t('raster_map_deleted'))),
      );
    }
  }

  Future<void> _confirmDeleteRasterMap(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text('${LocServ.inst.t('delete')}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(LocServ.inst.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(LocServ.inst.t('yes'))),
        ],
      ),
    );
    if (confirmed == true) {
      _deleteRasterMap(id);
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
    if (await file.exists()) {
      try {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Image.file(file),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        _editRasterMap(rm);
      }
    } else {
      if (!mounted) return;
      _editRasterMap(rm);
    }
  }

  void _editRasterMap(RasterMap rm) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RasterMapForm(caveId: widget.caveId, rasterMap: rm)),
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
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RasterMapForm(caveId: widget.caveId)),
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
      body: SingleChildScrollView(
        key: tourKeys['list'],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocServ.inst.t('raster_maps'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          onPressed: () => _confirmDeleteRasterMap(rm.id),
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
      ),
      )
    );
  }
}