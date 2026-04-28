import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speleoloc/utils/app_logger.dart';
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
  const GpsRecorderPage({super.key});

  @override
  State<GpsRecorderPage> createState() => _GpsRecorderPageState();
}

class _GpsRecorderPageState extends State<GpsRecorderPage> {
  static final _log = AppLogger.of('GpsRecorderPage');

  StreamSubscription<Position>? _sub;

  // Live state
  Position? _lastPosition;
  String? _errorMessage;
  bool _permissionDenied = false;
  bool _serviceDisabled = false;

  // Running mean state
  int _sampleCount = 0;
  double _sumLat = 0;
  double _sumLong = 0;
  double _sumAlt = 0;
  int _altSampleCount = 0;
  double _bestAccuracy = double.infinity;

  // Captured snapshot (frozen running average)
  GpsRecorderResult? _captured;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _errorMessage = null;
      _permissionDenied = false;
      _serviceDisabled = false;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _serviceDisabled = true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _permissionDenied = true);
        return;
      }

      _sub?.cancel();
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      ).listen(
        _onPosition,
        onError: (Object e, StackTrace st) {
          _log.warning('Position stream error: $e');
          if (mounted) setState(() => _errorMessage = e.toString());
        },
      );
    } catch (e) {
      _log.warning('Failed to start GPS: $e');
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  void _onPosition(Position p) {
    _sampleCount += 1;
    _sumLat += p.latitude;
    _sumLong += p.longitude;
    if (!p.altitude.isNaN) {
      _altSampleCount += 1;
      _sumAlt += p.altitude;
    }
    if (p.accuracy > 0 && p.accuracy < _bestAccuracy) {
      _bestAccuracy = p.accuracy;
    }
    if (mounted) setState(() => _lastPosition = p);
  }

  double? get _avgLat => _sampleCount == 0 ? null : _sumLat / _sampleCount;
  double? get _avgLong => _sampleCount == 0 ? null : _sumLong / _sampleCount;
  double? get _avgAlt =>
      _altSampleCount == 0 ? null : _sumAlt / _altSampleCount;

  /// Quality estimate from current accuracy (lower meters = better).
  /// Returns a 0..1 quality score and a label.
  (double, String) _qualityFromAccuracy(double? accuracy) {
    if (accuracy == null || accuracy <= 0 || accuracy.isNaN) {
      return (0.0, LocServ.inst.t('gps_quality_unknown'));
    }
    if (accuracy <= 5) return (1.0, LocServ.inst.t('gps_quality_excellent'));
    if (accuracy <= 10) return (0.8, LocServ.inst.t('gps_quality_good'));
    if (accuracy <= 20) return (0.6, LocServ.inst.t('gps_quality_fair'));
    if (accuracy <= 50) return (0.35, LocServ.inst.t('gps_quality_poor'));
    return (0.1, LocServ.inst.t('gps_quality_very_poor'));
  }

  void _capture() {
    final lat = _avgLat;
    final lng = _avgLong;
    if (lat == null || lng == null) return;
    setState(() {
      _captured = GpsRecorderResult(
        latitude: lat,
        longitude: lng,
        altitude: _avgAlt,
        accuracyMeters:
            _bestAccuracy.isFinite ? _bestAccuracy : _lastPosition?.accuracy,
        samples: _sampleCount,
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(loc),
      ),
    );
  }

  Widget _buildBody(LocServ loc) {
    if (_serviceDisabled) {
      return _StatusPanel(
        icon: Icons.location_disabled,
        title: loc.t('gps_location_service_disabled_title'),
        message: loc.t('gps_location_service_disabled_message'),
        primaryAction: ElevatedButton.icon(
          onPressed: () async {
            await Geolocator.openLocationSettings();
            _start();
          },
          icon: const Icon(Icons.settings),
          label: Text(loc.t('open_settings')),
        ),
      );
    }
    if (_permissionDenied) {
      return _StatusPanel(
        icon: Icons.gpp_bad,
        title: loc.t('gps_permission_denied_title'),
        message: loc.t('gps_permission_denied_message'),
        primaryAction: ElevatedButton.icon(
          onPressed: () async {
            await Geolocator.openAppSettings();
            _start();
          },
          icon: const Icon(Icons.settings),
          label: Text(loc.t('open_settings')),
        ),
      );
    }
    if (_errorMessage != null && _lastPosition == null) {
      return _StatusPanel(
        icon: Icons.error_outline,
        title: loc.t('gps_error_title'),
        message: _errorMessage!,
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
    final pos = _lastPosition;
    final accuracy = pos?.accuracy;
    final (quality, qLabel) = _qualityFromAccuracy(accuracy);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('gps_recorder_live'),
                style: Theme.of(context).textTheme.titleMedium),
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
              _kv(loc.t('latitude'),
                  _avgLat?.toStringAsFixed(7) ?? pos.latitude.toStringAsFixed(7)),
              _kv(loc.t('longitude'),
                  _avgLong?.toStringAsFixed(7) ??
                      pos.longitude.toStringAsFixed(7)),
              _kv(
                loc.t('altitude'),
                _avgAlt != null
                    ? '${_avgAlt!.toStringAsFixed(1)} m'
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
              _kv(loc.t('gps_samples'), _sampleCount.toString()),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: quality,
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
                  child: Text(loc.t('gps_recorder_captured'),
                      style: Theme.of(context).textTheme.titleMedium),
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
              Text(loc.t('gps_recorder_no_capture_yet'),
                  style: Theme.of(context).textTheme.bodySmall)
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
    final canCapture = _avgLat != null && _avgLong != null;
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
            child: Text(k,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[700])),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
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
