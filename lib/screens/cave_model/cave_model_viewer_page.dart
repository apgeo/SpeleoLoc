import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_model/cave_model_mapping_controller.dart';
import 'package:speleoloc/screens/cave_model/mapped_places_sheet.dart';
import 'package:speleoloc/screens/cave_model/model_mode_banner.dart';
import 'package:speleoloc/screens/cave_model/model_place_picker_sheet.dart';
import 'package:speleoloc/screens/cave_model/model_station_search_sheet.dart';
import 'package:speleoloc/screens/cave_model/model_station_sheet.dart';
import 'package:speleoloc/screens/cave_model/model_view_menu_button.dart';
import 'package:speleoloc/screens/cave_model/server_models_sheet.dart';
import 'package:speleoloc/screens/cave_model/trip_replay_panel.dart';
import 'package:speleoloc/services/cave_model/model_mark_colours.dart';
import 'package:speleoloc/services/cave_model/model_splay_offset.dart';
import 'package:speleoloc/services/cave_model/model_viewer_asset_server.dart';
import 'package:speleoloc/services/cave_model/model_viewer_command.dart';
import 'package:speleoloc/services/cave_model/model_viewer_event.dart';
import 'package:speleoloc/services/cave_model/model_viewer_settings.dart';
import 'package:speleoloc/services/cave_model/survey_model_format.dart';
import 'package:speleoloc/services/map/best_raster_map_finder.dart';
import 'package:speleoloc/state/model_viewer_settings_notifier.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/app_routes.dart';
import 'package:speleoloc/utils/file_utils.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_controller.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_unavailable.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Shows a Therion `.lox` or Survex `.3d` survey model in 3D.
///
/// With [caveUuid] and [model] it also shows where the cave's places are in
/// the model and lets the caver map them; [focusPlaceUuid] opens on that
/// place (or asks for its station), [replayTripUuid] replays that trip.
class CaveModelViewerPage extends ConsumerStatefulWidget {
  const CaveModelViewerPage({
    super.key,
    required this.file,
    required this.title,
    this.model,
    this.caveUuid,
    this.focusPlaceUuid,
    this.replayTripUuid,
  });

  final File file;
  final String title;
  final DocumentationFile? model;
  final Uuid? caveUuid;
  final Uuid? focusPlaceUuid;
  final Uuid? replayTripUuid;

  @override
  ConsumerState<CaveModelViewerPage> createState() =>
      _CaveModelViewerPageState();
}

enum _Phase { starting, loading, shown, failed }

/// What a tap on the model means at the moment.
sealed class _Mode {
  const _Mode();
}

final class _Browse extends _Mode {
  const _Browse();
}

/// The next station tapped is [place]'s; [chain] moves on to the next
/// unmapped place afterwards.
final class _PickStation extends _Mode {
  const _PickStation(this.place, {this.chain = false});

  final CavePlace place;
  final bool chain;
}

final class _PickSplay extends _Mode {
  const _PickSplay();
}

final class _Distance extends _Mode {
  const _Distance(this.text);

  final String text;
}

final class _Replay extends _Mode {
  const _Replay(this.stations, this.labels, this.atLength, this.length);

  final List<String> stations;
  final List<String> labels;
  final List<double> atLength;
  final double length;
}

class _CaveModelViewerPageState extends ConsumerState<CaveModelViewerPage> {
  static final _log = AppLogger.of('CaveModelViewerPage');
  static const _focusSpanMetres = 30.0;

  final _controller = ModelViewerController();
  ModelViewerAssetServer? _server;
  Uri? _pageUri;
  _Phase _phase = _Phase.starting;
  String? _failure;
  Timer? _loadTimer;
  _Mode _mode = const _Browse();

  CaveModelMappingController? _mapping;
  List<DocumentationFile> _models = const [];
  Uuid? _defaultModel;
  String? _pushedMarks;
  final _servedMedia = <String, String>{};
  final _stationInfo = <String, Completer<ModelStationInfo?>>{};
  List<String>? _replayStations;
  List<String>? _replayLabels;

  bool get _hasContext => widget.caveUuid != null && widget.model != null;

  ModelViewerSettings get _settings =>
      ref.read(modelViewerSettingsProvider).valueOrNull ??
      const ModelViewerSettings();

  bool get _mappingOn => _hasContext && _settings.stationMapping;

  @override
  void initState() {
    super.initState();
    if (ref.read(modelViewerBuilderProvider) != null) unawaited(_start());
    final cave = widget.caveUuid;
    final model = widget.model;
    if (cave != null && model != null) {
      final mapping = CaveModelMappingController(
        caveUuid: cave,
        modelUuid: model.uuid,
        places: ref.read(cavePlaceRepositoryProvider),
        caves: ref.read(caveRepositoryProvider),
        mappings: ref.read(placeStationMappingRepositoryProvider),
      )..addListener(_onMappingChanged);
      _mapping = mapping;
      unawaited(mapping.start());
      unawaited(_loadModels(cave));
    }
  }

  Future<void> _loadModels(Uuid cave) async {
    final models = await ref.read(caveModelLocatorProvider).modelsOf(cave);
    final chosen = await ref
        .read(caveDefaultModelRepositoryProvider)
        .defaultModelOf(cave);
    if (!mounted) return;
    setState(() {
      _models = models;
      _defaultModel = chosen;
    });
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
    final Uri uri;
    try {
      uri = await server.start(
        language: LocServ.inst.locale == 'ro' ? 'ro' : 'en',
      );
    } on IOException catch (e) {
      _log.warning('viewer server did not start: $e');
      _fail(LocServ.inst.t('model_viewer_cannot_show'));
      return;
    }
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
    // A page that never answers (a script that did not parse stops all of
    // its own error reporting) must not leave the spinner up for good.
    _loadTimer = Timer(ref.read(modelViewerLoadTimeoutProvider), () {
      _log.warning('viewer did not load in time');
      _fail(LocServ.inst.t('model_viewer_cannot_show'));
    });
  }

  void _fail(String message) {
    if (!mounted) return;
    _loadTimer?.cancel();
    setState(() {
      _phase = _Phase.failed;
      _failure = message;
    });
  }

  /// Starts over after a failure, with a fresh server and page.
  void _retry() {
    unawaited(_server?.stop());
    _server = null;
    setState(() {
      _pageUri = null;
      _failure = null;
      _phase = _Phase.starting;
    });
    unawaited(_start());
  }

  void _send(ModelViewerCommand command) =>
      unawaited(_controller.send(command));

  // ---------------------------------------------------------------- events

  void _onEvent(ModelViewerEvent event) {
    switch (event) {
      case ModelViewerReady():
        _log.info('viewer ${event.engine} ${event.engineVersion} ready');
      case ModelViewerLoaded():
        _log.info('model drawn, ${event.stations} stations');
        _loadTimer?.cancel();
        setState(() => _phase = _Phase.shown);
        unawaited(_onModelShown());
      case ModelViewerFailed(code: 'load' || 'script' || 'page')
          when _phase == _Phase.starting || _phase == _Phase.loading:
        _log.warning('viewer reported ${event.code}: ${event.message}');
        _fail(
          event.code == 'load'
              ? event.message
              : LocServ.inst.t('model_viewer_cannot_show'),
        );
      case ModelViewerFailed(code: 'notFound'):
        SnackBarService.showWarning(
          LocServ.inst.t('model_station_not_found', {'station': event.message}),
        );
      case ModelViewerFailed():
        _log.warning('viewer reported ${event.code}');
      case ModelViewerStationTapped():
        _onStationTapped(event);
      case ModelMarksResolved():
        _mapping?.markUnresolved(event.unresolved);
      case ModelMarkTapped():
        _onMarkTapped(event.ids);
      case ModelStationInfo():
        _stationInfo.remove(event.station)?.complete(event);
      case ModelStationList():
        unawaited(_searchStations(event.names));
      case ModelSplayPicked():
        unawaited(_onSplayPicked(event.station, event.offset));
      case ModelSplayPickerEmpty():
        setState(() => _mode = const _Browse());
        SnackBarService.showInfo(LocServ.inst.t('model_no_splays'));
      case ModelTrailInfo():
        _onTrail(event);
    }
  }

  Future<void> _onModelShown() async {
    _pushMarks();
    await _pushMedia();
    _showWhereIAm();
    if (widget.replayTripUuid case final trip?) await _startReplay(trip);
    final focus = widget.focusPlaceUuid;
    final mapping = _mapping;
    if (focus == null || mapping == null) return;
    // The places are read from the database while the model loads.
    for (var i = 0; i < 20 && mapping.place(focus) == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final place = mapping.place(focus);
    if (place == null || !mounted) return;
    final mapped = mapping.mappingOf(focus);
    if (mapped != null) {
      _send(FocusModelStation(mapped.station, spanMetres: _focusSpanMetres));
      _send(HighlightModelStation(mapped.station));
    } else if (_mappingOn) {
      setState(() => _mode = _PickStation(place));
    }
  }

  void _onMappingChanged() {
    _pushMarks();
    unawaited(_pushMedia());
  }

  void _pushMarks() {
    if (_phase != _Phase.shown) return;
    final marks = _mappingOn
        ? _mapping!.marks(colourByArea: _settings.markColourByArea)
        : const <ModelMark>[];
    final command = SetModelMarks(marks);
    final encoded = command.encode();
    if (encoded == _pushedMarks) return;
    _pushedMarks = encoded;
    _send(command);
  }

  /// The photos of each mapped place, shown on its station.
  Future<void> _pushMedia() async {
    final mapping = _mapping;
    final server = _server;
    if (_phase != _Phase.shown || mapping == null || server == null) return;
    final documents = ref.read(documentationRepositoryProvider);
    final media = <String, List<ModelStationPhoto>>{};
    if (_mappingOn) {
      for (final place in mapping.mappedPlaces) {
        final station = mapping.mappingOf(place.uuid)?.station;
        if (station == null) continue;
        final photos = (await documents.getDocumentationFiles(
          parentLink: DocumentationGeofeatureLink(
            type: GeofeatureType.cavePlace,
            geofeatureUuid: place.uuid,
          ),
        )).where((d) => d.fileType == 'photo');
        for (final photo in photos) {
          final file = await getDocumentsFile(photo.fileName);
          if (file == null) continue;
          final url = _servedMedia[file.path] ??= server.serveMedia(file);
          media
              .putIfAbsent(station, () => [])
              .add(ModelStationPhoto(url: url, caption: photo.title));
        }
      }
    }
    if (mounted) _send(SetModelStationMedia(media));
  }

  void _showWhereIAm() {
    final here = ref.read(lastLocatedPlaceProvider).current;
    final mapping = here == null ? null : _mapping?.mappingOf(here);
    if (mapping == null || !_mappingOn) return;
    _send(
      SetModelPerson(
        id: 'here',
        station: mapping.station,
        label: LocServ.inst.t('model_you_are_here'),
        color: ModelMarkColours.here,
      ),
    );
  }

  void _onStationTapped(ModelViewerStationTapped station) {
    switch (_mode) {
      case _PickStation(:final place, :final chain):
        unawaited(_mapAndContinue(place, station.station, chain: chain));
      case _PickSplay():
        break;
      case _Browse() || _Distance() || _Replay():
        unawaited(_showStation(station));
    }
  }

  void _onMarkTapped(List<String> ids) {
    if (_mode is _PickStation) return;
    final mapping = _mapping;
    if (mapping == null || ids.isEmpty) return;
    final uuid = Uuid.tryParse(ids.first);
    final station = uuid == null ? null : mapping.mappingOf(uuid)?.station;
    if (station == null) return;
    unawaited(_showStation(ModelViewerStationTapped(station: station)));
  }

  // --------------------------------------------------------------- mapping

  Future<void> _mapAndContinue(
    CavePlace place,
    String station, {
    required bool chain,
    ModelSplayOffset? splay,
  }) async {
    final mapping = _mapping!;
    await mapping.map(place, station, splay: splay);
    SnackBarService.showSuccess(
      LocServ.inst.t('model_mapped_done', {
        'place': place.title,
        'station': station,
      }),
    );
    if (!mounted) return;
    final next = chain ? mapping.nextUnmapped(after: place.uuid) : null;
    setState(
      () => _mode = next == null
          ? const _Browse()
          : _PickStation(next, chain: true),
    );
  }

  Future<CavePlace?> _pickPlace({bool mappedOnly = false}) {
    final mapping = _mapping!;
    return showModalBottomSheet<CavePlace>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ModelPlacePickerSheet(
        places: mappedOnly ? mapping.mappedPlaces : mapping.places,
        stationOf: (p) => mapping.mappingOf(p.uuid)?.station,
      ),
    );
  }

  Future<void> _mapPlaceHere(String station) async {
    final place = await _pickPlace();
    if (place == null || !mounted) return;
    await _mapAndContinue(place, station, chain: false);
  }

  void _startSplayPick(String station) {
    setState(() => _mode = const _PickSplay());
    _send(ShowSplayPicker(station));
  }

  Future<void> _onSplayPicked(String station, ModelSplayOffset offset) async {
    _send(const HideSplayPicker());
    setState(() => _mode = const _Browse());
    final place = await _pickPlace();
    if (place == null || !mounted) return;
    await _mapAndContinue(place, station, chain: false, splay: offset);
  }

  Future<ModelStationInfo?> _askStation(String station) {
    final answer = _stationInfo.putIfAbsent(station, Completer.new);
    _send(GetModelStation(station));
    return answer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _stationInfo.remove(station);
        return null;
      },
    );
  }

  /// A place for a station that has none yet, named after the station and,
  /// when the cave's entrance is mapped, as deep below it as the model says.
  Future<void> _createPlaceAt(ModelViewerStationTapped station) async {
    final mapping = _mapping!;
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _NewPlaceDialog(initial: station.station.split('.').last),
    );
    if (title == null || title.trim().isEmpty || !mounted) return;
    double? depth;
    final entrance = mapping.mappedPlaces
        .where((p) => p.isMainEntrance == 1 || p.isEntrance == 1)
        .firstOrNull;
    final z = station.z;
    if (entrance != null && z != null) {
      final info = await _askStation(mapping.mappingOf(entrance.uuid)!.station);
      if (info?.z case final entranceZ?) {
        depth = double.parse((entranceZ - z).toStringAsFixed(2));
      }
    }
    final place = await mapping.createPlace(title.trim(), depthInCave: depth);
    if (place == null || !mounted) return;
    await _mapAndContinue(place, station.station, chain: false);
  }

  Future<void> _unmap(CavePlace place) async {
    await _mapping!.unmap(place);
    SnackBarService.showInfo(
      LocServ.inst.t('model_unmapped_done', {'place': place.title}),
    );
  }

  // ------------------------------------------------------------ navigation

  Future<void> _openOnMap(CavePlace place) async {
    final best = await BestRasterMapFinder(
      ref.read(rasterMapRepositoryProvider),
      ref.read(definitionRepositoryProvider),
    ).bestMapFor(place);
    if (!mounted) return;
    if (best == null) {
      SnackBarService.showWarning(
        LocServ.inst.t('no_map_definition_for_place'),
      );
      return;
    }
    await AppRoutes.pushCavePlaceView(
      context,
      cavePlaceUuid: place.uuid,
      caveUuid: place.caveUuid,
      initialRasterMapUuid: best,
    );
  }

  Future<void> _openPlace(CavePlace place) => AppRoutes.pushCavePlace(
    context,
    caveUuid: place.caveUuid,
    cavePlaceUuid: place.uuid,
  );

  void _fly(CavePlace place) {
    final station = _mapping?.mappingOf(place.uuid)?.station;
    if (station == null) return;
    _send(FocusModelStation(station, spanMetres: _focusSpanMetres));
    _send(HighlightModelStation(station));
  }

  Future<void> _showStation(ModelViewerStationTapped station) {
    final mapping = _mapping;
    final on = _mappingOn && mapping != null;
    final here = on ? mapping.placesAt(station.station) : const <CavePlace>[];
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ModelStationSheet(
        station: station,
        placesHere: here,
        splayPlaces: {
          for (final p in here)
            if (mapping!.mappingOf(p.uuid)?.needsReview == 1) p.uuid,
        },
        actions: ModelStationActions(
          onCentre: () => _send(
            FocusModelStation(station.station, spanMetres: _focusSpanMetres),
          ),
          onMapPlace: on ? () => _mapPlaceHere(station.station) : null,
          onMapSplay: on ? () => _startSplayPick(station.station) : null,
          onCreatePlace: on ? () => _createPlaceAt(station) : null,
          onOpenPlace: on ? _openPlace : null,
          onOpenOnMap: on ? _openOnMap : null,
          onUnmap: on ? _unmap : null,
          onDistance: on ? _measureFrom : null,
        ),
      ),
    );
  }

  Future<void> _showMappedPlaces() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    barrierColor: Colors.transparent,
    builder: (_) => MappedPlacesSheet(
      controller: _mapping!,
      onFly: _fly,
      onOpenOnMap: _openOnMap,
      onOpenPlace: _openPlace,
      onMapUnmapped: () {
        final next = _mapping!.nextUnmapped();
        if (next != null) {
          setState(() => _mode = _PickStation(next, chain: true));
        }
      },
    ),
  );

  Future<void> _searchStations(List<String> names) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ModelStationSearchSheet(names: names),
    );
    if (name == null || !mounted) return;
    _send(FocusModelStation(name, spanMetres: _focusSpanMetres));
    _send(HighlightModelStation(name));
  }

  // ----------------------------------------------------- distance & replay

  Future<void> _measureFrom(CavePlace from) async {
    final to = await _pickPlace(mappedOnly: true);
    final mapping = _mapping;
    if (to == null || mapping == null || !mounted) return;
    final a = mapping.mappingOf(from.uuid)?.station;
    final b = mapping.mappingOf(to.uuid)?.station;
    if (a == null || b == null) return;
    setState(
      () => _mode = _Distance(
        LocServ.inst.t('model_distance_measuring', {
          'from': from.title,
          'to': to.title,
        }),
      ),
    );
    _send(
      SetModelTrail(
        id: 'distance',
        stations: [a, b],
        color: ModelMarkColours.route,
      ),
    );
  }

  void _onTrail(ModelTrailInfo trail) {
    if (trail.id == 'distance' && _mode is _Distance) {
      final metres = trail.lengthMetres.toStringAsFixed(1);
      setState(
        () => _mode = _Distance(
          LocServ.inst.t(
            trail.gaps > 0 ? 'model_distance_gap' : 'model_distance_result',
            {'metres': metres},
          ),
        ),
      );
    } else if (trail.id == 'trip' &&
        _replayStations != null &&
        trail.lengthMetres > 0) {
      setState(
        () => _mode = _Replay(
          _replayStations!,
          _replayLabels!,
          trail.atLength,
          trail.lengthMetres,
        ),
      );
      _replayStep(0);
    }
  }

  Future<void> _startReplay(Uuid trip) async {
    final mapping = _mapping;
    if (mapping == null) return;
    final points = await ref
        .read(caveTripRepositoryProvider)
        .getTripPoints(trip);
    points.sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
    final stations = <String>[];
    final labels = <String>[];
    final time = DateFormat.Hm();
    for (final point in points) {
      final place = point.cavePlaceUuid;
      if (place == null) continue;
      final station = mapping.mappingOf(place)?.station;
      if (station == null) continue;
      stations.add(station);
      labels.add(
        '${time.format(DateTime.fromMillisecondsSinceEpoch(point.scannedAt))}'
        ' · ${mapping.place(place)?.title ?? station}',
      );
    }
    if (!mounted) return;
    if (stations.length < 2) {
      SnackBarService.showWarning(LocServ.inst.t('model_replay_too_few'));
      return;
    }
    _replayStations = stations;
    _replayLabels = labels;
    _send(
      SetModelTrail(
        id: 'trip',
        stations: stations,
        color: ModelMarkColours.route,
        progress: 0,
      ),
    );
  }

  void _replayStep(int index) {
    final mode = _mode;
    if (mode is! _Replay || index >= mode.atLength.length) return;
    _send(SetModelTrailProgress('trip', mode.atLength[index] / mode.length));
    _send(
      SetModelPerson(
        id: 'trip',
        station: mode.stations[index],
        label: mode.labels[index],
        color: ModelMarkColours.route,
        durationMs: 600,
      ),
    );
  }

  void _endMode() {
    switch (_mode) {
      case _PickSplay():
        _send(const HideSplayPicker());
      case _Distance():
        _send(const RemoveModelTrail('distance'));
      case _Replay():
        _send(const RemoveModelTrail('trip'));
        _send(const RemoveModelPerson('trip'));
      case _Browse() || _PickStation():
        break;
    }
    setState(() => _mode = const _Browse());
  }

  // ------------------------------------------------------------- the model

  Future<void> _switchModel(DocumentationFile model) async {
    final file = await getDocumentsFile(model.fileName);
    if (file == null || !mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CaveModelViewerPage(
          file: file,
          title: model.title,
          model: model,
          caveUuid: widget.caveUuid,
        ),
      ),
    );
  }

  Future<void> _fetchServerModel() async {
    final cave = widget.caveUuid;
    if (cave == null) return;
    final fetched = await showServerModelsSheet(context, cave);
    if (fetched == null || !mounted) return;
    final models = await ref.read(caveModelLocatorProvider).modelsOf(cave);
    final model = models.where((m) => m.uuid == fetched).firstOrNull;
    if (model != null) await _switchModel(model);
  }

  Future<void> _makeDefault() async {
    final cave = widget.caveUuid;
    final model = widget.model;
    if (cave == null || model == null) return;
    await ref
        .read(caveDefaultModelRepositoryProvider)
        .setDefaultModel(cave, model.uuid);
    if (!mounted) return;
    setState(() => _defaultModel = model.uuid);
    SnackBarService.showSuccess(LocServ.inst.t('model_default_set'));
  }

  Future<void> _setSettings(ModelViewerSettings settings) =>
      ref.read(modelViewerSettingsProvider.notifier).set(settings);

  @override
  void dispose() {
    _loadTimer?.cancel();
    _mapping?.removeListener(_onMappingChanged);
    _mapping?.dispose();
    unawaited(_server?.stop());
    super.dispose();
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final builder = ref.watch(modelViewerBuilderProvider);
    final settings = watchModelViewerSettings(ref);
    ref.listen(modelViewerSettingsProvider, (_, _) => _onMappingChanged());
    final uri = _pageUri;
    final shown = _phase == _Phase.shown;
    final mappingOn = _hasContext && settings.stationMapping;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (shown && mappingOn)
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              tooltip: LocServ.inst.t('model_mapped_places'),
              onPressed: _showMappedPlaces,
            ),
          if (shown)
            ModelViewMenuButton(
              onSelected: (view) => _send(SetModelView(view)),
            ),
          if (shown)
            _overflowMenu(
              settings,
              serverModels: switch (widget.caveUuid) {
                final cave? =>
                  ref
                          .watch(caveServerModelsProvider(cave))
                          .valueOrNull
                          ?.length ??
                      0,
                null => 0,
              },
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
                if (_phase == _Phase.failed)
                  _Failed(
                    message: _failure ?? '',
                    onRetry: _retry,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                if (shown)
                  Align(alignment: Alignment.bottomCenter, child: _modeBar()),
              ],
            ),
    );
  }

  Widget _modeBar() => switch (_mode) {
    _Browse() => const SizedBox.shrink(),
    _PickStation(:final place, :final chain) => ModelModeBanner(
      text: LocServ.inst.t('model_pick_station_for', {'place': place.title}),
      actions: [
        if (chain)
          TextButton(
            onPressed: () {
              final next = _mapping!.nextUnmapped(after: place.uuid);
              setState(
                () => _mode = next == null || next.uuid == place.uuid
                    ? const _Browse()
                    : _PickStation(next, chain: true),
              );
            },
            child: Text(LocServ.inst.t('model_skip')),
          ),
        TextButton(
          onPressed: _endMode,
          child: Text(LocServ.inst.t('model_done')),
        ),
      ],
    ),
    _PickSplay() => ModelModeBanner(
      text: LocServ.inst.t('model_pick_splay'),
      actions: [
        TextButton(onPressed: _endMode, child: Text(LocServ.inst.t('cancel'))),
      ],
    ),
    _Distance(:final text) => ModelModeBanner(
      text: text,
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: LocServ.inst.t('close'),
          onPressed: _endMode,
        ),
      ],
    ),
    _Replay(:final labels) => TripReplayPanel(
      pointLabels: labels,
      onStep: _replayStep,
      onClose: _endMode,
    ),
  };

  Widget _overflowMenu(
    ModelViewerSettings settings, {
    required int serverModels,
  }) {
    final current = widget.model?.uuid;
    final canMakeDefault = _hasContext && current != _defaultModel;
    return PopupMenuButton<VoidCallback>(
      tooltip: LocServ.inst.t('model_more'),
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        if (_models.length > 1)
          for (final model in _models)
            CheckedPopupMenuItem(
              checked: model.uuid == current,
              value: () => unawaited(_switchModel(model)),
              child: Text(
                model.uuid == _defaultModel
                    ? '${model.title} · ${LocServ.inst.t('model_default')}'
                    : model.title,
              ),
            ),
        if (canMakeDefault)
          PopupMenuItem(
            value: () => unawaited(_makeDefault()),
            child: Text(LocServ.inst.t('model_make_default')),
          ),
        if (serverModels > 0)
          PopupMenuItem(
            value: () => unawaited(_fetchServerModel()),
            child: Text(
              LocServ.inst.t('model_server_models_count', {
                'count': '$serverModels',
              }),
            ),
          ),
        if (_models.length > 1 || canMakeDefault || serverModels > 0)
          const PopupMenuDivider(),
        PopupMenuItem(
          value: () => _send(const ListModelStations()),
          child: Text(LocServ.inst.t('model_search_station')),
        ),
        if (_hasContext)
          CheckedPopupMenuItem(
            checked: settings.stationMapping,
            value: () => unawaited(
              _setSettings(
                settings.copyWith(stationMapping: !settings.stationMapping),
              ),
            ),
            child: Text(LocServ.inst.t('model_setting_mapping')),
          ),
        if (_hasContext && settings.stationMapping)
          CheckedPopupMenuItem(
            checked: settings.markColourByArea,
            value: () => unawaited(
              _setSettings(
                settings.copyWith(markColourByArea: !settings.markColourByArea),
              ),
            ),
            child: Text(LocServ.inst.t('model_setting_colour_by_area')),
          ),
      ],
    );
  }
}

class _NewPlaceDialog extends StatefulWidget {
  const _NewPlaceDialog({required this.initial});

  final String initial;

  @override
  State<_NewPlaceDialog> createState() => _NewPlaceDialogState();
}

class _NewPlaceDialogState extends State<_NewPlaceDialog> {
  late final _title = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(LocServ.inst.t('model_new_place_here')),
    content: TextField(
      controller: _title,
      autofocus: true,
      maxLength: 80,
      decoration: InputDecoration(
        labelText: LocServ.inst.t('model_place_title'),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(LocServ.inst.t('cancel')),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_title.text),
        child: Text(LocServ.inst.t('model_create_and_map')),
      ),
    ],
  );
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
  const _Failed({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

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
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                OutlinedButton(
                  onPressed: onBack,
                  child: Text(LocServ.inst.t('back')),
                ),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(LocServ.inst.t('retry')),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
