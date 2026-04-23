import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_utils.dart';
import 'package:speleoloc/screens/cave_place/cave_place_map_tab.dart';
import 'package:speleoloc/screens/scanner_page.dart';
import 'package:speleoloc/screens/general_data/cave_areas_page.dart';
import 'package:speleoloc/screens/geofeature_documents_page.dart';
import 'package:speleoloc/services/documents_controller.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/cave_place_qr_preview_dialog.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

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

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _depthController = TextEditingController();
  final _qrController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();

  bool _qrEditable = false;

  TabController? _tabController;
  bool _showLatLngFields = false;
  int _currentTabIndex = 0;
  Uuid? _selectedCaveAreaId;
  // bool _qrEnabled = false;

  bool _hasUnsavedChanges = false;
  bool _titleModified = false;
  bool _descriptionModified = false;
  bool _depthModified = false;
  bool _qrModified = false;
  bool _latModified = false;
  bool _longModified = false;
  bool _entranceModified = false;
  bool _mainEntranceModified = false;
  bool _isEntrance = false;
  bool _isMainEntrance = false;
  int _descriptionLines = 1;

  // Feature toggle: show interactive RasterMapPlacePointEditor in the
  // "Raster maps" tab of CavePlacePage. Disabled by default so the
  // page shows a plain `Image` as before the refactor.
  static const bool USE_RASTER_EDITOR_IN_CAVEPLACE = false;

  @override
  void initState() {
    super.initState();
    _currentCavePlaceId = widget.cavePlaceUuid;
    AppLogger.of('CavePlacePage').fine('initState caveUuid=${widget.caveUuid}');
    _loadData();

    _titleController.addListener(() => _onFieldEdited('title'));
    _descriptionController.addListener(() => _onFieldEdited('description'));
    _depthController.addListener(() => _onFieldEdited('depth'));
    _qrController.addListener(() => _onFieldEdited('qr'));
    _latController.addListener(() => _onFieldEdited('lat'));
    _longController.addListener(() => _onFieldEdited('long'));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _depthController.dispose();
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
    )..where((c) => c.uuid.equalsValue(widget.caveUuid))).getSingleOrNull();
    if (_currentCavePlaceId != null) {
      _cavePlace = await (appDatabase.select(
        appDatabase.cavePlaces,
      )..where((cp) => cp.uuid.equalsValue(_currentCavePlaceId!))).getSingleOrNull();
      if (_cavePlace == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      _titleController.text = _cavePlace!.title;
      _descriptionController.text = _cavePlace!.description ?? '';
      _descriptionLines = _computeDescriptionLines(_descriptionController.text);
      _depthController.text = _formatDepthValue(_cavePlace!.depthInCave);
      _qrController.text = _cavePlace!.placeQrCodeIdentifier?.toString() ?? '';
      _latController.text = _cavePlace!.latitude?.toString() ?? '';
      _longController.text = _cavePlace!.longitude?.toString() ?? '';
      _selectedCaveAreaId = _cavePlace!.caveAreaUuid;
      _isEntrance = (_cavePlace!.isEntrance ?? 0) == 1;
      _isMainEntrance = (_cavePlace!.isMainEntrance ?? 0) == 1;
    } else {
      _descriptionLines = 1;
      _isEntrance = false;
      _isMainEntrance = false;
    }
    _rasterMaps = await (appDatabase.select(
      appDatabase.rasterMaps,
    )..where((rm) => rm.caveUuid.equalsValue(widget.caveUuid))).get();

    // Load cave areas for the cave (used in the dropdown)
    _caveAreas = await (appDatabase.select(
      appDatabase.caveAreas,
    )..where((ca) => ca.caveUuid.equalsValue(widget.caveUuid))).get();

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

  Future<Uuid?> _save({bool closeAfterSave = true}) async {
    final title = _titleController.text;
    final description = _descriptionController.text.isEmpty
        ? null
        : _descriptionController.text;
    final depth = _parseDepthValue(_depthController.text);
    final qr = int.tryParse(_qrController.text);
    final lat = double.tryParse(_latController.text);
    final long = double.tryParse(_longController.text);

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(LocServ.inst.t('title_required'))));
      return null;
    }

    if (_depthController.text.trim().isNotEmpty && depth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocServ.inst.t('depth_invalid_number'))),
      );
      return null;
    }

    if (depth != null && (depth < -5000 || depth > 5000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocServ.inst.t('depth_out_of_range'))),
      );
      return null;
    }

    if (depth != null && (depth < -1800 || depth > 1800)) {
      final confirmExtremeDepth = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(LocServ.inst.t('confirm')),
          content: Text(
            LocServ.inst
                .t('depth_outlier_confirm')
                .replaceAll('{depth}', _formatDepthValue(depth)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(LocServ.inst.t('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(LocServ.inst.t('yes')),
            ),
          ],
        ),
      );
      if (confirmExtremeDepth != true) return null;
    }

    // Check for duplicate QR code within the same cave
    if (qr != null) {
      final duplicates = await (appDatabase.select(appDatabase.cavePlaces)
            ..where((cp) =>
                cp.caveUuid.equalsValue(widget.caveUuid) &
                cp.placeQrCodeIdentifier.equals(qr) &
                (_currentCavePlaceId != null
                    ? cp.uuid.equalsValue(_currentCavePlaceId!).not()
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
      final newUuid = Uuid.v7();
      await appDatabase
          .into(appDatabase.cavePlaces)
          .insert(
            CavePlacesCompanion.insert(
              uuid: newUuid,
              title: title,
              caveUuid: widget.caveUuid,
              description: description == null
                  ? const Value.absent()
                  : Value(description),
                depthInCave: Value(depth),
              placeQrCodeIdentifier: Value(qr),
              latitude: Value(lat),
              longitude: Value(long),
              caveAreaUuid: Value(_selectedCaveAreaId),
              isEntrance: Value(_isEntrance ? 1 : 0),
              isMainEntrance: Value(_isEntrance && _isMainEntrance ? 1 : 0),
            ),
          );

      if (!mounted) return newUuid;
      if (closeAfterSave) {
        Navigator.pop(context, true);
      } else {
        await _refreshCavePlaceState(newUuid);
      }
      return newUuid;
    } else {
      await (appDatabase.update(
        appDatabase.cavePlaces,
      )..where((cp) => cp.uuid.equalsValue(_currentCavePlaceId!))).write(
        CavePlacesCompanion(
          title: Value(title),
          description: description == null
              ? const Value.absent()
              : Value(description),
            depthInCave: Value(depth),
          placeQrCodeIdentifier: Value(qr),
          latitude: Value(lat),
          longitude: Value(long),
          caveAreaUuid: Value(_selectedCaveAreaId),
          isEntrance: Value(_isEntrance ? 1 : 0),
          isMainEntrance: Value(_isEntrance && _isMainEntrance ? 1 : 0),
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

  Future<void> _refreshCavePlaceState(Uuid cavePlaceUuid) async {
    final refreshed = await (appDatabase.select(
      appDatabase.cavePlaces,
    )..where((cp) => cp.uuid.equalsValue(cavePlaceUuid))).getSingleOrNull();

    if (!mounted || refreshed == null) return;
    setState(() {
      _currentCavePlaceId = cavePlaceUuid;
      _cavePlace = refreshed;
      _selectedCaveAreaId = refreshed.caveAreaUuid;
      _isEntrance = (refreshed.isEntrance ?? 0) == 1;
      _isMainEntrance = (refreshed.isMainEntrance ?? 0) == 1;
      _hasUnsavedChanges = false;
      _titleModified = false;
      _descriptionModified = false;
      _depthModified = false;
      _qrModified = false;
      _latModified = false;
      _longModified = false;
      _entranceModified = false;
      _mainEntranceModified = false;
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
    } else if (field == 'depth') {
      final orig = _formatDepthValue(_cavePlace?.depthInCave);
      _depthModified = _depthController.text != orig;
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

    setState(_recomputeUnsavedChanges);
  }

  void _recomputeUnsavedChanges() {
    _hasUnsavedChanges =
        _titleModified ||
        _descriptionModified ||
        _depthModified ||
        _qrModified ||
        _latModified ||
        _longModified ||
        _entranceModified ||
        _mainEntranceModified;
  }

  void _syncEntranceModifiedState() {
    final origEntrance = (_cavePlace?.isEntrance ?? 0) == 1;
    final origMainEntrance = (_cavePlace?.isMainEntrance ?? 0) == 1;
    _entranceModified = _isEntrance != origEntrance;
    _mainEntranceModified = _isMainEntrance != origMainEntrance;
    _recomputeUnsavedChanges();
  }

  Future<List<CavePlace>> _findOtherEntrancePlaces({required bool mainOnly}) async {
    final query = appDatabase.select(appDatabase.cavePlaces)
      ..where((cp) {
        final sameCave = cp.caveUuid.equalsValue(widget.caveUuid);
        final flag = mainOnly ? cp.isMainEntrance.equals(1) : cp.isEntrance.equals(1);
        final notCurrent = _currentCavePlaceId != null
            ? cp.uuid.equalsValue(_currentCavePlaceId!).not()
            : const Constant(true);
        return sameCave & flag & notCurrent;
      });
    return query.get();
  }

  Future<void> _onEntranceToggleRequested(bool enabled) async {
    if (enabled == _isEntrance) return;

    if (enabled) {
      final confirmEnable = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(LocServ.inst.t('confirm')),
          content: Text(LocServ.inst.t('confirm_mark_as_entrance')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(LocServ.inst.t('cancel'))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(LocServ.inst.t('yes'))),
          ],
        ),
      );
      if (confirmEnable != true) return;

      final otherEntrances = await _findOtherEntrancePlaces(mainOnly: false);
      if (otherEntrances.isNotEmpty && mounted) {
        final names = otherEntrances.map((e) => e.title).join(', ');
        final confirmContinue = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(LocServ.inst.t('other_entrances_defined_title')),
            content: Text(
              LocServ.inst.t('other_entrances_defined_body').replaceAll('{names}', names),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(LocServ.inst.t('cancel'))),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(LocServ.inst.t('yes'))),
            ],
          ),
        );
        if (confirmContinue != true) return;
      }

      setState(() {
        _isEntrance = true;
        _syncEntranceModifiedState();
      });
      return;
    }

    final confirmDisable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(LocServ.inst.t('confirm_unmark_as_entrance')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(LocServ.inst.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(LocServ.inst.t('yes'))),
        ],
      ),
    );
    if (confirmDisable != true) return;

    setState(() {
      _isEntrance = false;
      _isMainEntrance = false;
      _syncEntranceModifiedState();
    });
  }

  Future<void> _onMainEntranceToggleRequested(bool enabled) async {
    if (!_isEntrance || enabled == _isMainEntrance) return;

    if (enabled) {
      final confirmEnable = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(LocServ.inst.t('confirm')),
          content: Text(LocServ.inst.t('confirm_mark_as_main_entrance')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(LocServ.inst.t('cancel'))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(LocServ.inst.t('yes'))),
          ],
        ),
      );
      if (confirmEnable != true) return;

      final otherMainEntrances = await _findOtherEntrancePlaces(mainOnly: true);
      if (otherMainEntrances.isNotEmpty && mounted) {
        final names = otherMainEntrances.map((e) => e.title).join(', ');
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(LocServ.inst.t('main_entrance_already_defined_title')),
            content: Text(
              LocServ.inst.t('main_entrance_already_defined_body').replaceAll('{names}', names),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LocServ.inst.t('ok'))),
            ],
          ),
        );
        return;
      }

      setState(() {
        _isMainEntrance = true;
        _syncEntranceModifiedState();
      });
      return;
    }

    final confirmDisable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(LocServ.inst.t('confirm_unmark_as_main_entrance')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(LocServ.inst.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(LocServ.inst.t('yes'))),
        ],
      ),
    );
    if (confirmDisable != true) return;

    setState(() {
      _isMainEntrance = false;
      _syncEntranceModifiedState();
    });
  }

  String _formatDepthValue(double? value) => formatDepthValue(value);

  int _computeDescriptionLines(String text) => computeDescriptionLines(text);

  double? _parseDepthValue(String input) => parseDepthValue(input);

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
        query.where((cp) => cp.uuid.equalsValue(_currentCavePlaceId!).not());
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

  Widget _buildMapTab(RasterMap rm) {
    return CavePlaceMapTab(
      caveUuid: widget.caveUuid,
      cavePlaceUuid: _currentCavePlaceId,
      rasterMap: rm,
      useInteractiveEditor: USE_RASTER_EDITOR_IN_CAVEPLACE,
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
                TextFormField(
                  key: tourKeys['title_field'],
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
                // Description (expandable multiline)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: tourKeys['desc_field'],
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: LocServ.inst.t('description'),
                          filled: _descriptionModified,
                          fillColor: _descriptionModified
                              ? Colors.green.withValues(alpha: 0.06)
                              : null,
                        ),
                        minLines: 1,
                        maxLines: _descriptionLines,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.unfold_more, size: 18),
                      tooltip: LocServ.inst.t('expand_description'),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_descriptionLines < 5) {
                            _descriptionLines += 1;
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Cave area dropdown and manage areas button, depth
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        key: tourKeys['depth_field'],
                        controller: _depthController,
                        decoration: InputDecoration(
                          labelText: "Depth '+/-'",
                          filled: _depthModified,
                          fillColor: _depthModified
                              ? Colors.green.withValues(alpha: 0.06)
                              : null,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [depthInputFormatter],
                      ),
                    ),

                    const SizedBox(width: 28),

                    Expanded(
                      child: DropdownButtonFormField<Uuid?>(
                        initialValue: _selectedCaveAreaId,
                        decoration: InputDecoration(
                          labelText: LocServ.inst.t('area_title'),
                        ),
                        items: [
                          DropdownMenuItem<Uuid?>(
                            value: null,
                            child: Text(LocServ.inst.t('none')),
                          ),
                          ..._caveAreas.map(
                            (a) => DropdownMenuItem<Uuid?>(
                              value: a.uuid,
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
                                CaveAreasPage(caveUuid: widget.caveUuid),
                          ),
                        );
                        // reload areas after return
                        final areas =
                            await (appDatabase.select(appDatabase.caveAreas)
                                  ..where(
                                    (ca) => ca.caveUuid.equalsValue(widget.caveUuid),
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
                  key: tourKeys['qr_field'],
                  children: [
                    // QR code preview – only for existing places with a QR identifier.
                    if (_currentCavePlaceId != null &&
                        _cavePlace?.placeQrCodeIdentifier != null)
                      IconButton(
                        icon: const Icon(Icons.qr_code_2),
                        tooltip: LocServ.inst.t('view_qr_code'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: () {
                          CavePlaceQrPreviewDialog.show(context, _cavePlace!);
                        },
                      ),

                    IconButton(
                      icon: Icon(
                        _qrEditable ? Icons.lock_open : Icons.lock_outline,
                      ),
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
                          key: tourKeys['tabs'],
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

                const SizedBox(height: 4),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _isEntrance,
                  title: Text(LocServ.inst.t('is_cave_entrance')),
                  onChanged: (v) => _onEntranceToggleRequested(v ?? false),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _isMainEntrance,
                    title: Text(LocServ.inst.t('is_main_cave_entrance')),
                    onChanged: _isEntrance
                        ? (v) => _onMainEntranceToggleRequested(v ?? false)
                        : null,
                  ),
                ),
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
