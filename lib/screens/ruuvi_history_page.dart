import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/beacon/beacon_scan_helper.dart';
import 'package:speleoloc/services/ruuvi/ruuvi_history_service.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

enum _Metric { temperature, humidity, pressure }

enum _Range { day, week, all }

/// Stored on-tag history of one Ruuvi tag: line chart / data list with
/// range filter, "download from tag" (GATT), CSV export and clear.
class RuuviHistoryPage extends ConsumerStatefulWidget {
  const RuuviHistoryPage({super.key, required this.macAddress, this.title});

  final String macAddress;
  final String? title;

  static Future<void> push(
    BuildContext context, {
    required String macAddress,
    String? title,
  }) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => RuuviHistoryPage(macAddress: macAddress, title: title),
    ),
  );

  @override
  ConsumerState<RuuviHistoryPage> createState() => _RuuviHistoryPageState();
}

class _RuuviHistoryPageState extends ConsumerState<RuuviHistoryPage> {
  final _log = AppLogger.of('RuuviHistoryPage');
  _Metric _metric = _Metric.temperature;
  _Range _range = _Range.day;
  bool _listView = false;
  bool _downloading = false;
  RuuviDownloadProgress? _progress;

  String get _mac => widget.macAddress.toUpperCase();

  Future<void> _download() async {
    if (_downloading) return;
    if (!await BeaconScanHelper.ensureAndroidPermissions()) {
      if (mounted) {
        SnackBarService.showWarning(
          LocServ.inst.t('beacon_lab_permissions_missing'),
        );
      }
      return;
    }
    if (!mounted) return;
    if (!await BeaconScanHelper.ensureLocationServicesEnabled(context)) {
      return;
    }
    setState(() {
      _downloading = true;
      _progress = null;
    });
    try {
      final result = await ref
          .read(ruuviHistoryServiceProvider)
          .download(
            _mac,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      SnackBarService.showSuccess(
        LocServ.inst.t('ruuvi_download_done', {
          'n': '${result.timestampsStored}',
        }),
      );
    } catch (e, st) {
      _log.warning('Ruuvi history download failed', e, st);
      SnackBarService.showError(e);
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _exportCsv(List<RuuviSensorHistoryData> rows) async {
    if (rows.isEmpty) {
      SnackBarService.showWarning(LocServ.inst.t('ruuvi_history_empty'));
      return;
    }
    try {
      final data = <List<Object?>>[
        ['timestamp_utc', 'temperature_c', 'humidity_pct', 'pressure_hpa'],
        for (final r in rows)
          [
            DateTime.fromMillisecondsSinceEpoch(
              r.measuredAt * 1000,
              isUtc: true,
            ).toIso8601String(),
            r.temperatureC,
            r.humidityPct,
            r.pressureHpa,
          ],
      ];
      final bytes = Uint8List.fromList(
        utf8.encode(const ListToCsvConverter().convert(data)),
      );
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final macPart = _mac.replaceAll(':', '');
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: LocServ.inst.t('ruuvi_history_export'),
        fileName: 'ruuvi_${macPart}_$ts.csv',
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
        LocServ.inst.t('ruuvi_history_exported', {'n': '${rows.length}'}),
      );
    } catch (e, st) {
      _log.warning('Ruuvi history export failed', e, st);
      SnackBarService.showError(e);
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(LocServ.inst.t('ruuvi_history_clear_confirm')),
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
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(ruuviHistoryRepositoryProvider).clearHistory(_mac);
    } catch (e) {
      SnackBarService.showError(e);
    }
  }

  List<RuuviSensorHistoryData> _applyRange(List<RuuviSensorHistoryData> rows) {
    if (_range == _Range.all) return rows;
    final cutoff =
        DateTime.now()
            .subtract(
              _range == _Range.day
                  ? const Duration(hours: 24)
                  : const Duration(days: 7),
            )
            .millisecondsSinceEpoch ~/
        1000;
    return [
      for (final r in rows)
        if (r.measuredAt >= cutoff) r,
    ];
  }

  double? _value(RuuviSensorHistoryData r) => switch (_metric) {
    _Metric.temperature => r.temperatureC,
    _Metric.humidity => r.humidityPct,
    _Metric.pressure => r.pressureHpa,
  };

  String get _unit => switch (_metric) {
    _Metric.temperature => '°C',
    _Metric.humidity => '%',
    _Metric.pressure => 'hPa',
  };

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(ruuviHistoryStreamProvider(_mac));
    final progressLabel = switch (_progress?.phase) {
      RuuviDownloadPhase.searching => LocServ.inst.t('ruuvi_download_searching'),
      RuuviDownloadPhase.connecting => LocServ.inst.t(
        'ruuvi_download_connecting',
      ),
      RuuviDownloadPhase.downloading => LocServ.inst.t(
        'ruuvi_download_downloading',
        {'n': '${_progress!.samplesReceived}'},
      ),
      RuuviDownloadPhase.storing => LocServ.inst.t('ruuvi_download_storing'),
      null => LocServ.inst.t('ruuvi_download_searching'),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? LocServ.inst.t('ruuvi_history_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: LocServ.inst.t('ruuvi_download'),
            onPressed: _downloading ? null : _download,
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: LocServ.inst.t('ruuvi_history_export'),
            onPressed: () => _exportCsv(historyAsync.valueOrNull ?? const []),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: LocServ.inst.t('ruuvi_history_clear'),
            onPressed: _clear,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_downloading) ...[
            const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                progressLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SegmentedButton<_Metric>(
                  segments: [
                    ButtonSegment(
                      value: _Metric.temperature,
                      label: Text(LocServ.inst.t('ruuvi_temperature_short')),
                    ),
                    ButtonSegment(
                      value: _Metric.humidity,
                      label: Text(LocServ.inst.t('ruuvi_humidity_short')),
                    ),
                    ButtonSegment(
                      value: _Metric.pressure,
                      label: Text(LocServ.inst.t('ruuvi_pressure_short')),
                    ),
                  ],
                  selected: {_metric},
                  onSelectionChanged: (s) =>
                      setState(() => _metric = s.single),
                  showSelectedIcon: false,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(_listView ? Icons.show_chart : Icons.table_rows),
                  tooltip: LocServ.inst.t(
                    _listView ? 'ruuvi_view_chart' : 'ruuvi_view_list',
                  ),
                  onPressed: () => setState(() => _listView = !_listView),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<_Range>(
              segments: [
                ButtonSegment(
                  value: _Range.day,
                  label: Text(LocServ.inst.t('ruuvi_range_24h')),
                ),
                ButtonSegment(
                  value: _Range.week,
                  label: Text(LocServ.inst.t('ruuvi_range_7d')),
                ),
                ButtonSegment(
                  value: _Range.all,
                  label: Text(LocServ.inst.t('ruuvi_range_all')),
                ),
              ],
              selected: {_range},
              onSelectionChanged: (s) => setState(() => _range = s.single),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (rows) {
                final ranged = _applyRange(rows);
                if (ranged.isEmpty) {
                  // Distinguish "nothing downloaded yet" from "the selected
                  // range hides it" — tags with an unsynced clock can report
                  // timestamps far outside the recent ranges.
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        rows.isEmpty
                            ? LocServ.inst.t('ruuvi_history_empty')
                            : LocServ.inst.t('ruuvi_history_range_empty', {
                                'n': '${rows.length}',
                              }),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return _listView ? _list(ranged) : _chart(ranged);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chart(List<RuuviSensorHistoryData> rows) {
    final spots = <FlSpot>[
      for (final r in rows)
        if (_value(r) != null) FlSpot(r.measuredAt.toDouble(), _value(r)!),
    ];
    if (spots.isEmpty) {
      return Center(child: Text(LocServ.inst.t('ruuvi_no_data_metric')));
    }
    final cs = Theme.of(context).colorScheme;
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final span = (maxX - minX).clamp(1, double.infinity);
    final dateFmt = span > 2 * 86400
        ? DateFormat('MM-dd')
        : DateFormat('HH:mm');
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: cs.primary,
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: false),
            ),
          ],
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: cs.outlineVariant, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (v, meta) => Text(
                  meta.formattedValue,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: span / 4,
                getTitlesWidget: (v, meta) {
                  if (v == meta.min || v == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dateFmt.format(
                        DateTime.fromMillisecondsSinceEpoch(v.toInt() * 1000),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => cs.inverseSurface,
              getTooltipItems: (touched) => [
                for (final t in touched)
                  LineTooltipItem(
                    '${DateFormat('MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(t.x.toInt() * 1000))}\n'
                    '${t.y.toStringAsFixed(2)} $_unit',
                    TextStyle(color: cs.onInverseSurface, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(List<RuuviSensorHistoryData> rows) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final r = rows[rows.length - 1 - i]; // newest first
        final parts = [
          if (r.temperatureC != null)
            '${r.temperatureC!.toStringAsFixed(2)} °C',
          if (r.humidityPct != null) '${r.humidityPct!.toStringAsFixed(2)} %',
          if (r.pressureHpa != null)
            '${r.pressureHpa!.toStringAsFixed(2)} hPa',
        ];
        return ListTile(
          dense: true,
          title: Text(
            fmt.format(
              DateTime.fromMillisecondsSinceEpoch(r.measuredAt * 1000),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: Text(parts.join(' · '), style: const TextStyle(fontSize: 12)),
        );
      },
    );
  }
}
