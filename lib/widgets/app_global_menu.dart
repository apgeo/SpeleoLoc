import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/scanner_page.dart';
import 'package:speleoloc/screens/settings/settings_main_page.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/screens/general_data/documentation_files_page.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:url_launcher/url_launcher.dart';

/// Configuration key for the persisted menu mode preference.
const String _menuModeConfigKey = 'app_menu_mode';

/// A menu item descriptor used by the global menu system.
class AppMenuItem {
  final String? value;
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final Color? color;

  const AppMenuItem({
    this.value,
    required this.icon,
    this.label,
    this.onTap,
    this.color,
  });
}

/// Defines how the app menu is presented.
enum AppMenuMode { popup, drawer }

/// Global notifier so all screens share the same menu mode.
final ValueNotifier<AppMenuMode> _menuModeNotifier =
    ValueNotifier(AppMenuMode.drawer);

/// Cached app version string, populated at startup.
String _appVersion = '';

/// Call once at app startup to load the persisted menu mode.
Future<void> initAppMenuMode() async {
  final stored = await SettingsHelper.loadStringConfig(_menuModeConfigKey, 'drawer');
  _menuModeNotifier.value =
      stored == 'popup' ? AppMenuMode.popup : AppMenuMode.drawer;
  try {
    final info = await PackageInfo.fromPlatform();
    _appVersion = 'v${info.version}+${info.buildNumber}';
  } catch (_) {
    _appVersion = '';
  }
}

/// Mixin that adds a unified app menu (popup or end-drawer) to any screen
/// with an [AppBar].
///
/// Usage:
/// ```dart
/// class _MyPageState extends State<MyPage> with AppBarMenuMixin<MyPage> {
///   @override
///   List<AppMenuItem> get screenMenuItems => [ ... ];
///
///   @override
///   void onScreenMenuItemSelected(String value) { ... }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       key: appMenuScaffoldKey,
///       endDrawer: buildAppMenuEndDrawer(),
///       appBar: AppBar(
///         actions: [
///           ...otherActions,
///           buildAppBarMenuButton(),
///         ],
///       ),
///     );
///   }
/// }
/// ```
mixin AppBarMenuMixin<T extends StatefulWidget> on State<T> {
  /// Override to provide screen-specific menu items.
  List<AppMenuItem> get screenMenuItems => const [];

  /// Override to handle selection of screen-specific popup-menu items.
  void onScreenMenuItemSelected(String value) {}

  /// GlobalKey for the Scaffold. Screens must set `key: appMenuScaffoldKey`.
  final GlobalKey<ScaffoldState> appMenuScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _menuModeNotifier.addListener(_onMenuModeChanged);
  }

  @override
  void dispose() {
    _menuModeNotifier.removeListener(_onMenuModeChanged);
    super.dispose();
  }

  void _onMenuModeChanged() {
    if (mounted) setState(() {});
  }

  /// Builds the menu trigger button for the AppBar actions list.
  Widget buildAppBarMenuButton() {
    if (_menuModeNotifier.value == AppMenuMode.popup) {
      return _buildPopupMenuButton();
    }
    return IconButton(
      icon: const Icon(Icons.more_vert),
      tooltip: LocServ.inst.t('more'),
      onPressed: () => appMenuScaffoldKey.currentState?.openEndDrawer(),
    );
  }

  /// Builds the end-drawer widget. Assign to [Scaffold.endDrawer].
  Widget buildAppMenuEndDrawer() {
    return _AppMenuDrawer(
      screenItems: screenMenuItems,
      onScreenItemTap: (item) {
        Navigator.pop(context); // close drawer
        if (item.onTap != null) {
          item.onTap!();
        } else if (item.value != null) {
          onScreenMenuItemSelected(item.value!);
        }
      },
      onHelpPressed: this is ProductTourMixin
          ? () {
              Navigator.pop(context); // close drawer
              (this as ProductTourMixin).startScreenTour();
            }
          : null,
    );
  }

  Widget _buildPopupMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: LocServ.inst.t('more'),
      onSelected: (value) {
        if (value == '_toggle_menu_mode') {
          _setMenuMode(AppMenuMode.drawer);
          return;
        }
        if (value == '_help') {
          if (this is ProductTourMixin) {
            (this as ProductTourMixin).startScreenTour();
          }
          return;
        }
        if (_handleGlobalMenuSelection(value)) return;
        onScreenMenuItemSelected(value);
      },
      itemBuilder: (_) {
        final items = <PopupMenuEntry<String>>[];

        // Screen-specific items
        for (final item in screenMenuItems) {
          items.add(PopupMenuItem<String>(
            value: item.value,
            child: Row(
              children: [
                Icon(item.icon, size: 20),
                if (item.label != null) ...[
                  const SizedBox(width: 8),
                  Text(item.label!),
                ],
              ],
            ),
          ));
        }

        if (screenMenuItems.isNotEmpty) {
          items.add(const PopupMenuDivider());
        }

        // Global navigation items — icon-only row
        items.add(_GlobalNavRow());

        // Help tour
        if (this is ProductTourMixin) {
          items.add(const PopupMenuDivider());
          items.add(PopupMenuItem<String>(
            value: '_help',
            child: Row(
              children: [
                const Icon(Icons.help_outline, size: 20),
                const SizedBox(width: 8),
                Text(LocServ.inst.t('help_tour')),
              ],
            ),
          ));
        }

        // Mode toggle
        items.add(const PopupMenuDivider());
        items.add(PopupMenuItem<String>(
          value: '_toggle_menu_mode',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_open, size: 20),
            ],
          ),
        ));

        return items;
      },
    );
  }

  bool _handleGlobalMenuSelection(String value) {
    switch (value) {
      case '_nav_caves':
        Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
        return true;
      case '_nav_scan':
        _navigateToScanner();
        return true;
      case '_nav_documents':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DocumentationFilesPage()));
        return true;
      case '_nav_settings':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SettingsMainPage()));
        return true;
      default:
        return false;
    }
  }

  void _navigateToScanner() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;

    if (status.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScannerPage(
            onScan: (code) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${LocServ.inst.t('scan_result')}: $code')),
                );
                Navigator.pop(context, code);
              }
            },
          ),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(LocServ.inst.t('permission_required')),
          content: Text(LocServ.inst.t('camera_permission_required')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(LocServ.inst.t('cancel')),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(ctx).pop();
              },
              child: Text(LocServ.inst.t('open_settings')),
            ),
          ],
        ),
      );
    }
  }

  static void _setMenuMode(AppMenuMode mode) {
    _menuModeNotifier.value = mode;
    SettingsHelper.saveStringConfig(
        _menuModeConfigKey, mode == AppMenuMode.popup ? 'popup' : 'drawer');
  }
}

/// Custom popup entry that renders global navigation as a row of icon buttons.
class _GlobalNavRow extends PopupMenuEntry<String> {
  @override
  final double height = 170;

  @override
  bool represents(String? value) => false;

  @override
  State<_GlobalNavRow> createState() => _GlobalNavRowState();
}

class _GlobalNavRowState extends State<_GlobalNavRow> {
  void _go(String value) {
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 8,
        runSpacing: 8,
        children: [
          _navIconWithLabel(Icons.home, LocServ.inst.t('caves'), () => _go('_nav_caves')),
          _navIconWithLabel(Icons.qr_code_scanner, LocServ.inst.t('scan'), () => _go('_nav_scan')),
          _navIconWithLabel(Icons.description, LocServ.inst.t('documentation'), () => _go('_nav_documents')),
          _navIconWithLabel(Icons.settings, LocServ.inst.t('settings'), () => _go('_nav_settings')),
        ],
      ),
    );
  }

  Widget _navIconWithLabel(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: 88,
      child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
      ),
    );
  }
}

/// The sliding drawer that shows screen-specific and global menu items.
class _AppMenuDrawer extends StatelessWidget {
  final List<AppMenuItem> screenItems;
  final void Function(AppMenuItem) onScreenItemTap;
  final VoidCallback? onHelpPressed;

  const _AppMenuDrawer({
    required this.screenItems,
    required this.onScreenItemTap,
    this.onHelpPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 220,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // Screen-specific items
            if (screenItems.isNotEmpty) ...[
              ...screenItems.map((item) => ListTile(
                    leading: Icon(item.icon),
                    title: item.label != null ? Text(item.label!) : null,
                    dense: true,
                    onTap: () => onScreenItemTap(item),
                    iconColor: item.color
                  )),
              const Divider(),
            ],
            // Global navigation items with labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _navIconWithLabel(context, Icons.home, LocServ.inst.t('caves'), () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                        context, homeRoute, (route) => false);
                  }),
                  _navIconWithLabel(context, Icons.qr_code_scanner, LocServ.inst.t('scan'), () {
                    Navigator.pop(context);
                    _openScanner(context);
                  }),
                  _navIconWithLabel(context, Icons.description, LocServ.inst.t('documentation'), () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const DocumentationFilesPage()));
                  }),
                  _navIconWithLabel(context, Icons.settings, LocServ.inst.t('settings'), () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsMainPage()));
                  }),
                ],
              ),
            ),
            const Spacer(),
            ValueListenableBuilder<int?>(
              valueListenable: caveTripService.activeTripIdNotifier,
              builder: (context, tripId, _) {
                if (tripId == null) return const SizedBox.shrink();
                return _ActiveTripCard(tripId: tripId, onClose: () => Navigator.pop(context));
              },
            ),
            // Help tour + Mode toggle icon + version label at bottom
            const Divider(),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (onHelpPressed != null)
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        tooltip: LocServ.inst.t('help_tour'),
                        onPressed: onHelpPressed,
                      ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      tooltip: LocServ.inst.t('about'),
                      onPressed: () => _showAboutDialog(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      tooltip: LocServ.inst.t('menu_use_popup'),
                      onPressed: () {
                        Navigator.pop(context);
                        AppBarMenuMixin._setMenuMode(AppMenuMode.popup);
                      },
                    ),
                  ],
                ),
                if (_appVersion.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      _appVersion,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _navIconWithLabel(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: 88,
      child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('about')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('A project by '),
                GestureDetector(
                  onTap: () => launchUrl(
                    Uri.parse('https://speosilex.ro'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text(
                    'SpeoSilex',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse('https://github.com/apgeo/SpeleoLoc'),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text(
                'SpeoLoc on GitHub',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openScanner(BuildContext context) async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!context.mounted) return;

    if (status.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScannerPage(
            onScan: (code) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${LocServ.inst.t('scan_result')}: $code')),
                );
                Navigator.pop(context, code);
              }
            },
          ),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(LocServ.inst.t('permission_required')),
          content: Text(LocServ.inst.t('camera_permission_required')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(LocServ.inst.t('cancel')),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(ctx).pop();
              },
              child: Text(LocServ.inst.t('open_settings')),
            ),
          ],
        ),
      );
    }
  }
}

class _ActiveTripCard extends StatefulWidget {
  final int tripId;
  final VoidCallback onClose;
  const _ActiveTripCard({required this.tripId, required this.onClose});

  @override
  State<_ActiveTripCard> createState() => _ActiveTripCardState();
}

class _ActiveTripCardState extends State<_ActiveTripCard> {
  CaveTrip? _trip;
  Cave? _cave;
  List<CaveTripPoint> _points = [];
  Map<int, CavePlace> _placesById = {};
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _load();
    caveTripService.isPausedNotifier.addListener(_onPauseChanged);
  }

  void _onPauseChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    caveTripService.isPausedNotifier.removeListener(_onPauseChanged);
    super.dispose();
  }

  Future<void> _load() async {
    final trip = await (appDatabase.select(appDatabase.caveTrips)
          ..where((t) => t.id.equals(widget.tripId)))
        .getSingleOrNull();
    if (trip == null) return;
    final cave = await (appDatabase.select(appDatabase.caves)
          ..where((c) => c.id.equals(trip.caveId)))
        .getSingleOrNull();
    final points = await appDatabase.getTripPoints(widget.tripId);
    final last5 = points.reversed.take(5).toList().reversed.toList();
    final placeIds = last5
      .map((p) => p.cavePlaceId)
      .whereType<int>()
      .toSet()
      .toList();
    Map<int, CavePlace> placesById = {};
    if (placeIds.isNotEmpty) {
      final places = await (appDatabase.select(appDatabase.cavePlaces)
            ..where((cp) => cp.id.isIn(placeIds)))
          .get();
      placesById = {for (var p in places) p.id: p};
    }
    if (mounted) setState(() {
      _trip = trip;
      _cave = cave;
      _points = last5;
      _placesById = placesById;
      _totalPoints = points.length;
    });
  }

  String _formatDuration(int startMs) {
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(startMs));
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    if (trip == null) return const SizedBox.shrink();
    final isPaused = caveTripService.isPausedNotifier.value;
    final dateTimeFormat = DateFormat('HH:mm');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isPaused
          ? Colors.orange.withValues(alpha: 0.08)
          : Colors.green.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          widget.onClose();
          Navigator.pushNamed(context, caveTripRoute, arguments: trip.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(children: [
              Icon(
                isPaused ? Icons.pause_circle : Icons.fiber_manual_record,
                color: isPaused ? Colors.orange : Colors.green,
                size: 10,
              ),
              const SizedBox(width: 4),
              Expanded(child: Text(trip.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              if (isPaused)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.pause_circle, size: 10, color: Colors.orange),
                ),
            ]),
            if (_cave != null)
              Text(_cave!.title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            Text('${_formatDuration(trip.tripStartedAt)} · $_totalPoints pts', style: const TextStyle(fontSize: 10)),
            if (_points.isNotEmpty) ...[
              const Divider(height: 8),
              ..._points.map((pt) {
                final place = _placesById[pt.cavePlaceId];
                final time = dateTimeFormat.format(DateTime.fromMillisecondsSinceEpoch(pt.scannedAt));
                return Text('$time ${place?.title ?? '#${pt.cavePlaceId}'}',
                    style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis);
              }),
              if (_totalPoints > _points.length)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+${_totalPoints - _points.length} cps',
                    style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                  ),
                ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.route, size: 28),
                  padding: EdgeInsets.zero,
                  color: Colors.blue,
                  constraints: const BoxConstraints(),
                  tooltip: LocServ.inst.t('trip_view'),
                  onPressed: () {
                    widget.onClose();
                    Navigator.pushNamed(context, caveTripRoute, arguments: trip.id);
                  },
                ),
                IconButton(
                  icon: Icon(
                    isPaused ? Icons.play_circle : Icons.pause_circle,
                    size: 28,
                    color: isPaused ? Colors.green : Colors.orange,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: isPaused ? LocServ.inst.t('trip_resume') : LocServ.inst.t('trip_pause'),
                  onPressed: () {
                    if (isPaused) {
                      caveTripService.resumeTrip();
                    } else {
                      caveTripService.pauseTrip();
                    }
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.stop, size: 28, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: LocServ.inst.t('trip_stop'),
                  onPressed: () async {
                    widget.onClose();
                    await caveTripService.stopTrip();
                  },
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
