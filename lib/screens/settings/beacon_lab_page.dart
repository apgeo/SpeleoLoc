import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:speleoloc/services/beacon/beacon_scan_helper.dart';
import 'package:speleoloc/services/beacon/bp1003_advertisement_parser.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Phase-0 diagnostics screen for BLE beacon hardware validation.
///
/// Two independent capture channels:
///  * **iBeacon tab** — CoreLocation / android-beacon-library ranging via
///    `dchs_flutter_beacon`. This is the only channel able to see iBeacon
///    frames on iOS.
///  * **Raw scan tab** — generic BLE scanning via `flutter_blue_plus` with
///    BP1003 scan-response decoding (battery, MAC, temperature…). On iOS
///    the iBeacon manufacturer frame is hidden by the OS; this tab tells us
///    which secondary identity channels remain visible there.
///
/// Everything observed can be exported as a JSON-lines file for offline
/// analysis of field tests (see `.claude/plans/ble-beacon-support-plan.md`,
/// Phase 0 checklist).
class BeaconLabPage extends StatefulWidget {
  const BeaconLabPage({super.key});

  @override
  State<BeaconLabPage> createState() => _BeaconLabPageState();
}

class _BeaconLabPageState extends State<BeaconLabPage>
    with SingleTickerProviderStateMixin {
  static const int _maxLogLines = 20000;

  late final TabController _tabs;
  final _log = AppLogger.of('BeaconLab');

  // Shared JSONL capture buffer (oldest dropped beyond _maxLogLines).
  final List<String> _logLines = [];
  int _droppedLogLines = 0;

  // --- iBeacon ranging state -----------------------------------------------
  StreamSubscription<RangingResult>? _rangingSub;
  final Map<String, _RangedBeacon> _ranged = {};
  List<String> _regionUuids = [honeyCommDefaultProximityUuid];
  bool _ranging = false;
  String? _rangingError;

  // --- Raw scan state -------------------------------------------------------
  StreamSubscription<List<fbp.ScanResult>>? _scanSub;
  final Map<String, _RawDevice> _rawDevices = {};
  bool _scanning = false;
  bool _beaconsOnly = true;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadRegionUuids();
  }

  @override
  void dispose() {
    _stopRanging();
    _stopRawScan();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadRegionUuids() async {
    final uuids = await BeaconScanHelper.loadRegionUuids();
    setState(() => _regionUuids = uuids);
  }

  Future<void> _saveRegionUuids() =>
      BeaconScanHelper.saveRegionUuids(_regionUuids);

  // ---------------------------------------------------------------------------
  // Capture log
  // ---------------------------------------------------------------------------

  void _appendLog(String source, Map<String, dynamic> payload) {
    if (_logLines.length >= _maxLogLines) {
      _logLines.removeAt(0);
      _droppedLogLines++;
    }
    _logLines.add(
      jsonEncode({
        'ts': DateTime.now().toIso8601String(),
        'src': source,
        ...payload,
      }),
    );
  }

  Future<void> _exportLog() async {
    if (_logLines.isEmpty) {
      SnackBarService.showWarning(LocServ.inst.t('beacon_lab_log_empty'));
      return;
    }
    try {
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final bytes = Uint8List.fromList(
        utf8.encode('${_logLines.join('\n')}\n'),
      );
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: LocServ.inst.t('beacon_lab_export_log'),
        fileName: 'beacon_lab_$ts.jsonl',
        type: FileType.any,
        bytes: bytes,
      );
      if (outputPath == null) return;
      // Android/iOS write [bytes] via the system picker and return a SAF
      // content path that dart:io cannot open (PathNotFoundException).
      // Only desktop returns a real path without writing the file.
      if (!Platform.isAndroid && !Platform.isIOS) {
        if (!File(outputPath).existsSync()) {
          await File(outputPath).writeAsBytes(bytes);
        }
      }
      SnackBarService.showSuccess(
        LocServ.inst.t('beacon_lab_log_exported', {'n': '${_logLines.length}'}),
      );
    } catch (e, st) {
      _log.warning('Log export failed', e, st);
      SnackBarService.showError(e);
    }
  }

  void _clearAll() {
    setState(() {
      _logLines.clear();
      _droppedLogLines = 0;
      _ranged.clear();
      _rawDevices.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // iBeacon ranging (dchs_flutter_beacon)
  // ---------------------------------------------------------------------------

  Future<bool> _ensureAndroidPermissions() async {
    final ok = await BeaconScanHelper.ensureAndroidPermissions();
    if (!ok && mounted) {
      SnackBarService.showWarning(
        LocServ.inst.t('beacon_lab_permissions_missing'),
      );
    }
    return ok;
  }

  Future<void> _startRanging() async {
    if (_ranging) return;
    if (!await _ensureAndroidPermissions()) return;
    setState(() => _rangingError = null);
    try {
      await flutterBeacon.initializeAndCheckScanning;
    } on PlatformException catch (e, st) {
      _log.warning('Beacon scanning init failed', e, st);
      setState(() => _rangingError = e.message ?? e.code);
      return;
    }

    final regions = BeaconScanHelper.buildRegions(_regionUuids);

    _rangingSub = flutterBeacon
        .ranging(regions)
        .listen(
          (result) {
            final now = DateTime.now();
            for (final b in result.beacons) {
              final key = '${b.proximityUUID}/${b.major}/${b.minor}';
              final entry = _ranged.putIfAbsent(
                key,
                () => _RangedBeacon(first: now, beacon: b),
              );
              entry.update(b, now);
              _appendLog('ranging', {
                'uuid': b.proximityUUID,
                'major': b.major,
                'minor': b.minor,
                'rssi': b.rssi,
                'accuracy': b.accuracy,
                'proximity': b.proximity.name,
                if (b.macAddress != null) 'mac': b.macAddress,
                if (b.txPower != null) 'txPower': b.txPower,
              });
            }
            if (mounted && result.beacons.isNotEmpty) setState(() {});
          },
          onError: (Object e, StackTrace st) {
            _log.warning('Ranging stream error', e, st);
            if (mounted) setState(() => _rangingError = e.toString());
          },
        );
    setState(() => _ranging = true);
  }

  Future<void> _stopRanging() async {
    await _rangingSub?.cancel();
    _rangingSub = null;
    if (mounted && _ranging) setState(() => _ranging = false);
  }

  Future<void> _addRegionUuid() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('beacon_lab_add_uuid')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocServ.inst.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(LocServ.inst.t('ok')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    final normalized = value.toUpperCase();
    final uuidPattern = RegExp(
      r'^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$',
    );
    if (!uuidPattern.hasMatch(normalized)) {
      SnackBarService.showWarning(LocServ.inst.t('beacon_lab_invalid_uuid'));
      return;
    }
    if (_regionUuids.contains(normalized)) return;
    setState(() => _regionUuids.add(normalized));
    await _saveRegionUuids();
    if (_ranging) {
      await _stopRanging();
      await _startRanging();
    }
  }

  Future<void> _removeRegionUuid(String uuid) async {
    if (_regionUuids.length <= 1) return; // keep at least one for iOS
    setState(() => _regionUuids.remove(uuid));
    await _saveRegionUuids();
    if (_ranging) {
      await _stopRanging();
      await _startRanging();
    }
  }

  // ---------------------------------------------------------------------------
  // Raw scanning (flutter_blue_plus)
  // ---------------------------------------------------------------------------

  Future<void> _startRawScan() async {
    if (_scanning) return;
    if (!await _ensureAndroidPermissions()) return;
    setState(() => _scanError = null);
    try {
      if (await fbp.FlutterBluePlus.adapterState.first !=
          fbp.BluetoothAdapterState.on) {
        setState(() => _scanError = LocServ.inst.t('beacon_lab_bt_off'));
        return;
      }
      _scanSub = fbp.FlutterBluePlus.scanResults.listen(
        _onRawResults,
        onError: (Object e, StackTrace st) {
          _log.warning('Raw scan stream error', e, st);
          if (mounted) setState(() => _scanError = e.toString());
        },
      );
      await fbp.FlutterBluePlus.startScan(
        continuousUpdates: true,
        androidUsesFineLocation: true,
      );
      setState(() => _scanning = true);
    } catch (e, st) {
      _log.warning('Raw scan start failed', e, st);
      await _scanSub?.cancel();
      _scanSub = null;
      setState(() => _scanError = e.toString());
    }
  }

  void _onRawResults(List<fbp.ScanResult> results) {
    final now = DateTime.now();
    var changed = false;
    for (final r in results) {
      final id = r.device.remoteId.str;
      final entry = _rawDevices.putIfAbsent(
        id,
        () => _RawDevice(first: now, last: r),
      );
      final isNewPacket =
          entry.count == 0 || r.timeStamp != entry.last.timeStamp;
      entry.update(r, now);
      changed = true;
      if (isNewPacket && (entry.isBeaconLike || !_beaconsOnly)) {
        _appendLog('rawscan', {
          'id': id,
          'name': r.advertisementData.advName,
          'rssi': r.rssi,
          if (entry.iBeacon != null)
            'ibeacon': {
              'uuid': entry.iBeacon!.proximityUuid,
              'major': entry.iBeacon!.major,
              'minor': entry.iBeacon!.minor,
              'measuredPower': entry.iBeacon!.measuredPower,
            },
          if (entry.bp1003 != null)
            'bp1003': {
              'batteryMv': entry.bp1003!.batteryMv,
              'intervalMs': entry.bp1003!.broadcastIntervalMs,
              'txPowerDbm': entry.bp1003!.txPowerDbm,
              'mac': entry.bp1003!.macAddress,
              'flags': entry.bp1003!.statusFlags,
              'temperatureC': entry.bp1003!.temperatureC,
              'humidityPct': entry.bp1003!.humidityPct,
            },
          'manufacturerData': {
            for (final e in r.advertisementData.manufacturerData.entries)
              '0x${e.key.toRadixString(16).padLeft(4, '0')}': _hex(e.value),
          },
          'serviceData': {
            for (final e in r.advertisementData.serviceData.entries)
              e.key.str: _hex(e.value),
          },
        });
      }
    }
    if (mounted && changed) setState(() {});
  }

  Future<void> _stopRawScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    try {
      await fbp.FlutterBluePlus.stopScan();
    } catch (_) {
      // adapter may already be off — nothing to stop
    }
    if (mounted && _scanning) setState(() => _scanning = false);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocServ.inst.t('beacon_lab')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: LocServ.inst.t('beacon_lab_export_log'),
            onPressed: _exportLog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: LocServ.inst.t('beacon_lab_clear'),
            onPressed: _clearAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: LocServ.inst.t('beacon_lab_ibeacon_tab')),
            Tab(text: LocServ.inst.t('beacon_lab_raw_tab')),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildCaptureBar(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [_buildIBeaconTab(), _buildRawTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureBar() {
    final total = _logLines.length + _droppedLogLines;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.fiber_manual_record,
            size: 12,
            color: (_ranging || _scanning) ? Colors.red : Colors.grey,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              LocServ.inst.t('beacon_lab_captured_lines', {'n': '$total'}),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIBeaconTab() {
    final beacons = _ranged.values.toList()
      ..sort((a, b) => b.beacon.rssi.compareTo(a.beacon.rssi));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final uuid in _regionUuids)
                Chip(
                  label: Text(
                    '…${uuid.substring(uuid.length - 12)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onDeleted: _regionUuids.length > 1
                      ? () => _removeRegionUuid(uuid)
                      : null,
                ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: LocServ.inst.t('beacon_lab_add_uuid'),
                onPressed: _addRegionUuid,
              ),
            ],
          ),
        ),
        if (Platform.isAndroid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              LocServ.inst.t('beacon_lab_android_all_note'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (_rangingError != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _rangingError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.icon(
            icon: Icon(_ranging ? Icons.stop : Icons.play_arrow),
            label: Text(
              LocServ.inst.t(_ranging ? 'beacon_lab_stop' : 'beacon_lab_start'),
            ),
            onPressed: _ranging ? _stopRanging : _startRanging,
          ),
        ),
        Expanded(
          child: beacons.isEmpty
              ? Center(child: Text(LocServ.inst.t('beacon_lab_no_beacons')))
              : ListView.separated(
                  itemCount: beacons.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _rangedTile(beacons[i]),
                ),
        ),
      ],
    );
  }

  Widget _rangedTile(_RangedBeacon rb) {
    final b = rb.beacon;
    final age = DateTime.now().difference(rb.lastSeen).inSeconds;
    return ListTile(
      dense: true,
      leading: _rssiBadge(b.rssi),
      title: Text(
        'major ${b.major} / minor ${b.minor}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${b.proximityUUID}\n'
        '~${b.accuracy.toStringAsFixed(1)} m · ${b.proximity.name}'
        '${b.macAddress != null ? ' · ${b.macAddress}' : ''}'
        ' · ×${rb.count} · ${age}s ago'
        ' · min ${rb.minRssi} / max ${rb.maxRssi} dBm',
        style: const TextStyle(fontSize: 11),
      ),
      isThreeLine: true,
    );
  }

  Widget _buildRawTab() {
    final devices =
        _rawDevices.values
            .where((d) => !_beaconsOnly || d.isBeaconLike)
            .toList()
          ..sort((a, b) => b.last.rssi.compareTo(a.last.rssi));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          dense: true,
          title: Text(LocServ.inst.t('beacon_lab_beacons_only')),
          value: _beaconsOnly,
          onChanged: (v) => setState(() => _beaconsOnly = v),
        ),
        if (_scanError != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _scanError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton.icon(
            icon: Icon(_scanning ? Icons.stop : Icons.play_arrow),
            label: Text(
              LocServ.inst.t(
                _scanning ? 'beacon_lab_stop' : 'beacon_lab_start',
              ),
            ),
            onPressed: _scanning ? _stopRawScan : _startRawScan,
          ),
        ),
        Expanded(
          child: devices.isEmpty
              ? Center(child: Text(LocServ.inst.t('beacon_lab_no_beacons')))
              : ListView.separated(
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _rawTile(devices[i]),
                ),
        ),
      ],
    );
  }

  Widget _rawTile(_RawDevice d) {
    final r = d.last;
    final adv = r.advertisementData;
    final name = adv.advName.isNotEmpty ? adv.advName : r.device.remoteId.str;
    final ib = d.iBeacon;
    final sd = d.bp1003;
    final subtitleParts = <String>[
      if (ib != null) 'iBeacon ${ib.major}/${ib.minor} @${ib.measuredPower}dBm',
      if (sd != null)
        'bat ${sd.batteryMv}mV · ${sd.macAddress}'
            '${sd.temperatureC != null ? ' · ${sd.temperatureC!.toStringAsFixed(2)}°C ${sd.humidityPct}%' : ''}',
      '×${d.count}',
    ];
    return ExpansionTile(
      dense: true,
      leading: _rssiBadge(r.rssi),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitleParts.join(' · '),
        style: const TextStyle(fontSize: 11),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ib != null) _kv('iBeacon UUID', ib.proximityUuid),
        if (sd != null) ...[
          _kv('BP1003', sd.toString()),
          _kv(
            'Flags',
            '0x${sd.statusFlags.toRadixString(16)} · connectable: ${sd.isConnectable} · accel: ${sd.hasAccelerometer} · T/H sensor: ${sd.hasTempHumiditySensor}',
          ),
          _kv('Raw T/H bytes', _hex(sd.rawTempHumidity)),
        ],
        for (final e in adv.manufacturerData.entries)
          _kv(
            'MSD 0x${e.key.toRadixString(16).padLeft(4, '0')}',
            _hex(e.value),
          ),
        for (final e in adv.serviceData.entries)
          _kv('SD ${e.key.str}', _hex(e.value)),
        _kv('Device ID', r.device.remoteId.str),
        if (adv.txPowerLevel != null) _kv('TxPower AD', '${adv.txPowerLevel}'),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: SelectableText('$k: $v', style: const TextStyle(fontSize: 12)),
  );

  Widget _rssiBadge(int rssi) {
    final Color color = rssi >= -60
        ? Colors.green
        : rssi >= -80
        ? Colors.orange
        : Colors.grey;
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        '$rssi',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

/// Aggregated observations of one ranged iBeacon identity.
class _RangedBeacon {
  Beacon beacon;
  final DateTime first;
  DateTime lastSeen;
  int count = 0;
  int minRssi = 0;
  int maxRssi = -999;

  _RangedBeacon({required this.first, required this.beacon}) : lastSeen = first;

  void update(Beacon b, DateTime now) {
    beacon = b;
    lastSeen = now;
    count++;
    if (b.rssi != 0 && b.rssi != -1) {
      if (b.rssi < minRssi) minRssi = b.rssi;
      if (b.rssi > maxRssi) maxRssi = b.rssi;
    }
  }
}

/// Aggregated observations of one raw-scanned device.
class _RawDevice {
  fbp.ScanResult last;
  final DateTime first;
  DateTime lastSeen;
  int count = 0;
  IBeaconFrame? iBeacon;
  Bp1003ServiceData? bp1003;

  _RawDevice({required this.first, required this.last}) : lastSeen = first;

  void update(fbp.ScanResult r, DateTime now) {
    last = r;
    lastSeen = now;
    count++;
    // Advertising and scan-response arrive merged or separately depending on
    // platform timing — keep the latest successful decode of each.
    iBeacon =
        IBeaconFrame.fromManufacturerData(
          r.advertisementData.manufacturerData,
        ) ??
        iBeacon;
    bp1003 =
        Bp1003ServiceData.fromServiceData({
          for (final e in r.advertisementData.serviceData.entries)
            e.key.str: e.value,
        }) ??
        bp1003;
  }

  bool get isBeaconLike =>
      iBeacon != null ||
      bp1003 != null ||
      bp1003LocalNamePattern.hasMatch(last.advertisementData.advName);
}
