import 'package:flutter/material.dart';
import 'package:speleo_loc/data/source/database/app_database.dart';
import 'package:speleo_loc/screens/raster_map_place_selector.dart';
import 'package:speleo_loc/screens/scanner_page.dart';
import 'package:speleo_loc/screens/cave_place_page.dart';
import 'package:speleo_loc/screens/generated_qr_code_viewer.dart';
import 'package:speleo_loc/screens/map_viewer_page.dart';
import 'package:speleo_loc/utils/constants.dart';
import 'package:speleo_loc/services/service_locator.dart';
import 'package:speleo_loc/utils/localization.dart';
import 'package:speleo_loc/widgets/icon_action_button.dart';
import 'package:speleo_loc/screens/add_new_cave.dart';
import 'package:speleo_loc/screens/general_data/cave_areas_page.dart';
import 'package:speleo_loc/screens/general_data/surface_areas_page.dart';
import 'package:speleo_loc/screens/csv_cave_place_import_page.dart';
import 'package:speleo_loc/utils/deep_link_handler.dart';

class CavePage extends StatefulWidget {
  const CavePage({super.key, required this.caveId});

  final int caveId;

  @override
  State<CavePage> createState() => _CavePageState();
}

class _CavePageState extends State<CavePage> {
  // Using global appDatabase instance
  Cave? _cave;
  List<CavePlace> _cavePlaces = [];
  List<CavePlace> _filteredCavePlaces = [];
  final _qrCodeController = TextEditingController();
  final _filterController = TextEditingController();
  bool _showFilter = false;
  bool _showManualQrSection = false;
  Map<int, String> _areaTitles = {};
  Map<int, String> _surfaceAreaTitles = {};

  // Per-place definitions info and scroll handling
  Map<int, int> _definitionCountByPlace = {};
  int _rasterMapsCountForCave = 0;
  late ScrollController _scrollController;
  bool _showDownArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadCave();
    _loadSurfaceAreas();
    _loadCavePlaces();
  }

  Future<void> _loadSurfaceAreas() async {
    try {
      final areas = await (appDatabase.select(appDatabase.surfaceAreas)).get();
      _surfaceAreaTitles = {for (var a in areas) a.id: a.title};
    } catch (e) {
      _surfaceAreaTitles = {};
    }
  }

  Future<void> _printQRCodes() async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GeneratedQRCodeViewer(caveId: widget.caveId),
      ),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.position.maxScrollExtent > 0;
    if (show != _showDownArrow) setState(() => _showDownArrow = show);
  }

  @override
  void dispose() {
    _qrCodeController.dispose();
    _filterController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCave() async {
    _cave = await (appDatabase.select(
      appDatabase.caves,
    )..where((c) => c.id.equals(widget.caveId))).getSingleOrNull();
    // Save last open cave for deep link resolution
    DeepLinkHandler.saveLastOpenCave(widget.caveId);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadCavePlaces() async {
    print('[CavePage] _loadCavePlaces() for caveId ${widget.caveId}');

    _cavePlaces = await cavePlaceRepository.getCavePlaces(widget.caveId);
    await _loadCaveAreas();

    // Compute raster maps count and how many raster maps have definitions for each cave place
    final rasterMaps = await (appDatabase.select(
      appDatabase.rasterMaps,
    )..where((rm) => rm.caveId.equals(widget.caveId))).get();
    final rasterMapIds = rasterMaps.map((r) => r.id).toList();
    _rasterMapsCountForCave = rasterMapIds.length;

    Map<int, Set<int>> placeToRasters = {};
    if (rasterMapIds.isNotEmpty) {
      final defs = await (appDatabase.select(
        appDatabase.cavePlaceToRasterMapDefinitions,
      )..where((d) => d.rasterMapId.isIn(rasterMapIds))).get();
      for (final d in defs) {
        final cpId = d.cavePlaceId;
        final rmId = d.rasterMapId;
        placeToRasters
            .putIfAbsent(cpId, () => <int>{})
            .add(rmId);
      }
    }
    _definitionCountByPlace = {
      for (var cp in _cavePlaces) cp.id: (placeToRasters[cp.id]?.length ?? 0),
    };

    _applyFilter();
    if (!mounted) return;
    setState(() {});

    // Update arrow visibility after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        final canScroll = _scrollController.position.maxScrollExtent > 0;
        if (_showDownArrow != canScroll) {
          setState(() {
            _showDownArrow = canScroll;
          });
        }
      }
    });
  }

  Future<void> _loadCaveAreas() async {
    try {
      final areas = await (appDatabase.select(
        appDatabase.caveAreas,
      )..where((a) => a.caveId.equals(widget.caveId))).get();
      _areaTitles = {for (var a in areas) a.id: a.title};
    } catch (e) {
      _areaTitles = {};
    }
  }

  Future<void> _showDefinitionsReport(int cavePlaceId) async {
    // Load raster maps for cave and check if definition exists for each
    final rasterMaps = await (appDatabase.select(
      appDatabase.rasterMaps,
    )..where((rm) => rm.caveId.equals(widget.caveId))).get();
    final List<Map<String, dynamic>> rows = [];
    for (final rm in rasterMaps) {
      final def = await appDatabase.getDefinition(cavePlaceId, rm.id);
      rows.add({'rasterMap': rm, 'defined': def != null, 'definition': def});
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('definitions_report_title')),
        content: SizedBox(
          width: double.maxFinite,
          height: ((rows.length * 72).clamp(
            120,
            400,
          )).toDouble(),
          child: rows.isEmpty
              ? Center(child: Text(LocServ.inst.t('no_raster_maps_for_cave')))
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final rm = rows[index]['rasterMap'] as RasterMap;
                    final defined = rows[index]['defined'] as bool;
                    return InkWell(
                      onTap: () async {
                          Navigator.pop(context);
                          final existing = await appDatabase.getDefinition(
                            cavePlaceId,
                            rm.id,
                          );
                          final cavePlacesWithDefs = await appDatabase
                              .getCavePlacesWithDefinitionsForRasterMap(
                                widget.caveId,
                                rm.id,
                              );
                          if (!mounted) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RasterMapPlaceSelectorPage(
                                rasterMap: rm,
                                cavePlaceId: cavePlaceId,
                                cavePlacesWithDefinitions: cavePlacesWithDefs,
                                existingDefinition: existing,
                              ),
                            ),
                          );
                          _loadCavePlaces();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  defined
                                      ? Icons.check_circle
                                      : Icons.remove_circle_outline,
                                  color: defined ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.open_in_new, size: 18, color: Colors.grey[600]),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rm.title,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocServ.inst.t('close')),
          ),
        ],
      ),
    );
  }

  void _applyFilter() {
    final q = _filterController.text.trim();
    final qLower = q.toLowerCase();
    // final qNum = int.tryParse(q);
    if (q.isEmpty) {
      _filteredCavePlaces = List.from(_cavePlaces);
      return;
    }

    _filteredCavePlaces = _cavePlaces.where((cp) {
      final titleMatch = cp.title.toLowerCase().contains(qLower);
      final qrMatch =
          cp.placeQrCodeIdentifier?.toString().contains(qLower) ?? false;
      // final qrMatch = (qNum != null && cp.placeQrCodeIdentifier != null && cp.placeQrCodeIdentifier == qNum);
      final areaTitle = (cp.caveAreaId != null)
          ? (_areaTitles[cp.caveAreaId] ?? '')
          : '';
      final areaMatch = areaTitle.toLowerCase().contains(qLower);
      return titleMatch || qrMatch || areaMatch;
    }).toList();
  }

  Future<void> _deleteCavePlace(int id) async {
    await cavePlaceRepository.deleteCavePlace(id);
    _loadCavePlaces();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(LocServ.inst.t('cave_place_deleted'))));
    }
  }

  Future<void> _confirmDeleteCavePlace(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(LocServ.inst.t('delete_place_confirm')),
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
    if (confirmed == true) {
      await _deleteCavePlace(id);
    }
  }

  Future<void> _showRenameDialog() async {
    final controller = TextEditingController(text: _cave?.title ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('rename_cave')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: LocServ.inst.t('enter_new_name'),
          ),
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
    if (confirmed == true) {
      final newTitle = controller.text.trim();
      if (newTitle.isNotEmpty) {
        await caveRepository.updateCave(widget.caveId, newTitle);
        _loadCave();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _showRedefineAreaDialog() async {
    // show dropdown of surface areas (allow None)
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        int? temp = _cave?.surfaceAreaId;
        return AlertDialog(
          title: Text(LocServ.inst.t('area_title')),
          content: StatefulBuilder(
            builder: (context, setInner) => Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: temp,
                    decoration: InputDecoration(labelText: LocServ.inst.t('area_title')),
                    items: [
                      DropdownMenuItem(value: null, child: Text(LocServ.inst.t('none'))),
                      ..._surfaceAreaTitles.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                    ],
                    onChanged: (v) => setInner(() => temp = v),
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
                    if (result == true) {
                      await _loadSurfaceAreas();
                      setInner(() {});
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, {'confirmed': false}), child: Text(LocServ.inst.t('cancel'))),
            TextButton(onPressed: () => Navigator.pop(context, {'confirmed': true, 'value': temp}), child: Text(LocServ.inst.t('save'))),
          ],
        );
      },
    );

    if (result != null && result['confirmed'] == true) {
      final int? selected = result['value'] as int?;
      if (selected != _cave?.surfaceAreaId) {
        await caveRepository.updateCave(widget.caveId, _cave!.title, surfaceAreaId: selected);
        await _loadCave();
        await _loadSurfaceAreas();
        if (mounted) setState(() {});
      }
    }
  }

  void _onScan(String code) async {
    final qrCode = int.tryParse(code);
    if (qrCode != null) {
      final cavePlace = await cavePlaceRepository.findCavePlaceByQrCode(qrCode, widget.caveId);
      if (cavePlace != null) {
        _onCavePlaceFound(cavePlace);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${LocServ.inst.t('cave_place_not_found')}: \'$code\'')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocServ.inst.t('invalid_qr_code_detail')}: \'$code\'',
            ),
          ),
        );
      }
    }
  }

  void _onCavePlaceFound(CavePlace cavePlace) async {
    // Navigate to MapViewerPage for the found cave place and show snackbar
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapViewerPage(cavePlaceId: cavePlace.id),
      ),
    );
    if (!mounted) return;
    _loadCavePlaces();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${LocServ.inst.t('cave_place_identified')}: "${cavePlace.title}"'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_cave?.title ?? LocServ.inst.t('loading')),
            if (_cave?.surfaceAreaId != null && _surfaceAreaTitles[_cave!.surfaceAreaId] != null)
              Text(
                _surfaceAreaTitles[_cave!.surfaceAreaId]!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.layers),
          //   tooltip: LocServ.inst.t('manage_cave_areas'),
          //   onPressed: () async {
          //     await Navigator.push(context, MaterialPageRoute(builder: (_) => CaveAreasPage(caveId: widget.caveId)));
          //     _loadCavePlaces();
          //   },
          // ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit_cave') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddNewCave(cave: _cave),
                  ),
                );
                if (result != null) {
                  await _loadCave();
                  await _loadSurfaceAreas();
                  if (mounted) setState(() {});
                }
              } else if (v == 'rename') {
                await _showRenameDialog();
              } else if (v == 'redefine_area') {
                await _showRedefineAreaDialog();
              } else if (v == 'csv_import') {
                final result = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CSVCavePlaceImportPage(caveId: widget.caveId),
                  ),
                );
                if (result == true) {
                  _loadCavePlaces();
                }
              } else if (v == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(LocServ.inst.t('confirm')),
                    content: Text(LocServ.inst.t('delete_cave_confirm')),
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
                if (confirmed == true) {
                  await caveRepository.deleteCave(widget.caveId);
                  if (!mounted) return;
                  Navigator.pop(context, true);
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit_cave',
                child: Row(
                  children: [
                    Icon(Icons.edit_note, size: 20),
                    const SizedBox(width: 8),
                    Text(LocServ.inst.t('edit_cave')),
                  ],
                ),
              ),
              // PopupMenuItem(
              //   value: 'rename',
              //   child: Row(
              //     children: [
              //       Icon(Icons.edit, size: 20),
              //       const SizedBox(width: 8),
              //       Text(LocServ.inst.t('rename_cave')),
              //     ],
              //   ),
              // ),
              // PopupMenuItem(
              //   value: 'redefine_area',
              //   child: Row(
              //     children: [
              //       Icon(Icons.location_on, size: 20),
              //       const SizedBox(width: 8),
              //       Text(LocServ.inst.t('area_title')),
              //     ],
              //   ),
              // ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20),
                    const SizedBox(width: 8),
                    Text(LocServ.inst.t('delete_cave')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv_import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, size: 20),
                    const SizedBox(width: 8),
                    Text(LocServ.inst.t('csv_import_places')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // toolbarsection (icon-only)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconActionButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScannerPage(onScan: _onScan),
                          ),
                        ),
                        icon: Icons.qr_code_scanner,
                        tooltip: LocServ.inst.t('scan_qr'),
                      ),
                      const SizedBox(width: 8),
                      IconActionButton(
                        onPressed: () async {
                          // print('');
                          // print('[CavePage] Navigating to CavePlacePage to add new place for caveId ${widget.caveId}');

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CavePlacePage(
                                // //todo: remove if Unhandled Exception: Bad state: Too many elements solved
                                // key: ValueKey('cave_place_page_${widget.caveId}'), // Force rebuild when caveId changes
                                caveId: widget.caveId,
                              ),
                            ),
                          );
                          if (result == true) _loadCavePlaces();
                        },
                        icon: Icons.add,
                        tooltip: LocServ.inst.t('add_cave_place'),
                      ),
                      const SizedBox(width: 8),
                      IconActionButton(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            rasterMapsRoute,
                            arguments: widget.caveId,
                          );
                          if (result == true) _loadCavePlaces();
                        },
                        icon: Icons.map,
                        tooltip: LocServ.inst.t('view_raster_maps'),
                      ),
                      const SizedBox(width: 8),
                      IconActionButton(
                        onPressed: _printQRCodes,
                        icon: Icons.print,
                        tooltip: LocServ.inst.t('print_qr_codes'),
                      ),
                      const SizedBox(width: 8),
                      IconActionButton(
                        onPressed: () {
                          setState(() {
                            _showManualQrSection = !_showManualQrSection;
                          });
                        },
                        icon: Icons.qr_code_rounded,
                        tooltip: LocServ.inst.t('manual_qr_search'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.layers),
                        tooltip: LocServ.inst.t('manage_cave_areas'),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CaveAreasPage(caveId: widget.caveId),
                            ),
                          );
                          if (result == true) _loadCavePlaces();
                        },
                      )
                      // ,
                      // IconButton(
                      //   icon: const Icon(Icons.landscape),
                      //   tooltip: LocServ.inst.t('manage_surface_areas'),
                      //   onPressed: () async {
                      //     final result = await Navigator.push<bool?>(
                      //       context,
                      //       MaterialPageRoute(builder: (_) => const SurfaceAreasPage()),
                      //     );
                      //     if (result == true) {
                      //       await _loadSurfaceAreas();
                      //       _loadCavePlaces();
                      //     }
                      //   },
                      // ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (_showManualQrSection)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _qrCodeController,
                                decoration: InputDecoration(
                                  labelText: LocServ.inst.t(
                                    'qr_code_identifier',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                final code = _qrCodeController.text.trim();
                                if (code.isNotEmpty) {
                                  _onScan(code);
                                }
                              },
                              child: Text(
                                LocServ.inst.t(
                                  'search_place_by_qr_code_by_identifier',
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${LocServ.inst.t('cave_place')}:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_list, size: 20),
                        tooltip: LocServ.inst.t('show_filter'),
                        onPressed: () {
                          setState(() {
                            _showFilter = !_showFilter;
                            if (!_showFilter) {
                              _filterController.clear();
                              _applyFilter();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_showFilter)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        controller: _filterController,
                        decoration: InputDecoration(
                          labelText:
                              LocServ.inst.t('filter_cave_places'),
                        ),
                        onChanged: (v) {
                          setState(() {
                            //todo: retest and fix filtering by QR code number if it was broken by the recent filter refactor (now supports partial matches, but maybe some parsing issue broke it);
                            //todo: consider potential performance issues with large number of cave places (throttle/debounce, optimize _applyFilter, etc)
                            _applyFilter();
                          });
                        },
                      ),
                    ),
                  ..._filteredCavePlaces.map(
                    (cp) => Column(
                      children: [
                        InkWell(
                          onTap: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              cavePlaceRoute,
                              arguments: {
                                'caveId': widget.caveId,
                                'cavePlaceId': cp.id,
                              },
                            );
                            if (result == true) _loadCavePlaces();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                // Title takes all available space
                                Expanded(
                                  child: Text(
                                    cp.title,
                                    style: const TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Icons aligned to the right
                                // QR presence indicator
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0, right: 2.0),
                                  child: Icon(
                                    cp.placeQrCodeIdentifier != null
                                        ? Icons.qr_code
                                        : Icons.qr_code_outlined,
                                    color: cp.placeQrCodeIdentifier != null
                                        ? Colors.green.withValues(alpha: 0.8)
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                                // Definitions count (clickable)
                                Builder(
                                  builder: (context) {
                                    final count = _definitionCountByPlace[cp.id] ?? 0;
                                    final Color col = (count == 0)
                                        ? Colors.red.withValues(alpha: 0.8)
                                        : (count == _rasterMapsCountForCave && _rasterMapsCountForCave > 0)
                                            ? Colors.green.withValues(alpha: 0.8)
                                            : Colors.grey;
                                    return InkWell(
                                      onTap: () => _showDefinitionsReport(cp.id),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.place, color: col, size: 18),
                                            const SizedBox(width: 2),
                                            Text('$count', style: TextStyle(color: col)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Delete button
                                IconActionButton(
                                  onPressed: () => _confirmDeleteCavePlace(cp.id),
                                  icon: Icons.delete,
                                  tooltip: LocServ.inst.t('delete_cave_place'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey[300]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // overlay down-arrow (bottom-center) — visible while content is scrollable
          if (_showDownArrow)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: IgnorePointer(
                ignoring: true,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _showDownArrow ? 1.0 : 0.0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
