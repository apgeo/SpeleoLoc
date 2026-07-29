import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:speleoloc/screens/cave_map/cave_map_placement.dart';
import 'package:speleoloc/services/location/gps_averaging_session.dart';
import 'package:speleoloc/utils/coordinate_formats.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/gps_averaging_readout.dart';

/// Bottom bar shown while placing a point on the map. It is the single
/// confirm surface for every placement outcome (pick / new cave / new
/// entrance / move place): tap the map, long-press, or use the GPS location
/// to set the point, then confirm.
///
/// The GPS action runs a precision capture: it averages a stream of fixes
/// (the same [GpsAveragingSession] the recorder screen uses) and shows the
/// live sample count, accuracy and quality while the pin converges, so a
/// new cave or entrance can be recorded to a tighter position than a single
/// fix gives.
class CaveMapPlacementBar extends StatelessWidget {
  const CaveMapPlacementBar({
    super.key,
    required this.placement,
    required this.point,
    required this.busy,
    required this.locating,
    required this.gpsSession,
    required this.onUseLocation,
    required this.onCancel,
    required this.onConfirm,
    this.coordinateFormat = CoordinateDisplayFormat.decimal,
  });

  final CaveMapPlacement placement;
  final LatLng? point;
  final bool busy;
  final CoordinateDisplayFormat coordinateFormat;

  /// True while the averaged GPS capture is being started.
  final bool locating;

  /// Precision-capture state driving the readout and the toggle label.
  final GpsAveragingSession gpsSession;

  final VoidCallback onUseLocation;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  String _title(LocServ loc) {
    switch (placement.kind) {
      case PlacementKind.returnToCaller:
      case PlacementKind.moveExistingPlace:
        return placement.subjectLabel ?? loc.t('map_place_set_location');
      case PlacementKind.newCave:
        return loc.t('map_new_cave');
      case PlacementKind.newEntrance:
        return loc.t('map_new_entrance');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final p = point;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _title(loc),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              p == null
                  ? loc.t('map_place_hint')
                  : '${formatCoordinates(p.latitude, p.longitude, coordinateFormat)}'
                        '  ·  ${loc.t('map_place_tap_to_change')}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            // Live precision-capture readout: samples, accuracy, quality.
            if (gpsSession.isRunning || gpsSession.hasFix) ...[
              const SizedBox(height: 4),
              GpsAveragingReadout(session: gpsSession),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: (busy || locating) ? null : onUseLocation,
                  icon: locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          gpsSession.isRunning
                              ? Icons.stop_circle_outlined
                              : Icons.my_location,
                          size: 18,
                        ),
                  label: Text(
                    gpsSession.isRunning
                        ? loc.t('map_gps_average_stop')
                        : loc.t('map_use_my_location'),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: busy ? null : onCancel,
                  child: Text(loc.t('cancel')),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: (p != null && !busy) ? onConfirm : null,
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(loc.t('map_place_confirm')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
