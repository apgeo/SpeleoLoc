import 'package:flutter/material.dart';
import 'dart:async';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_places/past_trips_button.dart';
import 'package:speleoloc/screens/raster_map_place_selector.dart';
import 'package:speleoloc/screens/cave_place_page.dart';
import 'package:speleoloc/screens/generated_qr_code_viewer.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/icon_action_button.dart';
import 'package:speleoloc/widgets/place_code_batch_ui.dart';
import 'package:speleoloc/services/place_code/batch/place_code_batch_runner.dart';
import 'package:speleoloc/widgets/filterable_list.dart';
import 'package:speleoloc/screens/add_new_cave.dart';
import 'package:speleoloc/screens/general_data/cave_areas_page.dart';
import 'package:speleoloc/screens/csv_cave_place_import_page.dart';
import 'package:speleoloc/utils/deep_link_handler.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/widgets/qr_code_lookup_handler.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

class CavePlacesListPage extends StatefulWidget {
  const CavePlacesListPage({super.key, required this.caveUuid});

  final Uuid caveUuid;

  @override
  State<CavePlacesListPage> createState() => _CavePlacesListPageState();
}

class _CavePlacesListPageState extends State<CavePlacesListPage> with AppBarMenuMixin<CavePlacesListPage>, ProductTourMixin<CavePlacesListPage> {
  static const bool _pinTopControls = true;
  static const double TOOLBAR_BUTTON_SPACING = 1;
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
        ),
      // else ...[
      //   AppMenuItem(
      //     value: 'view_trip',
      //     icon: Icons.route,
      //     label: LocServ.inst.t('trip_view'),
      //   ),
      //   AppMenuItem(
      //     value: 'stop_trip',
      //     icon: Icons.stop,
      //     label: LocServ.inst.t('trip_stop'),
      //   ),
      // ],
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
      AppMenuItem(
        value: 'generate_codes',
        icon: Icons.auto_awesome,
        label: LocServ.inst.t('generate_codes'),
      ),
      AppMenuItem(
        value: 'raster_map_place_selector',
        icon: Icons.push_pin,
        label: LocServ.inst.t('raster_map_place_selector'),
      ),
    ];
  }

  @override
  void onScreenMenuItemSelected(String value) async {
    if (value == 'edit_cave') {
      final result = await Navigator.push<Uuid?>(
        context,
        MaterialPageRoute(
          builder: (_) => CaveFormPage(cave: _cave),
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
          builder: (_) => CSVCavePlacesImportPage(caveUuid: widget.caveUuid),
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
        await caveRepository.deleteCave(widget.caveUuid);
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } else if (value == 'start_trip') {
      await _startTrip();
    } else if (value == 'stop_trip') {
      await _stopTrip();
    } else if (value == 'view_trip') {
      _viewActiveTrip();
    } else if (value == 'generate_codes') {
      await PlaceCodeBatchUi.run(
        context,
        scope: PerCaveScope(widget.caveUuid),
        confirmTitle: LocServ.inst.t('generate_codes'),
        confirmBody: LocServ.inst.t('generate_codes_confirm_cave'),
      );
    } else if (value == 'raster_map_place_selector') {
      await _openRasterMapPlaceSelector();
    }
  }
  // Using global appDatabase instance
  Cave? _cave;
  List<CavePlace> _cavePlaces = [];
  final _qrCodeController = TextEditingController();
  bool _showManualQrSection = false;
  final FilterableListController<CavePlace> _listController =
      FilterableListController<CavePlace>();

  // Long-press on the scan toolbar button → manual QR search dialog.
  Timer? _qrScanLongPressTimer;
  final TextEditingController _manualQrSearchController =
      TextEditingController();
  Map<Uuid, String> _areaTitles = {};
  Map<Uuid, String> _surfaceAreaTitles = {};
  int _pastTripsCount = 0;

  // Per-place definitions info and scroll handling
  Map<Uuid, int> _definitionCountByPlace = {};
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
        .watchCavePlaces(widget.caveUuid)
        .skip(1) // initial load is handled by explicit _loadCavePlaces above
        .listen((_) {
      if (!mounted) return;
      _loadCavePlaces();
    });
  }

  Future<void> _loadSurfaceAreas() async {
    try {
      final areas = await (appDatabase.select(appDatabase.surfaceAreas)).get();
      _surfaceAreaTitles = {for (var a in areas) a.uuid: a.title};
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
    final trips = await appDatabase.getCaveTrips(widget.caveUuid);
    final ended = trips.where((t) => t.tripEndedAt != null).length;
    if (mounted) setState(() => _pastTripsCount = ended);
  }

  Future<void> _startTrip() async {
    final defaultTitle = '${_cave?.title ?? ''} ${dateFormat.format(DateTime.now())}';
    final existingTitles = await appDatabase.getCaveTripTitles(widget.caveUuid);
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
        ]
      ),
    );
    if (confirmed == true && mounted) {
      await caveTripService.startTrip(widget.caveUuid, controller.text.trim().isNotEmpty ? controller.text.trim() : suggestedTitle);
      if (mounted) {
        await Navigator.pushNamed(context, caveTripListRoute, arguments: widget.caveUuid);
        setState(() {});
      }
    }
  }

  /// Stops the active trip immediately (no confirmation dialog).
  Future<void> _performStopTrip() async {
    await caveTripService.stopTrip();
    if (mounted) {
      SnackBarService.showSuccess(LocServ.inst.t('trip_stopped'));
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
    if (confirmed == true) await _performStopTrip();
  }

  void _viewActiveTrip() {
    final id = caveTripService.activeTripIdNotifier.value;
    if (id == null) return;
    Navigator.pushNamed(context, caveTripRoute, arguments: id);
  }

  Future<void> _deleteSelectedPlaces(List<CavePlace> selected) async {
    for (final cp in selected) {
      await cavePlaceRepository.deleteCavePlace(cp.uuid);
    }
    await _loadCavePlaces();
  }

  Future<void> _printQRCodes() async {
    if (!mounted) return;
    final selectedFromController = _listController.selectedItems;
    if (_listController.selectionMode && selectedFromController.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GeneratedQRCodeViewer(cavePlaces: selectedFromController),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GeneratedQRCodeViewer(caveUuid: widget.caveUuid),
        ),
      );
    }
  }

  Future<void> _openRasterMapPlaceSelector() async {
    final rasterMaps = await (appDatabase.select(appDatabase.rasterMaps)
          ..where((rm) => rm.caveUuid.equalsValue(widget.caveUuid)))
        .get();
    if (rasterMaps.isEmpty) {
      if (mounted) SnackBarService.showWarning(LocServ.inst.t('no_raster_maps_for_cave'));
      return;
    }
    if (_cavePlaces.isEmpty) {
      if (mounted) SnackBarService.showWarning(LocServ.inst.t('no_cave_places'));
      return;
    }
    final rm = rasterMaps.first;
    final cavePlacesWithDefs = await appDatabase
        .getCavePlacesWithDefinitionsForRasterMap(widget.caveUuid, rm.uuid);
    final firstPlaceId = _cavePlaces.first.uuid;
    final existing = await appDatabase.getDefinition(firstPlaceId, rm.uuid);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RasterMapPlaceSelectorPage(
          rasterMap: rm,
          cavePlaceUuid: firstPlaceId,
          cavePlacesWithDefinitions: cavePlacesWithDefs,
          existingDefinition: existing,
          initialTapDefinesNewPoint: false,
        ),
      ),
    );
    if (mounted) await _loadCavePlaces();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.position.maxScrollExtent > 0;
    if (show != _showDownArrow) setState(() => _showDownArrow = show);
  }

  @override
  void dispose() {
    _qrCodeController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _cavePlacesSub?.cancel();
    _listController.dispose();
    _qrScanLongPressTimer?.cancel();
    _manualQrSearchController.dispose();
    caveTripService.activeTripIdNotifier.removeListener(_onTripStateChanged);
    super.dispose();
  }

  void _startQrScanLongPress() {
    _qrScanLongPressTimer?.cancel();
    _qrScanLongPressTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) _showManualQrSearchDialog();
    });
  }

  void _cancelQrScanLongPress() {
    _qrScanLongPressTimer?.cancel();
    _qrScanLongPressTimer = null;
  }

  Future<void> _showManualQrSearchDialog() async {
    _manualQrSearchController.clear();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('manual_qr_search')),
        content: TextField(
          controller: _manualQrSearchController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: LocServ.inst.t('qr_code_identifier'),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocServ.inst.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, _manualQrSearchController.text.trim()),
            child:
                Text(LocServ.inst.t('search_place_by_qr_code_by_identifier')),
          ),
        ],
      ),
    );
    if (confirmed != null && confirmed.isNotEmpty && mounted) {
      await _onScan(confirmed);
    }
  }

  Future<void> _loadCave() async {
    _cave = await (appDatabase.select(
      appDatabase.caves,
    )..where((c) => c.uuid.equalsValue(widget.caveUuid))).getSingleOrNull();
    // Save last open cave for deep link resolution
    DeepLinkHandler.saveLastOpenCave(widget.caveUuid);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadCavePlaces() async {
    AppLogger.of('CavePlacesListPage').fine('_loadCavePlaces() for caveUuid=${widget.caveUuid}');

    _cavePlaces = await cavePlaceRepository.getCavePlaces(widget.caveUuid);
    await _loadCaveAreas();

    // Compute raster maps count and how many raster maps have definitions for each cave place
    final rasterMaps = await (appDatabase.select(
      appDatabase.rasterMaps,
    )..where((rm) => rm.caveUuid.equalsValue(widget.caveUuid))).get();
    final rasterMapIds = rasterMaps.map((r) => r.uuid).toList();
    _rasterMapsCountForCave = rasterMapIds.length;

    Map<Uuid, Set<Uuid>> placeToRasters = {};
    if (rasterMapIds.isNotEmpty) {
      final defs = await (appDatabase.select(
        appDatabase.cavePlaceToRasterMapDefinitions,
      )..where((d) => d.rasterMapUuid.isInValues(rasterMapIds))).get();
      for (final d in defs) {
        final cpId = d.cavePlaceUuid;
        final rmId = d.rasterMapUuid;
        placeToRasters
            .putIfAbsent(cpId, () => <Uuid>{})
            .add(rmId);
      }
    }
    _definitionCountByPlace = {
      for (var cp in _cavePlaces) cp.uuid: (placeToRasters[cp.uuid]?.length ?? 0),
    };

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
      )..where((a) => a.caveUuid.equalsValue(widget.caveUuid))).get();
      _areaTitles = {for (var a in areas) a.uuid: a.title};
    } catch (e) {
      _areaTitles = {};
    }
  }

  Future<void> _showDefinitionsReport(Uuid cavePlaceUuid) async {
    // Load raster maps for cave and check if definition exists for each
    final rasterMaps = await (appDatabase.select(
      appDatabase.rasterMaps,
    )..where((rm) => rm.caveUuid.equalsValue(widget.caveUuid))).get();
    final List<Map<String, dynamic>> rows = [];
    for (final rm in rasterMaps) {
      final def = await appDatabase.getDefinition(cavePlaceUuid, rm.uuid);
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
                            cavePlaceUuid,
                            rm.uuid,
                          );
                          final cavePlacesWithDefs = await appDatabase
                              .getCavePlacesWithDefinitionsForRasterMap(
                                widget.caveUuid,
                                rm.uuid,
                              );
                          if (!mounted) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RasterMapPlaceSelectorPage(
                                rasterMap: rm,
                                cavePlaceUuid: cavePlaceUuid,
                                cavePlacesWithDefinitions: cavePlacesWithDefs,
                                existingDefinition: existing,
                                initialTapDefinesNewPoint: false,
                              ),
                            ),
                          );
                          if (mounted) await _loadCavePlaces();
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

  Future<void> _deleteCavePlace(Uuid id) async {
    await cavePlaceRepository.deleteCavePlace(id);
    _loadCavePlaces();
    if (mounted) SnackBarService.showSuccess(LocServ.inst.t('cave_place_deleted'));
  }

  Future<void> _confirmDeleteCavePlace(Uuid id) async {
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

  Future<void> _onScan(String code) async {
    final result =
        await QrCodeLookupHandler.defaultInstance().handleScannedCode(
      context,
      code,
      currentCaveId: widget.caveUuid,
    );
    if (result != null && mounted) _loadCavePlaces();
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
            if (_cave?.surfaceAreaUuid != null && _surfaceAreaTitles[_cave!.surfaceAreaUuid] != null)
              Text(
                _surfaceAreaTitles[_cave!.surfaceAreaUuid]!,
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
                        child: _buildPlacesList(),
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
                        _buildPlacesList(),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Listener(
                onPointerDown: enableQrManualInput
                    ? (_) => _startQrScanLongPress()
                    : null,
                onPointerUp: enableQrManualInput
                    ? (_) => _cancelQrScanLongPress()
                    : null,
                onPointerCancel: enableQrManualInput
                    ? (_) => _cancelQrScanLongPress()
                    : null,
                child: IconActionButton(
                  onPressed: () async {
                    final result = await QrCodeLookupHandler.openAndHandle(
                      context,
                      currentCaveId: widget.caveUuid,
                    );
                    if (result != null && mounted) _loadCavePlaces();
                  },
                  icon: Icons.qr_code_scanner,
                  tooltip: LocServ.inst.t('scan_qr'),
                ),
              ),
              const SizedBox(width: TOOLBAR_BUTTON_SPACING),
              IconActionButton(
                key: tourKeys['add'],
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CavePlacePage(caveUuid: widget.caveUuid),
                    ),
                  );
                  if (result == true) _loadCavePlaces();
                },
                icon: Icons.add,
                tooltip: LocServ.inst.t('add_cave_place'),
              ),
              const SizedBox(width: TOOLBAR_BUTTON_SPACING),
              IconActionButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    rasterMapsRoute,
                    arguments: widget.caveUuid,
                  );
                  if (result == true) _loadCavePlaces();
                },
                icon: Icons.map,
                tooltip: LocServ.inst.t('view_raster_maps'),
              ),
              const SizedBox(width: TOOLBAR_BUTTON_SPACING),
              IconActionButton(
                onPressed: _printQRCodes,
                icon: Icons.print,
                tooltip: LocServ.inst.t('print_qr_codes'),
              ),
              const SizedBox(width: TOOLBAR_BUTTON_SPACING),
              IconActionButton(
                onPressed: () {
                  setState(() {
                    _showManualQrSection = !_showManualQrSection;
                  });
                },
                icon: Icons.qr_code_rounded,
                tooltip: LocServ.inst.t('manual_qr_search'),
              ),
              const SizedBox(width: TOOLBAR_BUTTON_SPACING),
              IconButton(
                icon: const Icon(Icons.layers),
                tooltip: LocServ.inst.t('manage_cave_areas'),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CaveAreasPage(caveUuid: widget.caveUuid),
                    ),
                  );
                  if (result == true) _loadCavePlaces();
                },
              ),
              const SizedBox(width: TOOLBAR_BUTTON_SPACING),
              IconActionButton(
                onPressed: _openRasterMapPlaceSelector,
                icon: Icons.push_pin,
                tooltip: LocServ.inst.t('raster_map_place_selector'),
              ),
              const SizedBox(width: TOOLBAR_BUTTON_SPACING),
              IconActionButton(
                onPressed: () async {
                  final result = await Navigator.push<bool?>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CSVCavePlacesImportPage(caveUuid: widget.caveUuid),
                    ),
                  );
                  if (result == true) _loadCavePlaces();
                },
                icon: Icons.upload_file,
                tooltip: LocServ.inst.t('csv_import_places'),
              ),
              const SizedBox(width: TOOLBAR_BUTTON_SPACING),
              IconActionButton(
                onPressed: () async {
                  await PlaceCodeBatchUi.run(
                    context,
                    scope: PerCaveScope(widget.caveUuid),
                    confirmTitle: LocServ.inst.t('generate_codes'),
                    confirmBody: LocServ.inst.t('generate_codes_confirm_cave'),
                  );
                },
                icon: Icons.auto_awesome,
                tooltip: LocServ.inst.t('generate_codes'),
              ),
              const SizedBox(width: TOOLBAR_BUTTON_SPACING),
              PopupMenuButton<String>(
                icon: const Icon(Icons.home_filled),
                tooltip: LocServ.inst.t('cave_management'),
                padding: EdgeInsets.zero,
                onSelected: (value) => onScreenMenuItemSelected(value),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit_cave',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note, size: 20),
                        const SizedBox(width: 8),
                        Text(LocServ.inst.t('edit_cave')),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          LocServ.inst.t('delete_cave'),
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        if (_pastTripsCount > 0)
          PastTripsButton(
            pastTripsCount: _pastTripsCount,
            onPressed: () async {
              await Navigator.pushNamed(context, caveTripListRoute,
                  arguments: widget.caveUuid);
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
      ],
    );
  }

  Widget _buildPlacesList() {
    return FilterableList<CavePlace>(
      headerKey: tourKeys['list'],
      headerLabelText: '${LocServ.inst.t('cave_place')}:',
      items: _cavePlaces,
      keyOf: (cp) => cp.uuid,
      controller: _listController,
      scrollController: _scrollController,
      filterHintText: LocServ.inst.t('filter_cave_places'),
      persistKey: 'cave_places_list_sort',
      initialSort: const FilterableListSortSpec(
        primaryFieldId: 'last_modified',
        primaryAscending: false,
      ),
      sortFields: [
        FilterableListSortField<CavePlace>(
          id: 'last_modified',
          label: LocServ.inst.t('sort_last_modified'),
          compare: (a, b) => (a.updatedAt ?? 0).compareTo(b.updatedAt ?? 0),
        ),
        FilterableListSortField<CavePlace>(
          id: 'title',
          label: LocServ.inst.t('title'),
          compare: (a, b) =>
              a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          groupKeyOf: (cp) {
            final t = cp.title.trim();
            return t.isEmpty ? '' : t[0].toUpperCase();
          },
        ),
        FilterableListSortField<CavePlace>(
          id: 'cave_area',
          label: LocServ.inst.t('cave_area'),
          compare: (a, b) {
            final at = a.caveAreaUuid != null
                ? (_areaTitles[a.caveAreaUuid] ?? '')
                : '';
            final bt = b.caveAreaUuid != null
                ? (_areaTitles[b.caveAreaUuid] ?? '')
                : '';
            return at.toLowerCase().compareTo(bt.toLowerCase());
          },
          groupKeyOf: (cp) => cp.caveAreaUuid != null
              ? (_areaTitles[cp.caveAreaUuid] ?? '')
              : '',
        ),
        FilterableListSortField<CavePlace>(
          id: 'depth',
          label: LocServ.inst.t('sort_depth'),
          // Treat null depth as +infinity so unspecified entries sort last
          // when ascending.
          compare: (a, b) => (a.depthInCave ?? double.infinity)
              .compareTo(b.depthInCave ?? double.infinity),
        ),
        FilterableListSortField<CavePlace>(
          id: 'qr_code_identifier',
          label: LocServ.inst.t('qr_code_identifier'),
          // Null PCIs sort last on ascending.
          compare: (a, b) {
            final av = a.placeCodeIdentifier;
            final bv = b.placeCodeIdentifier;
            if (av == null && bv == null) return 0;
            if (av == null) return 1;
            if (bv == null) return -1;
            return av.compareTo(bv);
          },
        ),
        FilterableListSortField<CavePlace>(
          id: 'is_entrance',
          label: LocServ.inst.t('sort_is_entrance'),
          // Main entrance > entrance > non-entrance, so ascending puts
          // non-entrances first; descending puts main entrances first.
          compare: (a, b) {
            int rank(CavePlace p) =>
                p.isMainEntrance == 1 ? 2 : (p.isEntrance == 1 ? 1 : 0);
            return rank(a).compareTo(rank(b));
          },
          groupKeyOf: (cp) {
            if (cp.isMainEntrance == 1) return LocServ.inst.t('main_entrance');
            if (cp.isEntrance == 1) return LocServ.inst.t('entrance');
            return LocServ.inst.t('sort_non_entrance');
          },
        ),
        FilterableListSortField<CavePlace>(
          id: 'has_qr_code',
          label: LocServ.inst.t('sort_has_qr_code'),
          compare: (a, b) {
            final av = a.placeCodeIdentifier != null ? 1 : 0;
            final bv = b.placeCodeIdentifier != null ? 1 : 0;
            return av.compareTo(bv);
          },
          groupKeyOf: (cp) => cp.placeCodeIdentifier != null
              ? LocServ.inst.t('sort_has_qr_code_yes')
              : LocServ.inst.t('sort_has_qr_code_no'),
        ),
        FilterableListSortField<CavePlace>(
          id: 'definitions_count',
          label: LocServ.inst.t('sort_definitions_count'),
          compare: (a, b) => (_definitionCountByPlace[a.uuid] ?? 0)
              .compareTo(_definitionCountByPlace[b.uuid] ?? 0),
        ),
      ],
      filter: (cp, qLower) {
        if (cp.title.toLowerCase().contains(qLower)) return true;
        if (cp.placeCodeIdentifier?.toLowerCase().contains(qLower) ?? false) {
          return true;
        }
        final areaTitle = (cp.caveAreaUuid != null)
            ? (_areaTitles[cp.caveAreaUuid] ?? '')
            : '';
        return areaTitle.toLowerCase().contains(qLower);
      },
      onBulkDelete: _deleteSelectedPlaces,
      onItemTap: (cp) async {
        final result = await Navigator.pushNamed(
          context,
          cavePlaceRoute,
          arguments: {
            'caveUuid': widget.caveUuid,
            'cavePlaceUuid': cp.uuid,
          },
        );
        if (result == true) _loadCavePlaces();
      },
      itemDecoration: (context, cp, child) {
        final bool isMainEntrance = cp.isMainEntrance == 1;
        final bool isEntrance = isMainEntrance || cp.isEntrance == 1;
        return ColoredBox(
          color: isEntrance
              ? const Color(0xFFF5F5F5)
              : const Color(0x00000000),
          child: child,
        );
      },
      itemBuilder: (context, cp, _) {
        final bool isMainEntrance = cp.isMainEntrance == 1;
        final bool isEntrance = isMainEntrance || cp.isEntrance == 1;
        return Row(
          children: [
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
                cp.placeCodeIdentifier != null
                    ? Icons.qr_code
                    : Icons.qr_code_outlined,
                color: cp.placeCodeIdentifier != null
                    ? Colors.green.withValues(alpha: 0.8)
                    : Colors.grey,
                size: 20,
              ),
            ),
            Builder(
              builder: (context) {
                final count = _definitionCountByPlace[cp.uuid] ?? 0;
                final Color col = (count == 0)
                    ? Colors.red.withValues(alpha: 0.8)
                    : (count == _rasterMapsCountForCave && _rasterMapsCountForCave > 0)
                        ? Colors.green.withValues(alpha: 0.8)
                        : Colors.grey;
                return InkWell(
                  onTap: () => _showDefinitionsReport(cp.uuid),
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
              onPressed: () => _confirmDeleteCavePlace(cp.uuid),
              icon: Icons.delete,
              tooltip: LocServ.inst.t('delete_cave_place'),
            ),
          ],
        );
      },
    );
  }
}