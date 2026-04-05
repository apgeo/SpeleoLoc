import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/scanner_page.dart';
import 'package:speleoloc/screens/add_new_cave.dart';
import 'package:speleoloc/screens/general_data/surface_areas_page.dart';
import 'package:speleoloc/screens/settings/settings_main_page.dart';
import 'package:speleoloc/screens/general_data/documentation_files_page.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/app_start_counter.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/database_restore_helper.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/icon_action_button.dart';
import 'package:speleoloc/screens/csv_cave_place_import_page.dart';

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

class _HomePageState extends State<HomePage> {
  // Using global appDatabase instance
  List<Cave> _caves = [];
  Map<int, int> _cavePlaceCounts = {};
  Map<int, int> _caveRasterMapCounts = {};
  Map<int, String?> _surfaceAreaTitles = {}; // surface_area_id -> title
  bool showActionButtons = false;

  bool _testDataPromptShown = false;

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

  @override
  void initState() {
    super.initState();
    _loadCaves();
  }

  Future<void> _loadCaves() async {
    try {
      _caves = await caveRepository.getCaves();
      // compute place counts
      final allPlaces = await (appDatabase.select(appDatabase.cavePlaces)).get();
      _cavePlaceCounts = {};
      for (var p in allPlaces) {
        _cavePlaceCounts[p.caveId] = (_cavePlaceCounts[p.caveId] ?? 0) + 1;
      }
      // compute raster map counts
      final allRasterMaps = await (appDatabase.select(appDatabase.rasterMaps)).get();
      _caveRasterMapCounts = {};
      for (var rm in allRasterMaps) {
        _caveRasterMapCounts[rm.caveId] = (_caveRasterMapCounts[rm.caveId] ?? 0) + 1;
      }

      // load surface area titles for display on the cave list
      final areas = await (appDatabase.select(appDatabase.surfaceAreas)).get();
      _surfaceAreaTitles = {for (var a in areas) a.id: a.title};

      if (!mounted) return;
      setState(() {});

      // On the first 4 starts, if no caves exist, offer to populate test data.
      if (!_testDataPromptShown &&
          _caves.isEmpty &&
          AppStartCounter.count <= 4) {
        _testDataPromptShown = true;
        _offerTestDataPopulation();
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

  Future<void> _openScannerWithPermission() async {
    final status = await Permission.camera.status;
    PermissionStatus resultStatus = status;
    if (!status.isGranted) {
      resultStatus = await Permission.camera.request();
    }

    if (!mounted) return;

    if (resultStatus.isGranted) {
      await Navigator.push<String?>(
        context,
        MaterialPageRoute(builder: (_) => ScannerPage(onScan: (code) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${LocServ.inst.t('scan_result')}: $code')),
            );
            Navigator.pop(context, code);
          }
        })),
      );
    } else if (resultStatus.isPermanentlyDenied) {
      // Permission permanently denied, open app settings
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

  void _addNewCave() async {
    // Open AddNewCave screen to let user enter title and area
    try {
      final result = await Navigator.push<int?>(
        context,
        MaterialPageRoute(builder: (_) => const AddNewCave()),
      );
      if (result != null) {
        _loadCaves();
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

  void _deleteCave(int caveId) async {
    try {
      await caveRepository.deleteCave(caveId);
      _loadCaves();
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
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: GestureDetector(
          onTap: _onTitleTap,
          child: Text(widget.title),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: LocServ.inst.t('add_new_cave'),
            onPressed: _addNewCave,
          ),
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: LocServ.inst.t('documentation'),
            onPressed: () async {
              final result = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(builder: (_) => const DocumentationFilesPage()),
              );
              if (result == true) _loadCaves();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(builder: (_) => const SettingsMainPage()),
              );
              if (result == true || true) {
                print('[HomePage] _loadCaves triggered after returning from SettingsMainPage');
                _loadCaves();
                if (mounted) setState(() {});
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: LocServ.inst.t('more'),
            onSelected: (value) async {
              switch (value) {
                case 'surface_areas':
                  final result = await Navigator.push<bool?>(
                    context,
                    MaterialPageRoute(builder: (_) => const SurfaceAreasPage()),
                  );
                  if (result == true) {
                    print('[HomePage] _loadCaves triggered after returning from SurfaceAreasPage');
                    _loadCaves();
                  }
                  break;
                case 'csv_import':
                  final result = await Navigator.push<bool?>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CSVCavePlaceImportPage(),
                    ),
                  );
                  if (result == true) {
                    _loadCaves();
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'surface_areas',
                child: ListTile(
                  leading: const Icon(Icons.landscape),
                  title: Text(LocServ.inst.t('manage_surface_areas')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'csv_import',
                child: ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: Text(LocServ.inst.t('csv_import_places')),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // const Text('You have pushed the button this many times:'),
              // Text(
              //   '$_counter',
              //   style: Theme.of(context).textTheme.headlineMedium,
              // ),
              // const SizedBox(height: 20),
              // const Text('Adjust counter with slider:'),
              // Slider(
              //   value: _counter.toDouble(),
              //   min: -10,
              //   max: 10,
              //   divisions: 20,
              //   label: _counter.toString(),
              //   onChanged: _updateCounterWithSlider,
              // ),
              // const SizedBox(height: 10),
              if (showActionButtons)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openScannerWithPermission,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(LocServ.inst.t('scan_qr')),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _addNewCave,
                      icon: const Icon(Icons.add),
                      label: Text(LocServ.inst.t('add_new_cave')),
                    ),
                  ],
                ),
              if (showActionButtons) const SizedBox(height: 10),
               Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28.0),
                          child: 
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('${LocServ.inst.t('caves')}:', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            )
              ),
              ..._caves.map((cave) => Column(
                children: [
                  ListTile(
                    title: Text(cave.title),
                    subtitle: cave.surfaceAreaId != null && _surfaceAreaTitles[cave.surfaceAreaId] != null
                        ? Text(_surfaceAreaTitles[cave.surfaceAreaId]!, style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                        : null,
                    onTap: () => _navigateToCavePage(context, cave),
                    hoverColor: Colors.grey[200],
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // cavePlaceCounts with GPS icon
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text('${_cavePlaceCounts[cave.id] ?? 0}'),
                        ),
                        const SizedBox(width: 8),
                        // Raster maps count with map icon
                        Icon(Icons.map, size: 16, color: Colors.grey[600]),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, right: 8.0),
                          child: Text('${_caveRasterMapCounts[cave.id] ?? 0}'),
                        ),
                        if (showCaveDeleteButtons)
                          IconActionButton(
                            onPressed: () => _deleteCave(cave.id),
                            icon: Icons.delete,
                            tooltip: LocServ.inst.t('delete_cave'),
                          ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                ],
              )),
              // reload caves when returning from cave page
              // Update navigation helper below to refresh on result
              if (_caves.length > 3) const Padding(padding: EdgeInsets.only(top: 10), child: Icon(Icons.arrow_downward, size: 20, color: Colors.grey)),
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

  Future<dynamic> _navigateToCavePage(BuildContext context, Cave cave) async {
    final result = await Navigator.pushNamed(context, caveRoute, arguments: cave.id);
    if (result == true) {
      _loadCaves();
    }
    return result;
  }
}
