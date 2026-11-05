import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/file_digest.dart';
import 'package:speleoloc/utils/image_compression_settings.dart';
import 'package:speleoloc/utils/image_compressor.dart';
import 'package:speleoloc/utils/image_format_sniffer.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/full_screen_image_viewer.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/widgets/raster_map_image_cache.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Whether to apply image compression when picking raster map images.
const bool kCompressRasterMapImages = false;

class RasterMapForm extends ConsumerStatefulWidget {
  const RasterMapForm({super.key, required this.caveUuid, this.rasterMap});

  final Uuid caveUuid;
  final RasterMap? rasterMap;

  @override
  ConsumerState<RasterMapForm> createState() => _RasterMapFormState();
}

class _RasterMapFormState extends ConsumerState<RasterMapForm>
    with AppBarMenuMixin<RasterMapForm>, ProductTourMixin<RasterMapForm> {
  @override
  String get tourId => 'raster_map_form';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(
      keyId: 'title_field',
      titleLocKey: 'tour_raster_map_form_title_field_title',
      bodyLocKey: 'tour_raster_map_form_title_field_body',
    ),
    TourStepDef(
      keyId: 'type_dropdown',
      titleLocKey: 'tour_raster_map_form_type_dropdown_title',
      bodyLocKey: 'tour_raster_map_form_type_dropdown_body',
    ),
    TourStepDef(
      keyId: 'image_picker',
      titleLocKey: 'tour_raster_map_form_image_picker_title',
      bodyLocKey: 'tour_raster_map_form_image_picker_body',
    ),
    TourStepDef(
      keyId: 'menu',
      titleLocKey: 'tour_raster_map_form_menu_title',
      bodyLocKey: 'tour_raster_map_form_menu_body',
    ),
  ];

  String? _selectedMapType;
  String? _imagePath;
  String? _fullImagePath;
  final _titleController = TextEditingController();
  String?
  _pendingFileHash; // hash of the newly-picked image file (null when not changed)
  int? _pendingFileSize; // size in bytes of the newly-picked image file

  /// Path of the copy made when an image was picked and not stored yet. It
  /// is removed again when another image replaces it or the form closes
  /// without saving, so abandoned picks do not pile up in the cave folder.
  String? _unsavedPickPath;

  /// True while a pick or a save is running; both buttons are off meanwhile.
  bool _busy = false;
  static final _log = AppLogger.of('RasterMapForm');

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
    final unsaved = _unsavedPickPath;
    if (unsaved != null) unawaited(_deleteQuietly(unsaved));
    super.dispose();
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (e, st) {
      _log.warning('could not remove an unused map image', e, st);
    }
  }

  Future<void> _setFullImagePath() async {
    if (_imagePath != null) {
      final directory = await getApplicationDocumentsDirectory();
      _fullImagePath = '${directory.path}/$_imagePath';
      final file = File(_fullImagePath!);
      if (!await file.exists()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SnackBarService.showWarning(
              LocServ.inst.t('image_file_not_found_warning'),
            );
          }
        });
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    String? copiedPath;
    try {
      copiedPath = await _pickAndStoreImage();
    } on Exception catch (e, st) {
      _log.warning('picking the map image failed', e, st);
      if (mounted) {
        SnackBarService.showError(LocServ.inst.t('raster_map_image_failed'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    // A copy that never made it into the form is of no use to anyone.
    if (copiedPath != null && copiedPath != _unsavedPickPath) {
      unawaited(_deleteQuietly(copiedPath));
    }
  }

  /// Copies the picked image into the cave folder and puts it in the form.
  /// Returns the copy's path when it was made but not taken over (the form
  /// closed meanwhile), otherwise null.
  Future<String?> _pickAndStoreImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Save to local documents directory in subfolder
      final directory = await getApplicationDocumentsDirectory();
      final subfolder = Directory('${directory.path}/cave_${widget.caveUuid}');
      if (!await subfolder.exists()) {
        await subfolder.create(recursive: true);
      }
      // The name carries the format the bytes really have; the picker may
      // hand over a PNG or WebP.
      final stamp = DateTime.now().millisecondsSinceEpoch;
      var ext = ImageFormatSniffer.extensionForPicked(
        await ImageFormatSniffer.readHead(pickedFile.path),
        pickedFile.name,
      );
      var fileName = 'raster_$stamp.$ext';
      var savedFile = await File(
        pickedFile.path,
      ).copy('${subfolder.path}/$fileName');

      // Apply image compression if enabled by constant and settings.
      if (kCompressRasterMapImages) {
        final compressionSettings = await ImageCompressionSettings.load();
        await ImageCompressor.compressFile(savedFile, compressionSettings);
        // Compression re-encodes as JPEG, so the name follows the result.
        final afterExt = ImageFormatSniffer.extensionFor(
          await ImageFormatSniffer.readHead(savedFile.path),
        );
        if (afterExt != null && afterExt != ext) {
          ext = afterExt;
          fileName = 'raster_$stamp.$ext';
          savedFile = await savedFile.rename('${subfolder.path}/$fileName');
        }
      }

      // Drop any cached decode for this path so viewers re-decode the new
      // bytes. Filenames are timestamped (so this is normally a no-op), but
      // this keeps the decoded-image cache correct if a path is ever reused.
      invalidateDecodedImage(savedFile.path);

      // Hash and size for duplicate detection.
      final FileDigest digest;
      try {
        digest = await FileDigest.of(savedFile.path);
      } on Exception {
        await _deleteQuietly(savedFile.path);
        rethrow;
      }
      if (!mounted) return savedFile.path;

      final replaced = _unsavedPickPath;
      setState(() {
        _imagePath = 'cave_${widget.caveUuid}/$fileName';
        _fullImagePath = savedFile.path;
        _pendingFileHash = digest.sha256Hex;
        _pendingFileSize = digest.size;
        _unsavedPickPath = savedFile.path;
      });
      if (replaced != null) unawaited(_deleteQuietly(replaced));
    }
    return null;
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_imagePath == null || _selectedMapType == null) {
      SnackBarService.showWarning(
        LocServ.inst.t('please_select_image_and_map_type'),
      );
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

    setState(() => _busy = true);
    var saved = false;
    try {
      saved = await _saveChecked(title);
    } on DuplicateEntryException {
      if (mounted) {
        SnackBarService.showWarning(
          LocServ.inst.t('raster_map_title_duplicate'),
        );
      }
    } on Exception catch (e, st) {
      _log.warning('saving the raster map failed', e, st);
      if (mounted) {
        SnackBarService.showError(LocServ.inst.t('raster_map_save_failed'));
      }
    } finally {
      // After a successful save the form is closing; keep it locked through
      // the exit transition.
      if (!saved && mounted) setState(() => _busy = false);
    }
  }

  /// Runs the duplicate checks and the write. Returns whether the form was
  /// closed after storing the map.
  Future<bool> _saveChecked(String title) async {
    // Check for a duplicate (title, map_type, cave_uuid) matching the DB UNIQUE constraint.
    final existingMaps = await ref
        .read(rasterMapRepositoryProvider)
        .findRasterMapsByTitleAndType(
          caveUuid: widget.caveUuid,
          title: title,
          mapType: _selectedMapType!,
        );
    final isDuplicate = existingMaps.any(
      (rm) => widget.rasterMap == null || rm.uuid != widget.rasterMap!.uuid,
    );
    if (isDuplicate) {
      SnackBarService.showWarning(LocServ.inst.t('raster_map_title_duplicate'));
      return false;
    }

    // Check for a duplicate image (same SHA-256 hash, same cave).
    // Only run this check when a new image was picked in this session.
    if (_pendingFileHash != null) {
      final hashMatches = await ref
          .read(rasterMapRepositoryProvider)
          .findRasterMapsByHash(
            caveUuid: widget.caveUuid,
            hash: _pendingFileHash!,
          );
      RasterMap? hashDuplicate;
      for (final rm in hashMatches) {
        if (widget.rasterMap == null || rm.uuid != widget.rasterMap!.uuid) {
          hashDuplicate = rm;
          break;
        }
      }
      if (!mounted) return false;
      if (hashDuplicate != null) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(LocServ.inst.t('raster_map_image_duplicate_title')),
            content: Text(
              LocServ.inst
                  .t('raster_map_image_duplicate_body')
                  .replaceFirst('{title}', hashDuplicate?.title ?? ''),
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
        if (proceed != true) return false;
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
        orderIndex: widget.rasterMap!.orderIndex,
      );
      await ref.read(rasterMapRepositoryProvider).updateRasterMap(updated);
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
      await ref.read(rasterMapRepositoryProvider).addRasterMap(companion);
    }
    if (!mounted) return false;
    // The picked image now belongs to the stored map.
    _unsavedPickPath = null;
    Navigator.pop(context, true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(
          widget.rasterMap != null
              ? LocServ.inst.t('edit_raster_map')
              : LocServ.inst.t('add_raster_map'),
        ),
        actions: [
          KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
        ],
      ),
      // Scrollable because the form is taller than a landscape phone, and
      // than any phone once the keyboard is up.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              key: tourKeys['title_field'],
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '${LocServ.inst.t('title')}',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: tourKeys['image_picker'],
              onPressed: _busy ? null : _pickImage,
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
                  // Decoded at the preview's height: map pictures are scans
                  // far larger than this 200 dp strip.
                  child: Image.file(
                    File(_fullImagePath!),
                    height: 200,
                    cacheHeight: (200 * MediaQuery.devicePixelRatioOf(context))
                        .ceil(),
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
                DropdownMenuItem(
                  value: 'plane view',
                  child: Text(LocServ.inst.t('plane_view')),
                ),
                DropdownMenuItem(
                  value: 'projected profile',
                  child: Text(LocServ.inst.t('projected_profile')),
                ),
                DropdownMenuItem(
                  value: 'extended profile',
                  child: Text(LocServ.inst.t('extended_profile')),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text(LocServ.inst.t('other')),
                ),
              ],
              onChanged: (value) => setState(() => _selectedMapType = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: Text(LocServ.inst.t('save')),
            ),
          ],
        ),
      ),
    );
  }
}
