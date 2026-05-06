import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/screens/general_data/surface_areas_page.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

class CaveFormPage extends StatefulWidget {
  final Cave? cave; // if provided, we're editing

  const CaveFormPage({super.key, this.cave});

  @override
  State<CaveFormPage> createState() => _CaveFormPageState();
}

class _CaveFormPageState extends State<CaveFormPage>
    with AppBarMenuMixin<CaveFormPage>, ProductTourMixin<CaveFormPage> {
  @override
  String get tourId => 'add_new_cave';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'title_field', titleLocKey: 'tour_add_new_cave_title_field_title', bodyLocKey: 'tour_add_new_cave_title_field_body'),
    TourStepDef(keyId: 'desc_field', titleLocKey: 'tour_add_new_cave_desc_field_title', bodyLocKey: 'tour_add_new_cave_desc_field_body'),
    TourStepDef(keyId: 'area_dropdown', titleLocKey: 'tour_add_new_cave_area_dropdown_title', bodyLocKey: 'tour_add_new_cave_area_dropdown_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_add_new_cave_menu_title', bodyLocKey: 'tour_add_new_cave_menu_body'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _saving = false;

  List<SurfaceArea> _surfaceAreas = [];
  Uuid? _selectedSurfaceAreaId;

  @override
  void initState() {
    super.initState();
    if (widget.cave != null) {
      _titleController.text = widget.cave!.title;
      _descriptionController.text = widget.cave!.description ?? '';
      _selectedSurfaceAreaId = widget.cave!.surfaceAreaUuid;
    }
    _loadSurfaceAreas();
  }

  void _loadSurfaceAreas() async {
    final areas = await (appDatabase.select(appDatabase.surfaceAreas)).get();
    if (!mounted) return;
    setState(() => _surfaceAreas = areas);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final desc = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
      if (widget.cave != null) {
        await caveRepository.updateCave(widget.cave!.uuid, _titleController.text.trim(), surfaceAreaUuid: _selectedSurfaceAreaId, description: desc);
        if (mounted) Navigator.pop(context, widget.cave!.uuid);
      } else {
        final id = await caveRepository.addCave(_titleController.text.trim(), surfaceAreaUuid: _selectedSurfaceAreaId, description: desc);
        // Auto-add entrance cave place if setting is enabled (default: true)
        final autoAdd = await SettingsHelper.loadStringConfig(autoAddEntrancePlaceKey, 'true');
        if (autoAdd == 'true') {
          await cavePlaceRepository.addCavePlace(
            id,
            LocServ.inst.t('entrance'),
            isEntrance: true,
            isMainEntrance: true,
          );
        }
        if (mounted) Navigator.pop(context, id);
      }
    } catch (e, st) {
      debugPrint('AddNewCave._save error: $e\n$st');
      if (mounted) {
        SnackBarService.showError(e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cave != null;
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? LocServ.inst.t('edit_cave') : LocServ.inst.t('add_new_cave'),
              style: const TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isEditing)
              Text(
                widget.cave!.title,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton())],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                key: tourKeys['title_field'],
                controller: _titleController,
                decoration: InputDecoration(labelText: LocServ.inst.t('cave_title')),
                validator: (v) => (v == null || v.trim().isEmpty) ? LocServ.inst.t('title_required') : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: tourKeys['desc_field'],
                controller: _descriptionController,
                decoration: InputDecoration(labelText: LocServ.inst.t('description')),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              Row(
                key: tourKeys['area_dropdown'],
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Uuid?>(
                      initialValue: _selectedSurfaceAreaId,
                      decoration: InputDecoration(labelText: LocServ.inst.t('area_title')),
                      items: [
                        DropdownMenuItem(value: null, child: Text(LocServ.inst.t('none'))),
                        ..._surfaceAreas.map((a) => DropdownMenuItem(value: a.uuid, child: Text(a.title))),
                      ],
                      onChanged: (v) => setState(() => _selectedSurfaceAreaId = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.landscape),
                    tooltip: LocServ.inst.t('manage_surface_areas'),
                    onPressed: () async {
                      final result = await Navigator.push<bool?>(
                        context,
                        MaterialPageRoute(builder: (_) => const SurfaceAreasPage()),
                      );
                      if (result == true) _loadSurfaceAreas();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? LocServ.inst.t('saving') : (isEditing ? LocServ.inst.t('save') : LocServ.inst.t('add'))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
