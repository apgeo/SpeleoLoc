import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

class CaveAreasPage extends StatefulWidget {
  const CaveAreasPage({super.key, required this.caveId});

  final int caveId;

  @override
  State<CaveAreasPage> createState() => _CaveAreasPageState();
}

class _CaveAreasPageState extends State<CaveAreasPage>
    with AppBarMenuMixin<CaveAreasPage>, ProductTourMixin<CaveAreasPage> {
  @override
  String get tourId => 'cave_areas';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'add', titleLocKey: 'tour_cave_areas_add_title', bodyLocKey: 'tour_cave_areas_add_body'),
    TourStepDef(keyId: 'list', titleLocKey: 'tour_cave_areas_list_title', bodyLocKey: 'tour_cave_areas_list_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_cave_areas_menu_title', bodyLocKey: 'tour_cave_areas_menu_body'),
  ];

  List<CaveArea> _areas = [];
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  void _loadAreas() async {
    final areas = await (appDatabase.select(appDatabase.caveAreas)..where((a) => a.caveId.equals(widget.caveId))).get();
    if (!mounted) return;
    setState(() {
      _areas = areas;
    });
  }

  Future<void> _showAddEditDialog({CaveArea? existing}) async {
    final controller = TextEditingController(text: existing?.title ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? LocServ.inst.t('add_cave_area') : LocServ.inst.t('edit')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: LocServ.inst.t('enter_area_title')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(LocServ.inst.t('cancel'))),
          TextButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              if (existing == null) {
                await appDatabase.into(appDatabase.caveAreas).insert(
                  CaveAreasCompanion.insert(title: title, caveId: widget.caveId),
                );
              } else {
                await (appDatabase.update(appDatabase.caveAreas)..where((a) => a.id.equals(existing.id))).write(
                  CaveAreasCompanion(title: Value(title)),
                );
              }
              Navigator.pop(context, true);
            },
            child: Text(LocServ.inst.t('save')),
          ),
        ],
      ),
    );

    if (result == true) {
      _changed = true;
      _loadAreas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocServ.inst.t('area_saved'))));
    }
  }

  Future<void> _confirmDelete(CaveArea area) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(LocServ.inst.t('delete_area_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(LocServ.inst.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(LocServ.inst.t('yes'))),
        ],
      ),
    );

    if (confirmed == true) {
      await (appDatabase.delete(appDatabase.caveAreas)..where((a) => a.id.equals(area.id))).go();
      _changed = true;
      _loadAreas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocServ.inst.t('area_deleted'))));
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
          title: Text(LocServ.inst.t('manage_cave_areas')),
          actions: [
            IconButton(key: tourKeys['add'], onPressed: () => _showAddEditDialog(), icon: const Icon(Icons.add)),
            KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
          ],
        ),
        body: ListView.separated(
          key: tourKeys['list'],
          itemCount: _areas.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final area = _areas[index];
            return ListTile(
              title: Text(area.title),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: () => _showAddEditDialog(existing: area), icon: const Icon(Icons.edit)),
                  IconButton(onPressed: () => _confirmDelete(area), icon: const Icon(Icons.delete)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
