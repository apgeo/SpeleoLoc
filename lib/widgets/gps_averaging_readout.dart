import 'package:flutter/material.dart';
import 'package:speleoloc/services/location/gps_averaging_session.dart';
import 'package:speleoloc/utils/localization.dart';

/// Compact live readout of a [GpsAveragingSession]: sample count, best
/// accuracy and a quality bar.
///
/// Sized for an overlay bar (the map placement bar); the recorder screen has
/// room for its own full-height cards and renders those instead.
class GpsAveragingReadout extends StatelessWidget {
  const GpsAveragingReadout({super.key, required this.session});

  final GpsAveragingSession session;

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final theme = Theme.of(context);

    final String message;
    switch (session.status) {
      case GpsAveragingStatus.serviceDisabled:
        message = loc.t('gps_service_disabled_short');
      case GpsAveragingStatus.permissionDenied:
        message = loc.t('gps_permission_denied_short');
      case GpsAveragingStatus.error:
        message = session.errorMessage ?? loc.t('gps_error_title');
      case GpsAveragingStatus.waitingForFix:
        message = loc.t('gps_waiting_for_fix');
      case GpsAveragingStatus.idle:
      case GpsAveragingStatus.averaging:
      case GpsAveragingStatus.stopped:
        final accuracy = session.accuracyMeters;
        message =
            '${loc.t('gps_samples')}: ${session.sampleCount}'
            '  ·  ${loc.t('gps_accuracy')}: '
            '${accuracy == null || accuracy.isNaN ? '—' : '±${accuracy.toStringAsFixed(1)} m'}';
    }

    final isProblem =
        session.status == GpsAveragingStatus.serviceDisabled ||
        session.status == GpsAveragingStatus.permissionDenied ||
        session.status == GpsAveragingStatus.error;

    return Row(
      children: [
        if (session.status == GpsAveragingStatus.waitingForFix) ...[
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: isProblem ? theme.colorScheme.error : Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (session.hasFix) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: LinearProgressIndicator(
              value: session.quality.score,
              minHeight: 6,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            loc.t(session.quality.labelKey),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
