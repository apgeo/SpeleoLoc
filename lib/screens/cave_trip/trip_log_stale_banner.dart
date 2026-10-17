import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/utils/app_routes.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Says that a trip's log has fallen behind its recorded points, and offers
/// what to do about it: regenerate it (after a warning that hand-typed text
/// is replaced), keep it as written, or change the setting that left it
/// behind. Shown on the trip screen and on the log page alike.
class TripLogStaleBanner extends ConsumerWidget {
  const TripLogStaleBanner({
    super.key,
    required this.trip,
    required this.onRegenerated,
    required this.onKept,
  });

  /// Shown only while [CaveTrip.logStaleSince] is set.
  final CaveTrip trip;

  /// The log text changed: anything showing it should reload it.
  final VoidCallback onRegenerated;

  /// Only the out-of-date mark went: the text is as it was, so a page
  /// holding unsaved edits to it must not reload it.
  final VoidCallback onKept;

  static final _dateFmt = DateFormat('yyyy/MM/dd HH:mm');

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('trip_log_regenerate_confirm_title')),
        content: Text(LocServ.inst.t('trip_log_regenerate_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('trip_log_regenerate')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(caveTripServiceProvider).regenerateLog(trip.uuid);
    SnackBarService.showSuccess(LocServ.inst.t('trip_log_regenerated'));
    onRegenerated();
  }

  Future<void> _keep(WidgetRef ref) async {
    await ref.read(caveTripServiceProvider).keepLogAsWritten(trip.uuid);
    SnackBarService.showInfo(LocServ.inst.t('trip_log_kept'));
    onKept();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final since = trip.logStaleSince;
    if (since == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.history_toggle_off,
                  color: scheme.onTertiaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocServ.inst.t('trip_log_stale_title'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LocServ.inst.t('trip_log_stale_body', {
                          'date': _dateFmt.format(
                            DateTime.fromMillisecondsSinceEpoch(since),
                          ),
                        }),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // A Wrap so the three actions drop to a second line on a narrow
            // phone or at a large font instead of overflowing.
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(LocServ.inst.t('trip_log_settings_link')),
                  onPressed: () => AppRoutes.pushTripLogSettings(context),
                ),
                TextButton(
                  onPressed: () => unawaited(_keep(ref)),
                  child: Text(LocServ.inst.t('trip_log_keep_as_written')),
                ),
                FilledButton.tonal(
                  onPressed: () => unawaited(_regenerate(context, ref)),
                  child: Text(LocServ.inst.t('trip_log_regenerate')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
