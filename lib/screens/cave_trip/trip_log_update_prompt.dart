import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/trip_log_update.dart';
import 'package:speleoloc/utils/app_routes.dart';
import 'package:speleoloc/utils/localization.dart';

/// Decides, before a change to a trip's points, what the change does to the
/// trip's log — asking the user only when the answer would cost them text.
///
/// With regenerating off, the log is kept and marked out of date; nothing is
/// lost, so nothing is asked. With it on, a log that renders the same as its
/// points is regenerated silently; one that holds anything else — typed by
/// hand, or from changes it fell behind — gets a question first, because
/// regenerating would replace that.
class TripLogUpdatePrompt {
  const TripLogUpdatePrompt._();

  /// The update to pass to the edit, or null when the user cancelled — in
  /// which case the edit must not happen either.
  static Future<TripLogUpdate?> decide(
    BuildContext context,
    WidgetRef ref,
    Uuid tripUuid,
  ) async {
    final service = ref.read(caveTripServiceProvider);
    if (!await service.regeneratesLogOnEdit()) return TripLogUpdate.markStale;
    if (!await service.regenerationWouldChangeLog(tripUuid)) {
      return TripLogUpdate.regenerate;
    }
    if (!context.mounted) return null;
    return showDialog<TripLogUpdate>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('trip_log_overwrite_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocServ.inst.t('trip_log_overwrite_body')),
              const SizedBox(height: 8),
              // The setting this dialog exists because of, one tap away —
              // the dialog stays open underneath and is answered on return.
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(LocServ.inst.t('trip_log_settings_link')),
                onPressed: () => AppRoutes.pushTripLogSettings(ctx),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, TripLogUpdate.markStale),
            child: Text(LocServ.inst.t('trip_log_keep_as_written')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, TripLogUpdate.regenerate),
            child: Text(LocServ.inst.t('trip_log_regenerate')),
          ),
        ],
      ),
    );
  }
}
