import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speleoloc/services/location/gps_averaging_session.dart';
import 'package:speleoloc/services/location/gps_quality.dart';
import 'package:speleoloc/services/location/location_service.dart';
import 'package:speleoloc/utils/localization.dart';

/// Result returned from [GpsRecorderPage] when the user saves a recorded
/// position. All values are in WGS84; altitude is GPS-reported (ellipsoidal).
class GpsRecorderResult {
  GpsRecorderResult({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracyMeters,
    this.samples,
  });

  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracyMeters;
  final int? samples;
}

/// Records a GPS point by streaming positions from the device, computing a
/// running arithmetic mean, and letting the user "Capture" a snapshot then
/// "Use" it. Returns a [GpsRecorderResult] via [Navigator.pop].
class GpsRecorderPage extends StatefulWidget {
  const GpsRecorderPage({
    super.key,
    this.locationService = const GeolocatorLocationService(),
  });

  /// Injectable so tests can fake the device location.
  final LocationService locationService;

  @override
  State<GpsRecorderPage> createState() => _GpsRecorderPageState();
}

class _GpsRecorderPageState extends State<GpsRecorderPage> {
  /// The shared precision-recording core; this screen is its presentation.
  late final GpsAveragingSession _session;

  // Captured snapshot (frozen running average)
  GpsRecorderResult? _captured;

  @override
  void initState() {
    super.initState();
    _session = GpsAveragingSession(widget.locationService)
      ..addListener(_onSessionChanged);
    unawaited(_session.start());
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _start() => _session.start();

  void _capture() {
    final lat = _session.latitude;
    final lng = _session.longitude;
    if (lat == null || lng == null) return;
    setState(() {
      _captured = GpsRecorderResult(
        latitude: lat,
        longitude: lng,
        altitude: _session.altitude,
        accuracyMeters: _session.accuracyMeters,
        samples: _session.sampleCount,
      );
    });
  }

  void _discardCaptured() {
    setState(() => _captured = null);
  }

  void _useCaptured() {
    final cap = _captured;
    if (cap == null) return;
    Navigator.pop(context, cap);
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('gps_recorder_title'))),
      body: Padding(padding: const EdgeInsets.all(16), child: _buildBody(loc)),
    );
  }

  Widget _buildBody(LocServ loc) {
    if (_session.status == GpsAveragingStatus.serviceDisabled) {
      return _StatusPanel(
        icon: Icons.location_disabled,
        title: loc.t('gps_location_service_disabled_title'),
        message: loc.t('gps_location_service_disabled_message'),
        primaryAction: ElevatedButton.icon(
          onPressed: () async {
            await widget.locationService.openLocationSettings();
            unawaited(_start());
          },
          icon: const Icon(Icons.settings),
          label: Text(loc.t('open_settings')),
        ),
      );
    }
    if (_session.status == GpsAveragingStatus.permissionDenied) {
      return _StatusPanel(
        icon: Icons.gpp_bad,
        title: loc.t('gps_permission_denied_title'),
        message: loc.t('gps_permission_denied_message'),
        primaryAction: ElevatedButton.icon(
          onPressed: () async {
            await widget.locationService.openAppSettings();
            unawaited(_start());
          },
          icon: const Icon(Icons.settings),
          label: Text(loc.t('open_settings')),
        ),
      );
    }
    if (_session.errorMessage != null && !_session.hasFix) {
      return _StatusPanel(
        icon: Icons.error_outline,
        title: loc.t('gps_error_title'),
        message: _session.errorMessage!,
        primaryAction: ElevatedButton(
          onPressed: _start,
          child: Text(loc.t('retry')),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLiveCard(loc),
        const SizedBox(height: 12),
        _buildCapturedCard(loc),
        const Spacer(),
        _buildBottomBar(loc),
      ],
    );
  }

  Widget _buildLiveCard(LocServ loc) {
    final pos = _session.lastPosition;
    final accuracy = pos?.accuracy;
    final quality = GpsQuality.fromAccuracy(accuracy);
    final qLabel = loc.t(quality.labelKey);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.t('gps_recorder_live'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (pos == null)
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(loc.t('gps_waiting_for_fix')),
                ],
              )
            else ...[
              _kv(
                loc.t('latitude'),
                _session.latitude?.toStringAsFixed(7) ??
                    pos.latitude.toStringAsFixed(7),
              ),
              _kv(
                loc.t('longitude'),
                _session.longitude?.toStringAsFixed(7) ??
                    pos.longitude.toStringAsFixed(7),
              ),
              _kv(
                loc.t('altitude'),
                _session.altitude != null
                    ? '${_session.altitude!.toStringAsFixed(1)} m'
                    : (pos.altitude.isNaN
                          ? '—'
                          : '${pos.altitude.toStringAsFixed(1)} m'),
              ),
              _kv(
                loc.t('gps_accuracy'),
                accuracy == null || accuracy.isNaN
                    ? '—'
                    : '±${accuracy.toStringAsFixed(1)} m',
              ),
              _kv(loc.t('gps_samples'), _session.sampleCount.toString()),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: quality.score,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(qLabel, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedCard(LocServ loc) {
    final cap = _captured;
    return Card(
      color: cap == null
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.t('gps_recorder_captured'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (cap != null)
                  IconButton(
                    tooltip: loc.t('gps_recorder_discard_capture'),
                    onPressed: _discardCaptured,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (cap == null)
              Text(
                loc.t('gps_recorder_no_capture_yet'),
                style: Theme.of(context).textTheme.bodySmall,
              )
            else ...[
              _kv(loc.t('latitude'), cap.latitude.toStringAsFixed(7)),
              _kv(loc.t('longitude'), cap.longitude.toStringAsFixed(7)),
              _kv(
                loc.t('altitude'),
                cap.altitude == null
                    ? '—'
                    : '${cap.altitude!.toStringAsFixed(1)} m',
              ),
              _kv(
                loc.t('gps_accuracy'),
                cap.accuracyMeters == null
                    ? '—'
                    : '±${cap.accuracyMeters!.toStringAsFixed(1)} m',
              ),
              _kv(loc.t('gps_samples'), (cap.samples ?? 0).toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(LocServ loc) {
    final canCapture = _session.hasFix;
    final canUse = _captured != null;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canCapture ? _capture : null,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(loc.t('gps_recorder_capture')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canUse ? _useCaptured : null,
            icon: const Icon(Icons.check),
            label: Text(loc.t('gps_recorder_use')),
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget primaryAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          primaryAction,
        ],
      ),
    );
  }
}
