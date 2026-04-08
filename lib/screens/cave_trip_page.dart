import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

class CaveTripPage extends StatefulWidget {
  const CaveTripPage({super.key, required this.tripId});
  final int tripId;

  @override
  State<CaveTripPage> createState() => _CaveTripPageState();
}

class _CaveTripPageState extends State<CaveTripPage> with AppBarMenuMixin<CaveTripPage> {
  CaveTrip? _trip;
  Cave? _cave;
  List<CaveTripPoint> _points = [];
  Map<int, CavePlace> _placesById = {};

  bool get _isActive => _trip?.tripEndedAt == null;

  @override
  List<AppMenuItem> get screenMenuItems => [
    AppMenuItem(
      value: 'delete_trip',
      icon: Icons.delete,
      label: LocServ.inst.t('trip_delete'),
    ),
  ];

  @override
  void onScreenMenuItemSelected(String value) async {
    if (value == 'delete_trip') {
      await _deleteTrip();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
    caveTripService.activeTripIdNotifier.addListener(_onTripStateChanged);
    caveTripService.isPausedNotifier.addListener(_onTripStateChanged);
  }

  @override
  void dispose() {
    caveTripService.activeTripIdNotifier.removeListener(_onTripStateChanged);
    caveTripService.isPausedNotifier.removeListener(_onTripStateChanged);
    super.dispose();
  }

  void _onTripStateChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    final trip = await (appDatabase.select(appDatabase.caveTrips)
          ..where((t) => t.id.equals(widget.tripId)))
        .getSingleOrNull();
    if (trip == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final cave = await (appDatabase.select(appDatabase.caves)
          ..where((c) => c.id.equals(trip.caveId)))
        .getSingleOrNull();
    final points = await appDatabase.getTripPoints(widget.tripId);
    final placeIds = points.map((p) => p.cavePlaceId).toSet().toList();
    Map<int, CavePlace> placesById = {};
    if (placeIds.isNotEmpty) {
      final places = await (appDatabase.select(appDatabase.cavePlaces)
            ..where((cp) => cp.id.isIn(placeIds)))
          .get();
      placesById = {for (var p in places) p.id: p};
    }
    if (mounted) {
      setState(() {
        _trip = trip;
        _cave = cave;
        _points = points;
        _placesById = placesById;
      });
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
        _load();
      }
    }
  }

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(LocServ.inst.t('trip_delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(LocServ.inst.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(LocServ.inst.t('yes'))),
        ],
      ),
    );
    if (confirmed == true) {
      if (_isActive) await caveTripService.stopTrip();
      await appDatabase.deleteCaveTrip(widget.tripId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocServ.inst.t('trip_deleted'))));
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _restartTrip() async {
    final trip = _trip;
    if (trip == null) return;
    final dateStr = DateFormat('yyyy/MM/dd').format(DateTime.now());
    final defaultTitle = '${trip.title.replaceAll(RegExp(r' \d{4}/\d{2}/\d{2}$'), '')} $dateStr';
    final controller = TextEditingController(text: defaultTitle);
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(LocServ.inst.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(LocServ.inst.t('ok'))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final newTitle = controller.text.trim().isNotEmpty ? controller.text.trim() : defaultTitle;
      final newTripId = await caveTripService.startTrip(trip.caveId, newTitle);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocServ.inst.t('trip_restarted'))),
        );
        Navigator.pushReplacementNamed(context, caveTripRoute, arguments: newTripId);
      }
    }
  }

  String _formatDuration(int startMs, int? endMs) {
    final end = endMs != null ? DateTime.fromMillisecondsSinceEpoch(endMs) : DateTime.now();
    final start = DateTime.fromMillisecondsSinceEpoch(startMs);
    final d = end.difference(start);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  Widget _buildActionToolbar() {
    final isPaused = caveTripService.isPausedNotifier.value;
    final buttons = <_TripToolbarButton>[];

    if (_isActive) {
      buttons.add(_TripToolbarButton(
        icon: Icons.stop_circle,
        label: LocServ.inst.t('trip_stop'),
        color: Colors.red,
        onTap: _stopTrip,
      ));
      if (isPaused) {
        buttons.add(_TripToolbarButton(
          icon: Icons.play_circle,
          label: LocServ.inst.t('trip_resume'),
          color: Colors.green,
          onTap: () { caveTripService.resumeTrip(); setState(() {}); },
        ));
      } else {
        buttons.add(_TripToolbarButton(
          icon: Icons.pause_circle,
          label: LocServ.inst.t('trip_pause'),
          color: Colors.orange,
          onTap: () { caveTripService.pauseTrip(); setState(() {}); },
        ));
      }
    } else {
      buttons.add(_TripToolbarButton(
        icon: Icons.replay,
        label: LocServ.inst.t('trip_restart'),
        color: Colors.blue,
        onTap: _restartTrip,
      ));
    }

    buttons.add(_TripToolbarButton(
      icon: Icons.article_outlined,
      label: LocServ.inst.t('trip_log'),
      color: Colors.grey[700]!,
      onTap: () => Navigator.pushNamed(context, caveTripLogRoute, arguments: widget.tripId),
    ));

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons.map((b) => _buildTripButton(b)).toList(),
      ),
    );
  }

  Widget _buildTripButton(_TripToolbarButton btn) {
    return InkWell(
      onTap: btn.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(btn.icon, size: 36, color: btn.color),
            const SizedBox(height: 4),
            Text(btn.label, style: TextStyle(fontSize: 11, color: btn.color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    if (trip == null) {
      return Scaffold(
        key: appMenuScaffoldKey,
        appBar: AppBar(title: Text(LocServ.inst.t('trip_active'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isPaused = caveTripService.isPausedNotifier.value;
    final dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm');
    final startDt = DateTime.fromMillisecondsSinceEpoch(trip.tripStartedAt);
    final endDt = trip.tripEndedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(trip.tripEndedAt!)
        : null;

    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(trip.title),
        actions: [buildAppBarMenuButton()],
      ),
      body: Column(
        children: [
          _buildActionToolbar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_cave != null)
                          Row(children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Text(_cave!.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ]),
                        const SizedBox(height: 4),
                        Text('${LocServ.inst.t('trip_started')}: ${dateTimeFormat.format(startDt)}'),
                        if (endDt != null)
                          Text('${LocServ.inst.t('trip_ended')}: ${dateTimeFormat.format(endDt)}'),
                        Text('${LocServ.inst.t('trip_duration')}: ${_formatDuration(trip.tripStartedAt, trip.tripEndedAt)}'),
                        Text('${LocServ.inst.t('trip_points')}: ${_points.length}'),
                        if (_isActive) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPaused
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPaused ? Icons.pause_circle : Icons.fiber_manual_record,
                                      color: isPaused ? Colors.orange : Colors.green,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isPaused
                                          ? LocServ.inst.t('trip_paused')
                                          : LocServ.inst.t('trip_active'),
                                      style: TextStyle(
                                        color: isPaused ? Colors.orange : Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_points.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(LocServ.inst.t('trip_no_points'), style: TextStyle(color: Colors.grey[600])),
                  ))
                else
                  ...List.generate(_points.length, (i) {
                    final pt = _points[i];
                    final place = _placesById[pt.cavePlaceId];
                    final dt = DateTime.fromMillisecondsSinceEpoch(pt.scannedAt);
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                      ),
                      title: Text(place?.title ?? '#${pt.cavePlaceId}'),
                      subtitle: Text(dateTimeFormat.format(dt)),
                      trailing: place?.depthInCave != null
                          ? Text(
                              '${place!.depthInCave! > 0 ? '+' : ''}${place.depthInCave}m',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            )
                          : null,
                      onTap: place == null
                          ? null
                          : () => Navigator.pushNamed(context, cavePlaceRoute,
                              arguments: {'caveId': place.caveId, 'cavePlaceId': place.id}),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripToolbarButton {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TripToolbarButton({required this.icon, required this.label, required this.color, required this.onTap});
}
