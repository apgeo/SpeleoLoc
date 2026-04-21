import 'package:flutter/material.dart';
import 'dart:async';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_places/cave_place_filter.dart';
import 'package:speleoloc/screens/cave_places/past_trips_button.dart';
import 'package:speleoloc/screens/raster_map_place_selector.dart';
import 'package:speleoloc/screens/scanner_page.dart';
import 'package:speleoloc/screens/cave_place_page.dart';
import 'package:speleoloc/screens/generated_qr_code_viewer.dart';
import 'package:speleoloc/screens/map_viewer_page.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/icon_action_button.dart';
import 'package:speleoloc/screens/add_new_cave.dart';
import 'package:speleoloc/screens/general_data/cave_areas_page.dart';
import 'package:speleoloc/screens/csv_cave_place_import_page.dart';
import 'package:speleoloc/utils/deep_link_handler.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/utils/app_logger.dart';

class CavePlacesListPage extends StatefulWidget {
  const CavePlacesListPage({super.key, required this.caveId});

  final int caveId;

  @override
  State<CavePlacesListPage> createState() => _CavePlacesListPageState();
}

class _CavePlacesListPageState extends State<CavePlacesListPage> with AppBarMenuMixin<CavePlacesListPage>, ProductTourMixin<CavePlacesListPage> {
  static const bool _pinTopControls = true;
  @override
  String get tourId => 'cave_places_list';
  @override
  final tourKeys = TourKeySet(['add', 'list', 'menu']);
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'add', titleLocKey: 'tour_cave_places_list_add_title', bodyLocKey: 'tour_cave_places_list_add_body'),
    TourStepDef(keyId: 'list', titleLocKey: 'tour_cave_places_list_list_title', bodyLocKey: 'tour_cave_places_list_list_body', align: ContentAlign.top),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_cave_places_list_menu_title', bodyLocKey: 'tour_cave_places_list_menu_body'),
  ];
  @override
  List<AppMenuItem> get screenMenuItems {
    final activeTripId = caveTripService.activeTripIdNotifier.value;
    return [
      if (activeTripId == null)
        AppMenuItem(
          value: 'start_trip',
          icon: Icons.play_arrow,
          label: LocServ.inst.t('trip_start'),
          color: Colors.green
          // color: Colors.green.shade900
        )
      else ...[
        AppMenuItem(
          value: 'view_trip',
          icon: Icons.route,
          label: LocServ.inst.t('trip_view'),
        ),
        AppMenuItem(
          value: 'stop_trip',
          icon: Icons.stop,
          label: LocServ.inst.t('trip_stop'),
        ),
      ],
      AppMenuItem(
        value: 'edit_cave',
        icon: Icons.edit_note,
        label: LocServ.inst.t('edit_cave'),
      ),
      AppMenuItem(
        value: 'delete',
        icon: Icons.delete,
        label: LocServ.inst.t('delete_cave'),
      ),
      AppMenuItem(
        value: 'csv_import',
        icon: Icons.upload_file,
        label: LocServ.inst.t('csv_import_places'),
      ),
    ];
  }

  @override
  void onScreenMenuItemSelected(String value) async {
    if (value == 'edit_cave') {
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
    } else if (value == 'csv_import') {
      final result = await Navigator.push<bool?>(
        context,
        MaterialPageRoute(
          builder: (_) => CSVCavePlacesImportPage(caveId: widget.caveId),
        ),
      );
      if (result == true) {
        _loadCavePlaces();
      }
    } else if (value == 'delete') {
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
    } else if (value == 'start_trip') {
      await _startTrip();
    } else if (value == 'stop_trip') {
      await _stopTrip();
    } else if (value == 'view_trip') {
      _viewActiveTrip();
    }
  }
  // Using global appDatabase instance
  Cave? _cave;
  List<CavePlace> _cavePlaces = [];
  List<CavePlace> _filteredCavePlaces = [];
  final _qrCodeController = TextEditingController();
  final _filterController = TextEditingController();
  bool _showFilter = false;
  bool _showManualQrSection = false;
  bool _checkboxMode = false;
  Set<int> _selectedPlaceIds = {};
  Map<int, String> _areaTitles = {};
  Map<int, String> _surfaceAreaTitles = {};
  int _pastTripsCount = 0;

  // Per-place definitions info and scroll handling
  Map<int, int> _definitionCountByPlace = {};
  int _rasterMapsCountForCave = 0;
  late ScrollController _scrollController;
  bool _showDownArrow = false;
  StreamSubscription<List<CavePlace>>? _cavePlacesSub;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    caveTripService.activeTripIdNotifier.addListener(_onTripStateChanged);
    _loadCave();
    _loadSurfaceAreas();
    _loadCavePlaces();
    _loadTripCount();
    // Live-refresh when cave_places table changes from any source (this
    // screen's mutations, other screens, imports, DB merges).
    _cavePlacesSub = cavePlaceRepository
        .watchCavePlaces(widget.caveId)
        .skip(1) // initial load is handled by explicit _loadCavePlaces above
        .listen((_) {
      if (!mounted) return;
      _loadCavePlaces();
    });
  }

  Future<void> _loadSurfaceAreas() async {
    try {
      final areas = await (appDatabase.select(appDatabase.surfaceAreas)).get();
      _surfaceAreaTitles = {for (var a in areas) a.id: a.title};
    } catch (e) {
      _surfaceAreaTitles = {};
    }
  }

  void _onTripStateChanged() {
    if (mounted) {
      setState(() {});
      _loadTripCount();
    }
  }

  Future<void> _loadTripCount() async {
    final trips = await appDatabase.getCaveTrips(widget.caveId);
    final ended = trips.where((t) => t.tripEndedAt != null).length;
    if (mounted) setState(() => _pastTripsCount = ended);
  }

  Future<void> _startTrip() async {
    final defaultTitle = '${_cave?.title ?? ''} ${dateFormat.format(DateTime.now())}';
    final existingTitles = await appDatabase.getCaveTripTitles(widget.caveId);
    final suggestedTitle = CaveTripService.uniqueTripTitle(defaultTitle, existingTitles);
    final controller = TextEditingController(text: suggestedTitle);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('trip_name_dialog_title')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: LocServ.inst.t('trip_title_hint')),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('ok')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await caveTripService.startTrip(widget.caveId, controller.text.trim().isNotEmpty ? controller.text.trim() : suggestedTitle);
      setState(() {});
    }
  }

  Future<void> _stopTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(LocServ.inst.t('trip_stop_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(LocServ.inst.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(LocServ.inst.t('yes'))),
        ],
      ),
    );
    if (confirmed == true) {
      await caveTripService.stopTrip();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocServ.inst.t('trip_stopped'))));
        setState(() {});
      }
    }
  }

  void _viewActiveTrip() {
    final id = caveTripService.activeTripIdNotifier.value;
    if (id == null) return;
    Navigator.pushNamed(context, caveTripRoute, arguments: id);
  }

  Future<void> _deleteSelectedPlaces() async {
    final count = _selectedPlaceIds.length;
    if (count == 0) return;
    final confirmMsg = LocServ.inst.t('delete_selected_confirm').replaceAll('{count}', '$count');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(confirmMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(LocServ.inst.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(LocServ.inst.t('yes'))),
        ],
      ),
    );
    if (confirmed == true) {
      for (final id in _selectedPlaceIds) {
        await cavePlaceRepository.deleteCavePlace(id);
      }
      setState(() {
        _selectedPlaceIds.clear();
        _checkboxMode = false;
      });
      await _loadCavePlaces();
    }
  }

  Future<void> _printQRCodes() async {
    if (!mounted) return;
    if (_checkboxMode && _selectedPlaceIds.isNotEmpty) {
      final selected = _filteredCavePlaces.where((cp) => _selectedPlaceIds.contains(cp.id)).toList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GeneratedQRCodeViewer(cavePlaces: selected),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GeneratedQRCodeViewer(caveId: widget.caveId),
        ),
      );
    }
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
    _cavePlacesSub?.cancel();
    caveTripService.activeTripIdNotifier.removeListener(_onTripStateChanged);
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
    AppLogger.of('CavePlacesListPage').fine('_loadCavePlaces() for caveId=${widget.caveId}');

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
    _filteredCavePlaces = filterCavePlaces(
      _cavePlaces,
      _filterController.text,
      _areaTitles,
    );
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

  void _onScan(String code) async {
    final qrCode = int.tryParse(code);
    if (qrCode != null) {
      final cavePlace = await cavePlaceRepository.findCavePlaceByQrCode(qrCode, widget.caveId);
      if (cavePlace != null) {
        // Record trip point if there's an active trip for this cave
        final activeTripCaveId = await caveTripService.getActiveTripCaveId();
        if (activeTripCaveId == widget.caveId) {
          await caveTripService.recordPoint(cavePlace.id, placeTitle: cavePlace.title);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(LocServ.inst.t('trip_point_added'))),
            );
          }
        }
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
        builder: (_) => MapViewerPage(cavePlaceId: cavePlace.id, caveId: widget.caveId),
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
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
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
          KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
        ],
      ),
      body: Stack(
        children: [
          _pinTopControls
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildTopControls(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildPlacesList(scrollable: true),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopControls(),
                        _buildPlacesList(scrollable: false),
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

  Widget _buildTopControls() {
    return Column(
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
              key: tourKeys['add'],
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CavePlacePage(caveId: widget.caveId),
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
                    builder: (_) => CaveAreasPage(caveId: widget.caveId),
                  ),
                );
                if (result == true) _loadCavePlaces();
              },
            ),
          ],
        ),

        const SizedBox(height: 4),

        if (_pastTripsCount > 0)
          PastTripsButton(
            pastTripsCount: _pastTripsCount,
            onPressed: () async {
              await Navigator.pushNamed(context, caveTripListRoute,
                  arguments: widget.caveId);
              _loadTripCount();
            },
          ),

        if (_showManualQrSection)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qrCodeController,
                      decoration: InputDecoration(
                        labelText: LocServ.inst.t('qr_code_identifier'),
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
                      LocServ.inst.t('search_place_by_qr_code_by_identifier'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),

        const SizedBox(height: 2),
        Row(
          key: tourKeys['list'],
          children: [
            Expanded(
              child: Text(
                '${LocServ.inst.t('cave_place')}:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            if (_checkboxMode) ...[
              IconButton(
                icon: const Icon(Icons.select_all, size: 20),
                tooltip: LocServ.inst.t('select_all'),
                onPressed: () {
                  setState(() {
                    _selectedPlaceIds = _filteredCavePlaces.map((cp) => cp.id).toSet();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.flip, size: 20),
                tooltip: LocServ.inst.t('invert_selection'),
                onPressed: () {
                  setState(() {
                    final all = _filteredCavePlaces.map((cp) => cp.id).toSet();
                    _selectedPlaceIds = all.difference(_selectedPlaceIds);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep, size: 20),
                tooltip: LocServ.inst.t('delete_selected'),
                color: Colors.red,
                onPressed: _selectedPlaceIds.isEmpty ? null : _deleteSelectedPlaces,
              ),
            ],
            IconButton(
              icon: Icon(
                Icons.checklist,
                size: 20,
                color: _checkboxMode ? Theme.of(context).colorScheme.primary : null,
              ),
              tooltip: LocServ.inst.t('select_mode'),
              onPressed: () {
                setState(() {
                  _checkboxMode = !_checkboxMode;
                  if (!_checkboxMode) _selectedPlaceIds.clear();
                });
              },
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
              decoration: InputDecoration(labelText: LocServ.inst.t('filter_cave_places')),
              onChanged: (v) {
                setState(() {
                  _applyFilter();
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPlacesList({required bool scrollable}) {
    final children = _filteredCavePlaces
        .map(
          (cp) {
            final bool isMainEntrance = cp.isMainEntrance == 1;
            final bool isEntrance = isMainEntrance || cp.isEntrance == 1;
            return ColoredBox(
              color: isEntrance ? const Color(0xFFF5F5F5) : const Color(0x00000000),
              child: Column(
            children: [
              InkWell(
                onTap: () async {
                  if (_checkboxMode) {
                    setState(() {
                      if (_selectedPlaceIds.contains(cp.id)) {
                        _selectedPlaceIds.remove(cp.id);
                      } else {
                        _selectedPlaceIds.add(cp.id);
                      }
                    });
                    return;
                  }
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
                      if (_checkboxMode)
                        Checkbox(
                          value: _selectedPlaceIds.contains(cp.id),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedPlaceIds.add(cp.id);
                              } else {
                                _selectedPlaceIds.remove(cp.id);
                              }
                            });
                          },
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                if (isMainEntrance) ...[
                                  const Icon(Icons.door_front_door, size: 15, color: Colors.blue),
                                  const SizedBox(width: 4),
                                ] else if (isEntrance) ...[
                                  Icon(Icons.door_front_door_outlined, size: 15, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    cp.title,
                                    style: const TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (isMainEntrance)
                              Text(
                                LocServ.inst.t('main_entrance'),
                                style: const TextStyle(fontSize: 11, color: Colors.blue),
                              )
                            else if (isEntrance)
                              Text(
                                LocServ.inst.t('entrance'),
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
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
        );
      },
    )
        .toList();

    if (scrollable) {
      return ListView(
        controller: _scrollController,
        children: children,
      );
    }
    return Column(children: children);
  }
}