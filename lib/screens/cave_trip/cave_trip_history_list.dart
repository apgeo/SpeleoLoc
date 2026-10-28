import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_trip_origin_service.dart';
import 'package:speleoloc/utils/localization.dart';

/// The ended trips of a cave, with another phone's recordings — read from an
/// installation — kept out of the way: hidden by default, counted, and shown
/// with a badge once the caver turns them on.
class CaveTripHistoryList extends StatefulWidget {
  const CaveTripHistoryList({
    required this.trips,
    required this.pointCounts,
    required this.onOpen,
    this.received,
    this.emptyText = '',
    super.key,
  });

  final List<CaveTrip> trips;
  final Map<Uuid, int> pointCounts;
  final ValueChanged<CaveTrip> onOpen;

  /// The recordings that came from an installation, or null when none did.
  final SilexgisReceivedTrips? received;

  /// What to say when no trip is listed.
  final String emptyText;

  @override
  State<CaveTripHistoryList> createState() => _CaveTripHistoryListState();
}

class _CaveTripHistoryListState extends State<CaveTripHistoryList> {
  static final _dateFormat = DateFormat('yyyy/MM/dd HH:mm');

  bool _showReceived = false;

  @override
  Widget build(BuildContext context) {
    final received = widget.received;
    bool isReceived(CaveTrip trip) => received?.contains(trip.uuid) ?? false;
    final receivedCount = widget.trips.where(isReceived).length;
    final visible = _showReceived
        ? widget.trips
        : widget.trips.where((t) => !isReceived(t)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (received != null && receivedCount > 0)
          SwitchListTile(
            dense: true,
            secondary: const Icon(Icons.cloud_download_outlined),
            title: Text(
              LocServ.inst.t('trip_installation_show', <String, String>{
                'installation': received.installation,
              }),
            ),
            subtitle: _showReceived
                ? null
                : Text(
                    LocServ.inst.t('trip_installation_hidden', <String, String>{
                      'count': '$receivedCount',
                      'installation': received.installation,
                    }),
                  ),
            value: _showReceived,
            onChanged: (value) => setState(() => _showReceived = value),
          ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    widget.emptyText,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final trip = visible[i];
                    final count = widget.pointCounts[trip.uuid] ?? 0;
                    return ListTile(
                      title: Text(trip.title),
                      subtitle: Text(
                        _dateFormat.format(
                          DateTime.fromMillisecondsSinceEpoch(
                            trip.tripStartedAt,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (isReceived(trip))
                            _InstallationBadge(
                              installation: received!.installation,
                            ),
                          Text(
                            '$count pts',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => widget.onOpen(trip),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Marks a recording another phone made, read from [installation].
class _InstallationBadge extends StatelessWidget {
  const _InstallationBadge({required this.installation});

  final String installation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: LocServ.inst.t('trip_from_installation', <String, String>{
        'installation': installation,
      }),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(
          Icons.cloud_download_outlined,
          size: 18,
          color: scheme.secondary,
          semanticLabel: LocServ.inst.t(
            'trip_from_installation',
            <String, String>{'installation': installation},
          ),
        ),
      ),
    );
  }
}
