import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/screens/cave_model/model_station_sheet.dart';
import 'package:speleoloc/screens/cave_model/model_view_menu_button.dart';
import 'package:speleoloc/services/cave_model/model_viewer_asset_server.dart';
import 'package:speleoloc/services/cave_model/model_viewer_command.dart';
import 'package:speleoloc/services/cave_model/model_viewer_event.dart';
import 'package:speleoloc/services/cave_model/survey_model_format.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_controller.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_unavailable.dart';

/// Shows a Therion `.lox` or Survex `.3d` survey model in 3D.
class CaveModelViewerPage extends ConsumerStatefulWidget {
  const CaveModelViewerPage({
    super.key,
    required this.file,
    required this.title,
  });

  final File file;
  final String title;

  @override
  ConsumerState<CaveModelViewerPage> createState() =>
      _CaveModelViewerPageState();
}

enum _Phase { starting, loading, shown, failed }

class _CaveModelViewerPageState extends ConsumerState<CaveModelViewerPage> {
  static final _log = AppLogger.of('CaveModelViewerPage');

  final _controller = ModelViewerController();
  ModelViewerAssetServer? _server;
  Uri? _pageUri;
  _Phase _phase = _Phase.starting;
  String? _failure;

  @override
  void initState() {
    super.initState();
    if (ref.read(modelViewerBuilderProvider) != null) unawaited(_start());
  }

  Future<SurveyModelFormat?> _formatOf(File file) async {
    final head = await file
        .openRead(0, 32)
        .fold<BytesBuilder>(BytesBuilder(), (b, chunk) => b..add(chunk));
    return SurveyModelFormat.sniff(head.takeBytes()) ??
        SurveyModelFormat.fromFileName(file.path);
  }

  Future<void> _start() async {
    final SurveyModelFormat? format;
    try {
      format = await _formatOf(widget.file);
    } on FileSystemException catch (e) {
      _fail(e.message);
      return;
    }
    if (!mounted) return;
    if (format == null) {
      _fail(LocServ.inst.t('model_viewer_not_a_model'));
      return;
    }
    final server = ref.read(modelViewerAssetServerFactoryProvider)(
      widget.file,
      format,
    );
    _server = server;
    final uri = await server.start(
      language: LocServ.inst.locale == 'ro' ? 'ro' : 'en',
    );
    if (!mounted) {
      // The screen closed while the port was being opened, after dispose()
      // had already stopped a server that was not yet listening.
      unawaited(server.stop());
      return;
    }
    setState(() {
      _pageUri = uri;
      _phase = _Phase.loading;
    });
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.failed;
      _failure = message;
    });
  }

  void _onEvent(ModelViewerEvent event) {
    switch (event) {
      case ModelViewerReady():
        _log.info('viewer ${event.engine} ${event.engineVersion} ready');
      case ModelViewerLoaded():
        _log.info('model drawn, ${event.stations} stations');
        setState(() => _phase = _Phase.shown);
      case ModelViewerFailed(code: 'load'):
        _fail(event.message);
      case ModelViewerFailed():
        _log.warning('viewer reported ${event.code}');
      case ModelViewerStationTapped():
        unawaited(_showStation(event));
    }
  }

  Future<void> _showStation(ModelViewerStationTapped station) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => ModelStationSheet(
          station: station,
          onCentre: () {
            Navigator.of(sheetContext).pop();
            unawaited(
              _controller.send(
                FocusModelStation(station.station, spanMetres: 30),
              ),
            );
          },
        ),
      );

  @override
  void dispose() {
    unawaited(_server?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builder = ref.watch(modelViewerBuilderProvider);
    final uri = _pageUri;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (_phase == _Phase.shown)
            ModelViewMenuButton(
              onSelected: (view) =>
                  unawaited(_controller.send(SetModelView(view))),
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: builder == null
          ? const ModelViewerUnavailable()
          : Stack(
              fit: StackFit.expand,
              children: [
                if (uri != null && _phase != _Phase.failed)
                  builder(
                    pageUri: uri,
                    controller: _controller,
                    onEvent: _onEvent,
                  ),
                if (_phase == _Phase.starting || _phase == _Phase.loading)
                  const _Loading(),
                if (_phase == _Phase.failed) _Failed(message: _failure ?? ''),
              ],
            ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            LocServ.inst.t('model_viewer_loading'),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              LocServ.inst.t('model_viewer_failed'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
