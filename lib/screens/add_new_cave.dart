import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/screens/general_data/surface_areas_page.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

class AddNewCave extends StatefulWidget {
  final Cave? cave; // if provided, we're editing

  const AddNewCave({super.key, this.cave});

  @override
  State<AddNewCave> createState() => _AddNewCaveState();
}

class _AddNewCaveState extends State<AddNewCave>
    with AppBarMenuMixin<AddNewCave> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _saving = false;

  List<SurfaceArea> _surfaceAreas = [];
  int? _selectedSurfaceAreaId;

  @override
  void initState() {
    super.initState();
    if (widget.cave != null) {
      _titleController.text = widget.cave!.title;
      _descriptionController.text = widget.cave!.description ?? '';
      _selectedSurfaceAreaId = widget.cave!.surfaceAreaId;
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
        await caveRepository.updateCave(widget.cave!.id, _titleController.text.trim(), surfaceAreaId: _selectedSurfaceAreaId, description: desc);
        if (mounted) Navigator.pop(context, widget.cave!.id);
      } else {
        final id = await caveRepository.addCave(_titleController.text.trim(), surfaceAreaId: _selectedSurfaceAreaId, description: desc);
        if (mounted) Navigator.pop(context, id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${LocServ.inst.t('error')}: $e')));
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
        title: Text(isEditing ? LocServ.inst.t('edit_cave') : LocServ.inst.t('add_new_cave')),
        actions: [buildAppBarMenuButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: LocServ.inst.t('cave_title')),
                validator: (v) => (v == null || v.trim().isEmpty) ? LocServ.inst.t('title_required') : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: LocServ.inst.t('description')),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _selectedSurfaceAreaId,
                      decoration: InputDecoration(labelText: LocServ.inst.t('area_title')),
                      items: [
                        DropdownMenuItem(value: null, child: Text(LocServ.inst.t('none'))),
                        ..._surfaceAreas.map((a) => DropdownMenuItem(value: a.id, child: Text(a.title))),
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
                      child: Text(_saving ? LocServ.inst.t('saving') : LocServ.inst.t('add')),
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
