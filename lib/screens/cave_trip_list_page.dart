import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

class CaveTripListPage extends StatefulWidget {
  const CaveTripListPage({super.key, required this.caveUuid});
  final Uuid caveUuid;

  @override
  State<CaveTripListPage> createState() => _CaveTripListPageState();
}

class _CaveTripListPageState extends State<CaveTripListPage> with AppBarMenuMixin<CaveTripListPage>, ProductTourMixin<CaveTripListPage> {
  @override
  String get tourId => 'cave_trip_list';
  @override
  final tourKeys = TourKeySet(['toolbar', 'list', 'menu']);
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'toolbar', titleLocKey: 'tour_cave_trip_list_toolbar_title', bodyLocKey: 'tour_cave_trip_list_toolbar_body'),
    TourStepDef(keyId: 'list', titleLocKey: 'tour_cave_trip_list_list_title', bodyLocKey: 'tour_cave_trip_list_list_body', align: ContentAlign.top),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_cave_trip_list_menu_title', bodyLocKey: 'tour_cave_trip_list_menu_body'),
  ];
  Cave? _cave;
  List<CaveTrip> _endedTrips = [];
  Map<Uuid, int> _pointCounts = {};

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
    final cave = await (appDatabase.select(appDatabase.caves)
          ..where((c) => c.uuid.equalsValue(widget.caveUuid)))
        .getSingleOrNull();
    final allTrips = await appDatabase.getCaveTrips(widget.caveUuid);
    final ended = allTrips.where((t) => t.tripEndedAt != null).toList();
    Map<Uuid, int> counts = {};
    for (final trip in ended) {
      final points = await appDatabase.getTripPoints(trip.uuid);
      counts[trip.uuid] = points.length;
    }
    if (mounted) {
      setState(() {
        _cave = cave;
        _endedTrips = ended;
        _pointCounts = counts;
      });
    }
  }

  Future<void> _startTrip() async {
    final caveName = _cave?.title ?? '';
    final dateStr = DateFormat('yyyy/MM/dd').format(DateTime.now());
    final defaultTitle = '$caveName $dateStr';
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(LocServ.inst.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(LocServ.inst.t('ok'))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final title = controller.text.trim().isNotEmpty ? controller.text.trim() : suggestedTitle;
      await caveTripService.startTrip(widget.caveUuid, title);
      if (mounted) {
        _load();
      }
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

  Widget _buildToolbar() {
    final activeTripId = caveTripService.activeTripIdNotifier.value;
    final isPaused = caveTripService.isPausedNotifier.value;
    final isActiveForThisCave = activeTripId != null;

    final buttons = <_ToolbarBtn>[];

    if (!isActiveForThisCave) {
      buttons.add(_ToolbarBtn(
        icon: Icons.play_circle,
        label: LocServ.inst.t('trip_start'),
        color: Colors.green,
        onTap: _startTrip,
      ));
    } else {
      buttons.add(_ToolbarBtn(
        icon: Icons.stop_circle,
        label: LocServ.inst.t('trip_stop'),
        color: Colors.red,
        onTap: _stopTrip,
      ));
      if (isPaused) {
        buttons.add(_ToolbarBtn(
          icon: Icons.play_circle,
          label: LocServ.inst.t('trip_resume'),
          color: Colors.green,
          onTap: () { caveTripService.resumeTrip(); setState(() {}); },
        ));
      } else {
        buttons.add(_ToolbarBtn(
          icon: Icons.pause_circle,
          label: LocServ.inst.t('trip_pause'),
          color: Colors.orange,
          onTap: () { caveTripService.pauseTrip(); setState(() {}); },
        ));
      }
      buttons.add(_ToolbarBtn(
        icon: Icons.route,
        label: LocServ.inst.t('trip_view'),
        color: Colors.blue,
        onTap: () async {
          await Navigator.pushNamed(context, caveTripRoute, arguments: activeTripId);
          _load();
        },
      ));
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons.map((b) {
          return InkWell(
            onTap: b.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(b.icon, size: 40, color: b.color),
                  const SizedBox(height: 4),
                  Text(b.label, style: TextStyle(fontSize: 12, color: b.color, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveTripCard(Uuid tripId) {
    return FutureBuilder<CaveTrip?>(
      future: (appDatabase.select(appDatabase.caveTrips)..where((t) => t.uuid.equalsValue(tripId))).getSingleOrNull(),
      builder: (context, snap) {
        final trip = snap.data;
        if (trip == null) return const SizedBox.shrink();
        final isPaused = caveTripService.isPausedNotifier.value;
        final pts = _pointCounts[trip.uuid] ?? 0;
        return Card(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          color: isPaused
              ? Colors.orange.withValues(alpha: 0.08)
              : Colors.green.withValues(alpha: 0.08),
          child: ListTile(
            leading: Icon(
              isPaused ? Icons.pause_circle : Icons.fiber_manual_record,
              color: isPaused ? Colors.orange : Colors.green,
            ),
            title: Text(trip.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isPaused
                ? LocServ.inst.t('trip_paused')
                : '${LocServ.inst.t('trip_active')} · $pts ${LocServ.inst.t('trip_points')}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.pushNamed(context, caveTripRoute, arguments: tripId);
              _load();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTripId = caveTripService.activeTripIdNotifier.value;
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('trip_history')),
        actions: [KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton())],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyedSubtree(key: tourKeys['toolbar'], child: _buildToolbar()),
          if (activeTripId != null) _buildActiveTripCard(activeTripId),
          if (_endedTrips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                LocServ.inst.t('trip_history'),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          Expanded(
            key: tourKeys['list'],
            child: _endedTrips.isEmpty
                ? Center(child: Text(
                    activeTripId != null ? '' : LocServ.inst.t('trip_no_history'),
                    style: TextStyle(color: Colors.grey[600]),
                  ))
                : ListView.separated(
                    itemCount: _endedTrips.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final trip = _endedTrips[i];
                      final dt = DateTime.fromMillisecondsSinceEpoch(trip.tripStartedAt);
                      final count = _pointCounts[trip.uuid] ?? 0;
                      return ListTile(
                        title: Text(trip.title),
                        subtitle: Text(dateFormat.format(dt)),
                        trailing: Text('$count pts', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        onTap: () async {
                          await Navigator.pushNamed(context, caveTripRoute, arguments: trip.uuid);
                          _load();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarBtn {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ToolbarBtn({required this.icon, required this.label, required this.color, required this.onTap});
}
