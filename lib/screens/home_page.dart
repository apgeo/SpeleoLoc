import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/scanner_page.dart';
import 'package:speleoloc/screens/add_new_cave.dart';
import 'package:speleoloc/screens/general_data/surface_areas_page.dart';
import 'package:speleoloc/screens/settings/settings_main_page.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/screens/settings/sync_dashboard_page.dart';
import 'package:speleoloc/screens/settings/ftp_sync_progress_page.dart';
import 'package:speleoloc/screens/general_data/documentation_files_page.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_start_counter.dart';
import 'package:speleoloc/services/qr_code_lookup_service.dart';
import 'package:speleoloc/widgets/qr_code_lookup_handler.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/database_restore_helper.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/icon_action_button.dart';
import 'package:speleoloc/widgets/filterable_list.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/screens/csv_cave_place_import_page.dart';
import 'package:speleoloc/screens/csv_caves_import_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AppBarMenuMixin<HomePage>, ProductTourMixin<HomePage> {
  static const bool _pinTopControls = true;
  @override
  String get tourId => 'home';
  @override
  final tourKeys = TourKeySet(['scan_qr', 'add_cave', 'docs', 'cave_list', 'menu']);
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'scan_qr', titleLocKey: 'tour_home_scan_qr_title', bodyLocKey: 'tour_home_scan_qr_body'),
    TourStepDef(keyId: 'add_cave', titleLocKey: 'tour_home_add_cave_title', bodyLocKey: 'tour_home_add_cave_body'),
    TourStepDef(keyId: 'docs', titleLocKey: 'tour_home_docs_title', bodyLocKey: 'tour_home_docs_body'),
    TourStepDef(keyId: 'cave_list', titleLocKey: 'tour_home_cave_list_title', bodyLocKey: 'tour_home_cave_list_body', align: ContentAlign.top),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_home_menu_title', bodyLocKey: 'tour_home_menu_body'),
  ];
  @override
  List<AppMenuItem> get screenMenuItems => [
    AppMenuItem(
      value: 'add_cave',
      icon: Icons.add,
      label: LocServ.inst.t('add_new_cave'),
    ),
    AppMenuItem(
      value: 'documents',
      icon: Icons.description,
      label: LocServ.inst.t('documentation'),
    ),
    AppMenuItem(
      value: 'surface_areas',
      icon: Icons.landscape,
      label: LocServ.inst.t('manage_surface_areas'),
    ),
    AppMenuItem(
      value: 'csv_import_caves',
      icon: Icons.upload_file,
      label: LocServ.inst.t('csv_import_caves'),
    ),
  ];

  @override
  void onScreenMenuItemSelected(String value) async {
    switch (value) {
      case 'add_cave':
        _addNewCave();
        break;
      case 'documents':
        await _openDocumentationFiles();
        break;
      case 'surface_areas':
        final result = await Navigator.push<bool?>(
          context,
          MaterialPageRoute(builder: (_) => const SurfaceAreasPage()),
        );
        if (result == true) _loadCaves();
        break;
      case 'csv_import':
        final result = await Navigator.push<bool?>(
          context,
          MaterialPageRoute(builder: (_) => const CSVCavePlacesImportPage()),
        );
        if (result == true) _loadCaves();
        break;
      case 'csv_import_caves':
        final result = await Navigator.push<bool?>(
          context,
          MaterialPageRoute(builder: (_) => const CSVCavesImportPage()),
        );
        if (result == true) _loadCaves();
        break;
    }
  }
  // Using global appDatabase instance
  List<Cave> _caves = [];
  Map<Uuid, int> _cavePlaceCounts = {};
  Map<Uuid, int> _caveRasterMapCounts = {};
  Map<Uuid, String?> _surfaceAreaTitles = {}; // surface_area_id -> title
  bool _showMainToolbar = false;

  bool _testDataPromptShown = false;
  Completer<void>? _testDataPromptCompleter;

  // --- Long-press QR manual input (enabled by [enableQrManualInput]) ---
  Timer? _qrScanLongPressTimer;
  final TextEditingController _manualQrController = TextEditingController();

  void _startQrScanLongPress() {
    _qrScanLongPressTimer?.cancel();
    _qrScanLongPressTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) _showManualQrInputDialog();
    });
  }

  void _cancelQrScanLongPress() {
    _qrScanLongPressTimer?.cancel();
    _qrScanLongPressTimer = null;
  }

  int _titleTapCount = 0;
  DateTime _lastTitleTap = DateTime(0);

  void _onTitleTap() {
    final now = DateTime.now();
    if (now.difference(_lastTitleTap).inSeconds > 3) {
      _titleTapCount = 0;
    }
    _lastTitleTap = now;
    _titleTapCount++;
    if (_titleTapCount >= 9) {
      _titleTapCount = 0;
      final newValue = !debugModeNotifier.value;
      debugModeNotifier.value = newValue;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue
              ? 'Debug mode activated'
              : 'Debug mode deactivated'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Subscription to Drift's live cave stream — replaces manual post-mutation
  // _loadCaves() calls. Derived data (counts, surface area titles) is still
  // pulled imperatively on each emission.
  StreamSubscription<List<Cave>>? _cavesSub;

  @override
  void initState() {
    super.initState();
    homePageRefreshNotifier.addListener(_onHomePageRefreshRequested);
    _loadUiSettings();
    _cavesSub = caveRepository.watchCaves().listen((_) {
      if (!mounted) return;
      _loadCaves();
    });
  }

  @override
  void dispose() {
    _qrScanLongPressTimer?.cancel();
    _manualQrController.dispose();
    _cavesSub?.cancel();
    homePageRefreshNotifier.removeListener(_onHomePageRefreshRequested);
    super.dispose();
  }

  void _onHomePageRefreshRequested() {
    if (!mounted) return;
    // Full refresh path used after destructive operations (e.g. DB restore)
    // where the underlying sqlite file was swapped and stream subscriptions
    // on the previous connection no longer emit.
    _loadUiSettings();
    _loadCaves();
    setState(() {});
  }

  Future<void> _loadUiSettings() async {
    final showToolbar = await SettingsHelper.loadStringConfig(
      showHomeToolbarKey,
      'false',
    );
    if (!mounted) return;
    setState(() {
      _showMainToolbar = showToolbar == 'true';
    });
  }

  Future<void> _toggleMainToolbar() async {
    final newValue = !_showMainToolbar;
    setState(() => _showMainToolbar = newValue);
    await SettingsHelper.saveStringConfig(showHomeToolbarKey, newValue.toString());
  }

  @override
  Future<void> beforeAutoTour() async {
    if (_testDataPromptCompleter != null) await _testDataPromptCompleter!.future;
  }

  Future<void> _loadCaves() async {
    try {
      _caves = await caveRepository.getCaves();
      // compute place counts
      final allPlaces = await (appDatabase.select(appDatabase.cavePlaces)).get();
      _cavePlaceCounts = {};
      for (var p in allPlaces) {
        _cavePlaceCounts[p.caveUuid] = (_cavePlaceCounts[p.caveUuid] ?? 0) + 1;
      }
      // compute raster map counts
      final allRasterMaps = await (appDatabase.select(appDatabase.rasterMaps)).get();
      _caveRasterMapCounts = {};
      for (var rm in allRasterMaps) {
        _caveRasterMapCounts[rm.caveUuid] = (_caveRasterMapCounts[rm.caveUuid] ?? 0) + 1;
      }

      // load surface area titles for display on the cave list
      final areas = await (appDatabase.select(appDatabase.surfaceAreas)).get();
      _surfaceAreaTitles = {for (var a in areas) a.uuid: a.title};

      if (!mounted) return;
      setState(() {});

      // On the first 4 starts, if no caves exist, offer to populate test data.
      if (!_testDataPromptShown &&
          _caves.isEmpty &&
          AppStartCounter.count <= 4) {
        _testDataPromptShown = true;
        _testDataPromptCompleter = Completer<void>();
        _offerTestDataPopulation().whenComplete(() {
          _testDataPromptCompleter?.complete();
          _testDataPromptCompleter = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${LocServ.inst.t('error_loading_caves')}: $e')),
      );
      rethrow;
    }
  }

  Future<void> _offerTestDataPopulation() async {
    if (!mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('populate_test_data_title')),
        content: Text(LocServ.inst.t('populate_test_data_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocServ.inst.t('no')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocServ.inst.t('yes')),
          ),
        ],
      ),
    );
    if (accepted == true) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(LocServ.inst.t('loading_test_data')),
            ],
          ),
        ),
      );
      try {
        await DatabaseRestoreHelper.reinitializeDatabase(
            populateTestData: true);
        if (mounted) Navigator.pop(context);
        await DatabaseRestoreHelper.restartApplication();
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${LocServ.inst.t('error_reinitializing_database')}: $e')),
          );
        }
      }
    }
  }

  void _addNewCave() async {
    // Open AddNewCave screen to let user enter title and area
    try {
      final result = await Navigator.push<Uuid?>(
        context,
        MaterialPageRoute(builder: (_) => const CaveFormPage()),
      );
      if (result != null) {
        // Stream subscription refreshes the list; just show the snackbar.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocServ.inst.t('new_cave_added'))));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${LocServ.inst.t('error_adding_cave')}: $e')));
      }
    }
  }

  Future<void> _openDocumentationFiles() async {
    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => const DocumentationFilesPage()),
    );
    if (result == true) _loadCaves();
  }

  Future<void> _openSettings() async {
    await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsMainPage()),
    );
    await _loadUiSettings();
    _loadCaves();
    if (mounted) setState(() {});
  }

  void _deleteCave(Uuid caveUuid) async {
    try {
      await caveRepository.deleteCave(caveUuid);
      // Stream subscription auto-refreshes _caves.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocServ.inst.t('cave_deleted'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${LocServ.inst.t('error_deleting_cave')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: GestureDetector(
          onTap: _onTitleTap,
          child: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        actions: [
          if (!_showMainToolbar)
            Listener(
              onPointerDown: enableQrManualInput ? (_) => _startQrScanLongPress() : null,
              onPointerUp: enableQrManualInput ? (_) => _cancelQrScanLongPress() : null,
              onPointerCancel: enableQrManualInput ? (_) => _cancelQrScanLongPress() : null,
              child: IconButton(
                key: tourKeys['scan_qr'],
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: LocServ.inst.t('scan_qr'),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                onPressed: _scanAndLookupQr,
              ),
            ),
          if (!_showMainToolbar)
            IconButton(
              key: tourKeys['add_cave'],
              icon: const Icon(Icons.add),
              tooltip: LocServ.inst.t('add_new_cave'),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
              onPressed: _addNewCave,
            ),
          if (!_showMainToolbar)
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: LocServ.inst.t('sync_dashboard_title'),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SyncDashboardPage()),
                );
              },
            ),
          if (!_showMainToolbar)
            Consumer(
              builder: (context, ref, _) => IconButton(
                icon: const Icon(Icons.cloud_sync),
                tooltip: LocServ.inst.t('ftp_sync_title'),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  unawaited(
                    ref.read(ftpSyncControllerProvider).startDefault(),
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FtpSyncProgressPage()));
                },
              ),
            ),
          // if (!_showMainToolbar)
          //   IconButton(
          //     key: tourKeys['docs'],
          //     icon: const Icon(Icons.description),
          //     tooltip: LocServ.inst.t('documentation'),
          //     onPressed: _openDocumentationFiles,
          //   ),
          // if (!_showMainToolbar)
          //   IconButton(
          //     icon: const Icon(Icons.settings),
          //     tooltip: LocServ.inst.t('settings'),
          //     onPressed: _openSettings,
          //   ),
          KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
        ],
      ),
      body: _pinTopControls
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showMainToolbar) _buildMainToolbar(),
                if (_showMainToolbar) const SizedBox(height: 6),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildCaveList(),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_showMainToolbar) _buildMainToolbar(),
                    if (_showMainToolbar) const SizedBox(height: 10),
                    SizedBox(
                      height: 600,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildCaveList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  Future<void> _showManualQrInputDialog() async {
    _manualQrController.clear();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('manual_qr_search')),
        content: TextField(
          controller: _manualQrController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: LocServ.inst.t('qr_code_identifier'),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocServ.inst.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _manualQrController.text.trim()),
            child: Text(LocServ.inst.t('search_place_by_qr_code_by_identifier')),
          ),
        ],
      ),
    );
    if (confirmed != null && confirmed.isNotEmpty && mounted) {
      final handler = QrCodeLookupHandler(QrCodeLookupService(appDatabase));
      final result = await handler.handleScannedCode(context, confirmed);
      if (result != null) _loadCaves();
    }
  }

  Future<void> _scanAndLookupQr() async {
    final status = await Permission.camera.status;
    PermissionStatus resultStatus = status;
    if (!status.isGranted) {
      resultStatus = await Permission.camera.request();
    }
    if (!mounted) return;

    if (resultStatus.isGranted) {
      String? scannedCode;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScannerPage(onScan: (code) {
            scannedCode = code;
          }),
        ),
      );
      if (scannedCode != null && mounted) {
        final handler = QrCodeLookupHandler(QrCodeLookupService(appDatabase));
        final result = await handler.handleScannedCode(context, scannedCode!);
        if (result != null) _loadCaves();
      }
    } else if (resultStatus.isPermanentlyDenied) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(LocServ.inst.t('permission_required')),
            content: Text(LocServ.inst.t('camera_permission_required')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(LocServ.inst.t('cancel')),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
                child: Text(LocServ.inst.t('open_settings')),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocServ.inst.t('camera_permission_denied'))),
        );
      }
    }
  }

  Future<dynamic> _navigateToCavePage(BuildContext context, Cave cave) async {
    final result = await Navigator.pushNamed(context, caveRoute, arguments: cave.uuid);
    // Always refresh cave list summary after returning: cave places/areas/maps/definitions may have changed.
    _loadCaves();
    return result;
  }

  Widget _buildMainToolbar() {
    final buttons = <_HomeToolbarBtn>[
      _HomeToolbarBtn(
        icon: Icons.qr_code_scanner,
        tooltip: LocServ.inst.t('scan_qr'),
        onTap: _scanAndLookupQr,
      ),
      _HomeToolbarBtn(
        icon: Icons.add_circle,
        tooltip: LocServ.inst.t('add_new_cave'),
        onTap: _addNewCave,
      ),
      _HomeToolbarBtn(
        icon: Icons.description,
        tooltip: LocServ.inst.t('documentation'),
        onTap: _openDocumentationFiles,
      ),
      _HomeToolbarBtn(
        icon: Icons.settings,
        tooltip: LocServ.inst.t('settings'),
        onTap: _openSettings,
      ),
    ];

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      // color: Theme.of(context).colorScheme.surfaceContainerHighest, 
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(buttons.length, (i) {
            final b = buttons[i];
            Widget btn = Padding(
              padding: EdgeInsets.only(right: i == buttons.length - 1 ? 0 : 3),
              child: IconButton(
                icon: Icon(
                  b.icon,
                  size: 28,
                  color: Colors.blue[400],
                ),
                tooltip: b.tooltip,
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: b.onTap,
              ),
            );
            if (i == 0 && enableQrManualInput) {
              btn = Listener(
                onPointerDown: (_) => _startQrScanLongPress(),
                onPointerUp: (_) => _cancelQrScanLongPress(),
                onPointerCancel: (_) => _cancelQrScanLongPress(),
                child: btn,
              );
            }
            return btn;
          }),
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: IconButton(
                icon: Icon(Icons.sync, size: 28, color: Colors.blue[400]),
                tooltip: LocServ.inst.t('sync_dashboard_title'),
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncDashboardPage())),
              ),
            ),
            Consumer(
              builder: (context, ref, _) => Padding(
                padding: const EdgeInsets.only(left: 3),
                child: IconButton(
                  icon: Icon(Icons.cloud_sync, size: 28, color: Colors.blue[400]),
                  tooltip: LocServ.inst.t('ftp_sync_title'),
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () {
                    unawaited(ref.read(ftpSyncControllerProvider).startDefault());
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FtpSyncProgressPage()));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaveList() {
    return FilterableList<Cave>(
      headerKey: tourKeys['cave_list'],
      headerLabelText: '${LocServ.inst.t('caves')}:',
      headerTrailing: [IconButton(icon: Icon(_showMainToolbar ? Icons.view_day : Icons.view_day_outlined), tooltip: LocServ.inst.t(_showMainToolbar ? 'hide_docs_toolbar' : 'show_docs_toolbar'), visualDensity: VisualDensity.compact, onPressed: _toggleMainToolbar,),],
      enableSelection: false,
      items: _caves,
      keyOf: (c) => c.uuid,
      enableBulkDelete: showCaveDeleteButtons,
      onBulkDelete: showCaveDeleteButtons
          ? (selected) async {
              for (final c in selected) {
                await caveRepository.deleteCave(c.uuid);
              }
            }
          : null,
      searchableText: (cave) {
        final area = cave.surfaceAreaUuid != null
            ? (_surfaceAreaTitles[cave.surfaceAreaUuid] ?? '')
            : '';
        return '${cave.title} $area';
      },
      onItemTap: (cave) => _navigateToCavePage(context, cave),
      itemBuilder: (context, cave, _) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cave.title, style: const TextStyle(fontSize: 16)),
                  if (cave.surfaceAreaUuid != null &&
                      _surfaceAreaTitles[cave.surfaceAreaUuid] != null)
                    Text(
                      _surfaceAreaTitles[cave.surfaceAreaUuid]!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text('${_cavePlaceCounts[cave.uuid] ?? 0}'),
            ),
            const SizedBox(width: 8),
            Icon(Icons.map, size: 16, color: Colors.grey[600]),
            Padding(
              padding: const EdgeInsets.only(left: 4.0, right: 8.0),
              child: Text('${_caveRasterMapCounts[cave.uuid] ?? 0}'),
            ),
            if (showCaveDeleteButtons)
              IconActionButton(
                onPressed: () => _deleteCave(cave.uuid),
                icon: Icons.delete,
                tooltip: LocServ.inst.t('delete_cave'),
              ),
          ],
        );
      },
    );
  }
}

class _HomeToolbarBtn {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HomeToolbarBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
}
