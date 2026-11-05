import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

/// Asks before ending the trip recording at [caveTitle]. Every path that
/// ends a trip from a single tap — the trip page, the drawer, an entrance
/// scan — asks in these words, so the caver always reads what is at stake.
///
/// "Keep recording" is the filled button, on the right where the confirming
/// action usually sits, so a reflex tap keeps the trip; "End trip" is the
/// outlined red one. Both are 48 dp tall for gloved hands. True means end;
/// false or dismissing keeps the trip recording. [message] replaces the
/// general explanation when the caller knows why the question comes up.
Future<bool> showEndTripDialog(
  BuildContext context, {
  required String caveTitle,
  String? message,
}) async {
  final end = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final error = Theme.of(ctx).colorScheme.error;
      return AlertDialog(
        title: Text(
          caveTitle.isEmpty
              ? LocServ.inst.t('trip_end_dialog_title_no_cave')
              : LocServ.inst.t('trip_end_dialog_title', {'cave': caveTitle}),
        ),
        content: Text(message ?? LocServ.inst.t('trip_end_dialog_body')),
        actions: [
          OutlinedButton(
            key: const ValueKey('end_trip_confirm'),
            style: OutlinedButton.styleFrom(
              foregroundColor: error,
              side: BorderSide(color: error),
              minimumSize: const Size(48, 48),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('trip_end_dialog_end')),
          ),
          FilledButton(
            key: const ValueKey('end_trip_keep'),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('trip_end_dialog_keep')),
          ),
        ],
      );
    },
  );
  return end ?? false;
}
