import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/services/trip_point_time_check.dart';
import 'package:speleoloc/utils/localization.dart';

/// Date + time picker for the moment a trip point was (or should have
/// been) scanned.
///
/// Times outside the trip window are accepted — see [checkTripPointTime] —
/// but are called out live under the fields so the user commits knowingly.
/// Resolves to the chosen [DateTime], or null on cancel.
class TripPointTimeDialog extends StatefulWidget {
  const TripPointTimeDialog({
    super.key,
    required this.initial,
    required this.tripStart,
    this.tripEnd,
  });

  final DateTime initial;
  final DateTime tripStart;
  final DateTime? tripEnd;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initial,
    required DateTime tripStart,
    DateTime? tripEnd,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (_) => TripPointTimeDialog(
        initial: initial,
        tripStart: tripStart,
        tripEnd: tripEnd,
      ),
    );
  }

  @override
  State<TripPointTimeDialog> createState() => _TripPointTimeDialogState();
}

class _TripPointTimeDialogState extends State<TripPointTimeDialog> {
  static final _dateFmt = DateFormat('yyyy/MM/dd');
  static final _timeFmt = DateFormat('HH:mm');
  static final _dateTimeFmt = DateFormat('yyyy/MM/dd HH:mm');

  late DateTime _value = widget.initial;

  /// The pickers must reach either side of the trip whatever the trip's own
  /// dates are: a forgotten stop can be back-dated, and a clock-skewed
  /// device can record one in the future.
  DateTime get _firstDate =>
      widget.tripStart.subtract(const Duration(days: 365));
  DateTime get _lastDate =>
      (widget.tripEnd ?? DateTime.now()).add(const Duration(days: 365));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _value,
      firstDate: _firstDate,
      lastDate: _lastDate,
    );
    if (picked == null) return;
    setState(() {
      _value = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _value.hour,
        _value.minute,
        _value.second,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_value),
    );
    if (picked == null) return;
    setState(() {
      // Seconds are dropped: the picker has no second field, and keeping the
      // original ones would silently reintroduce a value the user can't see.
      _value = DateTime(
        _value.year,
        _value.month,
        _value.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  String? get _warning {
    switch (checkTripPointTime(
      at: _value,
      tripStart: widget.tripStart,
      tripEnd: widget.tripEnd,
    )) {
      case TripPointTimeIssue.beforeTripStart:
        return LocServ.inst.t('trip_point_warn_before_start', {
          'time': _dateTimeFmt.format(widget.tripStart),
        });
      case TripPointTimeIssue.afterTripEnd:
        return LocServ.inst.t('trip_point_warn_after_end', {
          'time': _dateTimeFmt.format(widget.tripEnd!),
        });
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final warning = _warning;
    return AlertDialog(
      title: Text(LocServ.inst.t('trip_point_time_dialog_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(LocServ.inst.t('trip_point_date')),
            subtitle: Text(_dateFmt.format(_value)),
            onTap: _pickDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(LocServ.inst.t('trip_point_time')),
            subtitle: Text(_timeFmt.format(_value)),
            onTap: _pickTime,
          ),
          if (warning != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    warning,
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocServ.inst.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _value),
          child: Text(LocServ.inst.t('ok')),
        ),
      ],
    );
  }
}
