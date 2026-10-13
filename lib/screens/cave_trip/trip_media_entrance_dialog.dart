import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/trip_media/trip_media_entrance_plan.dart';
import 'package:speleoloc/utils/localization.dart';

/// What the user agreed to when the import's entrance markers clashed with
/// what the trip already recorded.
class TripMediaEntranceDecision {
  const TripMediaEntranceDecision({
    this.deletePointUuids = const [],
    this.newTripStart,
    this.newTripEnd,
  });

  final List<Uuid> deletePointUuids;
  final DateTime? newTripStart;
  final DateTime? newTripEnd;
}

/// Asks about each thing an entrance photo contradicts: the entrance points
/// already on the trip, and the trip's own start and end.
///
/// Everything starts switched off. These are edits to records the caver
/// already made, so each one is something they turn on deliberately rather
/// than something that happens because a dialog went by — and leaving the
/// whole dialog untouched is the "just add the points" answer.
class TripMediaEntranceDialog extends StatefulWidget {
  const TripMediaEntranceDialog({
    super.key,
    required this.plan,
    required this.tripStart,
    required this.tripEnd,
    required this.placeTitles,
  });

  final TripMediaEntrancePlan plan;
  final DateTime tripStart;
  final DateTime? tripEnd;

  /// Place title per uuid, so a superseded point is named rather than shown
  /// as an identifier.
  final Map<Uuid, String> placeTitles;

  static Future<TripMediaEntranceDecision?> show(
    BuildContext context, {
    required TripMediaEntrancePlan plan,
    required DateTime tripStart,
    required DateTime? tripEnd,
    required Map<Uuid, String> placeTitles,
  }) {
    return showDialog<TripMediaEntranceDecision>(
      context: context,
      builder: (_) => TripMediaEntranceDialog(
        plan: plan,
        tripStart: tripStart,
        tripEnd: tripEnd,
        placeTitles: placeTitles,
      ),
    );
  }

  @override
  State<TripMediaEntranceDialog> createState() =>
      _TripMediaEntranceDialogState();
}

class _TripMediaEntranceDialogState extends State<TripMediaEntranceDialog> {
  static final _fmt = DateFormat('yyyy/MM/dd HH:mm');

  final Set<Uuid> _toDelete = {};
  bool _moveStart = false;
  bool _moveEnd = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return AlertDialog(
      title: Text(LocServ.inst.t('trip_media_entrance_title')),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocServ.inst.t('trip_media_entrance_body'),
                style: const TextStyle(fontSize: 13),
              ),
              if (plan.supersededPoints.isNotEmpty) ...[
                const Divider(height: 20),
                Text(
                  LocServ.inst.t('trip_media_entrance_existing'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final point in plan.supersededPoints)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _toDelete.contains(point.uuid),
                    title: Text(
                      widget.placeTitles[point.cavePlaceUuid] ??
                          LocServ.inst.t('trip_media_no_place'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      _fmt.format(
                        DateTime.fromMillisecondsSinceEpoch(point.scannedAt),
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _toDelete.add(point.uuid);
                      } else {
                        _toDelete.remove(point.uuid);
                      }
                    }),
                  ),
              ],
              if (plan.proposedTripStart != null) ...[
                const Divider(height: 20),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _moveStart,
                  title: Text(
                    LocServ.inst.t('trip_media_entrance_move_start'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    '${_fmt.format(widget.tripStart)} → '
                    '${_fmt.format(plan.proposedTripStart!)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onChanged: (v) => setState(() => _moveStart = v),
                ),
              ],
              if (plan.proposedTripEnd != null && widget.tripEnd != null) ...[
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _moveEnd,
                  title: Text(
                    LocServ.inst.t('trip_media_entrance_move_end'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    '${_fmt.format(widget.tripEnd!)} → '
                    '${_fmt.format(plan.proposedTripEnd!)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onChanged: (v) => setState(() => _moveEnd = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocServ.inst.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            TripMediaEntranceDecision(
              deletePointUuids: _toDelete.toList(),
              newTripStart: _moveStart ? widget.plan.proposedTripStart : null,
              newTripEnd: _moveEnd ? widget.plan.proposedTripEnd : null,
            ),
          ),
          child: Text(LocServ.inst.t('ok')),
        ),
      ],
    );
  }
}
