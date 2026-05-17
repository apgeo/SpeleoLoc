import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/place_code_batch_ui.dart';
import 'package:speleoloc/services/place_code/batch/place_code_batch_runner.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

class SurfaceAreasPage extends StatefulWidget {
  const SurfaceAreasPage({super.key});

  @override
  State<SurfaceAreasPage> createState() => _SurfaceAreasPageState();
}

class _SurfaceAreasPageState extends State<SurfaceAreasPage>
    with AppBarMenuMixin<SurfaceAreasPage>, ProductTourMixin<SurfaceAreasPage> {
  @override
  String get tourId => 'surface_areas';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'add', titleLocKey: 'tour_surface_areas_add_title', bodyLocKey: 'tour_surface_areas_add_body'),
    TourStepDef(keyId: 'list', titleLocKey: 'tour_surface_areas_list_title', bodyLocKey: 'tour_surface_areas_list_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_surface_areas_menu_title', bodyLocKey: 'tour_surface_areas_menu_body'),
  ];

  List<SurfaceArea> _areas = [];
  bool _changed = false;
  bool _showGenerateIcons = false;

  @override
  List<AppMenuItem> get screenMenuItems => [
    AppMenuItem(
      value: 'toggle_generate_icons',
      icon: _showGenerateIcons ? Icons.check_box : Icons.check_box_outline_blank,
      label: LocServ.inst.t('show_generate_codes_icons'),
    ),
  ];

  @override
  void onScreenMenuItemSelected(String value) {
    if (value == 'toggle_generate_icons') {
      setState(() => _showGenerateIcons = !_showGenerateIcons);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  void _loadAreas() async {
    final areas = await (appDatabase.select(appDatabase.surfaceAreas)).get();
    if (!mounted) return;
    setState(() {
      _areas = areas;
    });
  }

  Future<void> _showAddEditDialog({SurfaceArea? existing}) async {
    final controller = TextEditingController(text: existing?.title ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final identifierController =
        TextEditingController(text: existing?.generalAreaIdentifier ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? LocServ.inst.t('add_surface_area') : LocServ.inst.t('edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: LocServ.inst.t('enter_surface_area_title')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: identifierController,
              decoration: InputDecoration(
                labelText: LocServ.inst.t('general_area_identifier'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: LocServ.inst.t('description')),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          if (existing != null)
            TextButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(LocServ.inst.t('generate_codes')),
              onPressed: () async {
                await PlaceCodeBatchUi.run(
                  context,
                  scope: PerAreaScope(existing.uuid),
                  confirmTitle: LocServ.inst.t('generate_codes'),
                  confirmBody: LocServ.inst.t('generate_codes_confirm_area'),
                );
              },
            ),
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(LocServ.inst.t('cancel'))),
          TextButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              final desc = descController.text.trim().isEmpty ? null : descController.text.trim();
              final identifier = identifierController.text.trim().isEmpty
                  ? null
                  : identifierController.text.trim();
              final now = DateTime.now().millisecondsSinceEpoch;
              final author = await currentUserService.currentOrSystem();
              if (existing == null) {
                final newUuid = Uuid.v7();
                await appDatabase.into(appDatabase.surfaceAreas).insert(
                  SurfaceAreasCompanion.insert(
                    uuid: newUuid,
                    title: title,
                    description: Value(desc),
                    generalAreaIdentifier: Value(identifier),
                    createdAt: Value(now),
                    updatedAt: Value(now),
                    createdByUserUuid: Value(author),
                    lastModifiedByUserUuid: Value(author),
                  ),
                );
                await changeLogger.logInsert('surface_areas', newUuid);
              } else {
                await (appDatabase.update(appDatabase.surfaceAreas)..where((a) => a.uuid.equalsValue(existing.uuid))).write(
                  SurfaceAreasCompanion(
                    title: Value(title),
                    description: Value(desc),
                    generalAreaIdentifier: Value(identifier),
                    updatedAt: Value(now),
                    lastModifiedByUserUuid: Value(author),
                  ),
                );
                await changeLogger.logUpdate(
                  'surface_areas',
                  existing.uuid,
                  oldValues: {
                    'title': existing.title,
                    'description': existing.description,
                    'general_area_identifier': existing.generalAreaIdentifier,
                  },
                  newValues: {
                    'title': title,
                    'description': desc,
                    'general_area_identifier': identifier,
                  },
                );
              }
              if (!context.mounted) return;
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
      SnackBarService.showSuccess(LocServ.inst.t('surface_area_saved'));
    }
  }

  Future<void> _confirmDelete(SurfaceArea area) async {
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
      await (appDatabase.delete(appDatabase.surfaceAreas)..where((a) => a.uuid.equalsValue(area.uuid))).go();
      await changeLogger.logDelete(
        'surface_areas',
        area.uuid,
        oldValues: {
          'title': area.title,
          'description': area.description,
        },
      );
      _changed = true;
      _loadAreas();
      if (!mounted) return;
      SnackBarService.showSuccess(LocServ.inst.t('surface_area_deleted'));
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
          title: Text(LocServ.inst.t('manage_surface_areas')),
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
              subtitle: area.description != null && area.description!.isNotEmpty
                  ? Text(area.description!, style: const TextStyle(fontSize: 12, color: Colors.grey))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showGenerateIcons)
                    IconButton(
                      onPressed: () => PlaceCodeBatchUi.run(
                        context,
                        scope: PerAreaScope(area.uuid),
                        confirmTitle: LocServ.inst.t('generate_codes'),
                        confirmBody:
                            LocServ.inst.t('generate_codes_confirm_area'),
                      ),
                      icon: const Icon(Icons.auto_awesome),
                      tooltip: LocServ.inst.t('generate_codes'),
                    ),
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
