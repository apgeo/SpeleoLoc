import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/image_compression_settings.dart';
import 'package:speleoloc/utils/image_compressor.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/full_screen_image_viewer.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Whether to apply image compression when picking raster map images.
const bool kCompressRasterMapImages = false;

class RasterMapForm extends StatefulWidget {
  const RasterMapForm({super.key, required this.caveUuid, this.rasterMap});

  final Uuid caveUuid;
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
  String? _pendingFileHash; // hash of the newly-picked image file (null when not changed)
  int? _pendingFileSize;   // size in bytes of the newly-picked image file

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
      final directory = await getApplicationDocumentsDirectory();
      _fullImagePath = '${directory.path}/$_imagePath';
      final file = File(_fullImagePath!);
      if (!await file.exists()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SnackBarService.showWarning(LocServ.inst.t('image_file_not_found_warning'));
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
      final subfolder = Directory('${directory.path}/cave_${widget.caveUuid}');
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

      // Compute SHA-256 hash and file size for duplicate detection.
      final bytes = await savedFile.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      final size = bytes.length;

      setState(() {
        _imagePath = 'cave_${widget.caveUuid}/$fileName';
        _fullImagePath = savedFile.path;
        _pendingFileHash = hash;
        _pendingFileSize = size;
      });
    }
  }

  void _save() async {
    if (_imagePath == null || _selectedMapType == null) {
      SnackBarService.showWarning(LocServ.inst.t('please_select_image_and_map_type'));
      return;
    }

    // Use filename (without extension) as title when user left title empty.
    String title = _titleController.text.trim();
    if (title.isEmpty) {
      final base = _imagePath!.split('/').last;
      final dot = base.lastIndexOf('.');
      title = dot > 0 ? base.substring(0, dot) : base;
      _titleController.text = title;
    }

    // Check for a duplicate (title, map_type, cave_uuid) matching the DB UNIQUE constraint.
    final existingMaps = await (appDatabase.select(appDatabase.rasterMaps)
          ..where((rm) =>
              rm.caveUuid.equalsValue(widget.caveUuid) &
              rm.title.equals(title) &
              rm.mapType.equals(_selectedMapType!)))
        .get();
    final isDuplicate = existingMaps.any(
      (rm) => widget.rasterMap == null || rm.uuid != widget.rasterMap!.uuid,
    );
    if (isDuplicate) {
      SnackBarService.showWarning(LocServ.inst.t('raster_map_title_duplicate'));
      return;
    }

    // Check for a duplicate image (same SHA-256 hash, same cave).
    // Only run this check when a new image was picked in this session.
    if (_pendingFileHash != null) {
      final hashMatches = await (appDatabase.select(appDatabase.rasterMaps)
            ..where((rm) =>
                rm.caveUuid.equalsValue(widget.caveUuid) &
                rm.fileHash.equals(_pendingFileHash!)))
          .get();
      RasterMap? hashDuplicate;
      for (final rm in hashMatches) {
        if (widget.rasterMap == null || rm.uuid != widget.rasterMap!.uuid) {
          hashDuplicate = rm;
          break;
        }
      }
      if (hashDuplicate != null && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(LocServ.inst.t('raster_map_image_duplicate_title')),
            content: Text(
              LocServ.inst.t('raster_map_image_duplicate_body').replaceFirst(
                '{title}',
                hashDuplicate?.title ?? '',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(LocServ.inst.t('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(LocServ.inst.t('save_anyway')),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    // Resolve the hash/size to persist: prefer the just-picked values; for
    // edits without a new image, carry over the existing stored values.
    final fileHash = _pendingFileHash ?? widget.rasterMap?.fileHash;
    final fileSize = _pendingFileSize ?? widget.rasterMap?.fileSize;

    if (widget.rasterMap != null) {
      final updated = RasterMap(
        uuid: widget.rasterMap!.uuid,
        title: title,
        mapType: _selectedMapType!,
        fileName: _imagePath!,
        fileHash: fileHash,
        fileSize: fileSize,
        caveUuid: widget.caveUuid,
        caveAreaUuid: widget.rasterMap!.caveAreaUuid,
      );
      await rasterMapRepository.updateRasterMap(updated);
    } else {
      final companion = RasterMapsCompanion.insert(
        uuid: Uuid.v7(),
        title: title,
        mapType: _selectedMapType!,
        fileName: _imagePath!,
        fileHash: Value(fileHash),
        fileSize: Value(fileSize),
        caveUuid: widget.caveUuid,
      );
      await rasterMapRepository.addRasterMap(companion);
    }
    if (mounted) Navigator.pop(context, true);
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
              decoration: InputDecoration(labelText: '${LocServ.inst.t('title')}'),
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
                child: GestureDetector(
                  onTap: () => FullScreenImageViewer.show(
                    context,
                    File(_fullImagePath!),
                    title: _titleController.text.trim().isNotEmpty
                        ? _titleController.text.trim()
                        : null,
                  ),
                  child: Image.file(
                    File(_fullImagePath!),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
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
                DropdownMenuItem(value: 'other', child: Text(LocServ.inst.t('other'))),
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