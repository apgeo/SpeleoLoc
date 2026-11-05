import 'dart:async';

import 'package:speleoloc/services/cave_trip_service.dart';
import 'package:speleoloc/services/trip_record_outcome.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Tells the caver what a scan or detection did to the trip: a green
/// confirmation only when a point was recorded, and an amber warning with
/// a Resume button when a pause dropped it — a paused trip must never look
/// like a recording one. [lead] is said first when the caller has its own
/// news, such as which place a beacon found; [outcome] is null when no trip
/// point was attempted at all.
void showTripRecordFeedback(
  CaveTripService trips,
  TripRecordOutcome? outcome, {
  String? lead,
}) {
  String join(String? tripPart) =>
      [lead, tripPart].whereType<String>().join(' · ');

  switch (outcome) {
    case TripRecordOutcome.recorded:
      SnackBarService.showSuccess(join(LocServ.inst.t('trip_point_added')));
    case TripRecordOutcome.paused:
      SnackBarService.showWarning(
        join(LocServ.inst.t('trip_point_not_recorded_paused')),
        duration: const Duration(seconds: 6),
        action: ToastAction(
          label: LocServ.inst.t('trip_resume'),
          onPressed: () => unawaited(trips.resumeTrip()),
        ),
      );
    case TripRecordOutcome.failed:
      SnackBarService.showWarning(
        join(LocServ.inst.t('trip_point_record_failed')),
      );
    case TripRecordOutcome.noActiveTrip:
    case null:
      if (lead != null) SnackBarService.showSuccess(lead);
  }
}
