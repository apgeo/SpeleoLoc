import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/localization.dart';

/// Asks before restarting [trip]. Restarting rewrites the trip's start to
/// now and clears its end, and that rewrite syncs to other devices, so the
/// question shows the times about to be lost. True means restart.
Future<bool> showTripRestartDialog(BuildContext context, CaveTrip trip) async {
  final format = DateFormat('yyyy/MM/dd HH:mm');
  String at(int? ms) =>
      ms == null ? '…' : format.format(DateTime.fromMillisecondsSinceEpoch(ms));
  final restart = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(LocServ.inst.t('trip_restart_confirm_title')),
      content: Text(
        LocServ.inst.t('trip_restart_confirm_body', {
          'start': at(trip.tripStartedAt),
          'end': at(trip.tripEndedAt),
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(LocServ.inst.t('cancel')),
        ),
        TextButton(
          key: const ValueKey('trip_restart_confirm'),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(LocServ.inst.t('trip_restart_confirm_action')),
        ),
      ],
    ),
  );
  return restart ?? false;
}
