import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

class CaveTripListPage extends StatefulWidget {
  const CaveTripListPage({super.key, required this.caveId});
  final int caveId;

  @override
  State<CaveTripListPage> createState() => _CaveTripListPageState();
}

class _CaveTripListPageState extends State<CaveTripListPage> with AppBarMenuMixin<CaveTripListPage> {
  List<CaveTrip> _trips = [];
  Map<int, int> _pointCounts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final trips = await appDatabase.getCaveTrips(widget.caveId);
    final ended = trips.where((t) => t.tripEndedAt != null).toList();
    Map<int, int> counts = {};
    for (final trip in ended) {
      final points = await appDatabase.getTripPoints(trip.id);
      counts[trip.id] = points.length;
    }
    if (mounted) setState(() {
      _trips = ended;
      _pointCounts = counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('trip_history')),
        actions: [buildAppBarMenuButton()],
      ),
      body: _trips.isEmpty
          ? Center(child: Text(LocServ.inst.t('trip_no_history'), style: TextStyle(color: Colors.grey[600])))
          : ListView.separated(
              itemCount: _trips.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final trip = _trips[i];
                final dt = DateTime.fromMillisecondsSinceEpoch(trip.tripStartedAt);
                final count = _pointCounts[trip.id] ?? 0;
                return ListTile(
                  title: Text(trip.title),
                  subtitle: Text(dateFormat.format(dt)),
                  trailing: Text('$count pts', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    await Navigator.pushNamed(context, caveTripRoute, arguments: trip.id);
                    _load();
                  },
                );
              },
            ),
    );
  }
}
