import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:path_provider/path_provider.dart';
import 'package:speleo_loc/data/source/database/app_database.dart';
import 'package:speleo_loc/screens/scanner_page.dart';
import 'package:speleo_loc/screens/raster_map_place_selector.dart';
import 'package:speleo_loc/widgets/raster_map_place_point_editor.dart';
import 'package:speleo_loc/screens/general_data/cave_areas_page.dart';
import 'package:speleo_loc/screens/geofeature_documents_page.dart';
import 'package:speleo_loc/services/documents_controller.dart';
import 'package:speleo_loc/utils/localization.dart';
import 'package:speleo_loc/widgets/cave_place_qr_preview_dialog.dart';

class CavePlacePage extends StatefulWidget {
  const CavePlacePage({super.key, required this.caveId, this.cavePlaceId});

  final int caveId;
  final int? cavePlaceId;

  @override
  State<CavePlacePage> createState() => _CavePlacePageState();
}

class _CavePlacePageState extends State<CavePlacePage>
    with TickerProviderStateMixin {
  // Using global appDatabase instance
  CavePlace? _cavePlace;
  int? _currentCavePlaceId;
  Cave? _cave;
  List<RasterMap> _rasterMaps = [];
  List<CaveArea> _caveAreas = [];
  final Map<String, Future<String>> _imagePathFutures = {};
  final Map<int, Future<List<CavePlaceWithDefinition>>>
      _rasterDefinitionFutures = {};

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _qrController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();

  bool _qrEditable = false;

  TabController? _tabController;
  bool _showLatLngFields = false;
  int _currentTabIndex = 0;
  int? _selectedCaveAreaId;
  // bool _qrEnabled = false;

  bool _hasUnsavedChanges = false;
  bool _titleModified = false;
  bool _descriptionModified = false;
  bool _qrModified = false;
  bool _latModified = false;
  bool _longModified = false;

  // Feature toggle: show interactive RasterMapPlacePointEditor in the
  // "Raster maps" tab of CavePlacePage. Disabled by default so the
  // page shows a plain `Image` as before the refactor.
  static const bool USE_RASTER_EDITOR_IN_CAVEPLACE = false;

  @override
  void initState() {
    super.initState();
    _currentCavePlaceId = widget.cavePlaceId;
    print('');
    print('[CavePlacePage] caveId ${widget.caveId}');
    _loadData();

    _titleController.addListener(() => _onFieldEdited('title'));
    _descriptionController.addListener(() => _onFieldEdited('description'));
    _qrController.addListener(() => _onFieldEdited('qr'));
    _latController.addListener(() => _onFieldEdited('lat'));
    _longController.addListener(() => _onFieldEdited('long'));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _qrController.dispose();
    _latController.dispose();
    _longController.dispose();

    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  void _loadData() async {
    _cave = await (appDatabase.select(
      appDatabase.caves,
    )..where((c) => c.id.equals(widget.caveId))).getSingleOrNull();
    if (_currentCavePlaceId != null) {
      _cavePlace = await (appDatabase.select(
        appDatabase.cavePlaces,
      )..where((cp) => cp.id.equals(_currentCavePlaceId!))).getSingleOrNull();
      if (_cavePlace == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      _titleController.text = _cavePlace!.title;
      _descriptionController.text = _cavePlace!.description ?? '';
      _qrController.text = _cavePlace!.placeQrCodeIdentifier?.toString() ?? '';
      _latController.text = _cavePlace!.latitude?.toString() ?? '';
      _longController.text = _cavePlace!.longitude?.toString() ?? '';
      _selectedCaveAreaId = _cavePlace!.caveAreaId;
    }
    _rasterMaps = await (appDatabase.select(
      appDatabase.rasterMaps,
    )..where((rm) => rm.caveId.equals(widget.caveId))).get();

    // Load cave areas for the cave (used in the dropdown)
    _caveAreas = await (appDatabase.select(
      appDatabase.caveAreas,
    )..where((ca) => ca.caveId.equals(widget.caveId))).get();

    if (!mounted) return;
    setState(() {
      _tabController = TabController(length: _rasterMaps.length, vsync: this);
      _tabController!.addListener(_onTabChanged);
    });
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {
        _currentTabIndex = _tabController!.index;
      });
    }
  }

  Future<int?> _save({bool closeAfterSave = true}) async {
    final title = _titleController.text;
    final description = _descriptionController.text.isEmpty
        ? null
        : _descriptionController.text;
    final qr = int.tryParse(_qrController.text);
    final lat = double.tryParse(_latController.text);
    final long = double.tryParse(_longController.text);

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(LocServ.inst.t('title_required'))));
      return null;
    }

    // Check for duplicate QR code within the same cave
    if (qr != null) {
      final duplicates = await (appDatabase.select(appDatabase.cavePlaces)
            ..where((cp) =>
                cp.caveId.equals(widget.caveId) &
                cp.placeQrCodeIdentifier.equals(qr) &
                (_currentCavePlaceId != null
                    ? cp.id.equals(_currentCavePlaceId!).not()
                    : const Constant(true))))
          .get();
      if (duplicates.isNotEmpty && mounted) {
        final otherTitle = duplicates.first.title;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(LocServ.inst.t('duplicate_qr_warning')),
            content: Text(
              LocServ.inst
                  .t('duplicate_qr_message')
                  .replaceAll('{title}', otherTitle)
                  .replaceAll('{qr}', qr.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(LocServ.inst.t('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(LocServ.inst.t('yes')),
              ),
            ],
          ),
        );
        if (confirmed != true) return null;
      }
    }

    if (_currentCavePlaceId == null) {
      final newId = await appDatabase
          .into(appDatabase.cavePlaces)
          .insert(
            CavePlacesCompanion.insert(
              title: title,
              caveId: widget.caveId,
              description: description == null
                  ? const Value.absent()
                  : Value(description),
              placeQrCodeIdentifier: Value(qr),
              latitude: Value(lat),
              longitude: Value(long),
              caveAreaId: Value(_selectedCaveAreaId),
            ),
          );

      if (!mounted) return newId;
      if (closeAfterSave) {
        Navigator.pop(context, true);
      } else {
        await _refreshCavePlaceState(newId);
      }
      return newId;
    } else {
      await (appDatabase.update(
        appDatabase.cavePlaces,
      )..where((cp) => cp.id.equals(_currentCavePlaceId!))).write(
        CavePlacesCompanion(
          title: Value(title),
          description: description == null
              ? const Value.absent()
              : Value(description),
          placeQrCodeIdentifier: Value(qr),
          latitude: Value(lat),
          longitude: Value(long),
          caveAreaId: Value(_selectedCaveAreaId),
        ),
      );

      if (!mounted) return _currentCavePlaceId;
      if (closeAfterSave) {
        Navigator.pop(context, true);
      } else {
        await _refreshCavePlaceState(_currentCavePlaceId!);
      }
      return _currentCavePlaceId;
    }
  }

  Future<void> _refreshCavePlaceState(int cavePlaceId) async {
    final refreshed = await (appDatabase.select(
      appDatabase.cavePlaces,
    )..where((cp) => cp.id.equals(cavePlaceId))).getSingleOrNull();

    if (!mounted || refreshed == null) return;
    setState(() {
      _currentCavePlaceId = cavePlaceId;
      _cavePlace = refreshed;
      _selectedCaveAreaId = refreshed.caveAreaId;
      _hasUnsavedChanges = false;
      _titleModified = false;
      _descriptionModified = false;
      _qrModified = false;
      _latModified = false;
      _longModified = false;
    });
  }

  void _onFieldEdited(String field) {
    // Compare with original loaded values
    if (field == 'title') {
      final orig = _cavePlace?.title ?? '';
      _titleModified = _titleController.text != orig;
    } else if (field == 'description') {
      final orig = _cavePlace?.description ?? '';
      _descriptionModified = _descriptionController.text != orig;
    } else if (field == 'qr') {
      final orig = _cavePlace?.placeQrCodeIdentifier?.toString() ?? '';
      _qrModified = _qrController.text != orig;
    } else if (field == 'lat') {
      final orig = _cavePlace?.latitude?.toString() ?? '';
      _latModified = _latController.text != orig;
    } else if (field == 'long') {
      final orig = _cavePlace?.longitude?.toString() ?? '';
      _longModified = _longController.text != orig;
    }

    setState(() {
      _hasUnsavedChanges =
          _titleModified ||
          _descriptionModified ||
          _qrModified ||
          _latModified ||
          _longModified;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(LocServ.inst.t('discard_changes')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocServ.inst.t('cancel_no_dont_discard')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocServ.inst.t('yes_discard_changes')),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  void _openQrCodeScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScannerPage(onScan: _onQrScanned)),
    );
  }

  void _onQrScanned(String code) async {
    final qr = int.tryParse(code);
    if (qr != null) {
      final currentQrValue = int.tryParse(_qrController.text);

      // Check if same code is already in the field
      if (currentQrValue == qr) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocServ.inst.t('qr_code_already_present'))),
        );
        return;
      }

      // mark qr as potentially modified (user may change after scan)
      setState(() {
        _qrModified = true;
        _hasUnsavedChanges = true;
      });

      // Check if this QR code already exists for another cave place
      final query = appDatabase.select(appDatabase.cavePlaces)
        ..where((cp) => cp.placeQrCodeIdentifier.equals(qr));
      if (_currentCavePlaceId != null) {
        query.where((cp) => cp.id.isNotValue(_currentCavePlaceId!));
      }
      final existing = await query.getSingleOrNull();

      if (existing != null) {
        // QR code belongs to another cave place
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'QR code ${LocServ.inst.t('already_used_for')}: "${existing.title}"',
            ),
          ),
        );
        return;
      }

      // If there's already a value and it's different, ask for confirmation
      if (currentQrValue != null && currentQrValue != qr) {
        if (!mounted) return;
        final shouldReplace = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(LocServ.inst.t('replace_qr_code')),
            content: Text(LocServ.inst.t('existing_qr_code_will_be_replaced')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(LocServ.inst.t('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(LocServ.inst.t('yes')),
              ),
            ],
          ),
        );
        if (shouldReplace == true) {
          if (!mounted) return;
          setState(() {
            _qrEditable = true;
            _qrController.text = qr.toString();
          });
        }
      } else {
        // No existing value, just set it
        if (!mounted) return;
        setState(() {
          _qrEditable = true;
          _qrController.text = qr.toString();
        });
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocServ.inst.t('invalid_qr_code'))),
      );
    }
  }

  Widget _buildImage(RasterMap rm) {
    return FutureBuilder<String>(
      future: _imagePathFutures[rm.fileName] ??= _getImagePath(rm.fileName),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(LocServ.inst.t('error')));
        }
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            // Show readonly editor (no legend, no zoom controls) so users can still
            // view raster with existing cave-place markers.
            return FutureBuilder<List<CavePlaceWithDefinition>>(
              future: _rasterDefinitionFutures[rm.id] ??=
                  appDatabase.getCavePlacesWithDefinitionsForRasterMap(
                widget.caveId,
                rm.id,
              ),
              builder: (context, defsSnap) {
                if (!defsSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final defs = defsSnap.data!;
                if (USE_RASTER_EDITOR_IN_CAVEPLACE) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      height: 300, // keep aspect similar to previous Image display area
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

                // Default (legacy) rendering: plain Image widget without the
                // interactive editor. This is the default behaviour and keeps
                // the previous visual appearance.
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
          } else {
            return Text(LocServ.inst.t('image_not_found'));
          }
        }
        return const CircularProgressIndicator();
      },
    );
  }

  // tab page builder 
  Widget _buildMapTab(RasterMap rm) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => _definePlace(rm),
                child: _buildImage(rm),
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
                      onPressed: () => _definePlace(rm),
                      icon: const Icon(Icons.edit_location_alt, color: Colors.white),
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

  void _definePlace(RasterMap rm) async {
    print('_definePlace rasterMapId ${rm.id}');
    var cavePlaceId = _currentCavePlaceId;
    if (cavePlaceId == null) {
      cavePlaceId = await _save(closeAfterSave: false);
      if (cavePlaceId == null) {
        return;
      }
    }

    print(
      'Opening place selector for cavePlaceId $cavePlaceId and rasterMapId ${rm.id}',
    );
    final existing = await appDatabase.getDefinition(
      cavePlaceId,
      rm.id,
    );
    final cavePlacesWithDefs = await appDatabase
        .getCavePlacesWithDefinitionsForRasterMap(widget.caveId, rm.id);
    print(
      'after db retrievals cavePlaceId=${existing?.cavePlaceId ?? 'xnull'}',
    );

    if (!mounted) return;
    final navContext = context;
    await Navigator.push(
      navContext,
      MaterialPageRoute(
        builder: (_) => RasterMapPlaceSelectorPage(
          key: ValueKey(
            'place_selector_widget_${cavePlaceId}_${rm.id}_${Random().nextInt(100000000)}',
          ), // Force rebuild when cavePlaceId or rasterMap changes
          rasterMap: rm,
          cavePlaceId: cavePlaceId!,
          cavePlacesWithDefinitions: cavePlacesWithDefs,
          existingDefinition: existing,
        ),
      ),
    );

    _invalidateRasterDefinitionCache(rm.id);
  }

  void _invalidateRasterDefinitionCache(int rasterMapId) {
    if (!mounted) return;
    setState(() {
      _rasterDefinitionFutures.remove(rasterMapId);
    });
  }

  Future<String> _getImagePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _onWillPop()) {
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentCavePlaceId == null
                    ? LocServ.inst.t('add_new_cave_place')
                    : (_cavePlace?.title ?? LocServ.inst.t('edit_cave_place')),
                style: const TextStyle(fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_cave != null)
                Text(
                  _cave!.title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          actions: [
            // QR code preview – only for existing places with a QR identifier.
            if (_currentCavePlaceId != null &&
                _cavePlace?.placeQrCodeIdentifier != null)
              IconButton(
                icon: const Icon(Icons.qr_code),
                tooltip: LocServ.inst.t('view_qr_code'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  CavePlaceQrPreviewDialog.show(context, _cavePlace!);
                },
              ),
            // Documents button – only for existing (saved) cave places.
            if (_currentCavePlaceId != null)
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: LocServ.inst.t('open_documents'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GeofeatureDocumentsPage(
                        source: DocumentsSource.cavePlace(
                          cavePlaceId: _currentCavePlaceId!,
                          cavePlaceTitle: _cavePlace?.title ?? '',
                          caveTitle: _cave?.title,
                        ),
                      ),
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: LocServ.inst.t('save'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => _save(),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onSelected: (value) {
                if (value == 'toggle_gps') {
                  setState(() {
                    _showLatLngFields = !_showLatLngFields;
                  });
                }
              },
              itemBuilder: (context) => [
                CheckedPopupMenuItem<String>(
                  value: 'toggle_gps',
                  checked: _showLatLngFields,
                  child: Text(LocServ.inst.t('show_hide_gps')),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: LocServ.inst.t('title'),
                    filled: _titleModified,
                    fillColor: _titleModified
                        ? Colors.green.withValues(alpha: 0.06)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                // Description (multiline)
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: LocServ.inst.t('description'),
                    filled: _descriptionModified,
                    fillColor: _descriptionModified
                        ? Colors.green.withValues(alpha: 0.06)
                        : null,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                // Cave area dropdown + manage button
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: _selectedCaveAreaId,
                        decoration: InputDecoration(
                          labelText: LocServ.inst.t('area_title'),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(LocServ.inst.t('none')),
                          ),
                          ..._caveAreas.map(
                            (a) => DropdownMenuItem<int?>(
                              value: a.id,
                              child: Text(a.title),
                            ),
                          ),
                        ],
                        onChanged: (v) async {
                          final old = _selectedCaveAreaId;
                          if (v == null && old != null) {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(LocServ.inst.t('confirm')),
                                content: Text(
                                  LocServ.inst.t('clear_area_confirm'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(LocServ.inst.t('cancel')),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(LocServ.inst.t('yes')),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              setState(() => _selectedCaveAreaId = null);
                            } else {
                              setState(() => _selectedCaveAreaId = old);
                            }
                          } else {
                            setState(() => _selectedCaveAreaId = v);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.layers),
                      tooltip: LocServ.inst.t('manage_cave_areas'),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CaveAreasPage(caveId: widget.caveId),
                          ),
                        );
                        // reload areas after return
                        final areas =
                            await (appDatabase.select(appDatabase.caveAreas)
                                  ..where(
                                    (ca) => ca.caveId.equals(widget.caveId),
                                  ))
                                .get();
                        setState(() {
                          _caveAreas = areas;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // QR code identifier with edit toggle
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_qrEditable ? Icons.check : Icons.edit),
                      tooltip: _qrEditable
                          ? LocServ.inst.t('disable_qr_edit')
                          : LocServ.inst.t('enable_qr_edit'),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      onPressed: () {
                        setState(() {
                          _qrEditable = !_qrEditable;
                        });
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _qrController,
                        decoration: InputDecoration(
                          labelText: LocServ.inst.t('qr_code_identifier'),
                          filled: _qrModified,
                          fillColor: _qrModified
                              ? Colors.green.withValues(alpha: 0.06)
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        enabled: _qrEditable,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: _openQrCodeScanner,
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: Text(LocServ.inst.t('scan')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_showLatLngFields)
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              decoration: InputDecoration(
                                labelText: LocServ.inst.t('latitude'),
                                filled: _latModified,
                                fillColor: _latModified
                                    ? Colors.green.withValues(alpha: 0.06)
                                    : null,
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _longController,
                              decoration: InputDecoration(
                                labelText: LocServ.inst.t('longitude'),
                                filled: _longModified,
                                fillColor: _longModified
                                    ? Colors.green.withValues(alpha: 0.06)
                                    : null,
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                Row(
                  children: [
                    const SizedBox(height: 8),

                    /// Show/Hide GPS coordinates
                    // IconButton(
                    //   icon: const Icon(Icons.location_on),
                    //   tooltip: 'Show/Hide GPS coordinates',
                    //   onPressed: () {
                    //     setState(() {
                    //       _showLatLngFields = !_showLatLngFields;
                    //     });
                    //   },
                    // ),
                  ],
                ),

                /// Raster maps section
                if (_rasterMaps.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '${LocServ.inst.t('raster_maps')}:',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        /// Raster maps tab bar controller section, with left/right header buttons
                        DefaultTabController(
                          length: _rasterMaps.length,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _currentTabIndex > 0
                                        ? () => _tabController?.animateTo(
                                            _currentTabIndex - 1,
                                          )
                                        : null,
                                    icon: const Icon(Icons.arrow_left),
                                  ),
                                  Expanded(
                                    child: TabBar(
                                      controller: _tabController,
                                      isScrollable: true,
                                      tabs: _rasterMaps
                                          .map(
                                            (rm) => Tab(
                                              text:
                                                  rm.title.isEmpty
                                                      ? rm.fileName.replaceAll(
                                                          RegExp(
                                                            r'\.(jpg|jpeg|png|bmp)$',
                                                          ),
                                                          "",
                                                        )
                                                      : rm.title
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        _currentTabIndex <
                                            (_tabController?.length ?? 0) - 1
                                        ? () => _tabController?.animateTo(
                                            _currentTabIndex + 1,
                                          )
                                        : null,
                                    icon: const Icon(Icons.arrow_right),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height:
                                    350, // Increased height to accommodate larger images
                                child: TabBarView(
                                  controller: _tabController,
                                  children: _rasterMaps
                                      .map((rm) => _buildMapTab(rm))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                /*
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   const SizedBox(height: 80),
                    ElevatedButton(
                      onPressed: _save,
                      child: Text(LocServ.inst.t('save')),
                    ),
                ],
              ),
              */
              ],
            ),
          ),
        ),
      ),
    );
  }
}
