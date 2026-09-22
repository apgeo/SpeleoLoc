import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/cave_place_picker_dialog.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';
import 'package:speleoloc/widgets/trip_point_time_dialog.dart';

/// The dialog-driven edits a user can make to a trip's recorded points:
/// add one at a chosen time, move an existing one, or remove it.
///
/// Extracted from `CaveTripPage` so the screen keeps only its own view
/// state. Every method returns true when the trip changed and the caller
/// should reload.
class TripPointActions {
  const TripPointActions(this._ref);

  final WidgetRef _ref;

  /// Records a point as if it had been scanned at a time the user picks —
  /// place first, then time.
  Future<bool> addPoint(BuildContext context, CaveTrip trip) async {
    final place = await CavePlacePickerDialog.show(context, trip.caveUuid);
    if (place == null || !context.mounted) return false;

    // An ended trip defaults to its last recorded moment, an active one to
    // now: both land inside the window, so the warning fires only once the
    // user deliberately moves out of it.
    final endedAt = trip.tripEndedAt;
    final initial = endedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(endedAt)
        : DateTime.now();

    final at = await _pickTime(context, trip, initial);
    if (at == null) return false;

    return _run(() async {
      await _ref
          .read(caveTripServiceProvider)
          .addPointAt(tripUuid: trip.uuid, cavePlaceUuid: place.uuid, at: at);
      SnackBarService.showSuccess(LocServ.inst.t('trip_point_added'));
    });
  }

  /// Moves [point] to a new time.
  Future<bool> editTime(
    BuildContext context,
    CaveTrip trip,
    CaveTripPoint point,
  ) async {
    final at = await _pickTime(
      context,
      trip,
      DateTime.fromMillisecondsSinceEpoch(point.scannedAt),
    );
    if (at == null) return false;
    if (at.millisecondsSinceEpoch == point.scannedAt) return false;

    return _run(() async {
      await _ref.read(caveTripServiceProvider).updatePointTime(point.uuid, at);
      SnackBarService.showSuccess(LocServ.inst.t('trip_point_time_updated'));
    });
  }

  /// Removes [point] after confirmation. [placeTitle] is what the list row
  /// shows, so the prompt names the same thing the user tapped.
  Future<bool> deletePoint(
    BuildContext context,
    CaveTripPoint point, {
    required String placeTitle,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(
          LocServ.inst.t('trip_point_delete_confirm', {'label': placeTitle}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('yes')),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    return _run(() async {
      await _ref.read(caveTripServiceProvider).deletePoint(point.uuid);
      SnackBarService.showSuccess(LocServ.inst.t('trip_point_deleted'));
    });
  }

  Future<DateTime?> _pickTime(
    BuildContext context,
    CaveTrip trip,
    DateTime initial,
  ) {
    final endedAt = trip.tripEndedAt;
    return TripPointTimeDialog.show(
      context,
      initial: initial,
      tripStart: DateTime.fromMillisecondsSinceEpoch(trip.tripStartedAt),
      tripEnd: endedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(endedAt)
          : null,
    );
  }

  /// Runs a mutation, turning the two failures the user can actually cause
  /// into messages instead of a silent no-op.
  Future<bool> _run(Future<void> Function() mutation) async {
    try {
      await mutation();
      return true;
    } on DuplicateEntryException {
      SnackBarService.showWarning(LocServ.inst.t('trip_point_duplicate'));
      return false;
    } catch (e) {
      SnackBarService.showError(e);
      return false;
    }
  }
}
