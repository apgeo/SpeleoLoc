import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/services/trip_point_time_check.dart';
import 'package:speleoloc/utils/localization.dart';

/// The start and end a trip was edited to.
typedef TripWindow = ({DateTime start, DateTime? end});

/// Edits when a trip started and, for one that has ended, when it ended —
/// mostly for entering an old trip after the fact, where the recorded
/// times are the moment it was typed in rather than the moment it happened.
///
/// A live trip offers only its start: its end is set by stopping it, which
/// also releases it as the active trip. An end before the start is refused;
/// recorded points that would fall outside the new times are allowed but
/// counted, so the user sees what the change does to them.
class TripWindowDialog extends StatefulWidget {
  const TripWindowDialog({
    super.key,
    required this.start,
    required this.end,
    required this.pointTimes,
  });

  final DateTime start;

  /// Null for a trip that has not ended.
  final DateTime? end;

  /// When each recorded point was scanned.
  final List<DateTime> pointTimes;

  static Future<TripWindow?> show(
    BuildContext context, {
    required DateTime start,
    required DateTime? end,
    required List<DateTime> pointTimes,
  }) {
    return showDialog<TripWindow>(
      context: context,
      builder: (_) =>
          TripWindowDialog(start: start, end: end, pointTimes: pointTimes),
    );
  }

  @override
  State<TripWindowDialog> createState() => _TripWindowDialogState();
}

class _TripWindowDialogState extends State<TripWindowDialog> {
  static final _dateFmt = DateFormat('yyyy/MM/dd');
  static final _timeFmt = DateFormat('HH:mm');

  late DateTime _start = widget.start;
  late DateTime? _end = widget.end;

  bool get _inverted => _end != null && _end!.isBefore(_start);

  int get _pointsOutside => widget.pointTimes
      .where(
        (t) =>
            checkTripPointTime(at: t, tripStart: _start, tripEnd: _end) != null,
      )
      .length;

  Future<DateTime?> _pick(DateTime value) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      // Old trips are the point of this dialog, so the range reaches far
      // back; an end can legitimately be today.
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Widget _row({
    required String label,
    required IconData icon,
    required DateTime value,
    required ValueChanged<DateTime> onPicked,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text('${_dateFmt.format(value)}  ${_timeFmt.format(value)}'),
      trailing: const Icon(Icons.edit_calendar_outlined),
      onTap: () async {
        final picked = await _pick(value);
        if (picked != null && mounted) setState(() => onPicked(picked));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final outside = _pointsOutside;
    final warn = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: Text(LocServ.inst.t('trip_window_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row(
              label: LocServ.inst.t('trip_started'),
              icon: Icons.play_circle_outline,
              value: _start,
              onPicked: (v) => _start = v,
            ),
            if (_end != null)
              _row(
                label: LocServ.inst.t('trip_ended'),
                icon: Icons.stop_circle_outlined,
                value: _end!,
                onPicked: (v) => _end = v,
              )
            else
              Text(
                LocServ.inst.t('trip_window_live'),
                style: const TextStyle(fontSize: 12),
              ),
            if (_inverted) ...[
              const SizedBox(height: 8),
              Text(
                LocServ.inst.t('trip_window_inverted'),
                style: TextStyle(fontSize: 12, color: warn),
              ),
            ] else if (outside > 0) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      LocServ.inst.t('trip_window_points_outside', {
                        'n': '$outside',
                      }),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocServ.inst.t('cancel')),
        ),
        TextButton(
          onPressed: _inverted
              ? null
              : () => Navigator.pop<TripWindow>(context, (
                  start: _start,
                  end: _end,
                )),
          child: Text(LocServ.inst.t('ok')),
        ),
      ],
    );
  }
}
