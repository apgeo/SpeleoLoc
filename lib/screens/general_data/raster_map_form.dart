import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/image_compression_settings.dart';
import 'package:speleoloc/utils/image_compressor.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// Whether to apply image compression when picking raster map images.
const bool kCompressRasterMapImages = false;

class RasterMapForm extends StatefulWidget {
  const RasterMapForm({super.key, required this.caveId, this.rasterMap});

  final int caveId;
  final RasterMap? rasterMap;

  @override
  State<RasterMapForm> createState() => _RasterMapFormState();
}

class _RasterMapFormState extends State<RasterMapForm>
    with AppBarMenuMixin<RasterMapForm>, ProductTourMixin<RasterMapForm> {
  @override
  String get tourId => 'raster_map_form';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'title_field', titleLocKey: 'tour_raster_map_form_title_field_title', bodyLocKey: 'tour_raster_map_form_title_field_body'),
    TourStepDef(keyId: 'type_dropdown', titleLocKey: 'tour_raster_map_form_type_dropdown_title', bodyLocKey: 'tour_raster_map_form_type_dropdown_body'),
    TourStepDef(keyId: 'image_picker', titleLocKey: 'tour_raster_map_form_image_picker_title', bodyLocKey: 'tour_raster_map_form_image_picker_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_raster_map_form_menu_title', bodyLocKey: 'tour_raster_map_form_menu_body'),
  ];

  String? _selectedMapType;
  String? _imagePath;  String? _fullImagePath;  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.rasterMap != null) {
      _titleController.text = widget.rasterMap!.title;
      _selectedMapType = widget.rasterMap!.mapType;
      _imagePath = widget.rasterMap!.fileName;
      _setFullImagePath();
    } else {
      // Default select 'plane view' when adding a new raster map
      _selectedMapType = 'plane view';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _setFullImagePath() async {
    if (_imagePath != null) {
      final localContext = context;
      final directory = await getApplicationDocumentsDirectory();
      _fullImagePath = '${directory.path}/$_imagePath';
      final file = File(_fullImagePath!);
      if (!await file.exists()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(localContext).showSnackBar(
              SnackBar(content: Text(LocServ.inst.t('image_file_not_found_warning'))),
            );
          }
        });
      }
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Save to local documents directory in subfolder
      final directory = await getApplicationDocumentsDirectory();
      final subfolder = Directory('${directory.path}/cave_${widget.caveId}');
      if (!await subfolder.exists()) {
        await subfolder.create(recursive: true);
      }
      final fileName = 'raster_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(pickedFile.path).copy('${subfolder.path}/$fileName');

      // Apply image compression if enabled by constant and settings.
      if (kCompressRasterMapImages) {
        final compressionSettings = await ImageCompressionSettings.load();
        await ImageCompressor.compressFile(savedFile, compressionSettings);
      }

      setState(() {
        _imagePath = 'cave_${widget.caveId}/$fileName';
        _fullImagePath = savedFile.path;
      });
    }
  }

  void _save() async {
    if (_imagePath != null && _selectedMapType != null) {
      final title = _titleController.text.isEmpty ? null : _titleController.text;
      if (widget.rasterMap != null) {
        // Update
        final updated = RasterMap(
          id: widget.rasterMap!.id,
          title: title ?? widget.rasterMap!.title,
          mapType: _selectedMapType!,
          fileName: _imagePath!,
          caveId: widget.caveId,
          caveAreaId: widget.rasterMap!.caveAreaId,
        );
        await rasterMapRepository.updateRasterMap(updated);
      } else {
        // Insert
        final companion = RasterMapsCompanion.insert(
          title: title ?? '?????', //todo: fix this
          mapType: _selectedMapType!,
          fileName: _imagePath!,
          caveId: widget.caveId,
        );
        await rasterMapRepository.addRasterMap(companion);
      }
      if (mounted) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocServ.inst.t('please_select_image_and_map_type'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(widget.rasterMap != null ? LocServ.inst.t('edit_raster_map') : LocServ.inst.t('add_raster_map')),
        actions: [KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton())],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              key: tourKeys['title_field'],
              controller: _titleController,
              decoration: InputDecoration(labelText: '${LocServ.inst.t('title')} (${LocServ.inst.t('cave')})'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: tourKeys['image_picker'],
              onPressed: _pickImage,
              child: Text(LocServ.inst.t('select_image')),
            ),
            if (_fullImagePath != null && File(_fullImagePath!).existsSync())
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Image.file(
                  File(_fullImagePath!),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else if (_fullImagePath != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(LocServ.inst.t('image_file_not_found_warning')),
              ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              key: tourKeys['type_dropdown'],
              value: _selectedMapType,
              hint: Text(LocServ.inst.t('map_type')),
              items: [
                DropdownMenuItem(value: 'plane view', child: Text(LocServ.inst.t('plane_view'))),
                DropdownMenuItem(value: 'projected profile', child: Text(LocServ.inst.t('projected_profile'))),
                DropdownMenuItem(value: 'extended profile', child: Text(LocServ.inst.t('extended_profile'))),
              ],
              onChanged: (value) => setState(() => _selectedMapType = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text(LocServ.inst.t('save')),
            ),
          ],
        ),
      ),
    );
  }
}