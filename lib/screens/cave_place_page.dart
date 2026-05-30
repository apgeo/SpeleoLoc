import 'package:flutter/material.dart';
import 'dart:async';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_place/cave_place_area_row.dart';
import 'package:speleoloc/screens/cave_place/cave_place_confirmation_port.dart';
import 'package:speleoloc/screens/cave_place/cave_place_coordinates_section.dart';
import 'package:speleoloc/screens/cave_place/cave_place_entrance_handler.dart';
import 'package:speleoloc/screens/cave_place/cave_place_entrance_toggles.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_controller.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_utils.dart';
import 'package:speleoloc/screens/cave_place/cave_place_map_tab.dart';
import 'package:speleoloc/screens/cave_place/cave_place_pci_section.dart';
import 'package:speleoloc/screens/cave_place/cave_place_qcri_section.dart';
import 'package:speleoloc/screens/cave_place/cave_place_qr_controller.dart';
import 'package:speleoloc/screens/cave_place/cave_place_raster_maps_section.dart';
import 'package:speleoloc/screens/cave_place/cave_place_save_command.dart';
import 'package:speleoloc/screens/cave_place/cave_place_title_section.dart';
import 'package:speleoloc/screens/gps_recorder_page.dart';
import 'package:speleoloc/screens/general_data/cave_areas_page.dart';
import 'package:speleoloc/screens/geofeature_documents_page.dart';
import 'package:speleoloc/services/documents_controller.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

class CavePlacePage extends StatefulWidget {
  const CavePlacePage({super.key, required this.caveUuid, this.cavePlaceUuid});

  final Uuid caveUuid;
  final Uuid? cavePlaceUuid;

  @override
  State<CavePlacePage> createState() => _CavePlacePageState();
}

class _CavePlacePageState extends State<CavePlacePage>
    with TickerProviderStateMixin, AppBarMenuMixin<CavePlacePage>, ProductTourMixin<CavePlacePage> {
  @override
  String get tourId => 'cave_place';
  @override
  final tourKeys = TourKeySet(['title_field', 'desc_field', 'depth_field', 'qr_field', 'tabs', 'menu']);
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'title_field', titleLocKey: 'tour_cave_place_title_field_title', bodyLocKey: 'tour_cave_place_title_field_body'),
    TourStepDef(keyId: 'desc_field', titleLocKey: 'tour_cave_place_desc_field_title', bodyLocKey: 'tour_cave_place_desc_field_body'),
    TourStepDef(keyId: 'depth_field', titleLocKey: 'tour_cave_place_depth_field_title', bodyLocKey: 'tour_cave_place_depth_field_body'),
    TourStepDef(keyId: 'qr_field', titleLocKey: 'tour_cave_place_qr_field_title', bodyLocKey: 'tour_cave_place_qr_field_body'),
    TourStepDef(keyId: 'tabs', titleLocKey: 'tour_cave_place_tabs_title', bodyLocKey: 'tour_cave_place_tabs_body', align: ContentAlign.top),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_cave_place_menu_title', bodyLocKey: 'tour_cave_place_menu_body'),
  ];
  @override
  List<AppMenuItem> get screenMenuItems => [
    AppMenuItem(
      value: 'toggle_gps',
      icon: _showLatLngFields ? Icons.check_box : Icons.check_box_outline_blank,
      label: LocServ.inst.t('show_hide_gps'),
    ),
  ];

  @override
  void onScreenMenuItemSelected(String value) {
    if (value == 'toggle_gps') {
      setState(() {
        _showLatLngFields = !_showLatLngFields;
      });
    }
  }

  // Using global appDatabase instance
  CavePlace? _cavePlace;
  Uuid? _currentCavePlaceId;
  Cave? _cave;
  List<RasterMap> _rasterMaps = [];
  List<CaveArea> _caveAreas = [];

  /// All form-field state (text controllers, dirty flags, toggle states)
  /// lives on this controller. See [CavePlaceFormController].
  final _form = CavePlaceFormController();

  bool _qrEditable = false;
  bool _qcriEditable = false;

  TabController? _tabController;
  bool _showLatLngFields = false;
  int _currentTabIndex = 0;
  int _descriptionLines = 1;

  /// When true, hide the PCI row (it's identical to QCRI in mirror mode).
  /// User can press the "show" button on the area row to reveal it.
  bool _pciRowHidden = false;

  /// Handles all QR-scan and place-code-generation interactions.
  late CavePlaceQrController _qrController;

  @override
  void initState() {
    super.initState();
    _currentCavePlaceId = widget.cavePlaceUuid;
    AppLogger.of('CavePlacePage').fine('initState caveUuid=${widget.caveUuid}');
    _qrController = CavePlaceQrController(
      state: this,
      form: _form,
      cavePlaceRepository: cavePlaceRepository,
      placeCodeService: placeCodeService,
      caveUuid: widget.caveUuid,
      cavePlaceId: () => _currentCavePlaceId,
      cavePlace: () => _cavePlace,
      rebuild: setState,
      setQrEditable: (v) => _qrEditable = v,
      setQcriEditable: (v) => _qcriEditable = v,
    );
    _loadData();

    _form.attachTextListeners(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _form.dispose();

    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _qrController.dispose();
    super.dispose();
  }

  void _loadData() async {
    // PR 11: kick off the four independent repository reads in parallel.
    // Before this change these were 4–5 sequential awaits (cave, cavePlace,
    // rasterMaps, caveAreas, then mirror-mode), which on cold DB cache
    // dominated the page-open latency. The mirror-mode check still runs
    // sequentially because it needs the form text populated from _cavePlace.
    final caveFuture = caveRepository.findById(widget.caveUuid);
    final cavePlaceFuture = _currentCavePlaceId != null
        ? cavePlaceRepository.findById(_currentCavePlaceId!)
        : Future<CavePlace?>.value(null);
    final rasterMapsFuture = rasterMapRepository.getRasterMaps(widget.caveUuid);
    final caveAreasFuture = caveRepository.getCaveAreas(widget.caveUuid);

    _cave = await caveFuture;
    if (_currentCavePlaceId != null) {
      _cavePlace = await cavePlaceFuture;
      if (_cavePlace == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      // Populate form controllers + reset dirty flags.
      // Note: the cave-area selection is assigned below after _caveAreas
      // is loaded, to avoid a DropdownButtonFormField assertion when
      // setState fires from text controller listeners before the areas
      // list is available.
      _form.loadFrom(_cavePlace);
      _descriptionLines = _computeDescriptionLines(_form.description.text);
    } else {
      _form.loadFrom(null);
      _descriptionLines = 1;
    }
    // Hide PCI row by default when mirror mode is active AND PCI equals
    // QCRI — the user is unlikely to want to edit a field that mirrors
    // another. They can reveal it with a button on the area row.
    try {
      final mirror = await placeCodeService.isMirrorMode();
      final pci = _form.qr.text.trim();
      final qcri = _form.qcri.text.trim();
      _pciRowHidden = mirror && pci.isNotEmpty && pci == qcri;
    } catch (e, st) {
      log.warning('PCI mirror-mode check failed; showing PCI row', e, st);
      _pciRowHidden = false;
    }
    _rasterMaps = await rasterMapsFuture;

    // Load cave areas for the cave (used in the dropdown)
    final loadedAreas = await caveAreasFuture;
    // Deduplicate by UUID to prevent DropdownButtonFormField assertion errors
    final seenUuids = <dynamic>{};
    final deduplicatedAreas =
        loadedAreas.where((a) => seenUuids.add(a.uuid)).toList();
    // Determine the selected area: use the value from the loaded place only if
    // it exists in the areas list; otherwise fall back to null.
    final initialAreaId = _cavePlace?.caveAreaUuid;
    final resolvedAreaId =
        (initialAreaId != null &&
                deduplicatedAreas.any((a) => a.uuid == initialAreaId))
            ? initialAreaId
            : null;

    if (!mounted) return;
    setState(() {
      _caveAreas = deduplicatedAreas;
      _form.selectedCaveAreaId = resolvedAreaId;
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

  Future<Uuid?> _save({bool closeAfterSave = true}) async {
    final command = CavePlaceSaveCommand(
      caveUuid: widget.caveUuid,
      currentCavePlaceId: _currentCavePlaceId,
      form: _form,
      repository: cavePlaceRepository,
      placeCodeService: placeCodeService,
      confirmations: PageCavePlaceConfirmationPort(this),
    );
    final result = await command.execute();
    switch (result) {
      case SaveValidationFailed(:final messageKey):
        SnackBarService.showWarning(LocServ.inst.t(messageKey));
        return null;
      case SaveCancelled():
        return null;
      case SaveOk(:final uuid):
        if (!mounted) return uuid;
        if (closeAfterSave) {
          Navigator.pop(context, true);
        } else {
          await _refreshCavePlaceState(uuid);
        }
        return uuid;
    }
  }

  Future<void> _refreshCavePlaceState(Uuid cavePlaceUuid) async {
    final refreshed = await cavePlaceRepository.findById(cavePlaceUuid);

    if (!mounted || refreshed == null) return;
    _cavePlace = refreshed;
    setState(() {
      _currentCavePlaceId = cavePlaceUuid;
      _form.adoptAsBaseline(refreshed);
    });
  }

  Future<void> _onEntranceToggleRequested(bool enabled) async {
    if (enabled == _form.isEntrance) return;
    final apply = enabled
        ? await CavePlaceEntranceHandler.confirmEnableEntrance(
            context,
            repository: cavePlaceRepository,
            caveUuid: widget.caveUuid,
            excludeUuid: _currentCavePlaceId,
          )
        : await CavePlaceEntranceHandler.confirmDisableEntrance(context);
    if (!apply || !mounted) return;
    setState(() {
      _form.setEntrance(enabled);
      if (!enabled) _form.setMainEntrance(false);
    });
  }

  Future<void> _onMainEntranceToggleRequested(bool enabled) async {
    if (!_form.isEntrance || enabled == _form.isMainEntrance) return;
    final apply = enabled
        ? await CavePlaceEntranceHandler.confirmEnableMainEntrance(
            context,
            repository: cavePlaceRepository,
            caveUuid: widget.caveUuid,
            excludeUuid: _currentCavePlaceId,
          )
        : await CavePlaceEntranceHandler.confirmDisableMainEntrance(context);
    if (!apply || !mounted) return;
    setState(() => _form.setMainEntrance(enabled));
  }

  int _computeDescriptionLines(String text) => computeDescriptionLines(text);

  Future<bool> _onWillPop() async {
    if (!_form.hasUnsavedChanges) return true;

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

  Future<void> _openGpsRecorder() async {
    final result = await Navigator.push<GpsRecorderResult>(
      context,
      MaterialPageRoute(builder: (_) => const GpsRecorderPage()),
    );
    if (!mounted || result == null) return;
    setState(() {
      _form.lat.text = result.latitude.toStringAsFixed(7);
      _form.long.text = result.longitude.toStringAsFixed(7);
      if (result.altitude != null) {
        _form.alt.text = result.altitude!.toStringAsFixed(1);
      }
    });
  }

  Widget _buildMapTab(RasterMap rm) {
    return CavePlaceMapTab(
      caveUuid: widget.caveUuid,
      cavePlaceUuid: _currentCavePlaceId,
      rasterMap: rm,
      useInteractiveEditor: false,
      onSaveRequired: () => _save(closeAfterSave: false),
    );
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
        key: appMenuScaffoldKey,
        endDrawer: buildAppMenuEndDrawer(),
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
                          cavePlaceUuid: _currentCavePlaceId!,
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
            KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CavePlaceTitleSection(
                  form: _form,
                  descriptionLines: _descriptionLines,
                  onExpandDescription: () {
                    setState(() {
                      if (_descriptionLines < 5) {
                        _descriptionLines += 1;
                      }
                    });
                  },
                  titleFieldKey: tourKeys['title_field'],
                  descFieldKey: tourKeys['desc_field'],
                ),
                const SizedBox(height: 8),
                // Cave area dropdown, manage-areas button, depth field, and
                // optional PCI-row visibility toggle.
                CavePlaceAreaRow(
                  form: _form,
                  caveAreas: _caveAreas,
                  depthFieldKey: tourKeys['depth_field'],
                  pciRowHidden: _pciRowHidden,
                  onAreaChanged: (v) => setState(() => _form.setArea(v)),
                  onManageAreas: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CaveAreasPage(caveUuid: widget.caveUuid),
                      ),
                    );
                    // Reload areas after returning from CaveAreasPage.
                    final reloadedAreas =
                        await caveRepository.getCaveAreas(widget.caveUuid);
                    // Deduplicate by UUID to prevent DropdownButtonFormField
                    // assertion errors.
                    final seen = <dynamic>{};
                    final deduped = reloadedAreas
                        .where((a) => seen.add(a.uuid))
                        .toList();
                    setState(() {
                      _caveAreas = deduped;
                      // Clear selected area if it was deleted.
                      if (_form.selectedCaveAreaId != null &&
                          !_caveAreas
                              .any((a) => a.uuid == _form.selectedCaveAreaId)) {
                        _form.selectedCaveAreaId = null;
                      }
                    });
                  },
                  onShowPciRow: () => setState(() => _pciRowHidden = false),
                ),
                const SizedBox(height: 8),
                // Place code identifier with edit toggle.
                // Hidden when QCRI mirrors PCI (mode=mirror) and the
                // two values are equal — the user can reveal it with
                // the eye-button on the area row above.
                CavePlacePciSection(
                  visible: !_pciRowHidden,
                  form: _form,
                  editable: _qrEditable,
                  onEditableToggled: () => setState(() => _qrEditable = !_qrEditable),
                  onAutoGenerate: _qrController.autoGeneratePci,
                  rowKey: tourKeys['qr_field'],
                ),
                const SizedBox(height: 8),
                // QR code resource identifier row
                CavePlaceQcriSection(
                  form: _form,
                  editable: _qcriEditable,
                  onEditableToggled: () => setState(() => _qcriEditable = !_qcriEditable),
                  onAutoGenerate: _qrController.autoGenerateQcri,
                  onOpenScanner: _qrController.openScanner,
                  onScanLongPressStart: _qrController.startLongPress,
                  onScanLongPressEnd: _qrController.cancelLongPress,
                  cavePlace: _cavePlace,
                  currentCavePlaceId: _currentCavePlaceId,
                ),
                const SizedBox(height: 8),
                CavePlaceCoordinatesSection(
                  visible: _showLatLngFields,
                  form: _form,
                  onOpenGpsRecorder: _openGpsRecorder,
                ),

                /// Raster maps section
                if (_rasterMaps.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  CavePlaceRasterMapsSection(
                    rasterMaps: _rasterMaps,
                    tabController: _tabController,
                    currentTabIndex: _currentTabIndex,
                    buildMapTab: _buildMapTab,
                    tabsKey: tourKeys['tabs'],
                  ),
                ],

                const SizedBox(height: 4),
                CavePlaceEntranceToggles(
                  form: _form,
                  onEntranceChanged: _onEntranceToggleRequested,
                  onMainEntranceChanged: _onMainEntranceToggleRequested,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

